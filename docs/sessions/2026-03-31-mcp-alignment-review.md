# Session: MCP Server Alignment Review & Issue Tracking

**Date:** 2026-03-31
**Branch:** `chore/cw1-alignment`
**Repos touched:** synapse-mcp, swag-mcp, overseerr-mcp, arcane-mcp, gotify-mcp, unifi-mcp, syslog-mcp, unraid-mcp

---

## Session Overview

This session continued the `chore/cw1-alignment` epic — aligning all MCP server repos with the canonical plugin setup guide at `docs/plugin-setup-guide.md`. The session consisted of two phases:

1. **Completion phase**: Closing out remaining alignment work from previous sessions (syslog-mcp, arcane-mcp, gotify-mcp background agents) and acknowledging that axon_rust was dropped from scope.
2. **Review phase**: Dispatching 8 parallel review agents (one per repo) to audit what was actually implemented vs what the closed beads claimed. Findings revealed ~63 issues across all 8 repos, which were then filed as new beads.

---

## Timeline

| Time | Activity |
|------|----------|
| Session start | Resumed from compaction; identified pending work: axon_rust (wrong dir), syslog close, arcane agent running, gotify agent running |
| Early | User said to ignore axon entirely; closed syslog beads b98 + cw1.7 |
| Early | Arcane agent (aafa6ed85ca012ea7) confirmed complete — cw1.6 + z25 closed |
| Early | Gotify agent (ace5a96ee37c99f82) confirmed complete — 11 issues closed |
| Mid | User requested review agents for all repos to verify alignment quality |
| Mid | Checked git diffs + closed beads for all 8 repos before dispatching reviews |
| Mid | 8 review agents dispatched in parallel; each read plugin-setup-guide.md and audited their repo |
| Late | Review results collected — ~63 issues found across 8 repos |
| Late | 8 parallel agents created all beads (~63 total) |

---

## Key Findings

### Cross-Cutting Issues (affect multiple repos)

1. **`sensitive: true` on MCP tokens** — breaks `${user_config.*}` substitution in `.mcp.json` — affects swag-mcp, overseerr-mcp, unraid-mcp. `sensitive: false` is required for `.mcp.json` Authorization header substitution to work.

2. **`ensure-ignore-files.sh` only handles `.gitignore`** — affects synapse-mcp, swag-mcp, overseerr-mcp, unifi-mcp, syslog-mcp. Spec requires both `.gitignore` (27 patterns) and `.dockerignore` (28 patterns) with `--check` mode.

3. **Missing `AGENTS.md`/`GEMINI.md` symlinks** — affects synapse-mcp, arcane-mcp, gotify-mcp, unraid-mcp. Both must be `ln -sf CLAUDE.md` symlinks committed to git.

4. **Missing `assets/` directories** — affects synapse-mcp, arcane-mcp, unraid-mcp.

5. **Unprefixed env var names in server code** — affects unifi-mcp (`NO_AUTH`, `ALLOW_DESTRUCTIVE`, `ALLOW_YOLO` instead of `UNIFI_MCP_*`), syslog-mcp (`.env.example` uses unprefixed names), gotify-mcp (server reads unprefixed `ALLOW_DESTRUCTIVE`).

6. **`validate-skills` Justfile recipe is a stub** — affects synapse-mcp, swag-mcp, overseerr-mcp. Recipe does `echo ok` or file-existence check instead of `npx skills-ref validate skills/`.

7. **`fix-env-perms.sh` uses bypassable stdin-parse heuristic** — affects swag-mcp, overseerr-mcp. Spec requires unconditional `chmod 600` with `cat > /dev/null` stdin drain.

### Repo-Specific Critical Findings

**overseerr-mcp** (worst): No `BearerAuthMiddleware` at all — unauthenticated requests accepted. Tool design never migrated from 6 individual tools to 2-tool action+subaction pattern. `scripts/` directory entirely missing. Double URL encoding bug in `client.py`. Dockerfile has baked `ENV` directives.

**unifi-mcp**: Bearer auth uses `!=` string comparison (timing oracle vulnerability). Server reads wrong env var names — `UNIFI_MCP_NO_AUTH`, `UNIFI_MCP_ALLOW_DESTRUCTIVE`, `UNIFI_MCP_HOST` set in `.env.example` but server reads `NO_AUTH`, `ALLOW_DESTRUCTIVE`, `UNIFI_LOCAL_MCP_HOST` — config knobs silently do nothing.

