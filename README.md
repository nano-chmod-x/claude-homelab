# Claude Homelab: Core Plugin Hub

> **The central management hub for self-hosted homelab services, providing specialized agents, slash commands, and unified credential orchestration.**

[![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)
[![Marketplace](https://img.shields.io/badge/marketplace-27_plugins-orange.svg)]( .claude-plugin/marketplace.json)
[![FastMCP](https://img.shields.io/badge/FastMCP-Enabled-brightgreen.svg)](https://github.com/jlowin/fastmcp)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

---

## ✨ Overview
`homelab-core` is the foundation of the Claude Homelab ecosystem. It manages the marketplace manifest, provides shared credential bootstrapping, and exposes a powerful suite of agents and slash commands designed to turn Claude into a senior homelab administrator.

### 🎯 Key Features
| Feature | Description |
|---------|-------------|
| **Core Skills** | Integrated `setup` (credential wizard) and `health` (dashboard) skills |
| **Command Suite** | 15+ specialized slash commands for Docker, ZFS, and system health |
| **Marketplace** | Single source of truth for 27 local and external MCP plugins |
| **Agents** | Specialized specialists (e.g., `notebooklm-specialist`) for complex workflows |

---

## 🎯 Claude Code Integration
Install the core plugin hub directly from the marketplace:

```bash
# Add the marketplace
/plugin marketplace add jmagar/claude-homelab

# Install the core hub
/plugin install homelab-core @jmagar-claude-homelab
```

---

## ⚙️ Configuration & Credentials
All homelab services share a central credential store managed by `homelab-core`.

**Location:** `~/.claude-homelab/.env`

### Bootstrapping Credentials
```bash
# Interactive setup wizard
/homelab-core:setup

# Manual bootstrap via script
curl -sSL https://raw.githubusercontent.com/jmagar/claude-homelab/main/scripts/setup-creds.sh | bash
```

> **Security Note:** `homelab-core` enforces `chmod 600` on your `.env` file and provides a shared `load-env.sh` helper for all sub-plugins.

---

## 🛠️ Available Tools & Resources

### 🔧 Top-Level Commands
| Command | Argument Hint | Description |
|---------|---------------|-------------|
| **`/check`** | `[target]` | System-wide health and dependency validation |
| **`/deploy`** | `<env>` | Managed deployment workflow for homelab stacks |
| **`/quick-push`** | `[msg]` | Standardized git commit and push workflow |
| **`/save-to-md`** | `<file>` | Export current session context to structured Markdown |

### 🔧 Namespaced Commands
| Namespace | Commands | Description |
|-----------|----------|-------------|
| **`/homelab`** | `system-resources`, `docker-health`, `disk-space`, `zfs-health` | Infrastructure monitoring |
| **`/notebooklm`** | `create`, `ask`, `source`, `generate`, `download`, `list`, `research` | Automation for Google NotebookLM |

### 📊 Resources
| URI | Description | Output Format |
|-----|-------------|---------------|
| `ui://homelab/health` | Real-time service health dashboard | Interactive Widget |
| `ui://homelab/stats` | System resource overview | Live Metrics |

---

## 🏗️ Architecture & Design
`homelab-core` uses a **Symlink-Driven Architecture** for bash-path installs and a **Marketplace-First** model for Claude Code.
- **Shared Library:** Centralized `scripts/load-env.sh` for all plugins.
- **Prompts Layer:** Separated `.toml` prompt sidecars in `prompts/` for maintainability.
- **Verification:** Mandatory `scripts/verify.sh` to ensure ecosystem integrity.

---

## 🔧 Development
### Setup
```bash
# Create all symlinks
./scripts/setup-symlinks.sh

# Verify the environment
./scripts/verify.sh
```

### Quality Standards
- **Bash:** `set -euo pipefail` strict mode required for all scripts.
- **JSON:** All tools must return machine-readable JSON on success/failure.
- **Version Bumping:** Mandatory version synchronization across all manifest files.

---

## 🐛 Troubleshooting
| Issue | Cause | Solution |
|-------|-------|----------|
| **.env missing** | First-time setup | Run `/homelab-core:setup` |
| **Symlink broken** | Manual file move | Run `scripts/setup-symlinks.sh` |
| **API Error** | Credential mismatch | Check `~/.claude-homelab/.env` |

---

## 📄 License
MIT © jmagar
