# Coding Rules -- claude-homelab

Standards and conventions enforced across the homelab mono-repo and its external plugins.

## Git workflow

### Conventional commits

All commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

| Prefix | Purpose | Example |
| --- | --- | --- |
| `feat:` | New feature | `feat(radicale): add CalDAV/CardDAV skill` |
| `fix:` | Bug fix | `fix(plex): correct authentication headers` |
| `chore:` | Maintenance | `chore: update dependencies` |
| `refactor:` | Code restructure | `refactor(lib): improve load-env error handling` |
| `test:` | Tests | `test: add integration tests for search` |
| `docs:` | Documentation | `docs(readme): update skill catalog` |
| `ci:` | CI/CD changes | `ci: add Docker build workflow` |

### Branch strategy

- `main` is production-ready at all times
- Feature branches for development: `feat/tool-name`, `fix/issue-description`
- PR required before merge to `main`

### Never commit

- `.env` files or any file containing credentials
- API keys, tokens, or passwords
- Large binary files
- Temporary or debug files
- `__pycache__/`, `node_modules/`, `target/`

## Version bumping

### Bump type rules

Every feature branch push MUST bump the version in ALL version-bearing files.

| Commit prefix | Bump | Example |
| --- | --- | --- |
| `feat!:` or `BREAKING CHANGE` | Major | `1.2.3` -> `2.0.0` |
| `feat:` or `feat(...):` | Minor | `1.2.3` -> `1.3.0` |
| Everything else (`fix`, `chore`, `refactor`, `test`, `docs`) | Patch | `1.2.3` -> `1.2.4` |

### Version-bearing files

All of these files must have the same version. Never bump only one:

| File | Field |
| --- | --- |
| `.claude-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `.codex-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `gemini-extension.json` | `"version": "X.Y.Z"` |
| `README.md` | `Version: X.Y.Z` |
| `CLAUDE.md` | `**Version:** X.Y.Z` |
| `CHANGELOG.md` | New entry under `## X.Y.Z` |

Use `just version-check` to detect drift and `just version-sync <version>` to fix it.

### CHANGELOG format

```markdown
## 1.4.0

- feat: add docs/repo/ documentation set
- fix: correct symlink verification logic

## 1.3.0

- Initial release with full skill catalog
```

## Code standards

### Bash

```bash
#!/bin/bash
set -euo pipefail          # Strict mode (always)
"$variable"                # Always quote variables
function_name() { ... }   # Use functions for reusable code
chmod +x script.sh         # Executable permissions
```

- Use `scripts/load-env.sh` for all credential loading
- Return JSON where appropriate
- Support `--help` flag
- Include shebangs

### Python

- Type hints on all function signatures
- Google-style docstrings
- f-strings for formatting
- `async`/`await` for I/O operations
- PEP 8 via `ruff format`

```python
async def search_media(query: str, limit: int = 10) -> list[dict]:
    """Search upstream service for media.

    Args:
        query: Search term.
        limit: Maximum results to return.

    Returns:
        List of matching media items.
    """
```

### TypeScript

- ESM modules (`import` syntax, not `require`)
- No `any` types -- use explicit types or `unknown`
- Strict mode enabled in `tsconfig.json`
- `async`/`await` for I/O

### Rust

- Standard clippy lints (`#![warn(clippy::all)]`)
- Proper error handling with `thiserror` or `anyhow`
- `async`/`await` with `tokio`
- `serde` for serialization

## Security rules

- Credentials in `.env` only, never in code or docs
- `.env` has `chmod 600` permissions
- Docker images run as non-root
- No baked environment variables in Docker images
- Health endpoint (`/health`) is unauthenticated; all other endpoints require bearer auth
- Never log credentials, even in debug mode
- See `docs/references/security-patterns.md` for input sanitization, command injection prevention, URL encoding, SQL injection prevention, API key protection, and path traversal prevention

## Documentation requirements

### Every skill requires

| File | Audience | Purpose |
| --- | --- | --- |
| `SKILL.md` | Claude Code | Skill definition with commands and workflows |
| `README.md` | Humans | Overview, install, configuration, examples |
| Reference docs | Both | API endpoints, troubleshooting, quick reference |

### Every plugin requires

| File | Audience | Purpose |
| --- | --- | --- |
| `CLAUDE.md` | Claude Code | Project instructions for AI sessions |
| `README.md` | Humans | Overview, install, configuration |
| `CHANGELOG.md` | Both | Version history |

## Skill vs plugin boundary

- A directory under `skills/` does not automatically become a standalone plugin
- Skill-only integrations remain bundled with `homelab-core`
- A service becomes a standalone plugin only when it gains agents, commands, hooks, MCP servers, or companion skills
- At that point, it moves to its own repository and gets added to `marketplace.json` as an external repo-sourced plugin
