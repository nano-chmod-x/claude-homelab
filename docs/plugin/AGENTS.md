# Agent Definitions -- claude-homelab

Patterns for defining autonomous agents within a Claude Code plugin.

## File location

```
agents/
  notebooklm-specialist.md       # The sole agent in this repo
```

Agents are Markdown files in the `agents/` directory. Claude Code discovers them automatically when the plugin is installed, or via symlinks to `~/.claude/agents/`.

## Current agents

claude-homelab has **1 agent**:

| Agent | File | Purpose |
| --- | --- | --- |
| notebooklm-specialist | `agents/notebooklm-specialist.md` | AI-powered deep research via Google NotebookLM |

## Naming conventions

| Pattern | Use case | Example |
| --- | --- | --- |
| `*-specialist.md` | Domain expert for a specific service | `notebooklm-specialist.md` |
| `*-orchestrator.md` | Coordinates multiple agents/tools | (none currently) |

The filename (minus `.md`) becomes the agent identifier.

## YAML frontmatter

```yaml
---
name: notebooklm-specialist
description: |
  Use this agent when you need AI-powered deep research and analysis
  via Google NotebookLM.
  <example>
  Context: Orchestrator has spawned this agent for NotebookLM analysis phase
  user: "You are the NotebookLM specialist. Research brief: [topic]."
  assistant: "Reading my skills and starting NotebookLM deep research."
  </example>
tools: Bash, Read, Write, SendMessage
memory: user
color: magenta
---
```

### Frontmatter fields

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Agent identifier (matches filename) |
| `description` | yes | Trigger conditions with `<example>` blocks |
| `tools` | yes | Comma-separated list of tools the agent may use |
| `memory` | no | `user` (persists across sessions) or `session` (current only) |
| `color` | no | Terminal color: `blue`, `red`, `green`, `yellow`, `cyan`, `magenta` |

### Tool restrictions

List only the tools the agent actually needs. Fewer tools = safer execution.

| Tool | When to include |
| --- | --- |
| `Bash` | Agent runs shell commands |
| `Read` | Agent reads files |
| `Write` | Agent creates new files |
| `Edit` | Agent modifies existing files |
| `Glob` | Agent searches for files by pattern |
| `Grep` | Agent searches file contents |
| `SendMessage` | Agent communicates with other agents |
| `mcp__plugin__tool` | Agent uses a specific MCP tool |

## Body structure

After the frontmatter, the agent body follows this structure:

```markdown
# Agent Title

## Initialization
Read the relevant SKILL.md before taking any action.

## Your Mission
What the agent is responsible for.

## Methodology
Step-by-step instructions for completing the mission.

## Key Behaviors
Prioritized list of operational rules.

## Error Handling
How to handle common failure modes.

## Communication Protocol
How to report progress and signal completion.
```

The notebooklm-specialist follows this structure with sections for Initialization (reads shared playbook and NotebookLM skill), Mission (deep research, Q&A, artifact generation), and a detailed Methodology with six numbered steps.

## Discovery

Agents are discovered through two paths:

| Path | Mechanism |
| --- | --- |
| Plugin install | Claude Code reads `agents/` from the plugin directory |
| Bash install | Symlinks: `~/.claude/agents/notebooklm-specialist.md` -> `~/claude-homelab/agents/notebooklm-specialist.md` |

## Cross-references

- [SKILLS.md](SKILLS.md) -- Skills that agents delegate to
- [COMMANDS.md](COMMANDS.md) -- Commands that may invoke agents
