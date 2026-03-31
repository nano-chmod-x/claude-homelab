#!/usr/bin/env bash
set -euo pipefail

# ── scaffold-plugin.sh ──────────────────────────────────────────────────────
# Generates a new MCP server plugin from the canonical template defined in
# docs/plugin-setup-guide.md.
#
# Usage:
#   ./scripts/scaffold-plugin.sh <service-name> <language> [--port PORT]
#
# Example:
#   ./scripts/scaffold-plugin.sh gotify python --port 9158
#   ./scripts/scaffold-plugin.sh synapse typescript --port 3000
#   ./scripts/scaffold-plugin.sh syslog rust --port 3100
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Argument parsing ────────────────────────────────────────────────────────

usage() {
  cat >&2 <<EOF
Usage: $0 <service-name> <language> [--port PORT]

Arguments:
  service-name   Lowercase, hyphenated service name (e.g. my-service)
  language       python | typescript | rust

Options:
  --port PORT    MCP server port (default: 9000)
  -h, --help     Show this help

Examples:
  $0 gotify python --port 9158
  $0 synapse typescript --port 3000
  $0 syslog rust --port 3100
EOF
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: $0 <service-name> <language> [--port PORT]

Generates a new MCP server plugin skeleton from the canonical template.

Arguments:
  service-name   Lowercase, hyphenated service name (e.g. my-service)
  language       python | typescript | rust

Options:
  --port PORT    MCP server port (default: 9000)
  -h, --help     Show this help and exit

Examples:
  $0 gotify python --port 9158
  $0 synapse typescript --port 3000
  $0 syslog rust --port 3100

Creates directory ./<service-name>-mcp/ with full plugin structure.
EOF
  exit 0
fi

if [ $# -lt 2 ]; then
  usage
fi

SERVICE="$1"
LANG="$2"
shift 2

PORT=9000

while [ $# -gt 0 ]; do
  case "$1" in
    --port)
      PORT="${2:?--port requires a value}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate language
case "$LANG" in
  python|typescript|rust) ;;
  *)
    echo "Error: language must be python, typescript, or rust (got: $LANG)" >&2
    exit 1
    ;;
esac

# Validate service name (lowercase, hyphens, no leading/trailing hyphen)
if ! echo "$SERVICE" | grep -qE '^[a-z][a-z0-9-]*[a-z0-9]$'; then
  echo "Error: service name must be lowercase alphanumeric with hyphens (got: $SERVICE)" >&2
  exit 1
fi

# ── Derive all names ────────────────────────────────────────────────────────

PLUGIN_NAME="${SERVICE}-mcp"
TOOL_NAME="$(echo "$SERVICE" | tr '-' '_')"
ENV_PREFIX="$(echo "$SERVICE" | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
MCP_ENV_PREFIX="${ENV_PREFIX}_MCP"
DOCKER_NETWORK="${SERVICE}_mcp"
MODULE_NAME="${TOOL_NAME}_mcp"
DISPLAY_NAME="$(echo "$SERVICE" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')"
CURRENT_YEAR="$(date +%Y)"
TODAY="$(date +%Y-%m-%d)"

OUT_DIR="./${PLUGIN_NAME}"

if [ -d "$OUT_DIR" ]; then
  echo "Error: directory $OUT_DIR already exists" >&2
  exit 1
fi

echo "Scaffolding ${PLUGIN_NAME} (${LANG}) at ${OUT_DIR} ..."

# ── Create directory structure ──────────────────────────────────────────────

mkdir -p "${OUT_DIR}"/{.claude-plugin,.codex-plugin,assets,hooks/scripts,skills/"${SERVICE}",scripts,tests,backups,logs}

# ── 1. .claude-plugin/plugin.json ──────────────────────────────────────────

cat > "${OUT_DIR}/.claude-plugin/plugin.json" <<EOFPLUGIN
{
  "name": "${PLUGIN_NAME}",
  "version": "1.0.0",
  "description": "Manage ${DISPLAY_NAME} via MCP tools with HTTP fallback.",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "repository": "https://github.com/jmagar/${PLUGIN_NAME}",
  "homepage": "https://github.com/jmagar/${PLUGIN_NAME}",
  "license": "MIT",
  "keywords": ["${SERVICE}", "homelab", "mcp"],
  "userConfig": {
    "${TOOL_NAME}_mcp_url": {
      "type": "string",
      "title": "${DISPLAY_NAME} MCP Server URL",
      "description": "Full MCP endpoint URL including /mcp path (e.g. https://${PLUGIN_NAME}.example.com/mcp).",
      "default": "http://localhost:${PORT}/mcp",
      "sensitive": false
    },
    "${TOOL_NAME}_mcp_token": {
      "type": "string",
      "title": "MCP Server Bearer Token",
      "description": "Bearer token for authenticating with the MCP server. Must match ${MCP_ENV_PREFIX}_TOKEN in .env. Generate with: openssl rand -hex 32",
      "sensitive": false
    },
    "${TOOL_NAME}_url": {
      "type": "string",
      "title": "${DISPLAY_NAME} URL",
      "description": "Base URL of your ${DISPLAY_NAME} instance, e.g. https://${SERVICE}.example.com. No trailing slash.",
      "sensitive": true
    },
    "${TOOL_NAME}_api_key": {
      "type": "string",
      "title": "${DISPLAY_NAME} API Key",
      "description": "API key for ${DISPLAY_NAME}. Found in Settings -> API.",
      "sensitive": true
    }
  }
}
EOFPLUGIN

# ── 2. .codex-plugin/plugin.json ──────────────────────────────────────────

