---
name: setup
description: "Interactive credential setup wizard for claude-homelab. Use when the user wants to configure credentials, set up a new service, update API keys, or run initial setup after installing the homelab-core plugin. Triggers on: 'setup credentials', 'configure plex', 'add my API key', 'I just installed homelab-core', 'setup homelab', or any mention of needing to configure a specific service."
---

# Homelab Credential Setup Wizard

You are guiding the user through configuring their `~/.claude-homelab/.env` file. This is the single credential store for all homelab service plugins.

## Before You Start

Check the current state:
```bash
[ -f ~/.claude-homelab/.env ] && echo "EXISTS" || echo "MISSING"
[ -s ~/.claude-homelab/.env ] && echo "NON-EMPTY" || echo "EMPTY"
```

If the file is missing entirely, run `setup-creds.sh` first to create it from the template:
```bash
"${CLAUDE_PLUGIN_ROOT:-$HOME/claude-homelab}/scripts/setup-creds.sh"
```

## The Wizard Flow

### Step 1: Ask which services the user runs

Group the choices to make it manageable:

> "Which of these do you use? (say all that apply, or 'all', or list numbers)"
>
> **Media**
> 1. Plex — media server
> 2. Radarr — movies
> 3. Sonarr — TV shows
> 4. Overseerr — media requests
> 5. Prowlarr — indexers
> 6. Tautulli — Plex analytics
>
> **Downloads**
> 7. qBittorrent — torrents
> 8. SABnzbd — Usenet
>
> **Infrastructure**
> 9. Unraid — NAS/hypervisor (can have 2 servers)
> 10. UniFi — network
> 11. Tailscale — VPN mesh
> 12. ZFS — storage (no credentials needed, just CLI access)
>
> **Utilities**
> 13. Gotify — push notifications
> 14. Linkding — bookmarks
> 15. Memos — notes
> 16. ByteStash — code snippets
> 17. Paperless-ngx — documents
> 18. Radicale — calendar/contacts

Wait for the user's response before continuing.

### Step 2: For each selected service, collect credentials

Work through services **one at a time**. For each service:

1. Tell the user what you need and where to find it
2. Ask them to paste/type the value
3. Write it to `~/.claude-homelab/.env` immediately using `sed -i`
4. Confirm it was saved before moving to the next service

**Never echo or log credential values.** Use this pattern to write without revealing:
```bash
sed -i "s|^SERVICE_URL=.*|SERVICE_URL=$value|" ~/.claude-homelab/.env
```

If a key doesn't exist in the file yet, append it:
```bash
echo "SERVICE_KEY=$value" >> ~/.claude-homelab/.env
```

Always ensure `chmod 600 ~/.claude-homelab/.env` after writing.

### Service-specific guidance

**Plex** (`PLEX_URL`, `PLEX_TOKEN`)
- URL: `https://your-plex-ip:32400`
- Token: Settings → Account → XML TV metadata path — token is in the URL, or use [plex.tv/claim](https://plex.tv/claim)

**Radarr/Sonarr/Prowlarr/Overseerr** (`*_URL`, `*_API_KEY`)
- URL: the base URL including port
- API key: Settings → General → API Key

**Tautulli** (`TAUTULLI_URL`, `TAUTULLI_API_KEY`)
- API key: Settings → Web Interface → API key

**qBittorrent** (`QBITTORRENT_URL`, `QBITTORRENT_USERNAME`, `QBITTORRENT_PASSWORD`)
- URL: the WebUI URL
- Credentials: whatever you set in the WebUI

**SABnzbd** (`SABNZBD_URL`, `SABNZBD_API_KEY`)
- URL: the SABnzbd web interface URL
- API key: Config → General → API Key

**Unraid** (`UNRAID_SERVER1_NAME`, `UNRAID_SERVER1_URL`, `UNRAID_SERVER1_API_KEY`, and optionally `UNRAID_SERVER2_*`)
- URL: `https://your-unraid-ip/graphql`
- API key: Unraid Settings → Management Access → API Keys → Create (Viewer role is sufficient)
- Ask the user what they want to name each server (used as the display label in health checks)
- Supports two servers; skip SERVER2 if they only have one

**UniFi** (`UNIFI_URL`, `UNIFI_USERNAME`, `UNIFI_PASSWORD`, `UNIFI_SITE`)
- URL: `https://your-unifi-controller-ip`
- Site: usually `default`

**Tailscale** (`TAILSCALE_API_KEY`, `TAILSCALE_TAILNET`)
- API key: [tailscale.com/admin/settings/keys](https://tailscale.com/admin/settings/keys)
- Tailnet: your tailnet name (e.g., `example.com` or `-` for personal)

**Gotify** (`GOTIFY_URL`, `GOTIFY_TOKEN`)
- URL: your Gotify server URL
- Token: create an application in Gotify UI, copy its token

**Linkding** (`LINKDING_URL`, `LINKDING_API_KEY`)
- API key: Settings → REST API → API Token

**Memos** (`MEMOS_URL`, `MEMOS_API_TOKEN`)
- Token: Settings → My Account → API Tokens

**ByteStash** (`BYTESTASH_URL`, `BYTESTASH_API_KEY`)
- API key: ByteStash Settings → API

**Paperless-ngx** (`PAPERLESS_URL`, `PAPERLESS_API_TOKEN`)
- Token: Admin → Auth Tokens → Add token

**Radicale** (`RADICALE_URL`, `RADICALE_USERNAME`, `RADICALE_PASSWORD`)
- URL: `https://your-radicale-url`
- Credentials: whatever you configured in Radicale

### Step 3: Verify and offer health check

After collecting credentials, confirm:

> "All set! I've saved credentials for: [list services]. Want me to run a health check to verify everything is reachable?"

If yes, invoke `/homelab-core:health` (or tell them to run it manually).

## Reconfiguration

If the user already has an `.env` and just wants to update one service:
- Ask which service
- Ask for the new values
- Update only those specific keys with `sed -i`
- Don't touch anything else

## Security Rules

- Never print, echo, or log any credential value
- Never show the contents of `.env`
- Always set `chmod 600 ~/.claude-homelab/.env` after any write
- If the user accidentally pastes a credential in chat, acknowledge it, don't repeat it, and remind them credentials should only go into the `.env` file
