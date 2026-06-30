#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/status.sh [--target PATH] [--agents claude,codex]

Shows the local agentic-dev-kit installation status for a target project.
EOF
}

if ! parse_common_args "$@"; then
  usage
  exit 0
fi

check_path() {
  label="$1"
  path="$2"
  if [ -e "$path" ]; then
    printf 'ok   %s: %s\n' "$label" "$path"
  else
    printf 'miss %s: %s\n' "$label" "$path"
  fi
}

check_exec() {
  label="$1"
  path="$2"
  if [ -x "$path" ]; then
    printf 'ok   %s: %s\n' "$label" "$path"
  else
    printf 'miss %s: %s\n' "$label" "$path"
  fi
}

info "Status for $TARGET"
check_path ".agent-tools" "$TARGET/.agent-tools"
check_exec "RTK" "$TARGET/.agent-tools/rtk/bin/rtk"
check_exec "Serena" "$TARGET/.agent-tools/serena-venv/bin/serena"
check_exec "Headroom" "$TARGET/.agent-tools/headroom-venv/bin/headroom"
check_exec "Context7 MCP" "$TARGET/node_modules/.bin/context7-mcp"
check_exec "ccusage" "$TARGET/node_modules/.bin/ccusage"
check_path "Codex config" "$TARGET/.codex/config.toml"
check_path "Codex skill" "$TARGET/.agents/skills/agentic-token-optimization/SKILL.md"
check_path "AGENTS.md" "$TARGET/AGENTS.md"
check_path "CLAUDE.md" "$TARGET/CLAUDE.md"

if has_agent claude && command_exists claude; then
  printf '\n'
  info "Claude Code visible MCP entries"
  warn "Claude may include user/global entries in this list; project-local entries should point at $TARGET."
  (cd "$TARGET" && claude mcp list) || true
fi
