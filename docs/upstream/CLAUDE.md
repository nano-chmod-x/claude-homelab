# Upstream Service Integration Reference

How claude-homelab skills and MCP servers integrate with external services.

## Purpose

This document is the single reference for every upstream service that claude-homelab wraps. It covers the API access pattern, authentication method, required credentials, and skill directory for each service. Use it when adding new integrations, debugging auth failures, or auditing credential usage.

## Credential conventions

All credentials live in `~/.claude-homelab/.env` (never committed). The naming convention is:

| Pattern | Meaning | Example |
| --- | --- | --- |
| `SERVICE_URL` | Base URL of the service | `RADARR_URL` |
| `SERVICE_API_KEY` | API key for authentication | `RADARR_API_KEY` |
| `SERVICE_TOKEN` | Bearer or session token | `PLEX_TOKEN` |
| `SERVICE_USERNAME` / `SERVICE_PASSWORD` | Basic or form auth | `QBITTORRENT_USERNAME` |
| `SERVICE_API_TOKEN` | Token-style auth (DRF, etc.) | `PAPERLESS_API_TOKEN` |
| `SERVICE1_URL`, `SERVICE2_URL` | Multi-instance numbering | `UNRAID_SERVER1_URL` |

Scripts load credentials through the shared library:

```bash
source ~/.claude-homelab/load-env.sh
load_service_credentials "service-name" "SERVICE_URL" "SERVICE_API_KEY"
```

## Services by category

### Media Management

#### Plex

| Field | Value |
| --- | --- |
| What it does | Media server -- libraries, playback, metadata, sessions |
| API type | REST API (XML/JSON) |
| Auth method | Custom header `X-Plex-Token` + query parameter |
| Auth header | `X-Plex-Token: <token>` |
| Env vars | `PLEX_URL`, `PLEX_TOKEN` |
| Skill directory | `skills/plex/` |
| API base | `$PLEX_URL/` (no versioned prefix) |

```bash
# Example: list libraries
curl -sS -H "Accept: application/json" -H "X-Plex-Token: $PLEX_TOKEN" \
  "$PLEX_URL/library/sections?X-Plex-Token=$PLEX_TOKEN"
```

#### Radarr

| Field | Value |
| --- | --- |
| What it does | Movie management -- search, add, monitor, organize |
| API type | REST API v3 |
| Auth method | API key header |
| Auth header | `X-Api-Key: <key>` |
| Env vars | `RADARR_URL`, `RADARR_API_KEY`, `RADARR_DEFAULT_QUALITY_PROFILE` (optional) |
| Skill directory | `skills/radarr/` |
| API base | `$RADARR_URL/api/v3` |

```bash
# Example: search movies
curl -s -H "X-Api-Key: $RADARR_API_KEY" "$RADARR_URL/api/v3/movie/lookup?term=Dune"
```

#### Sonarr

| Field | Value |
| --- | --- |
| What it does | TV show management -- search, add, monitor, organize |
| API type | REST API v3 |
| Auth method | API key header |
| Auth header | `X-Api-Key: <key>` |
| Env vars | `SONARR_URL`, `SONARR_API_KEY`, `SONARR_DEFAULT_QUALITY_PROFILE` (optional) |
| Skill directory | `skills/sonarr/` |
| API base | `$SONARR_URL/api/v3` |

```bash
# Example: search TV shows
curl -s -H "X-Api-Key: $SONARR_API_KEY" "$SONARR_URL/api/v3/series/lookup?term=Bluey"
```

#### Prowlarr

| Field | Value |
| --- | --- |
| What it does | Indexer manager -- search across all configured indexers |
| API type | REST API v1 |
| Auth method | API key header |
| Auth header | `X-Api-Key: <key>` |
| Env vars | `PROWLARR_URL`, `PROWLARR_API_KEY` |
| Skill directory | `skills/prowlarr/` |
| API base | `$PROWLARR_URL/api/v1` |

```bash
# Example: search indexers
curl -s -H "X-Api-Key: $PROWLARR_API_KEY" "$PROWLARR_URL/api/v1/search?query=term&type=search"
```

#### Overseerr

