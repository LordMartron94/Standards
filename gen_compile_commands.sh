#!/bin/sh
set -eu

DEBUG=0

if [ "${COMPILATION_GENERATOR_DEBUG:-false}" = "true" ]; then
    DEBUG=1
fi

diagnostic() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "$@" >&2
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --debug|-d)
            DEBUG=1
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Usage: $0 [--debug|-d] <output_compile_commands.json> <input_graph_dump.json>" >&2
            echo "[ERROR] Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [--debug|-d] <output_compile_commands.json> <input_graph_dump.json>" >&2
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

diagnostic "[DIAGNOSTIC] --- Starting Helm Graph Parse ---"

TOTAL_TARGETS=$(jq '.targets | length' "$INPUT_GRAPH")
ENTITY_COUNT=$(jq '(.entities? // {}) | length' "$INPUT_GRAPH")
diagnostic "[DIAGNOSTIC] Targets: $TOTAL_TARGETS, entities: $ENTITY_COUNT"

jq '
  def is_compile_argv($argv):
    ($argv | type) == "array"
    and ($argv | length) >= 4
    and ($argv[0] | tostring | endswith("compile_object.sh"));

  def flatten_tail($tail):
    if ($tail | length) == 0 then []
    elif ($tail | length) == 1 and (($tail[0] | tostring) | test("\\n")) then
      ($tail[0] | tostring | gsub("[\\n\\r\\t ]+"; " ") | split(" ") | map(select(length > 0)))
    else $tail end;

  def param_text($tgt; $name):
    ($tgt.parameters[$name] // null)
    | if . == null then null
      elif type == "array" then (.[0] | tostring)
      else tostring end;

  def matrix_src($tgt):
    (param_text($tgt; "SRC"))
    // (
      ($tgt.matrix_instance // "")
      | if test("^SRC=") then sub("^SRC="; "") else null end
    );

  def has_template($text):
    ($text | tostring | test("\\$\\{"));

  def resolved_src($tgt; $argv):
    ($argv[1] | tostring) as $raw
    | if has_template($raw) then (matrix_src($tgt) // $raw) else $raw end;

  def resolved_obj($tgt; $argv; $src):
    ($argv[2] | tostring) as $raw
    | if has_template($raw) then
        ((param_text($tgt; "OBJ_DIR") // "build/linux/x86_64/obj")
         + "/"
         + ((param_text($tgt; "OUT_NAME") // "") + "_obj")
         + "/"
         + $src
         + ".o")
      else $raw end;

  def resolved_dep($tgt; $argv; $src):
    ($argv[3] | tostring) as $raw
    | if has_template($raw) then
        ((param_text($tgt; "OBJ_DIR") // "build/linux/x86_64/obj")
         + "/"
         + ((param_text($tgt; "OUT_NAME") // "") + "_obj")
         + "/"
         + $src
         + ".d")
      else $raw end;

  def record_from_argv($directory; $argv):
    ($argv[1] | tostring) as $file
    | select($file | test("\\$\\{") | not)
    | (flatten_tail($argv[4:])) as $flags
    | {
        directory: ($directory | tostring),
        file: $file,
        arguments: (["clang", "-c", $file, "-MD", "-MF", ($argv[3] | tostring), "-o", ($argv[2] | tostring)] + $flags)
      };

  (
    [
      .targets[]
      | select(
          .canonical_target == "_compile_objects"
          or .canonical_target == "_build_code"
          or any((.run_argvs? // [])[]; is_compile_argv(.))
        )
      | . as $tgt
      | (
          if any(($tgt.run_argvs? // [])[]; is_compile_argv(.)) then
            ($tgt.run_argvs[] | select(is_compile_argv(.)))
          else
            empty
          end
        ) as $argv
      | resolved_src($tgt; $argv) as $file
      | select($file | test("\\$\\{") | not)
      | {
          directory: ($tgt.directory | tostring),
          file: $file,
          arguments: (
            ["clang", "-c", $file, "-MD", "-MF", (resolved_dep($tgt; $argv; $file)), "-o", (resolved_obj($tgt; $argv; $file))]
            + flatten_tail($argv[4:])
          )
        }
    ]
    +
    [
      (.entities? // {})[]
      | . as $ent
      | (($ent.run_argvs? // [])[] | select(is_compile_argv(.))) as $argv
      | record_from_argv($ent.directory; $argv)
    ]
  )
' "$INPUT_GRAPH" > "$OUTPUT_FILE"

FINAL_COUNT=$(jq 'length' "$OUTPUT_FILE")
diagnostic "[DIAGNOSTIC] Successfully wrote $FINAL_COUNT records to $OUTPUT_FILE"
