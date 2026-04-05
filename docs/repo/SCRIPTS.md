# Scripts Reference -- claude-homelab

Scripts in `~/claude-homelab/scripts/` for installation, credential management, and verification.

## install.sh

**Bash-path entry point.** One-liner installer for curl | bash usage.

```bash
curl -sSL https://raw.githubusercontent.com/jmagar/claude-homelab/main/scripts/install.sh | bash
```

**Steps:**
1. Checks prerequisites (`git`, `jq`, `curl`)
2. Clones repo to `~/claude-homelab` (or `git pull` if exists)
3. Runs `setup-creds.sh` (creates `~/.claude-homelab/.env`)
4. Runs `setup-symlinks.sh` (symlinks into `~/.claude/`)
5. Runs `verify.sh` (confirms installation)
6. Prints next steps

**Properties:** Non-interactive, safe for `curl | bash` (no `read -p` prompts).

## setup-creds.sh

**Creates `~/.claude-homelab/.env` from `.env.example`.**

```bash
./scripts/setup-creds.sh
```

**Steps:**
1. Creates `~/.claude-homelab/` directory
2. Copies `scripts/load-env.sh` to `~/.claude-homelab/load-env.sh`
3. Copies `.env.example` to `~/.claude-homelab/.env` (if not already present)
4. Sets permissions: `chmod 600 ~/.claude-homelab/.env`

**Safety:** Never overwrites an existing `.env`. If running via `curl | bash` without a local repo, fetches `.env.example` from GitHub.

## setup-symlinks.sh

**Symlinks skills, agents, and commands into `~/.claude/` for Claude Code discovery.**

```bash
./scripts/setup-symlinks.sh
```

**Symlinks created:**

| Source | Target |
| --- | --- |
| `skills/<name>/` | `~/.claude/skills/<name>` |
| `agents/*.md` | `~/.claude/agents/*.md` |
| `commands/*.md` | `~/.claude/commands/*.md` |
| `commands/<dir>/` | `~/.claude/commands/<dir>` |

**Also:**
- Copies `scripts/load-env.sh` to `~/.claude-homelab/load-env.sh`
- Creates `~/.claude-homelab/.env` from `.env.example` if missing (`chmod 600`)

**Safety:** Skips existing valid symlinks, never overwrites `.env`.

## verify.sh

**Dual-path installation verifier.** Checks both bash path (symlinks) and plugin path (marketplace).

```bash
./scripts/verify.sh
```

**Checks performed:**

| Section | What it verifies |
| --- | --- |
| Credentials | `.env` exists, permissions are 600, has configured variables, `load-env.sh` installed |
| Bash Path | Skill symlinks (count, broken links), agent symlinks, command files |
| Plugin Path | `marketplace.json` valid (plugin count), `plugin.json` valid, source paths exist |
| Homelab-Core | `setup` and `health` SKILL.md files present, `check-health.sh` executable |

**Exit codes:** 0 = healthy, 1 = critical issues found.

## load-env.sh

**Credential loading library.** Must be sourced, not executed directly.

```bash
source "$HOME/.claude-homelab/load-env.sh"
```

### Functions

#### `load_env_file [path]`

Loads `~/.claude-homelab/.env` (or an explicit override path) into the environment using `set -a` / `source` / `set +a`.

```bash
load_env_file                              # Default: ~/.claude-homelab/.env
load_env_file /path/to/custom/.env         # Override path
```

Returns 1 if the file does not exist.

#### `validate_env_vars "VAR1" "VAR2" ...`

Validates that all named environment variables are set and non-empty.

```bash
validate_env_vars "PLEX_URL" "PLEX_TOKEN"
```

Returns 1 if any variable is missing, printing the missing variable names to stderr.

#### `load_service_credentials "service-name" "URL_VAR" "KEY_VAR"`

Convenience wrapper: calls `load_env_file` (if vars are not already set) then `validate_env_vars`.

```bash
load_service_credentials "radarr" "RADARR_URL" "RADARR_API_KEY"
```

### Usage in skill scripts

```bash
#!/bin/bash
set -euo pipefail
source "$HOME/.claude-homelab/load-env.sh"
load_env_file || exit 1
validate_env_vars "SERVICE_URL" "SERVICE_API_KEY"
# ... use $SERVICE_URL and $SERVICE_API_KEY
```

## push-github-secrets.sh

**Push upstream service credentials from `~/.claude-homelab/.env` to GitHub Actions secrets.**

```bash
./scripts/push-github-secrets.sh                  # All repos
./scripts/push-github-secrets.sh overseerr-mcp    # One repo only
```

**Repos covered:** overseerr-mcp, gotify-mcp, unifi-mcp, unraid-mcp, synapse-mcp, arcane-mcp. Skips swag-mcp and syslog-mcp (no upstream creds needed).

**Note:** MCP bearer tokens (`*_MCP_TOKEN`) are NOT pushed -- CI generates them at runtime.

**Prerequisites:** `gh` CLI authenticated (`gh auth status`).

## standardize-changelog.sh

**CHANGELOG format standardizer.** Creates or updates a CHANGELOG.md to follow Keep a Changelog format.

```bash
./scripts/standardize-changelog.sh /path/to/repo 1.0.0
```

**Arguments:**
1. Repository path
2. New version number

## Script conventions

All scripts in this repo follow:

- `#!/bin/bash` shebang
- `set -euo pipefail` strict mode
- Quoted variables: `"$var"`
- Color-coded logging: `log_info`, `log_success`, `log_warn`, `log_error`
- Exit code 0 for success, 1 for failure
