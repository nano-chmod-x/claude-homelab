# MCP Fleet Authentication

Authentication patterns across the 10 external MCP server repos in the homelab fleet.

## Two Authentication Boundaries

Every MCP server has two distinct auth layers:

1. **Inbound** -- MCP client (Claude Code, Codex, Gemini) authenticating to the MCP server
2. **Outbound** -- MCP server authenticating to the upstream service it wraps

```
Claude Code --[bearer token]--> MCP Server --[API key]--> Upstream Service
```

## Inbound Authentication (Client to MCP Server)

### Bearer Token

All HTTP requests to an MCP server require a bearer token in the `Authorization` header:

```
Authorization: Bearer {SERVICE_MCP_TOKEN}
```

Generate tokens with:

```bash
openssl rand -hex 32
```

### Token Environment Variables by Repo

| # | Repo | Token Env Var | Default Port |
|---|------|---------------|-------------|
| 1 | overseerr-mcp | `OVERSEERR_MCP_TOKEN` | 9151 |
| 2 | unraid-mcp | `UNRAID_MCP_BEARER_TOKEN` | 6970 |
| 3 | unifi-mcp | `UNIFI_MCP_TOKEN` | 8001 |
| 4 | gotify-mcp | `GOTIFY_MCP_TOKEN` | 9158 |
| 5 | swag-mcp | `SWAG_MCP_TOKEN` | 8012 |
| 6 | synapse-mcp | `SYNAPSE_MCP_TOKEN` | 8014 |
| 7 | arcane-mcp | `ARCANE_MCP_TOKEN` | 44332 |
| 8 | syslog-mcp | `SYSLOG_MCP_TOKEN` | 3100 |
| 9 | plugin-lab | _(dev tooling, no runtime token)_ | -- |

### No-Auth Mode

Every fleet server supports disabling bearer auth when running behind a reverse proxy (SWAG with Authelia, Cloudflare Access, etc.):

```env
# Each repo has its own flag:
OVERSEERR_MCP_NO_AUTH=true
UNRAID_MCP_DISABLE_HTTP_AUTH=true
UNIFI_MCP_NO_AUTH=true
GOTIFY_MCP_NO_AUTH=true
SWAG_MCP_NO_AUTH=true
SYNAPSE_MCP_NO_AUTH=1
SYSLOG_MCP: NO_AUTH=true
```

Only use no-auth mode when the proxy enforces its own authentication layer.

### Unauthenticated Endpoints

Every fleet server exposes `/health` without authentication:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Liveness probe -- returns `{"status": "ok"}` |

This is mandatory so load balancers and monitoring can probe without credentials.

### stdio Transport

stdio transport does not use bearer tokens. Process-level isolation provides the security boundary -- only the parent process (Claude Desktop, Codex CLI) can communicate with the server.

## Outbound Authentication (MCP Server to Upstream)

Each MCP server authenticates to its upstream service using service-specific credentials:

| Repo | Upstream Auth | Env Vars |
|------|--------------|----------|
| overseerr-mcp | API key header | `OVERSEERR_URL`, `OVERSEERR_API_KEY` |
| unraid-mcp | API key (GraphQL) | `UNRAID_API_URL`, `UNRAID_API_KEY` |
| unifi-mcp | Username/password session | `UNIFI_CONTROLLER_URL`, `UNIFI_USERNAME`, `UNIFI_PASSWORD` |
| gotify-mcp | App/client tokens | `GOTIFY_URL`, `GOTIFY_APP_TOKEN`, `GOTIFY_CLIENT_TOKEN` |
| swag-mcp | SSH/filesystem access | `SWAG_MCP_PROXY_CONFS_URI` |
| synapse-mcp | SSH key auth | Per-host SSH config |
| arcane-mcp | API key | `ARCANE_API_URL`, `ARCANE_API_KEY` |
| syslog-mcp | Direct DB access | `SYSLOG_MCP_DB_PATH` (no upstream API) |

## Plugin userConfig Integration

When installed via `plugin marketplace add`, credentials are declared in each repo's `plugin.json` under `userConfig`:

```json
{
  "userConfig": {
    "overseerr_mcp_token": {
      "type": "string",
      "title": "MCP Server Bearer Token",
      "description": "Bearer token for authenticating with the MCP server.",
      "sensitive": true
    },
    "overseerr_url": {
      "type": "string",
      "title": "Overseerr Server URL",
      "sensitive": true
    },
    "overseerr_api_key": {
      "type": "string",
      "title": "Overseerr API Key",
      "sensitive": true
    }
  }
}
```

Fields marked `"sensitive": true` are stored encrypted by the client.

## Token Bootstrap: Fail-Fast

Fleet servers must fail fast with a clear error when credentials are missing, not silently return 401s:

```
ERROR: OVERSEERR_MCP_TOKEN not set. Generate one with: openssl rand -hex 32
```

This is enforced at startup, not at first request.

## Security Best Practices

- **Never log tokens** -- not even at DEBUG level
- **No environment baking** -- never embed credentials in Docker images
- **Rotate credentials regularly** -- update `.env` and restart
- **Use HTTPS in production** -- terminate TLS at the reverse proxy
- **Dedicated API keys** -- generate service-specific keys, not personal admin keys
- **Minimal permissions** -- read-only upstream keys unless writes are needed

## See Also

- [TRANSPORT.md](TRANSPORT.md) -- Transport-specific auth behavior
- [CONNECT.md](CONNECT.md) -- Client connection patterns
- [PATTERNS.md](PATTERNS.md) -- Error handling for auth failures
