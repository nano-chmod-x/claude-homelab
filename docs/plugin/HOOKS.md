# Hook Configuration -- claude-homelab

Lifecycle hooks that run automatically during Claude Code sessions.

## Overview

claude-homelab uses hooks minimally. The primary hook infrastructure lives in external MCP plugin repos (e.g., gotify-mcp, overseerr-mcp) rather than in the core repo.

## Hook events

| Event | When it fires | Typical use |
| --- | --- | --- |
| `SessionStart` | Claude Code session begins | Sync credentials, validate environment |
| `PreToolUse` | Before a tool executes | Block dangerous operations, inject context |
| `PostToolUse` | After a tool executes | Fix permissions, enforce invariants |

## hooks.json structure

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/sync-env.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fix-env-perms.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Matcher syntax

The `matcher` field on `PreToolUse` and `PostToolUse` groups filters which tool invocations trigger the hooks. Use pipe-separated tool names:

| Matcher | Triggers on |
| --- | --- |
| `Write\|Edit\|Bash` | File writes or shell commands |
| `Bash` | Shell commands only |
| `mcp__plugin__tool` | Specific MCP tool call |

## Path variables

| Variable | Expands to |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to the plugin root directory |

## Further reading

For detailed hook development patterns (custom scripts, timeout handling, matcher design), see the `plugin-dev:hook-development` skill.

## Cross-references

- [CONFIG.md](CONFIG.md) -- Settings that hooks sync
- [PLUGINS.md](PLUGINS.md) -- Plugin manifest where hooks are registered
