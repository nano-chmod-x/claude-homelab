# Claude Homelab — project recipes

set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes
default:
    @just --list

# ─── Version Management ──────────────────────────────────────────────

# Files that may carry a version field (checked only if they exist)
_version_files := "package.json Cargo.toml pyproject.toml .claude-plugin/plugin.json .codex-plugin/plugin.json gemini-extension.json README.md CLAUDE.md"

# Extract version from a single file (prints "file version" or nothing)
[private]
_extract_version file:
    #!/usr/bin/env bash
    f="{{file}}"
    [[ ! -f "$f" ]] && exit 0
    case "$f" in
        package.json|.claude-plugin/plugin.json|.codex-plugin/plugin.json|gemini-extension.json)
            v=$(grep -m1 '"version"' "$f" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            ;;
        Cargo.toml|pyproject.toml)
            v=$(grep -m1 '^version' "$f" | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')
            ;;
        README.md)
            v=$(grep -m1 '^Version:' "$f" | sed 's/Version:[[:space:]]*//')
            ;;
        CLAUDE.md)
            v=$(grep -m1 '^\*\*Version:\*\*' "$f" | sed 's/\*\*Version:\*\*[[:space:]]*//')
            ;;
        *) exit 0 ;;
    esac
    [[ -n "${v:-}" ]] && printf "%-40s %s\n" "$f" "$v"

# Check all version-bearing files for drift
version-check:
    #!/usr/bin/env bash
    set -euo pipefail
    versions=()
    files=()
    echo "File                                     Version"
    echo "──────────────────────────────────────── ───────"
    for f in {{_version_files}}; do
        [[ ! -f "$f" ]] && continue
        line=$(just _extract_version "$f")
        [[ -z "$line" ]] && continue
        echo "$line"
        v=$(echo "$line" | awk '{print $NF}')
        versions+=("$v")
        files+=("$f")
    done
    if [[ ${#versions[@]} -eq 0 ]]; then
        echo "No version-bearing files found."
        exit 0
    fi
    # Check for drift
    first="${versions[0]}"
    drift=false
    for v in "${versions[@]}"; do
        if [[ "$v" != "$first" ]]; then
            drift=true
            break
        fi
    done
    echo ""
    if $drift; then
        echo "DRIFT DETECTED — versions are not in sync."
        echo "Run: just version-sync <version>"
        exit 1
    else
        echo "All versions in sync: $first"
    fi

# Sync all version-bearing files to the given version
version-sync version:
    #!/usr/bin/env bash
    set -euo pipefail
    v="{{version}}"
    # Validate semver-ish format
    if ! [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: version must be semver (e.g. 1.3.0), got: $v"
        exit 1
    fi
    for f in {{_version_files}}; do
        [[ ! -f "$f" ]] && continue
        case "$f" in
            package.json|.claude-plugin/plugin.json|.codex-plugin/plugin.json|gemini-extension.json)
                if grep -q '"version"' "$f"; then
                    sed -i 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'"$v"'"/' "$f"
                    echo "Updated $f → $v"
                fi
                ;;
            Cargo.toml)
                if grep -q '^version' "$f"; then
                    sed -i 's/^version[[:space:]]*=.*/version = "'"$v"'"/' "$f"
                    echo "Updated $f → $v"
                fi
                ;;
            pyproject.toml)
                if grep -q '^version' "$f"; then
                    sed -i 's/^version[[:space:]]*=.*/version = "'"$v"'"/' "$f"
                    echo "Updated $f → $v"
                fi
                ;;
            README.md)
                if grep -q '^Version:' "$f"; then
                    sed -i 's/^Version:.*/Version: '"$v"'/' "$f"
                    echo "Updated $f → $v"
                fi
                ;;
            CLAUDE.md)
                if grep -q '^\*\*Version:\*\*' "$f"; then
                    sed -i 's/^\*\*Version:\*\*.*/\*\*Version:\*\* '"$v"'/' "$f"
                    echo "Updated $f → $v"
                fi
                ;;
        esac
    done
    echo ""
    echo "All files synced to $v"

# ─── CLAUDE.md Symlinks ──────────────────────────────────────────────

# Ensure AGENTS.md and GEMINI.md symlink to CLAUDE.md everywhere
link-claude-md:
    #!/usr/bin/env bash
    set -euo pipefail
    count=0
    # Find every directory containing a regular-file CLAUDE.md
    while IFS= read -r claude_file; do
        dir=$(dirname "$claude_file")
        for target in AGENTS.md GEMINI.md; do
            link="$dir/$target"
            if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "CLAUDE.md" ]]; then
                echo "OK   $link → CLAUDE.md"
            else
                # Remove stale file/symlink if present
                rm -f "$link"
                ln -s CLAUDE.md "$link"
                echo "LINK $link → CLAUDE.md"
                count=$((count + 1))
            fi
        done
    done < <(find . -name CLAUDE.md -not -path './.git/*' -not -path './.beads/*' -type f)
    echo ""
    if [[ $count -eq 0 ]]; then
        echo "All symlinks already in place."
    else
        echo "Created $count new symlink(s)."
    fi
