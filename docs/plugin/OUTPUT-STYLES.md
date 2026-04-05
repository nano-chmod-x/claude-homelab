# Output Style Definitions -- claude-homelab

Custom formatting for agent and tool responses.

## Overview

Output styles control how Claude Code formats responses from plugin tools and agents. They enable compact, consistent, and domain-appropriate output without requiring each tool to implement its own formatting.

claude-homelab does not heavily use output styles. The conventions below are documented for reference and future use.

## File location

Output styles are Markdown files in `output-styles/`:

```
output-styles/
  compact-table.md
  dashboard.md
  json-summary.md
```

Each file defines a formatting template with a name, description, and formatting rules.

## Defining an output style

```markdown
---
name: compact-status
description: Compact status table for health checks
---

Format health check responses as a table:

| Service | Status | Latency | Details |
| --- | --- | --- | --- |
| [service name] | OK/DEGRADED/DOWN | [ms] | [brief note] |
```

## Use cases

| Style | When to apply | Format |
| --- | --- | --- |
| Compact table | List/status responses | Aligned columns, minimal whitespace |
| JSON summary | API responses | Structure with key fields only |
| Dashboard | Multi-service health | Grouped sections with status indicators |
| Error report | Failure responses | Error, context, suggested fix |

## Cross-references

- [AGENTS.md](AGENTS.md) -- Agents that apply output styles
- [COMMANDS.md](COMMANDS.md) -- Commands that reference output styles
