#!/usr/bin/env bash
# Target path relative to plugin root: scripts/lint-plugin.sh

set -euo pipefail

fail() {
  echo "lint-plugin: $1" >&2
  exit 1
}

[ -f .claude-plugin/plugin.json ] || fail "missing .claude-plugin/plugin.json"
[ -f .codex-plugin/plugin.json ] || fail "missing .codex-plugin/plugin.json"
[ -f .mcp.json ] || fail "missing .mcp.json"
[ -f .env.example ] || fail "missing .env.example"
[ -f tests/test_live.sh ] || fail "missing tests/test_live.sh"

grep -q "MY_SERVICE_MCP_TOKEN" .env.example || fail ".env.example must define MY_SERVICE_MCP_TOKEN"
grep -q "my_service_help" tests/test_live.sh || fail "tests/test_live.sh must cover my_service_help"
grep -q "confirm" tests/test_live.sh || fail "tests/test_live.sh must cover destructive confirmation"
grep -q "pagination" tests/test_live.sh || fail "tests/test_live.sh must validate pagination metadata"

if grep -Rq "MCP_BEARER_TOKEN" .; then
  fail "generic MCP_BEARER_TOKEN naming found; use MY_SERVICE_MCP_TOKEN"
fi

echo "lint-plugin: OK"
