# Security Guardrails

Safety and security standards enforced across all skills, scripts, and plugins.

## Credential management

### Storage

- All credentials stored in `~/.claude-homelab/.env` with `chmod 600` permissions
- Never commit `.env` or any file containing secrets
- Use `.env.example` as a tracked template with placeholder values only
- Generate MCP tokens with `openssl rand -hex 32`
- The `load-env.sh` library handles loading and validation for all scripts

### Loading credentials in scripts

Every script that needs credentials must use the shared library:

```bash
source "$REPO_ROOT/scripts/load-env.sh"
load_env_file || exit 1
validate_env_vars "SERVICE_URL" "SERVICE_API_KEY"
```

Never read credentials directly from environment variables without going through `load-env.sh`. This ensures the `.env` file is loaded from the correct location and permissions are consistent.

### Credential rotation

1. Generate new token: `openssl rand -hex 32`
2. Update `~/.claude-homelab/.env` with the new value
3. Restart any affected MCP servers
4. Update MCP client configuration with the new token
5. Verify with `/homelab-core:health`

## Never-commit rules

### .gitignore requirements

The repository `.gitignore` must include:

```
.env
*.secret
credentials.*
*.pem
*.key
```

### .dockerignore requirements

Every Dockerfile context must have a `.dockerignore` that includes:

```
.env
.git/
*.secret
credentials.*
.claude-plugin/
.omc/
.lavra/
.beads/
.cache/
```

The `.claude-plugin/`, `.omc/`, `.lavra/`, `.beads/`, and `.cache/` directories are excluded to prevent plugin metadata, orchestration state, and caches from leaking into container images.

### Pre-commit verification

Before committing, verify no secrets are staged:

```bash
git diff --cached --name-only | grep -E '\.(env|secret|pem|key)$'
```

If any matches, unstage them immediately.

## Docker security

### No baked environment

Docker images must never contain credentials at build time:

- No `ENV SERVICE_API_KEY=...` in Dockerfile
- No `COPY .env` in Dockerfile
- Credentials are injected at runtime via `--env-file` or `environment:` in compose

Verify an image has no baked credentials:

```bash
docker inspect <image>:latest | jq '.[0].Config.Env'
```

No sensitive values should appear in the output.

### Non-root execution

Containers should run as non-root (UID/GID 1000 by default). Override with `PUID` and `PGID` environment variables where supported.

### Image scanning

Run vulnerability scans before publishing images:

```bash
docker scout cves <image>:latest
```

## Network security

### HTTPS in production

- All service URLs should use `https://` in production
- Use valid TLS certificates (Let's Encrypt via SWAG or similar)
- HTTP is acceptable only for local development on trusted networks

### Token authentication

- MCP servers require bearer token authentication by default
- Token sent as `Authorization: Bearer <token>` header
- Disable auth only behind a trusted reverse proxy (set `*_MCP_NO_AUTH=true`)
- Fail fast with a clear error on missing or invalid tokens -- silent 401s are worse than explicit failures

### Health endpoints

- `/health` is unauthenticated -- required for container liveness probes
- Returns only status information, never credentials or internal state
- All other MCP endpoints require bearer authentication

## Input handling

For detailed patterns with code examples, see [references/security-patterns.md](references/security-patterns.md).

The key rules:

- **Sanitize user input** before using in commands, URLs, or API calls
- **URL-encode** all user-supplied values in query parameters
- **Never interpolate** user input directly into shell commands or SQL
- **Use parameterized queries** for any database access
- **Validate file paths** to prevent directory traversal
- **Validate JSON responses** before parsing
- **Reject unexpected parameter types** early

## Logging

- Never log credentials, tokens, or API keys -- not even at DEBUG level
- Mask sensitive headers in request logs (strip `Authorization` headers)
- Log file permissions should be restrictive (`chmod 640`)
- Rotate logs to prevent disk exhaustion

## Destructive operations

Actions that delete or modify data irreversibly are gated in MCP servers:

- Tool calls require `confirm=True` parameter
- Without confirmation, the server returns an error explaining what would happen
- Server-wide bypass via `ALLOW_DESTRUCTIVE=true` (automated environments only)
- `ALLOW_YOLO=true` is an alias for the same behavior
- Never enable destructive bypass in production without understanding the implications

## Skill script standards

All skill scripts in `skills/*/scripts/` must:

1. Start with `set -euo pipefail` (strict mode)
2. Load credentials via `load-env.sh`
3. Quote all variables: `"$var"`
4. Validate required environment variables before making API calls
5. Return structured JSON output
6. Handle errors gracefully with meaningful messages
7. Support `--help` flag for usage information
8. Never expose credentials in error output
