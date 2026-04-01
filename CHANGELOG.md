# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `overseerr-mcp` and `unifi-mcp` external MCP server plugins in marketplace
- `swag-mcp` external MCP server plugin for NGINX reverse proxy management
- `gotify-mcp` external MCP server plugin (replaces local gotify HTTP plugin)
- Detailed plugin setup guide for MCP-server-backed plugins
- Engineering principles section: Research → Plan → Validate → Implement loop
- Context and token efficiency section: tool count, pagination, schema surface area guidance
- `.codex/` and `.github/` top-level directories
- `scripts/update-doc-mirrors.sh` utility

### Fixed
- Marketplace `source` field for external GitHub plugins now uses correct object format `{"source": "github", "repo": "owner/repo"}`
- Plugin setup guide: fix token var name (`MCP_BEARER_TOKEN` → `MY_SERVICE_MCP_TOKEN`)
- Plugin setup guide: clarify stdio transport has no bearer auth (HTTP-only)
- Plugin setup guide: fix directory name placeholder (`repo-root/` → `my-service-mcp/`)

### Changed
- `skills/CLAUDE.md`: extract skill catalog and migration checklist to `skills/references/`, remove duplicate mandatory-invocation block, fix `load-env.sh` credential pattern, add `bd create` step to new-skill workflow (1124→915 lines)
- `CLAUDE.md`: compress auto-injected Beads/Session sections to 2 lines (hooks already inject this context)
- `~/.claude/CLAUDE.md`: clarify "Refer to CLAUDE.md" → explicit `~/CLAUDE.md` path
- `~/CLAUDE.md` (RTK): add Installation section with binary path and PATH fallback note
- Plugin setup guide: destructive tool actions now require `confirm=true` parameter
- Migrate all service skills from `service-plugins/` to `skills/` (flat structure)
- Remove `templates/my-plugin/` — template content moved to standalone `plugin-templates` repo
- Remove `scripts/homelab/` legacy orchestration scripts (superseded by skills)
- Remove `prompts/` directory (commands moved to `commands/`)
- Remove `skills/setup/` (merged into homelab-core plugin)
- Update `CLAUDE.md` with current architecture and beads workflow
- Update `README.md` to reflect restructured layout

## [1.1.2] - 2026-03-29

### Fixed
- Bundle `load-env.sh` in each plugin with fallback sourcing for plugin-path installs
- Add `setup-creds.sh` to `skills/setup/scripts/` for plugin-path users
- Move scripts into `skills/<name>/scripts/` so plugin installer includes them
- Source `load-env.sh` from installed path in all service plugin scripts

### Changed
- Bump patch versions across all plugins for scripts location fix

## [1.1.1] - 2026-03-20

### Changed
- Plugin validation cleanup and structural fixes
- Remove remaining internal server name references from health skill and README
- Remove `fail2ban-swag` plugin
- Standardize Unraid environment variable naming

### Fixed
- Cleanup stale references and hardcoded server names

## [1.1.0] - 2026-03-15

### Added
- `homelab-core` plugin at repo root (dual-path: marketplace + bash install)
- 21 service plugins under `service-plugins/`
- `skills/setup/` — interactive credential wizard
- `skills/health/` — service health dashboard with curl checks
- Complete README rewrite with architecture documentation
- `.env` distribution via homelab-core plugin setup command

### Changed
- Migrate all skills to `service-plugins/` structure
- Standardize all skill scripts and SKILL.md files
- Move `.env` location to `~/.claude-homelab/`
- Env loading standardized via `scripts/load-env.sh`

### Removed
- Deprecated standalone skills
- `firecrawl` skill (replaced by agent)

## [1.0.0] - 2026-02-08

### Added
- Claude Code plugin marketplace structure (`.claude-plugin/marketplace.json`)
- 22-plugin catalog covering media, infrastructure, development, and utilities
- Agents: `agentic-orchestrator`, `exa-specialist`, `firecrawl-specialist`, `notebooklm-specialist`
- Commands: `/agentic-research`, `/homelab:*`, `/notebooklm:*`
- Shared credential library (`scripts/load-env.sh`)
- Install scripts: `install.sh`, `setup-symlinks.sh`, `verify.sh`
- Security sanitization for public release
