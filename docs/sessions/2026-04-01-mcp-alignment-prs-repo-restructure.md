# Session: MCP Alignment PRs + Repo Restructure

**Date:** 2026-04-01
**Branch:** `chore/add-changelog-gitignore-omc` (claude-homelab), `chore/cw1-alignment` (all MCP repos)

---

## Session Overview

Two parallel workstreams:

1. **MCP alignment PRs**: Committed pending changes and opened PRs for all 8 MCP server repos on the `chore/cw1-alignment` branch. Fixed a real bug in synapse-mcp discovered by a pre-push test failure.
2. **claude-homelab restructure**: Committed a large repo reorganization — migrated `service-plugins/` → `skills/`, removed `templates/my-plugin/` (moved to standalone `plugin-templates` repo), removed legacy `scripts/homelab/`, initialized 4 new repos.

---

## Timeline

| Time | Activity |
|------|----------|
| Start | Remove `.beads/`, `.lavra/`, `logs/` from git tracking in unraid-mcp |
| Early | Check status of all 8 MCP repos; commit pending changes in synapse-mcp, arcane-mcp, gotify-mcp, unifi-mcp |
| Mid | Pre-push hook blocked synapse-mcp push — 1 failing test discovered |
| Mid | Fix synapse-mcp bug: `registerChannel` not filtering root SSH hosts before `startDockerEventWatcher` |
| Mid | Push all 8 repos, open PRs for all 8 |
| Late | Initialize 4 new repos: plugin-templates, plugin-lab-mcp-py, plugin-lab-mcp-ts, plugin-lab-mcp-rs |
| End | Stage and commit claude-homelab restructure (371 files, 906 ins / 27033 del) |

---

## Key Findings

