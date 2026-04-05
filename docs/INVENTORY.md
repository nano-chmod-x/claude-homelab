# Component Inventory

Complete listing of all skills, agents, commands, plugins, and external repositories.

## Skills (18)

All skills live in `skills/` and are symlinked to `~/.claude/skills/` for bash-path discovery.

### Homelab core skills (2)

| Skill | Path | Description |
| --- | --- | --- |
| homelab-setup | `skills/homelab-setup/` | Interactive credential setup wizard |
| homelab-health | `skills/homelab-health/` | Unified service health dashboard |

### Media skills (6)

| Skill | Path | Credentials |
| --- | --- | --- |
| plex | `skills/plex/` | `PLEX_URL`, `PLEX_TOKEN` |
| radarr | `skills/radarr/` | `RADARR_URL`, `RADARR_API_KEY` |
| sonarr | `skills/sonarr/` | `SONARR_URL`, `SONARR_API_KEY` |
| prowlarr | `skills/prowlarr/` | `PROWLARR_URL`, `PROWLARR_API_KEY` |
| tautulli | `skills/tautulli/` | `TAUTULLI_URL`, `TAUTULLI_API_KEY` |
| notebooklm | `skills/notebooklm/` | `NOTEBOOKLM_COOKIE`, `NOTEBOOKLM_AUTH_JSON` |

### Download skills (2)

| Skill | Path | Credentials |
| --- | --- | --- |
| qbittorrent | `skills/qbittorrent/` | `QBITTORRENT_URL`, `QBITTORRENT_USERNAME`, `QBITTORRENT_PASSWORD` |
| sabnzbd | `skills/sabnzbd/` | `SABNZBD_URL`, `SABNZBD_API_KEY` |

### Utility skills (5)

| Skill | Path | Credentials |
| --- | --- | --- |
| bytestash | `skills/bytestash/` | `BYTESTASH_URL`, `BYTESTASH_API_KEY` |
| linkding | `skills/linkding/` | `LINKDING_URL`, `LINKDING_API_KEY` |
| memos | `skills/memos/` | `MEMOS_URL`, `MEMOS_API_TOKEN` |
| paperless-ngx | `skills/paperless-ngx/` | `PAPERLESS_URL`, `PAPERLESS_API_TOKEN` |
| radicale | `skills/radicale/` | `RADICALE_URL`, `RADICALE_USERNAME`, `RADICALE_PASSWORD` |

### Infrastructure skills (3)

| Skill | Path | Credentials |
| --- | --- | --- |
| tailscale | `skills/tailscale/` | `TAILSCALE_API_KEY`, `TAILSCALE_TAILNET` |
| zfs | `skills/zfs/` | `ZFS_HOST` |
| gh-address-comments | `skills/gh-address-comments/` | `GITHUB_TOKEN` |

## Agents (1)

| Agent | Path | Description |
| --- | --- | --- |
| notebooklm-specialist | `agents/notebooklm-specialist.md` | Specialized agent for NotebookLM research workflows |

## Commands (16)

Commands are `.md` files in `commands/` that become slash commands in Claude Code.

### Top-level commands (5)

| Command | File | Description |
| --- | --- | --- |
| `/check` | `commands/check.md` | View the latest screenshot |
| `/deploy` | `commands/deploy.md` | Deploy all MCP plugin servers |
| `/quick-push` | `commands/quick-push.md` | Git add, commit, and push |
| `/save-to-md` | `commands/save-to-md.md` | Save session documentation |
| `/validate-plan` | `commands/validate-plan.md` | Validate plan against homelab standards |

### Homelab namespace (4)

| Command | File | Description |
| --- | --- | --- |
| `/homelab:system-resources` | `commands/homelab/system-resources.md` | Check CPU, RAM, temps, and system load |
| `/homelab:docker-health` | `commands/homelab/docker-health.md` | Check health of all Docker containers |
| `/homelab:disk-space` | `commands/homelab/disk-space.md` | Analyze disk space usage |
| `/homelab:zfs-health` | `commands/homelab/zfs-health.md` | Check ZFS pool health and snapshots |

### NotebookLM namespace (7)

| Command | File | Description |
| --- | --- | --- |
| `/notebooklm:create` | `commands/notebooklm/create.md` | Create a new notebook |
| `/notebooklm:ask` | `commands/notebooklm/ask.md` | Chat with notebook content |
| `/notebooklm:source` | `commands/notebooklm/source.md` | Add or manage sources |
| `/notebooklm:generate` | `commands/notebooklm/generate.md` | Generate artifacts (podcast, video, etc.) |
| `/notebooklm:download` | `commands/notebooklm/download.md` | Download generated artifacts |
| `/notebooklm:list` | `commands/notebooklm/list.md` | List notebooks, sources, or artifacts |
| `/notebooklm:research` | `commands/notebooklm/research.md` | Run web research and import as sources |

