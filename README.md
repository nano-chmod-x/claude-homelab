# Claude Homelab

Claude Code plugins, skills, agents, and commands for self-hosted homelab service management.

This repository currently serves three roles:

1. It is a Claude Code plugin marketplace via [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).
2. It is the source for the `homelab-core` plugin at the repo root.
3. It contains installable local skill plugins under [`skills/`](skills/) plus references to external MCP plugin repos.

## Table of Contents

- [What You Get](#what-you-get)
- [Install](#install)
- [Credentials](#credentials)
- [Plugin Catalog](#plugin-catalog)
- [Homelab-Core](#homelab-core)
- [Repository Layout](#repository-layout)
- [Marketplace Layout](#marketplace-layout)
- [Bash Path](#bash-path)
- [Verification](#verification)
- [Adding or Updating Plugins](#adding-or-updating-plugins)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## What You Get

This repo gives you a mix of local Claude plugins and external MCP-backed plugins for common homelab tasks:

- Media management: Plex, Radarr, Sonarr, Prowlarr, Tautulli
- Downloads: qBittorrent, SABnzbd
- Infrastructure: Tailscale, ZFS, plus external Unraid and UniFi MCP plugins
- Utilities: Linkding, Memos, ByteStash, Paperless-ngx, Radicale, plus external Gotify MCP plugin
- Research and workflow tools: NotebookLM, PR comment handling, Axon, plugin deployment helpers

The repo also ships:

- `homelab-core` agents in [`agents/`](agents/)
- slash commands in [`commands/`](commands/)
- shared credential bootstrap scripts in [`scripts/`](scripts/)
- a shared env template in [`.env.example`](.env.example)

## Install

Two install paths are supported.

### Plugin Path

This is the Claude Code native path. Claude installs plugins from the marketplace into its plugin cache.

```text
/plugin marketplace add jmagar/claude-homelab
```

Install the core plugin first:

```text
/plugin install homelab-core@jmagar-claude-homelab
```

Install any local skill plugins you actually use:

```text
/plugin install plex@jmagar-claude-homelab
/plugin install radarr@jmagar-claude-homelab
/plugin install sonarr@jmagar-claude-homelab
/plugin install prowlarr@jmagar-claude-homelab
/plugin install tautulli@jmagar-claude-homelab
/plugin install qbittorrent@jmagar-claude-homelab
/plugin install sabnzbd@jmagar-claude-homelab
/plugin install tailscale@jmagar-claude-homelab
/plugin install zfs@jmagar-claude-homelab
/plugin install linkding@jmagar-claude-homelab
/plugin install memos@jmagar-claude-homelab
/plugin install bytestash@jmagar-claude-homelab
/plugin install paperless-ngx@jmagar-claude-homelab
/plugin install radicale@jmagar-claude-homelab
/plugin install notebooklm@jmagar-claude-homelab
/plugin install gh-address-comments@jmagar-claude-homelab
```

Optional external MCP plugins exposed by this marketplace:

```text
/plugin install overseerr-mcp@jmagar-claude-homelab
/plugin install unraid-mcp@jmagar-claude-homelab
/plugin install unifi-mcp@jmagar-claude-homelab
/plugin install gotify-mcp@jmagar-claude-homelab
/plugin install swag-mcp@jmagar-claude-homelab
/plugin install synapse-mcp@jmagar-claude-homelab
/plugin install arcane-mcp@jmagar-claude-homelab
/plugin install syslog-mcp@jmagar-claude-homelab
/plugin install plugin-lab@jmagar-claude-homelab
/plugin install axon@jmagar-claude-homelab
```

Bootstrap credentials locally:

```bash
curl -sSL https://raw.githubusercontent.com/jmagar/claude-homelab/main/scripts/setup-creds.sh | bash
```

Then edit:

```bash
$EDITOR ~/.claude-homelab/.env
```

You can also use the restored setup skill flow from Claude Code:

```text
/homelab-core:setup
```

That skill uses `setup-creds.sh` when needed and then walks the user through filling or updating `~/.claude-homelab/.env`.

### Bash Path

This path clones the repo and symlinks the current checkout into `~/.claude/`.

```bash
curl -sSL https://raw.githubusercontent.com/jmagar/claude-homelab/main/scripts/install.sh | bash
```

The installer:

1. checks `git`, `jq`, and `curl`
2. clones or updates `~/claude-homelab`
3. runs [`setup-creds.sh`](scripts/setup-creds.sh)
4. runs [`setup-symlinks.sh`](scripts/setup-symlinks.sh)
5. runs [`verify.sh`](scripts/verify.sh)

After install:

```bash
$EDITOR ~/.claude-homelab/.env
```

Restart Claude Code after either install path so it reloads plugin and skill metadata.

## Credentials

Runtime credentials live in:

```text
~/.claude-homelab/.env
```

The bootstrap template is [`.env.example`](.env.example).

Shared helper:

- [`scripts/load-env.sh`](scripts/load-env.sh) is copied to `~/.claude-homelab/load-env.sh`

Common variables include:

```bash
PLEX_URL=https://your-plex-url:32400
PLEX_TOKEN=your_x_plex_token

RADARR_URL=https://your-radarr-url
RADARR_API_KEY=your_api_key

SONARR_URL=https://your-sonarr-url
SONARR_API_KEY=your_api_key

TAILSCALE_API_KEY=your_api_key
TAILSCALE_TAILNET=your_tailnet_or_dash
```

Special cases:

- `zfs` uses local CLI access and does not require API credentials
- external MCP plugins may have their own runtime requirements depending on their repo

## Plugin Catalog

The marketplace currently exposes 27 plugins in three groups.

### Core Plugin

- `homelab-core`

### Local Skill Plugins From This Repo

These point at local directories under [`skills/`](skills/):

- `bytestash`
- `gh-address-comments`
- `linkding`
- `memos`
- `notebooklm`
- `paperless-ngx`
- `plex`
- `prowlarr`
- `qbittorrent`
- `radarr`
- `radicale`
- `sabnzbd`
- `sonarr`
- `tailscale`
- `tautulli`
- `zfs`

### External GitHub-Backed Plugins

These are marketplace entries whose `source` is a GitHub repo object rather than a local path:

- `overseerr-mcp`
- `unraid-mcp`
- `unifi-mcp`
- `gotify-mcp`
- `swag-mcp`
- `synapse-mcp`
- `arcane-mcp`
- `syslog-mcp`
- `plugin-lab`
- `axon`

### Service Notes

Local skill plugins generally wrap scripts and references shipped in this repo.

Examples:

- `plex`: browse libraries, search media, inspect sessions
- `radarr`: search and add movies, inspect config, remove entries with confirmation-sensitive flows
- `sonarr`: search and add shows, inspect library state
- `linkding`: manage bookmarks
- `memos`: create and search notes
- `paperless-ngx`: upload and manage OCR-backed documents
- `radicale`: manage CalDAV and CardDAV data
- `notebooklm`: drive the NotebookLM CLI workflows

The marketplace prefers the external MCP version for integrations like Overseerr, Unraid, UniFi, and Gotify. Those services do not have local skill directories in this repo.

## Homelab-Core

The root plugin manifest is [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json).

`homelab-core` currently provides:

- agents from [`agents/`](agents/)
- slash commands from [`commands/`](commands/)
- the setup skill at [`skills/homelab-setup/SKILL.md`](skills/homelab-setup/SKILL.md)
- the health skill at [`skills/homelab-health/SKILL.md`](skills/homelab-health/SKILL.md)

### Agents

- `notebooklm-specialist`

### Commands

Top-level commands currently present:

- `/check`
- `/deploy`
- `/quick-push`
- `/save-to-md`

Namespaced commands currently present:

- `/homelab:system-resources`
- `/homelab:docker-health`
- `/homelab:disk-space`
- `/homelab:zfs-health`
- `/notebooklm:create`
- `/notebooklm:ask`
- `/notebooklm:source`
- `/notebooklm:generate`
- `/notebooklm:download`
- `/notebooklm:list`
- `/notebooklm:research`

### Setup Skill

The restored core setup skill is:

- [`skills/homelab-setup/SKILL.md`](skills/homelab-setup/SKILL.md)

It guides the user through:

- checking whether `~/.claude-homelab/.env` exists
- bootstrapping it with `scripts/setup-creds.sh` when needed
- collecting credentials one service at a time
- writing updates back into `~/.claude-homelab/.env`

### Health Skill

The shipped core skill is:

- [`skills/homelab-health/SKILL.md`](skills/homelab-health/SKILL.md)

Its backing script is:

- [`skills/homelab-health/scripts/check-health.sh`](skills/homelab-health/scripts/check-health.sh)

The health checker:

- reads `~/.claude-homelab/.env`
- uses a 5 second timeout
- treats any HTTP response code other than curl failure as reachable
- checks media, downloads, infrastructure, and utility services defined in the script

## Repository Layout

Current structure:

```text
claude-homelab/
├── .claude-plugin/
│   ├── marketplace.json
│   ├── plugin.json
│   └── README.md
├── agents/
├── bin/
├── commands/
│   ├── homelab/
│   └── notebooklm/
├── hooks/
├── output-styles/
├── prompts/
│   └── homelab/
├── references/
├── scripts/
│   ├── install.sh
│   ├── load-env.sh
│   ├── setup-creds.sh
│   ├── setup-symlinks.sh
│   └── verify.sh
├── skills/
│   ├── homelab-health/
│   ├── homelab-setup/
│   └── <service>/
│       ├── SKILL.md
│       ├── README.md
│       ├── load-env.sh
│       ├── references/
│       └── scripts/
└── .env.example
```

Important current facts:

- `scripts/load-env.sh` is the shared env helper, not `lib/load-env.sh`
- service plugin roots now live directly under `skills/<name>/`
- SKILL.md is at the root of each skill directory, not nested

## Marketplace Layout

The marketplace file is [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

It currently mixes three source shapes:

1. Root plugin source:
   - `homelab-core` uses `"source": "./"`

2. Local skill plugin sources:
   - examples: `"source": "./skills/plex"`, `"source": "./skills/radarr"`
   - these entries currently use `strict: false` and `skills: "./skills/"`

3. External GitHub sources:
   - example:
   ```json
   {
     "source": {
       "source": "github",
       "repo": "jmagar/axon"
     }
   }
   ```

That means this marketplace is not limited to one packaging convention.

## Bash Path

[`scripts/setup-symlinks.sh`](scripts/setup-symlinks.sh) currently symlinks:

- each first-level directory under [`skills/`](skills/) into `~/.claude/skills/`
- each Markdown file under [`agents/`](agents/) into `~/.claude/agents/`
- top-level command files and command namespaces under [`commands/`](commands/) into `~/.claude/commands/`

It also:

- copies [`scripts/load-env.sh`](scripts/load-env.sh) to `~/.claude-homelab/load-env.sh`
- creates `~/.claude-homelab/.env` from [`.env.example`](.env.example) if missing

Because the symlink script operates on the current top-level `skills/` tree, its behavior follows the repo as it exists now.

## Verification

Run:

```bash
~/claude-homelab/scripts/verify.sh
```

The verifier currently checks:

- `~/.claude-homelab/.env` existence and permissions
- `~/.claude-homelab/load-env.sh`
- bash-path symlink counts
- marketplace JSON validity
- whether local marketplace source paths exist
- whether root `.claude-plugin/plugin.json` exists
- whether `skills/homelab-setup/SKILL.md` exists
- whether `skills/homelab-health/SKILL.md` exists
- whether `skills/homelab-health/scripts/check-health.sh` is executable

With the setup skill restored, that core-skill check should now pass in a normal repo checkout.

## Adding or Updating Plugins

The current repo supports two plugin patterns.

### Local Skill Plugin Pattern

A local plugin root currently looks like:

```text
skills/myservice/
├── SKILL.md
├── README.md
├── load-env.sh
├── references/
└── scripts/
```

To expose it in the marketplace, add an entry to [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) similar to:

```json
{
  "name": "myservice",
  "source": "./skills/myservice",
  "description": "My service description",
  "version": "1.0.0",
  "skills": "./skills/",
  "strict": false,
  "homepage": "https://github.com/jmagar/claude-homelab"
}
```

This is the pattern used by current local plugin entries like `plex`, `radarr`, and `paperless-ngx`.

### External MCP Plugin Pattern

For a standalone plugin in another repo, the marketplace entry uses a GitHub source object:

```json
{
  "name": "myservice-mcp",
  "source": {
    "source": "github",
    "repo": "jmagar/myservice-mcp"
  },
  "description": "External MCP plugin",
  "version": "1.0.0",
  "homepage": "https://github.com/jmagar/myservice-mcp"
}
```

This is the pattern used by `axon`, `unraid-mcp`, `unifi-mcp`, and the other external marketplace entries.

## Security

Credentials:

- keep `~/.claude-homelab/.env` at `chmod 600`
- never commit `.env`
- use [`.env.example`](.env.example) as the template only
- scripts should load credentials via [`scripts/load-env.sh`](scripts/load-env.sh) or the copied file in `~/.claude-homelab/`

Transport:

- prefer HTTPS service URLs where possible
- remember that health checks only prove reachability, not correct credentials

Local state:

- `.beads/` is now gitignored and intended to remain local-only

## Troubleshooting

### Plugin install fails with "plugin not found"

Re-add the marketplace:

```text
/plugin marketplace add jmagar/claude-homelab
```

Then retry the exact plugin name from the current marketplace.

### Health checks say a service is reachable but calls still fail

That usually means the service answered HTTP but the credentials are wrong. Update `~/.claude-homelab/.env` and retry.

### Bash path skills or commands are missing

Re-run:

```bash
~/claude-homelab/scripts/setup-symlinks.sh
```

Then restart Claude Code.

### `verify.sh` reports a core setup skill error

If that happens again, check that [`skills/homelab-setup/SKILL.md`](skills/homelab-setup/SKILL.md) exists in your checkout and that you are on the expected branch.

## References

- Repository: https://github.com/jmagar/claude-homelab
- Marketplace manifest: [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)
- Core plugin manifest: [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)

## External Plugin Repositories

- [jmagar/axon](https://github.com/jmagar/axon)
- [jmagar/gotify-mcp](https://github.com/jmagar/gotify-mcp)
- [jmagar/unraid-mcp](https://github.com/jmagar/unraid-mcp)
- [jmagar/overseerr-mcp](https://github.com/jmagar/overseerr-mcp)
- [jmagar/unifi-mcp](https://github.com/jmagar/unifi-mcp)
- [jmagar/syslog-mcp](https://github.com/jmagar/syslog-mcp)
- [jmagar/arcane-mcp](https://github.com/jmagar/arcane-mcp)
- [jmagar/synapse-mcp](https://github.com/jmagar/synapse-mcp)
- [jmagar/swag-mcp](https://github.com/jmagar/swag-mcp)
- [jmagar/plugin-lab](https://github.com/jmagar/plugin-lab)

Version: 1.3.0
Last Updated: 2026-04-03
