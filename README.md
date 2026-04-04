# Claude Homelab

Current release: 1.4.0.

Homelab plugin hub for Claude Code, Codex, and Gemini. This repository is the source of truth for the `homelab-core` plugin, bundled skill-only integrations, agents, commands, prompts, and shared credential bootstrapping.

## What this repository is

`claude-homelab` is both:

- the `homelab-core` plugin published through the Claude marketplace
- the canonical mono-repo for bundled skill-only integrations such as bytestash, gh-address-comments, linkding, memos, notebooklm, paperless-ngx, plex, prowlarr, qbittorrent, radarr, radicale, sabnzbd, sonarr, tailscale, tautulli, and zfs
- the source for the Codex plugin manifest and Gemini extension manifest that mirror the same core homelab workflow surface

The repo root is the source of truth. Do not edit generated copies in `~/.claude/` or other client-specific caches directly.

## What ships in this repo

- `agents/`: top-level agents; currently `notebooklm-specialist`
- `commands/`: slash command definitions such as `/check`, `/deploy`, `/quick-push`, `/save-to-md`, and `/validate-plan`
- `prompts/`: prompt sidecars for commands
- `skills/`: 18 tracked skill directories plus `skills/.cache/` for generated cache data
- `references/`: shared reference docs such as security patterns
- `scripts/`: install, bootstrap, setup, and verification helpers
- `.claude-plugin/`: Claude marketplace manifest and plugin catalog
- `.codex-plugin/`: Codex plugin manifest
- `gemini-extension.json`: Gemini extension manifest
- `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, and `.env.example`: repo guidance, release history, and credential template

## Installation

### Claude marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install homelab-core @jmagar-claude-homelab
```

### Bash / symlink install

```bash
./scripts/install.sh
./scripts/setup-symlinks.sh
./scripts/verify.sh
```

The bash path creates symlinks into `~/.claude/` and installs shared runtime files into `~/.claude-homelab/`.

## Credential model

Shared credentials live in:

```bash
~/.claude-homelab/.env
```

Bootstrapping options:

```bash
/homelab-core:setup
./scripts/setup-creds.sh
```

Security rules:

- `.env` must never be committed
- permissions should be `chmod 600 ~/.claude-homelab/.env`
- service scripts load credentials via `scripts/load-env.sh`

## Top-level command surface

### Root commands

| Command | Purpose |
| --- | --- |
| `/check` | Inspect the most recent screenshot and describe it |
| `/deploy` | Build and deploy MCP/plugin repos from the marketplace |
| `/quick-push` | Standardized commit-and-push workflow |
| `/save-to-md` | Save current session context to Markdown |
| `/validate-plan` | Audit technical plans against repo standards |

### Namespaced commands

| Namespace | Commands |
| --- | --- |
| `/homelab` | `system-resources`, `docker-health`, `disk-space`, `zfs-health` |
| `/notebooklm` | `create`, `ask`, `source`, `generate`, `download`, `list`, `research` |

## Marketplace scope

The marketplace catalog in this repo spans 27 entries total:

- 1 core plugin: `homelab-core`
- 10 external MCP repos: `overseerr-mcp`, `unraid-mcp`, `unifi-mcp`, `gotify-mcp`, `swag-mcp`, `synapse-mcp`, `arcane-mcp`, `syslog-mcp`, `plugin-lab`, and `axon`
- 16 bundled skill-only plugins: `bytestash`, `gh-address-comments`, `linkding`, `memos`, `notebooklm`, `paperless-ngx`, `plex`, `prowlarr`, `qbittorrent`, `radarr`, `radicale`, `sabnzbd`, `sonarr`, `tailscale`, `tautulli`, and `zfs`

## Repository layout

```text
agents/                 Top-level specialist agents
commands/               Slash command definitions
prompts/                Prompt sidecars for commands
skills/                 Bundled service skills and generated cache data
references/             Shared reference docs
scripts/                Install/setup/verification helpers
.claude-plugin/         Claude marketplace/plugin manifests
.codex-plugin/          Codex plugin manifest
gemini-extension.json   Gemini extension manifest
AGENTS.md               Repo-wide development instructions
CLAUDE.md               Claude-facing project instructions
CHANGELOG.md            Release history
.env.example            Shared credential template
```

## Development workflow

```bash
./scripts/setup-symlinks.sh
./scripts/verify.sh
```

Project rules that matter when editing:

- use `bd` for task tracking, not markdown TODOs
- keep bundled skill docs, command definitions, and prompt sidecars in sync
- if a change bumps a version, update every version-bearing manifest plus `CHANGELOG.md`
- the repo is the source of truth; never patch files directly in `~/.claude/`

## Verification

Recommended checks after doc or command changes:

```bash
./scripts/verify.sh
rtk rg -n "^## " README.md AGENTS.md CLAUDE.md
```

For command changes, confirm the command definition under `commands/` and the matching prompt under `prompts/` still agree.

## Related files

- `AGENTS.md`: canonical development and repo-structure guidance
- `CLAUDE.md`: Claude-facing project instructions
- `.env.example`: shared credential template
- `.claude-plugin/marketplace.json`: marketplace source of truth
- `CHANGELOG.md`: release history

## License

MIT