## External MCP plugin repositories (10)

Each is an independent repository with its own MCP server, Docker deployment, and CI/CD.

| # | Plugin | Repository | Version | Category |
| --- | --- | --- | --- | --- |
| 1 | overseerr-mcp | [jmagar/overseerr-mcp](https://github.com/jmagar/overseerr-mcp) | 1.0.0 | media |
| 2 | unraid-mcp | [jmagar/unraid-mcp](https://github.com/jmagar/unraid-mcp) | 1.2.0 | infrastructure |
| 3 | unifi-mcp | [jmagar/unifi-mcp](https://github.com/jmagar/unifi-mcp) | 1.0.0 | infrastructure |
| 4 | gotify-mcp | [jmagar/gotify-mcp](https://github.com/jmagar/gotify-mcp) | 1.0.0 | utilities |
| 5 | swag-mcp | [jmagar/swag-mcp](https://github.com/jmagar/swag-mcp) | 1.0.0 | infrastructure |
| 6 | synapse-mcp | [jmagar/synapse-mcp](https://github.com/jmagar/synapse-mcp) | 2.2.1 | infrastructure |
| 7 | arcane-mcp | [jmagar/arcane-mcp](https://github.com/jmagar/arcane-mcp) | 1.1.3 | infrastructure |
| 8 | syslog-mcp | [jmagar/syslog-mcp](https://github.com/jmagar/syslog-mcp) | 1.0.0 | infrastructure |
| 9 | plugin-lab | [jmagar/plugin-lab](https://github.com/jmagar/plugin-lab) | 1.0.0 | dev-tools |

## Marketplace summary (26 entries)

The marketplace manifest at `.claude-plugin/marketplace.json` contains 26 plugin entries:

| Type | Count | Description |
| --- | --- | --- |
| Core | 1 | `homelab-core` -- the root plugin (this repo) |
| External MCP repos | 10 | Standalone plugin repositories listed above |
| Bundled skill plugins | 16 | Skills from `skills/` exposed as marketplace entries |

### Bundled skill plugins (16)

These are sourced from `skills/` within this repo and listed in the marketplace as individual entries. They graduate to their own external repo when they gain additional plugin surface area (agents, commands, MCP servers).

| Plugin | Source | Category |
| --- | --- | --- |
| bytestash | `./skills/bytestash` | utilities |
| gh-address-comments | `./skills/gh-address-comments` | dev-tools |
| linkding | `./skills/linkding` | utilities |
| memos | `./skills/memos` | utilities |
| notebooklm | `./skills/notebooklm` | research |
| paperless-ngx | `./skills/paperless-ngx` | utilities |
| plex | `./skills/plex` | media |
| prowlarr | `./skills/prowlarr` | media |
| qbittorrent | `./skills/qbittorrent` | downloads |
| radarr | `./skills/radarr` | media |
| radicale | `./skills/radicale` | utilities |
| sabnzbd | `./skills/sabnzbd` | downloads |
| sonarr | `./skills/sonarr` | media |
| tailscale | `./skills/tailscale` | infrastructure |
| tautulli | `./skills/tautulli` | media |
| zfs | `./skills/zfs` | infrastructure |

## Scripts

| Script | Path | Purpose |
| --- | --- | --- |
| install.sh | `scripts/install.sh` | One-liner bash installer |
| setup-creds.sh | `scripts/setup-creds.sh` | Create `~/.claude-homelab/.env` from template |
| setup-symlinks.sh | `scripts/setup-symlinks.sh` | Symlink skills/agents/commands into `~/.claude/` |
| verify.sh | `scripts/verify.sh` | Dual-path installation verification |
| load-env.sh | `scripts/load-env.sh` | Shared credential loading library |

## Plugin surfaces

| Surface | Present | Location |
| --- | --- | --- |
| Skills | yes | `skills/` (18 directories) |
| Agents | yes | `agents/` (1 file) |
| Commands | yes | `commands/` (5 top-level + 2 namespaces) |
| Prompts | yes | `prompts/` (TOML sidecars for commands) |
| Hooks | no | -- |
| Channels | no | -- |
| Output styles | no | -- |
| MCP servers | no | External repos only |
