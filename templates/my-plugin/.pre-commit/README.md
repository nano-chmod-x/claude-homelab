# Hook Runner Templates

These files define the hook runner configuration to copy into the plugin repo.

Target paths relative to plugin root:
- Python: `.pre-commit-config.yaml`
- Rust: `lefthook.yml`
- TypeScript: `lefthook.yml`

Recommended defaults:
- Python uses `pre-commit` because the ecosystem support is still the least-friction choice.
- Rust uses `lefthook`.
- TypeScript uses `lefthook` and delegates actual formatting/linting to package scripts.
