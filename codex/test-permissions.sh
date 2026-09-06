#!/bin/bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
PERMISSIONS_FRAGMENT="$SCRIPT_DIR/permissions.toml"
INSTALLER="$SCRIPT_DIR/install-permissions.sh"
RULES_FILE="$SCRIPT_DIR/rules/default.rules"

assert_fragment_line() {
    expected_line=$1
    if ! grep -Fqx "$expected_line" "$PERMISSIONS_FRAGMENT"; then
        echo "Missing Codex permission rule: $expected_line" >&2
        exit 1
    fi
}

assert_file_line() {
    file_path=$1
    expected_line=$2
    if ! grep -Fqx "$expected_line" "$file_path"; then
        echo "Missing expected line in $file_path: $expected_line" >&2
        exit 1
    fi
}

assert_preserved_config_block() {
    installed_path=$1
    original_path=$2
    description=$3
    extracted_path=$4
    original_line_count=$(wc -l < "$original_path")
    original_end_line=$((3 + original_line_count))

    sed -n "4,${original_end_line}p" "$installed_path" > "$extracted_path"
    if ! cmp -s "$original_path" "$extracted_path"; then
        echo "Installer did not preserve $description byte-for-byte." >&2
        return 1
    fi
}

# Codex must be able to load the complete instructions and resources for both
# standalone and plugin-provided skills. NVM hosts the local node/npm/codex
# executables on this machine, and the per-user TMPDIR is needed by compilers
# and test runners.
assert_fragment_line '"~/.agents/skills" = "read"'
assert_fragment_line '"~/.codex/skills" = "read"'
assert_fragment_line '"~/.codex/plugins/cache" = "read"'
assert_fragment_line '"~/.nvm/versions/node" = "read"'
assert_fragment_line '":tmpdir" = "write"'

# Allow ordinary toolchain reads and temporary files while keeping sensitive paths denied.
assert_fragment_line '":root" = "read"'
assert_fragment_line '"~/.ssh" = "deny"'
assert_fragment_line '"~/.aws/credentials" = "deny"'
assert_fragment_line '":slash_tmp" = "write"'

REPO_ROOT=$(dirname "$SCRIPT_DIR")
TEST_DIR=$(mktemp -d "$REPO_ROOT/.codex-permissions-test.XXXXXX")
trap 'rm -rf -- "$TEST_DIR"' EXIT HUP INT TERM

CONFIG_PATH="$TEST_DIR/config.toml"
ORIGINAL_CONFIG="$TEST_DIR/original.toml"
FIRST_CONFIG="$TEST_DIR/first.toml"

printf '%s\n' 'model = "gpt-5.6"' 'approval_policy = "never"' > "$CONFIG_PATH"
cp "$CONFIG_PATH" "$ORIGINAL_CONFIG"

bash "$INSTALLER" "$CONFIG_PATH" "$PERMISSIONS_FRAGMENT" >/dev/null
cmp -s "$ORIGINAL_CONFIG" "$CONFIG_PATH.dotfiles-backup"
cp "$CONFIG_PATH" "$FIRST_CONFIG"

# The installed config asks for approvals and keeps a single managed profile.
# Users can explicitly launch `codex --yolo` when they intend to bypass both
# approvals and the sandbox for that session.
assert_file_line "$CONFIG_PATH" 'default_permissions = "personal-workspace"'
assert_file_line "$CONFIG_PATH" '[permissions.personal-workspace]'
assert_file_line "$CONFIG_PATH" 'description = "Personal workspace access with sensitive files denied."'
assert_file_line "$CONFIG_PATH" 'approval_policy = "on-request"'
assert_file_line "$CONFIG_PATH" '".git" = "write"'
assert_file_line "$CONFIG_PATH" '"~/.ssh" = "deny"'
if grep -Fq '[permissions.dotfiles-workspace' "$CONFIG_PATH"; then
    echo "Generated config still contains the old managed profile." >&2
    exit 1
fi
if grep -Fq "dotfiles-trusted" "$CONFIG_PATH" || [ -e "$SCRIPT_DIR/trusted.config.toml" ]; then
    echo "Unexpected trusted Codex profile; use codex --yolo for an explicit bypass session." >&2
    exit 1
fi

# A repeated setup must be idempotent and leave valid TOML behind.
bash "$INSTALLER" "$CONFIG_PATH" "$PERMISSIONS_FRAGMENT" >/dev/null
cmp -s "$FIRST_CONFIG" "$CONFIG_PATH"

# A prior managed profile must migrate cleanly, preserving the backup exactly.
MIGRATION_CONFIG="$TEST_DIR/migration.toml"
MIGRATION_ORIGINAL="$TEST_DIR/migration-original.toml"
printf '%s\n' \
    'default_permissions = "dotfiles-workspace"' \
    'model = "gpt-5.6"' \
    '# >>> dotfiles managed Codex permissions >>>' \
    '[permissions.dotfiles-workspace]' \
    'extends = ":workspace"' \
    '# <<< dotfiles managed Codex permissions <<<' > "$MIGRATION_CONFIG"
