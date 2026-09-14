#!/bin/sh
# Analyze a C source file using this project's real compile flags, always
# sourced from compile_commands.json -- never hand-picked or guessed flags.
#
# Usage:
#   analyze_with_project_flags.sh [--no-regen] <file relative to repo root> [-- extra clang-tidy args...]
#
# By default, regenerates compile_commands.json first via the project's own
# `helm run generate_compilation_database` target, so it's always in sync
# with the real build graph -- pass --no-regen to skip that (e.g. if helm
# isn't available, or the file is known to already be current).
#
# Only works for files that are actually part of the build graph (i.e. have
# an entry in compile_commands.json). A header is analyzed indirectly, via
# whichever .c file includes it (e.g. analyze nexus.h by passing a .c file
# that #includes it).

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPILE_DB="$REPO_ROOT/compile_commands.json"

REGEN=1
if [ "${1:-}" = "--no-regen" ]; then
  REGEN=0
  shift
fi

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 [--no-regen] <file> [-- extra clang-tidy args...]" >&2
  exit 1
fi

FILE="$1"
shift

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] 'jq' is required but not installed." >&2
  exit 1
fi

if [ "$REGEN" -eq 1 ]; then
  if ! command -v helm >/dev/null 2>&1; then
    echo "[ERROR] 'helm' is required to regenerate compile_commands.json (or pass --no-regen to use it as-is)." >&2
    exit 1
  fi
  ( cd "$REPO_ROOT" && helm run generate_compilation_database >&2 )
fi

if [ ! -f "$COMPILE_DB" ]; then
  echo "[ERROR] compile_commands.json not found at $COMPILE_DB." >&2
  exit 1
fi

if ! jq -e --arg f "$FILE" 'any(.[]; .file == $f)' "$COMPILE_DB" >/dev/null; then
  echo "[ERROR] '$FILE' has no entry in compile_commands.json -- it is not part of the real build graph, so there is no authoritative flag set for it." >&2
  echo "        Known files:" >&2
  jq -r '.[].file' "$COMPILE_DB" | sed 's/^/          /' >&2
  exit 1
fi

cd "$REPO_ROOT"
exec clang-tidy -p "$REPO_ROOT" "$FILE" "$@"
