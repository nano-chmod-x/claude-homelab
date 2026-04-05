# MCP Fleet Tool Design

Tool design philosophy and conventions across the 10 external MCP server repos.

## The 2-Tool Pattern

Every fleet server exposes exactly two MCP tools:

1. **Action router** -- single entry point that dispatches to handlers via `action` and optional `subaction`
2. **Help companion** -- returns markdown reference for all available operations

This keeps the MCP tool surface small (2 tools per server) while supporting arbitrarily large action spaces. Clients call the help tool first to discover operations, then call the action router.

## Tool Names by Repo

| # | Repo | Action Router | Help Companion |
|---|------|--------------|----------------|
| 1 | overseerr-mcp | `search_media`, `request_movie`, `request_tv_show`, `get_movie_details`, `get_tv_show_details`, `list_failed_requests` | `overseerr_help` |
| 2 | unraid-mcp | `unraid` | `unraid_help` |
| 3 | unifi-mcp | `unifi` | `unifi_help` |
| 4 | gotify-mcp | _(OAuth-gated)_ | _(OAuth-gated)_ |
| 5 | swag-mcp | `swag` | `swag_help` |
| 6 | synapse-mcp | `flux`, `scout` | `synapse_help` |
| 7 | arcane-mcp | _(OAuth-gated)_ | _(OAuth-gated)_ |
| 8 | syslog-mcp | `search_logs`, `tail_logs`, `get_errors`, `list_hosts`, `correlate_events`, `get_stats` | `syslog_help` |
| 9 | plugin-lab | _(dev tooling)_ | -- |
| 10 | axon | _(research tooling)_ | -- |

**Note:** Some servers (overseerr-mcp, syslog-mcp) use multiple focused tools instead of a single action router. This is acceptable when actions have fundamentally different parameter schemas. The help companion pattern still applies.

**Note:** Synapse-mcp exposes two action routers (`flux` for Docker, `scout` for SSH) because they manage distinct infrastructure domains with separate parameter spaces.

## Action/Subaction Dispatch

The canonical input schema for a unified action router:

```json
{
  "action": "<action>",
  "subaction": "<subaction>",
  "id": "<resource-id>",
  "params": { "<key>": "<value>" }
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | enum | yes | Resource domain to operate on |
| `subaction` | enum | yes | Operation within the domain |
| Additional params | varies | no | Action-specific parameters |

### Example: unraid-mcp

```json
{"action": "docker", "subaction": "list"}
{"action": "system", "subaction": "overview"}
{"action": "array", "subaction": "parity_status"}
{"action": "vm", "subaction": "start", "vm_id": "my-vm", "confirm": true}
```

### Example: synapse-mcp (flux)

```json
{"action": "container", "subaction": "list"}
{"action": "container", "subaction": "stop", "container_id": "abc123"}
{"action": "compose", "subaction": "status"}
```

### Example: swag-mcp

```json
{"action": "list", "list_filter": "active"}
{"action": "create", "config_name": "jellyfin.subdomain.conf", "server_name": "jellyfin.example.com", "upstream_app": "jellyfin", "upstream_port": 8096}
{"action": "health_check", "domain": "media.example.com"}
```

## Destructive Operation Gates

Operations that modify or delete data use a two-call confirmation pattern:

### Confirmation Flow

1. Client calls destructive operation without `confirm`:
   ```json
   {"action": "vm", "subaction": "force_stop", "vm_id": "my-vm"}
   ```

2. Server returns a warning prompt:
   ```
   WARNING: This will forcibly stop VM my-vm. Re-call with confirm: true to proceed.
   ```

3. Client re-calls with confirmation:
   ```json
   {"action": "vm", "subaction": "force_stop", "vm_id": "my-vm", "confirm": true}
   ```

### Safety Environment Variables

Each repo supports overriding the confirmation gate:

| Variable Pattern | Default | Effect |
|-----------------|---------|--------|
| `{SERVICE}_MCP_ALLOW_DESTRUCTIVE` | `false` | Auto-confirms destructive operations |
| `{SERVICE}_MCP_ALLOW_YOLO` | `false` | Skips confirmation entirely (implies destructive) |

Repos with these flags:

| Repo | ALLOW_DESTRUCTIVE | ALLOW_YOLO |
|------|------------------|------------|
| unraid-mcp | `UNRAID_MCP_ALLOW_DESTRUCTIVE` | `UNRAID_MCP_ALLOW_YOLO` |
| synapse-mcp | `SYNAPSE_MCP_ALLOW_DESTRUCTIVE` | -- |
| arcane-mcp | `ARCANE_MCP_ALLOW_DESTRUCTIVE` | `ARCANE_MCP_ALLOW_YOLO` |

These are intended for CI/testing only. Never enable in production.

## Response Format

All tool responses use MCP text content blocks with markdown formatting:

```json
{
  "content": [
    {
      "type": "text",
      "text": "## Containers\n\n| Name | Status | Uptime |\n|------|--------|--------|\n| plex | running | 3d 12h |"
    }
  ]
}
```

Conventions:
- **Tables** for list results
- **Structured text** for single-resource details
- **Markdown headings** for section separation
- **`isError: true`** flag on error responses

## Error Responses

Errors follow a consistent format across the fleet:

```json
{
  "content": [
    {"type": "text", "text": "Error: container not found (id: abc-123)"}
  ],
  "isError": true
}
```

Common error categories:
- **ValidationError** -- invalid action, subaction, or missing required parameter
- **NotFoundError** -- resource ID does not exist
- **AuthError** -- upstream API rejected credentials
- **TimeoutError** -- upstream service did not respond

## Help Tool Convention

Every fleet server ships a `*_help` tool that takes no parameters and returns markdown listing all actions, subactions, required parameters, and examples:

```json
{"name": "unraid_help", "arguments": {}}
```

This is the client's first point of reference for discovering available operations.

## See Also

- [AUTH.md](AUTH.md) -- Authentication required before tool calls
- [PATTERNS.md](PATTERNS.md) -- Implementation patterns for tools
- [CONNECT.md](CONNECT.md) -- How clients discover and call tools
