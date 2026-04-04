# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

To report a security vulnerability, please open an issue with the `[security]` label on the
[GitHub repository](https://github.com/jmagar/claude-homelab/issues).

**Please do not report security vulnerabilities through public GitHub issues for sensitive matters.**
For sensitive vulnerabilities (credentials exposure, auth bypass, etc.), email the repository owner
directly via the GitHub profile contact before opening a public issue.

## Security Practices

- API keys and credentials are stored in `~/.claude-homelab/.env` (never committed)
- Scripts use `chmod 600` for credential files
- All credential loading goes through `scripts/load-env.sh`
- No hardcoded secrets in any scripts or documentation

## Scope

This repository provides Claude Code skill definitions and shell scripts for homelab service
management. Security issues include but are not limited to:

- Hardcoded credentials or secrets in scripts
- Command injection vulnerabilities in shell scripts
- Insecure credential handling or storage patterns
- Sensitive data exposure in logs or output
