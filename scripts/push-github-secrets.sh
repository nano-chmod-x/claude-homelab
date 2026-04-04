#!/usr/bin/env bash
# scripts/push-github-secrets.sh
#
# Push upstream service credentials from ~/.claude-homelab/.env to GitHub
# Actions secrets for all MCP server repos.
#
# MCP bearer tokens (*_MCP_TOKEN) are NOT pushed — CI generates them at
# runtime since it controls both the server and the client.
#
# Usage:
#   ./scripts/push-github-secrets.sh            # Push all repos
#   ./scripts/push-github-secrets.sh overseerr-mcp  # One repo only
#
# Prerequisites:
#   - gh CLI authenticated: gh auth status
#   - ~/.claude-homelab/.env populated with upstream credentials

set -euo pipefail

ENV_FILE="${HOME}/.claude-homelab/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: $ENV_FILE not found. Run scripts/setup-creds.sh first." >&2
    exit 1
fi

# Load env (strip comments and blank lines, no export)
while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]] || continue
    declare "${line?}"
done < "$ENV_FILE"

push_secret() {
    local repo="$1"
    local key="$2"
    local val="${!key:-}"
    if [[ -z "$val" ]]; then
        echo "  SKIP  $key (not set in .env)"
        return
    fi
    gh secret set "$key" --repo "jmagar/$repo" --body "$val" 2>&1 && echo "  ✓     $key"
}

push_repo() {
    local repo="$1"
    shift
    echo ""
    echo "── $repo ─────────────────────────────────"
    for key in "$@"; do
        push_secret "$repo" "$key"
    done
}

TARGET="${1:-}"

run_all() {
    push_repo overseerr-mcp \
        OVERSEERR_URL \
        OVERSEERR_API_KEY

    push_repo gotify-mcp \
        GOTIFY_URL \
        GOTIFY_APP_TOKEN

    push_repo unifi-mcp \
        UNIFI_URL \
        UNIFI_USERNAME \
        UNIFI_PASSWORD

    # swag-mcp: no upstream creds; uses fixture files in CI
    # push_repo swag-mcp  (nothing to push)

    push_repo unraid-mcp \
        UNRAID_API_URL \
        UNRAID_API_KEY

    push_repo synapse-mcp \
        SYNAPSE_MCP_URL \
        SYNAPSE_HOSTS_CONFIG

    push_repo arcane-mcp \
        ARCANE_API_URL \
        ARCANE_API_KEY

    # syslog-mcp: no upstream creds; it IS the service
    # push_repo syslog-mcp  (nothing to push)
}

if [[ -n "$TARGET" ]]; then
    case "$TARGET" in
        overseerr-mcp)  push_repo overseerr-mcp OVERSEERR_URL OVERSEERR_API_KEY ;;
        gotify-mcp)     push_repo gotify-mcp GOTIFY_URL GOTIFY_APP_TOKEN ;;
        unifi-mcp)      push_repo unifi-mcp UNIFI_URL UNIFI_USERNAME UNIFI_PASSWORD ;;
        swag-mcp)       echo "swag-mcp: no upstream secrets to push" ;;
        unraid-mcp)     push_repo unraid-mcp UNRAID_API_URL UNRAID_API_KEY ;;
        synapse-mcp)    push_repo synapse-mcp SYNAPSE_MCP_URL SYNAPSE_HOSTS_CONFIG ;;
        arcane-mcp)     push_repo arcane-mcp ARCANE_API_URL ARCANE_API_KEY ;;
        syslog-mcp)     echo "syslog-mcp: no upstream secrets to push" ;;
        *)
            echo "ERROR: Unknown repo '$TARGET'. Valid: overseerr-mcp gotify-mcp unifi-mcp swag-mcp unraid-mcp synapse-mcp arcane-mcp syslog-mcp" >&2
            exit 1
            ;;
    esac
else
    run_all
fi

echo ""
echo "Done."
