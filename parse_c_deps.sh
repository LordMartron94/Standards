#!/bin/sh
# Normalizes clang -MD output to workspace-relative paths (one per line).
# Paths outside the workspace root are silently dropped.
set -eu

INPUT_FILE="$1"
OUTPUT_FILE="$2"
HELM_ROOT="${HELM_ROOT:-$(pwd)}"

HELM_ROOT="$(cd "$HELM_ROOT" && pwd)"

if [ ! -f "$INPUT_FILE" ]; then
	echo "Error: Input dependency file '$INPUT_FILE' not found." >&2
	exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT INT HUP TERM

awk '
{
	sub(/\\$/, "")
	sub(/^[^:]*: /, "")
	gsub(/\\ /, "\x01")
	for (i = 1; i <= NF; i++) {
		if ($i != "") {
			val = $i
			gsub(/\x01/, " ", val)
			print val
		}
	}
}' "$INPUT_FILE" >"$tmp"

: >"$OUTPUT_FILE"
while IFS= read -r path || [ -n "$path" ]; do
	[ -z "$path" ] && continue

	case "$path" in
	/*) abs_path="$path" ;;
	*) abs_path="$HELM_ROOT/$path" ;;
	esac

	if ! rel="$(realpath --relative-to="$HELM_ROOT" "$abs_path" 2>/dev/null)"; then
		continue
	fi

	case "$rel" in
	.. | ../*) continue ;;
	esac

	echo "$rel" >>"$OUTPUT_FILE"
done <"$tmp"
