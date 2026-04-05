# Skill Definitions -- claude-homelab

Patterns for defining skills (domain knowledge modules) within the plugin.

## Directory structure

```
skills/
  <service>/
    SKILL.md                      # Skill definition (required)
    README.md                     # User-facing documentation (required)
    scripts/                      # Executable scripts
    references/                   # Detailed reference documentation
      api-endpoints.md            # REST API reference
      quick-reference.md          # Common operations cheat sheet
      troubleshooting.md          # Known issues and fixes
    examples/                     # Example usage scripts (optional)
```

## All 18 skills

### Homelab core skills (2)

| Skill | Directory | Purpose |
| --- | --- | --- |
| homelab-setup | `skills/homelab-setup/` | Interactive credential setup wizard |
| homelab-health | `skills/homelab-health/` | Unified service health dashboard |

### Service skills (16)

| Skill | Directory | Category | Description |
| --- | --- | --- | --- |
| bytestash | `skills/bytestash/` | utilities | Code snippet storage and management |
| gh-address-comments | `skills/gh-address-comments/` | dev-tools | Address GitHub PR review comments |
| linkding | `skills/linkding/` | utilities | Bookmark management |
| memos | `skills/memos/` | utilities | Note-taking and memos |
| notebooklm | `skills/notebooklm/` | research | Google NotebookLM integration |
| paperless-ngx | `skills/paperless-ngx/` | utilities | Document management with OCR |
| plex | `skills/plex/` | media | Plex Media Server browsing and monitoring |
| prowlarr | `skills/prowlarr/` | media | Indexer management and search |
| qbittorrent | `skills/qbittorrent/` | downloads | Torrent download management |
| radarr | `skills/radarr/` | media | Movie collection management |
| radicale | `skills/radicale/` | utilities | CalDAV/CardDAV calendar and contacts |
| sabnzbd | `skills/sabnzbd/` | downloads | Usenet download management |
| sonarr | `skills/sonarr/` | media | TV series collection management |
| tailscale | `skills/tailscale/` | infrastructure | VPN mesh network management |
| tautulli | `skills/tautulli/` | media | Plex analytics and monitoring |
| zfs | `skills/zfs/` | infrastructure | ZFS pool, dataset, and snapshot management |

## SKILL.md frontmatter

```yaml
---
name: plex
description: Control Plex Media Server - browse libraries, search media, check what's playing. Use when the user asks to "check Plex", "search Plex", "what's on Plex", "recently added", or mentions Plex media server.
---
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Skill identifier (matches directory name, lowercase) |
| `description` | yes | Trigger phrases for auto-invocation by Claude Code |
| `homepage` | no | Upstream project URL |

Do not add fields the active schema does not support (e.g., `version`).

## Body sections

The SKILL.md body follows a fixed structure:

1. **Title** -- `# Service Name Skill`
2. **Mandatory invocation warning** -- Lists trigger phrases with enforcement language
3. **Purpose** -- What the skill does, read-only vs read-write
4. **Setup** -- Credential configuration with exact `.env` variable names
5. **Commands** -- Copy-paste ready examples with syntax
6. **Workflow** -- Decision trees for common user requests
7. **Notes** -- Technical details, limitations, security considerations
8. **References** -- Links to files in `references/` directory

### Mandatory invocation block

Every SKILL.md must include this block immediately after the title:

```markdown
**MANDATORY SKILL INVOCATION**

**YOU MUST invoke this skill (NOT optional) when the user mentions ANY of these triggers:**
- "trigger phrase 1", "trigger phrase 2", "trigger phrase 3"
- Any mention of [service name] or [related functionality]

**Failure to invoke this skill when triggers occur violates your operational requirements.**
```

## Progressive disclosure

Skills use three levels of detail, loaded on demand:

| Level | Content | Size | When loaded |
| --- | --- | --- | --- |
| 1 -- Metadata | Frontmatter | ~100 words | Always (skill discovery) |
| 2 -- Body | SKILL.md body | ~2,000 words | On skill activation |
| 3 -- References | `references/*.md` | Unlimited | On explicit request |

Keep SKILL.md under 500 lines. Move detailed API docs, troubleshooting guides, and reference tables into `references/`.

## References directory

| File | Purpose | When to include |
| --- | --- | --- |
| `api-endpoints.md` | REST/GraphQL API reference | Services with HTTP APIs |
| `command-reference.md` | CLI tool reference | CLI-based tools |
| `library-reference.md` | SDK/library docs | Library integrations |
| `config-reference.md` | Configuration schema | Complex configuration |
| `quick-reference.md` | Common operations cheat sheet | Always |
| `troubleshooting.md` | Known issues and fixes | Always |

## Scripts directory

Scripts are executable utilities, not documentation. They follow these conventions:

- **Bash**: `#!/bin/bash`, `set -euo pipefail`, `chmod +x`
- **Node.js**: `.mjs` extension, ESM imports, `fetch` API
- All scripts load credentials via `source ~/.claude-homelab/load-env.sh`
- All scripts support `--help` flag
- All scripts return JSON output where appropriate

## Skill types

| Type | Operations | Confirmation needed | Examples |
| --- | --- | --- | --- |
| Read-only | GET requests only | No | plex, tautulli, tailscale |
| Read-write (safe) | POST/PUT (additive) | For significant actions | radarr, sonarr, linkding |
| Read-write (destructive) | DELETE, file removal | Always required | qbittorrent (delete torrents) |

## Discovery

Skills are discovered through two paths:

| Path | Mechanism |
| --- | --- |
| Plugin install | Claude Code reads `skills/` from the plugin directory |
| Bash install | Symlinks: `~/.claude/skills/<name>/` -> `~/claude-homelab/skills/<name>/` |

## Cross-references

- [AGENTS.md](AGENTS.md) -- Agents that delegate to skills
- [COMMANDS.md](COMMANDS.md) -- Slash commands that may reference skills
- Development guidelines: `skills/CLAUDE.md`
