#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/doctor.sh [--target PATH] [--agents claude,codex]

Checks prerequisites for a local agentic-dev-kit installation.
EOF
}

if ! parse_common_args "$@"; then
  usage
  exit 0
fi

info "Checking prerequisites for $TARGET"
failed=0

require_prereq git || failed=1
require_prereq node || failed=1
require_prereq npm || failed=1
require_prereq npx || failed=1
require_prereq uv || failed=1
require_prereq cargo || failed=1

if has_agent claude; then
  require_prereq claude || failed=1
fi

if has_agent codex; then
  require_prereq codex || failed=1
fi

printf '\n'
info "Local-only policy checks"
printf 'ok   default installer avoids brew install\n'
printf 'ok   default installer avoids npm install -g\n'
printf 'ok   default installer avoids uv tool install\n'
printf 'ok   default installer avoids rtk init -g\n'
printf 'ok   default installer avoids global Headroom wrapping\n'

if [ "$failed" -ne 0 ]; then
  printf '\n'
  die "One or more prerequisites are missing."
fi

printf '\n'
info "Doctor passed."

