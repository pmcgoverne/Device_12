#!/bin/bash

echo "NOTE: $NOTE"

# Get the full path of the current file from Obsidian
NOTE="$1"
NOTE_DIR=$(dirname "$NOTE")
NOTE_NAME=$(basename "$NOTE" .md)

# Lua filter location
LUA_FILTER="/path/to/your/filter/myfilter.lua"

# Exit if user cancels template choice
[ -z "$TEMPLATE_NAME" ] && exit 1

# Output path
OUTPUT_FILE="${NOTE_DIR}/${NOTE_NAME}.pdf"

# Run pandoc with the chosen template and filter
pandoc "$NOTE" \
  --pdf-engine=xelatex \
  --template="${TEMPLATE_DIR}/${TEMPLATE_NAME}" \
  --lua-filter="$LUA_FILTER" \
  -o "$OUTPUT_FILE"

# Optional: Open the PDF after creation
open "$OUTPUT_FILE"