| Field | Value |
| --- | --- |
| What it does | Media request management -- request movies/TV, track status |
| API type | REST API v1 |
| Auth method | API key header |
| Auth header | `X-Api-Key: <key>` |
| Env vars (skill) | `OVERSEERR_URL`, `OVERSEERR_API_KEY` |
| Env vars (MCP) | `OVERSEERR_MCP_TOKEN`, `OVERSEERR_MCP_PORT` |
| Skill directory | `skills/` (bundled) + external MCP repo |
| API base | `$OVERSEERR_URL/api/v1` |

```bash
# Example: search media
curl -s -H "X-Api-Key: $OVERSEERR_API_KEY" "$OVERSEERR_URL/api/v1/search?query=Inception"
```

#### Tautulli

| Field | Value |
| --- | --- |
| What it does | Plex analytics -- watch history, statistics, notifications |
| API type | REST API v2 |
| Auth method | API key as query parameter |
| Auth header | None (key in URL: `?apikey=<key>`) |
| Env vars | `TAUTULLI_URL`, `TAUTULLI_API_KEY` |
| Skill directory | `skills/tautulli/` |
| API base | `$TAUTULLI_URL/api/v2` |

```bash
# Example: get activity
curl -s "$TAUTULLI_URL/api/v2?apikey=$TAUTULLI_API_KEY&cmd=get_activity"
```

### Downloads

#### SABnzbd

| Field | Value |
| --- | --- |
| What it does | Usenet download client -- queue management, history, categories |
| API type | REST API |
| Auth method | API key as query parameter |
| Auth header | None (key in URL: `?apikey=<key>`) |
| Env vars | `SABNZBD_URL`, `SABNZBD_API_KEY` |
| Skill directory | `skills/sabnzbd/` |
| API base | `$SABNZBD_URL/api` |

```bash
# Example: get queue
curl -s "$SABNZBD_URL/api?apikey=$SABNZBD_API_KEY&mode=queue&output=json"
```

#### qBittorrent

| Field | Value |
| --- | --- |
| What it does | BitTorrent client -- torrent management, downloads, categories |
| API type | REST API (WebUI) |
| Auth method | Session cookie (form login) |
| Auth header | Cookie-based (login first, then use session cookie) |
| Env vars | `QBITTORRENT_URL`, `QBITTORRENT_USERNAME`, `QBITTORRENT_PASSWORD` |
| Skill directory | `skills/qbittorrent/` |
| API base | `$QBITTORRENT_URL/api/v2` |

```bash
# Example: login then list torrents
curl -s -c /tmp/qbit_cookie.txt \
  --data "username=$QBITTORRENT_USERNAME&password=$QBITTORRENT_PASSWORD" \
  "$QBITTORRENT_URL/api/v2/auth/login"
curl -s -b /tmp/qbit_cookie.txt "$QBITTORRENT_URL/api/v2/torrents/info"
```

### Productivity

#### Paperless-ngx

| Field | Value |
| --- | --- |
| What it does | Document management -- upload, OCR, search, tag, organize |
| API type | REST API (Django REST Framework) |
| Auth method | Token authentication |
| Auth header | `Authorization: Token <token>` |
| Env vars | `PAPERLESS_URL`, `PAPERLESS_API_TOKEN` |
| Skill directory | `skills/paperless-ngx/` |
| API base | `$PAPERLESS_URL/api` |

```bash
# Example: search documents
curl -s -H "Authorization: Token $PAPERLESS_API_TOKEN" \
  "$PAPERLESS_URL/api/documents/?query=invoice"
```

#### Linkding

| Field | Value |
| --- | --- |
| What it does | Bookmark manager -- save, tag, search bookmarks |
| API type | REST API |
| Auth method | Token authentication |
| Auth header | `Authorization: Token <token>` |
| Env vars | `LINKDING_URL`, `LINKDING_API_KEY` |
| Skill directory | `skills/linkding/` |
| API base | `$LINKDING_URL/api` |

```bash
# Example: list bookmarks
curl -s -H "Authorization: Token $LINKDING_API_KEY" \
  "$LINKDING_URL/api/bookmarks/"
```

#### Memos

| Field | Value |
| --- | --- |
| What it does | Note-taking -- create, search, tag memos |
| API type | REST API (protobuf-backed) |
| Auth method | Bearer token |
| Auth header | `Authorization: Bearer <token>` |
| Env vars | `MEMOS_URL`, `MEMOS_API_TOKEN` |
| Skill directory | `skills/memos/` |
| API base | `$MEMOS_URL/api/v1` |

```bash
# Example: list memos
curl -s -H "Authorization: Bearer $MEMOS_API_TOKEN" \
  "$MEMOS_URL/api/v1/memos"
```

