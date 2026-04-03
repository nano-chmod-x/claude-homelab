---
description: Bump version, tag, and publish a repo to its package registry
argument-hint: [major|minor|patch]
allowed-tools: Bash
---

## Context

- Current directory: !`pwd`
- Current branch: !`git branch --show-current`
- Current version: !`grep -m1 'version' pyproject.toml Cargo.toml package.json 2>/dev/null | head -1`
- Git status: !`git status --short`

## Your task

Publish the current repo to its package registry by bumping the version, syncing all manifests, and pushing a git tag.

### 1. Pre-flight checks

- Ensure we're on `main` — if not, abort: "Switch to main before publishing."
- Ensure working tree is clean — if dirty, abort: "Commit or stash changes first."
- Ensure we're up to date: `git pull origin main`

### 2. Determine bump type

Use `$ARGUMENTS` if provided (major, minor, patch). Default to `patch`.

### 3. Bump version in ALL manifest files

Read current version from the primary manifest (first match: `Cargo.toml`, `package.json`, `pyproject.toml`).

Calculate the new version, then update ALL of these files if they exist:
- `Cargo.toml` — `version = "X.Y.Z"` in `[package]`
- `package.json` — `"version": "X.Y.Z"`
- `pyproject.toml` — `version = "X.Y.Z"` in `[project]`
- `.claude-plugin/plugin.json` — `"version": "X.Y.Z"`
- `.codex-plugin/plugin.json` — `"version": "X.Y.Z"`
- `gemini-extension.json` — `"version": "X.Y.Z"`

If Rust: run `cargo check` to update `Cargo.lock`.

Report: `Version: X.Y.Z → A.B.C (bump type)`

### 4. Update CHANGELOG.md

If `CHANGELOG.md` exists:
- Add a new section for the version: `## [A.B.C] - YYYY-MM-DD`
- Summarize changes since last tag: `git log $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~10)..HEAD --oneline`
- Group by type (feat, fix, chore, etc.)

### 5. Commit, tag, push

```bash
git add -A
git commit -m "release: vA.B.C"
git tag vA.B.C
git push origin main --tags
```

### 6. Verify

After pushing, check that the publish workflow started:
```bash
gh run list --workflow=publish-npm.yml --limit=1 2>/dev/null || \
gh run list --workflow=publish-pypi.yml --limit=1 2>/dev/null || \
gh run list --workflow=publish-crates.yml --limit=1 2>/dev/null
```

Report the workflow run URL so the user can monitor it.

---

**Notes:**
- The tag push triggers the publish workflow automatically (npm/PyPI/crates.io)
- Docker images are also built on main push via docker-publish.yml
- Never publish from a feature branch
