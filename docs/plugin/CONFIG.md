# Plugin Settings -- claude-homelab

Plugin configuration, user-facing settings, and environment sync.

## Configuration layers

Settings flow through three layers with clear precedence:

| Priority | Source | Managed by |
| --- | --- | --- |
| 1 (highest) | `userConfig` in plugin.json | User at install time |
| 2 | `~/.claude-homelab/.env` file | User or hooks |
| 3 (lowest) | System environment variables | OS/container |

Higher-priority sources override lower ones for the same key.

## userConfig

User-facing configuration declared in `.claude-plugin/plugin.json`. Claude Code prompts the user for these values during plugin installation.

claude-homelab does not currently declare `userConfig` in its Claude/Codex manifests. Instead, credentials are managed via the `.env` file and the `/homelab-core:setup` skill.

### Field schema (for plugins that use userConfig)

| Property | Type | Description |
| --- | --- | --- |
| `type` | string | Value type: `string`, `number`, `boolean` |
| `title` | string | Human-readable label |
| `description` | string | Help text shown during configuration |
| `default` | any | Default value (omit for required fields) |
| `sensitive` | boolean | `true` masks the value in logs and UI |

### Sensitive fields

Fields with `"sensitive": true`:

- Masked in Claude Code UI (shown as `****`)
- Excluded from debug logs
- Never included in error messages
- Stored securely by Claude Code

Use `sensitive: true` for: API keys, tokens, passwords, secrets.

## Gemini settings

The `gemini-extension.json` manifest uses a flat `settings` array that maps directly to environment variables:

```json
{
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

claude-homelab declares 32 settings entries in its Gemini manifest covering all service credentials (URL + API key pairs for each service).

## .env conventions

All credentials are stored in `~/.claude-homelab/.env`:

```bash
# Service credentials
PLEX_URL="http://192.168.1.100:32400"
PLEX_TOKEN="your_plex_token"

# Multi-instance services use numbered variables
UNRAID_SERVER1_URL="http://server1.local:PORT"
UNRAID_SERVER1_API_KEY="key1"
```

Requirements:
- File permissions: `chmod 600`
- Group variables with comment headers
- No actual secrets in `.env.example` -- use descriptive placeholders
- Template file: `.env.example` (tracked in git)

## Environment sync

Hooks can sync `userConfig` values to `.env` at session start:

```
userConfig (plugin.json)
  --> sync-env.sh (SessionStart hook)
    --> .env file
      --> MCP server / scripts read environment variables
```

## Credential loading in scripts

All scripts use the shared `load-env.sh` library:

```bash
source ~/.claude-homelab/load-env.sh
load_env_file || exit 1
validate_env_vars "SERVICE_URL" "SERVICE_API_KEY"
```

Missing required variables produce a clear error with the variable name.

## settings.json

Plugin-level settings that control internal behavior (not user-facing):

```json
{
  "log_level": "INFO",
  "max_results": 50,
  "timeout_seconds": 30
}
```

These are read by the plugin at runtime and not prompted during installation.

## Cross-references

- [PLUGINS.md](PLUGINS.md) -- Plugin manifest where userConfig is declared
- [HOOKS.md](HOOKS.md) -- Hooks that perform environment sync