#### ByteStash

| Field | Value |
| --- | --- |
| What it does | Code snippet storage -- save, search, categorize code snippets |
| API type | REST API |
| Auth method | API key |
| Auth header | `Authorization: Bearer <key>` |
| Env vars | `BYTESTASH_URL`, `BYTESTASH_API_KEY` |
| Skill directory | `skills/bytestash/` |
| API base | `$BYTESTASH_URL/api` |

```bash
# Example: list snippets
curl -s -H "Authorization: Bearer $BYTESTASH_API_KEY" \
  "$BYTESTASH_URL/api/snippets"
```

#### Radicale

| Field | Value |
| --- | --- |
| What it does | CalDAV/CardDAV server -- calendars, contacts, events |
| API type | CalDAV/CardDAV (WebDAV-based) |
| Auth method | Basic authentication |
| Auth header | `Authorization: Basic <base64(user:pass)>` |
| Env vars | `RADICALE_URL`, `RADICALE_USERNAME`, `RADICALE_PASSWORD` |
| Skill directory | `skills/radicale/` |
| Client library | Python `caldav` (not raw curl) |

```python
# Example: connect via caldav library
import caldav
client = caldav.DAVClient(
    url=RADICALE_URL,
    username=RADICALE_USERNAME,
    password=RADICALE_PASSWORD
)
principal = client.principal()
calendars = principal.calendars()
```

### Infrastructure

#### Tailscale

| Field | Value |
| --- | --- |
| What it does | Mesh VPN management -- devices, routes, ACLs, DNS |
| API type | REST API v2 (cloud-hosted) |
| Auth method | Basic auth (API key as username, empty password) |
| Auth header | `Authorization: Basic <base64(apikey:)>` |
| Env vars | `TAILSCALE_API_KEY`, `TAILSCALE_TAILNET` |
| Skill directory | `skills/tailscale/` |
| API base | `https://api.tailscale.com/api/v2` |

```bash
# Example: list devices
curl -s -u "$TAILSCALE_API_KEY:" \
  "https://api.tailscale.com/api/v2/tailnet/$TAILSCALE_TAILNET/devices"
```

#### ZFS

| Field | Value |
| --- | --- |
| What it does | Storage pool management -- health, scrubs, snapshots, SMART data |
| API type | Local CLI commands (`zpool`, `zfs`) |
| Auth method | None (local/SSH execution) |
| Auth header | N/A |
| Env vars | `ZFS_HOST` (optional, for remote execution) |
| Skill directory | `skills/zfs/` |

```bash
# Example: check pool health
zpool status -v
zpool list -o name,size,alloc,free,frag,cap,health
```

### AI / Research

#### NotebookLM

| Field | Value |
| --- | --- |
| What it does | Google NotebookLM -- notebooks, sources, research, artifact generation |
| API type | Proprietary (browser automation / cookie auth) |
| Auth method | Session cookie |
| Auth header | Cookie-based |
| Env vars | `NOTEBOOKLM_COOKIE`, `NOTEBOOKLM_AUTH_JSON`, `NOTEBOOKLM_LOG_LEVEL` (optional) |
| Skill directory | `skills/notebooklm/` |

```bash
# Example: uses shell scripts wrapping the notebooklm CLI
./scripts/nlm-research.sh -n <notebook_id> "research query"
```

## Authentication method summary

| Auth method | Services | Header pattern |
| --- | --- | --- |
| API key header (`X-Api-Key`) | Radarr, Sonarr, Prowlarr, Overseerr | `X-Api-Key: <key>` |
| Custom token header | Plex | `X-Plex-Token: <token>` |
| API key in query string | Tautulli, SABnzbd | `?apikey=<key>` |
| Token auth (DRF-style) | Paperless-ngx, Linkding | `Authorization: Token <token>` |
| Bearer token | Memos, ByteStash | `Authorization: Bearer <token>` |
| Basic auth | Tailscale, Radicale | `Authorization: Basic <base64>` |
| Session cookie (form login) | qBittorrent | POST login, then cookie |
| Session cookie (browser) | NotebookLM | Exported browser cookie |
| None (local CLI) | ZFS | N/A |

## Complete env var reference

The table below lists every credential env var grouped by service. See `~/.claude-homelab/.env` (created from `.env.example`) for the full file.

