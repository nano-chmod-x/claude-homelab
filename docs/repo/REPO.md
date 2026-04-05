# Repository Structure -- claude-homelab

Directory layout for the claude-homelab mono-repo. This repo provides agents, commands, skills, and scripts for self-hosted homelab service management via Claude Code.

## Directory tree

```
claude-homelab/
├── .claude-plugin/
│   ├── marketplace.json             # Plugin catalog (27 plugins)
│   ├── plugin.json                  # homelab-core manifest (v1.4.0)
│   └── README.md                    # Marketplace documentation
├── .codex-plugin/
│   └── plugin.json                  # Codex plugin manifest
├── .github/
│   └── workflows/
│       └── update-doc-mirrors.yaml  # CI for doc mirror sync
├── agents/
│   └── notebooklm-specialist.md     # NotebookLM research agent
├── bin/
│   └── .gitkeep                     # Reserved for future executables
├── commands/
│   ├── check.md                     # /check — latest screenshot
│   ├── deploy.md                    # /deploy — deploy MCP servers
│   ├── quick-push.md                # /quick-push — git add/commit/push
│   ├── save-to-md.md                # /save-to-md — session docs
│   ├── validate-plan.md             # /validate-plan — plan validation
│   ├── homelab/                     # /homelab:* namespace
│   │   ├── disk-space.md
│   │   ├── docker-health.md
│   │   ├── system-resources.md
│   │   └── zfs-health.md
│   └── notebooklm/                  # /notebooklm:* namespace
│       ├── ask.md
│       ├── create.md
│       ├── download.md
│       ├── generate.md
│       ├── list.md
│       ├── research.md
│       └── source.md
├── docs/
│   ├── mcp/                         # MCP server documentation
│   ├── plugin/                      # Plugin development docs
│   ├── readme-refresh/              # README refresh materials
│   ├── references/
│   │   ├── AGENTS.md                # Agent reference (symlink)
│   │   ├── CLAUDE.md                # Claude reference (symlink)
│   │   ├── GEMINI.md                # Gemini reference (symlink)
│   │   └── security-patterns.md     # Shared security patterns
│   ├── repo/                        # This directory
│   │   ├── CLAUDE.md                # Index (this set of docs)
│   │   ├── MEMORY.md                # Memory file system docs
│   │   ├── RECIPES.md               # Justfile recipe reference
│   │   ├── REPO.md                  # This file
│   │   ├── RULES.md                 # Coding rules and conventions
│   │   └── SCRIPTS.md               # Scripts reference
│   ├── sessions/                    # Session logs (dated .md files)
│   ├── stack/                       # Tech stack docs
│   ├── superpowers/                 # Superpowers plans
│   └── upstream/                    # Upstream service docs
├── hooks/
│   └── .gitkeep                     # Reserved for lifecycle hooks
├── output-styles/
│   └── .gitkeep                     # Reserved for output styles
├── scripts/
│   ├── install.sh                   # Bash-path entry point (curl | bash)
│   ├── load-env.sh                  # Credential loading library
│   ├── push-github-secrets.sh       # Push .env secrets to GitHub Actions
│   ├── setup-creds.sh               # Create ~/.claude-homelab/.env
│   ├── setup-symlinks.sh            # Symlink skills/agents/commands to ~/.claude/
│   ├── standardize-changelog.sh     # CHANGELOG format standardizer
│   └── verify.sh                    # Dual-path installation verifier
├── skills/
│   ├── CLAUDE.md                    # Skill development guidelines
│   ├── AGENTS.md                    # Symlink to CLAUDE.md
│   ├── GEMINI.md                    # Symlink to CLAUDE.md
│   ├── bytestash/                   # ByteStash snippet storage
│   ├── gh-address-comments/         # GitHub PR comment resolution
│   ├── homelab-health/              # Service health dashboard
│   ├── homelab-setup/               # Interactive credential wizard
│   ├── linkding/                    # Linkding bookmarks
│   ├── memos/                       # Memos note-taking
│   ├── notebooklm/                  # Google NotebookLM
│   ├── paperless-ngx/               # Paperless-ngx documents
│   ├── plex/                        # Plex Media Server
│   ├── prowlarr/                    # Prowlarr indexer manager
│   ├── qbittorrent/                 # qBittorrent downloads
│   ├── radarr/                      # Radarr movie manager
│   ├── radicale/                    # Radicale CalDAV/CardDAV
│   ├── sabnzbd/                     # SABnzbd Usenet downloads
│   ├── sonarr/                      # Sonarr TV show manager
│   ├── tailscale/                   # Tailscale mesh VPN
│   ├── tautulli/                    # Tautulli Plex analytics
│   └── zfs/                         # ZFS pool management
│
├── .app.json                        # App metadata
├── .codex                           # Codex config
├── .codexignore                     # Codex ignore rules
├── .env                             # Local credentials (gitignored)
├── .env.example                     # Credential template (tracked)
├── .gitignore                       # Git ignore rules
├── AGENTS.md                        # Symlink to CLAUDE.md
├── CHANGELOG.md                     # Version history
├── CLAUDE.md                        # Project instructions (24 KB)
├── GEMINI.md                        # Symlink to CLAUDE.md
├── gemini-extension.json            # Gemini extension manifest
├── Justfile                         # Task runner (74 KB, ~1880 lines)
├── LICENSE                          # MIT license
├── README.md                        # User-facing documentation (27 KB)
└── SECURITY.md                      # Security policy
```

## Root files

| File | Required | Purpose |
| --- | --- | --- |
| `CLAUDE.md` | Yes | Project instructions for Claude Code sessions |
| `README.md` | Yes | User-facing overview, install, configuration |
| `CHANGELOG.md` | Yes | Version history with entries for every bump |
| `.env.example` | Yes | Template for credentials -- placeholder values only |
| `Justfile` | Yes | Task runner -- validation, docker, health, publishing |
| `gemini-extension.json` | Yes | Gemini extension manifest |
| `SECURITY.md` | Yes | Security policy |
| `LICENSE` | Yes | MIT license |

## Plugin manifests

| File | Platform | Key fields |
| --- | --- | --- |
| `.claude-plugin/plugin.json` | Claude Code | name, version, description |
| `.claude-plugin/marketplace.json` | Claude Code | 27 plugins (1 core, 16 local, 10 external) |
| `.codex-plugin/plugin.json` | Codex | name, version, description |
| `gemini-extension.json` | Gemini | name, version, description |

All manifests must have the same `version` value (currently 1.4.0).

## Skill directory structure

Each skill under `skills/<name>/` follows this pattern:

```
skills/<name>/
├── SKILL.md             # Skill definition (Claude-facing)
├── README.md            # User-facing documentation
├── load-env.sh          # Per-skill env loader (sources scripts/load-env.sh)
├── scripts/             # Executable API scripts (.sh)
└── references/          # API docs, quick-reference, troubleshooting
```

## External plugin repos

10 external plugins live in separate repositories under `~/workspace/`:

| Plugin | Local path |
| --- | --- |
| overseerr-mcp | ~/workspace/overseerr-mcp |
| unraid-mcp | ~/workspace/unraid-mcp |
| unifi-mcp | ~/workspace/unifi-mcp |
| gotify-mcp | ~/workspace/gotify-mcp |
| swag-mcp | ~/workspace/swag-mcp |
| synapse-mcp | ~/workspace/synapse-mcp |
| arcane-mcp | ~/workspace/arcane-mcp |
| syslog-mcp | ~/workspace/syslog-mcp |
| plugin-lab | ~/workspace/plugin-lab |
| axon | ~/workspace/axon_rust |
