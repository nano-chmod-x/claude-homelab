# Marketplace Publishing -- claude-homelab

Registration and publishing patterns for the Claude and Codex marketplaces.

## Marketplace location

The marketplace manifest lives at `.claude-plugin/marketplace.json` in the homelab-core repo. This single file catalogs all 27 plugins in the ecosystem.

## Marketplace metadata

```json
{
  "name": "claude-homelab",
  "owner": {
    "name": "jmagar",
    "email": "jmagar@users.noreply.github.com"
  },
  "metadata": {
    "description": "Comprehensive Claude Code skills and agents for homelab service management",
    "version": "1.1.0"
  },
  "plugins": [ ... ]
}
```

## All 27 plugins

### Core plugin (1)

| Name | Source | Category | Version |
| --- | --- | --- | --- |
| homelab-core | `"./"` (this repo) | core | 1.1.2 |

### External repo plugins (10)

These plugins live in their own GitHub repositories:

| Name | Repo | Category | Version |
| --- | --- | --- | --- |
| overseerr-mcp | `jmagar/overseerr-mcp` | media | 1.0.0 |
| unraid-mcp | `jmagar/unraid-mcp` | infrastructure | 1.2.0 |
| unifi-mcp | `jmagar/unifi-mcp` | infrastructure | 1.0.0 |
| gotify-mcp | `jmagar/gotify-mcp` | utilities | 1.0.0 |
| swag-mcp | `jmagar/swag-mcp` | infrastructure | 1.0.0 |
| synapse-mcp | `jmagar/synapse-mcp` | infrastructure | 2.2.1 |
| arcane-mcp | `jmagar/arcane-mcp` | infrastructure | 1.1.3 |
| syslog-mcp | `jmagar/syslog-mcp` | infrastructure | 1.0.0 |
| plugin-lab | `jmagar/plugin-lab` | dev-tools | 1.0.0 |
| axon | `jmagar/axon` | research | 0.34.1 |

### Bundled skill plugins (16)

These are skill-only integrations sourced from `./skills/<name>` within this repo:

| Name | Source | Category | Version |
| --- | --- | --- | --- |
| bytestash | `./skills/bytestash` | utilities | 1.0.0 |
| gh-address-comments | `./skills/gh-address-comments` | dev-tools | 1.0.0 |
| linkding | `./skills/linkding` | utilities | 1.0.0 |
| memos | `./skills/memos` | utilities | 1.0.0 |
| notebooklm | `./skills/notebooklm` | research | 1.0.0 |
| paperless-ngx | `./skills/paperless-ngx` | utilities | 1.0.0 |
| plex | `./skills/plex` | media | 1.0.0 |
| prowlarr | `./skills/prowlarr` | media | 1.0.0 |
| qbittorrent | `./skills/qbittorrent` | downloads | 1.0.0 |
| radarr | `./skills/radarr` | media | 1.0.0 |
| radicale | `./skills/radicale` | utilities | 1.0.0 |
| sabnzbd | `./skills/sabnzbd` | downloads | 1.0.0 |
| sonarr | `./skills/sonarr` | media | 1.0.0 |
| tailscale | `./skills/tailscale` | infrastructure | 1.0.0 |
| tautulli | `./skills/tautulli` | media | 1.0.0 |
| zfs | `./skills/zfs` | infrastructure | 1.0.0 |

## Entry format

### External repo plugin

```json
{
  "name": "overseerr-mcp",
  "source": {
    "source": "github",
    "repo": "jmagar/overseerr-mcp"
  },
  "description": "Overseerr media requests via MCP tools with HTTP fallback.",
  "version": "1.0.0",
  "category": "media",
  "tags": ["overseerr", "media", "mcp"],
  "homepage": "https://github.com/jmagar/overseerr-mcp"
}
```

### Bundled skill plugin

```json
{
  "name": "plex",
  "source": "./skills/plex",
  "description": "Plex Media Server management.",
  "version": "1.0.0",
  "category": "media",
  "tags": ["plex", "media", "streaming", "homelab"],
  "homepage": "https://github.com/jmagar/claude-homelab"
}
```

Key difference: external plugins use the object format `{"source": "github", "repo": "owner/repo"}`, while bundled skills use a string path `"./skills/<name>"`.

## Categories

| Category | Description | Count |
| --- | --- | --- |
| core | Core orchestration and setup | 1 |
| infrastructure | Server, network, storage management | 8 |
| media | Media management and requests | 6 |
| utilities | Notifications, bookmarks, notes, docs | 5 |
| downloads | Torrent and Usenet management | 2 |
| dev-tools | Development and scaffolding | 2 |
| research | Experimental, AI, and crawling | 2 |

## Graduation criteria

A bundled skill graduates to its own external repo when it gains plugin surface area beyond a SKILL.md directory:

| Surface added | Requires own repo? |
| --- | --- |
| SKILL.md + references only | No -- stays bundled |
| + MCP server | Yes |
| + Agents | Yes |
| + Commands | Yes |
| + Hooks | Yes |

When graduating:
1. Create new repo: `jmagar/<name>`
2. Move skill content and add new surfaces
3. Update marketplace entry to use `source.repo` format
4. Remove or thin the bundled skill in homelab-core

## Version sync

The marketplace entry `version` field should match the plugin's `plugin.json` version. For external repos, version updates happen independently.

For the core plugin, all version-bearing files must stay in sync. Verify with `just check-contract`.

## Installation

Users install plugins via:

```
/plugin marketplace add jmagar/claude-homelab
```

This reads the marketplace manifest, discovers all plugins, and enables them.

## Cross-references

- [PLUGINS.md](PLUGINS.md) -- Plugin manifest structure
- [CONFIG.md](CONFIG.md) -- userConfig prompted at install time
