#!/bin/sh
set -eu

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input dependency file '$INPUT_FILE' not found." >&2
    exit 1
fi

awk '
{
    # 1. Strip the trailing backslash used for Make line continuation
    sub(/\\$/, "")
    
    # 2. Strip the target declaration (e.g., "build/dev-bin/libsplash.so: ")
    # This specifically looks for a colon followed by a space to avoid 
    # destroying Windows paths if this is ever ported.
    sub(/^[^:]*: /, "")
    
    # 3. Shield escaped spaces by replacing "\ " with a non-printable character (\x01)
    gsub(/\\ /, "\x01")
    
    # 4. Iterate over the remaining space-separated fields
    for (i = 1; i <= NF; i++) {
        if ($i != "") {
            # 5. Restore the space and print the clean absolute path
            val = $i
            gsub(/\x01/, " ", val)
            print val
        }
    }
}' "$INPUT_FILE" > "$OUTPUT_FILE"