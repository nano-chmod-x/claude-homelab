# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `overseerr-mcp` and `unifi-mcp` external MCP server plugins in marketplace
- `swag-mcp` external MCP server plugin for NGINX reverse proxy management
- `gotify-mcp` external MCP server plugin (replaces local gotify HTTP plugin)
- Detailed plugin setup guide for MCP-server-backed plugins

### Fixed
- Marketplace `source` field for external GitHub plugins now uses correct object format `{"source": "github", "repo": "owner/repo"}`

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
- Env loading standardized via `lib/load-env.sh`

### Removed
- Deprecated standalone skills
- `firecrawl` skill (replaced by agent)

## [1.0.0] - 2026-02-08

### Added
- Claude Code plugin marketplace structure (`.claude-plugin/marketplace.json`)
- 22-plugin catalog covering media, infrastructure, development, and utilities
- Agents: `agentic-orchestrator`, `exa-specialist`, `firecrawl-specialist`, `notebooklm-specialist`
- Commands: `/agentic-research`, `/homelab:*`, `/notebooklm:*`
- Shared credential library (`lib/load-env.sh`)
- Install scripts: `install.sh`, `setup-symlinks.sh`, `verify.sh`
- Security sanitization for public release
