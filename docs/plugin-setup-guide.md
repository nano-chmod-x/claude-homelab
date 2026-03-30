# Claude Code Plugin Setup Guide

This guide documents the exact structure, conventions, and standards for all MCP-server-backed
Claude Code plugins in this ecosystem (`gotify-mcp`, `overseerr-mcp`, `unifi-mcp`, `swag-mcp`,
and any future additions).

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Directory Layout](#directory-layout)
3. [HTTP Security — Bearer Tokens](#http-security--bearer-tokens)
4. [Tool Design — Action + Subaction Pattern](#tool-design--action--subaction-pattern)
5. [File-by-File Reference](#file-by-file-reference)
   - [plugin.json](#claudepluginpluginjson)
   - [.mcp.json](#mcpjson)
   - [hooks/hooks.json](#hookshooksjson)
   - [hooks/scripts/sync-env.sh](#hooksscriptssync-envsh)
   - [hooks/scripts/fix-env-perms.sh](#hooksscriptsfix-env-permssh)
   - [hooks/scripts/ensure-gitignore.sh](#hooksscriptsensure-gitignore-sh)
   - [skills/SKILL.md](#skillsskillmd)
   - [.gitignore](#gitignore)
   - [.env.example](#envexample)
6. [Marketplace Registration](#marketplace-registration)
7. [Testing with mcporter](#testing-with-mcporter)
8. [Validation Checklist](#validation-checklist)
9. [Credential Flow Diagram](#credential-flow-diagram)
10. [Adding a New Plugin](#adding-a-new-plugin)

---

## Architecture Overview

Each plugin lives **inside its MCP server repo**, not in this repo. The marketplace here points
to those repos as sources. Plugin, MCP server, and Docker Compose stack all ship together.

The plugin provides three things:
1. **`userConfig`** — prompts the user for credentials/URLs at install time
2. **`.mcp.json`** — wires the MCP server connection using those credentials
3. **`hooks/`** — syncs credentials to `.env` so Docker Compose can read them

```
Claude Code plugin install
    → userConfig prompts
    → credentials stored encrypted
    → SessionStart hook → .env written
    → Docker Compose reads .env
    → MCP server starts, reads env vars
    → .mcp.json connects Claude Code → MCP server
    → Claude Code calls tools
```

---

## Directory Layout

```
repo-root/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest — name, version, userConfig
├── .mcp.json                    # MCP server connection config
├── hooks/
│   ├── hooks.json               # Hook event wiring (SessionStart, PostToolUse)
│   └── scripts/
│       ├── sync-env.sh          # Syncs userConfig → .env on session start
│       ├── fix-env-perms.sh     # Re-enforces chmod 600 when .env is touched
│       └── ensure-gitignore.sh  # Ensures .env and backups are gitignored
├── skills/
│   └── <service>/
│       └── SKILL.md             # Claude-facing skill definition
├── tests/
│   └── test_live.sh             # Full end-to-end live test (mcporter-based)
├── backups/
│   └── .gitkeep                 # Gitignored — holds .env.bak.* files
├── logs/
│   └── .gitkeep                 # Gitignored — holds server log files
├── <service>_mcp/               # Python package
│   ├── __init__.py
│   ├── server.py                # FastMCP server — action+subaction pattern
│   └── client.py                # Service API client
├── .env                         # Runtime credentials — gitignored, chmod 600
├── .env.example                 # Template — tracked in git, no real values
├── .gitignore                   # Must include patterns listed below
├── pyproject.toml               # uv-managed, entry point to server:main
├── Dockerfile                   # uv-based, multi-stage
└── docker-compose.yaml
```

---

## HTTP Security — Bearer Tokens

All MCP servers **must** use HTTP bearer token authentication by default. The only exception is
when a `NO_HTTP_AUTH` env var is set — for deployments where auth is handled at the proxy/gateway
level (e.g. SWAG with Authelia, a router with ACLs, Tailscale).

### Required environment variables

| Variable | Purpose |
|---|---|
| `MCP_BEARER_TOKEN` | The bearer token the server validates on all requests. Required unless `NO_HTTP_AUTH=true`. |
| `NO_HTTP_AUTH` | Set to `true` to disable bearer token enforcement entirely. Default: unset (auth enforced). |

### Token generation

If `MCP_BEARER_TOKEN` is not set and `NO_HTTP_AUTH` is not `true`, the server **must fail to
start** with a clear error message:

```
CRITICAL: MCP_BEARER_TOKEN is not set.
Set MCP_BEARER_TOKEN to a secure random token, or set NO_HTTP_AUTH=true to disable auth
(only appropriate when secured at the network/proxy level).

Generate a token with: openssl rand -hex 32
```

The `sync-env.sh` hook generates a token automatically if one is not present in `.env`:

```bash
# In sync-env.sh, after writing userConfig values:
if ! grep -q "^MCP_BEARER_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  generated=$(openssl rand -hex 32)
  echo "MCP_BEARER_TOKEN=${generated}" >> "$ENV_FILE"
fi
```

### FastMCP bearer token enforcement

```python
import os
import sys
from fastmcp import FastMCP
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

BEARER_TOKEN = os.getenv("MCP_BEARER_TOKEN")
NO_HTTP_AUTH = os.getenv("NO_HTTP_AUTH", "").lower() in ("true", "1", "yes")

if not NO_HTTP_AUTH and not BEARER_TOKEN:
    print(
        "CRITICAL: MCP_BEARER_TOKEN is not set.\n"
        "Set MCP_BEARER_TOKEN to a secure random token, or set NO_HTTP_AUTH=true\n"
        "to disable auth (only appropriate when secured at the network/proxy level).\n\n"
        "Generate a token with: openssl rand -hex 32",
        file=sys.stderr,
    )
    sys.exit(1)

class BearerAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if NO_HTTP_AUTH:
            return await call_next(request)
        if request.url.path in ("/health",):
            return await call_next(request)
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer ") or auth[7:] != BEARER_TOKEN:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)

mcp = FastMCP(name="MyServiceMCP", ...)
mcp.app.add_middleware(BearerAuthMiddleware)
```

### `.mcp.json` — passing the token

The bearer token must be passed from `userConfig` to the MCP connection headers. Since
`MCP_BEARER_TOKEN` is synced to `.env` (sensitive), it is also exposed as
`CLAUDE_PLUGIN_OPTION_MCP_BEARER_TOKEN`. However, `.mcp.json` only supports
`${user_config.*}` substitution — so the token must be a `userConfig` field:

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}/mcp",
      "headers": {
        "Authorization": "Bearer ${user_config.my_service_mcp_token}"
      }
    }
  }
}
```

Add `my_service_mcp_token` to `userConfig` in `plugin.json`:

```json
"my_service_mcp_token": {
  "type": "string",
  "title": "MCP Server Bearer Token",
  "description": "Bearer token for authenticating with the MCP server. Must match MCP_BEARER_TOKEN in the server's .env. Generate with: openssl rand -hex 32",
  "sensitive": true
}
```

The `sync-env.sh` hook maps this to `MCP_BEARER_TOKEN` in `.env`.

---

## Tool Design — Action + Subaction Pattern

All MCP servers must expose a **single tool per domain** that uses `action` + optional `subaction`
parameters. This minimises token usage (fewer tool definitions in context) while preserving full
functionality.

### Why

- Claude Code loads all tool definitions into context on every request
- 20 individual tools × 500 tokens each = 10,000 tokens of tool overhead per call
- 1 tool with 20 actions = ~800 tokens total — ~12× improvement
- Subactions further group related operations without new top-level tokens

### Pattern

```python
from typing import Literal, Optional
from fastmcp import FastMCP, Context

mcp = FastMCP(name="MyServiceMCP")

@mcp.tool()
async def my_service(
    ctx: Context,
    action: Literal[
        "list", "get", "create", "update", "delete",
        "search", "status", "logs"
    ],
    # Subaction for actions that have sub-operations
    subaction: Optional[Literal["enable", "disable", "reload"]] = None,
    # Shared parameters — provide only what the action needs
    id: Optional[str] = None,
    name: Optional[str] = None,
    query: Optional[str] = None,
    config: Optional[dict] = None,
) -> dict | list | str:
    """Interact with My Service.

    Actions:
      list     — list all resources
      get      — get resource by id
      create   — create new resource (requires name, config)
      update   — update resource (requires id, config)
      delete   — delete resource by id (destructive — confirm first)
      search   — search resources by query
      status   — check service health
      logs     — tail recent log lines

    Subactions (for action=update):
      enable   — enable the resource
      disable  — disable the resource
      reload   — reload resource config
    """
    match action:
        case "list":
            return await _list_resources(ctx)
        case "get":
            return await _get_resource(ctx, id)
        case "create":
            return await _create_resource(ctx, name, config)
        case "update":
            return await _update_resource(ctx, id, subaction, config)
        case "delete":
            return await _delete_resource(ctx, id)
        case "search":
            return await _search_resources(ctx, query)
        case "status":
            return await _get_status(ctx)
        case "logs":
            return await _get_logs(ctx)
        case _:
            return f"Unknown action: {action}"
```

### SKILL.md tool reference format for action+subaction tools

```
mcp__my-service-mcp__my_service
  action:     (required) "list" | "get" | "create" | "update" | "delete" | "search" | "status" | "logs"
  subaction:  (optional, for action=update) "enable" | "disable" | "reload"
  id:         (required for get, update, delete) Resource ID
  name:       (required for create) Resource name
  query:      (required for search) Search query
  config:     (optional) Configuration dict
```

---

## File-by-File Reference

### `.claude-plugin/plugin.json`

**The `userConfig` block is the canonical source of truth for all plugin configuration.**
Every environment variable the Docker Compose service and MCP server need must be declared as a
`userConfig` field. There is no other mechanism for getting values into `.env` — `sync-env.sh`
reads exclusively from `CLAUDE_PLUGIN_OPTION_*` vars, which are populated exclusively from
`userConfig`. If a required env var is not in `userConfig`, it will never reach the container.

`userConfig` must cover at minimum:
- **MCP server URL** — so `.mcp.json` can connect (`sensitive: false`)
- **MCP bearer token** — so `.mcp.json` can authenticate (`sensitive: false`)
- **Service URL / host** — base URL of the proxied service (`sensitive: true`)
- **Service credentials** — API key, password, token, or whatever the service requires (`sensitive: true`)
- **Any other required env vars** — ports, log levels, feature flags (`sensitive` as appropriate)

All four fields (`name`, `type`, `title`, `description`) are required by the validator on every
`userConfig` entry. `type` and `title` are not in official docs but the validator enforces them.
Use all available metadata fields.

```json
{
  "name": "my-service-mcp",
  "version": "1.0.0",
  "description": "One-line description of what this plugin does.",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "repository": "https://github.com/jmagar/my-service-mcp",
  "homepage": "https://github.com/jmagar/my-service-mcp",
  "license": "MIT",
  "keywords": ["my-service", "homelab", "mcp"],
  "userConfig": {
    "my_service_mcp_url": {
      "type": "string",
      "title": "My Service MCP Server URL",
      "description": "URL of the MCP server. Default works if running locally via docker compose.",
      "default": "http://localhost:9000",
      "sensitive": false
    },
    "my_service_mcp_token": {
      "type": "string",
      "title": "MCP Server Bearer Token",
      "description": "Bearer token for authenticating with the MCP server. Must match MCP_BEARER_TOKEN in .env. Generate with: openssl rand -hex 32",
      "sensitive": true
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

| Field | Required | Notes |
|---|---|---|
| `type` | Yes | Always `"string"` — validator requires it, docs omit it |
| `title` | Yes | Shown in install UI — validator requires it, docs omit it |
| `description` | Yes | Help text at install prompt |
| `sensitive` | Yes | `true` = encrypted, accessible only as `$CLAUDE_PLUGIN_OPTION_*` in Bash, NOT as `${user_config.*}` in skill content or `.mcp.json` |
| `default` | Recommended | Pre-fills install prompt; only meaningful for non-sensitive fields |

**Env var mapping:** `my_service_api_key` → `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`

---

### `.mcp.json`

Streamable-http transport with bearer auth header. Only non-sensitive `userConfig` values support
`${user_config.*}` substitution here.

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}/mcp",
      "headers": {
        "Authorization": "Bearer ${user_config.my_service_mcp_token}"
      }
    }
  }
}
```

Wait — `my_service_mcp_token` is `sensitive: true` above, which means `${user_config.*}` won't
work for it in `.mcp.json`. **Resolution:** make `my_service_mcp_token` `sensitive: false` in
`plugin.json`. It's not a service credential — it's an MCP transport credential, and it only
provides access to the local MCP server (which itself holds the real service credentials).
The token is still protected in `.env` at `chmod 600`.

---

### `hooks/hooks.json`

The wrapper object with `"description"` and `"hooks"` is required. Bare arrays are rejected.

```json
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

`${CLAUDE_PLUGIN_ROOT}` — set by Claude Code to the repo root. Reliable in hook scripts only.

---

### `hooks/scripts/sync-env.sh`

Runs at `SessionStart`. Maps `CLAUDE_PLUGIN_OPTION_*` → `.env` keys. Generates
`MCP_BEARER_TOKEN` if absent. Keeps max 3 backups, all chmod 600.

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
  [MCP_BEARER_TOKEN]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN:-}"
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

# Auto-generate MCP_BEARER_TOKEN if not yet set
if ! grep -q "^MCP_BEARER_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  generated=$(openssl rand -hex 32)
  echo "MCP_BEARER_TOKEN=${generated}" >> "$ENV_FILE"
  echo "sync-env: generated MCP_BEARER_TOKEN (update plugin userConfig to match)" >&2
fi

chmod 600 "$ENV_FILE"

mapfile -t baks < <(ls -t "${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "${baks[@]}"; do chmod 600 "$bak"; done
for bak in "${baks[@]:3}"; do rm -f "$bak"; done
```

**Key rules:**
- Map each userConfig key → the `.env` key Docker Compose and the server read
- Skip empty values — avoids clobbering existing `.env` when a field isn't filled in
- Auto-generate `MCP_BEARER_TOKEN` if absent — users who don't fill in the token field still get a secure default
- Backup before every write, prune to 3 most recent, chmod 600 on all

---

### `hooks/scripts/fix-env-perms.sh`

Identical across all plugins. Re-enforces chmod 600 on `.env` and backups whenever a file-touching
tool runs that might have touched `.env`.

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

Identical across all plugins. Appends required gitignore patterns if missing. Runs at both
`SessionStart` and `PostToolUse`.

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

Why `!.env.example`: the `.env.*` glob silently gitignores `.env.example` on fresh clones without it.

---

### `skills/<service>/SKILL.md`

Dual-mode: MCP preferred, HTTP fallback. The `description` frontmatter is what Claude Code uses
to decide when to activate the skill — make it exhaustive.

```markdown
---
name: my-service
description: Activate when user says "list resources", "get resource", "create X",
  "delete X", "check status", or mentions My Service or its domain keywords.
---

# My Service Skill

## Mode Detection

**MCP mode** (preferred): Use when `mcp__my-service-mcp__my_service` tool is available.

**HTTP fallback**: Use when MCP tools are unavailable. Credentials are in Bash subprocesses
as `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL` and `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`.
Do NOT attempt `${user_config.my_service_api_key}` in curl — sensitive values only work
as `$CLAUDE_PLUGIN_OPTION_*` in Bash subprocesses.

**MCP URL**: `${user_config.my_service_mcp_url}`

---

## MCP Mode — Tool Reference

Single tool: `mcp__my-service-mcp__my_service` with `action` parameter.

### List resources
\`\`\`
mcp__my-service-mcp__my_service
  action: "list"
\`\`\`

### Get resource
\`\`\`
mcp__my-service-mcp__my_service
  action: "get"
  id:     (required) Resource ID
\`\`\`

### Create resource
\`\`\`
mcp__my-service-mcp__my_service
  action: "create"
  name:   (required) Resource name
  config: (optional) Configuration dict
\`\`\`

### Update resource
\`\`\`
mcp__my-service-mcp__my_service
  action:    "update"
  id:        (required) Resource ID
  subaction: (optional) "enable" | "disable" | "reload"
  config:    (optional) New configuration
\`\`\`

### Delete resource — DESTRUCTIVE
\`\`\`
mcp__my-service-mcp__my_service
  action: "delete"
  id:     (required) Resource ID
\`\`\`
Always confirm with user before executing.

---

## HTTP Fallback Mode

\`\`\`bash
# List
curl -s "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY"

# Create
curl -s -X POST "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$NAME\"}"
\`\`\`
```

---

### `.gitignore`

Required patterns in every plugin repo:

```
.env
.env.*
!.env.example
backups/*
!backups/.gitkeep
logs/*
!logs/.gitkeep
```

The `ensure-gitignore.sh` hook enforces `.env` and `backups/` patterns automatically at runtime,
but these must be present from the initial commit.

---

### `.env.example`

Tracked in git. All keys with placeholder values — no real credentials.

```bash
# My Service MCP Configuration

# Service credentials (synced from Claude Code userConfig at SessionStart)
MY_SERVICE_URL=https://your-service.example.com
MY_SERVICE_API_KEY=your_api_key_here

# MCP server
MY_SERVICE_MCP_PORT=9000
MY_SERVICE_MCP_TRANSPORT=streamable-http
LOG_LEVEL=INFO

# HTTP auth — set by sync-env.sh from userConfig, or auto-generated if absent
MCP_BEARER_TOKEN=

# Set to true to disable bearer token enforcement (use only when secured at proxy/gateway level)
NO_HTTP_AUTH=false
```

---

## Marketplace Registration

Plugins in external repos use the GitHub source format. Use all available metadata fields.

```json
{
  "name": "my-service-mcp",
  "source": {
    "source": "github",
    "repo": "jmagar/my-service-mcp"
  },
  "description": "Manage My Service via MCP tools with HTTP fallback. Requires my-service-mcp MCP server running.",
  "version": "1.0.0",
  "category": "infrastructure",
  "tags": ["my-service", "homelab", "mcp"],
  "homepage": "https://github.com/jmagar/my-service-mcp"
}
```

Plugins shipped inside this repo use local path source:

```json
{
  "name": "my-local-plugin",
  "source": "./service-plugins/my-local-plugin",
  ...
}
```

**Current MCP server plugins:**

| Plugin | Repo | Category | Default Port | Bearer Token userConfig key |
|--------|------|----------|--------------|-----------------------------|
| `gotify-mcp` | `jmagar/gotify-mcp` | utilities | 9158 | `gotify_mcp_token` |
| `overseerr-mcp` | `jmagar/overseerr-mcp` | media | 6975 | `overseerr_mcp_token` |
| `unifi-mcp` | `jmagar/unifi-mcp` | infrastructure | 8001 | `unifi_mcp_token` |
| `swag-mcp` | `jmagar/swag-mcp` | infrastructure | 8000 | `swag_mcp_token` |

---

## Testing with mcporter

[mcporter](https://github.com/steipete/mcporter) is the primary testing tool for all MCP servers.
It lets you call tools, compare schemas, and generate CLIs — all without spending tokens.

### Install

```bash
npm install -g mcporter
# or via npx (no install)
npx mcporter list
```

### Each server must have a `tests/test_live.sh`

This script performs a full end-to-end live test of every tool, action, subaction, and resource.
It must run against a live server instance (not mocked).

```bash
#!/usr/bin/env bash
# tests/test_live.sh — Full live integration test for my-service-mcp
# Requires: mcporter, jq, running server at $MCP_URL with $MCP_BEARER_TOKEN
set -euo pipefail

MCP_URL="${MY_SERVICE_MCP_URL:-http://localhost:9000}"
TOKEN="${MCP_BEARER_TOKEN:-}"
SERVER_NAME="my-service-mcp"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)); }
skip() { echo "  SKIP: $1 — $2"; ((SKIP++)); }

header() { echo; echo "=== $1 ==="; }

# ── Schema comparison ──────────────────────────────────────────────────────────
header "Schema: external vs internal"

EXTERNAL_SCHEMA=$(npx mcporter list "$SERVER_NAME" --http-url "$MCP_URL" \
  --json 2>/dev/null) || fail "schema/list" "mcporter list failed"

TOOL_COUNT=$(echo "$EXTERNAL_SCHEMA" | jq '.tools | length' 2>/dev/null || echo 0)
echo "  Tools exposed: $TOOL_COUNT"

# Verify expected tool exists and has expected actions in schema
if echo "$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "my_service")' > /dev/null 2>&1; then
  pass "schema/tool-exists: my_service"
else
  fail "schema/tool-exists" "my_service tool not found in external schema"
fi

# ── Health check ───────────────────────────────────────────────────────────────
header "Health"

health=$(curl -sf "${MCP_URL}/health") && pass "health/endpoint" || fail "health/endpoint" "HTTP error"
echo "$health" | jq -e '.status == "ok"' > /dev/null 2>&1 \
  && pass "health/status-ok" || fail "health/status-ok" "$(echo "$health" | jq -r '.status')"

# ── Tools: all actions ─────────────────────────────────────────────────────────
header "Tool: my_service — action=list"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" action=list 2>/dev/null) \
  && pass "action/list" || fail "action/list" "call failed"

header "Tool: my_service — action=status"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" action=status 2>/dev/null) \
  && pass "action/status" || fail "action/status" "call failed"

header "Tool: my_service — action=create + get + update + delete (lifecycle)"

CREATE=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" action=create name=test-resource 2>/dev/null)
CREATED_ID=$(echo "$CREATE" | jq -r '.id // empty')

if [ -n "$CREATED_ID" ]; then
  pass "action/create"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" action=get "id=$CREATED_ID" > /dev/null 2>&1 \
    && pass "action/get" || fail "action/get" "failed for id=$CREATED_ID"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" action=update "id=$CREATED_ID" subaction=enable > /dev/null 2>&1 \
    && pass "action/update/enable" || fail "action/update/enable" "failed"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" action=delete "id=$CREATED_ID" > /dev/null 2>&1 \
    && pass "action/delete" || fail "action/delete" "failed"
else
  fail "action/create" "no id in response: $CREATE"
  skip "action/get" "create failed"
  skip "action/update/enable" "create failed"
  skip "action/delete" "create failed"
fi

header "Tool: my_service — action=search"

npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" action=search query=test > /dev/null 2>&1 \
  && pass "action/search" || fail "action/search" "call failed"

# ── Resources ─────────────────────────────────────────────────────────────────
header "Resources"

npx mcporter call "${SERVER_NAME}" --http-url "$MCP_URL" \
  --list-resources > /dev/null 2>&1 \
  && pass "resources/list" || skip "resources/list" "no resources defined"

# ── CLI generation ─────────────────────────────────────────────────────────────
header "CLI generation"

CLI_OUT=$(mktemp -d)
npx mcporter generate-cli \
  --server "$SERVER_NAME" \
  --command "$MCP_URL" \
  --name "my-service-cli" \
  --bundle \
  > /dev/null 2>&1 \
  && pass "cli/generate" || fail "cli/generate" "mcporter generate-cli failed"

# ── Auth ───────────────────────────────────────────────────────────────────────
header "Bearer token enforcement"

UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "${MCP_URL}/mcp" \
  -X POST -H "Content-Type: application/json" -d '{}')
[ "$UNAUTH" = "401" ] \
  && pass "auth/unauthenticated-rejected" \
  || fail "auth/unauthenticated-rejected" "expected 401, got $UNAUTH"

# ── Summary ────────────────────────────────────────────────────────────────────
echo
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" && exit 0
echo "FAILURES DETECTED" && exit 1
```

### Schema comparison workflow

```bash
# Export external schema (what the live server reports)
npx mcporter list my-service-mcp --http-url http://localhost:9000 \
  --json > /tmp/external-schema.json

# Diff against your internal schema definition
# (your pyproject.toml, FastMCP tool decorators define the internal schema)
python3 - << 'EOF'
import json

with open("/tmp/external-schema.json") as f:
    external = json.load(f)

# Expected tools and their required actions
EXPECTED = {
    "my_service": {
        "actions": ["list", "get", "create", "update", "delete", "search", "status", "logs"],
        "subactions": {"update": ["enable", "disable", "reload"]},
    }
}

for tool_name, spec in EXPECTED.items():
    tool = next((t for t in external.get("tools", []) if t["name"] == tool_name), None)
    if not tool:
        print(f"MISSING TOOL: {tool_name}")
        continue
    print(f"OK: {tool_name} found")
    # Further schema validation...
EOF
```

### Generate CLI for a running server

```bash
# Generate and bundle a standalone CLI
npx mcporter generate-cli \
  --server my-service-mcp \
  --command http://localhost:9000 \
  --name my-service-cli \
  --bundle

# Use it
./my-service-cli my_service action=list
./my-service-cli my_service action=get id=abc123
```

### mcporter in CI / `Makefile`

```makefile
.PHONY: test test-live cli

test:
	uv run pytest tests/

test-live:
	@bash tests/test_live.sh

cli:
	npx mcporter generate-cli \
	  --server $(SERVER_NAME) \
	  --command $(MCP_URL) \
	  --name $(SERVER_NAME)-cli \
	  --bundle
```

---

## Validation Checklist

Run before every commit to a plugin repo:

```bash
claude plugin validate .
```

Common errors and fixes:

| Error | Fix |
|---|---|
| `userConfig.*.type: Invalid option` | Add `"type": "string"` — required, undocumented |
| `userConfig.*.title: Invalid input` | Add `"title": "..."` — required, undocumented |
| Hook format rejected | Wrap in `{"description": "...", "hooks": {...}}` — bare arrays not accepted |
| `${user_config.*}` not substituting | Field must be `sensitive: false` for `.mcp.json` substitution |

---

## Credential Flow Diagram

```
Claude Code plugin install
         │
         ▼
  userConfig prompts (URL, API key, MCP token)
         │
         ▼
  Credentials stored encrypted in Claude Code
         │
         ▼ SessionStart
  sync-env.sh
  ├── Writes MY_SERVICE_URL, MY_SERVICE_API_KEY → .env
  ├── Writes MCP_BEARER_TOKEN → .env (or auto-generates if absent)
  └── chmod 600 .env
         │
         ├─────────────────────────────────────────────────────┐
         ▼                                                     ▼
  Docker Compose reads .env                         .mcp.json wires
  → passes vars to container                        Claude Code → MCP server
  → MCP server reads env vars                       (via ${user_config.url} + Bearer token)
  → connects to service                                        │
                                                               ▼
                                                    Claude Code calls tools
                                                    → MCP server proxies to service

Fallback (MCP server not running):
  CLAUDE_PLUGIN_OPTION_* in Bash subprocess → curl commands in SKILL.md
```

---

## Adding a New Plugin (Checklist)

1. **`plugin.json`** — all userConfig fields have `type`, `title`, `description`, `sensitive`; include `my_service_mcp_token` (`sensitive: false`) for bearer auth
2. **`.mcp.json`** — `url: "${user_config.my_service_mcp_url}/mcp"`, `Authorization: "Bearer ${user_config.my_service_mcp_token}"`
3. **`hooks/hooks.json`** — standard SessionStart + PostToolUse structure with wrapper object
4. **`sync-env.sh`** — maps `CLAUDE_PLUGIN_OPTION_*` → `.env` keys; auto-generates `MCP_BEARER_TOKEN` if absent
5. **Copy `fix-env-perms.sh`** — identical across all plugins
6. **Copy `ensure-gitignore.sh`** — identical across all plugins
7. **`server.py`** — bearer token middleware (fail on start if unset and `NO_HTTP_AUTH` not set); action+subaction tool pattern
8. **`SKILL.md`** — dual-mode, exhaustive trigger phrases, action+subaction reference
9. **`tests/test_live.sh`** — mcporter-based, tests all actions, subactions, resources, schema, CLI generation, and auth rejection
10. **`.env.example`** — all keys, including `MCP_BEARER_TOKEN=` and `NO_HTTP_AUTH=false`
11. **`.gitignore`** — `.env`, `.env.*`, `!.env.example`, `backups/*`, `!backups/.gitkeep`, `logs/*`, `!logs/.gitkeep`
12. **`backups/.gitkeep` and `logs/.gitkeep`**
13. **`claude plugin validate .`** — must pass with zero errors
14. **Add to `marketplace.json`** on dookie — use full metadata (name, source, description, version, category, tags, homepage)