**syslog-mcp**: `plugin.json` has no `userConfig` block — credential flow entirely broken. `.mcp.json` has hardcoded URL and no `Authorization` header.

**gotify-mcp**: 4 files marked done in closed beads that don't exist: `tests/test_live.sh`, `skills/gotify/SKILL.md`, `.github/workflows/ci.yml`, `hooks/scripts/ensure-ignore-files.sh`.

**synapse-mcp**: `sync-env.sh` MANAGED array writes `MCP_BEARER_TOKEN`/`NO_HTTP_AUTH`/`SYNAPSE_HTTP_PORT`/`SYNAPSE_HTTP_HOST` but server reads `SYNAPSE_MCP_TOKEN`/`SYNAPSE_MCP_NO_AUTH`/`SYNAPSE_MCP_PORT`/`SYNAPSE_MCP_HOST` — auth breaks on fresh install.

**arcane-mcp**: `normalizeServiceUrl` uses `/localhost/g` (misses `127.0.0.1`). SKILL.md action names don't match actual schema (`stack` vs `project`, `container:remove` vs `container:delete`).

---

## Technical Decisions

1. **Dropped axon from scope** — User explicitly said to ignore axon (`~/workspace/axon_rust`). Previously created files in wrong directory (`~/workspace/axon/`) were abandoned without cleanup.

2. **Review-then-file approach** — Rather than dispatching fix agents immediately, first reviewed all repos and created beads for all findings. This gives a clean issue backlog before any remediation.

3. **1 review agent per repo** — Each agent had full plugin-setup-guide.md context + specific closed bead list + git diff context, allowing targeted verification rather than generic review.

4. **`sensitive: false` for MCP bearer tokens** — This is a documented spec trade-off: tokens used in `.mcp.json` `${user_config.*}` substitution must be `sensitive: false`. This enables the Authorization header to be populated at install time.

---

## Files Modified

None in this session — this was a review and issue-creation session only.

### Files That Should Have Been Created (per closed beads, found missing)

| File | Repo | Bead |
|------|------|------|
| `tests/test_live.sh` | gotify-mcp | 7o0 |
| `skills/gotify/SKILL.md` | gotify-mcp | a54 |
| `.github/workflows/ci.yml` | gotify-mcp | gm7 |
| `hooks/scripts/ensure-ignore-files.sh` | gotify-mcp | w5p |
| `scripts/` (5 scripts) | overseerr-mcp | l1g |
| `tests/test_live.sh` | overseerr-mcp | bgv |

---

## Commands Executed

```bash
# Check repo git status
cd /home/jmagar/workspace/<repo> && rtk git log --oneline origin/main..chore/cw1-alignment

# Close syslog beads
bd close b98 cw1.7 --force

# Close arcane beads (agent work confirmed complete)
bd close cw1.6 z25 --force

# List open issues
bd list --status=open

# List closed issues (used to understand what was supposed to be done)
bd list --status=closed
```

---

## Behavior Changes (Before/After)

No code changes were made this session. This session was entirely review + issue filing.

---

## Verification Evidence

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `gotify-mcp: ls tests/` | test_live.sh present | No files | FAIL — bead 7o0 falsely closed |
| `gotify-mcp: ls skills/` | SKILL.md present | No files | FAIL — bead a54 falsely closed |
| `unifi-mcp: grep hmac server.py` | compare_digest | `if token != expected_token` | FAIL — timing oracle |
| `syslog-mcp: cat plugin.json \| jq .userConfig` | userConfig object | null | FAIL — credential flow broken |
| `overseerr-mcp: grep BearerAuth server.py` | BearerAuthMiddleware | (no match) | FAIL — no auth enforcement |
| `synapse-mcp: grep MCP_BEARER_TOKEN hooks/scripts/sync-env.sh` | SYNAPSE_MCP_TOKEN | MCP_BEARER_TOKEN | FAIL — wrong var name |
| `swag-mcp: grep sensitive .claude-plugin/plugin.json` | sensitive: false | sensitive: true | FAIL — .mcp.json substitution broken |

---

## Source IDs + Collections Touched

N/A — no Axon embeds or vector DB operations performed during this session.

---

## Risks and Rollback

