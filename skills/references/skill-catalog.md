# Skills Catalog

Complete catalog of all available skills in `skills/`. Update this file when adding or removing skills.

## Media Management

#### overseerr
Request movies and TV shows via Overseerr API.
- **Path:** `skills/overseerr/`
- **Type:** Read-Write (Safe)
- **Scripts:** Node.js ESM (.mjs)
- **Credentials:** `.env` (OVERSEERR_URL, OVERSEERR_API_KEY)
- **Version:** 1.2.0
- **Status:** ✅ Production ready

#### sonarr
Search and add TV shows to Sonarr library.
- **Path:** `skills/sonarr/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (SONARR_URL, SONARR_API_KEY)
- **Version:** 1.3.0
- **Status:** ✅ Production ready

#### radarr
Search and add movies to Radarr library with collection support.
- **Path:** `skills/radarr/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (RADARR_URL, RADARR_API_KEY)
- **Version:** 1.3.0
- **Status:** ✅ Production ready

#### prowlarr
Search indexers and manage Prowlarr.
- **Path:** `skills/prowlarr/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (PROWLARR_URL, PROWLARR_API_KEY)
- **Status:** ✅ Production ready

#### plex
Control Plex Media Server - browse, search, monitor sessions.
- **Path:** `skills/plex/`
- **Type:** Read-Only
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (PLEX_URL, PLEX_TOKEN)
- **Version:** 1.3.0
- **Status:** ✅ Production ready

#### tautulli
Monitor and analyze Plex Media Server usage via Tautulli analytics API.
- **Path:** `skills/tautulli/`
- **Type:** Read-Only
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (TAUTULLI_URL, TAUTULLI_API_KEY)
- **Version:** 1.0.0
- **Features:** Current activity, playback history, user statistics, library analytics, popular content, stream analytics, temporal trends
- **Integration:** Complements `plex` skill with historical analytics and viewing trends
- **Status:** ✅ Production ready

## Download Clients

#### qbittorrent
Manage torrents with qBittorrent WebUI API.
- **Path:** `skills/qbittorrent/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (QBITTORRENT_URL, QBITTORRENT_USERNAME, QBITTORRENT_PASSWORD)
- **Status:** ✅ Production ready

#### sabnzbd
Manage NZB downloads with SABnzbd API.
- **Path:** `skills/sabnzbd/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (SABNZBD_URL, SABNZBD_API_KEY)
- **Status:** ✅ Production ready

## Infrastructure

#### unraid
Query and monitor Unraid servers via GraphQL API.
- **Path:** `skills/unraid/`
- **Type:** Read-Only
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (UNRAID_URL, UNRAID_API_KEY)
- **Status:** ✅ Production ready

#### unifi
Monitor UniFi network via local gateway API.
- **Path:** `skills/unifi/`
- **Type:** Read-Only
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (UNIFI_URL, UNIFI_USERNAME, UNIFI_PASSWORD, UNIFI_SITE)
- **Version:** 1.2.0
- **Status:** ✅ Production ready (migrated to .env)

#### tailscale
Manage Tailscale tailnet via CLI and API.
- **Path:** `skills/tailscale/`
- **Type:** Read-Write (Safe)
- **Scripts:** CLI + Bash (.sh)
- **Credentials:** `.env` (TAILSCALE_API_KEY, TAILSCALE_TAILNET)
- **Status:** ✅ Production ready

## Utilities

#### gotify
Send and receive push notifications.
- **Path:** `skills/gotify/`
- **Type:** Read-Write (Safe)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (GOTIFY_URL, GOTIFY_TOKEN)
- **Version:** 1.3.0
- **Status:** ✅ Production ready

#### linkding
Manage bookmarks with Linkding API.
- **Path:** `skills/linkding/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (LINKDING_URL, LINKDING_API_KEY)
- **Status:** ✅ Production ready

#### memos
Manage notes and memos in self-hosted Memos instance.
- **Path:** `skills/memos/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (MEMOS_URL, MEMOS_API_TOKEN)
- **Features:** Create/update/delete memos, search by content/tags, upload attachments, tag management
- **Important:** Tags are parsed from content (#hashtag format), not separate field
- **Version:** 1.1.0
- **Status:** ✅ Production ready

#### nugs
Download and manage live music from Nugs.net.
- **Path:** `skills/nugs/`
- **Type:** Read-Write (Safe)
- **Scripts:** Binary CLI (`/home/jmagar/workspace/nugs/nugs`)
- **Credentials:** Config file `~/.nugs/config.json` (email, password, outPath, format)
- **Features:** Browse 13,000+ concerts offline, download shows, gap detection, coverage tracking, auto-refresh
- **Important:** Uses config file (not .env), supports rclone integration, requires FFmpeg for videos
- **Version:** 1.0.0
- **Status:** ✅ Production ready

#### bytestash
Manage code snippets in self-hosted ByteStash snippet storage service.
- **Path:** `skills/bytestash/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (BYTESTASH_URL, BYTESTASH_API_KEY)
- **Features:** Create/update/delete snippets, multi-file support, share management (public/protected/expiring), search, auto-categorization (30+ languages + context-aware patterns)
- **Important:** Supports multi-fragment snippets for related files, share links with access control, intelligent category detection from filename patterns
- **Version:** 1.1.0
- **Status:** ✅ Production ready

#### paperless-ngx
Manage documents in self-hosted Paperless-ngx document management system.
- **Path:** `skills/paperless-ngx/`
- **Type:** Read-Write (Safe + Destructive)
- **Scripts:** Bash (.sh)
- **Credentials:** `.env` (PAPERLESS_URL, PAPERLESS_API_TOKEN)
- **Features:** Upload documents with auto-OCR, full-text search, tag management, correspondent management, document metadata updates, bulk operations, archive/export, delete with confirmation
- **Important:** Auto-OCR processing, supports tags/correspondents/document types for organization, bulk operations for multiple documents
- **Version:** 1.0.0
- **Status:** ✅ Production ready

#### radicale
Manage calendars and contacts on self-hosted Radicale CalDAV/CardDAV server.
- **Path:** `skills/radicale/`
- **Type:** Read-Write (calendars and contacts)
- **Scripts:** Python (.py)
- **Credentials:** `.env` (RADICALE_URL, RADICALE_USERNAME, RADICALE_PASSWORD)
- **Features:** Calendar operations (list, create, search events), Contact operations (list, search, create contacts), Natural language parsing, ISO 8601 datetime support
- **Libraries:** caldav, vobject, icalendar (install with: `pip install caldav vobject icalendar`)
- **Protocols:** CalDAV (RFC 4791), CardDAV (RFC 6352)
- **Important:** All RFC protocol documentation embedded in Firecrawl vector database for semantic search
- **Version:** 1.0.0
- **Status:** ✅ Production ready
