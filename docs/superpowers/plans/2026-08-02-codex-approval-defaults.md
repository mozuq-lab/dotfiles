# Codex Approval Defaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the normal Codex configuration usable for skills and local development while retaining approval prompts, with `codex --yolo` as the only explicit per-session bypass.

**Architecture:** Keep one managed `dotfiles-workspace` permission profile based on `:workspace`, grant only the external skill/runtime paths, user temp directory, and workspace-local `.git` writes needed for development, and retain sensitive-path denies. The installer owns `approval_policy = "on-request"`; execpolicy keeps explicit prompts for `git add` and `git commit`. No additional permission or config profile is installed.

**Tech Stack:** TOML, POSIX shell, PowerShell, Codex CLI execpolicy, Git

## Global Constraints

- Do not add a trusted permission profile or `<name>.config.toml` session profile.
- Normal startup must use `approval_policy = "on-request"`.
- Keep explicit prompt rules for `git add` and `git commit`.
- Allow workspace-local `.git` writes so approved Git commands can complete.
- Preserve sensitive-path denies and unrelated `claude/settings.json` changes.
- Keep macOS and Windows installer logic aligned; Windows remains source-reviewed.

---

### Task 1: Test the single-profile approval contract

**Files:**
- Modify: `codex/test-permissions.sh`
- Test: `codex/test-permissions.sh`

**Interfaces:**
- Consumes: `codex/install-permissions.sh`, `codex/permissions.toml`, and `codex/rules/default.rules`.
- Produces: Regression coverage for default approval policy, one managed profile, idempotence, collision handling, lock diagnostics, and Git prompt rules.

- [x] **Step 1: Write the failing test**

Require the generated config to contain `approval_policy = "on-request"`, reject any `dotfiles-trusted` artifact, and check `git add`, `git commit`, and `git switch` with `codex execpolicy check`.

- [x] **Step 2: Run the test to verify RED**

Run: `bash codex/test-permissions.sh`

Observed: exit 1 with `Unexpected trusted Codex profile` while the superseded profile still existed.

### Task 2: Implement the single-profile configuration

**Files:**
- Modify: `codex/permissions.toml`
- Modify: `codex/install-permissions.sh`
- Modify: `codex/install-permissions.ps1`
- Modify: `codex/rules/default.rules`
- Verify: `setup.sh`, `setup.bat`

**Interfaces:**
- Consumes: The contract in Task 1.
- Produces: One `dotfiles-workspace` profile with approvals by default and no session overlay files.

- [x] **Step 1: Remove the superseded trusted profile implementation**

Remove `dotfiles-trusted`, `trusted.config.toml`, and its setup links. Restore explicit prompt rules for `git add` and `git commit`.

- [x] **Step 2: Keep the default approval policy installer-managed**

Generate these top-level values on Unix and Windows while preserving backup, locking, conflict detection, and atomic replacement behavior:

```toml
default_permissions = "dotfiles-workspace"
approval_policy = "on-request"
```

- [x] **Step 3: Run the test to verify GREEN**

Run: `bash codex/test-permissions.sh`

Observed: `Codex permissions tests passed.` with exit code 0.

### Task 3: Document, verify, and commit

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/plans/2026-08-02-codex-approval-defaults.md`

**Interfaces:**
- Consumes: Completed single-profile behavior.
- Produces: User-facing usage notes and a focused commit excluding `claude/settings.json`.

- [x] **Step 1: Document normal and bypass launches**

Document `codex` as the approval-on-request default and `codex --yolo` as an explicit session launch that bypasses approvals and sandboxing.

- [x] **Step 2: Run complete verification**

Run `bash -n setup.sh codex/install-permissions.sh codex/test-permissions.sh`, `bash codex/test-permissions.sh`, Codex execpolicy checks, and `git diff --check`.

- [ ] **Step 3: Review and commit the intended scope**

Stage `README.md`, `codex/`, and this plan. Leave `claude/settings.json` unstaged. Commit using the repository's bracketed Japanese subject style.

### Task 4: Allow approved Git metadata writes

**Files:**
- Modify: `codex/permissions.toml`
- Modify: `codex/test-permissions.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: The existing `dotfiles-workspace` profile and Git execpolicy prompt rules.
- Produces: A normal session where approved `git add` and `git commit` commands can write `.git/index`, objects, refs, and logs without adding another profile.

- [x] **Step 1: Write and verify the failing test**

Require the installer-generated config to contain `".git" = "write"`. Run `bash codex/test-permissions.sh` and observe exit 1 with `Missing expected line` before changing the permission fragment.

- [x] **Step 2: Add the minimal permission override**

Add `".git" = "write"` under `[permissions.dotfiles-workspace.filesystem.":workspace_roots"]` while retaining all sensitive-file deny rules.

- [x] **Step 3: Verify the test passes**

Run `bash codex/test-permissions.sh` and observe `Codex permissions tests passed.` with exit code 0.