- **No code was changed** this session — no rollback needed.
- All changes from previous sessions are on `chore/cw1-alignment` branch in each repo; rollback via `git checkout main` in any repo.
- The 63 new beads are in the beads tracker and can be closed/discarded if the issues are determined to be non-applicable.

---

## Decisions Not Taken

1. **Dispatching fix agents immediately** — Decided to review and file issues first rather than kick off 8 fix agents. Rationale: avoid re-doing work without a clear picture of what needs fixing; gives user visibility into all gaps before remediation.

2. **Including axon in review scope** — User explicitly excluded axon. The `chore/cw1-alignment` branch in `axon_rust` was never touched; existing wrong-directory files in `~/workspace/axon/` were not cleaned up.

3. **Grouping issues by type across repos** — Filed issues repo-by-repo rather than cross-cutting. Rationale: easier to dispatch per-repo fix agents later; beads scoped to one repo are cleaner to track and close.

---

## Open Questions

1. **`sensitive: false` vs `true` for MCP tokens** — The spec says `sensitive: false` is required for `.mcp.json` substitution, but tokens are credentials. Should repos use a separate `userConfig` field for the token vs the `.mcp.json` auth header? The spec's documented trade-off needs a definitive ruling.

2. **overseerr-mcp tool refactor scope** — Migrating from 6 individual tools to 2-tool action+subaction pattern is a significant refactor. This is currently in the open beads (reg, elb) — is this in scope for `chore/cw1-alignment` or a separate epic?

3. **Wrong-directory axon files** — `~/workspace/axon/skills/axon/SKILL.md` and `~/workspace/axon/tests/test_live.sh` were created in the wrong directory in a previous session. Should these be deleted?

4. **SWAG conf location** — Multiple repos have `.subdomain.conf` in `docs/` rather than repo root. Spec is clear (repo root), but the move should be verified against any references in `docker-compose.yaml` volume mounts.

---

## New Beads Created This Session

### synapse-mcp (6 beads)
| ID | Priority | Issue |
|----|----------|-------|
| iti | P0 | sync-env.sh writes wrong env var names |
| oya | P1 | plugin.json /mcp suffix, version mismatch, missing title fields |
| 1z5 | P2 | Missing AGENTS.md, GEMINI.md, .codex-plugin/, entrypoint.sh, assets/ |
| 00h | P2 | prettier in devDeps; validate-skills stub |
| mh0 | P2 | ensure-ignore-files.sh only handles .gitignore |
| 5ad | P3 | truncateIfNeeded uses char count not byte-based 512KB |

### swag-mcp (9 beads)
| ID | Priority | Issue |
|----|----------|-------|
| w8v | P0 | swag_mcp_token sensitive:true breaks .mcp.json |
| yf3 | P1 | sync-env.sh missing token fail-fast; bad flock |
| 19t | P1 | fix-env-perms.sh stdin-parse heuristic |
| a3h | P1 | ensure-gitignore.sh wrong name/scope |
| isj | P1 | version-sync CI never fails; contract-drift || true |
| 0yp | P2 | .app.json missing apps array; GEMINI.md absent |
| 8jn | P2 | test_live.sh no tool calls |
| f6h | P2 | validate-skills is file existence check |
| r03 | P3 | pyproject.toml missing [tool.ty] cache-dir |

### overseerr-mcp (13 beads)
| ID | Priority | Issue |
|----|----------|-------|
| reg | P0 | No BearerAuthMiddleware |
| elb | P0 | Tool design not migrated (6 tools) |
| 0n7 | P0 | overseerr_mcp_token sensitive:true |
| b80 | P0 | scripts/ directory missing |
| wwc | P1 | tests/test_live.sh missing |
| 7tr | P1 | Dockerfile single-stage, baked ENV |
| qp2 | P1 | SWAG conf wrong port/location |
| 7gs | P1 | client.py double URL encoding |
| x3f | P2 | pyproject.toml wrong build backend/config |
| yeq | P2 | .pre-commit missing ruff/ty hooks |
| gef | P2 | AGENTS.md stub; GEMINI.md, .codex-plugin/ absent |
| b7l | P2 | CI missing audit; version-sync broken; ensure-ignore-files incomplete |
| 0ao | P2 | Justfile test wrong path; port inconsistency |

