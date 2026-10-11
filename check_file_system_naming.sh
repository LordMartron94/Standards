#!/bin/sh
# Verifies the file <-> system naming rule (CONVENTIONS.md § Naming) for one
# library source file: in src/<prefix>_<system>.c, every non-static function
# DEFINED there must be named <library>_<system>_*, with <system> exactly the
# file's own system part. One system = one file; a function of another system
# belongs in that system's file.
#
# Usage: check_file_system_naming.sh <path to libs/<library>/src/<prefix>_<system>.c>
# Prints one line per violation (nothing when clean). Exit status is always 0
# so callers can treat the output as advisory text. Files outside
# libs/<library>/src/ and files whose stem has no "<prefix>_<system>" shape are
# ignored.
set -eu

f="$1"

case "$f" in
  */libs/*/src/*.c | libs/*/src/*.c) ;;
  *) exit 0 ;;
esac

library="$(printf '%s' "$f" | sed -E 's#^.*libs/([^/]+)/src/.*$#\1#')"
stem="$(basename "$f" .c)"

case "$stem" in
  *_*) system="${stem#*_}" ;;
  *) exit 0 ;;
esac

expected="${library}_${system}"
prefix="${stem%%_*}"
internal_expected="${prefix}_${system}"

awk -v expected="$expected" -v internal_expected="$internal_expected" -v library="$library" -v prefix="$prefix" -v file="$f" '
  # A definition: starts in column 0, is not static/typedef/extern/preprocessor,
  # has a name followed by "(", and the statement is not a bare declaration.
  /^[A-Za-z_]/ && !/^(static|typedef|extern|struct|union|enum|return|if|for|while|switch|case|else|do)[ \t]/ && /[A-Za-z_][A-Za-z0-9_]*\(/ && !/;[ \t]*$/ {
    line = $0
    sub(/\(.*/, "", line)
    n = split(line, parts, /[ \t*]+/)
    name = parts[n]
    if (name == "" || name ~ /^[A-Z_]/) next

    # Only names that claim to belong to this library are judged: <library>_*
    # (exported) or <prefix>_* (internal, non-static). Anything else is a
    # libc/OS symbol definition and out of scope.
    is_exported = (index(name, library "_") == 1)
    is_internal = (index(name, prefix "_") == 1)
    if (!is_exported && !is_internal) next

    if (is_exported && index(name, expected "_") != 1 && name != expected) {
      printf "%s:%d: function \"%s\" is not part of system \"%s\" (expected prefix \"%s_\") -- move it to the file of its own system\n", file, NR, name, expected, expected
    } else if (!is_exported && index(name, internal_expected "_") != 1) {
      printf "%s:%d: function \"%s\" is not part of system \"%s\" (expected prefix \"%s_\") -- move it to the file of its own system\n", file, NR, name, expected, internal_expected
    }
  }
' "$f"
