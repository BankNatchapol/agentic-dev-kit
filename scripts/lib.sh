#!/usr/bin/env sh

set -eu

ADK_NAME="agentic-dev-kit"
ADK_START_PREFIX="${ADK_NAME}:start"
ADK_END_PREFIX="${ADK_NAME}:end"

info() {
  printf '%s\n' "==> $*"
}

warn() {
  printf '%s\n' "WARN: $*" >&2
}

die() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

abs_path() {
  path="$1"
  if [ -d "$path" ]; then
    (cd "$path" && pwd)
  else
    dir=$(dirname "$path")
    base=$(basename "$path")
    (cd "$dir" && printf '%s/%s\n' "$(pwd)" "$base")
  fi
}

default_target() {
  pwd
}

parse_common_args() {
  TARGET="$(default_target)"
  AGENTS="claude,codex"
  INSTALL_TOOLS="1"
  CONFIGURE_AGENTS="1"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target)
        [ "$#" -ge 2 ] || die "--target requires a path"
        TARGET="$2"
        shift 2
        ;;
      --agents)
        [ "$#" -ge 2 ] || die "--agents requires a comma-separated value"
        AGENTS="$2"
        shift 2
        ;;
      --no-tools)
        INSTALL_TOOLS="0"
        shift
        ;;
      --no-agent-config)
        CONFIGURE_AGENTS="0"
        shift
        ;;
      -h|--help)
        return 2
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  [ -d "$TARGET" ] || die "Target directory does not exist: $TARGET"
  TARGET=$(abs_path "$TARGET")
}

has_agent() {
  case ",$AGENTS," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_dir() {
  mkdir -p "$1"
}

ensure_gitignore_line() {
  file="$1/.gitignore"
  line="$2"
  touch "$file"
  if ! grep -Fxq "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

remove_exact_line() {
  file="$1"
  line="$2"
  [ -f "$file" ] || return 0
  tmp=$(mktemp)
  awk -v line="$line" '$0 != line { print }' "$file" > "$tmp"
  mv "$tmp" "$file"
}

remove_if_empty() {
  file="$1"
  [ -f "$file" ] || return 0
  if ! grep -q '[^[:space:]]' "$file"; then
    rm -f "$file"
  fi
}

remove_marked_block() {
  file="$1"
  marker="$2"
  comment="$3"
  [ -f "$file" ] || return 0

  if [ "$comment" = "<!--" ]; then
    start="${comment} ${ADK_START_PREFIX}:${marker} -->"
    end="${comment} ${ADK_END_PREFIX}:${marker} -->"
  else
    start="${comment} ${ADK_START_PREFIX}:${marker}"
    end="${comment} ${ADK_END_PREFIX}:${marker}"
  fi
  tmp=$(mktemp)
  awk -v start="$start" -v end="$end" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

append_marked_file() {
  file="$1"
  marker="$2"
  comment="$3"
  content_file="$4"

  ensure_dir "$(dirname "$file")"
  touch "$file"
  remove_marked_block "$file" "$marker" "$comment"

  {
    if [ "$comment" = "<!--" ]; then
      printf '\n%s %s:%s -->\n' "$comment" "$ADK_START_PREFIX" "$marker"
    else
      printf '\n%s %s:%s\n' "$comment" "$ADK_START_PREFIX" "$marker"
    fi
    cat "$content_file"
    if [ "$comment" = "<!--" ]; then
      printf '%s %s:%s -->\n' "$comment" "$ADK_END_PREFIX" "$marker"
    else
      printf '%s %s:%s\n' "$comment" "$ADK_END_PREFIX" "$marker"
    fi
  } >> "$file"
}

render_template() {
  src="$1"
  dest="$2"
  target="$3"
  ensure_dir "$(dirname "$dest")"
  sed "s#__TARGET__#$target#g" "$src" > "$dest"
}

require_prereq() {
  if command_exists "$1"; then
    printf 'ok   %s\n' "$1"
  else
    printf 'miss %s\n' "$1"
    return 1
  fi
}
