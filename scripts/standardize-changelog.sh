#!/bin/bash
repo_path=$1
new_version=$2
changelog_path="$repo_path/CHANGELOG.md"

if [ ! -f "$changelog_path" ]; then
    echo "Creating new CHANGELOG.md for $repo_path"
    cat > "$changelog_path" <<EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [$new_version] - 2026-04-03

### Fixed
- **OAuth discovery 401 cascade**: BearerAuthMiddleware was blocking GET /.well-known/oauth-protected-resource, causing MCP clients to surface generic "unknown error". Added WellKnownMiddleware (RFC 9728) to return resource metadata.

### Added
- **docs/AUTHENTICATION.md**: New setup guide covering token generation and client config.
- **README Authentication section**: Added quick-start examples and link to full guide.
EOF
else
    echo "Updating existing CHANGELOG.md for $repo_path"
    # Create temp file with new header and version
    temp_file=$(mktemp)
    cat > "$temp_file" <<EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [$new_version] - 2026-04-03

### Fixed
- **OAuth discovery 401 cascade**: BearerAuthMiddleware was blocking GET /.well-known/oauth-protected-resource, causing MCP clients to surface generic "unknown error". Added WellKnownMiddleware (RFC 9728) to return resource metadata.

### Added
- **docs/AUTHENTICATION.md**: New setup guide covering token generation and client config.
- **README Authentication section**: Added quick-start examples and link to full guide.

EOF
    # Append existing history (skipping its own header if present)
    grep -vE "^(# Changelog|All notable changes|The format is based on|and this project adheres to)" "$changelog_path" | sed '/^## \[Unreleased\]/d' >> "$temp_file"
    mv "$temp_file" "$changelog_path"
fi
