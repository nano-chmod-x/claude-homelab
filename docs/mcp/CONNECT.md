# Connecting to MCP Fleet Servers

How to connect to the homelab MCP fleet from every supported client.

## Plugin Marketplace (Recommended)

The simplest path. The plugin manifest handles transport, auth, and tool registration.

### Claude Code

```bash
plugin marketplace add jmagar/overseerr-mcp
plugin marketplace add jmagar/unraid-mcp
plugin marketplace add jmagar/unifi-mcp
plugin marketplace add jmagar/gotify-mcp
plugin marketplace add jmagar/swag-mcp
plugin marketplace add jmagar/synapse-mcp
plugin marketplace add jmagar/arcane-mcp
plugin marketplace add jmagar/syslog-mcp
plugin marketplace add jmagar/axon
plugin marketplace add jmagar/plugin-lab
```

After install, sensitive credentials are prompted via `userConfig` and stored encrypted by the client.

### Codex CLI

```bash
codex plugin add jmagar/overseerr-mcp
codex plugin add jmagar/unraid-mcp
# ... etc.
```

## Claude Code CLI (Manual)

### HTTP Transport

```bash
claude mcp add --transport http \
  --header "Authorization: Bearer $OVERSEERR_MCP_TOKEN" \
  overseerr-mcp https://overseerr.example.com/mcp
```

### stdio Transport

```bash
# Python (uvx)
claude mcp add overseerr-mcp -- uvx overseerr-mcp

# Rust (cargo)
claude mcp add syslog-mcp -- cargo run -p syslog-mcp
```

### Scopes

| Flag | Scope | Config File |
|------|-------|-------------|
| `--scope project` | Current project only | `.claude/settings.local.json` |
| `--scope user` | All projects (local) | `~/.claude/settings.json` |
| _(none)_ | Defaults to project | `.claude/settings.local.json` |

## Manual JSON Configuration

All clients use the same `mcpServers` JSON structure. Only the file path differs.

### Config File Locations

| Client | Scope | File |
|--------|-------|------|
| Claude Code | Project | `.claude/settings.local.json` |
| Claude Code | User | `~/.claude/settings.json` |
| Codex CLI | Project | `.codex/mcp.json` |
| Codex CLI | User | `~/.codex/mcp.json` |
| Gemini CLI | Project | `gemini-extension.json` |
| Gemini CLI | Global | `~/.gemini/gemini-extension.json` |

### HTTP Config (All Clients)

```json
{
  "mcpServers": {
    "overseerr-mcp": {
      "type": "http",
      "url": "https://overseerr.example.com/mcp",
      "headers": {
        "Authorization": "Bearer your-token-here"
      }
    },
    "unraid-mcp": {
      "type": "http",
      "url": "http://localhost:6970/mcp",
      "headers": {
        "Authorization": "Bearer your-token-here"
      }
    }
  }
}
```

### stdio Config (All Clients)

```json
{
  "mcpServers": {
    "overseerr-mcp": {
      "command": "uvx",
      "args": ["overseerr-mcp"],
      "env": {
        "OVERSEERR_URL": "https://overseerr.example.com",
        "OVERSEERR_API_KEY": "your-api-key"
      }
    }
  }
}
```

## Fleet Connection Reference

Quick reference for connecting to every fleet server via HTTP:

| Repo | Default URL | Token Env Var |
|------|------------|---------------|
| overseerr-mcp | `http://localhost:9151/mcp` | `OVERSEERR_MCP_TOKEN` |
| unraid-mcp | `http://localhost:6970/mcp` | `UNRAID_MCP_BEARER_TOKEN` |
| unifi-mcp | `http://localhost:8001/mcp` | `UNIFI_MCP_TOKEN` |
| gotify-mcp | `http://localhost:9158/mcp` | `GOTIFY_MCP_TOKEN` |
| swag-mcp | `http://localhost:8012/mcp` | `SWAG_MCP_TOKEN` |
| synapse-mcp | `http://localhost:8014/mcp` | `SYNAPSE_MCP_TOKEN` |
| arcane-mcp | `http://localhost:44332/mcp` | `ARCANE_MCP_TOKEN` |
| syslog-mcp | `http://localhost:3100/mcp` | `SYSLOG_MCP_TOKEN` |
| axon | `http://localhost:8016/mcp` | `AXON_MCP_TOKEN` |

## Verifying Connection

After configuring, verify each server is reachable:

```bash
# Health check (unauthenticated)
curl -s http://localhost:9151/health
# Expected: {"status":"ok"}

# Test a tool call via Claude Code
claude "call overseerr_help()"

# Batch health check for all fleet servers
for port in 9151 6970 8001 9158 8012 8014 44332 3100 8016; do
  echo -n "Port $port: "
  curl -sf "http://localhost:$port/health" 2>/dev/null || echo "UNREACHABLE"
done
```

### Troubleshooting

If connection fails, check:

1. **Server running** -- `docker ps | grep mcp` or `just status`
2. **Port not blocked** -- firewall allows the port
3. **Token mismatch** -- client token must match server `.env` token exactly
4. **For stdio** -- the command (`uvx`, `npx`, `cargo`) is on PATH
5. **For SWAG proxied** -- check SWAG logs and ensure the subdomain config exists

## See Also

- [AUTH.md](AUTH.md) -- Token setup and userConfig integration
- [TRANSPORT.md](TRANSPORT.md) -- Transport methods and port assignments
- [PATTERNS.md](PATTERNS.md) -- Health endpoint conventions
