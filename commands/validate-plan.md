---
description: Validate a technical implementation plan against homelab standards
argument-hint: <plan-file-or-content>
allowed-tools: Read, Bash
---

Validate the provided technical implementation plan for compliance with homelab security, architectural, and documentation standards.

## Instructions

1. **Read the plan**: If a file path was provided, read its content. If raw text was provided, use that.
2. **Apply validation rules**:
   - Check for sensitive data (API keys, secrets) — MUST NOT be present.
   - Verify credential loading pattern — MUST use `scripts/load-env.sh` and `~/.claude-homelab/.env`.
   - Verify documentation — MUST include `README.md`, `SKILL.md`, and references.
   - Check for `confirm=True` gate on destructive actions.
   - Ensure standard directory structure (`scripts/`, `references/`, `examples/`).
3. **Report findings**: Provide a structured report with 'Compliance Check' table and 'Required Changes' list.