cat > "${OUT_DIR}/.codex-plugin/plugin.json" <<EOFCODEX
{
  "name": "${PLUGIN_NAME}",
  "version": "1.0.0",
  "description": "Manage ${DISPLAY_NAME} via MCP tools",
  "skills": "./skills/",
  "mcpServers": "./.mcp.json",
  "apps": "./.app.json",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "homepage": "https://github.com/jmagar/${PLUGIN_NAME}",
  "repository": "https://github.com/jmagar/${PLUGIN_NAME}",
  "license": "MIT",
  "keywords": ["${SERVICE}", "homelab", "mcp"],
  "interface": {
    "displayName": "${DISPLAY_NAME} MCP",
    "shortDescription": "Manage ${DISPLAY_NAME} resources via MCP tools",
    "longDescription": "Full MCP integration for ${DISPLAY_NAME} with action+subaction pattern, destructive operation gating, and dual-mode skill support.",
    "developerName": "Jacob Magar",
    "category": "Infrastructure",
    "capabilities": ["mcp", "tools", "skills"],
    "brandColor": "#4A90D9",
    "composerIcon": "./assets/icon.png",
    "logo": "./assets/logo.svg",
    "screenshots": ["./assets/screenshots/overview.png"]
  }
}
EOFCODEX

# ── 3. .app.json ────────────────────────────────────────────────────────────

cat > "${OUT_DIR}/.app.json" <<EOFAPP
{
  "apps": [
    {
      "name": "${PLUGIN_NAME}",
      "type": "mcp",
      "config": "./.mcp.json"
    }
  ]
}
EOFAPP

# ── 4. .mcp.json ────────────────────────────────────────────────────────────

cat > "${OUT_DIR}/.mcp.json" <<EOFMCP
{
  "mcpServers": {
    "${PLUGIN_NAME}": {
      "type": "http",
      "url": "\${user_config.${TOOL_NAME}_mcp_url}",
      "headers": {
        "Authorization": "Bearer \${user_config.${TOOL_NAME}_mcp_token}"
      }
    }
  }
}
EOFMCP

# ── 5. assets/.gitkeep ─────────────────────────────────────────────────────

mkdir -p "${OUT_DIR}/assets/screenshots"
touch "${OUT_DIR}/assets/.gitkeep"

# ── 6. hooks/hooks.json ─────────────────────────────────────────────────────

