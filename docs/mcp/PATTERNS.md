# MCP Fleet Common Patterns

Shared implementation patterns and conventions across the 10 external MCP server repos.

## Action + Subaction Dispatch

The canonical routing pattern. A single tool entry point dispatches to handlers by `action` and optional `subaction`.

```python
# Python (FastMCP) -- used by most fleet servers
@app.tool()
async def my_service(action: str, subaction: str | None = None, **kwargs) -> str:
    match action:
        case "docker":
            match subaction:
                case "list":  return await docker_list(**kwargs)
                case "start": return await docker_start(**kwargs)
                case _: raise ToolError(f"Unknown subaction: {subaction}")
        case _:
            raise ToolError(f"Unknown action: {action}")
```

```rust
// Rust (syslog-mcp, axon) -- enum-based dispatch
#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case")]
enum Action {
    SearchLogs { query: String, hostname: Option<String> },
    TailLogs { n: Option<u32> },
    GetStats,
}
```

## Error Handling

### MCP Error Response Format

All fleet servers return errors with the `isError` flag:

```json
{
  "content": [
    {"type": "text", "text": "Failed to list containers: connection refused (synapse at 192.168.1.10)"}
  ],
  "isError": true
}
```

### Error Categories

| Category | Description | Example |
|----------|-------------|---------|
| ValidationError | Invalid action, subaction, or missing parameter | `Unknown action: foobar` |
| NotFoundError | Resource does not exist | `Container not found: abc-123` |
| AuthError | Upstream rejected credentials | `Upstream returned 401: invalid API key` |
| TimeoutError | Upstream did not respond in time | `Request timed out after 30s` |
| ConnectionError | Cannot reach upstream | `Connection refused: unraid.local:443` |

### Error Middleware Pattern

```python
async def safe_call(fn, *args, **kwargs):
    try:
        return await asyncio.wait_for(fn(*args, **kwargs), timeout=30)
    except asyncio.TimeoutError:
        raise ToolError("Upstream request timed out after 30s")
    except httpx.HTTPStatusError as e:
        raise ToolError(f"Upstream returned {e.response.status_code}: {e.response.text[:200]}")
    except Exception as e:
        raise ToolError(f"Unexpected error: {e}")
```

### HTTP Status Codes (REST Fallback)

| Code | Meaning | When |
|------|---------|------|
| 200 | Success | Normal tool response |
| 401 | Unauthorized | Missing or invalid bearer token |
| 403 | Forbidden | Token valid but insufficient permissions |
| 404 | Not found | Unknown tool or resource |
| 500 | Server error | Unhandled exception |

## Health Endpoint

Every fleet server exposes `GET /health` -- unauthenticated, for liveness probes.

### Basic Health

```json
{"status": "ok"}
```

### Extended Health (Optional)

Some servers include upstream reachability:

```json
{
  "status": "degraded",
  "upstream": "unreachable",
  "version": "1.2.0"
}
```

### Docker Healthcheck

```yaml
healthcheck:
  test: ["CMD", "curl", "-sf", "http://localhost:${PORT}/health"]
  interval: 30s
  timeout: 5s
  retries: 3
```

## Pagination and Filtering

Fleet servers use consistent pagination and filtering patterns:

### Offset-Based Pagination

```json
{"action": "notification", "subaction": "list", "limit": 20, "offset": 0}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | int | 20-100 | Max results per page |
| `offset` | int | 0 | Number of results to skip |

### Filtering

```json
{"action": "container", "subaction": "list", "host": "tower"}
{"action": "container", "subaction": "search", "query": "plex"}
```

Filters are action-specific but follow consistent naming: `query` for text search, `host`/`hostname` for host filtering, `type`/`status` for enum filtering.

## Rate Limiting

Some fleet servers implement rate limiting to protect upstream services:

| Repo | Rate Limit | Env Vars |
|------|-----------|----------|
| swag-mcp | 10 RPS / burst 20 | `SWAG_MCP_RATE_LIMIT_ENABLED`, `SWAG_MCP_RATE_LIMIT_RPS`, `SWAG_MCP_RATE_LIMIT_BURST` |

Rate limiting is disabled by default. Enable for production deployments with high-traffic upstreams.

### Retry Logic

Fleet servers with retry middleware:

```env
SWAG_MCP_ENABLE_RETRY_MIDDLEWARE=true
SWAG_MCP_MAX_RETRIES=3
```

Default behavior: no retries. Enable explicitly when upstream services are flaky.

## Logging Conventions

### Log Level Configuration

Every server supports a log level env var:

| Repo | Env Var | Default |
|------|---------|---------|
| overseerr-mcp | `OVERSEERR_LOG_LEVEL` | DEBUG |
| unraid-mcp | `UNRAID_MCP_LOG_LEVEL` | INFO |
| unifi-mcp | `UNIFI_LOCAL_MCP_LOG_LEVEL` | DEBUG |
| gotify-mcp | `GOTIFY_LOG_LEVEL` | DEBUG |
| swag-mcp | `SWAG_MCP_LOG_LEVEL` | INFO |
| syslog-mcp | `RUST_LOG` | info |
| axon | `AXON_LOG_LEVEL` | INFO |

### Structured Logging (Optional)

```env
SWAG_MCP_ENABLE_STRUCTURED_LOGGING=false
SWAG_MCP_LOG_PAYLOADS=false
SWAG_MCP_LOG_PAYLOAD_MAX_LENGTH=1000
SWAG_MCP_SLOW_OPERATION_THRESHOLD_MS=1000
```

### Log to File

Some servers support file logging:

```env
SWAG_MCP_LOG_FILE_ENABLED=true
SWAG_MCP_LOG_FILE_MAX_BYTES=10485760
UNIFI_LOCAL_MCP_LOG_FILE=unifi_local_mcp.log
```

### Critical Rule: Never Log Tokens

Bearer tokens and API keys must never appear in logs at any level, including DEBUG.

## Bearer Auth Middleware

Standard middleware pattern across the fleet:

```python
class BearerAuth:
    async def authenticate(self, request):
        if os.getenv("MY_SERVICE_MCP_NO_AUTH", "").lower() in ("true", "1"):
            return  # Auth disabled (behind reverse proxy)

        token = os.environ["MY_SERVICE_MCP_TOKEN"]
        header = request.headers.get("Authorization", "")
        if header != f"Bearer {token}":
            raise HTTPException(401, "Invalid or missing bearer token")
```

- **401**: missing or wrong token
- **403**: token valid but operation not permitted (rare -- most servers are all-or-nothing)
- `/health` is always excluded from auth middleware

## Destructive Operation Gate

Two-call confirmation for dangerous actions:

```python
async def handle_delete(item_id: int, confirm: bool = False):
    if not confirm:
        return f"WARNING: This will permanently delete item {item_id}. Re-call with confirm=True to proceed."
    await client.delete(f"/items/{item_id}")
    return f"Deleted item {item_id}"
```

Override with `{SERVICE}_MCP_ALLOW_YOLO=true` for automated pipelines (CI only).

## Graceful Shutdown

Handle SIGTERM and SIGINT for clean container stops:

```python
import signal, asyncio

async def shutdown(sig, loop):
    logger.info(f"Received {sig.name}, shutting down...")
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()
```

## No Environment Baking

Credentials are never embedded in Docker images. All secrets are injected at runtime via `.env` files or Docker secrets. Images must be publishable to public registries without exposing credentials.

## See Also

- [AUTH.md](AUTH.md) -- Authentication details
- [TOOLS.md](TOOLS.md) -- Tool design philosophy
- [TRANSPORT.md](TRANSPORT.md) -- Transport methods
