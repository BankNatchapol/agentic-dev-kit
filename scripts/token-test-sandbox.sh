#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KIT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

TARGET="/tmp/agentic-dev-kit-token-test"
AGENTS="claude,codex"

usage() {
  cat <<'EOF'
Usage: scripts/token-test-sandbox.sh <command> [--target PATH] [--agents claude,codex]

Commands:
  create    Create or reset the small sandbox fixture.
  install   Install agentic-dev-kit into the sandbox.
  status    Check sandbox installation status and Serena health.
  prompts   Print the low-cost baseline/optimized prompts.
  usage     Print and run ccusage session reports when available.
  cleanup   Remove the sandbox directory.
  all       Run create, install, status, and prompts.

Default target: /tmp/agentic-dev-kit-token-test
EOF
}

COMMAND="${1:-help}"
if [ "$#" -gt 0 ]; then
  shift
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { echo "ERROR: --target requires a path" >&2; exit 1; }
      TARGET="$2"
      shift 2
      ;;
    --agents)
      [ "$#" -ge 2 ] || { echo "ERROR: --agents requires a comma-separated value" >&2; exit 1; }
      AGENTS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

info() {
  printf '%s\n' "==> $*"
}

safe_reset_target() {
  if [ -e "$TARGET" ] && [ ! -f "$TARGET/.agentic-dev-kit-token-test" ]; then
    echo "ERROR: Refusing to remove non-sandbox path: $TARGET" >&2
    echo "Remove it manually or choose a different --target." >&2
    exit 1
  fi
  rm -rf "$TARGET"
}

create_fixture() {
  safe_reset_target
  info "Creating sandbox fixture at $TARGET"
  mkdir -p "$TARGET/src" "$TARGET/docs" "$TARGET/logs" "$TARGET/test"
  printf '%s\n' "agentic-dev-kit token test sandbox" > "$TARGET/.agentic-dev-kit-token-test"

  cat > "$TARGET/README.md" <<'EOF'
# Token Test Sandbox

Small fake checkout used to compare baseline agent behavior against the local
agentic-dev-kit setup. The app pretends to refresh auth tokens and cache user
profiles.

Known failure: production logs show repeated `TOKEN_REFRESH_LOOP` events.
EOF

  cat > "$TARGET/package.json" <<'EOF'
{
  "name": "token-test-sandbox",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node test/auth-cache.test.js",
    "logs": "cat logs/app.log"
  }
}
EOF

  cat > "$TARGET/src/config.js" <<'EOF'
export const config = {
  authCacheTtlSeconds: Number(process.env.AUTH_CACHE_TTL_SECONDS ?? 0),
  maxRefreshAttempts: 3,
  retryBackoffMs: 25
};
EOF

  cat > "$TARGET/src/auth.js" <<'EOF'
import { config } from "./config.js";

export function shouldRefreshToken(cachedAtMs, nowMs = Date.now()) {
  const ageSeconds = Math.floor((nowMs - cachedAtMs) / 1000);
  return ageSeconds >= config.authCacheTtlSeconds;
}

export function explainRefreshDecision(cachedAtMs, nowMs = Date.now()) {
  return shouldRefreshToken(cachedAtMs, nowMs)
    ? "refresh because cached token is stale"
    : "reuse cached token";
}
EOF

  cat > "$TARGET/src/cache.js" <<'EOF'
const profiles = new Map();

export function getProfile(userId) {
  return profiles.get(userId);
}

export function setProfile(userId, profile) {
  profiles.set(userId, { ...profile, cachedAtMs: Date.now() });
}

export function clearProfiles() {
  profiles.clear();
}
EOF

  cat > "$TARGET/src/server.js" <<'EOF'
import { explainRefreshDecision } from "./auth.js";
import { getProfile, setProfile } from "./cache.js";

export function handleProfileRequest(userId) {
  const cached = getProfile(userId);
  if (!cached) {
    setProfile(userId, { id: userId, name: "Demo User" });
    return { status: 200, source: "origin" };
  }

  return {
    status: 200,
    source: "cache",
    auth: explainRefreshDecision(cached.cachedAtMs)
  };
}
EOF

  cat > "$TARGET/test/auth-cache.test.js" <<'EOF'
import assert from "node:assert/strict";
import { shouldRefreshToken } from "../src/auth.js";

const cachedAtMs = 1_000_000;
const nowMs = cachedAtMs + 5_000;

assert.equal(
  shouldRefreshToken(cachedAtMs, nowMs),
  false,
  "a token cached five seconds ago should not refresh with the default config"
);

console.log("auth cache test passed");
EOF

  cat > "$TARGET/docs/architecture.md" <<'EOF'
