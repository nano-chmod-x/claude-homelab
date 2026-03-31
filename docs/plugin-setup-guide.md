# Claude Code Plugin Setup Guide

This guide documents the exact structure, conventions, and standards for all MCP-server-backed
Claude Code plugins in this ecosystem (`gotify-mcp`, `overseerr-mcp`, `unifi-mcp`, `swag-mcp`,
`unraid-mcp`, `synapse-mcp`, `syslog-mcp`, `axon`, `arcane-mcp`, and any future additions).

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Directory Layout](#directory-layout)
3. [`.cache/` Convention](#cache-convention)
4. [Language Toolchain Standards](#language-toolchain-standards)
5. [HTTP Security — Bearer Tokens](#http-security--bearer-tokens)
6. [Tool Design — Action + Subaction Pattern](#tool-design--action--subaction-pattern)
7. [Code Architecture](#code-architecture)
8. [Destructive Operations — Confirmation Gate](#destructive-operations--confirmation-gate)
9. [Middleware & Server Hardening](#middleware--server-hardening)
10. [CI/CD Pipeline](#cicd-pipeline)
11. [MCP Resources](#mcp-resources)
12. [File-by-File Reference](#file-by-file-reference)
    - [plugin.json](#claudepluginpluginjson)
    - [.mcp.json](#mcpjson)
    - [hooks/hooks.json](#hookshooksjson)
    - [hooks/scripts/sync-env.sh](#hooksscriptssync-envsh)
    - [hooks/scripts/fix-env-perms.sh](#hooksscriptsfix-env-permssh)
    - [hooks/scripts/ensure-gitignore.sh](#hooksscriptsensure-gitignore-sh)
    - [skills/SKILL.md](#skillsserviceskillmd)
    - [agents/](#agentsagent-namemd)
    - [commands/](#commandscommandmd)
    - [CLAUDE.md / AGENTS.md / GEMINI.md](#claudemd--agentsmd--geminimd)
    - [.gitignore](#gitignore)
    - [.env.example](#envexample)
    - [Plugin Settings](#plugin-settings-claudeplugin-namelocalmd--optional)
    - [Justfile](#justfile)
    - [entrypoint.sh](#entrypointsh)
    - [Dockerfile](#dockerfile)
    - [docker-compose.yaml](#docker-composeyaml)
    - [SWAG Reverse Proxy Config](#swag-reverse-proxy-config)
13. [Codex CLI Compatibility](#codex-cli-compatibility)
14. [Marketplace Registration](#marketplace-registration)
15. [Testing with mcporter](#testing-with-mcporter)
16. [Validation Checklist](#validation-checklist)
17. [Credential Flow Diagram](#credential-flow-diagram)
18. [Development Tools Reference](#development-tools-reference)
19. [Adding a New Plugin](#adding-a-new-plugin)

---

## Architecture Overview

Each plugin lives **inside its MCP server repo**, not in this repo. The marketplace here points
to those repos as sources. Plugin, MCP server, and Docker Compose stack all ship together.

The plugin provides:
1. **userConfig** — prompts the user for credentials/URLs at install time
2. **MCP config** — wires the MCP server connection using those credentials
3. **Hooks** — syncs credentials to `.env` so Docker Compose can read them
4. **Skills** — dual-mode skill (MCP preferred, HTTP fallback) documenting all tool actions
5. **Agents** — specialized AI agents for complex multi-step workflows (optional)
6. **Commands** — slash commands for common operations (optional)

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

### Transport Modes

All MCP servers **must** support both transport modes:

| Mode | Env value | When used |
|------|-----------|-----------|
| **HTTP** (Streamable-HTTP) | `http` | **Default.** Production deployments, Docker, reverse proxy |
| **stdio** | `stdio` | Local development, direct pipe, Codex CLI without network |

The transport is controlled by `<SERVICE>_MCP_TRANSPORT` env var, defaulting to `http`:

```bash
# .env
MY_SERVICE_MCP_TRANSPORT=http    # default — Streamable-HTTP server
MY_SERVICE_MCP_TRANSPORT=stdio   # alternative — stdin/stdout pipe
```

**HTTP mode** starts a persistent HTTP server (the normal production path). The server
binds to `<SERVICE>_MCP_HOST` and `<SERVICE>_MCP_PORT`, enforces bearer auth, and exposes
`/health` and `/mcp` endpoints.

**stdio mode** reads JSON-RPC from stdin and writes to stdout. No HTTP server, no auth,
no health endpoint. Useful for local development and CLI tools that manage the process
directly (e.g., `codex` with stdio transport).

Servers should check the transport env var at startup and branch accordingly — both modes
use the same tool handlers and business logic.

---

## Directory Layout

```
repo-root/
├── .cache/                      # ALL tool artifacts — see .cache Convention below
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json              # Codex CLI plugin manifest
├── agents/                      # Specialized AI agents for complex workflows
│   └── <agent-name>.md          # Agent definition (system prompt, tools, triggers)
├── backups/
│   └── .gitkeep                 # Gitignored — holds .env.bak.* files
├── commands/                    # Slash commands (optional)
│   └── <command>.md             # Command definition with frontmatter
├── docs/                        # Reference docs, API endpoints, troubleshooting
├── hooks/
│   ├── hooks.json               # Hook event wiring (SessionStart, PostToolUse)
│   └── scripts/
│       ├── ensure-gitignore.sh  # Ensures .env and backups are gitignored
│       ├── fix-env-perms.sh     # Re-enforces chmod 600 when .env is touched
│       └── sync-env.sh          # Syncs userConfig → .env on session start
├── logs/
│   └── .gitkeep                 # Gitignored — holds server log files
├── skills/
│   └── <service>/
│       └── SKILL.md             # Claude-facing skill definition
├── src/ or <service>_mcp/       # Server source code (language-specific)
│   ├── client.*                 # Service API client
│   └── server.*                 # MCP server entry point — action+subaction pattern
├── tests/
│   └── test_live.sh             # Full end-to-end live test (mcporter-based)
├── .dockerignore                # Excludes .git, build artifacts, docs, tests, .env
├── .env                         # Runtime credentials — gitignored, chmod 600
├── .env.example                 # Template — tracked in git, no real values
├── .github/
│   └── workflows/
│       └── ci.yml               # CI pipeline: lint, typecheck, test, audit
├── .gitignore                   # Must include patterns listed below
├── .mcp.json                    # MCP server connection config
├── .pre-commit-config.yaml      # Pre-commit hook config
├── <service>.subdomain.conf     # SWAG reverse proxy config (no -mcp suffix)
├── AGENTS.md -> CLAUDE.md       # Symlink — Codex CLI support
├── CHANGELOG.md                 # Version history
├── CLAUDE.md                    # AI memory file — canonical source of truth
├── docker-compose.yaml          # env_file only, PUID/PGID, named volumes, external network
├── Dockerfile                   # Multi-stage, non-root user
├── entrypoint.sh               # Container entrypoint — env validation before server start
├── GEMINI.md -> CLAUDE.md       # Symlink — Gemini CLI support
├── Justfile                     # Task runner — build, test, lint, deploy recipes
├── LICENSE                      # MIT license
├── pyproject.toml / package.json / Cargo.toml  # Language-specific manifest
└── README.md                    # User-facing documentation (setup, usage, API)
```

---

## `.cache/` Convention

**The repo root must stay clutter-free.** Every tool artifact, cache, and generated output
that does not *have* to live at the root **must** be configured to write into `.cache/`.

`.cache/` is gitignored. Nothing inside it is committed.

### What goes in `.cache/`

| Tool | Default location | Required config |
|------|-----------------|-----------------|
| **Python** | | |
| pytest | `.pytest_cache/` | `cache_dir = ".cache/pytest"` in `pyproject.toml` |
| ruff | `.ruff_cache/` | `cache-dir = ".cache/ruff"` in `pyproject.toml` |
| ty | `.ty_cache/` | `cache-dir = ".cache/ty"` in `pyproject.toml` |
| mypy | `.mypy_cache/` | `cache_dir = ".cache/mypy"` in `pyproject.toml` |
| pyright | `.pyright/` | `"cacheDir": ".cache/pyright"` in `pyrightconfig.json` |
| coverage | `.coverage`, `htmlcov/` | `[tool.coverage.run] data_file = ".cache/coverage/.coverage"` |
| hypothesis | `.hypothesis/` | `database = ".cache/hypothesis"` in conftest or settings |
| tox | `.tox/` | `toxworkdir = .cache/tox` in `tox.ini` |
| nox | `.nox/` | `--envdir .cache/nox` flag |
| **JS/TS** | | |
| tsbuildinfo | `*.tsbuildinfo` | `"tsBuildInfoFile": ".cache/tsconfig.tsbuildinfo"` in `tsconfig.json` |
| vitest | `node_modules/.vitest/` | `cacheDir: '.cache/vitest'` in `vitest.config` |
| eslint | `.eslintcache` | `--cache-location .cache/eslint/` |
| stylelint | `.stylelintcache` | `--cache-location .cache/stylelint/` |
| next.js | `.next/` | `distDir: '.cache/next'` in `next.config` (dev only) |
| turbo | `.turbo/` | `"cacheDir": ".cache/turbo"` in `turbo.json` |
| parcel | `.parcel-cache/` | `--cache-dir .cache/parcel` |
| **Rust** | | |
| cargo | `target/` | `CARGO_TARGET_DIR=.cache/target` in `.cargo/config.toml` |
| **Go** | | |
| go test | per-package | `GOCACHE=.cache/go-build` env var |
| go cover | `cover.out` | `-coverprofile=.cache/cover.out` flag |

### `pyproject.toml` example

```toml
[tool.pytest.ini_options]
cache_dir = ".cache/pytest"

[tool.ruff]
cache-dir = ".cache/ruff"

[tool.ty]
cache-dir = ".cache/ty"

[tool.mypy]
cache_dir = ".cache/mypy"

[tool.coverage.run]
data_file = ".cache/coverage/.coverage"

[tool.coverage.html]
directory = ".cache/coverage/html"

[tool.coverage.xml]
output = ".cache/coverage/coverage.xml"
```

### Enforcement

The `.gitignore` includes a single `.cache/` entry that covers everything.
Individual tool cache directories (`.pytest_cache/`, `.ruff_cache/`, etc.) should
**not** appear at the repo root. If they do, the tool is misconfigured.

---

## Language Toolchain Standards

Each language has a **required** toolchain. Do not deviate.

### Python

| Concern | Tool | Notes |
|---------|------|-------|
| Package/project manager | **uv** | `uv init`, `uv add`, `uv run` — no pip, no poetry, no setuptools |
| Project config | **pyproject.toml** | Single source of truth — no `setup.py`, `setup.cfg`, `requirements.txt` |
| Testing | **pytest** | Via `uv run pytest` — configure in `[tool.pytest.ini_options]` |
| Linting + formatting | **ruff** | `ruff check` + `ruff format` — configure in `[tool.ruff]` |
| Type checking | **ty** | Strict mode — configure in `[tool.ty]` |
| Pre-commit hooks | **ruff + ty** | Both must pass before commit |
| MCP SDK | **FastMCP** (latest) | `uv add fastmcp` — the only supported Python MCP framework |

**No other linters, formatters, or type checkers.** No flake8, black, isort, pylint, mypy, pyright, pytype.

Minimal `pyproject.toml` tooling section:

```toml
[tool.ruff]
cache-dir = ".cache/ruff"
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "SIM", "TCH", "RUF"]

[tool.ty]
cache-dir = ".cache/ty"

[tool.pytest.ini_options]
cache_dir = ".cache/pytest"
testpaths = ["tests"]
```

### TypeScript / JavaScript

| Concern | Tool | Notes |
|---------|------|-------|
| Linting + formatting | **Biome** | Single tool — no ESLint, no Prettier, no separate formatter |
| Config | `biome.json` | At repo root |
| MCP SDK | **@modelcontextprotocol/sdk** (latest) | Official MCP TypeScript SDK — the only supported TS MCP framework |

**No ESLint, Prettier, or other JS/TS linters.** Biome handles everything.

Minimal `biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  }
}
```

### Rust

| Concern | Tool | Notes |
|---------|------|-------|
| Build system | **cargo** | Standard Rust toolchain |
| Project config | **Cargo.toml** | Single source of truth |
| Testing | **cargo test** | Built-in test framework |
| Linting | **clippy** | `cargo clippy -- -D warnings` |
| Formatting | **rustfmt** | `cargo fmt` |
| MCP SDK | **rmcp** (latest) | `cargo add rmcp` — the only supported Rust MCP framework |

### Pre-commit Hooks (all languages)

Every plugin **must** validate its skills in pre-commit. Use `skills-ref` from the
`@anthropic-ai/skills-ref` package:

```bash
# Validate a single skill
npx skills-ref validate skills/my-service/SKILL.md

# Validate all skills in the directory
npx skills-ref validate skills/

# Read parsed skill properties (debugging)
npx skills-ref read-properties skills/my-service/SKILL.md

# Convert skills to prompt format (testing)
npx skills-ref to-prompt skills/my-service/
```

Add to your pre-commit config (`.pre-commit-config.yaml` or equivalent):

```yaml
# Python repos (ruff + ty + skills)
repos:
  - repo: local
    hooks:
      - id: ruff
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
        types: [python]
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

```yaml
# TypeScript repos (biome + skills)
repos:
  - repo: local
    hooks:
      - id: biome
        name: biome
        entry: npx biome check --write
        language: system
        types_or: [javascript, typescript, json]
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

```yaml
# Rust repos (clippy + fmt + skills)
repos:
  - repo: local
    hooks:
      - id: cargo-fmt
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
        pass_filenames: false
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

The `skills-validate` hook runs whenever a `SKILL.md` file changes and ensures
frontmatter, structure, and content pass validation before commit.

---

## HTTP Security — Bearer Tokens

All MCP servers **must**:
1. Use HTTP bearer token authentication by default (exception: `MY_SERVICE_MCP_NO_AUTH=true` for proxy-managed auth)
2. Expose `GET /health` returning `{"status":"ok"}` — unauthenticated, exempt from bearer token enforcement. Used by Docker healthchecks, compose healthchecks, and `test_live.sh`.

### Environment variable naming convention

Use a **flat prefix structure** — no generic/unprefixed vars:

| Prefix | Scope | Examples |
|--------|-------|---------|
| `MY_SERVICE_` | Service-related (API URL, API key, credentials) | `MY_SERVICE_URL`, `MY_SERVICE_API_KEY` |
| `MY_SERVICE_MCP_` | MCP server config (host, port, auth, transport) | `MY_SERVICE_MCP_HOST`, `MY_SERVICE_MCP_PORT`, `MY_SERVICE_MCP_TOKEN` |

**No generic env vars.** Every variable is prefixed with the service name. This prevents
collisions when running multiple MCP servers on the same host and makes it clear which
service a variable belongs to.

### Required environment variables

| Variable | Purpose |
|---|---|
| `MY_SERVICE_MCP_TOKEN` | Bearer token the server validates. Required unless `MY_SERVICE_MCP_NO_AUTH=true`. |
| `MY_SERVICE_MCP_NO_AUTH` | Set to `true` to disable bearer auth. Default: unset (auth enforced). |
| `MY_SERVICE_MCP_HOST` | HTTP bind address. Default: `0.0.0.0`. |
| `MY_SERVICE_MCP_PORT` | HTTP port. Default: service-specific. |
| `MY_SERVICE_MCP_TRANSPORT` | `http` (default) or `stdio`. |
| `MY_SERVICE_MCP_ALLOW_YOLO` | Skip elicitation for destructive ops. Default: `false`. |
| `MY_SERVICE_MCP_ALLOW_DESTRUCTIVE` | Auto-confirm all destructive ops. Default: `false`. |
| `MY_SERVICE_URL` | Upstream service URL (e.g., `https://gotify.example.com`). |
| `MY_SERVICE_API_KEY` | Upstream service API key/token. |

### Token generation

If `MY_SERVICE_MCP_TOKEN` is not set and `MY_SERVICE_MCP_NO_AUTH` is not `true`, the server **must fail to
start** with a clear error message:

```
CRITICAL: MY_SERVICE_MCP_TOKEN is not set.
Set MY_SERVICE_MCP_TOKEN to a secure random token, or set MY_SERVICE_MCP_NO_AUTH=true to disable auth
(only appropriate when secured at the network/proxy level).

Generate a token with: openssl rand -hex 32
```

The `sync-env.sh` hook generates a token automatically if one is not present in `.env`:

```bash
# In sync-env.sh, after writing userConfig values:
if ! grep -q "^MY_SERVICE_MCP_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  generated=$(openssl rand -hex 32)
  echo "MY_SERVICE_MCP_TOKEN=${generated}" >> "$ENV_FILE"
fi
```

### Bearer token enforcement by language

#### Python (FastMCP + Starlette)

```python
import os
import sys
from fastmcp import FastMCP
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

BEARER_TOKEN = os.getenv("MY_SERVICE_MCP_TOKEN")
MY_SERVICE_MCP_NO_AUTH = os.getenv("MY_SERVICE_MCP_NO_AUTH", "").lower() in ("true", "1", "yes")

if not MY_SERVICE_MCP_NO_AUTH and not BEARER_TOKEN:
    print(
        "CRITICAL: MY_SERVICE_MCP_TOKEN is not set.\n"
        "Set MY_SERVICE_MCP_TOKEN to a secure random token, or set MY_SERVICE_MCP_NO_AUTH=true\n"
        "to disable auth (only appropriate when secured at the network/proxy level).\n\n"
        "Generate a token with: openssl rand -hex 32",
        file=sys.stderr,
    )
    sys.exit(1)

class BearerAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if MY_SERVICE_MCP_NO_AUTH:
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

#### TypeScript (Express middleware)

```typescript
import { timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  // Health + well-known are always unauthenticated
  if (req.path === "/health" || req.path.startsWith("/.well-known")) {
    next();
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing or invalid Authorization header" });
    return;
  }

  const token = authHeader.slice(7);
  const tokenBuf = Buffer.from(token);
  const expectedBuf = Buffer.from(env.AUTH_TOKEN);
  if (tokenBuf.length !== expectedBuf.length || !timingSafeEqual(tokenBuf, expectedBuf)) {
    res.status(401).json({ error: "Invalid bearer token" });
    return;
  }

  next();
}
```

#### Rust (rmcp + axum)

Rust servers use **rmcp** with the `#[tool_router]` macro for tool registration and
`StreamableHttpService` for HTTP transport. Auth is handled as axum middleware wrapping
the MCP service.

```rust
use rmcp::{
    tool, tool_handler, tool_router,
    handler::server::wrapper::Parameters,
    model::{ServerCapabilities, ServerInfo, InitializeResult},
    service::RequestContext,
    transport::{stdio, streamable_http_server::StreamableHttpService},
    ErrorData, RoleServer, ServerHandler, ServiceExt,
};

#[derive(Clone)]
pub struct MyServiceMcpServer { /* config, clients, etc. */ }

// Register the single action+subaction tool
#[tool_router]
impl MyServiceMcpServer {
    #[tool(
        name = "my_service",
        description = "Unified tool. Use action/subaction routing. Call action:help for reference."
    )]
    async fn my_service(
        &self,
        Parameters(raw): Parameters<serde_json::Map<String, serde_json::Value>>,
    ) -> Result<String, ErrorData> {
        let action = raw.get("action").and_then(|v| v.as_str()).unwrap_or("unknown");
        let subaction = raw.get("subaction").and_then(|v| v.as_str()).unwrap_or("");
        // Parse and dispatch...
        todo!()
    }
}

#[tool_handler(router = Self::tool_router())]
impl ServerHandler for MyServiceMcpServer {
    fn get_info(&self) -> ServerInfo { /* capabilities, name, version, instructions */ }
    async fn initialize(&self, request: InitializeRequestParams, _ctx: RequestContext<RoleServer>)
        -> Result<InitializeResult, ErrorData> { /* ... */ }
}

// Dual transport: stdio or HTTP
pub async fn run_stdio(cfg: Config) -> Result<(), Box<dyn std::error::Error>> {
    let service = MyServiceMcpServer::new(cfg).serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}

pub async fn run_http(cfg: Config, host: &str, port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let mcp_service = StreamableHttpService::new(
        move || Ok(MyServiceMcpServer::new(cfg.clone())),
        Default::default(),
        Default::default(),
    );
    // Wrap with auth middleware
    let app = Router::new()
        .nest_service("/mcp", mcp_service)
        .route("/health", get(health));
    let listener = tokio::net::TcpListener::bind((host, port)).await?;
    axum::serve(listener, app).await?;
    Ok(())
}
```

**Bearer auth** is applied as axum middleware on the `/mcp` route using
`subtle::ConstantTimeEq` for timing-safe token comparison. The `/health`
route is always unauthenticated.

**Key patterns across all languages:**
- Timing-safe comparison (`hmac.compare_digest`, `timingSafeEqual`, `subtle::ConstantTimeEq`)
- `/health` always unauthenticated
- Fail startup if no token and auth not explicitly disabled

### `.mcp.json` — passing the token

The bearer token must be passed from `userConfig` to the MCP connection headers. Since
`MY_SERVICE_MCP_TOKEN` is synced to `.env` (sensitive), it is also exposed as
`CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN`. However, `.mcp.json` only supports
`${user_config.*}` substitution — so the token must be a `userConfig` field:

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}",
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
  "description": "Bearer token for authenticating with the MCP server. Must match MY_SERVICE_MCP_TOKEN in the server's .env. Generate with: openssl rand -hex 32",
  "sensitive": true
}
```

The `sync-env.sh` hook maps this to `MY_SERVICE_MCP_TOKEN` in `.env`.

---

## Tool Design — Action + Subaction Pattern

**Mandatory.** All MCP servers **must** expose exactly **two tools**:

1. **Domain tool** — a single tool using `action` + optional `subaction` parameters for all operations
2. **Help tool** — auto-generated from the domain tool's schema, returns available actions, subactions, and parameter docs

No other tool structure is allowed. Do not create individual tools per operation.

### Why

- Claude Code loads all tool definitions into context on every request
- 20 individual tools × 500 tokens each = 10,000 tokens of tool overhead per call
- 1 tool with 20 actions = ~800 tokens total — ~12× improvement
- Subactions further group related operations without new top-level tokens
- The help tool lets Claude discover capabilities at runtime without extra context overhead

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

### Filtering, pagination, and sorting (required)

All `list`-type actions **must** support filtering, pagination, and sorting. Never return
unbounded result sets — they blow up the client's context window and waste tokens.

**Standard parameters** for any action that returns a list:

#### Python (FastMCP)

```python
@mcp.tool()
async def my_service(
    ctx: Context,
    action: Literal["list", ...],
    # Pagination
    offset: int = 0,                # Skip N results
    limit: int = 20,                # Max results (default 20, max 500)
    # Sorting
    sort_by: str | None = None,     # Field to sort by (e.g., "created", "name")
    sort_order: str | None = None,  # "asc" or "desc" (default "desc")
    # Filtering
    query: str | None = None,       # Free-text search/filter
    status: str | None = None,      # Filter by status (domain-specific)
) -> dict:
    ...
```

#### TypeScript (@modelcontextprotocol/sdk + zod)

```typescript
server.tool("my_service", {
  action: z.enum(["list", ...]),
  offset: z.number().int().min(0).default(0).describe("Skip N results"),
  limit: z.number().int().min(1).max(500).default(20).describe("Max results"),
  sort_by: z.string().optional().describe("Field to sort by"),
  sort_order: z.enum(["asc", "desc"]).default("desc").optional(),
  query: z.string().optional().describe("Free-text filter"),
}, async ({ action, offset, limit, sort_by, sort_order, query }) => {
  // ...
});
```

#### Rust (rmcp + schemars)

```rust
#[derive(Debug, Clone, Deserialize, schemars::JsonSchema)]
pub struct ListRequest {
    pub subaction: Option<ListSubaction>,
    /// Skip N results (default 0)
    pub offset: Option<usize>,
    /// Max results (default 20, max 500)
    pub limit: Option<i64>,
    /// Field to sort by
    pub sort_by: Option<String>,
    /// "asc" or "desc" (default "desc")
    pub sort_order: Option<String>,
    /// Free-text filter
    pub query: Option<String>,
}
```

**Response format** for paginated results (all languages):

```json
{
  "items": [...],
  "total": 142,
  "limit": 20,
  "offset": 0,
  "has_more": true
}
```

**Rules:**
- Default `limit` to a sensible value (50) — never return all records by default
- Include `total` count so Claude knows how much data exists
- Include `has_more` flag so Claude can request the next page
- Apply the response size limit (~512KB) as a safety net even with pagination

### Help tool (required)

Every server **must** expose a help tool that returns the full action/subaction reference,
auto-generated from the domain tool's schema. This lets Claude discover capabilities
at runtime without the SKILL.md needing to be loaded.

#### Python

```python
@mcp.tool()
async def my_service_help(
    action: str | None = None,
) -> str:
    """Return available actions, subactions, and parameters for the my_service tool.

    Call with no arguments for a full overview.
    Call with action="<name>" for detailed help on a specific action.
    """
    schema = {
        "list": {"description": "List all resources", "params": {}},
        "get": {"description": "Get resource by id", "params": {"id": "Resource ID (required)"}},
        "create": {"description": "Create new resource", "params": {"name": "Resource name (required)", "config": "Configuration dict (optional)"}},
        "update": {
            "description": "Update resource",
            "params": {"id": "Resource ID (required)", "config": "Configuration dict (optional)"},
            "subactions": {
                "enable": "Enable the resource",
                "disable": "Disable the resource",
                "reload": "Reload resource config",
            },
        },
        "delete": {"description": "Delete resource by id (DESTRUCTIVE)", "params": {"id": "Resource ID (required)"}},
        "search": {"description": "Search resources", "params": {"query": "Search query (required)"}},
        "status": {"description": "Check service health", "params": {}},
        "logs": {"description": "Tail recent log lines", "params": {}},
    }

    if action:
        if action not in schema:
            return f"Unknown action: {action}. Available: {', '.join(schema.keys())}"
        entry = schema[action]
        lines = [f"## {action}\n{entry['description']}\n"]
        if entry.get("params"):
            lines.append("**Parameters:**")
            for k, v in entry["params"].items():
                lines.append(f"  - `{k}`: {v}")
        if entry.get("subactions"):
            lines.append("**Subactions:**")
            for k, v in entry["subactions"].items():
                lines.append(f"  - `{k}`: {v}")
        return "\n".join(lines)

    lines = ["# my_service — Available Actions\n"]
    for name, entry in schema.items():
        destructive = " ⚠️" if "DESTRUCTIVE" in entry["description"] else ""
        lines.append(f"- **{name}**{destructive} — {entry['description']}")
    lines.append("\nCall `my_service_help(action=\"<name>\")` for detailed parameter info.")
    return "\n".join(lines)
```

#### TypeScript

```typescript
server.tool("my_service_help", "Return available actions and parameters", {
  action: z.string().optional().describe("Get detailed help for a specific action"),
}, async ({ action }) => {
  const schema = { /* same structure as Python */ };

  if (action) {
    const entry = schema[action];
    if (!entry) return { content: [{ type: "text", text: `Unknown action: ${action}` }] };
    // Format detailed help for the action
  }

  // Format overview of all actions
  return { content: [{ type: "text", text: overview }] };
});
```

The help tool schema object should be **derived from or kept in sync with** the domain
tool's actual type definitions — not maintained as a separate copy. If your language
supports runtime reflection on the tool schema, use that.

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

## Code Architecture

### Services layer (required)

All business logic **must** live in a services layer. Tool handlers are thin shims that
validate input, call the appropriate service, and format the response. This separation
allows adding new handlers (CLI, REST, tests) without duplicating logic.

```
src/ or <service>_mcp/
├── server.*                 # MCP server setup + tool registration (shims only)
├── client.*                 # Upstream API client (HTTP calls, auth)
├── services/                # Business logic — the real work happens here
│   ├── resource_service.*   # CRUD operations for resources
│   ├── monitoring_service.* # Health checks, metrics
│   └── config_service.*     # Configuration management
├── models/                  # Data models, types, enums
├── middleware/              # Auth, timing, rate limiting, error handling
└── utils/                   # Shared helpers (formatters, validators, logging)
```

**Tool handler pattern** — tools are shims:

```python
# ❌ Wrong — business logic in the tool handler
@mcp.tool()
async def my_service(action: str, id: str | None = None, ...) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{URL}/api/resources/{id}")
        data = response.json()
        # 50 lines of transformation logic...
        return transformed_data

# ✅ Right — tool handler delegates to service
@mcp.tool()
async def my_service(action: str, id: str | None = None, ...) -> dict:
    match action:
        case "get":
            return await resource_service.get(id)
        case "list":
            return await resource_service.list(limit=limit, offset=offset)
```

### Module size limit

**No file should exceed 500 lines.** If a module grows beyond this, split it:

- Extract service methods into domain-specific modules
- Split tool dispatch by action group (e.g., `_containers.py`, `_networks.py`)
- Move shared types/models to a `models/` or `types/` module
- Extract middleware into separate files

This keeps code reviewable, testable, and navigable.

---

## Destructive Operations — Confirmation Gate

Any action that can cause **data loss** (delete, destroy, prune, purge, reset) **must** require
confirmation before executing. This is enabled by default — users opt into skipping it.

### Three-path confirmation

Every destructive operation runs through this logic in order:

1. **Env bypass** — if `<SERVICE>_MCP_ALLOW_DESTRUCTIVE=true`, auto-confirm (for CI/automation)
2. **Elicitation** — if the MCP client supports `elicitation.form`, prompt the user with a
   confirmation dialog. Skipped when `<SERVICE>_MCP_ALLOW_YOLO=true` (YOLO mode)
3. **Hard block** — if neither bypass is enabled and elicitation isn't available, deny the
   operation and return guidance on how to proceed

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `<SERVICE>_MCP_ALLOW_DESTRUCTIVE` | `false` | Auto-confirm all destructive ops (CI/automation) |
| `<SERVICE>_MCP_ALLOW_YOLO` | `false` | Skip elicitation prompts but still allow `{ confirm: true }` in params |

### docker-compose.yaml

```yaml
environment:
  - ${SERVICE}_MCP_ALLOW_YOLO=${${SERVICE}_MCP_ALLOW_YOLO:-false}
  - ${SERVICE}_MCP_ALLOW_DESTRUCTIVE=${${SERVICE}_MCP_ALLOW_DESTRUCTIVE:-false}
```

### TypeScript implementation (reference: arcane-mcp)

```typescript
interface ConfirmResult {
  confirmed: boolean;
  method: "env_bypass" | "elicitation" | "blocked";
}

async function confirmDestructive(
  server: Server,
  action: string,
  subaction: string,
  id: string | undefined,
): Promise<ConfirmResult> {
  // Path 1: env bypass
  if (env.ALLOW_DESTRUCTIVE) {
    return { confirmed: true, method: "env_bypass" };
  }

  // Path 2: elicitation (skipped in YOLO mode)
  if (!env.YOLO_MODE && server.getClientCapabilities()?.elicitation?.form) {
    try {
      const result = await server.elicitInput({
        mode: "form",
        message: `WARNING: Destructive operation **${action}:${subaction}**${
          id ? ` on \`${id}\`` : ""
        }.\n\nThis action cannot be undone.\nTo suppress this prompt, set ${SERVICE}_MCP_ALLOW_YOLO=true.`,
        requestedSchema: {
          type: "object",
          properties: {
            confirm: {
              type: "boolean",
              title: `${subaction.charAt(0).toUpperCase() + subaction.slice(1)} this ${action}?`,
              description: "I understand this cannot be undone.",
              default: false,
            },
          },
          required: ["confirm"],
        },
      });
      if (result.action === "accept" && result.content?.confirm === true) {
        return { confirmed: true, method: "elicitation" };
      }
      return { confirmed: false, method: "elicitation" };
    } catch {
      // Elicitation failed — fall through to blocked
    }
  }

  // Path 3: hard block
  return { confirmed: false, method: "blocked" };
}
```

### Tool handler integration

Call `confirmDestructive` before executing any destructive subaction. When blocked,
return actionable guidance — not just an error:

```typescript
// Inside the action+subaction dispatcher:
if (DESTRUCTIVE_SUBACTIONS.has(subaction) && params?.confirm !== true) {
  const gate = await confirmDestructive(server, action, subaction, id);
  if (!gate.confirmed) {
    return {
      content: [{
        type: "text",
        text: gate.method === "elicitation"
          ? "Operation cancelled by user."
          : `⚠️ Confirmation required. Re-call with params: { confirm: true } to proceed.`,
      }],
      isError: gate.method === "elicitation",  // user-declined = error, blocked = guidance
    };
  }
}
```

### Python equivalent

```python
async def confirm_destructive(
    server: FastMCP, action: str, subaction: str, target_id: str | None = None
) -> tuple[bool, str]:
    """Returns (confirmed, method)."""
    if os.getenv(f"{SERVICE}_MCP_ALLOW_DESTRUCTIVE", "").lower() in ("true", "1"):
        return True, "env_bypass"

    if not os.getenv(f"{SERVICE}_MCP_ALLOW_YOLO", "").lower() in ("true", "1"):
        # Attempt elicitation if client supports it
        try:
            result = await server.elicit(
                message=f"Destructive: {action}:{subaction}" + (f" on `{target_id}`" if target_id else ""),
                schema={"confirm": {"type": "boolean", "required": True}},
            )
            if result.action == "accept" and result.data.get("confirm"):
                return True, "elicitation"
            return False, "elicitation"
        except Exception:
            pass

    return False, "blocked"
```

### SKILL.md documentation

Destructive subactions in the skill's tool reference **must** be clearly marked:

```markdown
### Delete resource — DESTRUCTIVE

Requires confirmation. Set `<SERVICE>_MCP_ALLOW_YOLO=true` to skip prompts.

Always confirm with user before executing.
```

---

## Middleware & Server Hardening

MCP servers **should** implement a middleware stack to protect against abuse and ensure
observability. The order matters — outermost middleware runs first.

### Recommended middleware stack

| Layer | Purpose | Required? |
|-------|---------|-----------|
| **Timing** | Track request/response duration per tool call | Yes |
| **Logging** | Log all tool calls and resource reads | Yes |
| **Error handling** | Convert exceptions to MCP errors, track stats | Yes |
| **Rate limiting** | Per-IP request throttling (e.g., 100 req/min) | Recommended |
| **Response limiting** | Cap responses at ~512KB to protect client context | Recommended |
| **Bearer auth** | Token validation (ASGI-level or framework middleware) | Yes |
| **Health** | Pass-through for `/health` endpoint (unauthenticated) | Yes |

### Error handling

Errors returned to Claude should be **LLM-friendly** — include:
- What action failed and on what target
- A unique error ID for traceability (e.g., 8-char UUID)
- Whether the error is retryable
- Actionable guidance (not raw stack traces)

```
container:stop on 'nginx-proxy' — Arcane API error (503): Service Unavailable.
Service may be temporarily unavailable. Retry after a moment. [err:a1b2c3d4]
```

### Graceful shutdown

All servers **must** handle `SIGTERM` and `SIGINT` for clean container stops:
- Drain in-flight requests
- Close database connections
- Flush log buffers

Python (FastMCP handles this), TypeScript (Express `server.close()`), Rust (tokio signal handlers).

### Response size limits

Tool responses can be arbitrarily large (e.g., listing 10,000 containers). Cap responses
to prevent blowing up the client's context window:

```python
MAX_RESPONSE_SIZE = 512 * 1024  # 512KB
if len(response) > MAX_RESPONSE_SIZE:
    response = response[:MAX_RESPONSE_SIZE] + "\n\n[Response truncated at 512KB]"
```

---

## CI/CD Pipeline

Every plugin repo **should** have a GitHub Actions CI pipeline.

### Minimum CI jobs

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  lint:
    # Python: uv run ruff check . && uv run ruff format --check .
    # TypeScript: npx biome ci .
    # Rust: cargo fmt --check && cargo clippy -- -D warnings

  typecheck:
    # Python: uv run ty check
    # TypeScript: npx tsc --noEmit
    # Rust: (covered by clippy)

  test:
    # Python: uv run pytest
    # TypeScript: npx vitest run
    # Rust: cargo test

  version-sync:
    # Verify pyproject.toml/package.json version matches .claude-plugin/plugin.json version

  audit:
    # Python: uv audit
    # TypeScript: npm audit
    # Rust: cargo audit
```

### Version sync check

The version in your language manifest **must** match `.claude-plugin/plugin.json`:

```bash
# Example check (Python)
PYPROJECT_VERSION=$(grep '^version' pyproject.toml | head -1 | cut -d'"' -f2)
PLUGIN_VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
if [ "$PYPROJECT_VERSION" != "$PLUGIN_VERSION" ]; then
  echo "Version mismatch: pyproject.toml=$PYPROJECT_VERSION plugin.json=$PLUGIN_VERSION"
  exit 1
fi
```

---

## MCP Resources

Servers **may** expose read-only data as MCP resources for direct access without tool calls.
Resources are useful for data Claude can reference without executing an action.

```python
# Python (FastMCP)
@mcp.resource("myservice://status")
async def service_status() -> str:
    """Current service status and configuration."""
    return json.dumps(await get_status())

@mcp.resource("myservice://items/{item_id}")
async def get_item(item_id: str) -> str:
    """Details for a specific item."""
    return json.dumps(await fetch_item(item_id))
```

```typescript
// TypeScript
server.resource("myservice://status", "Service status", async () => ({
  contents: [{ uri: "myservice://status", text: JSON.stringify(status) }],
}));
```

Resources are optional — not every server needs them. Use for data that is
frequently referenced but doesn't change often.

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
      "description": "Full MCP endpoint URL including /mcp path (e.g. https://my-service-mcp.example.com/mcp).",
      "default": "http://localhost:9000/mcp",
      "sensitive": false
    },
    "my_service_mcp_token": {
      "type": "string",
      "title": "MCP Server Bearer Token",
      "description": "Bearer token for authenticating with the MCP server. Must match MY_SERVICE_MCP_TOKEN in .env. Generate with: openssl rand -hex 32",
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

| Field | Required | Notes |
|---|---|---|
| `type` | Yes | Always `"string"` — validator requires it, docs omit it |
| `title` | Yes | Shown in install UI — validator requires it, docs omit it |
| `description` | Yes | Help text at install prompt |
| `sensitive` | Yes | `true` = encrypted, accessible only as `$CLAUDE_PLUGIN_OPTION_*` in Bash, NOT as `${user_config.*}` in `.mcp.json` or skill content. `false` = available as both `$CLAUDE_PLUGIN_OPTION_*` and `${user_config.*}` (required for `.mcp.json` substitution) |
| `default` | Recommended | Pre-fills install prompt; only meaningful for non-sensitive fields |

**Env var mapping:** `my_service_api_key` → `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`

---

### `.mcp.json`

MCP server connection config. Supports four transport types:

| Type | Use when |
|------|----------|
| `http` | **Default.** Streamable-HTTP for production deployments |
| `sse` | Server-Sent Events (legacy, prefer `http`) |
| `stdio` | Local process via stdin/stdout (dev only) |
| `ws` | WebSocket for real-time streaming |

Our servers use `http` with bearer auth. Only non-sensitive `userConfig` values support
`${user_config.*}` substitution.

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}",
      "headers": {
        "Authorization": "Bearer ${user_config.my_service_mcp_token}"
      }
    }
  }
}
```

> **Why `sensitive: false` for the MCP token?** `.mcp.json` only supports `${user_config.*}`
> substitution for non-sensitive fields. Since the `Authorization` header needs the token,
> it must be non-sensitive. This is safe because the token only grants access to the local
> MCP server — the real service credentials stay in `.env` at `chmod 600`.

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
`MY_SERVICE_MCP_TOKEN` if absent. Keeps max 3 backups, all chmod 600.

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
  [MY_SERVICE_MCP_TOKEN]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN:-}"
)

touch "$ENV_FILE"

if [ -s "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${BACKUP_DIR}/.env.bak.$(date +%s)"
fi

for key in "${!MANAGED[@]}"; do
  value="${MANAGED[$key]}"
  [ -z "$value" ] && continue
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\|]/\\&/g')
    sed -i "s|^${key}=.*|${key}=${escaped_value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
done

# Auto-generate MY_SERVICE_MCP_TOKEN if not yet set
if ! grep -q "^MY_SERVICE_MCP_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  generated=$(openssl rand -hex 32)
  echo "MY_SERVICE_MCP_TOKEN=${generated}" >> "$ENV_FILE"
  echo "sync-env: generated MY_SERVICE_MCP_TOKEN (update plugin userConfig to match)" >&2
fi

chmod 600 "$ENV_FILE"

mapfile -t baks < <(ls -t "${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "${baks[@]}"; do chmod 600 "$bak"; done
for bak in "${baks[@]:3}"; do rm -f "$bak"; done
```

**Key rules:**
- Map each userConfig key → the `.env` key Docker Compose and the server read
- Skip empty values — avoids clobbering existing `.env` when a field isn't filled in
- Auto-generate `MY_SERVICE_MCP_TOKEN` if absent — users who don't fill in the token field still get a secure default
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
  "logs/*"
  "!logs/.gitkeep"
  "__pycache__/"
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

**Every plugin must include a skill.** The skill is the bridge between Claude and the MCP
server — it documents all available actions, their parameters, and expected outputs. Without
it, Claude has no context on how to use the tools effectively.

Skills are **dual-mode**: MCP preferred, HTTP/script fallback. If the MCP server is running,
Claude uses the MCP tools. If not, the skill provides curl/script examples as a fallback so
the plugin remains functional without the server.

**Writing style requirements:**
- `description` must use **third person**: "This skill should be used when..." (not "Use when..." or "Activate when...")
- SKILL.md body must use **imperative/infinitive form** (verb-first instructions, not second person)
- Include specific trigger phrases users would say
- Target **1,500–2,000 words** for the body — move detailed content to `references/`

```markdown
---
name: my-service
description: This skill should be used when the user asks to "list resources", "get resource",
  "create X", "delete X", "check status", or mentions My Service or its domain keywords.
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

### `agents/<agent-name>.md`

Agents are autonomous subprocesses for complex multi-step tasks. Optional — only create
if the plugin needs specialized autonomous workflows.

```markdown
---
name: my-service-analyzer
description: Use this agent when the user asks to "analyze my-service performance",
  "diagnose my-service issues", or needs deep investigation of service metrics.

<example>
Context: User wants to investigate service issues
user: "Why is my-service responding slowly?"
assistant: "I'll use the my-service-analyzer agent to investigate."
<commentary>
Performance investigation requires multi-step analysis across logs, metrics, and config.
</commentary>
</example>

model: inherit
color: blue
tools: ["Read", "Grep", "Bash"]
---

You are a specialized analyst for My Service.

**Core Responsibilities:**
1. Gather metrics and logs from the service
2. Identify performance bottlenecks or errors
3. Provide actionable recommendations

**Process:**
1. Check service health via MCP tools
2. Review recent logs for errors
3. Analyze response times and resource usage
4. Report findings with specific remediation steps
```

**Required frontmatter fields:**
- `name` — lowercase, hyphens, 3–50 chars
- `description` — triggering conditions with `<example>` blocks (2–4 examples)
- `model` — `inherit` (recommended), `sonnet`, `opus`, or `haiku`
- `color` — `blue`, `cyan`, `green`, `yellow`, `magenta`, or `red`
- `tools` — (optional) restrict to specific tools; omit for full access

---

### `commands/<command>.md`

Slash commands are reusable prompts invoked as `/plugin-name:command-name`. Optional —
only create for frequently-used operations.

```markdown
---
description: Check service health and show status summary
allowed-tools: Bash(curl:*), mcp__my-service-mcp__my_service
argument-hint: [--verbose]
---

Check the health of My Service and provide a summary.

## Instructions

1. Call the my_service tool with action "health"
2. If $ARGUMENTS contains "--verbose", also call action "logs" with limit 20
3. Format results as a concise status report
```

**Frontmatter fields:**
- `description` — shown in `/help` autocomplete (under 60 chars)
- `allowed-tools` — pre-approved tools (no permission prompts)
- `argument-hint` — documents expected arguments
- `model` — (optional) `sonnet`, `opus`, or `haiku`

**Key rules:**
- Commands are instructions **for Claude**, not messages to the user
- `$ARGUMENTS` is replaced with user input after the command
- `` !`command` `` runs a shell command and injects its output as context

---

### `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`

`CLAUDE.md` is the **canonical AI memory file** — project context, conventions, and instructions
that AI coding assistants read at session start. Every plugin repo must have one.

To support all three major AI CLI tools (Claude Code, OpenAI Codex CLI, Google Gemini CLI)
without maintaining three separate files, create symlinks:

```bash
ln -sf CLAUDE.md AGENTS.md    # Codex CLI reads AGENTS.md
ln -sf CLAUDE.md GEMINI.md    # Gemini CLI reads GEMINI.md
```

**Both symlinks are committed to git.** Only edit `CLAUDE.md` — the symlinks follow automatically.

---

### `.gitignore`

Required patterns in every plugin repo. Copy this baseline and uncomment your language section.

```
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

# ── Python (uncomment if applicable) ────────────────────────────────────────
# .venv/
# __pycache__/
# *.py[oc]
# *.egg-info/
# *.egg
# dist/
# build/
# sdist/
# wheels/
# .hypothesis/
# .pytest_cache/
# .ruff_cache/
# .ty_cache/
# .mypy_cache/
# .pytype/
# .pyre/
# .pyright/
# htmlcov/
# .coverage
# .coverage.*
# coverage.xml
# .tox/
# .nox/
# pip-log.txt
# pip-wheel-metadata/
# *.whl

# ── Node/TypeScript (uncomment if applicable) ────────────────────────────────
# node_modules/
# dist/
# build/
# out/
# .next/
# .nuxt/
# coverage/
# .nyc_output/
# *.tsbuildinfo
# .eslintcache
# .stylelintcache
# .parcel-cache/
# .turbo/
# .vercel/
# *.js.map
# *.d.ts.map

# ── Rust (uncomment if applicable) ───────────────────────────────────────────
# target/
# *.db
# **/*.rs.bk
# Cargo.lock  # uncomment for libraries only, keep for binaries

# ── Go (uncomment if applicable) ─────────────────────────────────────────────
# bin/
# vendor/
# *.exe
# *.test
# *.out
# cover.out
# cover.html
# *.prof
# go.work
```

The `ensure-gitignore.sh` hook enforces `.env`, `backups/`, `logs/`, and `__pycache__/` patterns
automatically at runtime, but these must be present from the initial commit.

---

### `.env.example`

Tracked in git. All keys with placeholder values — no real credentials.

```bash
# ── Service credentials (synced from Claude Code userConfig at SessionStart) ──
MY_SERVICE_URL=https://your-service.example.com
MY_SERVICE_API_KEY=your_api_key_here

# ── MCP server ───────────────────────────────────────────────────────────────
MY_SERVICE_MCP_HOST=0.0.0.0
MY_SERVICE_MCP_PORT=9000
MY_SERVICE_MCP_TRANSPORT=http          # "http" (default) or "stdio"
MY_SERVICE_MCP_TOKEN=                  # auto-generated by sync-env.sh if absent
MY_SERVICE_MCP_NO_AUTH=false           # true = disable bearer auth (proxy-managed only)
MY_SERVICE_MCP_LOG_LEVEL=INFO

# ── Destructive operation safety ─────────────────────────────────────────────
MY_SERVICE_MCP_ALLOW_YOLO=false        # true = skip elicitation prompts
MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=false # true = auto-confirm all destructive ops

# ── Docker ───────────────────────────────────────────────────────────────────
PUID=1000
PGID=1000
DOCKER_NETWORK=my-service_mcp
```

---

### Plugin Settings (`.claude/<plugin-name>.local.md`) — optional

**Advanced pattern.** Most plugins don't need this — `userConfig` in `plugin.json` handles
standard configuration. Use this only when the plugin needs per-project settings that vary
independently of the install-time `userConfig` (e.g., agent state, feature flags, project-specific
overrides).

Plugins can store **per-project user configuration** in `.claude/<plugin-name>.local.md`.
This file uses YAML frontmatter for structured settings and a markdown body for additional
context. It is gitignored — each user has their own.

```markdown
---
enabled: true
strict_mode: false
allow_destructive: false
log_level: info
---

# My Service Plugin Configuration

Plugin is configured for standard mode.
```

**Reading settings from hooks:**

```bash
#!/bin/bash
set -euo pipefail

STATE_FILE=".claude/my-service-mcp.local.md"

# Quick exit if not configured
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi
```

**Rules:**
- File location: `.claude/<plugin-name>.local.md` (must match plugin name)
- Must be in `.gitignore` (add `.claude/*.local.md`)
- Settings changes require Claude Code restart
- Provide sensible defaults when file doesn't exist

---

### `.dockerignore`

Keeps the build context small and prevents secrets from leaking into the image.
Copy this baseline and uncomment the section for your language.

```
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

# ── Python (uncomment if applicable) ────────────────────────────────────────
# .venv
# __pycache__/
# *.py[oc]
# *.egg-info
# dist/
# .hypothesis/
# .pytest_cache/
# .ruff_cache/
# .ty_cache/
# htmlcov/
# .coverage
# coverage.xml

# ── Node/TypeScript (uncomment if applicable) ────────────────────────────────
# node_modules/
# dist/
# coverage/
# .husky/
# .nvmrc
# .prettierrc
# .prettierignore
# biome.json
# tsconfig*.json
# vitest.config.*
# pnpm-lock.yaml
# package-lock.json

# ── Rust (uncomment if applicable) ───────────────────────────────────────────
# target/
# Cargo.lock
```

---

### `Justfile`

Every plugin **must** include a `Justfile` with standard recipes. This provides a consistent
interface across all plugins regardless of language.

```just
# Default recipe — show available commands
default:
    @just --list

# ── Development ──────────────────────────────────────────────────────────────

# Start the MCP server in dev mode
dev:
    # Python: uv run python -m my_service_mcp.server
    # TypeScript: npm run dev
    # Rust: cargo run

# Run tests
test:
    # Python: uv run pytest
    # TypeScript: npx vitest run
    # Rust: cargo test

# Run linter
lint:
    # Python: uv run ruff check . && uv run ty check
    # TypeScript: npx biome check .
    # Rust: cargo clippy -- -D warnings

# Format code
fmt:
    # Python: uv run ruff format .
    # TypeScript: npx biome format --write .
    # Rust: cargo fmt

# Type check (Python/TypeScript only)
typecheck:
    # Python: uv run ty check
    # TypeScript: npx tsc --noEmit

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
    @curl -sf http://localhost:${MY_SERVICE_MCP_PORT:-9000}/health | jq . || echo "UNHEALTHY"

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

# ── Cleanup ──────────────────────────────────────────────────────────────────

# Remove build artifacts and caches
clean:
    rm -rf .cache/ dist/ build/ target/ node_modules/.cache/
    # Python: rm -rf __pycache__/ *.egg-info/
    # TypeScript: rm -rf dist/
    # Rust: cargo clean
```

Uncomment the lines for your language and remove the others. The recipe names are
standardized — `just dev`, `just test`, `just lint`, `just build`, `just up` work
the same across all plugins.

---

### `entrypoint.sh`

Container entrypoint script that validates environment before starting the server.
The Dockerfile's `CMD` should point here, not directly at the server binary.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "my-service-mcp: initializing..."

# Validate required env vars
if [ -z "${MY_SERVICE_URL:-}" ]; then
    echo "Error: MY_SERVICE_URL is required" >&2
    exit 1
fi

if [ -z "${MY_SERVICE_API_KEY:-}" ]; then
    echo "Warning: MY_SERVICE_API_KEY not set — some functionality may be limited" >&2
fi

# Set defaults
export MY_SERVICE_MCP_HOST="${MY_SERVICE_MCP_HOST:-0.0.0.0}"
export MY_SERVICE_MCP_PORT="${MY_SERVICE_MCP_PORT:-9000}"
export MY_SERVICE_MCP_TRANSPORT="${MY_SERVICE_MCP_TRANSPORT:-http}"

echo "my-service-mcp: starting server (${MY_SERVICE_MCP_TRANSPORT} on ${MY_SERVICE_MCP_HOST}:${MY_SERVICE_MCP_PORT})"

# Python
exec python3 -m my_service_mcp.server
# TypeScript
# exec node dist/index.js
# Rust
# exec my-service-mcp
```

**Rules:**
- Use `exec` to replace the shell process (proper signal handling)
- Validate required vars, warn on optional missing vars
- Never log credentials — only log config shape
- `set -euo pipefail` for strict mode
- Must be `chmod +x` in the Dockerfile

---

### `Dockerfile`

Multi-stage build with a non-root user. Adapt the base images and build commands for your
language (Python/uv, Node/pnpm, Rust/cargo, Go, etc.).

**Required patterns** (language-agnostic):

```dockerfile
# syntax=docker/dockerfile:1

# ── Build stage ─────────────────────────────────────────────────────────────────
FROM <language-base> AS builder
WORKDIR /app
# 1. Copy dependency manifest first (cache layer)
# 2. Install dependencies
# 3. Copy source and build

# ── Runtime stage ───────────────────────────────────────────────────────────────
FROM <slim-runtime-base> AS runtime
WORKDIR /app
COPY --from=builder /app/<build-output> /app/

# Non-root user
RUN mkdir -p /app/logs /app/backups

EXPOSE 9000

# Healthcheck — use wget (available in most slim images)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:9000/health || exit 1

ENTRYPOINT ["my-service-mcp-server"]
```

**Mandatory Dockerfile rules:**
- Multi-stage build — separate build and runtime stages to minimize image size
- Non-root user — never run the server as root
- `EXPOSE` the default port from `.env.example`
- `HEALTHCHECK` hitting `/health` — same endpoint the compose healthcheck uses
- Dependency manifest copied before source — leverages Docker layer caching

#### Python (uv)

```dockerfile
FROM python:3.13-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .

FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 9000
CMD ["python", "-m", "my_service_mcp.server"]
```

#### TypeScript (Node)

```dockerfile
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

#### Rust (cargo)

```dockerfile
FROM rust:1.86-slim-bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src
COPY src/ src/
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/my-service-mcp /usr/local/bin/my-service-mcp
RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home --shell /sbin/nologin app \
    && mkdir -p /data && chown app:app /data
USER 1000:1000
EXPOSE 3100
ENTRYPOINT ["my-service-mcp"]
```

---

### `docker-compose.yaml`

All configuration comes from `.env` — no hardcoded values. Supports `PUID`/`PGID` for file
ownership, named volumes, and external networks for reverse proxy integration.

```yaml
services:
  my-service-mcp:
    build: .
    container_name: my-service-mcp
    restart: unless-stopped
    user: "${PUID:-1000}:${PGID:-1000}"
    env_file: .env
    environment:
      - MY_SERVICE_MCP_ALLOW_YOLO=${MY_SERVICE_MCP_ALLOW_YOLO:-false}
      - MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=${MY_SERVICE_MCP_ALLOW_DESTRUCTIVE:-false}
    ports:
      - "${MY_SERVICE_MCP_PORT:-9000}:9000/tcp"
    volumes:
      - ${MY_SERVICE_MCP_VOLUME:-my-service-mcp-data}:/data
    networks:
      - proxy
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:9000/health || exit 1"]
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
  my-service-mcp-data:

networks:
  proxy:
    name: ${DOCKER_NETWORK:-my-service_mcp}
    external: true
```

**Key patterns:**
- `user: "${PUID}:${PGID}"` — file ownership matches host user, avoids root
- `env_file: .env` — sole source of config, no hardcoded `environment:` block
- Single named volume — `${MY_SERVICE_MCP_VOLUME:-default}` mounted at `/data`; server writes logs, cache, etc. as subdirectories
- No `backups/` mount — backups are host-side only (written by `sync-env.sh` hooks, not the container)
- External network — integrates with reverse proxy (SWAG, Traefik, Caddy)
- Resource limits — prevents runaway memory/CPU
- `wget` healthcheck — lighter than language-specific alternatives, available in most slim images

---

### SWAG Reverse Proxy Config

Every MCP server **must** ship a SWAG-compatible nginx reverse proxy config.
Place it at `<service>.subdomain.conf` in the repo root. The filename uses
the **service name without `-mcp`** — e.g., `gotify.subdomain.conf`, not `gotify-mcp.subdomain.conf`.

This is a **real, functional nginx config** — not a Jinja template. Replace the placeholder
values with the actual Tailscale IPs, ports, and domain for your service.

This config handles MCP Streamable-HTTP proxying with OAuth 2.1, origin validation,
health checks, and session management.

```nginx
## Version 2026/03/30 - MCP 2025-11-25 SWAG Compatible
# MCP Streamable-HTTP Reverse Proxy
# Service: gotify
# Domain: gotify.example.com
# Upstream: http://100.64.0.5:8080

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name gotify.example.com;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # Service UI upstream (Tailscale IP of the host running the service)
    set $upstream_app "100.64.0.5";
    set $upstream_port "8080";
    set $upstream_proto "http";

    # MCP server upstream (may be same host, different port)
    set $mcp_upstream_app "100.64.0.5";
    set $mcp_upstream_port "9000";
    set $mcp_upstream_proto "http";

    # DNS rebinding protection
    set $origin_valid 0;
    if ($http_origin = "") { set $origin_valid 1; }
    if ($http_origin = "https://$server_name") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(localhost|127\.0\.0\.1)(:[0-9]+)?$") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(.*\.)?anthropic\.com$") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(.*\.)?claude\.ai$") { set $origin_valid 1; }

    add_header X-MCP-Version "2025-11-25" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Uncomment for auth provider (authelia, authentik, etc.)
    # include /config/nginx/authelia-server.conf;

    # OAuth 2.1: /_oauth_verify, /.well-known/*, /jwks, /register,
    #            /authorize, /token, /revoke, /callback, /success, error pages
    include /config/nginx/oauth.conf;

    location /mcp {
        if ($origin_valid = 0) {
            add_header Content-Type "application/json" always;
            return 403 '{"error":"origin_not_allowed","message":"Origin header validation failed"}';
        }

        auth_request /_oauth_verify;
        auth_request_set $auth_status $upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;
        include /config/nginx/mcp.conf;

        proxy_pass $mcp_upstream_proto://$mcp_upstream_app:$mcp_upstream_port;
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

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    location ~* ^/(session|sessions) {
        auth_request /_oauth_verify;
        auth_request_set $auth_status $upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_set_header MCP-Protocol-Version $http_mcp_protocol_version;
        proxy_set_header Mcp-Session-Id $http_mcp_session_id;

        add_header Cache-Control "no-store" always;
        add_header Pragma "no-cache" always;

        proxy_pass $mcp_upstream_proto://$mcp_upstream_app:$mcp_upstream_port;
    }

    location / {
        # Uncomment for auth provider
        # include /config/nginx/authelia-location.conf;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

#### What to customize

| Value to replace | Example | Description |
|------------------|---------|-------------|
| `server_name` | `gotify.example.com` | Your FQDN (no `-mcp` suffix) |
| `$upstream_app` | `100.64.0.5` | Tailscale IP of the host running the service |
| `$upstream_port` | `8080` | Service UI port |
| `$mcp_upstream_app` | `100.64.0.5` | Tailscale IP of the host running the MCP server |
| `$mcp_upstream_port` | `9000` | MCP server port |
| Auth includes | `authelia-server.conf` | Uncomment and set to your auth provider |

#### Key design decisions

- **Tailscale IPs for upstreams** — use the device's Tailscale IP (e.g., `100.64.0.5`) instead of Docker container names, since SWAG proxies to services across the tailnet
- **Separate upstream vars** for the service UI vs MCP server — they may run on different ports or hosts
- **Origin validation** — only allows requests from the service domain, localhost, and Anthropic/Claude origins
- **`/mcp` endpoint** — OAuth-protected, includes `mcp.conf` for SSE/streaming headers
- **`/health` endpoint** — unauthenticated, short timeouts, no caching
- **`/session*` endpoints** — OAuth-protected, forwards MCP protocol headers
- **`/` catch-all** — proxies to the service UI with optional auth

---

## Codex CLI Compatibility

Every plugin **must** also work with OpenAI's Codex CLI. Since `CLAUDE.md` is symlinked to
`AGENTS.md`, Codex discovers the same project instructions automatically.

### Plugin structure mapping

Codex plugins use `.codex-plugin/` instead of `.claude-plugin/`. To support both CLIs from
a single repo, create both manifests:

```
repo-root/
├── .claude-plugin/
│   └── plugin.json           # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json           # Codex manifest (same structure, minor field differences)
├── CLAUDE.md                 # Canonical AI instructions
├── AGENTS.md -> CLAUDE.md    # Codex reads this
├── GEMINI.md -> CLAUDE.md    # Gemini CLI reads this
├── skills/                   # Shared — both CLIs discover skills here
│   └── <service>/
│       └── SKILL.md
└── .mcp.json                 # Shared — both CLIs read this
```

### Codex plugin.json

The Codex manifest lives at `.codex-plugin/plugin.json` with a compatible but slightly
different schema:

```json
{
  "name": "my-service-mcp",
  "version": "1.0.0",
  "description": "Manage My Service via MCP tools",
  "skills": "./skills/",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "homepage": "https://github.com/jmagar/my-service-mcp",
  "repository": "https://github.com/jmagar/my-service-mcp",
  "license": "MIT",
  "keywords": ["my-service", "homelab", "mcp"]
}
```

Key differences from Claude Code's `plugin.json`:
- `"skills"` field points to the skills directory (Claude Code auto-discovers)
- No `userConfig` — Codex uses `AGENTS.md` and env vars for configuration
- No `mcpServers` in manifest — Codex reads `.mcp.json` directly

### Codex marketplace

Codex supports two marketplace locations:

| Scope | Path |
|-------|------|
| Per-repo | `$REPO_ROOT/.agents/plugins/marketplace.json` |
| Personal | `~/.agents/plugins/marketplace.json` |

```json
{
  "name": "homelab-plugins",
  "interface": { "displayName": "Homelab Plugins" },
  "plugins": [{
    "name": "my-service-mcp",
    "source": {
      "source": "local",
      "path": "./path/to/my-service-mcp"
    },
    "policy": {
      "installation": "AVAILABLE",
      "authentication": "ON_INSTALL"
    },
    "category": "Infrastructure"
  }]
}
```

Codex installs plugins into `~/.codex/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION/`.

### AGENTS.md discovery

Codex builds an instruction chain by walking from the git root to the current directory:

1. **Global**: `~/.codex/AGENTS.override.md` → `~/.codex/AGENTS.md`
2. **Project**: each directory from repo root → cwd, checking `AGENTS.override.md` → `AGENTS.md`
3. Files are concatenated root-downward; closer files override earlier guidance

Default size limit is 32 KiB (`project_doc_max_bytes`). Customize in `~/.codex/config.toml`:

```toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
project_doc_max_bytes = 65536
```

### Invocation

Users invoke plugins in Codex via:
- **Natural language** — "Summarize my service status" (Codex picks the right tools)
- **Explicit** — `@my-service-mcp` to target a specific plugin

### Checklist for dual-CLI support

- [ ] `.claude-plugin/plugin.json` exists (Claude Code)
- [ ] `.codex-plugin/plugin.json` exists (Codex CLI)
- [ ] `AGENTS.md` symlinks to `CLAUDE.md`
- [ ] `GEMINI.md` symlinks to `CLAUDE.md`
- [ ] `.mcp.json` at repo root (shared by both CLIs)
- [ ] `skills/` directory with `SKILL.md` files (shared by both CLIs)

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

| Plugin | Repo | Language | Category | Default Port | Bearer Token userConfig key |
|--------|------|----------|----------|--------------|-----------------------------|
| `arcane-mcp` | `jmagar/arcane-mcp` | TypeScript | infrastructure | 44332 | `arcane_mcp_token` |
| `gotify-mcp` | `jmagar/gotify-mcp` | Python | utilities | 9158 | `gotify_mcp_token` |
| `overseerr-mcp` | `jmagar/overseerr-mcp` | Python | media | 9151 | `overseerr_mcp_token` |
| `swag-mcp` | `jmagar/swag-mcp` | Python | infrastructure | 8000 | `swag_mcp_token` |
| `synapse-mcp` | `jmagar/synapse-mcp` | TypeScript | infrastructure | 3000 | `synapse_mcp_token` |
| `syslog-mcp` | `jmagar/syslog-mcp` | Rust | observability | 3100 | `syslog_mcp_token` |
| `unifi-mcp` | `jmagar/unifi-mcp` | Python | infrastructure | 8001 | `unifi_mcp_token` |
| `unraid-mcp` | `jmagar/unraid-mcp` | Python | infrastructure | 6970 | `unraid_mcp_token` |
| `axon` | `jmagar/axon` | Rust | knowledge | 3000 | `axon_mcp_token` |

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
# Requires: mcporter, jq, running server at $MCP_URL with $MY_SERVICE_MCP_TOKEN
set -euo pipefail

MCP_URL="${MY_SERVICE_MCP_URL:-http://localhost:9000}"
TOKEN="${MY_SERVICE_MCP_TOKEN:?MY_SERVICE_MCP_TOKEN must be set}"
SERVER_NAME="my-service-mcp"
AUTH_HEADER="Authorization: Bearer $TOKEN"
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
  --header "$AUTH_HEADER" --json 2>/dev/null) || fail "schema/list" "mcporter list failed"

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
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=list 2>/dev/null) \
  && pass "action/list" || fail "action/list" "call failed"

header "Tool: my_service — action=status"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=status 2>/dev/null) \
  && pass "action/status" || fail "action/status" "call failed"

header "Tool: my_service — action=create + get + update + delete (lifecycle)"

CREATE=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=create name=test-resource 2>/dev/null)
CREATED_ID=$(echo "$CREATE" | jq -r '.id // empty')

if [ -n "$CREATED_ID" ]; then
  pass "action/create"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=get "id=$CREATED_ID" > /dev/null 2>&1 \
    && pass "action/get" || fail "action/get" "failed for id=$CREATED_ID"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=update "id=$CREATED_ID" subaction=enable > /dev/null 2>&1 \
    && pass "action/update/enable" || fail "action/update/enable" "failed"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=delete "id=$CREATED_ID" > /dev/null 2>&1 \
    && pass "action/delete" || fail "action/delete" "failed"
else
  fail "action/create" "no id in response: $CREATE"
  skip "action/get" "create failed"
  skip "action/update/enable" "create failed"
  skip "action/delete" "create failed"
fi

header "Tool: my_service — action=search"

npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=search query=test > /dev/null 2>&1 \
  && pass "action/search" || fail "action/search" "call failed"

# ── Resources (server-level, no tool name needed) ────────────────────────────
header "Resources"

npx mcporter call "${SERVER_NAME}" --http-url "$MCP_URL" --header "$AUTH_HEADER" \
  --list-resources > /dev/null 2>&1 \
  && pass "resources/list" || skip "resources/list" "no resources defined"

# ── CLI generation ─────────────────────────────────────────────────────────────
header "CLI generation"

npx mcporter generate-cli \
  --server "$SERVER_NAME" \
  --command "$MCP_URL" \
  --header "$AUTH_HEADER" \
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
  ├── Writes MY_SERVICE_MCP_TOKEN → .env (or auto-generates if absent)
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

## Development Tools Reference

Use these Claude Code skills, agents, and commands when building plugins. Don't build from
scratch — these tools enforce all the conventions in this guide.

### Plugin Creation

| Task | Tool | Type |
|------|------|------|
| Create a Claude Code plugin | `plugin-dev:create-plugin` | Command |
| Create a Codex CLI plugin | `plugin-creator` | Skill |
| Validate a Claude plugin | `plugin-dev:plugin-validator` | Agent |

### Components

| Task | Tool | Type |
|------|------|------|
| Create skills | `plugin-dev:skill-development` | Skill |
| Review skills | `plugin-dev:skill-reviewer` | Agent |
| Create hooks | `plugin-dev:hook-development` | Skill |
| Create agents | `plugin-dev:agent-development` + `plugin-dev:agent-creator` | Skill + Agent |
| Create commands | `plugin-dev:command-development` | Skill |

### MCP Servers

| Task | Tool | Type |
|------|------|------|
| Create MCP server | `mcp-server-dev:build-mcp-server` | Skill |
| Create interactive MCP app | `mcp-server-dev:build-mcp-app` | Skill |
| Create MCPB bundle | `mcp-server-dev:build-mcpb` | Skill |

### Quality & Optimization

| Task | Tool | Type |
|------|------|------|
| Generate optimal CLAUDE.md | `claude-md-management:claude-md-improver` | Skill |
| Recommend automations | `claude-code-setup:claude-automation-recommender` | Skill |
| Simplify codebase | `code-simplifier:code-simplifier` | Agent (run multiple) |

---

## Adding a New Plugin (Checklist)

### Repository setup
- [ ] **`CLAUDE.md`** — AI memory file with project conventions
- [ ] **`AGENTS.md`** → symlink to `CLAUDE.md` (Codex CLI)
- [ ] **`GEMINI.md`** → symlink to `CLAUDE.md` (Gemini CLI)
- [ ] **`README.md`** — user-facing documentation (setup, usage, API)
- [ ] **`CHANGELOG.md`** — version history
- [ ] **`LICENSE`** — MIT license
- [ ] **`.gitignore`** — secrets, caches, tool artifacts, language-specific patterns
- [ ] **`backups/.gitkeep`** and **`logs/.gitkeep`**

### Plugin manifests
- [ ] **`.claude-plugin/plugin.json`** — all userConfig fields have `type`, `title`, `description`, `sensitive`; `my_service_mcp_url` includes `/mcp` in default
- [ ] **`.codex-plugin/plugin.json`** — Codex manifest with `"skills": "./skills/"`
- [ ] **`.mcp.json`** — `url: "${user_config.my_service_mcp_url}"`, `Authorization: "Bearer ${user_config.my_service_mcp_token}"`

### Hooks
- [ ] **`hooks/hooks.json`** — SessionStart + PostToolUse structure
- [ ] **`hooks/scripts/sync-env.sh`** — maps `CLAUDE_PLUGIN_OPTION_*` → `.env`; auto-generates `MY_SERVICE_MCP_TOKEN` if absent
- [ ] **`hooks/scripts/fix-env-perms.sh`** — enforces chmod 600 on `.env` (identical across plugins)
- [ ] **`hooks/scripts/ensure-gitignore.sh`** — ensures required patterns (identical across plugins)

### MCP server
- [ ] **Server entry point** — action+subaction tool pattern + help tool; bearer auth middleware; bind `0.0.0.0`; `GET /health` unauthenticated
- [ ] **Dual transport** — supports both `http` (default) and `stdio` modes via `MY_SERVICE_MCP_TRANSPORT`
- [ ] **Middleware stack** — timing, logging, error handling, rate limiting, response limiting, bearer auth
- [ ] **Destructive ops** — confirmation gate with elicitation + YOLO mode for any data-loss actions
- [ ] **Filtering/pagination/sorting** — all list actions support `limit`, `offset`, `sort_by`, `sort_order`
- [ ] **Graceful shutdown** — handles SIGTERM/SIGINT

### Skill & agents
- [ ] **`skills/<service>/SKILL.md`** — dual-mode (MCP preferred, HTTP fallback), exhaustive trigger phrases, action+subaction reference
- [ ] **`agents/`** — specialized agents for complex workflows (optional)
- [ ] **`commands/`** — slash commands (optional)

### Configuration
- [ ] **`.env.example`** — flat prefix naming (`MY_SERVICE_*`, `MY_SERVICE_MCP_*`), includes `MY_SERVICE_MCP_TOKEN=`, `MY_SERVICE_MCP_NO_AUTH=false`, `MY_SERVICE_MCP_ALLOW_YOLO=false`, `MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=false`, `PUID=1000`, `PGID=1000`, `DOCKER_NETWORK=`
- [ ] **`pyproject.toml` / `package.json` / `Cargo.toml`** — tool caches pointed at `.cache/`

### Docker & deployment
- [ ] **`entrypoint.sh`** — env validation, `exec` for signal handling, strict mode
- [ ] **`Dockerfile`** — multi-stage build, non-root user (1000:1000), healthcheck on `/health`
- [ ] **`.dockerignore`** — exclude `.git`, build artifacts, `docs`, `tests`, `logs`, `.env`
- [ ] **`docker-compose.yaml`** — `env_file: .env`, `user: "${PUID}:${PGID}"`, destructive env vars, named volume, external network, resource limits
- [ ] **`<service>.subdomain.conf`** — SWAG reverse proxy config with Tailscale IPs (no `-mcp` suffix)

### Quality
- [ ] **`Justfile`** — standard recipes: dev, test, lint, fmt, build, up, down, health, test-live
- [ ] **`.pre-commit-config.yaml`** — language linter + `skills-ref validate`
- [ ] **`.github/workflows/ci.yml`** — lint, typecheck, test, version-sync, audit
- [ ] **`tests/test_live.sh`** — mcporter-based, tests all actions/subactions/resources, schema, auth rejection

### Publish
- [ ] **`claude plugin validate .`** — must pass with zero errors
- [ ] **`npx skills-ref validate skills/`** — must pass
- [ ] **Version sync** — `plugin.json` version matches language manifest version
- [ ] **Add to `marketplace.json`** — full metadata (name, source, description, version, category, tags, homepage)