- **synapse-mcp bug** (`src/channel/index.ts:55`): `registerChannel` called `startDockerEventWatcher` for ALL hosts without filtering root SSH hosts when `SYNAPSE_ALLOW_ROOT_LOGIN` is unset. Test `registerChannel skips docker watchers for root SSH hosts when root login is not allowed` caught this.
- **unraid-mcp** already had a PR open (#16) — `gh pr create` correctly reported the existing PR URL instead of creating a duplicate.
- **plugin-lab-mcp-rs/ts/py** directories were empty — initialized with empty root commits.
- **plugin-templates** had 127 files — pushed as full initial commit.
- **gotify-mcp** `tests/test_connection.py` was deleted (78 lines removed) — file had been staged for removal.

---

## Technical Decisions

1. **Fix in `registerChannel`, not `startDockerEventWatcher`**: The filtering logic belongs at the call site (where hosts are selected), not inside the watcher itself. Consistent with how the existing `SYNAPSE_ALLOW_ROOT_LOGIN` check works in `client-factory.ts:132`.
2. **Empty initial commit for empty repos**: plugin-lab-mcp-py/ts/rs had no content. Used `git commit --allow-empty` rather than creating placeholder files — keeps history clean.
3. **CHANGELOG updated inline**: No separate commit — changelog update included in the restructure commit per quick-push convention.

---

## Files Modified

### synapse-mcp
| File | Change |
|------|--------|
| `src/channel/index.ts` | Add root SSH host filter before `startDockerEventWatcher` call |
| `src/channel/index.test.ts` | Already contained the failing test (pre-existing) |
| `skills/synapse/SKILL.md` | Updated (pre-existing staged change) |
| `skills/synapsis/SKILL.md` | Updated (pre-existing staged change) |

### arcane-mcp
| File | Change |
|------|--------|
| `Dockerfile` | Updated |
| `tests/dockerfile.test.ts` | Created |

### gotify-mcp
| File | Change |
|------|--------|
| `tests/test_connection.py` | Deleted |

### unifi-mcp
| File | Change |
|------|--------|
| 43 files | Alignment changes including `docker-compose.yml→yaml`, `unifi.subdomain.conf`, CI workflow |

### unraid-mcp
| File | Change |
|------|--------|
| `.beads/` (13 files) | Removed from git index (kept locally) |
| `.lavra/` (3 files) | Removed from git index (kept locally) |
| `logs/.gitkeep` | Removed from git index |

### claude-homelab (371 files)
| Change | Description |
|--------|-------------|
| `service-plugins/` → `skills/` | All 22 service plugin directories renamed |
| `templates/my-plugin/` deleted | Moved to jmagar/plugin-templates repo |
| `scripts/homelab/` deleted | Legacy orchestration scripts removed |
| `prompts/` → `.codex/prompts/` | Renamed (4 files) |
| `skills/setup/` deleted | Merged into homelab-core plugin |
| `CHANGELOG.md` updated | Session changes documented |
| `CLAUDE.md`, `README.md` updated | Architecture references fixed |

---

## Commands Executed

```bash
# Remove from git index without deleting locally
git rm --cached -r .beads/ .lavra/ logs/

# Fix synapse-mcp test, verify
cd /home/jmagar/workspace/synapse-mcp && rtk vitest run src/channel/index.test.ts
# Result: PASS (4) FAIL (0)

# Commit and push all 8 repos
git add <files> && git commit -m "..." && rtk git push  # × 4 repos with changes

# Create PRs (parallel)
gh pr create --title "chore(cw1-alignment): MCP plugin alignment" ...  # × 8 repos

# Init new repos
git init && git commit --allow-empty -m "chore: initial commit" && git remote add origin ... && rtk git push -u origin main

# claude-homelab restructure
git add . && git commit -m "chore: restructure repo..."
rtk git push
```

---

## Behavior Changes (Before/After)

| Area | Before | After |
|------|--------|-------|
| synapse-mcp docker watchers | Root SSH hosts received docker watchers regardless of `SYNAPSE_ALLOW_ROOT_LOGIN` | Root SSH hosts skipped when `SYNAPSE_ALLOW_ROOT_LOGIN` unset |
| unraid-mcp git tracking | `.beads/`, `.lavra/`, `logs/` tracked in git | Gitignored, removed from index, local files preserved |
| claude-homelab layout | `service-plugins/` + `skills/` + `templates/` | Flat `skills/` only; templates in standalone repo |
| plugin-templates repo | Did not exist as standalone repo | Initialized at jmagar/plugin-templates with 127 files |

---

## Verification Evidence

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `rtk vitest run src/channel/index.test.ts` (synapse-mcp) | PASS (4) FAIL (0) | PASS (4) FAIL (0) | ✅ |
| `rtk git push` (synapse-mcp) | `ok chore/cw1-alignment` | `ok chore/cw1-alignment` | ✅ |
| `gh pr create` (8 repos) | PR URLs returned | 7 new PRs + 1 existing (#16 unraid-mcp) | ✅ |
| `rtk git push` (plugin-templates) | `ok main` | `ok main` | ✅ |
| `rtk git push` (claude-homelab) | `ok chore/add-changelog-gitignore-omc` | `ok chore/add-changelog-gitignore-omc` | ✅ |

---

## PRs Opened

| Repo | PR |
|------|----|
| synapse-mcp | https://github.com/jmagar/synapse-mcp/pull/62 |
| swag-mcp | https://github.com/jmagar/swag-mcp/pull/11 |
| overseerr-mcp | https://github.com/jmagar/overseerr-mcp/pull/1 |
| arcane-mcp | https://github.com/jmagar/arcane-mcp/pull/2 |
| gotify-mcp | https://github.com/jmagar/gotify-mcp/pull/3 |
| unifi-mcp | https://github.com/jmagar/unifi-mcp/pull/3 |
| syslog-mcp | https://github.com/jmagar/syslog-mcp/pull/2 |
| unraid-mcp | https://github.com/jmagar/unraid-mcp/pull/16 (existing) |

---

## Source IDs + Collections Touched

N/A — no Axon embed/retrieve operations prior to this save.

---

## Risks and Rollback

- **synapse-mcp fix**: Low risk — adds a filter guard that was clearly missing. Rollback: `git revert 378ee63` in synapse-mcp.
- **claude-homelab restructure**: Large rename (371 files). Anything symlinking to `service-plugins/` will break. Rollback: `git revert 475538e` — git will restore all renames.
- **plugin-templates push**: 127 files pushed to public repo. Contents are template files only — no credentials. No rollback needed.

---

## Decisions Not Taken

1. **Running full synapse-mcp test suite before pushing** — ran only the failing test file after the fix. The pre-push hook runs the full suite anyway, so this was sufficient.
2. **Creating PRs for plugin-lab-mcp-* repos** — empty repos have nothing to PR. Will be populated in future sessions.
3. **Deleting wrong-directory axon files** — user previously said to ignore axon entirely; not touched.

---

## Open Questions

1. **plugin-lab-mcp-py/ts/rs content** — should these be populated from `plugin-templates/py`, `plugin-templates/ts`, `plugin-templates/rs` subdirectories? Currently empty.
2. **arcane-mcp uncommitted change warning** on `gh pr create` — one file was untracked at PR creation time. Was it intentional?
3. **claude-homelab CLAUDE.md** still references `service-plugins/` in some places — needs a follow-up pass.

---

## Next Steps

1. Merge the 8 cw1-alignment PRs (after review)
2. Populate plugin-lab-mcp-py/ts/rs from plugin-templates subdirs if intended
3. Verify claude-homelab symlinks (`~/.claude/skills/`) still resolve after `service-plugins/` → `skills/` rename
4. Continue cw1 P0 fixes per open beads backlog
