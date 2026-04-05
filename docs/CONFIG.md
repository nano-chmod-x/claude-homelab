# Configuration Reference

Complete environment variable reference for all services. All credentials are stored in `~/.claude-homelab/.env`.

## Environment file

```bash
cp .env.example ~/.claude-homelab/.env
chmod 600 ~/.claude-homelab/.env
```

Precedence (highest to lowest):
1. `~/.claude-homelab/.env` (loaded by `scripts/load-env.sh`)
2. Container environment variables (Docker `environment:` or `-e` flags)
3. System environment variables

## Media services

### Plex

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `PLEX_URL` | yes | -- | no | Base URL of Plex instance |
| `PLEX_TOKEN` | yes | -- | yes | Plex authentication token |

### Overseerr

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `OVERSEERR_URL` | yes | -- | no | Base URL of Overseerr instance |
| `OVERSEERR_API_KEY` | yes | -- | yes | Overseerr API key |
| `OVERSEERR_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `OVERSEERR_MCP_TRANSPORT` | no | `streamable-http` | no | MCP transport mode |
| `OVERSEERR_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `OVERSEERR_MCP_PORT` | no | `9151` | no | MCP server port |
| `OVERSEERR_LOG_LEVEL` | no | `DEBUG` | no | Log verbosity |
| `OVERSEERR_MCP_NO_AUTH` | no | `true` | no | Disable bearer auth (behind trusted proxy) |

### Radarr

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `RADARR_URL` | yes | -- | no | Base URL of Radarr instance |
| `RADARR_API_KEY` | yes | -- | yes | Radarr API key |
| `RADARR_DEFAULT_QUALITY_PROFILE` | no | `1` | no | Default quality profile ID |

### Sonarr

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `SONARR_URL` | yes | -- | no | Base URL of Sonarr instance |
| `SONARR_API_KEY` | yes | -- | yes | Sonarr API key |
| `SONARR_DEFAULT_QUALITY_PROFILE` | no | `1` | no | Default quality profile ID |

### Prowlarr

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `PROWLARR_URL` | yes | -- | no | Base URL of Prowlarr instance |
| `PROWLARR_API_KEY` | yes | -- | yes | Prowlarr API key |

### Tautulli

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `TAUTULLI_URL` | yes | -- | no | Base URL of Tautulli instance |
| `TAUTULLI_API_KEY` | yes | -- | yes | Tautulli API key |

## Download services

### SABnzbd

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `SABNZBD_URL` | yes | -- | no | Base URL of SABnzbd instance |
| `SABNZBD_API_KEY` | yes | -- | yes | SABnzbd API key |

### qBittorrent

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `QBITTORRENT_URL` | yes | -- | no | Base URL of qBittorrent WebUI |
| `QBITTORRENT_USERNAME` | yes | -- | yes | Login username |
| `QBITTORRENT_PASSWORD` | yes | -- | yes | Login password |

## Infrastructure

### Unraid

Supports multiple Unraid servers. Skill variables use numbered suffixes; MCP variables configure the MCP server itself.

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `UNRAID_SERVER1_NAME` | yes | -- | no | Friendly name for server 1 |
| `UNRAID_SERVER1_URL` | yes | -- | no | GraphQL endpoint for server 1 |
| `UNRAID_SERVER1_API_KEY` | yes | -- | yes | API key for server 1 |
| `UNRAID_SERVER2_NAME` | no | -- | no | Friendly name for server 2 |
| `UNRAID_SERVER2_URL` | no | -- | no | GraphQL endpoint for server 2 |
| `UNRAID_SERVER2_API_KEY` | no | -- | yes | API key for server 2 |
| `UNRAID_MCP_BEARER_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `UNRAID_API_URL` | MCP only | -- | no | GraphQL endpoint for MCP server |
| `UNRAID_API_KEY` | MCP only | -- | yes | API key for MCP server |
| `UNRAID_MCP_TRANSPORT` | no | `streamable-http` | no | MCP transport mode |
| `UNRAID_MCP_PORT` | no | `6970` | no | MCP server port |
| `UNRAID_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `UNRAID_MCP_LOG_LEVEL` | no | `INFO` | no | Log verbosity |
| `UNRAID_MCP_ALLOW_DESTRUCTIVE` | no | `false` | no | Allow destructive operations without confirm |
| `UNRAID_MCP_ALLOW_YOLO` | no | `false` | no | Alias for ALLOW_DESTRUCTIVE |
| `UNRAID_MCP_DISABLE_HTTP_AUTH` | no | `true` | no | Disable HTTP auth (behind trusted proxy) |

