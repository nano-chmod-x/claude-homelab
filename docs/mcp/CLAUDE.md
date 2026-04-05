# MCP Fleet Documentation

Documentation for the homelab MCP fleet -- 10 external MCP server repos managed alongside the claude-homelab core plugin.

These docs cover fleet-level patterns and conventions. For individual server internals, see each repo's own documentation.

## Fleet Repos

| # | Repo | Category | Language | Description |
|---|------|----------|----------|-------------|
| 1 | [overseerr-mcp](https://github.com/jmagar/overseerr-mcp) | media | Python | Overseerr media requests |
| 2 | [unraid-mcp](https://github.com/jmagar/unraid-mcp) | infrastructure | Python | Unraid server management via GraphQL |
| 3 | [unifi-mcp](https://github.com/jmagar/unifi-mcp) | infrastructure | Python | UniFi network management |
| 4 | [gotify-mcp](https://github.com/jmagar/gotify-mcp) | utilities | Python | Gotify push notifications |
| 5 | [swag-mcp](https://github.com/jmagar/swag-mcp) | infrastructure | Python | SWAG reverse proxy configuration |
| 6 | [synapse-mcp](https://github.com/jmagar/synapse-mcp) | infrastructure | Python | Docker (Flux) and SSH (Scout) operations |
| 7 | [arcane-mcp](https://github.com/jmagar/arcane-mcp) | infrastructure | TypeScript | Docker management via Arcane API |
| 8 | [syslog-mcp](https://github.com/jmagar/syslog-mcp) | infrastructure | Rust | Syslog receiver and log search |
| 9 | [plugin-lab](https://github.com/jmagar/plugin-lab) | dev-tools | Mixed | Plugin scaffolding and templates |

## Documentation Index

| File | Contents |
|------|----------|
| [AUTH.md](AUTH.md) | Inbound/outbound auth, bearer tokens, token env vars, no-auth mode, userConfig |
| [TOOLS.md](TOOLS.md) | 2-tool pattern, action/subaction dispatch, destructive gates, response format |
| [TRANSPORT.md](TRANSPORT.md) | stdio, HTTP/SSE, streamable-http, port assignments, Docker networking |
| [CONNECT.md](CONNECT.md) | Plugin install, CLI config, manual JSON config for Claude/Codex/Gemini |
| [PATTERNS.md](PATTERNS.md) | Error handling, health endpoints, pagination, rate limiting, logging |

## Key Conventions

- **2-tool pattern**: action router + help companion per server
- **Bearer tokens**: `{SERVICE}_MCP_TOKEN` env var, generated with `openssl rand -hex 32`
- **Health endpoint**: `GET /health` is always unauthenticated
- **Fail-fast**: missing credentials cause startup failure, not silent 401s
- **No env baking**: credentials are never embedded in Docker images
- **Unique ports**: each server gets a dedicated port (see [TRANSPORT.md](TRANSPORT.md))

## Related

- [claude-homelab CLAUDE.md](../../CLAUDE.md) -- Main project guidelines
- [.env.example](../../.env.example) -- All MCP token env vars
- [marketplace.json](../../.claude-plugin/marketplace.json) -- Plugin catalog
- [skills/CLAUDE.md](../../skills/CLAUDE.md) -- Bundled skill development guidelines