| Service | Env var | Required | Purpose |
| --- | --- | --- | --- |
| **Plex** | `PLEX_URL` | Yes | Base URL |
| | `PLEX_TOKEN` | Yes | Authentication token |
| **Radarr** | `RADARR_URL` | Yes | Base URL |
| | `RADARR_API_KEY` | Yes | API key |
| | `RADARR_DEFAULT_QUALITY_PROFILE` | No | Default quality profile ID |
| **Sonarr** | `SONARR_URL` | Yes | Base URL |
| | `SONARR_API_KEY` | Yes | API key |
| | `SONARR_DEFAULT_QUALITY_PROFILE` | No | Default quality profile ID |
| **Prowlarr** | `PROWLARR_URL` | Yes | Base URL |
| | `PROWLARR_API_KEY` | Yes | API key |
| **Overseerr** | `OVERSEERR_URL` | Yes | Base URL |
| | `OVERSEERR_API_KEY` | Yes | API key |
| **Tautulli** | `TAUTULLI_URL` | Yes | Base URL |
| | `TAUTULLI_API_KEY` | Yes | API key |
| **SABnzbd** | `SABNZBD_URL` | Yes | Base URL |
| | `SABNZBD_API_KEY` | Yes | API key |
| **qBittorrent** | `QBITTORRENT_URL` | Yes | Base URL |
| | `QBITTORRENT_USERNAME` | Yes | Login username |
| | `QBITTORRENT_PASSWORD` | Yes | Login password |
| **Paperless-ngx** | `PAPERLESS_URL` | Yes | Base URL |
| | `PAPERLESS_API_TOKEN` | Yes | DRF token |
| **Linkding** | `LINKDING_URL` | Yes | Base URL |
| | `LINKDING_API_KEY` | Yes | API token |
| **Memos** | `MEMOS_URL` | Yes | Base URL |
| | `MEMOS_API_TOKEN` | Yes | Bearer token |
| **ByteStash** | `BYTESTASH_URL` | Yes | Base URL |
| | `BYTESTASH_API_KEY` | Yes | API key |
| **Radicale** | `RADICALE_URL` | Yes | Base URL |
| | `RADICALE_USERNAME` | Yes | Basic auth username |
| | `RADICALE_PASSWORD` | Yes | Basic auth password |
| **Tailscale** | `TAILSCALE_API_KEY` | Yes | API key (used as basic auth username) |
| | `TAILSCALE_TAILNET` | Yes | Tailnet name or `-` for default |
| **ZFS** | `ZFS_HOST` | No | Remote host (omit for local) |
| **NotebookLM** | `NOTEBOOKLM_COOKIE` | Yes | Session cookie |
| | `NOTEBOOKLM_AUTH_JSON` | No | Full auth JSON blob |
| | `NOTEBOOKLM_LOG_LEVEL` | No | Log verbosity |

## Skill directory map

| Skill directory | Service | Script language |
| --- | --- | --- |
| `skills/plex/` | Plex Media Server | Bash |
| `skills/radarr/` | Radarr | Bash |
| `skills/sonarr/` | Sonarr | Bash |
| `skills/prowlarr/` | Prowlarr | Bash |
| `skills/tautulli/` | Tautulli | Bash |
| `skills/sabnzbd/` | SABnzbd | Bash |
| `skills/qbittorrent/` | qBittorrent | Bash |
| `skills/paperless-ngx/` | Paperless-ngx | Bash |
| `skills/linkding/` | Linkding | Bash |
| `skills/memos/` | Memos | Bash |
| `skills/bytestash/` | ByteStash | Bash |
| `skills/radicale/` | Radicale | Python |
| `skills/tailscale/` | Tailscale | Bash |
| `skills/zfs/` | ZFS | Bash |
| `skills/notebooklm/` | NotebookLM | Bash |
| `skills/homelab-health/` | Health dashboard | Bash |
| `skills/homelab-setup/` | Credential wizard | (SKILL.md only) |
| `skills/gh-address-comments/` | GitHub PR comments | (SKILL.md only) |

## Cross-references

- `.env.example` -- complete credential template with all env vars
- `skills/CLAUDE.md` -- skill development guidelines and credential patterns
- `CLAUDE.md` (repo root) -- overall architecture and symlink setup
- `scripts/load-env.sh` -- shared credential loading library
- `skills/homelab-health/scripts/check-health.sh` -- health checks that hit all service URLs
