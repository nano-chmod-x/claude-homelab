# MCP Fleet Transport Methods

Transport configuration across the 10 external MCP server repos.

## Supported Transports

| Transport | Auth | Use Case | Config Value |
|-----------|------|----------|--------------|
| stdio | None (process isolation) | Claude Desktop, local dev | `stdio` |
| HTTP/SSE | Bearer token | Docker, remote servers | `http` |
| Streamable-HTTP | Bearer token | Docker, remote (recommended) | `streamable-http` |

## Transport by Repo

| # | Repo | Default Transport | Transport Env Var | Language |
|---|------|-------------------|-------------------|----------|
| 1 | overseerr-mcp | streamable-http | `OVERSEERR_MCP_TRANSPORT` | Python |
| 2 | unraid-mcp | streamable-http | `UNRAID_MCP_TRANSPORT` | Python |
| 3 | unifi-mcp | http | -- | Python |
| 4 | gotify-mcp | http | `GOTIFY_MCP_TRANSPORT` | Python |
| 5 | swag-mcp | http | -- | Python |
| 6 | synapse-mcp | http | -- | Python |
| 7 | arcane-mcp | http | `ARCANE_MCP_TRANSPORT` | TypeScript |
| 8 | syslog-mcp | http | `SYSLOG_MCP_TRANSPORT` | Rust |
| 9 | plugin-lab | -- | -- | Mixed |
| 10 | axon | http | -- | Rust |

## stdio

JSON-RPC messages over stdin/stdout. No network listener, no auth required -- the parent process owns the communication channel.

```env
MY_PLUGIN_MCP_TRANSPORT=stdio
```

**When to use:**
- Local development with Claude Desktop or Codex CLI
- Single-user setups where the MCP server runs as a child process
- No network exposure needed

**Security:** Process-level isolation provides the boundary. Only the parent process can communicate with the server.

## HTTP/SSE

HTTP server with Server-Sent Events for streaming responses. Requires bearer token authentication.

### Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/mcp` | POST | Bearer | MCP JSON-RPC endpoint |
| `/sse` | GET | Bearer | Server-Sent Events stream |
| `/health` | GET | None | Liveness probe |

**When to use:**
- Docker deployments
- Remote/shared MCP server
- Behind a reverse proxy (SWAG, nginx, Caddy)

## Streamable-HTTP

Enhanced HTTP transport with proper streaming support. The newest transport method, recommended for new deployments.

### Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/mcp` | POST | Bearer | MCP JSON-RPC with streaming responses |
| `/health` | GET | None | Liveness probe |

**When to use:**
- New deployments (preferred over HTTP/SSE)
- Long-running operations that benefit from streaming progress
- Clients that support streamable-http (Claude Code, latest MCP SDK versions)

## Port Assignments

Each fleet server uses a unique port to avoid conflicts:

| # | Repo | Default Port | Host Env Var | Port Env Var |
|---|------|-------------|-------------|-------------|
| 1 | overseerr-mcp | 9151 | `OVERSEERR_MCP_HOST` | `OVERSEERR_MCP_PORT` |
| 2 | unraid-mcp | 6970 | `UNRAID_MCP_HOST` | `UNRAID_MCP_PORT` |
| 3 | unifi-mcp | 8001 | `UNIFI_MCP_HOST` | `UNIFI_MCP_PORT` |
| 4 | gotify-mcp | 9158 | `GOTIFY_MCP_HOST` | `GOTIFY_MCP_PORT` |
| 5 | swag-mcp | 8012 | `SWAG_MCP_HOST` | `SWAG_MCP_PORT` |
| 6 | synapse-mcp | 8014 | `SYNAPSE_MCP_HOST` | `SYNAPSE_MCP_PORT` |
| 7 | arcane-mcp | 44332 | -- | `ARCANE_MCP_PORT` |
| 8 | syslog-mcp | 3100 | `SYSLOG_MCP_HOST` | `SYSLOG_MCP_PORT` |
| 9 | plugin-lab | -- | -- | -- |
| 10 | axon | 8016 | `AXON_MCP_HOST` | `AXON_MCP_PORT` |

All servers bind to `0.0.0.0` by default so they are reachable from the Docker network and reverse proxy.

## Docker Networking

Fleet servers run as Docker containers on a shared bridge network:

```yaml
services:
  overseerr-mcp:
    image: ghcr.io/jmagar/overseerr-mcp:latest
    ports:
      - "9151:9151"
    env_file: .env
    networks:
      - mcp-network
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:9151/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  mcp-network:
    driver: bridge
```

Container-to-container communication uses Docker DNS (service names), while external access goes through SWAG reverse proxy.

## Transport Selection Guide

```
Local dev with Claude Desktop?
  -> stdio (no setup needed)

Running in Docker or on a remote host?
  -> streamable-http (modern, streaming support)
  -> http (wider client compatibility)

Behind SWAG with Authelia?
  -> http or streamable-http + {SERVICE}_MCP_NO_AUTH=true
  -> SWAG handles TLS termination and authentication
```

## See Also

- [AUTH.md](AUTH.md) -- Bearer token setup for HTTP transports
- [CONNECT.md](CONNECT.md) -- Client configuration for each transport
