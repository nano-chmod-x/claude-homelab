---
description: Deploy all MCP plugin servers from .claude-plugin/marketplace.json
argument-hint: [plugin-name]
allowed-tools: Bash
---

Deploy MCP plugin servers defined in the homelab marketplace. Arguments (if provided): $ARGUMENTS

The marketplace lives at: `!cat ~/.claude/plugins/marketplaces/claude-homelab/.claude-plugin/marketplace.json 2>/dev/null || cat ~/claude-homelab/.claude-plugin/marketplace.json`

## Instructions

1. **Parse the marketplace** to get the list of external plugins (those with `source.source == "github"`). Extract `name` and `version` for each.

2. **Detect docker compose variant**:
   - `docker compose version` → use `docker compose`
   - `docker-compose version` → use `docker-compose`
   - If neither found, report error and stop

3. **Determine which plugins to deploy**:
   - If `$ARGUMENTS` is a plugin name (e.g. `synapse-mcp`, `axon`), deploy only that one
   - If no arguments, deploy **all** external plugins from the marketplace

4. **For each plugin to deploy**:
   - Find its compose file at: `~/.claude/plugins/cache/claude-homelab/<name>/<version>/docker-compose.yaml` (also check `.yml` variants)
   - Skip `tests/` subdirectory compose files
   - If compose file not found, warn and skip that plugin — do not stop

5. **Run the deploy** from each compose file's parent directory:
   ```bash
   cd ~/.claude/plugins/cache/claude-homelab/<name>/<version>
   docker compose up --build -d
   ```

6. **Report results** as a table:
   - Plugin name | Status (✓ up / ✗ failed / ⚠ skipped) | Notes
   - On any failure: show last 20 lines of that plugin's output
   - At the end: run `docker compose ps` in each successfully deployed directory to show running containers