cp "$MIGRATION_CONFIG" "$MIGRATION_ORIGINAL"
bash "$INSTALLER" "$MIGRATION_CONFIG" "$PERMISSIONS_FRAGMENT" >/dev/null
cmp -s "$MIGRATION_ORIGINAL" "$MIGRATION_CONFIG.dotfiles-backup"
assert_file_line "$MIGRATION_CONFIG" 'model = "gpt-5.6"'
assert_file_line "$MIGRATION_CONFIG" 'default_permissions = "personal-workspace"'
assert_file_line "$MIGRATION_CONFIG" '[permissions.personal-workspace]'
if grep -Fq '[permissions.dotfiles-workspace' "$MIGRATION_CONFIG"; then
    echo "Migration left the old managed profile in place." >&2
    exit 1
fi

# Refuse to overwrite an unmanaged profile with the managed profile name.
COLLISION_CONFIG="$TEST_DIR/collision.toml"
COLLISION_ERROR="$TEST_DIR/collision-error.log"
printf '%s\n' '[permissions.personal-workspace]' 'extends = ":workspace"' > "$COLLISION_CONFIG"
if bash "$INSTALLER" "$COLLISION_CONFIG" "$PERMISSIONS_FRAGMENT" 2>"$COLLISION_ERROR"; then
    echo "Installer unexpectedly replaced an unmanaged workspace profile." >&2
    exit 1
fi
if ! grep -Fq "A non-managed permissions.personal-workspace profile already exists" "$COLLISION_ERROR"; then
    echo "Installer did not report the personal workspace profile collision." >&2
    exit 1
fi

# An unmanaged legacy profile belongs to the user and must be retained.
LEGACY_CONFIG="$TEST_DIR/legacy-profile.toml"
printf '%s\n' '[permissions.dotfiles-workspace]' 'extends = ":workspace"' > "$LEGACY_CONFIG"
bash "$INSTALLER" "$LEGACY_CONFIG" "$PERMISSIONS_FRAGMENT" >/dev/null
assert_file_line "$LEGACY_CONFIG" 'default_permissions = "personal-workspace"'
assert_file_line "$LEGACY_CONFIG" '[permissions.personal-workspace]'
assert_file_line "$LEGACY_CONFIG" '[permissions.dotfiles-workspace]'

# TOML-looking lines inside multiline strings are unrelated string content.
MULTILINE_FAILURES=0
BASIC_STRING_CONFIG="$TEST_DIR/multiline-basic.toml"
BASIC_STRING_ORIGINAL="$TEST_DIR/multiline-basic-original.toml"
BASIC_STRING_ERROR="$TEST_DIR/multiline-basic-error.log"
printf '%s\n' \
    'basic_note = """' \
    'approval_policy = "never"' \
    '# >>> dotfiles managed Codex permissions >>>' \
    'sandbox_mode = "danger-full-access"' \
    '[permissions.personal-workspace]' \
    '# <<< dotfiles managed Codex permissions <<<' \
    '"""' > "$BASIC_STRING_CONFIG"
cp "$BASIC_STRING_CONFIG" "$BASIC_STRING_ORIGINAL"
if bash "$INSTALLER" "$BASIC_STRING_CONFIG" "$PERMISSIONS_FRAGMENT" >/dev/null 2>"$BASIC_STRING_ERROR"; then
    if ! assert_preserved_config_block \
        "$BASIC_STRING_CONFIG" \
        "$BASIC_STRING_ORIGINAL" \
        "a multiline basic string" \
        "$TEST_DIR/multiline-basic-preserved.toml"; then
        MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
    fi
else
    echo "Installer unexpectedly rejected a multiline basic string." >&2
    sed 's/^/  /' "$BASIC_STRING_ERROR" >&2
    MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
fi

LITERAL_STRING_CONFIG="$TEST_DIR/multiline-literal.toml"
LITERAL_STRING_ORIGINAL="$TEST_DIR/multiline-literal-original.toml"
LITERAL_STRING_ERROR="$TEST_DIR/multiline-literal-error.log"
printf '%s\n' \
    "literal_note = '''" \
    'default_permissions = "other"' \
    '# <<< dotfiles managed Codex permissions <<<' \
    'sandbox_workspace_write = true' \
    'permissions.personal-workspace = { extends = ":workspace" }' \
    '[permissions.personal-workspace]' \
    "'''" > "$LITERAL_STRING_CONFIG"
