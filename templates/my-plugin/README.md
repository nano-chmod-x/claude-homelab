# My Plugin MCP

Target path relative to plugin root: `README.md`

Use this file as the plugin repo README template. Replace placeholder names, URLs, ports, and environment variable names before publishing.

## What This Plugin Provides

- Claude Code plugin manifest and marketplace metadata
- Codex plugin manifest and app metadata
- MCP server connection config
- Docker and local runtime templates
- Claude and Codex hooks, skills, and agent templates
- CI, ignore files, and live test scaffolding

## Maximal Example Policy

This template library should prefer maximal examples over minimal stubs:

- Show the full frontmatter surface for Markdown-based templates.
- Show the full commonly used field surface for JSON and TOML templates.
- Keep optional fields in the examples when they are supported by the target runtime.
- If a field is runtime-specific or uncertain, document it in a nearby README instead of guessing in the live template.

## Setup

1. Copy the relevant template files into the plugin repo.
2. Pick the language-specific variants for `Dockerfile`, `entrypoint.sh`, `Justfile`, CI, hook runner config, and ignore files.
3. Replace `my-plugin`, `my-service`, and `MY_PLUGIN` placeholders.
4. Verify that all runtime config comes from `.env`.
5. Keep bearer auth enabled for HTTP transport unless the proxy enforces auth upstream.

## Repository Layout

Expected plugin repo layout:

```text
my-plugin-mcp/
├── .claude-plugin/
├── .codex-plugin/
├── .agents/plugins/
├── .github/workflows/
├── agents/
├── commands/
├── hooks/
├── scripts/
├── skills/
├── tests/
├── .app.json
├── .env.example
├── .mcp.json
├── docker-compose.yaml
├── Dockerfile
├── entrypoint.sh
├── Justfile
├── README.md
└── my-service.subdomain.conf
```

## Release Checklist

- Update manifest versions consistently.
- Validate Claude and Codex metadata.
- Run the language-specific CI steps locally.
- Run `tests/test_live.sh` against a real server.
- Confirm the reverse proxy and `.mcp.json` agree on `/mcp`.

## Other Marketplace Plugins

Each plugin README should end with links to the other MCP plugin repos in this marketplace:

- [jmagar/axon](https://github.com/jmagar/axon)
- [jmagar/gotify-mcp](https://github.com/jmagar/gotify-mcp)
- [jmagar/unraid-mcp](https://github.com/jmagar/unraid-mcp)
- [jmagar/overseerr-mcp](https://github.com/jmagar/overseerr-mcp)
- [jmagar/unifi-mcp](https://github.com/jmagar/unifi-mcp)
- [jmagar/syslog-mcp](https://github.com/jmagar/syslog-mcp)
- [jmagar/arcane-mcp](https://github.com/jmagar/arcane-mcp)
- [jmagar/synapse-mcp](https://github.com/jmagar/synapse-mcp)
- [jmagar/swag-mcp](https://github.com/jmagar/swag-mcp)
