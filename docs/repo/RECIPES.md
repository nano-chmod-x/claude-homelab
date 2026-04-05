# Justfile Recipes -- claude-homelab

Task runner recipes for the claude-homelab mono-repo. Run `just --list` to see all available recipes, or `just <recipe>` to execute.

## Validation

| Recipe | Command | Purpose |
| --- | --- | --- |
| `validate` | `just validate` | Comprehensive homelab validation: env, versions, installed plugins, connectivity, MCP servers, MCP config |
| `version-check` | `just version-check` | Check all version-bearing files for drift |
| `version-sync` | `just version-sync 1.4.0` | Sync all version-bearing files to a given version |
| `validate-skills` | `just validate-skills` | Validate all SKILL.md files across all marketplace plugins (uses `npx skills-ref validate`) |
| `validate-skill` | `just validate-skill plex` | Validate a single skill (local: `plex`, external: `synapse-mcp/synapse`) |

### `just validate` details

The `validate` recipe performs 6 checks in one run:

1. **Environment** -- `.env` exists, permissions 600, load-env.sh present
2. **Versions** -- All version-bearing files in sync
3. **Installed Plugins** -- Each installed marketplace plugin has required env vars set
4. **Connectivity** -- HTTP probe to each service URL (5s timeout)
5. **MCP Servers** -- Docker containers and local processes running for expected plugins
6. **MCP Config** -- `settings.json` has MCP URLs, workspace repos have `.mcp.json`

## Plugin Catalog

| Recipe | Command | Purpose |
| --- | --- | --- |
| `plugins` | `just plugins` | List all 27 marketplace plugins with repo, type (local/github), and local path |

## Testing

| Recipe | Command | Purpose |
| --- | --- | --- |
| `test` | `just test` | Run all tests (unit + live) for all plugins |
| `test-unit` | `just test-unit` | Run unit tests for all external plugins (pytest, vitest, cargo test) |
| `test-unit` | `just test-unit overseerr-mcp` | Run unit tests for a single plugin |
| `test-live` | `just test-live` | Run smoke/live integration tests for all external plugins |
| `test-live` | `just test-live gotify-mcp` | Run live tests for a single plugin |

Test runner auto-detection:
- `pyproject.toml` + `tests/` -> pytest
- `vitest.config.ts` -> vitest
- `Cargo.toml` + `tests/` or `src/*test*` -> cargo test

## MCP Security

| Recipe | Command | Purpose |
| --- | --- | --- |
| `mcp-security` | `just mcp-security` | Full security audit of all MCP endpoints: TLS, unauth probe, bearer auth, OAuth discovery, RFC 9728, health endpoint |
| `push-secrets` | `just push-secrets` | Push upstream credentials to GitHub Actions secrets for all MCP repos |
| `push-secrets` | `just push-secrets overseerr-mcp` | Push secrets for a single repo |

### `just mcp-security` details

For each MCP endpoint found in `~/.claude/settings.json`:

1. **TLS** -- HTTPS check, certificate expiry (warns at <30 days, critical at <7)
2. **Unauth probe** -- Sends unauthenticated request, expects 401/403
3. **Bearer auth** -- Tests configured token, expects 2xx/3xx
4. **WWW-Authenticate** -- Checks Bearer scheme, OAuth AS URI
5. **OAuth discovery** -- `.well-known/oauth-authorization-server`: issuer, PKCE, RFC 8707, JWKS, token endpoint
6. **RFC 9728** -- `.well-known/oauth-protected-resource`: resource, scopes, audience match
7. **Health endpoint** -- `/health` should return 200 without auth
8. **Security posture** -- Summary: OAuth gateway, bearer token, or unprotected

## Docker Compose Operations