### UniFi

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `UNIFI_URL` | yes | -- | no | UniFi controller URL (skill) |
| `UNIFI_USERNAME` | yes | -- | yes | Controller login username |
| `UNIFI_PASSWORD` | yes | -- | yes | Controller login password |
| `UNIFI_SITE` | no | `default` | no | UniFi site name |
| `UNIFI_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `UNIFI_CONTROLLER_URL` | MCP only | -- | no | Controller URL with port |
| `UNIFI_VERIFY_SSL` | no | `false` | no | Verify SSL certificates |
| `UNIFI_IS_UDM_PRO` | no | `true` | no | Using UDM Pro hardware |
| `UNIFI_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `UNIFI_MCP_PORT` | no | `8001` | no | MCP server port |
| `UNIFI_LOCAL_MCP_HOST` | no | `0.0.0.0` | no | Local MCP bind address |
| `UNIFI_LOCAL_MCP_PORT` | no | `8001` | no | Local MCP port |
| `UNIFI_LOCAL_MCP_LOG_LEVEL` | no | `DEBUG` | no | Local MCP log level |
| `UNIFI_LOCAL_MCP_LOG_FILE` | no | -- | no | Local MCP log file path |
| `UNIFI_MCP_NO_AUTH` | no | `true` | no | Disable bearer auth |

### SWAG (reverse proxy)

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `SWAG_HOST` | yes | -- | no | SSH host for SWAG container |
| `SWAG_CONTAINER_NAME` | no | `swag` | no | Docker container name |
| `SWAG_APPDATA_PATH` | yes | -- | no | Path to SWAG appdata |
| `SWAG_COMPOSE_PATH` | yes | -- | no | Path to SWAG compose file |
| `SWAG_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `SWAG_MCP_PROXY_CONFS_URI` | MCP only | -- | no | URI to proxy-confs directory |
| `SWAG_MCP_LOG_DIRECTORY` | no | -- | no | Log directory path |
| `SWAG_MCP_DEFAULT_AUTH_METHOD` | no | `authelia` | no | Default authentication method |
| `SWAG_MCP_DEFAULT_QUIC_ENABLED` | no | `false` | no | Enable QUIC by default |
| `SWAG_MCP_BACKUP_RETENTION_DAYS` | no | `30` | no | Days to retain config backups |
| `SWAG_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `SWAG_MCP_PORT` | no | `8012` | no | MCP server port |
| `SWAG_MCP_LOG_LEVEL` | no | `INFO` | no | Log verbosity |
| `SWAG_MCP_NO_AUTH` | no | `true` | no | Disable bearer auth |

### Synapse (Docker/SSH management)

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `SYNAPSE_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `SYNAPSE_ALLOW_ROOT_LOGIN` | no | `true` | no | Allow root SSH login |
| `SYNAPSE_MCP_ALLOW_DESTRUCTIVE` | no | `true` | no | Allow destructive operations |
| `SYNAPSE_MCP_NO_AUTH` | no | `1` | no | Disable bearer auth |
| `SYNAPSE_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `SYNAPSE_MCP_PORT` | no | `8014` | no | MCP server port |
| `SYNAPSE_MCP_ALLOWED_HOSTS` | no | -- | no | Comma-separated allowed SSH hosts |
| `SYNAPSE_EXCLUDE_HOSTS` | no | -- | no | Comma-separated excluded hosts |
| `SYNAPSE_CONFIG_FILE` | no | -- | no | Path to synapse config JSON |