### arcane-mcp (8 beads)
| ID | Priority | Issue |
|----|----------|-------|
| luh | P1 | entrypoint.sh missing |
| 2al | P1 | AGENTS.md, GEMINI.md, assets/ absent |
| 6ot | P1 | normalizeServiceUrl wrong regex |
| 22l | P2 | truncateResponse char not byte |
| 7dn | P2 | arcane_help missing action param |
| wrq | P2 | SKILL.md action names don't match schema |
| 6h8 | P2 | Missing contract-drift CI; validate-skills recipe absent |
| dt8 | P3 | sync-env missing arcane_mcp_url; .dockerignore no-op |

### gotify-mcp (9 beads)
| ID | Priority | Issue |
|----|----------|-------|
| 8jh | P0 | tests/test_live.sh missing |
| 621 | P0 | skills/gotify/SKILL.md missing |
| 0ak | P0 | .github/workflows/ci.yml missing |
| 3kk | P0 | hooks/scripts/ensure-ignore-files.sh missing |
| f9e | P1 | gotify_mcp_token sensitive value |
| rb5 | P1 | AGENTS.md, GEMINI.md missing |
| 03m | P1 | docker-compose.yml → .yaml extension |
| 4qt | P1 | ALLOW_DESTRUCTIVE/ALLOW_YOLO unprefixed in server |
| c1j | P2 | gotify_help missing action param |

### unifi-mcp (8 beads)
| ID | Priority | Issue |
|----|----------|-------|
| m2t | P0 | timing oracle in bearer auth |
| 18z | P0 | wrong env var names in server |
| bw9 | P1 | port mismatch 8001 vs 3003 |
| 0v1 | P1 | UID mismatch 1001 vs 1000 |
| ddy | P1 | mypy not ty; no tool cache dirs; missing pre-commit hooks |
| 1yb | P2 | SKILL.md not third-person; token sensitive value |
| 9no | P2 | ensure-ignore-files.sh missing .dockerignore |
| qwv | P2 | UNIFI_URL vs UNIFI_CONTROLLER_URL inconsistency |

### syslog-mcp (11 beads)
| ID | Priority | Issue |
|----|----------|-------|
| lyo | P0 | plugin.json missing userConfig |
| qfu | P0 | .mcp.json hardcoded URL, no auth header |
| pt8 | P1 | Dockerfile HEALTHCHECK curl not wget |
| 6g1 | P1 | .env.example unprefixed env vars |
| e6l | P1 | hooks.json wrong nesting, missing ensure-ignore-files.sh |
| so3 | P1 | scripts/ directory missing |
| kbw | P1 | syslog.subdomain.conf in docs/ not root |
| 02b | P2 | sync-env.sh /tmp lock, no token fail-fast |
| lvc | P2 | fix-env-perms.sh missing stdin drain |
| rxs | P2 | .pre-commit missing cargo-fmt, cargo-clippy |
| 6r0 | P2 | ensure-ignore-files.sh .gitignore only; port inconsistency |

### unraid-mcp (8 beads)
| ID | Priority | Issue |
|----|----------|-------|
| hvj | P0 | unraid_mcp_token sensitive:true breaks .mcp.json |
| vir | P1 | fix-env-perms.sh missing |
| 9f0 | P1 | AGENTS.md, GEMINI.md missing |
| b1i | P2 | assets/ missing |
| qoa | P2 | SWAG conf in docs/ not root |
| 2yk | P2 | sync-env.sh lock in /tmp/ |
| r9b | P2 | BEARER_TOKEN naming linter violation |
| h4n | P2 | .codex-plugin/ missing displayName, wrong port |

---

## Next Steps

1. **Fix P0s first** — Most critical: overseerr-mcp auth (reg), syslog-mcp credential flow (lyo, qfu), unifi-mcp timing oracle (m2t) + env var names (18z), gotify-mcp missing files (8jh, 621, 0ak, 3kk), synapse-mcp sync-env names (iti), swag/unraid token sensitive flag (w8v, hvj).

2. **Batch similar fixes across repos** — `sensitive: false` token fix, `AGENTS.md`/`GEMINI.md` symlinks, `assets/` creation, `ensure-ignore-files.sh` upgrade, `SWAG conf` relocation are all mechanical and can be dispatched in parallel.

3. **Overseerr tool refactor** — Requires architectural decision (scope question above) before dispatching.

4. **Server refactors** (deferred from this epic) — cfr (swag), 8m3 (unraid), ihk (overseerr), wm2 (syslog), cw1.18 (axon_rust).
