# Skill Migration Checklist

For existing skills that need updating to match current patterns:

- [ ] SKILL.md has complete YAML frontmatter (name, description)
- [ ] SKILL.md includes 5-10 trigger phrases in description
- [ ] SKILL.md has all required sections (Purpose, Setup, Commands, Workflow, Notes, Reference)
- [ ] README.md exists with user-facing documentation
- [ ] Scripts have proper shebangs and file headers
- [ ] Scripts are executable (`chmod +x`)
- [ ] Scripts support `--help` flag
- [ ] Scripts return JSON output where appropriate
- [ ] **Migrated credentials from JSON config files to `.env`** (SERVICE_URL, SERVICE_API_KEY variables)
- [ ] Removed `~/claude-homelab/credentials/<service>/` directory
- [ ] Scripts load credentials from `~/.claude-homelab/load-env.sh` (not direct `source .env`)
- [ ] References directory exists with appropriate reference file (api-endpoints.md for REST APIs, command-reference.md for CLI tools), quick-reference.md, troubleshooting.md
- [ ] Destructive operations require explicit confirmation
- [ ] Workflow section includes decision trees
- [ ] All commands have copy-paste examples
- [ ] External links included in search results (TMDB, TVDB, etc.)
- [ ] Updated `skills/references/skill-catalog.md` with skill entry