### Arcane (Docker management)

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `ARCANE_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `ARCANE_API_KEY` | yes | -- | yes | Arcane API key |
| `ARCANE_API_URL` | yes | -- | no | Arcane API URL |
| `ARCANE_MCP_TRANSPORT` | no | `http` | no | MCP transport mode |
| `ARCANE_MCP_BIND_PORT` | no | `3000` | no | Internal bind port |
| `ARCANE_MCP_PORT` | no | `44332` | no | Published MCP port |
| `ARCANE_MCP_AUTH_ENABLED` | no | `false` | no | Enable MCP auth |
| `ARCANE_MCP_ALLOW_YOLO` | no | `false` | no | Skip destructive confirmations |
| `ARCANE_MCP_ALLOW_DESTRUCTIVE` | no | `false` | no | Allow destructive operations |

### Syslog (log aggregation)

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `SYSLOG_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `SYSLOG_MCP_TRANSPORT` | no | `http` | no | MCP transport mode |
| `SYSLOG_HOST` | no | `0.0.0.0` | no | Syslog receiver bind address |
| `SYSLOG_PORT` | no | `1514` | no | Syslog receiver port |
| `SYSLOG_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `SYSLOG_MCP_PORT` | no | `3100` | no | MCP server port |
| `SYSLOG_MCP_DB_PATH` | no | `/data/syslog.db` | no | SQLite database path |
| `SYSLOG_MCP_POOL_SIZE` | no | `4` | no | Database connection pool size |
| `SYSLOG_MCP_RETENTION_DAYS` | no | `90` | no | Log retention in days |
| `SYSLOG_MCP_MAX_DB_SIZE_MB` | no | `10240` | no | Max database size in MB |
| `SYSLOG_MCP_RECOVERY_DB_SIZE_MB` | no | `9216` | no | Recovery threshold in MB |
| `RUST_LOG` | no | `info` | no | Rust log level |
| `NO_AUTH` | no | `true` | no | Disable authentication |

### Tailscale

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `TAILSCALE_API_KEY` | yes | -- | yes | Tailscale API key |
| `TAILSCALE_TAILNET` | yes | -- | no | Tailnet name or `-` for default |

### ZFS

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `ZFS_HOST` | yes | -- | no | Host running ZFS pools |

## Productivity and utilities

### Gotify

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `GOTIFY_URL` | yes | -- | no | Base URL of Gotify instance |
| `GOTIFY_TOKEN` | yes | -- | yes | Gotify app token (skill) |
| `GOTIFY_MCP_TOKEN` | MCP only | -- | yes | Bearer token for MCP auth |
| `GOTIFY_APP_TOKEN` | MCP only | -- | yes | Gotify app token for sending |
| `GOTIFY_CLIENT_TOKEN` | MCP only | -- | yes | Gotify client token for reading |
| `GOTIFY_MCP_TRANSPORT` | no | `http` | no | MCP transport mode |
| `GOTIFY_MCP_HOST` | no | `0.0.0.0` | no | MCP bind address |
| `GOTIFY_MCP_PORT` | no | `9158` | no | MCP server port |
| `GOTIFY_LOG_LEVEL` | no | `DEBUG` | no | Log verbosity |
| `GOTIFY_MCP_NO_AUTH` | no | `true` | no | Disable bearer auth |

### Linkding

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `LINKDING_URL` | yes | -- | no | Base URL of Linkding instance |
| `LINKDING_API_KEY` | yes | -- | yes | Linkding API key |

### Memos

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `MEMOS_URL` | yes | -- | no | Base URL of Memos instance |
| `MEMOS_API_TOKEN` | yes | -- | yes | Memos API token |

### ByteStash

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `BYTESTASH_URL` | yes | -- | no | Base URL of ByteStash instance |
| `BYTESTASH_API_KEY` | yes | -- | yes | ByteStash API key |

### Paperless-ngx

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `PAPERLESS_URL` | yes | -- | no | Base URL of Paperless instance |
| `PAPERLESS_API_TOKEN` | yes | -- | yes | Paperless API token |

### Radicale

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `RADICALE_URL` | yes | -- | no | Base URL of Radicale instance |
| `RADICALE_USERNAME` | yes | -- | yes | Login username |
| `RADICALE_PASSWORD` | yes | -- | yes | Login password |

## Research and development

### NotebookLM

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `NOTEBOOKLM_COOKIE` | yes | -- | yes | NotebookLM session cookie |
| `NOTEBOOKLM_AUTH_JSON` | yes | -- | yes | Authentication JSON blob |
| `NOTEBOOKLM_LOG_LEVEL` | no | `INFO` | no | Log verbosity |

## Monitoring

### Glances

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `GLANCES_URL` | yes | -- | no | Base URL of Glances API |
| `GLANCES_USERNAME` | no | -- | yes | Optional basic auth username |
| `GLANCES_PASSWORD` | no | -- | yes | Optional basic auth password |

## Development

### GitHub

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `GITHUB_TOKEN` | yes | -- | yes | GitHub personal access token |

## Shared runtime variables

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `ALLOW_DESTRUCTIVE` | no | `false` | no | Global destructive operations toggle |
| `ALLOW_YOLO` | no | `false` | no | Alias for ALLOW_DESTRUCTIVE |
| `DOCKER_NETWORK` | no | -- | no | External Docker network name |
| `LOG_LEVEL` | no | `info` | no | Global default log level |
