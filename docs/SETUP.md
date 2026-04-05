# Setup Guide

Step-by-step instructions to get claude-homelab running via either the plugin path or the bash path.

## Prerequisites

| Dependency | Version | Purpose |
| --- | --- | --- |
| git | any | Clone and update the repository |
| jq | any | JSON parsing in scripts |
| curl | any | HTTP calls to service APIs |
| Claude Code | latest | Runtime for skills, agents, and commands |

Optional but recommended:

| Dependency | Version | Purpose |
| --- | --- | --- |
| just | latest | Task runner for Justfile recipes |
| Docker | 24+ | Container deployment for MCP servers |
| Docker Compose | v2+ | Orchestrate multi-container stacks |

## Install Path A: Plugin Marketplace (recommended)

The plugin path uses Claude Code's native plugin system. No symlinks required.

### 1. Add the marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
```

### 2. Install the core plugin

```bash
/plugin install homelab-core @jmagar-claude-homelab
```

This installs the core plugin into `~/.claude/plugins/cache/` with all bundled skills, agents, and commands.

### 3. Install external MCP plugins

Each external MCP server plugin is installed separately:

```bash
/plugin install overseerr-mcp @jmagar-claude-homelab
/plugin install unraid-mcp @jmagar-claude-homelab
/plugin install unifi-mcp @jmagar-claude-homelab
/plugin install gotify-mcp @jmagar-claude-homelab
/plugin install swag-mcp @jmagar-claude-homelab
/plugin install synapse-mcp @jmagar-claude-homelab
/plugin install arcane-mcp @jmagar-claude-homelab
/plugin install syslog-mcp @jmagar-claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab
```

Only install the plugins for services you actually run.

### 4. Configure credentials

```bash
/homelab-core:setup
```

The interactive wizard prompts for each service you use and writes credentials to `~/.claude-homelab/.env`.

Or edit manually:

```bash
$EDITOR ~/.claude-homelab/.env
```

### 5. Verify

```bash
/homelab-core:health
```

## Install Path B: Bash (curl | bash)

The bash path clones the repository and symlinks skills, agents, and commands into `~/.claude/`.

### 1. Run the installer

```bash
curl -sSL https://raw.githubusercontent.com/jmagar/claude-homelab/main/scripts/install.sh | bash
```

This performs the following steps automatically:

1. Checks prerequisites (git, jq, curl)
2. Clones the repo to `~/claude-homelab` (or `git pull` if it already exists)
3. Runs `setup-creds.sh` -- creates `~/.claude-homelab/.env` from `.env.example` with `chmod 600`
4. Runs `setup-symlinks.sh` -- symlinks all skills, agents, and commands into `~/.claude/`
5. Runs `verify.sh` -- confirms everything is in place
6. Prints next steps

### 2. Configure credentials

Open the interactive wizard in Claude Code:

```bash
/homelab-core:setup
```

Or edit manually:

```bash
$EDITOR ~/.claude-homelab/.env
```

See [CONFIG.md](CONFIG.md) for all environment variables grouped by service.

### 3. Restart Claude Code

Claude Code discovers skills and commands at startup. Restart to pick up the new symlinks.

### 4. Verify

```bash
/homelab-core:health
```

Or run the verification script directly:

```bash
~/claude-homelab/scripts/verify.sh
```

Expected output shows green checkmarks for credentials, symlinks, and plugin manifests.

## Manual Setup (advanced)

If you prefer step-by-step control:

```bash
# Clone
git clone https://github.com/jmagar/claude-homelab.git ~/claude-homelab
cd ~/claude-homelab

# Create credential file
cp .env.example ~/.claude-homelab/.env
chmod 600 ~/.claude-homelab/.env

# Edit credentials
$EDITOR ~/.claude-homelab/.env

# Create symlinks
./scripts/setup-symlinks.sh

# Verify
./scripts/verify.sh
```

## Updating

### Plugin path

```bash
/plugin marketplace add jmagar/claude-homelab   # refreshes catalog
/plugin update homelab-core                      # updates core
```

### Bash path

```bash
cd ~/claude-homelab
git pull
./scripts/setup-symlinks.sh   # picks up new skills/commands
```

## Troubleshooting

### ".env file not found"

- Run `~/claude-homelab/scripts/setup-creds.sh` to create `~/.claude-homelab/.env`
- Or manually: `cp ~/claude-homelab/.env.example ~/.claude-homelab/.env && chmod 600 ~/.claude-homelab/.env`

### "Permission denied" on scripts

```bash
chmod +x ~/claude-homelab/scripts/*.sh
chmod +x ~/claude-homelab/skills/*/scripts/*.sh
```

### Skills not appearing in Claude Code

- Bash path: confirm symlinks exist in `~/.claude/skills/`
- Plugin path: run `/plugin list` and check for `homelab-core`
- Restart Claude Code after installation

### "401 Unauthorized" from a service

- Verify the correct API key/token is set in `~/.claude-homelab/.env`
- Check the service URL is reachable: `curl -s <SERVICE_URL>/api/v1/system/status`
- Some services need HTTPS; update the URL accordingly

### Broken symlinks after git pull

Re-run symlink setup to fix stale links:

```bash
~/claude-homelab/scripts/setup-symlinks.sh
~/claude-homelab/scripts/verify.sh
```

### Docker containers cannot reach localhost services

Inside a Docker container, `localhost` refers to the container itself. Use `host.docker.internal` or the LAN IP of your host machine instead.