cat > "${OUT_DIR}/hooks/hooks.json" <<'EOFHOOKS'
{
  "description": "Sync userConfig credentials to .env, enforce 600 permissions, ensure gitignore",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/sync-env.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-ignore-files.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fix-env-perms.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOFHOOKS

# ── 7. hooks/scripts/sync-env.sh ───────────────────────────────────────────

cat > "${OUT_DIR}/hooks/scripts/sync-env.sh" <<EOFSYNC
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="\${CLAUDE_PLUGIN_ROOT}/.env"
BACKUP_DIR="\${CLAUDE_PLUGIN_ROOT}/backups"
LOCK_FILE="\${CLAUDE_PLUGIN_ROOT}/.env.lock"
mkdir -p "\$BACKUP_DIR"

# Serialize concurrent sessions (two tabs starting at the same time)
exec 9>"\$LOCK_FILE"
flock -w 10 9 || { echo "sync-env: failed to acquire lock after 10s" >&2; exit 1; }

declare -A MANAGED=(
  [${ENV_PREFIX}_URL]="\${CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_URL:-}"
  [${ENV_PREFIX}_API_KEY]="\${CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_API_KEY:-}"
  [${MCP_ENV_PREFIX}_URL]="\${CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_MCP_URL:-}"
  [${MCP_ENV_PREFIX}_TOKEN]="\${CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_MCP_TOKEN:-}"
)

touch "\$ENV_FILE"

# Backup before writing (max 3 retained)
if [ -s "\$ENV_FILE" ]; then
  cp "\$ENV_FILE" "\${BACKUP_DIR}/.env.bak.\$(date +%s)"
fi

# Write managed keys — awk handles arbitrary values safely (no delimiter injection)
for key in "\${!MANAGED[@]}"; do
  value="\${MANAGED[\$key]}"
  [ -z "\$value" ] && continue
  if grep -q "^\${key}=" "\$ENV_FILE" 2>/dev/null; then
    awk -v k="\$key" -v v="\$value" '\$0 ~ "^"k"=" { print k"="v; next } { print }' \\
      "\$ENV_FILE" > "\${ENV_FILE}.tmp" && mv "\${ENV_FILE}.tmp" "\$ENV_FILE"
  else
    echo "\${key}=\${value}" >> "\$ENV_FILE"
  fi
done

# Fail if bearer token is not set — do NOT auto-generate.
if ! grep -q "^${MCP_ENV_PREFIX}_TOKEN=.\+" "\$ENV_FILE" 2>/dev/null; then
  echo "sync-env: ERROR — ${MCP_ENV_PREFIX}_TOKEN is not set." >&2
  echo "  Generate one:  openssl rand -hex 32" >&2
  echo "  Then paste it into the plugin's userConfig MCP token field." >&2
  exit 1
fi

chmod 600 "\$ENV_FILE"

# Prune old backups
mapfile -t baks < <(ls -t "\${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "\${baks[@]}"; do chmod 600 "\$bak"; done
for bak in "\${baks[@]:3}"; do rm -f "\$bak"; done
EOFSYNC
chmod +x "${OUT_DIR}/hooks/scripts/sync-env.sh"

# ── 8. hooks/scripts/fix-env-perms.sh ──────────────────────────────────────

cat > "${OUT_DIR}/hooks/scripts/fix-env-perms.sh" <<'EOFFIX'
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
[ -f "$ENV_FILE" ] || exit 0

# Read and discard stdin (PostToolUse hooks receive JSON on stdin)
cat > /dev/null

# Unconditionally enforce permissions — the PostToolUse matcher already limits
# this to Write|Edit|MultiEdit|Bash. Checking whether the command string
# contains ".env" is a heuristic that misses variable-based paths like:
#   f=".env"; echo "KEY=val" >> "$f"
chmod 600 "$ENV_FILE"
for bak in "${CLAUDE_PLUGIN_ROOT}/backups"/.env.bak.*; do
  [ -f "$bak" ] && chmod 600 "$bak"
done
EOFFIX
chmod +x "${OUT_DIR}/hooks/scripts/fix-env-perms.sh"

# ── 9. hooks/scripts/ensure-ignore-files.sh ─────────────────────────────────

if [ -f "${REPO_ROOT}/scripts/ensure-ignore-files.sh" ]; then
  cp "${REPO_ROOT}/scripts/ensure-ignore-files.sh" "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh"
else
  # Minimal fallback
  cat > "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh" <<'EOFENSURE'
#!/usr/bin/env bash
set -euo pipefail
# Ensure .gitignore and .dockerignore have required patterns.
# Copy the full version from claude-homelab/scripts/ensure-ignore-files.sh
echo "ensure-ignore-files: stub — replace with full script from claude-homelab/scripts/"
EOFENSURE
fi
chmod +x "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh"

# ── 10. skills/<service>/SKILL.md ───────────────────────────────────────────

cat > "${OUT_DIR}/skills/${SERVICE}/SKILL.md" <<EOFSKILL
---
name: ${SERVICE}
description: This skill should be used when the user asks to "list resources", "get resource",
  "create resource", "delete resource", "check status", or mentions ${DISPLAY_NAME} or its domain keywords.
---

# ${DISPLAY_NAME} Skill

## Mode Detection

**MCP mode** (preferred): Use when \`mcp__${PLUGIN_NAME}__${TOOL_NAME}\` tool is available.

**HTTP fallback**: Use when MCP tools are unavailable. Credentials are in Bash subprocesses
as \`\$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_URL\` and \`\$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_API_KEY\`.
Do NOT attempt \`\${user_config.${TOOL_NAME}_api_key}\` in curl — sensitive values only work
as \`\$CLAUDE_PLUGIN_OPTION_*\` in Bash subprocesses.

**MCP URL**: \`\${user_config.${TOOL_NAME}_mcp_url}\`

---

## MCP Mode — Tool Reference

Single tool: \`mcp__${PLUGIN_NAME}__${TOOL_NAME}\` with \`action\` parameter.

### List resources
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "list"
\`\`\`

### Get resource
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "get"
  id:     (required) Resource ID
\`\`\`

### Create resource
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "create"
  name:   (required) Resource name
  config: (optional) Configuration dict
\`\`\`

### Update resource
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action:    "update"
  id:        (required) Resource ID
  subaction: (optional) "enable" | "disable" | "reload"
  config:    (optional) New configuration
\`\`\`

### Delete resource — DESTRUCTIVE
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "delete"
  id:     (required) Resource ID
\`\`\`
Always confirm with user before executing.

### Search resources
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "search"
  query:  (required) Search query
\`\`\`

### Check status
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "status"
\`\`\`

### View logs
\`\`\`
mcp__${PLUGIN_NAME}__${TOOL_NAME}
  action: "logs"
\`\`\`

---

## HTTP Fallback Mode

\`\`\`bash
# List
curl -s "\$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_URL/api/v1/resources" \\
  -H "X-Api-Key: \$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_API_KEY"

# Create
curl -s -X POST "\$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_URL/api/v1/resources" \\
  -H "X-Api-Key: \$CLAUDE_PLUGIN_OPTION_${ENV_PREFIX}_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d "{\"name\":\"\$NAME\"}"
\`\`\`
EOFSKILL

# ── 11. CLAUDE.md ───────────────────────────────────────────────────────────

cat > "${OUT_DIR}/CLAUDE.md" <<EOFCLAUDE
# ${DISPLAY_NAME} MCP

MCP server plugin for ${DISPLAY_NAME} — action+subaction pattern, dual transport (HTTP/stdio),
bearer token auth, Docker Compose deployment.

## Quick Reference

- **Language**: ${LANG}
- **Default port**: ${PORT}
- **Env prefix**: \`${ENV_PREFIX}_*\` (service), \`${MCP_ENV_PREFIX}_*\` (MCP server)
- **Tool name**: \`${TOOL_NAME}\` (action+subaction pattern)

## Conventions

- All config via \`.env\` — no \`environment:\` block in docker-compose.yaml
- Bearer token auth required unless \`${MCP_ENV_PREFIX}_NO_AUTH=true\`
- \`/health\` endpoint is always unauthenticated
- Destructive operations require \`confirm=true\` or elicitation
- List responses include pagination metadata (\`items\`, \`total\`, \`limit\`, \`offset\`, \`has_more\`)

## Development

\`\`\`bash
just dev       # Start dev server
just test      # Run tests
just lint      # Run linter
just build     # Build Docker image
just up        # Start Docker container
just health    # Check health endpoint
just test-live # Run live integration tests
\`\`\`
EOFCLAUDE

# ── 12. AGENTS.md -> CLAUDE.md ──────────────────────────────────────────────

ln -sf CLAUDE.md "${OUT_DIR}/AGENTS.md"

# ── 13. GEMINI.md -> CLAUDE.md ──────────────────────────────────────────────

ln -sf CLAUDE.md "${OUT_DIR}/GEMINI.md"

# ── 14. README.md ───────────────────────────────────────────────────────────

cat > "${OUT_DIR}/README.md" <<EOFREADME
# ${PLUGIN_NAME}

MCP server plugin for [${DISPLAY_NAME}](https://${SERVICE}.example.com) — manage ${DISPLAY_NAME} resources
via Claude Code, Codex CLI, or HTTP API.

## Features

- Action+subaction tool pattern (single tool, multiple actions)
- Dual transport: HTTP (production) and stdio (development)
- Bearer token authentication
- Destructive operation confirmation gate
- Docker Compose deployment with healthcheck

## Quick Start

### 1. Install the plugin

\`\`\`bash
claude plugin add jmagar/${PLUGIN_NAME}
\`\`\`

### 2. Generate a bearer token

\`\`\`bash
openssl rand -hex 32
\`\`\`

Paste the token into the plugin's MCP token field when prompted.

### 3. Configure credentials

Enter your ${DISPLAY_NAME} URL and API key when prompted during plugin install.

### 4. Start the server

\`\`\`bash
cp .env.example .env
# Edit .env with your credentials
chmod 600 .env
docker compose up -d
\`\`\`

### 5. Verify

\`\`\`bash
curl http://localhost:${PORT}/health
\`\`\`

## Development

\`\`\`bash
just dev       # Start dev server
just test      # Run tests
just lint      # Run linter
just fmt       # Format code
just build     # Build Docker image
just up        # Start container
just health    # Check health
just test-live # Live integration tests
\`\`\`

## License

MIT
EOFREADME

# ── 15. CHANGELOG.md ────────────────────────────────────────────────────────

cat > "${OUT_DIR}/CHANGELOG.md" <<EOFCHANGELOG
# Changelog

## [1.0.0] - ${TODAY}

### Added
- Initial release
- Action+subaction tool pattern with help tool
- Bearer token authentication
- Dual transport support (HTTP + stdio)
- Docker Compose deployment
- SWAG reverse proxy config
- Live integration tests
EOFCHANGELOG

# ── 16. LICENSE ─────────────────────────────────────────────────────────────

cat > "${OUT_DIR}/LICENSE" <<EOFLICENSE
MIT License

Copyright (c) ${CURRENT_YEAR} Jacob Magar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOFLICENSE

# ── 17. .gitignore ──────────────────────────────────────────────────────────

# Build the language-specific section
GITIGNORE_PYTHON='# ── Python ────────────────────────────────────────────────────────────────
.venv/
__pycache__/
*.py[oc]
*.egg-info/
*.egg
dist/
build/
sdist/
wheels/
.hypothesis/
.pytest_cache/
.ruff_cache/
.ty_cache/
.mypy_cache/
.pytype/
.pyre/
.pyright/
htmlcov/
.coverage
.coverage.*
coverage.xml
.tox/
.nox/
pip-log.txt
pip-wheel-metadata/
*.whl'

GITIGNORE_TYPESCRIPT='# ── Node/TypeScript ────────────────────────────────────────────────────────
node_modules/
dist/
build/
out/
.next/
.nuxt/
coverage/
.nyc_output/
*.tsbuildinfo
.eslintcache
.stylelintcache
.parcel-cache/
.turbo/
.vercel/
*.js.map
*.d.ts.map'

GITIGNORE_RUST='# ── Rust ───────────────────────────────────────────────────────────────────
target/
*.db
**/*.rs.bk'

case "$LANG" in
  python)     LANG_GITIGNORE="$GITIGNORE_PYTHON" ;;
  typescript) LANG_GITIGNORE="$GITIGNORE_TYPESCRIPT" ;;
  rust)       LANG_GITIGNORE="$GITIGNORE_RUST" ;;
esac

cat > "${OUT_DIR}/.gitignore" <<EOFGITIGNORE
# ── Secrets ──────────────────────────────────────────────────────────────────
.env
.env.*
!.env.example

# ── Runtime / hook artifacts ─────────────────────────────────────────────────
backups/*
!backups/.gitkeep
logs/*
!logs/.gitkeep
*.log

# ── Claude Code / AI tooling ────────────────────────────────────────────────
.claude/settings.local.json
.claude/worktrees/
.omc/
.lavra/memory/session-state.md
.beads/
.serena/
.worktrees
.full-review/
.full-review-archive-*

# ── IDE / editor ─────────────────────────────────────────────────────────────
.vscode/
.cursor/
.windsurf/
.1code/

# ── Caches (ALL tool artifacts go here — see .cache Convention) ──────────────
.cache/

# ── Documentation artifacts (gitignore session/plan docs, keep reference) ───
docs/plans/
docs/sessions/
docs/reports/
docs/research/
docs/superpowers/

${LANG_GITIGNORE}
EOFGITIGNORE

# ── 18. .dockerignore ───────────────────────────────────────────────────────

DOCKERIGNORE_PYTHON='# ── Python ────────────────────────────────────────────────────────────────
.venv
__pycache__/
*.py[oc]
*.egg-info
dist/
.hypothesis/
.pytest_cache/
.ruff_cache/
.ty_cache/
htmlcov/
.coverage
coverage.xml'

DOCKERIGNORE_TYPESCRIPT='# ── Node/TypeScript ────────────────────────────────────────────────────────
node_modules/
dist/
coverage/
.husky/
.nvmrc
.prettierrc
.prettierignore
biome.json
tsconfig*.json
vitest.config.*
pnpm-lock.yaml
package-lock.json'

DOCKERIGNORE_RUST='# ── Rust ───────────────────────────────────────────────────────────────────
target/
Cargo.lock'

case "$LANG" in
  python)     LANG_DOCKERIGNORE="$DOCKERIGNORE_PYTHON" ;;
  typescript) LANG_DOCKERIGNORE="$DOCKERIGNORE_TYPESCRIPT" ;;
  rust)       LANG_DOCKERIGNORE="$DOCKERIGNORE_RUST" ;;
esac

cat > "${OUT_DIR}/.dockerignore" <<EOFDOCKERIGNORE
# ── Version control ──────────────────────────────────────────────────────────
.git
.github

# ── Secrets ──────────────────────────────────────────────────────────────────
.env
.env.*
!.env.example

# ── Claude Code / AI tooling ────────────────────────────────────────────────
.claude
.claude-plugin
.codex-plugin
.omc
.lavra
.beads
.serena
.worktrees
.full-review
.full-review-archive-*

# ── IDE / editor ─────────────────────────────────────────────────────────────
.vscode
.cursor
.windsurf
.1code

# ── Docs, tests, scripts (not needed at runtime) ────────────────────────────
docs
tests
scripts
*.md
!README.md

# ── Runtime artifacts ────────────────────────────────────────────────────────
logs
backups
*.log
.cache

${LANG_DOCKERIGNORE}
EOFDOCKERIGNORE

# ── 19. .env.example ────────────────────────────────────────────────────────

cat > "${OUT_DIR}/.env.example" <<EOFENVEX
# ── Service credentials (synced from Claude Code userConfig at SessionStart) ──
${ENV_PREFIX}_URL=https://your-${SERVICE}.example.com
${ENV_PREFIX}_API_KEY=your_api_key_here

# ── MCP server ───────────────────────────────────────────────────────────────
${MCP_ENV_PREFIX}_HOST=0.0.0.0
${MCP_ENV_PREFIX}_PORT=${PORT}
${MCP_ENV_PREFIX}_TRANSPORT=http          # "http" (default) or "stdio"
${MCP_ENV_PREFIX}_TOKEN=                  # required — generate with: openssl rand -hex 32
${MCP_ENV_PREFIX}_NO_AUTH=false           # true = disable bearer auth (proxy-managed only)
${MCP_ENV_PREFIX}_LOG_LEVEL=INFO

# ── Destructive operation safety ─────────────────────────────────────────────
${MCP_ENV_PREFIX}_ALLOW_YOLO=false        # true = skip elicitation prompts
${MCP_ENV_PREFIX}_ALLOW_DESTRUCTIVE=false # true = auto-confirm all destructive ops

# ── Docker ───────────────────────────────────────────────────────────────────
PUID=1000
PGID=1000
DOCKER_NETWORK=${DOCKER_NETWORK}
EOFENVEX

# ── 20. .pre-commit-config.yaml ─────────────────────────────────────────────

case "$LANG" in
  python)
    LANG_HOOKS='      - id: ruff
        name: ruff
        entry: uv run ruff check --fix
        language: system
        types: [python]
      - id: ruff-format
        name: ruff-format
        entry: uv run ruff format
        language: system
        types: [python]
      - id: ty
        name: ty
        entry: uv run ty check
        language: system
        types: [python]'
    ;;
  typescript)
    LANG_HOOKS='      - id: biome
        name: biome
        entry: npx biome check --write
        language: system
        types_or: [javascript, typescript, json]'
    ;;
  rust)
    LANG_HOOKS='      - id: cargo-fmt
        name: cargo-fmt
        entry: cargo fmt --check
        language: system
        types: [rust]
        pass_filenames: false
      - id: cargo-clippy
        name: cargo-clippy
        entry: cargo clippy -- -D warnings
        language: system
        types: [rust]
        pass_filenames: false'
    ;;
esac

cat > "${OUT_DIR}/.pre-commit-config.yaml" <<EOFPRECOMMIT
repos:
  - repo: local
    hooks:
${LANG_HOOKS}
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md\$'
      - id: docker-security
        name: docker-security
        entry: bash scripts/check-docker-security.sh
        language: system
        files: 'Dockerfile\$'
        pass_filenames: true
      - id: no-baked-env
        name: no-baked-env
        entry: bash scripts/check-no-baked-env.sh .
        language: system
        files: '(Dockerfile|docker-compose\.yaml|\.dockerignore|entrypoint\.sh)\$'
        pass_filenames: false
      - id: ensure-ignore-files
        name: ensure-ignore-files
        entry: bash scripts/ensure-ignore-files.sh --check .
        language: system
        files: '(\.gitignore|\.dockerignore)\$'
        pass_filenames: false
EOFPRECOMMIT

# ── 21. Justfile ────────────────────────────────────────────────────────────

case "$LANG" in
  python)
    JUST_DEV="uv run python -m ${MODULE_NAME}.server"
    JUST_TEST="uv run pytest"
    JUST_LINT="uv run ruff check . && uv run ty check"
    JUST_FMT="uv run ruff format ."
    JUST_TYPECHECK="uv run ty check"
    JUST_CLEAN='rm -rf .cache/ dist/ build/ __pycache__/ *.egg-info/'
    ;;
  typescript)
    JUST_DEV="npm run dev"
    JUST_TEST="npx vitest run"
    JUST_LINT="npx biome check ."
    JUST_FMT="npx biome format --write ."
    JUST_TYPECHECK="npx tsc --noEmit"
    JUST_CLEAN='rm -rf .cache/ dist/ node_modules/.cache/'
    ;;
  rust)
    JUST_DEV="cargo run"
    JUST_TEST="cargo test"
    JUST_LINT="cargo clippy -- -D warnings"
    JUST_FMT="cargo fmt"
    JUST_TYPECHECK="# covered by clippy"
    JUST_CLEAN='rm -rf .cache/ && cargo clean'
    ;;
esac

cat > "${OUT_DIR}/Justfile" <<EOFJUST
# Default recipe — show available commands
default:
    @just --list

# ── Development ──────────────────────────────────────────────────────────────

# Start the MCP server in dev mode
dev:
    ${JUST_DEV}

# Run tests
test:
    ${JUST_TEST}

# Run linter
lint:
    ${JUST_LINT}

# Format code
fmt:
    ${JUST_FMT}

# Type check
typecheck:
    ${JUST_TYPECHECK}

# Validate skills
validate-skills:
    npx skills-ref validate skills/

# ── Docker ───────────────────────────────────────────────────────────────────

# Build the Docker image
build:
    docker compose build

# Start the service
up:
    docker compose up -d

# Stop the service
down:
    docker compose down

# Restart the service
restart:
    docker compose restart

# View logs
logs *args='':
    docker compose logs -f {{ args }}

# ── Health & Testing ─────────────────────────────────────────────────────────

# Check service health
health:
    @curl -sf http://localhost:\${${MCP_ENV_PREFIX}_PORT:-${PORT}}/health | jq . || echo "UNHEALTHY"

# Run live integration tests (requires running server)
test-live:
    bash tests/test_live.sh

# ── Setup ────────────────────────────────────────────────────────────────────

# Create .env from .env.example if missing
setup:
    @[ -f .env ] || cp .env.example .env && chmod 600 .env && echo "Created .env from .env.example"

# Generate a bearer token
gen-token:
    @openssl rand -hex 32

# Check contract drift between schema, help tool, and skill docs
check-contract:
    bash scripts/lint-plugin.sh

# ── Cleanup ──────────────────────────────────────────────────────────────────

# Remove build artifacts and caches
clean:
    ${JUST_CLEAN}
EOFJUST

# ── 22. entrypoint.sh ───────────────────────────────────────────────────────

case "$LANG" in
  python)     EXEC_CMD="exec python3 -m ${MODULE_NAME}.server" ;;
  typescript) EXEC_CMD="exec node dist/index.js" ;;
  rust)       EXEC_CMD="exec ${PLUGIN_NAME}" ;;
esac

cat > "${OUT_DIR}/entrypoint.sh" <<EOFENTRY
#!/usr/bin/env bash
set -euo pipefail

echo "${PLUGIN_NAME}: initializing..."

# Validate required env vars
if [ -z "\${${ENV_PREFIX}_URL:-}" ]; then
    echo "Error: ${ENV_PREFIX}_URL is required" >&2
    exit 1
fi

if [ -z "\${${ENV_PREFIX}_API_KEY:-}" ]; then
    echo "Warning: ${ENV_PREFIX}_API_KEY not set — some functionality may be limited" >&2
fi

# Set defaults
export ${MCP_ENV_PREFIX}_HOST="\${${MCP_ENV_PREFIX}_HOST:-0.0.0.0}"
export ${MCP_ENV_PREFIX}_PORT="\${${MCP_ENV_PREFIX}_PORT:-${PORT}}"
export ${MCP_ENV_PREFIX}_TRANSPORT="\${${MCP_ENV_PREFIX}_TRANSPORT:-http}"

echo "${PLUGIN_NAME}: starting server (\${${MCP_ENV_PREFIX}_TRANSPORT} on \${${MCP_ENV_PREFIX}_HOST}:\${${MCP_ENV_PREFIX}_PORT})"

${EXEC_CMD}
EOFENTRY
chmod +x "${OUT_DIR}/entrypoint.sh"

# ── 23. Dockerfile ──────────────────────────────────────────────────────────

case "$LANG" in
  python)
    cat > "${OUT_DIR}/Dockerfile" <<EOFDOCKERFILE
# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────────────────────────
FROM python:3.13-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .

# ── Runtime stage ────────────────────────────────────────────────────────────
FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:\$PATH"

RUN mkdir -p /app/logs /app/backups
USER 1000:1000

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \\
    CMD wget -q --spider http://localhost:${PORT}/health || exit 1

COPY entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOFDOCKERFILE
    ;;
  typescript)
    cat > "${OUT_DIR}/Dockerfile" <<EOFDOCKERFILE
# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────────────────────────
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ── Runtime stage ────────────────────────────────────────────────────────────
FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist

RUN mkdir -p /app/logs /app/backups
USER 1000:1000

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \\
    CMD wget -q --spider http://localhost:${PORT}/health || exit 1

COPY entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOFDOCKERFILE
    ;;
  rust)
    cat > "${OUT_DIR}/Dockerfile" <<EOFDOCKERFILE
# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────────────────────────
FROM rust:1.86-slim-bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src
COPY src/ src/
RUN touch src/main.rs && cargo build --release

# ── Runtime stage ────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/${PLUGIN_NAME} /usr/local/bin/${PLUGIN_NAME}

RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home --shell /sbin/nologin app \\
    && mkdir -p /app/logs /app/backups /data && chown -R app:app /app /data
USER 1000:1000
WORKDIR /app

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \\
    CMD wget -q --spider http://localhost:${PORT}/health || exit 1

COPY entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOFDOCKERFILE
    ;;
esac

# ── 24. docker-compose.yaml ─────────────────────────────────────────────────

cat > "${OUT_DIR}/docker-compose.yaml" <<EOFCOMPOSE
services:
  ${PLUGIN_NAME}:
    build: .
    container_name: ${PLUGIN_NAME}
    restart: unless-stopped
    user: "\${PUID:-1000}:\${PGID:-1000}"
    env_file: .env
    # NOTE: No environment: block — all vars come from .env via env_file above.
    # Do NOT add environment: here. Put all variables in .env and .env.example.
    ports:
      - "\${${MCP_ENV_PREFIX}_PORT:-${PORT}}:${PORT}/tcp"
    volumes:
      - \${${MCP_ENV_PREFIX}_VOLUME:-${PLUGIN_NAME}-data}:/data
    networks:
      - proxy
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:${PORT}/health || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'

volumes:
  ${PLUGIN_NAME}-data:

networks:
  proxy:
    name: \${DOCKER_NETWORK:-${DOCKER_NETWORK}}
    external: true
EOFCOMPOSE

# ── 25. <service>.subdomain.conf ────────────────────────────────────────────

cat > "${OUT_DIR}/${SERVICE}.subdomain.conf" <<EOFSWAG
## Version ${TODAY} - MCP 2025-11-25 SWAG Compatible
# MCP Streamable-HTTP Reverse Proxy
# Service: ${SERVICE}
# Domain: ${SERVICE}.example.com
# Upstream: http://100.64.0.5:8080

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${SERVICE}.example.com;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # Service UI upstream (Tailscale IP of the host running the service)
    set \$upstream_app "100.64.0.5";
    set \$upstream_port "8080";
    set \$upstream_proto "http";

    # MCP server upstream (may be same host, different port)
    set \$mcp_upstream_app "100.64.0.5";
    set \$mcp_upstream_port "${PORT}";
    set \$mcp_upstream_proto "http";

    # DNS rebinding protection
    set \$origin_valid 0;
    if (\$http_origin = "") { set \$origin_valid 1; }
    if (\$http_origin = "https://\$server_name") { set \$origin_valid 1; }
    if (\$http_origin ~ "^https://(localhost|127\\.0\\.0\\.1)(:[0-9]+)?\$") { set \$origin_valid 1; }
    if (\$http_origin ~ "^https://(.*\\.)?anthropic\\.com\$") { set \$origin_valid 1; }
    if (\$http_origin ~ "^https://(.*\\.)?claude\\.ai\$") { set \$origin_valid 1; }

    add_header X-MCP-Version "2025-11-25" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Uncomment for auth provider (authelia, authentik, etc.)
    # include /config/nginx/authelia-server.conf;

    # OAuth 2.1: /_oauth_verify, /.well-known/*, /jwks, /register,
    #            /authorize, /token, /revoke, /callback, /success, error pages
    include /config/nginx/oauth.conf;

    location /mcp {
        if (\$origin_valid = 0) {
            add_header Content-Type "application/json" always;
            return 403 '{"error":"origin_not_allowed","message":"Origin header validation failed"}';
        }

        auth_request /_oauth_verify;
        auth_request_set \$auth_status \$upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;
        include /config/nginx/mcp.conf;

        proxy_pass \$mcp_upstream_proto://\$mcp_upstream_app:\$mcp_upstream_port;
    }

    location /health {
        include /config/nginx/resolver.conf;

        proxy_set_header Accept "application/json";
        proxy_set_header X-Health-Check "nginx-mcp-proxy";

        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;

        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;

        proxy_pass \$upstream_proto://\$upstream_app:\$upstream_port;
    }

    location ~* ^/(session|sessions) {
        auth_request /_oauth_verify;
        auth_request_set \$auth_status \$upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_set_header MCP-Protocol-Version \$http_mcp_protocol_version;
        proxy_set_header Mcp-Session-Id \$http_mcp_session_id;

        add_header Cache-Control "no-store" always;
        add_header Pragma "no-cache" always;

        proxy_pass \$mcp_upstream_proto://\$mcp_upstream_app:\$mcp_upstream_port;
    }

    location / {
        # Uncomment for auth provider
        # include /config/nginx/authelia-location.conf;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_pass \$upstream_proto://\$upstream_app:\$upstream_port;
    }
}
EOFSWAG

# ── 26. tests/test_live.sh ──────────────────────────────────────────────────

cat > "${OUT_DIR}/tests/test_live.sh" <<EOFTEST
#!/usr/bin/env bash
# tests/test_live.sh — Full live integration test for ${PLUGIN_NAME}
# Requires: mcporter, jq, running server at \$MCP_URL with \$${MCP_ENV_PREFIX}_TOKEN
set -euo pipefail

MCP_URL="\${${MCP_ENV_PREFIX}_URL:-http://localhost:${PORT}}"
TOKEN="\${${MCP_ENV_PREFIX}_TOKEN:?${MCP_ENV_PREFIX}_TOKEN must be set}"
SERVER_NAME="${PLUGIN_NAME}"
AUTH_HEADER="Authorization: Bearer \$TOKEN"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: \$1"; ((PASS++)); }
fail() { echo "  FAIL: \$1 — \$2"; ((FAIL++)); }
skip() { echo "  SKIP: \$1 — \$2"; ((SKIP++)); }

header() { echo; echo "=== \$1 ==="; }

# ── Health check ───────────────────────────────────────────────────────────
header "Health"

health=\$(curl -sf "\${MCP_URL}/health") && pass "health/endpoint" || fail "health/endpoint" "HTTP error"
echo "\$health" | jq -e '.status == "ok"' > /dev/null 2>&1 \\
  && pass "health/status-ok" || fail "health/status-ok" "\$(echo "\$health" | jq -r '.status')"

# ── Schema ─────────────────────────────────────────────────────────────────
header "Schema"

EXTERNAL_SCHEMA=\$(npx mcporter list "\$SERVER_NAME" --http-url "\$MCP_URL" \\
  --header "\$AUTH_HEADER" --json 2>/dev/null) || fail "schema/list" "mcporter list failed"

if echo "\$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "${TOOL_NAME}")' > /dev/null 2>&1; then
  pass "schema/tool-exists: ${TOOL_NAME}"
else
  fail "schema/tool-exists" "${TOOL_NAME} tool not found"
fi

if echo "\$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "${TOOL_NAME}_help")' > /dev/null 2>&1; then
  pass "schema/tool-exists: ${TOOL_NAME}_help"
else
  fail "schema/tool-exists" "${TOOL_NAME}_help tool not found"
fi

# ── Tool: list ─────────────────────────────────────────────────────────────
header "Tool: ${TOOL_NAME} — action=list"

result=\$(npx mcporter call "\${SERVER_NAME}.${TOOL_NAME}" \\
  --http-url "\$MCP_URL" --header "\$AUTH_HEADER" action=list 2>/dev/null) \\
  && pass "action/list" || fail "action/list" "call failed"

echo "\$result" | jq -e '
  has("items") and has("total") and has("limit") and has("offset") and has("has_more")
' > /dev/null 2>&1 \\
  && pass "action/list-pagination-shape" \\
  || fail "action/list-pagination-shape" "missing pagination metadata"

# ── Tool: status ───────────────────────────────────────────────────────────
header "Tool: ${TOOL_NAME} — action=status"

npx mcporter call "\${SERVER_NAME}.${TOOL_NAME}" \\
  --http-url "\$MCP_URL" --header "\$AUTH_HEADER" action=status > /dev/null 2>&1 \\
  && pass "action/status" || fail "action/status" "call failed"

# ── Help tool ──────────────────────────────────────────────────────────────
header "Tool: ${TOOL_NAME}_help"

HELP=\$(npx mcporter call "\${SERVER_NAME}.${TOOL_NAME}_help" \\
  --http-url "\$MCP_URL" --header "\$AUTH_HEADER" 2>/dev/null) \\
  && pass "help/overview" || fail "help/overview" "call failed"

printf '%s' "\$HELP" | grep -q "list" \\
  && pass "help/includes-list" || fail "help/includes-list" "list action missing"

printf '%s' "\$HELP" | grep -q "delete" \\
  && pass "help/includes-delete" || fail "help/includes-delete" "delete action missing"

printf '%s' "\$HELP" | grep -Eq "DESTRUCTIVE|destructive" \\
  && pass "help/marks-destructive" || fail "help/marks-destructive" "destructive marker missing"

# ── Bearer token enforcement ───────────────────────────────────────────────
header "Bearer token enforcement"

UNAUTH=\$(curl -s -o /dev/null -w "%{http_code}" "\${MCP_URL}/mcp" \\
  -X POST -H "Content-Type: application/json" -d '{}')
[ "\$UNAUTH" = "401" ] \\
  && pass "auth/unauthenticated-rejected" \\
  || fail "auth/unauthenticated-rejected" "expected 401, got \$UNAUTH"

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "Results: \$PASS passed, \$FAIL failed, \$SKIP skipped"
[ "\$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" && exit 0
echo "FAILURES DETECTED" && exit 1
EOFTEST
chmod +x "${OUT_DIR}/tests/test_live.sh"

# ── 27. backups/.gitkeep and logs/.gitkeep ──────────────────────────────────

touch "${OUT_DIR}/backups/.gitkeep"
touch "${OUT_DIR}/logs/.gitkeep"

# ── 28. scripts/ — copy from claude-homelab/scripts/ ────────────────────────

for script in check-docker-security.sh check-no-baked-env.sh ensure-ignore-files.sh; do
  src="${REPO_ROOT}/scripts/${script}"
  if [ -f "$src" ]; then
    cp "$src" "${OUT_DIR}/scripts/${script}"
    chmod +x "${OUT_DIR}/scripts/${script}"
  else
    echo "Warning: ${src} not found — creating stub" >&2
    cat > "${OUT_DIR}/scripts/${script}" <<EOFSTUB
#!/usr/bin/env bash
set -euo pipefail
echo "TODO: copy ${script} from claude-homelab/scripts/"
exit 0
EOFSTUB
    chmod +x "${OUT_DIR}/scripts/${script}"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────────────

FILE_COUNT=$(find "${OUT_DIR}" -type f | wc -l)
SYMLINK_COUNT=$(find "${OUT_DIR}" -type l | wc -l)

echo
echo "================================================================"
echo "  Plugin scaffolded: ${PLUGIN_NAME}"
echo "================================================================"
echo
echo "  Directory:   ${OUT_DIR}/"
echo "  Language:    ${LANG}"
echo "  Port:        ${PORT}"
echo "  Tool name:   ${TOOL_NAME}"
echo "  Env prefix:  ${ENV_PREFIX}_* / ${MCP_ENV_PREFIX}_*"
echo "  Network:     ${DOCKER_NETWORK}"
echo
echo "  Files created: ${FILE_COUNT}"
echo "  Symlinks:      ${SYMLINK_COUNT} (AGENTS.md, GEMINI.md)"
echo
echo "Directory structure:"
find "${OUT_DIR}" -type f -o -type l | sort | sed "s|^${OUT_DIR}/|  |"
echo
echo "Next steps:"
echo "  1. cd ${OUT_DIR}"
echo "  2. Initialize your ${LANG} project:"
case "$LANG" in
  python)
    echo "       uv init && uv add fastmcp"
    ;;
  typescript)
    echo "       npm init -y && npm install @modelcontextprotocol/sdk zod express"
    ;;
  rust)
    echo "       cargo init && cargo add rmcp serde serde_json tokio axum"
    ;;
esac
echo "  3. cp .env.example .env && chmod 600 .env"
echo "  4. Edit .env with your credentials"
echo "  5. Generate a bearer token: openssl rand -hex 32"
echo "  6. Implement your server in ${MODULE_NAME}/"
echo "  7. git init && git add -A && git commit -m 'feat: initial ${PLUGIN_NAME} scaffold'"
echo "  8. Validate: claude plugin validate ."
echo "  9. Test: just test-live"
echo " 10. Update ${SERVICE}.subdomain.conf with your Tailscale IPs and domain"
echo
