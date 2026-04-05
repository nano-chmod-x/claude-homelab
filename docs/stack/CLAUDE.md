# Technology Stack Documentation — claude-homelab

Reference documentation for the technology choices, architecture, and prerequisites of the claude-homelab skill collection.

## File index

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | This file — index for the stack/ documentation subdirectory |
| `TECH.md` | Technology choices — Bash, curl, jq, optional Python/Node.js |
| `ARCH.md` | Architecture — dual-install, symlinks, credential flow, marketplace, mermaid diagram |
| `PRE-REQS.md` | Prerequisites — required tools, versions, verification commands |

## Key distinction

claude-homelab is a **Bash skill collection**, not an MCP server. The technology stack is deliberately simple: Bash scripts that call upstream APIs with `curl` and parse responses with `jq`. The external MCP server repos (overseerr-mcp, synapse-mcp, syslog-mcp, etc.) have their own tech stacks documented in their respective repositories.

## Cross-references

- [SETUP](../SETUP.md) — step-by-step setup guide
- [Root CLAUDE.md](../../CLAUDE.md) — repository development guidelines
- [skills/CLAUDE.md](../../skills/CLAUDE.md) — skill development guidelines
