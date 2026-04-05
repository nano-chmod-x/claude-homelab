# Slash Commands -- claude-homelab

User-invocable slash commands defined as Markdown files.

## File location

Commands are Markdown files discovered by Claude Code from `commands/`:

```
commands/
  check.md                         # /check
  deploy.md                        # /deploy
  quick-push.md                    # /quick-push
  save-to-md.md                    # /save-to-md
  validate-plan.md                 # /validate-plan
  homelab/                         # /homelab:* namespace
    disk-space.md                  # /homelab:disk-space
    docker-health.md               # /homelab:docker-health
    system-resources.md            # /homelab:system-resources
    zfs-health.md                  # /homelab:zfs-health
  notebooklm/                      # /notebooklm:* namespace
    ask.md                         # /notebooklm:ask
    create.md                      # /notebooklm:create
    download.md                    # /notebooklm:download
    generate.md                    # /notebooklm:generate
    list.md                        # /notebooklm:list
    research.md                    # /notebooklm:research
    source.md                      # /notebooklm:source
```

## All 16 commands

### Top-level commands (5)

| Command | File | Description |
| --- | --- | --- |
| `/check` | `commands/check.md` | View the latest screenshot from ~/Pictures/Screenshots |
| `/deploy` | `commands/deploy.md` | Deploy all MCP plugin servers from marketplace.json |
| `/quick-push` | `commands/quick-push.md` | Git add all, commit with Claude, and push |
| `/save-to-md` | `commands/save-to-md.md` | Save session documentation with memory integration |
| `/validate-plan` | `commands/validate-plan.md` | Validate implementation plan against homelab standards |

### Homelab namespace (4)

| Command | File | Description |
| --- | --- | --- |
| `/homelab:disk-space` | `commands/homelab/disk-space.md` | Analyze disk space usage across all mounts |
| `/homelab:docker-health` | `commands/homelab/docker-health.md` | Check health of all Docker containers and services |
| `/homelab:system-resources` | `commands/homelab/system-resources.md` | Check CPU, RAM, temps, and system load |
| `/homelab:zfs-health` | `commands/homelab/zfs-health.md` | Check ZFS pool health, scrubs, and snapshots |

### NotebookLM namespace (7)

| Command | File | Description |
| --- | --- | --- |
| `/notebooklm:ask` | `commands/notebooklm/ask.md` | Chat with NotebookLM about notebook content |
| `/notebooklm:create` | `commands/notebooklm/create.md` | Create a new NotebookLM notebook |
| `/notebooklm:download` | `commands/notebooklm/download.md` | Download generated artifacts |
| `/notebooklm:generate` | `commands/notebooklm/generate.md` | Generate artifacts (podcast, video, quiz, report) |
| `/notebooklm:list` | `commands/notebooklm/list.md` | List notebooks, sources, or artifacts |
| `/notebooklm:research` | `commands/notebooklm/research.md` | Run web research and import results |
| `/notebooklm:source` | `commands/notebooklm/source.md` | Add, list, or manage notebook sources |

## Naming

| Layout | File | Resulting command |
| --- | --- | --- |
| Single | `commands/check.md` | `/check` |
| Namespaced | `commands/homelab/docker-health.md` | `/homelab:docker-health` |
| Namespaced | `commands/notebooklm/ask.md` | `/notebooklm:ask` |

The directory name becomes the namespace prefix. The filename (minus `.md`) becomes the command after the colon.

## Frontmatter

```yaml
---
description: Short description shown in autocomplete
argument-hint: <required> [optional]
allowed-tools: Bash(tool:*), mcp__plugin__tool
---
```

| Field | Required | Description |
| --- | --- | --- |
| `description` | yes | One-line description for autocomplete menu |
| `argument-hint` | no | Hint for expected arguments |
| `allowed-tools` | no | Pre-approved tools (no permission prompts at runtime) |

### allowed-tools syntax

| Pattern | Matches |
| --- | --- |
| `Bash(tool:*)` | All Bash commands |
| `Bash(rtk git status)` | Specific Bash command |
| `mcp__plugin__tool` | Specific MCP tool |
| `Read` | File read tool |
| `Write` | File write tool |

## Body

The command body contains instructions for Claude to follow when the command is invoked.

### Variables

| Variable | Description |
| --- | --- |
| `$ARGUMENTS` | Replaced with everything the user types after the command |

### Dynamic context injection

Use `` !`command` `` to inject shell output into the prompt at invocation time:

```markdown
---
description: Deploy MCP plugin servers
allowed-tools: Bash
---

Marketplace: !`cat ~/claude-homelab/.claude-plugin/marketplace.json`

## Instructions
Parse the marketplace and deploy the specified plugins.
```

The shell command runs before Claude sees the prompt. Output is injected inline. This is used by `/check` (to find the latest screenshot) and `/deploy` (to read marketplace.json).

## Discovery

Commands are discovered through two paths:

| Path | Mechanism |
| --- | --- |
| Plugin install | Claude Code reads `commands/` from the plugin directory |
| Bash install | Symlinks to `~/.claude/commands/` (file or directory) |

### Symlink setup

```bash
# Single command
ln -sf ~/claude-homelab/commands/check.md ~/.claude/commands/check.md

# Namespaced commands (symlink the directory)
ln -sf ~/claude-homelab/commands/homelab ~/.claude/commands/homelab
```

## Prompt definitions

Command prompt bodies also exist as `.toml` files in `prompts/`, separate from the `.md` command definitions. This keeps command metadata (frontmatter) distinct from prompt content.

```
prompts/
  check.toml
  deploy.toml
  homelab/
    docker-health.toml
    disk-space.toml
    system-resources.toml
    zfs-health.toml
```

## Cross-references

- [AGENTS.md](AGENTS.md) -- Agents that commands may delegate to
- [SKILLS.md](SKILLS.md) -- Skills that provide domain knowledge for commands
- [HOOKS.md](HOOKS.md) -- Hooks triggered by tool use within commands
