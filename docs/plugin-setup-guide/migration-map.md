# Plugin Setup Guide Migration Map

This map preserves a one-to-one checklist against `docs/plugin-setup-guide.md` without modifying the original file.

## Keep Together In The New Entry Docs

Move these sections into the new overview docs:
- `Architecture Overview`
- `Deployment Modes — Local & Docker`
- `Directory Layout`
- `Adding a New Plugin (Checklist)`
- `Credential Flow Diagram`

## Move Into Implementation Standards

Move these sections into standards-oriented docs or template guidance:
- `` `.cache/` Convention ``
- `Language Toolchain Standards`
- `HTTP Security — Bearer Tokens`
- `Tool Design — Action + Subaction Pattern`
- `Code Architecture`
- `Destructive Operations — Confirmation Gate`
- `Middleware & Server Hardening`
- `Validation Checklist`

## Move Into File Templates / File Reference

Map these sections to `templates/my-plugin/`:
- `File-by-File Reference`
- `Mode Detection`
- `MCP Mode — Tool Reference`
- `HTTP Fallback Mode`
- `Instructions`
- `Codex CLI Compatibility`

Primary target files:
- `templates/my-plugin/.claude-plugin/plugin.json`
- `templates/my-plugin/.claude-plugin/marketplace.json`
- `templates/my-plugin/.agents/plugins/marketplace.json`
- `templates/my-plugin/.codex-plugin/plugin.json`
- `templates/my-plugin/.app.json`
- `templates/my-plugin/.mcp.json`
- `templates/my-plugin/.env.example`
- `templates/my-plugin/docker-compose.yaml`
- `templates/my-plugin/my-service.subdomain.conf`
- `templates/my-plugin/README.md`
- `templates/my-plugin/CHANGELOG.md`
- `templates/my-plugin/tests/test_live.sh`

Language-variant target files:
- `templates/my-plugin/Dockerfile/<language>/Dockerfile`
- `templates/my-plugin/entrypoint.sh/<language>/entrypoint.sh`
- `templates/my-plugin/Justfile/<language>/Justfile`
- `templates/my-plugin/.github/workflows/ci.yaml/<language>/ci.yaml`
- `templates/my-plugin/.gitignore/<language>/.gitignore`
- `templates/my-plugin/.dockerignore/<language>/.dockerignore`
- `templates/my-plugin/.pre-commit/<language>/...`

## Move Into Testing / Release Docs

Move these sections into verification and publishing docs:
- `CI/CD Pipeline`
- `Marketplace Registration`
- `Testing with mcporter`
- `Development Tools Reference`

## Move Into Example / Reference Snippets

These are too long for primary guide docs and should stay as templates or example snippets:
- `SWAG Reverse Proxy Config`
- embedded `SKILL.md` examples
- embedded `agents/` examples
- embedded `commands/` examples

## Completeness Checklist

Before considering the migration complete:
- Every `##` heading from `docs/plugin-setup-guide.md` has a mapped destination.
- Every file explicitly requested for `templates/my-plugin/` exists.
- Language-variant templates clearly state the final target path relative to plugin root.
- The original guide remains unchanged for comparison.
