# Memory Files -- claude-homelab

Claude Code memory system for persistent knowledge across sessions.

## What is memory

Memory files are persistent, file-based knowledge that Claude Code retains across conversation sessions. They store project decisions, user preferences, external system pointers, and learned corrections.

## Location

Memory files live in the Claude Code project-scoped memory directory:

```
~/.claude/projects/-home-jmagar-claude-homelab/memory/
├── MEMORY.md                          # Index file (pointer list)
├── feedback_marketplace.md            # Marketplace schema and version gotchas
├── feedback_no_macos_compat.md        # Linux-only, no macOS shims
├── project_justfile.md                # Justfile recipe reference
├── project_mcp_alignment_status.md    # Per-repo MCP alignment audit
├── project_mcp_ci_composite_action.md # CI composite action pattern
├── project_mcp_registry_publishing.md # DNS auth, registry identifiers
├── project_mcp_server_conventions.md  # Required files, Docker patterns
├── project_oauth_gateway.md           # OAuth 2.1, RFC 8707, Redis cache
├── project_p0_bugs_history.md         # Historical P0 bugs fixed
├── project_plugin_architecture.md     # 27 plugins, flat layout, version sync
├── project_plugin_bin_executables.md  # Plugin bin/ executable patterns
├── project_scripts_pattern.md         # Scripts location and load-env
└── project_swag_mcp_proxy.md          # SWAG nginx MCP proxy patterns
```

The path `-home-jmagar-claude-homelab` is derived from the absolute path to the repo root. Claude Code auto-resolves this.

## Index file

`MEMORY.md` is the index -- a pointer list linking to individual memory files with short descriptions. Keep it under 200 lines.

```markdown
# Memory Index

- [Plugin Architecture Overview](project_plugin_architecture.md) -- 27 plugins; flat skills/ layout
- [Justfile Recipes](project_justfile.md) -- 30 recipes for dev/ops
- [MCP Server Conventions](project_mcp_server_conventions.md) -- Required files, Docker patterns
```

## Memory types

| Type | Prefix | Purpose | Example |
| --- | --- | --- | --- |
| `user` | `user_` | User-specific info | Role, preferences, team context |
| `feedback` | `feedback_` | Corrections and learned behaviors | "Always use uv, not pip" |
| `project` | `project_` | Project decisions and architecture | Tech stack choices, patterns |
| `reference` | `reference_` | External system pointers | API quirks, service endpoints |

## Frontmatter format

Every memory file starts with YAML frontmatter:

```yaml
---
name: architecture-decisions
description: MCP server architecture and tool organization patterns
type: project
---
```

## When to save

Save memory when encountering:

- User role or team context ("I'm the infra lead")
- Corrections to previous behavior ("Use ruff, not flake8")
- Project architecture decisions ("We chose FastMCP over raw SDK")
- External system pointers ("The upstream API has a 100 req/min limit")
- Non-obvious conventions ("All tool names use kebab-case")
- Marketplace schema gotchas (object source format, version sync)

## When NOT to save

Do not save:

- Code patterns visible in the codebase (read the code instead)
- Git history facts (use `git log`)
- Debugging sessions and their solutions (ephemeral)
- Temporary state ("Currently working on feature X")
- Information already in `CLAUDE.md` or documentation files

## Memory vs other persistence

| Mechanism | Scope | Lifetime | Use for |
| --- | --- | --- | --- |
| Memory files | Project-wide | Permanent | Decisions, preferences, pointers |
| `CLAUDE.md` | Project-wide | Permanent | Instructions, conventions, rules |
| Git commits | Project-wide | Permanent | Code history |
| Session context | Single session | Ephemeral | Current task state |

## Managing memory

- Review memory files periodically -- remove stale entries
- Keep individual files focused on one topic
- Update the index when adding or removing files
- Memory files are committed to git (no credentials in memory files)
- Use `bd comments add` for knowledge capture during bead work
