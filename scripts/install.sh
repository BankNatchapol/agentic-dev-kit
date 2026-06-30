#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KIT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--target PATH] [--agents claude,codex] [--no-tools] [--no-agent-config]

Installs agentic-dev-kit locally into the target project.

Default behavior is local-only:
- no brew install
- no npm install -g
- no uv tool install
- no rtk init -g
- no global Headroom wrapping
EOF
}

if ! parse_common_args "$@"; then
  usage
  exit 0
fi

TOOLS_DIR="$TARGET/.agent-tools"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

info "Installing local agentic dev kit into $TARGET"
ensure_dir "$TOOLS_DIR"
ensure_dir "$TMP_DIR"
ensure_dir "$TARGET/.claude"
ensure_dir "$TARGET/.codex"
ensure_dir "$TARGET/.agents/skills"

ensure_gitignore_line "$TARGET" ".agent-tools/"
ensure_gitignore_line "$TARGET" ".claude/settings.local.json"
ensure_gitignore_line "$TARGET" ".codex/log/"

AGENTS_TMP="$TMP_DIR/AGENTS.block.md"
CLAUDE_TMP="$TMP_DIR/CLAUDE.block.md"
CODEX_TMP="$TMP_DIR/codex-config.block.toml"

render_template "$KIT_ROOT/templates/AGENTS.block.md" "$AGENTS_TMP" "$TARGET"
render_template "$KIT_ROOT/templates/CLAUDE.block.md" "$CLAUDE_TMP" "$TARGET"
render_template "$KIT_ROOT/templates/codex-config.block.toml" "$CODEX_TMP" "$TARGET"

append_marked_file "$TARGET/AGENTS.md" "agent-guidance" "<!--" "$AGENTS_TMP"
append_marked_file "$TARGET/CLAUDE.md" "agent-guidance" "<!--" "$CLAUDE_TMP"

rm -rf "$TARGET/.agents/skills/agentic-token-optimization"
mkdir -p "$TARGET/.agents/skills/agentic-token-optimization"
render_template \
  "$KIT_ROOT/templates/agentic-token-optimization/SKILL.md" \
  "$TARGET/.agents/skills/agentic-token-optimization/SKILL.md" \
  "$TARGET"

append_marked_file "$TARGET/.codex/config.toml" "mcp" "#" "$CODEX_TMP"

if [ "$INSTALL_TOOLS" = "1" ]; then
  info "Installing local npm dev dependencies"
  if ! command_exists npm; then
    die "npm is required to install local ccusage and Context7. Run scripts/doctor.sh for details."
  fi
  if ! (
    cd "$TARGET"
    if [ ! -f package.json ]; then
      npm init -y
    fi
    npm install --save-dev @upstash/context7-mcp ccusage
  ); then
    die "Failed to install local npm dependencies. Fix npm and rerun install."
  fi

  info "Installing Serena into .agent-tools/serena-venv"
  if command_exists uv; then
    if ! (
      cd "$TARGET"
      if [ ! -x .agent-tools/serena-venv/bin/python ]; then
        uv venv .agent-tools/serena-venv --python 3.13 || uv venv .agent-tools/serena-venv
      fi
      uv pip install --python .agent-tools/serena-venv/bin/python -U serena-agent
    ); then
      warn "Serena install failed. Rerun scripts/doctor.sh, then rerun install."
    fi
  else
    warn "Skipping Serena install because uv is missing."
  fi

  info "Installing Headroom into .agent-tools/headroom-venv"
  if command_exists uv; then
    if ! (
      cd "$TARGET"
      if [ ! -x .agent-tools/headroom-venv/bin/python ]; then
        uv venv .agent-tools/headroom-venv
      fi
      uv pip install --python .agent-tools/headroom-venv/bin/python -U "headroom-ai[all]"
    ); then
      warn "Headroom install failed. Rerun scripts/doctor.sh, then rerun install."
    fi
  else
    warn "Skipping Headroom install because uv is missing."
  fi

  info "Installing RTK into .agent-tools/rtk"
  if command_exists cargo; then
    if ! (
      cd "$TARGET"
      cargo install --git https://github.com/rtk-ai/rtk --root "$TARGET/.agent-tools/rtk"
    ); then
      warn "RTK install failed. Rerun scripts/doctor.sh, then rerun install."
    fi
  else
    warn "Skipping RTK install because cargo is missing."
  fi
else
  info "Skipping tool installation because --no-tools was provided"
fi

if [ "$CONFIGURE_AGENTS" = "1" ]; then
  if has_agent claude; then
    if command_exists claude; then
      info "Configuring Claude Code local-scope MCP entries"
      (
        cd "$TARGET"
        claude mcp remove serena --scope local >/dev/null 2>&1 || true
        claude mcp remove context7 --scope local >/dev/null 2>&1 || true
        if [ -x "$TARGET/.agent-tools/serena-venv/bin/serena" ]; then
          claude mcp add serena --scope local -- \
            "$TARGET/.agent-tools/serena-venv/bin/serena" \
            start-mcp-server \
            --context claude-code \
            --project "$TARGET" \
            --open-web-dashboard false
        else
          warn "Skipping Claude Serena MCP entry because local Serena binary is missing."
        fi
        if [ -x "$TARGET/node_modules/.bin/context7-mcp" ]; then
          claude mcp add context7 --scope local -- "$TARGET/node_modules/.bin/context7-mcp"
        else
          warn "Skipping Claude Context7 MCP entry because local context7-mcp binary is missing."
        fi
      )
    else
      warn "Skipping Claude Code MCP configuration because claude CLI is missing."
    fi
  fi

  if has_agent codex; then
    info "Codex project MCP entries were written to $TARGET/.codex/config.toml"
    warn "Codex project config loads only for trusted projects. Verify with codex /mcp from the target repo."
  fi
else
  info "Skipping agent CLI configuration because --no-agent-config was provided"
fi

info "Install complete. Run scripts/status.sh --target \"$TARGET\" to inspect the setup."
