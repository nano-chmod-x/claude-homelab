---
description: Deploy services via docker compose (auto-detects compose variant)
argument-hint: [path/to/docker-compose.yml]
allowed-tools: Bash
---

Deploy using docker compose. Arguments (if provided): $ARGUMENTS

## Instructions

1. **Determine working directory**
   - If arguments include a path to a `docker-compose.yml` or `compose.yml`, use its parent directory
   - Otherwise use the current directory

2. **Detect docker compose variant** (in this order):
   - `docker compose version` — Docker Compose v2 plugin (preferred)
   - `docker-compose version` — Docker Compose v1 standalone
   - If neither found, report error and stop

3. **Confirm a compose file exists** in the target directory:
   - `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, or `compose.yaml`
   - If none found, report error listing what was checked

4. **Run the deploy**:
   ```bash
   # v2
   docker compose up --build -d

   # v1 fallback
   docker-compose up --build -d
   ```
   If a specific file path was provided via arguments, pass `-f <path>` to the command.

5. **Report result**:
   - On success: list running containers with `docker compose ps` (or `docker-compose ps`)
   - On failure: show the last 30 lines of output and suggest common fixes (missing env vars, port conflicts, image pull errors)
