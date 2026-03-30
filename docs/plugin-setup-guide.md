# Claude Code Plugin Setup Guide

This guide documents the exact structure and conventions used for MCP-server-backed Claude Code plugins in this repo and its satellite repos (`gotify-mcp`, `overseerr-mcp`, `unifi-mcp`, `swag-mcp`).

---

## Overview

Each plugin lives **inside its MCP server repo**, not in this repo. The marketplace here points to those repos as sources. This means the plugin, the MCP server, and the Docker Compose stack all ship together — the plugin knows exactly how to reach the server, and the server knows exactly which `.env` it reads.

The plugin provides three things:
1. **`userConfig`** — prompts the user for credentials/URLs at install time
2. **`.mcp.json`** — wires the MCP server connection using those credentials
3. **`hooks/`** — syncs credentials to `.env` so Docker Compose can read them

---

## Directory Layout

Every plugin repo follows this structure:

```
repo-root/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest — name, version, userConfig
├── .mcp.json                # MCP server connection config
├── hooks/
│   ├── hooks.json           # Hook event wiring (SessionStart, PostToolUse)
│   └── scripts/
│       ├── sync-env.sh      # Syncs userConfig → .env on session start
│       ├── fix-env-perms.sh # Re-enforces chmod 600 when .env is touched
│       └── ensure-gitignore.sh  # Ensures .env and backups are gitignored
├── skills/
│   └── <service>/
│       └── SKILL.md         # Claude-facing skill definition
├── backups/
│   └── .gitkeep             # Gitignored backup dir (holds .env.bak.* files)
├── logs/
│   └── .gitkeep             # Gitignored log dir
├── .env                     # Runtime credentials — gitignored, chmod 600
├── .env.example             # Template — tracked in git, no real values
└── .gitignore               # Must include patterns listed below
```

---

## File-by-File Reference

### `.claude-plugin/plugin.json`

The plugin manifest. All four fields (`name`, `type`, `title`, `description`) are required by the validator — `type` and `title` are not mentioned in official docs but the validator enforces them.

```json
{
  "name": "my-service-mcp",
  "version": "1.0.0",
  "description": "One-line description of what this plugin does.",
  "author": {
    "name": "Your Name"
  },
  "repository": "https://github.com/you/my-service-mcp",
  "license": "MIT",
  "keywords": ["service", "homelab", "mcp"],
  "userConfig": {
    "my_service_mcp_url": {
      "type": "string",
      "title": "My Service MCP Server URL",
      "description": "URL of the MCP server. Default works if running locally via docker compose.",
      "default": "http://localhost:9000",
      "sensitive": false
    },
    "my_service_url": {
      "type": "string",
      "title": "My Service URL",
      "description": "Base URL of your service, e.g. https://service.example.com. No trailing slash.",
      "sensitive": true
    },
    "my_service_api_key": {
      "type": "string",
      "title": "My Service API Key",
      "description": "API key. Found in Settings → API.",
      "sensitive": true
    }
  }
}
```

**`userConfig` field rules:**
- `type` — required (`"string"` for all credential fields)
- `title` — required, shown in the install UI
- `description` — required, shown as help text
- `sensitive: true` — value stored encrypted; accessible **only** as `$CLAUDE_PLUGIN_OPTION_<KEY_UPPER>` in Bash subprocesses, NOT as `${user_config.*}` in skill content
- `sensitive: false` — value accessible as both `${user_config.key}` (in `.mcp.json`, skill content) and `$CLAUDE_PLUGIN_OPTION_<KEY_UPPER>` in Bash
- `default` — pre-fills the install prompt; only useful for non-sensitive fields
- Key naming: `snake_case`, prefixed with the service name for namespace clarity

**Environment variable mapping:**
`userConfig` key `my_service_api_key` → env var `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`

---

### `.mcp.json`

Wires Claude Code to the MCP server using streamable-http transport. The `url` field uses `${user_config.KEY}` substitution — this only works for `sensitive: false` fields.

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}/mcp"
    }
  }
}
```

**Notes:**
- The server name (key under `mcpServers`) must match the `name` in `plugin.json`
- The path `/mcp` is the FastMCP streamable-http endpoint — all our servers use this
- Only non-sensitive `userConfig` values can appear in `.mcp.json`. Sensitive values are not substituted here — they reach the server through `.env` via the sync hook

---

### `hooks/hooks.json`

Wraps hook scripts in the Claude Code hooks format. The wrapper object with `"description"` and `"hooks"` is required — bare hook arrays are not accepted.

```json
{
  "description": "Sync userConfig credentials to .env and enforce permissions",
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
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-gitignore.sh",
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
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-gitignore.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Available hook events:**
- `SessionStart` — fires once when Claude Code starts a session. Used for credential sync.
- `PostToolUse` — fires after each tool call matching `matcher`. Used to re-enforce `.env` permissions if any file-touching tool runs.

**`${CLAUDE_PLUGIN_ROOT}`** — env var set by Claude Code to the absolute path of the plugin directory (i.e., the repo root). Reliable in hook scripts. Do not use it in skill content.

---

### `hooks/scripts/sync-env.sh`

Runs at `SessionStart`. Reads `CLAUDE_PLUGIN_OPTION_*` vars (populated from `userConfig`) and writes them to `.env` in the repo root. This is how Docker Compose gets the credentials it needs.

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
BACKUP_DIR="${CLAUDE_PLUGIN_ROOT}/backups"
mkdir -p "$BACKUP_DIR"

declare -A MANAGED=(
  [MY_SERVICE_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL:-}"
  [MY_SERVICE_API_KEY]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY:-}"
  [MY_SERVICE_MCP_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_URL:-}"
)

