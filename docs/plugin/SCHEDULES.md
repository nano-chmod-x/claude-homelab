# Scheduled Tasks -- claude-homelab

Automated recurring agent execution on a cron schedule.

## Overview

Schedules allow plugins to run agents on a recurring basis without manual invocation. Common use cases include health checks, log monitoring, backup verification, and periodic data syncing.

claude-homelab does not heavily use schedules. The conventions below are documented for reference and future use.

## Configuration

Schedules are configured as remote triggers that execute Claude Code agents:

```json
{
  "name": "homelab-health-check",
  "schedule": "*/5 * * * *",
  "agent": "notebooklm-specialist",
  "prompt": "Run a health check on configured services and report issues",
  "enabled": true
}
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Unique schedule identifier |
| `schedule` | yes | Cron expression (minute hour day month weekday) |
| `agent` | no | Agent to invoke (omit for default) |
| `prompt` | yes | Instruction passed to the agent |
| `enabled` | no | Toggle without deleting (default: `true`) |

## Common cron patterns

| Pattern | Frequency |
| --- | --- |
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * *` | Daily at midnight |
| `0 0 * * 1` | Weekly on Monday |

## Management

Create and manage schedules via the `/schedule` skill:

```
/schedule create "health-check" --cron "*/5 * * * *" --prompt "Check service health"
/schedule list
/schedule enable health-check
/schedule disable health-check
```

## Cross-references

- [AGENTS.md](AGENTS.md) -- Agents invoked by schedules
- [CHANNELS.md](CHANNELS.md) -- Channels used for schedule alerts