# Architecture

The fake service has three tiny modules:

- `src/server.js` handles profile requests.
- `src/cache.js` stores in-memory profile objects.
- `src/auth.js` decides whether cached auth should refresh.

The intended default auth cache TTL is 60 seconds. A value of 0 seconds causes
every request to be treated as stale, creating repeated token refreshes.
EOF

  {
    printf '%s\n' "timestamp level request_id event message"
    i=1
    while [ "$i" -le 220 ]; do
      printf '2026-06-30T09:%02d:%02dZ WARN req-%04d TOKEN_REFRESH_LOOP user=demo ttl=0 attempt=%d message="cached token treated as stale immediately"\n' \
        $((i % 60)) $(((i * 7) % 60)) "$i" $(((i % 3) + 1))
      i=$((i + 1))
    done
    printf '%s\n' "2026-06-30T09:59:59Z ERROR req-final AUTH_CACHE_MISCONFIG default ttl is zero; expected 60 seconds"
  } > "$TARGET/logs/app.log"

  (
    cd "$TARGET"
    git init -b main >/dev/null
    git add README.md package.json src docs test logs .agentic-dev-kit-token-test
    git commit -m "Create token test sandbox" >/dev/null
  )

  info "Sandbox created."
}

install_kit() {
  info "Installing agentic-dev-kit into $TARGET"
  "$KIT_ROOT/scripts/install.sh" --target "$TARGET" --agents "$AGENTS"
}

status_check() {
  info "Checking sandbox status"
  "$KIT_ROOT/scripts/status.sh" --target "$TARGET" --agents "$AGENTS"
  if [ -x "$TARGET/.agent-tools/serena-venv/bin/serena" ]; then
    (
      cd "$TARGET"
      .agent-tools/serena-venv/bin/serena project health-check .
    )
  fi
}

print_prompts() {
  cat <<EOF
Sandbox:
  cd "$TARGET"

Codex baseline:
  codex
  Prompt:
    Do not use Serena, Context7, RTK, or Headroom. Inspect the repo normally. Summarize the app structure, identify the failing log cause, and suggest one fix. Keep the answer under 8 bullets.

Codex optimized:
  codex
  Run /mcp and confirm Serena + Context7 are available.
  Prompt:
    Use the local agentic-dev-kit setup. Use Serena before reading full files, Context7 only if needed, and RTK for noisy shell/log output. Do the same task as before. Keep the answer under 8 bullets.

Claude baseline:
  claude
  Prompt:
    Do not use Serena, Context7, RTK, or Headroom. Inspect the repo normally. Summarize the app structure, identify the failing log cause, and suggest one fix. Keep the answer under 8 bullets.

Claude optimized:
  claude
  Run /mcp and confirm Serena + Context7 are available.
  Prompt:
    Use the local agentic-dev-kit setup. Use Serena before reading full files, Context7 only if needed, and RTK for noisy shell/log output. Do the same task as before. Keep the answer under 8 bullets.

After each run, record the newest session:
  "$TARGET/node_modules/.bin/ccusage" codex session --json
  "$TARGET/node_modules/.bin/ccusage" claude session --json
EOF
}

usage_report() {
  if [ -x "$TARGET/node_modules/.bin/ccusage" ]; then
    info "Codex sessions"
    "$TARGET/node_modules/.bin/ccusage" codex session || true
    printf '\n'
    info "Claude sessions"
    "$TARGET/node_modules/.bin/ccusage" claude session || true
  elif [ -x "$KIT_ROOT/node_modules/.bin/ccusage" ]; then
    info "Using kit-local ccusage because sandbox ccusage is not installed"
    "$KIT_ROOT/node_modules/.bin/ccusage" session || true
  else
    echo "ccusage is not installed yet. Run install first." >&2
    exit 1
  fi
}

cleanup() {
  if [ -e "$TARGET" ] && [ ! -f "$TARGET/.agentic-dev-kit-token-test" ]; then
    echo "ERROR: Refusing to remove non-sandbox path: $TARGET" >&2
    exit 1
  fi
  rm -rf "$TARGET"
  info "Removed $TARGET"
}

case "$COMMAND" in
  create) create_fixture ;;
  install) install_kit ;;
  status) status_check ;;
  prompts) print_prompts ;;
  usage) usage_report ;;
  cleanup) cleanup ;;
  all)
    create_fixture
    install_kit
    status_check
    print_prompts
    ;;
  help|-h|--help) usage ;;
  *)
    echo "ERROR: Unknown command: $COMMAND" >&2
    usage
    exit 1
    ;;
esac

