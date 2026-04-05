# Prerequisites — claude-homelab

Required tools and versions before using or developing claude-homelab skills.

## Required

These tools must be installed for core functionality:

| Tool | Version | Purpose | Install |
| --- | --- | --- | --- |
| Bash | 4+ | Script execution, credential loading | System default (Linux) |
| curl | any | HTTP requests to upstream service APIs | `apt install curl` |
| jq | 1.6+ | JSON parsing and formatting | `apt install jq` |
| git | 2.40+ | Version control, clone, branch management | `apt install git` |
| Claude Code | latest | CLI that discovers and runs skills | [claude.ai/code](https://claude.ai/code) |

### Verify required tools

```bash
bash --version       # GNU bash, version 5.x.x (must be 4+)
curl --version       # curl X.Y.Z
jq --version         # jq-1.6+
git --version        # git version 2.40+
claude --version     # Claude Code CLI version
```

## Recommended

These tools enhance the development and operations workflow:

| Tool | Version | Purpose | Install |
| --- | --- | --- | --- |
| Docker | 24+ | Container builds for MCP server plugins | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose | v2+ | Multi-container orchestration | Bundled with Docker |
| just | latest | Task runner (30 recipes in Justfile) | `cargo install just` |
| openssl | any | Token generation, hash computation | `apt install openssl` |

### Verify recommended tools

```bash
docker --version           # Docker version 24+
docker compose version     # Docker Compose version v2+
just --version             # just X.Y.Z
openssl version            # OpenSSL X.Y.Z
```

## Optional

Required only for specific skills:

| Tool | Version | Skills | Install |
| --- | --- | --- | --- |
| Python | 3.11+ | Some skill scripts with complex logic | `apt install python3` |
| Node.js | 18+ | NotebookLM skill (Google API client) | [nodejs.org](https://nodejs.org/) |
| gh | latest | GitHub CLI for PRs and issue workflows | [cli.github.com](https://cli.github.com/) |

### Verify optional tools

```bash
python3 --version    # Python 3.11+
node --version       # v18+ or v22+
gh --version         # gh version X.Y.Z
```

## Environment setup

After installing prerequisites, set up credentials:

```bash
# Clone the repo
git clone https://github.com/jmagar/claude-homelab.git
cd claude-homelab

# Automated setup (creates symlinks and copies .env.example)
./scripts/setup-symlinks.sh

# Add your credentials
vim ~/.claude-homelab/.env

# Lock down permissions
chmod 600 ~/.claude-homelab/.env

# Verify everything is in place
./scripts/verify.sh
```

Or use the plugin marketplace:

```bash
# Plugin install (no symlinks needed)
/plugin marketplace add jmagar/claude-homelab
```

## Platform requirements

claude-homelab targets Linux only. No macOS compatibility shims are needed.

| Requirement | Detail |
| --- | --- |
| OS | Linux (any modern distribution) |
| Shell | Bash 4+ (default on all modern Linux) |
| Filesystem | Supports symlinks (any standard Linux filesystem) |
| Network | Outbound HTTPS to upstream service APIs |
| Permissions | User-level (no root required for core skills) |

## Verification checklist

Run this to confirm all prerequisites are met:

```bash
# One-liner to check all required tools
for cmd in bash curl jq git; do
    if command -v "$cmd" &>/dev/null; then
        echo "OK: $cmd ($(command -v "$cmd"))"
    else
        echo "MISSING: $cmd"
    fi
done

# Check Bash version is 4+
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    echo "OK: Bash ${BASH_VERSION}"
else
    echo "FAIL: Bash ${BASH_VERSION} (need 4+)"
fi

# Check jq version is 1.6+
if jq --version 2>/dev/null | grep -qE 'jq-1\.[6-9]|jq-[2-9]'; then
    echo "OK: $(jq --version)"
else
    echo "WARN: jq version may be too old"
fi
```

## Cross-references

- [TECH](TECH.md) — technology choices and tooling details
- [ARCH](ARCH.md) — architecture overview and data flow
- [SETUP](../SETUP.md) — step-by-step setup guide
