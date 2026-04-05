# Documentation Index

Comprehensive documentation for the claude-homelab project, organized by domain.

## Root-Level Docs

| File | Purpose |
| --- | --- |
| [SETUP.md](SETUP.md) | Step-by-step setup guide (plugin marketplace + bash symlink paths) |
| [CONFIG.md](CONFIG.md) | Complete environment variable reference for all services |
| [GUARDRAILS.md](GUARDRAILS.md) | Security standards and credential management rules |
| [CHECKLIST.md](CHECKLIST.md) | Pre-release quality checklist |
| [INVENTORY.md](INVENTORY.md) | Component inventory (18 skills, 1 agent, 16 commands, 10 MCP repos) |

## Sections

| Directory | Purpose | Key Files |
| --- | --- | --- |
| [repo/](repo/CLAUDE.md) | Repository structure, conventions, scripts, Justfile recipes | REPO, MEMORY, RULES, SCRIPTS, RECIPES |
| [stack/](stack/CLAUDE.md) | Technology choices, architecture, prerequisites | TECH, ARCH, PRE-REQS |
| [plugin/](plugin/CLAUDE.md) | Plugin surfaces: manifests, skills, agents, commands, marketplace | PLUGINS, SKILLS, COMMANDS, MARKETPLACES + 7 more |
| [mcp/](mcp/CLAUDE.md) | MCP fleet: auth, tools, transport, connection, patterns | AUTH, TOOLS, TRANSPORT, CONNECT, PATTERNS |
| [upstream/](upstream/CLAUDE.md) | Upstream service integration reference (16 services) | Single CLAUDE.md with all services |
| [references/](references/CLAUDE.md) | Cross-cutting reference material | security-patterns.md |

## Reading Order

**New to the project:** SETUP → CONFIG → INVENTORY → repo/REPO → stack/ARCH

**Adding a skill:** plugin/SKILLS → upstream/CLAUDE → CONFIG → GUARDRAILS

**Working with MCP servers:** mcp/CONNECT → mcp/AUTH → mcp/TOOLS → mcp/PATTERNS

**Before a release:** CHECKLIST → GUARDRAILS → repo/RULES

## Existing Directories

| Directory | Purpose | Note |
| --- | --- | --- |
| `sessions/` | Ephemeral session notes | Not part of structured docs — working notes from dev sessions |
| `superpowers/` | Plan archives | Historical implementation plans |
| `readme-refresh/` | README drafts | Staging area for README updates |