touch "$ENV_FILE"

if [ -s "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${BACKUP_DIR}/.env.bak.$(date +%s)"
fi

for key in "${!MANAGED[@]}"; do
  value="${MANAGED[$key]}"
  [ -z "$value" ] && continue
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
done

chmod 600 "$ENV_FILE"

mapfile -t baks < <(ls -t "${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "${baks[@]}"; do
  chmod 600 "$bak"
done
for bak in "${baks[@]:3}"; do
  rm -f "$bak"
done
```

**Key rules:**
- Map `userConfig` key (e.g. `my_service_url`) → `.env` key (e.g. `MY_SERVICE_URL`) — the names in `.env` must match what Docker Compose and the server read
- Skip empty values (`[ -z "$value" ] && continue`) — avoids overwriting existing `.env` entries when a userConfig field isn't set
- Backup before every write, prune to 3 most recent, chmod 600 on all
- `.env` must be chmod 600 — enforced both here and in `fix-env-perms.sh`

---

### `hooks/scripts/fix-env-perms.sh`

Runs at `PostToolUse` when a file-touching tool is used. Reads stdin JSON from Claude Code to detect if `.env` was involved; if so, re-enforces `chmod 600`.

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
[ -f "$ENV_FILE" ] || exit 0

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
tool_input=$(echo "$input" | jq -r '.tool_input // {}')

touched_env=false

case "$tool_name" in
  Write|Edit|MultiEdit)
    file_path=$(echo "$tool_input" | jq -r '.file_path // ""')
    [[ "$file_path" == *".env"* ]] && touched_env=true
    ;;
  Bash)
    command=$(echo "$tool_input" | jq -r '.command // ""')
    [[ "$command" == *".env"* ]] && touched_env=true
    ;;
esac

if [ "$touched_env" = true ]; then
  chmod 600 "$ENV_FILE"
  for bak in "${CLAUDE_PLUGIN_ROOT}/backups"/.env.bak.*; do
    [ -f "$bak" ] && chmod 600 "$bak"
  done
fi
```

---

### `hooks/scripts/ensure-gitignore.sh`

Runs at both `SessionStart` and `PostToolUse`. Appends required gitignore patterns if missing. Ensures that even if `.gitignore` is created fresh or partially edited, credentials and backups will never be committed.

```bash
#!/usr/bin/env bash
set -euo pipefail

GITIGNORE="${CLAUDE_PLUGIN_ROOT}/.gitignore"

REQUIRED=(
  ".env"
  ".env.*"
  "!.env.example"
  "backups/*"
  "!backups/.gitkeep"
)

touch "$GITIGNORE"

for pattern in "${REQUIRED[@]}"; do
  if ! grep -qxF "$pattern" "$GITIGNORE" 2>/dev/null; then
    echo "$pattern" >> "$GITIGNORE"
  fi
done
```

**Why `!.env.example`:** The `.env.*` glob would otherwise silently gitignore `.env.example` on fresh clones, making the template invisible.

---

### `skills/<service>/SKILL.md`

Claude-facing skill definition. The frontmatter `description` is what Claude Code uses to decide when to invoke the skill. The body is the actual instructions Claude follows.

**Structure:**
```markdown
---
name: my-service
description: Trigger phrases and keywords that activate this skill...
---

# My Service Skill

## Mode Detection

**MCP mode** (preferred): Use when `mcp__my-service-mcp__*` tools are available.

**HTTP fallback**: Use when MCP tools are not loaded. Credentials available as
`$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL` and `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`
in Bash subprocesses.

**MCP URL**: `${user_config.my_service_mcp_url}`

---

## MCP Mode — Tool Reference

### Tool Name
\`\`\`
mcp__my-service-mcp__tool_name
  param1  (required) Description
  param2  (optional) Description — default X
\`\`\`

---

## HTTP Fallback Mode

\`\`\`bash
curl -s "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/endpoint" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY"
\`\`\`
```

**Critical rules:**
- Sensitive `userConfig` values are **not** available as `${user_config.*}` in skill content — only as `$CLAUDE_PLUGIN_OPTION_*` in Bash subprocesses. Never write `${user_config.my_service_api_key}` in a curl command.
- Non-sensitive values (e.g. `my_service_mcp_url`) are available as both `${user_config.my_service_mcp_url}` and `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_URL`.
- The MCP tool prefix is always `mcp__<plugin-name>__<tool-name>`.

---

### `.gitignore` Required Patterns

Every plugin repo must have these in `.gitignore`:

```
.env
.env.*
!.env.example
backups/*
!backups/.gitkeep
logs/*
!logs/.gitkeep
```

The `ensure-gitignore.sh` hook enforces the `.env` and `backups/` patterns automatically, but `logs/` should be present from the start.

---

### `.env.example`

Tracked in git. Contains all keys with placeholder values — no real credentials. Used as the template for `.env`.

```bash
# My Service MCP Server Configuration

MY_SERVICE_URL=https://your-service.example.com
MY_SERVICE_API_KEY=your_api_key_here

# MCP Server
MY_SERVICE_MCP_PORT=9000
MY_SERVICE_MCP_TRANSPORT=streamable-http
LOG_LEVEL=INFO
```

---

## Marketplace Registration (`marketplace.json`)

Plugins hosted in external repos use the GitHub source format:

```json
{
  "name": "my-service-mcp",
  "source": {
    "source": "github",
    "repo": "jmagar/my-service-mcp"
  },
  "description": "One-line description. Requires my-service-mcp MCP server running.",
  "version": "1.0.0",
  "category": "media",
  "tags": ["my-service", "homelab", "mcp"],
  "homepage": "https://github.com/jmagar/my-service-mcp"
}
```

Plugins shipped inside this repo use a local path:

```json
{
  "name": "my-local-plugin",
  "source": "./service-plugins/my-local-plugin",
  ...
}
```

**Current MCP server plugins in marketplace:**

| Plugin | Source Repo | Category | Default Port |
|--------|-------------|----------|--------------|
| `gotify-mcp` | `jmagar/gotify-mcp` | utilities | 9158 |
| `overseerr-mcp` | `jmagar/overseerr-mcp` | media | 6975 |
| `unifi-mcp` | `jmagar/unifi-mcp` | infrastructure | 8001 |
| `swag-mcp` | `jmagar/swag-mcp` | infrastructure | 8000 |

---

## Validation

Before committing a plugin, validate it with:

```bash
cd /path/to/repo
claude plugin validate .
```

Common validation errors and fixes:

| Error | Fix |
|-------|-----|
| `userConfig.*.type: Invalid option` | Add `"type": "string"` to the field — required but undocumented |
| `userConfig.*.title: Invalid input` | Add `"title": "..."` to the field — required but undocumented |
| Hook format rejected | Wrap hooks in `{"description": "...", "hooks": {...}}` — bare arrays not accepted |

---

## How Credentials Flow

```
User installs plugin
        ↓
Claude Code prompts for userConfig values
        ↓
Values stored encrypted in Claude Code's credential store
        ↓
SessionStart fires → sync-env.sh runs
        ↓
CLAUDE_PLUGIN_OPTION_* vars → written to .env (chmod 600)
        ↓
Docker Compose reads .env → passes vars to container
        ↓
MCP server reads env vars → connects to service
        ↓
.mcp.json wires Claude Code → MCP server (via non-sensitive URL from userConfig)
        ↓
Claude Code calls MCP tools → server proxies to service
```

**Fallback path (MCP server not running):**
```
CLAUDE_PLUGIN_OPTION_* vars in Bash subprocess
        ↓
curl commands in SKILL.md HTTP fallback section
```

---

## Adding a New Plugin (Checklist)

1. **Create `.claude-plugin/plugin.json`** — include `type`, `title`, `description`, `sensitive` on every `userConfig` field
2. **Create `.mcp.json`** — point to `${user_config.<service>_mcp_url}/mcp`
3. **Create `hooks/hooks.json`** — use the standard SessionStart + PostToolUse structure
4. **Create `hooks/scripts/sync-env.sh`** — map `CLAUDE_PLUGIN_OPTION_*` vars to `.env` key names matching what Docker Compose expects
5. **Copy `hooks/scripts/fix-env-perms.sh`** — identical across all plugins
6. **Copy `hooks/scripts/ensure-gitignore.sh`** — identical across all plugins
7. **Create `skills/<service>/SKILL.md`** — dual-mode: MCP preferred, HTTP fallback
8. **Create `backups/.gitkeep` and `logs/.gitkeep`**
9. **Update `.gitignore`** — add `.env`, `.env.*`, `!.env.example`, `backups/*`, `!backups/.gitkeep`, `logs/*`, `!logs/.gitkeep`
10. **Run `claude plugin validate .`** — must pass with zero errors
11. **Add entry to `marketplace.json`** on dookie with GitHub source format
