#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/doctor.sh [--target PATH] [--agents claude,codex] [--install-prereqs]

Checks prerequisites for a local agentic-dev-kit installation.

By default this only checks and suggests fixes. Use --install-prereqs to install
supported missing prerequisites with official user-level installers.
EOF
}

INSTALL_PREREQS="0"
DOCTOR_ARGS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-prereqs)
      INSTALL_PREREQS="1"
      shift
      ;;
    *)
      escaped=$(printf '%s\n' "$1" | sed "s/'/'\\\\''/g")
      DOCTOR_ARGS="$DOCTOR_ARGS '$escaped'"
      shift
      ;;
  esac
done

eval "set -- $DOCTOR_ARGS"

if ! parse_common_args "$@"; then
  usage
  exit 0
fi

print_fix_steps() {
  printf '\n'
  info "Next steps"

  if ! command_exists git; then
    printf '%s\n' "- Install Git, for example with Apple's developer tools:"
    printf '%s\n' "  xcode-select --install"
  fi

  if ! command_exists node || ! command_exists npm || ! command_exists npx; then
    printf '%s\n' "- Install Node.js so npm/npx are available:"
    printf '%s\n' "  https://nodejs.org/"
    printf '%s\n' "  # or use your preferred version manager, such as fnm/nvm"
  fi

  if ! command_exists uv; then
    printf '%s\n' "- Install uv for local Serena and Headroom virtualenvs:"
    printf '%s\n' "  curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi

  if ! command_exists cargo; then
    printf '%s\n' "- Install Rust/Cargo for the local RTK source install:"
    printf '%s\n' "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  fi

  if has_agent claude && ! command_exists claude; then
    printf '%s\n' "- Install or sign in to Claude Code, then rerun doctor."
  fi

  if has_agent codex && ! command_exists codex; then
    printf '%s\n' "- Install or sign in to Codex, then rerun doctor."
  fi

  printf '\n'
  printf '%s\n' "You can also let doctor install supported missing prereqs:"
  printf '%s\n' "  scripts/doctor.sh --target \"$TARGET\" --agents \"$AGENTS\" --install-prereqs"
  printf '\n'
  printf '%s\n' "After installing uv or Rust/Cargo, restart your shell or source your shell profile, then rerun doctor."
}

install_supported_prereqs() {
  installed_any="0"

  if ! command_exists uv; then
    info "Installing uv with the official user-level installer"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    installed_any="1"
  fi

  if ! command_exists cargo; then
    info "Installing Rust/Cargo with rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
    installed_any="1"
  fi

  if [ "$installed_any" = "1" ]; then
    printf '\n'
    info "Prerequisite installers finished"
    printf '%s\n' "Restart your shell, or source your shell profile, then rerun:"
    printf '%s\n' "  scripts/doctor.sh --target \"$TARGET\" --agents \"$AGENTS\""
  else
    info "No supported missing prerequisites to install automatically."
  fi
}

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
  print_fix_steps
  if [ "$INSTALL_PREREQS" = "1" ]; then
    install_supported_prereqs
  fi
  die "One or more prerequisites are missing."
fi

printf '\n'
info "Doctor passed."