cp "$LITERAL_STRING_CONFIG" "$LITERAL_STRING_ORIGINAL"
if bash "$INSTALLER" "$LITERAL_STRING_CONFIG" "$PERMISSIONS_FRAGMENT" >/dev/null 2>"$LITERAL_STRING_ERROR"; then
    if ! assert_preserved_config_block \
        "$LITERAL_STRING_CONFIG" \
        "$LITERAL_STRING_ORIGINAL" \
        "a multiline literal string" \
        "$TEST_DIR/multiline-literal-preserved.toml"; then
        MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
    fi
else
    echo "Installer unexpectedly rejected a multiline literal string." >&2
    sed 's/^/  /' "$LITERAL_STRING_ERROR" >&2
    MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
fi

# A matching path component in another table is not the managed profile.
UNRELATED_TABLE_CONFIG="$TEST_DIR/unrelated-table.toml"
UNRELATED_TABLE_ORIGINAL="$TEST_DIR/unrelated-table-original.toml"
UNRELATED_TABLE_ERROR="$TEST_DIR/unrelated-table-error.log"
printf '%s\n' \
    '[projects."/Users/me/personal-workspace"]' \
    'trust_level = "trusted"' \
    '["permissions.personal-workspace"]' \
    'owner = "user"' > "$UNRELATED_TABLE_CONFIG"
cp "$UNRELATED_TABLE_CONFIG" "$UNRELATED_TABLE_ORIGINAL"
if bash "$INSTALLER" "$UNRELATED_TABLE_CONFIG" "$PERMISSIONS_FRAGMENT" >/dev/null 2>"$UNRELATED_TABLE_ERROR"; then
    if ! assert_preserved_config_block \
        "$UNRELATED_TABLE_CONFIG" \
        "$UNRELATED_TABLE_ORIGINAL" \
        "an unrelated personal-workspace table" \
        "$TEST_DIR/unrelated-table-preserved.toml"; then
        MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
    fi
else
    echo "Installer unexpectedly rejected an unrelated personal-workspace table." >&2
    sed 's/^/  /' "$UNRELATED_TABLE_ERROR" >&2
    MULTILINE_FAILURES=$((MULTILINE_FAILURES + 1))
fi

if [ "$MULTILINE_FAILURES" -ne 0 ]; then
    exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "Codex CLI is required to validate the installed config and execpolicy rules." >&2
    exit 1
fi
CODEX_BIN=$(command -v codex)
for native_codex in "$(dirname "$CODEX_BIN")"/../lib/node_modules/@openai/codex/node_modules/@openai/codex-*/vendor/*/bin/codex; do
    if [ -x "$native_codex" ]; then
        CODEX_BIN=$native_codex
        break
    fi
done
if ! "$CODEX_BIN" --version >/dev/null 2>&1; then
    echo "Codex CLI could not start for config validation: $CODEX_BIN" >&2
    exit 1
fi
CODEX_HOME="$TEST_DIR" "$CODEX_BIN" features list >/dev/null
"$CODEX_BIN" --yolo --version >/dev/null

assert_default_rule() {
    policy_json=$("$CODEX_BIN" execpolicy check --rules "$RULES_FILE" "$@" 2>/dev/null)
    if ! printf '%s\n' "$policy_json" | python3 -c 'import json, sys; result = json.load(sys.stdin); sys.exit(bool(result.get("matchedRules")) or "decision" in result)'; then
        echo "Routine command unexpectedly overrides the normal approval policy: $*" >&2
        exit 1
    fi
}

assert_default_rule git add README.md
assert_default_rule git commit -m test
assert_default_rule git switch main
assert_default_rule npm run test:e2e
assert_default_rule gh auth status

READ_ONLY_DIR="$TEST_DIR/read-only"
READ_ONLY_ERROR="$TEST_DIR/read-only-error.log"
mkdir "$READ_ONLY_DIR"
printf '%s\n' 'model = "gpt-5.6"' > "$READ_ONLY_DIR/config.toml"
chmod 0555 "$READ_ONLY_DIR"
if bash "$INSTALLER" "$READ_ONLY_DIR/config.toml" "$PERMISSIONS_FRAGMENT" 2>"$READ_ONLY_ERROR"; then
    echo "Installer unexpectedly updated a read-only config directory." >&2
    chmod 0755 "$READ_ONLY_DIR"
    exit 1
fi
chmod 0755 "$READ_ONLY_DIR"
if ! grep -Fq "Could not create Codex config lock directory:" "$READ_ONLY_ERROR"; then
    echo "Installer misreported an unwritable lock directory as lock contention." >&2
    exit 1
fi

if ! grep -Fq "Could not create Codex config lock directory:" "$SCRIPT_DIR/install-permissions.ps1"; then
    echo "PowerShell installer is missing the matching lock error diagnostic." >&2
    exit 1
fi

echo "Codex permissions tests passed."
