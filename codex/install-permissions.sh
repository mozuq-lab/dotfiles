#!/bin/bash
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 CONFIG_PATH PERMISSIONS_FRAGMENT" >&2
    exit 2
fi

CONFIG_PATH=$1
FRAGMENT_PATH=$2
PROFILE_NAME=dotfiles-workspace
BEGIN_MARKER="# >>> dotfiles managed Codex permissions >>>"
END_MARKER="# <<< dotfiles managed Codex permissions <<<"

if [ ! -f "$FRAGMENT_PATH" ]; then
    echo "Codex permissions fragment not found: $FRAGMENT_PATH" >&2
    exit 1
fi

CONFIG_DIR=$(dirname "$CONFIG_PATH")
mkdir -p "$CONFIG_DIR"

resolve_write_path() {
    current_path=$1
    link_count=0

    case "$current_path" in
        /*) ;;
        *) current_path=$(pwd)/$current_path ;;
    esac

    while [ -L "$current_path" ]; do
        link_count=$((link_count + 1))
        if [ "$link_count" -gt 40 ]; then
            echo "Too many symbolic links while resolving: $1" >&2
            return 1
        fi

        link_target=$(readlink "$current_path")
        case "$link_target" in
            /*) current_path=$link_target ;;
            *) current_path=$(dirname "$current_path")/$link_target ;;
        esac
    done

    target_directory=$(dirname "$current_path")
    if [ ! -d "$target_directory" ]; then
        echo "Codex config target directory does not exist: $target_directory" >&2
        return 1
    fi
    target_directory=$(CDPATH= cd -- "$target_directory" && pwd -P)
    printf '%s/%s\n' "$target_directory" "$(basename "$current_path")"
}

config_fingerprint() {
    if [ -e "$CONFIG_PATH" ]; then
        if command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$CONFIG_PATH"
        elif command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$CONFIG_PATH"
        else
            cksum < "$CONFIG_PATH"
        fi
    else
        printf '%s\n' missing
    fi
}

validate_toml() {
    for python_command in python3.14 python3.13 python3.12 python3.11 python3; do
        if ! command -v "$python_command" >/dev/null 2>&1; then
            continue
        fi

        if "$python_command" -c 'import tomllib' >/dev/null 2>&1; then
            "$python_command" -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))' "$1"
            return
        fi

        if "$python_command" -c 'import tomli' >/dev/null 2>&1; then
            "$python_command" -c 'import pathlib, sys, tomli; tomli.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))' "$1"
            return
        fi
    done

    echo "Warning: no TOML parser was available; syntax validation was skipped." >&2
}

WRITE_PATH=$(resolve_write_path "$CONFIG_PATH")
WRITE_DIR=$(dirname "$WRITE_PATH")
LOCK_DIR="$CONFIG_DIR/.config.toml.dotfiles.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
acquire_lock() {
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        if ! printf '%s\n' "$$" > "$LOCK_PID_FILE"; then
            rmdir "$LOCK_DIR" 2>/dev/null || true
            return 1
        fi
        return
    fi

    lock_pid=
    if [ -f "$LOCK_PID_FILE" ]; then
        IFS= read -r lock_pid < "$LOCK_PID_FILE" || true
    fi

    case "$lock_pid" in
        ''|*[!0-9]*) ;;
        *)
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                rm -f "$LOCK_PID_FILE"
                if rmdir "$LOCK_DIR" 2>/dev/null && mkdir "$LOCK_DIR" 2>/dev/null; then
                    printf '%s\n' "$$" > "$LOCK_PID_FILE"
                    return
                fi
            fi
            ;;
    esac

    echo "Another Codex config update may be running: $LOCK_DIR" >&2
    echo "If no setup process is running, remove this stale lock directory." >&2
    return 1
}

acquire_lock

CLEANED_CONFIG=
TRIMMED_CONFIG=
FINAL_CONFIG=
BACKUP_CONFIG=
cleanup() {
    for temporary_path in "$CLEANED_CONFIG" "$TRIMMED_CONFIG" "$FINAL_CONFIG" "$BACKUP_CONFIG"; do
        [ -n "$temporary_path" ] && rm -f "$temporary_path"
    done
    rm -f "$LOCK_PID_FILE"
    rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

CLEANED_CONFIG=$(mktemp "$WRITE_DIR/config.toml.cleaned.XXXXXX")
TRIMMED_CONFIG=$(mktemp "$WRITE_DIR/config.toml.trimmed.XXXXXX")
FINAL_CONFIG=$(mktemp "$WRITE_DIR/config.toml.final.XXXXXX")

ORIGINAL_FINGERPRINT=$(config_fingerprint)
if [ -e "$CONFIG_PATH" ]; then
    SOURCE_CONFIG=$CONFIG_PATH
else
    SOURCE_CONFIG=/dev/null
fi

awk -v begin_marker="$BEGIN_MARKER" -v end_marker="$END_MARKER" -v profile_name="$PROFILE_NAME" '
    $0 == begin_marker {
        if (in_managed_block) {
            print "Nested Codex permissions marker in config.toml" > "/dev/stderr"
            exit 1
        }
        in_managed_block = 1
        next
    }
    $0 == end_marker {
        if (!in_managed_block) {
            print "Unexpected Codex permissions end marker in config.toml" > "/dev/stderr"
            exit 1
        }
        in_managed_block = 0
        next
    }
    in_managed_block { next }
    {
        trimmed_line = $0
        sub(/^[[:space:]]*/, "", trimmed_line)
        if (trimmed_line ~ /^#/) {
            print
            next
        }

        assignment_index = index(trimmed_line, "=")
        if (assignment_index > 0) {
            key_part = substr(trimmed_line, 1, assignment_index - 1)
            value_part = substr(trimmed_line, assignment_index + 1)
            normalized_key = key_part
            gsub(/[[:space:]"\047]/, "", normalized_key)

            if (!seen_table && normalized_key == "default_permissions") {
                next
            }
            if (normalized_key ~ /(^|[.])(sandbox_mode|sandbox_workspace_write)($|[.])/) {
                print "Cannot install Codex permission profile while legacy sandbox settings are present." > "/dev/stderr"
                print "Remove sandbox_mode and sandbox_workspace_write from config.toml first." > "/dev/stderr"
                exit 1
            }
            if (index(normalized_key, profile_name) != 0 ||
                (normalized_key == "permissions" && index(value_part, profile_name) != 0)) {
                print "A non-managed permissions." profile_name " profile already exists in config.toml." > "/dev/stderr"
                exit 1
            }
        }

        if (assignment_index == 0 && trimmed_line ~ /^\[/) {
            if (trimmed_line ~ /(sandbox_mode|sandbox_workspace_write)/) {
                print "Cannot install Codex permission profile while legacy sandbox settings are present." > "/dev/stderr"
                print "Remove sandbox_mode and sandbox_workspace_write from config.toml first." > "/dev/stderr"
                exit 1
            }
            if (index(trimmed_line, profile_name) != 0) {
                print "A non-managed permissions." profile_name " profile already exists in config.toml." > "/dev/stderr"
                exit 1
            }
            if (trimmed_line ~ /^\[\[?[^,]*\]\]?[[:space:]]*(#.*)?$/) {
                seen_table = 1
            }
        }

        print
    }
    END {
        if (in_managed_block) {
            print "Unclosed Codex permissions marker in config.toml" > "/dev/stderr"
            exit 1
        }
    }
' "$SOURCE_CONFIG" > "$CLEANED_CONFIG"

# Removing a managed block can leave blank lines at the file boundaries.
# Trim only those boundary lines so repeated setup runs produce identical TOML.
awk '
    /^[[:space:]]*$/ {
        if (seen_content) {
            pending_blank_lines = pending_blank_lines $0 ORS
        }
        next
    }
    {
        if (seen_content && pending_blank_lines != "") {
            printf "%s", pending_blank_lines
        }
        print
        seen_content = 1
        pending_blank_lines = ""
    }
' "$CLEANED_CONFIG" > "$TRIMMED_CONFIG"

{
    printf 'default_permissions = "%s"\n' "$PROFILE_NAME"
    if [ -s "$TRIMMED_CONFIG" ]; then
        printf '\n'
        cat "$TRIMMED_CONFIG"
    fi
    printf '\n%s\n' "$BEGIN_MARKER"
    cat "$FRAGMENT_PATH"
    printf '%s\n' "$END_MARKER"
} > "$FINAL_CONFIG"

validate_toml "$FINAL_CONFIG"

CURRENT_FINGERPRINT=$(config_fingerprint)
if [ "$CURRENT_FINGERPRINT" != "$ORIGINAL_FINGERPRINT" ]; then
    echo "Codex config changed during setup; leaving the newer file untouched." >&2
    exit 1
fi

if [ "$ORIGINAL_FINGERPRINT" != missing ]; then
    BACKUP_CONFIG=$(mktemp "$CONFIG_DIR/config.toml.backup.XXXXXX")
    cp -pL "$CONFIG_PATH" "$BACKUP_CONFIG"
fi

CURRENT_FINGERPRINT=$(config_fingerprint)
if [ "$CURRENT_FINGERPRINT" != "$ORIGINAL_FINGERPRINT" ]; then
    echo "Codex config changed while its backup was being created; leaving the newer file untouched." >&2
    exit 1
fi

if [ -n "$BACKUP_CONFIG" ]; then
    mv -f "$BACKUP_CONFIG" "$CONFIG_PATH.dotfiles-backup"
    BACKUP_CONFIG=
fi

CURRENT_FINGERPRINT=$(config_fingerprint)
if [ "$CURRENT_FINGERPRINT" != "$ORIGINAL_FINGERPRINT" ]; then
    echo "Codex config changed immediately before replacement; leaving the newer file untouched." >&2
    exit 1
fi

# FINAL_CONFIG is on the same filesystem as WRITE_PATH, so rename is atomic.
# WRITE_PATH resolves the target first to preserve an existing config symlink.
mv -f "$FINAL_CONFIG" "$WRITE_PATH"
FINAL_CONFIG=
echo "Installed Codex permission profile: $PROFILE_NAME"
