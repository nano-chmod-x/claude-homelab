# Docker Ignore Templates

These files all target the same path relative to plugin root:
- `.dockerignore`

Choose the language-specific variant that matches the repo and copy it to the plugin root.

Each variant includes:
- the full shared baseline from the legacy plugin setup guide
- the relevant language section already uncommented
- runtime-focused exclusions so secrets, docs, tests, and tooling do not enter the image
