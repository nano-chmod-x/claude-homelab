# Plugin Manifest Reference -- claude-homelab

Structure and conventions for plugin manifest files across Claude Code, Codex, and Gemini platforms.

## File locations

| Platform | Path | Required |
| --- | --- | --- |
| Claude Code | `.claude-plugin/plugin.json` | yes |
| Codex | `.codex-plugin/plugin.json` | yes |
| Gemini | `gemini-extension.json` | optional |

All manifests must declare the same version. The current version across all files is **1.4.0**.

## Claude / Codex manifest

`.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` share nearly identical structure.

### Required fields

```json
{
  "name": "homelab-core",
  "version": "1.4.0",
  "description": "Core homelab agents, commands, and setup/health skills for self-hosted service management.",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "repository": "https://github.com/jmagar/claude-homelab",
  "license": "MIT"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | kebab-case, matches repo name |
| `version` | string | Semver -- synced across all manifests |
| `description` | string | One sentence, no period |
| `author` | object | `name` and `email` required |
| `repository` | string | Full GitHub URL |
| `license` | string | SPDX identifier |

### Optional fields

| Field | Type | Notes |
| --- | --- | --- |
| `homepage` | string | Plugin homepage or docs URL |
| `keywords` | string[] | Discovery tags (e.g., `["homelab", "skills", "agents"]`) |
| `mcpServers` | object | MCP server declarations (transport + auth) |
| `userConfig` | object | User-facing configuration schema |
| `skills` | string | Path to skills directory (e.g., `"./skills/"`) |
| `interface` | object | UI metadata for marketplace display |

### Codex-specific fields

The `.codex-plugin/plugin.json` includes an `interface` block for marketplace display:

```json
{
  "interface": {
    "displayName": "Claude Homelab",
    "shortDescription": "Homelab workflows, setup, and service health",
    "longDescription": "Bundle reusable homelab agents, commands, and service skills...",
    "developerName": "Jacob Magar",
    "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "websiteURL": "https://github.com/jmagar/claude-homelab",
    "defaultPrompt": [
      "Check the health of my homelab services.",
      "Help me configure credentials for a new homelab service."
    ],
    "brandColor": "#2563EB"
  }
}
```

### userConfig schema

Defines settings the user provides at install time. Values are accessible to hooks and MCP servers.

```json
{
  "userConfig": {
    "my_plugin_url": {
      "type": "string",
      "title": "Service URL",
      "description": "Base URL of your service instance",
      "default": "http://localhost:8000",
      "sensitive": false
    },
    "my_plugin_token": {
      "type": "string",
      "title": "API Token",
      "description": "API token for authentication",
      "sensitive": true
    }
  }
}
```

Fields marked `sensitive: true` are masked in logs and UI.

### mcpServers configuration

Two transport modes:

**stdio** -- subprocess spawned by Claude Code:

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "stdio",
      "command": "uv",
      "args": ["run", "--directory", "${CLAUDE_PLUGIN_ROOT}", "my_plugin"]
    }
  }
}
```

**HTTP** -- remote server with bearer auth:

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "http",
      "url": "${user_config.my_plugin_url}/mcp",
      "headers": {
        "Authorization": "Bearer ${user_config.my_plugin_token}"
      }
    }
  }
}
```

| Variable | Scope | Description |
| --- | --- | --- |
| `${CLAUDE_PLUGIN_ROOT}` | runtime | Absolute path to the plugin directory |
| `${user_config.<key>}` | runtime | Value from userConfig |

## Gemini manifest

`gemini-extension.json` uses a Gemini-specific format with a flat `settings` array instead of `userConfig`:

```json
{
  "name": "claude-homelab",
  "version": "1.4.0",
  "description": "Core homelab agents, commands, and setup/health skills...",
  "author": "Jacob Magar <jmagar@users.noreply.github.com>",
  "contextFileName": "GEMINI.md",
  "settings": [
    {
      "envVar": "PLEX_URL",
      "description": "Plex URL",
      "sensitive": false
    },
    {
      "envVar": "PLEX_TOKEN",
      "description": "Plex Token",
      "sensitive": true
    }
  ]
}
```

The `contextFileName` field points to the skill context file that Gemini loads (defaults to `GEMINI.md` in `skills/`).

The `settings` array maps directly to environment variables. Each entry has:

| Field | Description |
| --- | --- |
| `envVar` | Environment variable name |
| `description` | Human-readable label |
| `sensitive` | Whether to mask the value |

## Version sync

All manifests must declare identical versions. Files to update on every bump:

| File | Field |
| --- | --- |
| `.claude-plugin/plugin.json` | `"version"` |
| `.codex-plugin/plugin.json` | `"version"` |
| `gemini-extension.json` | `"version"` |
| `.claude-plugin/marketplace.json` | `metadata.version` |
| `CHANGELOG.md` | New entry |

Bump type follows commit message prefix:
- `feat!:` or `BREAKING CHANGE` -- **major** (X+1.0.0)
- `feat` or `feat(...)` -- **minor** (X.Y+1.0)
- Everything else -- **patch** (X.Y.Z+1)

## Cross-references

- [CONFIG.md](CONFIG.md) -- userConfig and settings patterns
- [MARKETPLACES.md](MARKETPLACES.md) -- Publishing and marketplace registration
