# Technology Choices — claude-homelab

Technology stack reference for the claude-homelab skill collection.

## Important distinction

claude-homelab is **not** an MCP server. It is a Bash-centric skill collection that integrates with self-hosted homelab services via shell scripts calling upstream APIs with `curl`. The external MCP server repos (overseerr-mcp, synapse-mcp, syslog-mcp, etc.) each have their own tech stacks and are documented separately.

## Primary language

| Language | Version | Usage | Coverage |
| --- | --- | --- | --- |
| Bash | 4+ | All skills, scripts, credential loading, install/setup | ~95% of codebase |

Bash was chosen because every skill follows the same pattern: load credentials from `.env`, call an upstream REST API with `curl`, parse the JSON response with `jq`, and return structured output. No compilation, no dependency installation, no runtime beyond a POSIX shell.

## Shell tools

These are the core tools that Bash scripts depend on:

| Tool | Purpose | Used by |
| --- | --- | --- |
| `curl` | HTTP requests to upstream service APIs | Every skill script |
| `jq` | JSON parsing, filtering, and formatting | Every skill script |
| `openssl` | Token generation, hash computation | Auth scripts, setup |
| `git` | Version control, branch management | Repository workflows |
| `chmod` | File permissions (credential security) | Setup scripts |
| `ln` | Symlink creation | Install scripts |
| `timeout` | Command timeout protection | Health check scripts |

## Credential loading library

The shared library at `scripts/load-env.sh` provides three functions:

| Function | Purpose |
| --- | --- |
| `load_env_file` | Sources `~/.claude-homelab/.env` (or an explicit path) |
| `validate_env_vars` | Checks that required variables are set and non-empty |
| `load_service_credentials` | Combines load + validate for a service's URL and API key |

All skill scripts source this library. It uses `set -a` / `set +a` to export variables from the env file.

## Optional languages

Some skills use Python or Node.js for capabilities beyond what Bash can handle:

| Language | Version | Skills | Reason |
| --- | --- | --- | --- |
| Python | 3.11+ | Some skill scripts | Complex API interactions, data processing |
| Node.js | 18+ | NotebookLM | Google API client library requirement |

These are optional: the majority of skills work with Bash alone.

## Task runner

| Tool | Config file | Purpose |
| --- | --- | --- |
| `just` | `Justfile` | Build, test, lint, deploy recipes |

The Justfile provides ~30 recipes for validation, compose operations, MCP server management, testing, linting, and status dashboards. It replaces most manual script invocations.

## Docker (optional)

Docker is used for optional containerization of external MCP server plugins, not for the core skill collection itself:

| Tool | Version | Purpose |
| --- | --- | --- |
| Docker | 24+ | Container builds for MCP server plugins |
| Docker Compose | v2+ | Multi-container orchestration |

The core skills run directly on the host via Bash and do not require Docker.

## Script patterns

All Bash scripts follow consistent patterns:

```bash
#!/bin/bash
set -euo pipefail

# Source shared credential library
source "$HOME/.claude-homelab/load-env.sh"
load_env_file || exit 1
validate_env_vars "SERVICE_URL" "SERVICE_API_KEY"

# Make API call
response=$(curl -sf \
    -H "X-Api-Key: $SERVICE_API_KEY" \
    "$SERVICE_URL/api/v1/endpoint")

# Parse and output JSON
echo "$response" | jq '{
    success: true,
    data: .
}'
```

## What this repo does NOT use

To avoid confusion with the external MCP server repos in the marketplace:

- No MCP SDK (Python FastMCP, TypeScript MCP SDK, or Rust MCP crates)
- No MCP transport layer (stdio, HTTP+SSE, streamable-http)
- No web framework (FastAPI, Express, axum)
- No compiled artifacts or build steps for core skills
- No package managers beyond system packages (no `pip`, `npm`, `cargo` for core)

## External MCP server tech stacks

For reference, the 10 external MCP server repos use their own stacks:

| Plugin | Language | Framework |
| --- | --- | --- |
| overseerr-mcp | Python | FastMCP |
| unraid-mcp | Python | FastMCP |
| unifi-mcp | Python | FastMCP |
| gotify-mcp | Python | FastMCP |
| arcane-mcp | Python | FastMCP |
| swag-mcp | Python | FastMCP |
| synapse-mcp | TypeScript | MCP SDK + Express |
| syslog-mcp | Rust | axum + tokio |
| plugin-lab | Mixed | Templates for all three |

Each is documented in its own repository.

## Cross-references

- [ARCH](ARCH.md) — architecture and data flow
- [PRE-REQS](PRE-REQS.md) — prerequisites for development and usage