| Recipe | Command | Purpose |
| --- | --- | --- |
| `up` | `just up` | `docker compose up -d` for all external plugins |
| `up` | `just up overseerr-mcp` | Start a single plugin |
| `down` | `just down` | `docker compose down` for all external plugins |
| `down` | `just down synapse-mcp` | Stop a single plugin |
| `build` | `just build` | `docker compose build` for all external plugins |
| `build` | `just build gotify-mcp` | Build a single plugin |
| `restart` | `just restart` | `docker compose restart` for all external plugins |
| `restart` | `just restart unraid-mcp` | Restart a single plugin |
| `compose-status` | `just compose-status` | Show running/down status for all external plugins |
| `deploy` | `just deploy overseerr-mcp` | Build + up in one shot |

## MCP Server Logs

| Recipe | Command | Purpose |
| --- | --- | --- |
| `mcp-servers` | `just mcp-servers` | List running MCP servers (Docker containers + local processes) |
| `mcp-logs` | `just mcp-logs overseerr-mcp` | Show last 50 lines of a container's logs |
| `mcp-logs` | `just mcp-logs overseerr-mcp 100` | Show last 100 lines |
| `mcp-logs-all` | `just mcp-logs-all` | Show last 20 lines from ALL running MCP containers |
| `mcp-logs-all` | `just mcp-logs-all 50` | Show last 50 lines from each |

## Symlinks

| Recipe | Command | Purpose |
| --- | --- | --- |
| `symlinks` | `just symlinks` | Full bash-path setup: skills, agents, commands to `~/.claude/`; install `load-env.sh`; create `.env` |
| `link-claude-md` | `just link-claude-md` | Ensure `AGENTS.md` and `GEMINI.md` symlink to `CLAUDE.md` everywhere |

## Dev Workflow

| Recipe | Command | Purpose |
| --- | --- | --- |
| `deploy` | `just deploy overseerr-mcp` | Build + start a plugin in one shot |
| `update` | `just update` | Git pull + rebuild + restart across all external plugins |
| `update` | `just update synapse-mcp` | Update a single plugin |
| `git-status` | `just git-status` | Show git branch, dirty/clean, ahead/behind for all workspace repos |

## Operations

| Recipe | Command | Purpose |
| --- | --- | --- |
| `health` | `just health` | Quick HTTP connectivity check for all configured services and MCP endpoints |
| `certs` | `just certs` | TLS certificate expiry dashboard for all HTTPS endpoints |
| `outdated` | `just outdated` | Check for outdated dependencies across external repos |

## Hygiene

| Recipe | Command | Purpose |
| --- | --- | --- |
| `lint` | `just lint` | Comprehensive lint: local Python (ruff + ty), shellcheck, skills-ref validate, PR comments, monolith detector |
| `monoliths` | `just monoliths` | Find code files over 500 LOC across all repos |
| `monoliths` | `just monoliths 300` | Custom LOC threshold |
| `env-diff` | `just env-diff` | Compare `.env.example` with actual `.env` to find new or missing variables |

### `just lint` details

Runs 5 checks in sequence:

1. **Python** -- `ruff check`, `ruff format --check`, `ty check` on local `.py` files
2. **Shell** -- `shellcheck -S warning` on all `.sh` files
3. **Skills** -- `npx skills-ref validate` on all skill directories
4. **PR comments** -- Checks for unresolved review threads in open PRs
5. **Monolith detector** -- Flags source files over 500 LOC

## Observability

| Recipe | Command | Purpose |
| --- | --- | --- |
| `status` | `just status` | One-screen dashboard: versions, compose status, health, MCP servers |
| `ports` | `just ports` | List all host:port bindings for running MCP containers + configured MCP ports |
| `resources` | `just resources` | Docker stats (CPU, memory, network) + local process RSS for MCP servers |

### `just status` details

Combines 4 views into one screen:

1. **Versions** -- Sync check across all version-bearing files
2. **Docker Compose** -- Running/down status for all plugins
3. **Service Health** -- HTTP status codes for all configured services
4. **MCP Servers** -- Running containers and local processes

## Common workflows

```bash
# Full validation after changes
just validate

# Deploy a rebuilt plugin
just deploy overseerr-mcp

# Check everything at a glance
just status

# Prepare for a version release
just version-check
just version-sync 1.5.0
just lint

# Debug an MCP server
just mcp-logs overseerr-mcp 200
just mcp-security

# Update all plugins from upstream
just update
```
