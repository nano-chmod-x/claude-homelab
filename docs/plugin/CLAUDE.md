# Plugin Surface Documentation -- claude-homelab

Index for the `docs/plugin/` documentation subdirectory. These docs cover every Claude Code plugin surface area available to claude-homelab.

## File index

| File | Surface | Description |
| --- | --- | --- |
| [PLUGINS.md](PLUGINS.md) | Manifests | `plugin.json` structure, required/optional fields, version sync |
| [AGENTS.md](AGENTS.md) | Agents | Agent definitions, frontmatter schema, delegation patterns |
| [SKILLS.md](SKILLS.md) | Skills | Skill definitions, progressive disclosure, reference docs |
| [COMMANDS.md](COMMANDS.md) | Commands | Slash commands, namespacing, dynamic context injection |
| [HOOKS.md](HOOKS.md) | Hooks | Session/tool hooks, scripts, matcher syntax |
| [CHANNELS.md](CHANNELS.md) | Channels | Bidirectional messaging with external services |
| [OUTPUT-STYLES.md](OUTPUT-STYLES.md) | Output Styles | Custom formatting for agent/tool responses |
| [SCHEDULES.md](SCHEDULES.md) | Schedules | Cron-based recurring agent execution |
| [CONFIG.md](CONFIG.md) | Settings | Plugin configuration, userConfig, env sync |
| [MARKETPLACES.md](MARKETPLACES.md) | Marketplaces | Publishing to Claude/Codex marketplaces |

## How plugin surfaces compose

A Claude Code plugin is a bundle of one or more surfaces. Not every plugin needs every surface -- pick what fits:

```
plugin.json (required)        Declares the plugin to Claude Code
  |-- mcpServers               MCP tools and resources
  |-- skills/                  Domain knowledge and workflows
  |-- agents/                  Specialized autonomous behaviors
  |-- commands/                User-invocable slash commands
  |-- hooks/                   Lifecycle event handlers
  |-- channels/                External messaging integration
  |-- output-styles/           Custom response formatting
  |-- schedules                Recurring automated tasks
  |-- settings.json            Plugin-level config
```

The minimum viable plugin is `plugin.json` alone. Each additional surface adds capability without requiring the others.

## claude-homelab surface composition

This repo uses the following surfaces:

| Surface | Status | Count | Notes |
| --- | --- | --- | --- |
| Manifests | Active | 3 files | `.claude-plugin/`, `.codex-plugin/`, `gemini-extension.json` |
| Skills | Active | 18 | 2 core + 16 service integrations |
| Commands | Active | 16 | 5 top-level + 4 homelab + 7 notebooklm |
| Agents | Active | 1 | notebooklm-specialist |
| Marketplace | Active | 27 entries | 1 core + 10 external + 16 bundled |
| Channels | Active | 1 | Discord integration |
| Hooks | Minimal | -- | Used by external MCP repos, not core |
| Output Styles | Not used | -- | Documented for future use |
| Schedules | Not used | -- | Documented for future use |

## Cross-references

- `CLAUDE.md` (repo root) -- Development guidelines and repository structure
- `skills/CLAUDE.md` -- Skill development guidelines
- `.claude-plugin/marketplace.json` -- Full marketplace catalog
