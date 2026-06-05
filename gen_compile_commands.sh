#!/bin/sh
set -eu

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <output_compile_commands.json> <input_graph_dump.json>" >&2
    exit 1
fi

OUTPUT_FILE="$1"
INPUT_GRAPH="$2"

if ! command -v jq >/dev/null 2>&1; then
    echo "[ERROR] 'jq' utility is required but not installed." >&2
    exit 1
fi

if [ ! -f "$INPUT_GRAPH" ]; then
    echo "[ERROR] Input graph file does not exist: $INPUT_GRAPH" >&2
    exit 1
fi

echo "[DIAGNOSTIC] --- Starting Helm Graph Parse ---" >&2

TOTAL_TARGETS=$(jq '.targets | length' "$INPUT_GRAPH")
echo "[DIAGNOSTIC] Total targets found in graph dump: $TOTAL_TARGETS" >&2

BUILD_CODE_TARGETS=$(jq '[.targets[] | select(.canonical_target == "_build_code")] | length' "$INPUT_GRAPH")
echo "[DIAGNOSTIC] Targets with canonical_target == \"_build_code\": $BUILD_CODE_TARGETS" >&2

CLANG_COMMANDS=$(jq '[.targets[] | select(.canonical_target == "_build_code" and .run_commands != null) | .run_commands[] | select(contains("clang"))] | length' "$INPUT_GRAPH")
echo "[DIAGNOSTIC] Extracted valid 'clang' compilation commands: $CLANG_COMMANDS" >&2

# Process graph directly from the file path
jq '
  [
    .targets[] | 
    select(.canonical_target == "_build_code" and .run_commands != null) | 
    . as $tgt |
    
    ($tgt.run_commands[] | select(contains("clang "))) as $cmd |
    
    $tgt.parameters.SOURCE_FILES | 
    (if type == "string" then (if startswith("\"") and endswith("\"") then .[1:-1] else . end) else . end) as $file |
    
    {
      directory: $tgt.directory,
      file: $file,
      command: $cmd
    }
  ]
' "$INPUT_GRAPH" > "$OUTPUT_FILE"

FINAL_COUNT=$(jq 'length' "$OUTPUT_FILE")
echo "[DIAGNOSTIC] Successfully wrote $FINAL_COUNT records to $OUTPUT_FILE" >&2
echo "[DIAGNOSTIC] --- Diagnostic Complete ---" >&2