#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/uninstall.sh [--target PATH] [--agents claude,codex] [--no-tools] [--no-agent-config]

Removes files, marked config blocks, local tools, and project-local agent entries
created by agentic-dev-kit. It does not remove unrelated user/global config.
EOF
}

if ! parse_common_args "$@"; then
  usage
  exit 0
fi

info "Uninstalling local agentic dev kit from $TARGET"

if [ "$CONFIGURE_AGENTS" = "1" ] && has_agent claude && command_exists claude; then
  info "Removing Claude Code local-scope MCP entries"
  (
    cd "$TARGET"
    claude mcp remove serena --scope local >/dev/null 2>&1 || true
    claude mcp remove context7 --scope local >/dev/null 2>&1 || true
  )
fi

remove_marked_block "$TARGET/AGENTS.md" "agent-guidance" "<!--"
remove_marked_block "$TARGET/CLAUDE.md" "agent-guidance" "<!--"
remove_marked_block "$TARGET/.codex/config.toml" "mcp" "#"
remove_if_empty "$TARGET/AGENTS.md"
remove_if_empty "$TARGET/CLAUDE.md"
remove_if_empty "$TARGET/.codex/config.toml"

remove_exact_line "$TARGET/.gitignore" ".agent-tools/"
remove_exact_line "$TARGET/.gitignore" ".claude/settings.local.json"
remove_exact_line "$TARGET/.gitignore" ".codex/log/"
remove_if_empty "$TARGET/.gitignore"

rm -rf "$TARGET/.agents/skills/agentic-token-optimization"

if [ "$INSTALL_TOOLS" = "1" ]; then
  info "Removing local tool directories"
  rm -rf "$TARGET/.agent-tools"

  if [ -f "$TARGET/package.json" ] && command_exists npm; then
    info "Removing local npm dev dependencies"
    (
      cd "$TARGET"
      npm uninstall @upstash/context7-mcp ccusage --save-dev >/dev/null 2>&1 || true
    )
  fi
else
  info "Keeping local tools because --no-tools was provided"
fi

info "Uninstall complete."
