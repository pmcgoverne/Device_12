#!/bin/bash

INPUT="$1"
CHOICE="$2"
TITLE="$3"
FORMAT="$4"  # Default to PDF if not specified

# Lock file to prevent repeat execution
LOCK="/tmp/pandoc-export-$(basename "$INPUT").lock"

if [ -e "$LOCK" ]; then
  echo "🚫 Export already in progress or just completed. Skipping."
  exit 0
fi

touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

TEMPLATE_DIR="00 - Assets/Pandoc Templates"
LUA_FILTER="00 - Assets/Scripts/wikicite.lua"
BIB_FILE="00 - Assets/Sources/my_library.bib"

case "$CHOICE" in
  Abstract)
    TEMPLATE="$TEMPLATE_DIR/abstract.tex"
    ;;
  Essay)
    TEMPLATE="$TEMPLATE_DIR/essay.tex"
    ;;
  Manuscript)
    TEMPLATE="$TEMPLATE_DIR/manuscript.tex"
    ;;
  *)
    echo "❌ Unknown template choice: $CHOICE"
    exit 1
    ;;
esac

case "$FORMAT" in
  pdf)
    OUTPUT="03 - Published/${TITLE}.pdf"
    PANDOC_OPTIONS=(
      --template="$TEMPLATE"
      --pdf-engine=lualatex
    )
    ;;
  docx)
    OUTPUT="03 - Published/${TITLE}.docx"
    PANDOC_OPTIONS=()  # Word doesn't use LaTeX templates
    ;;
  *)
    echo "❌ Unknown format: $FORMAT. Use 'pdf' or 'docx'."
    exit 1
    ;;
esac

echo "📄 Input: $INPUT"
echo "📑 Using template: $TEMPLATE"
echo "📚 Using bibliography: $BIB_FILE"
echo "📤 Exporting to: $OUTPUT"

pandoc "$INPUT" \
  --from markdown+wikilinks_title_after_pipe\
  --to "$FORMAT" \
  --lua-filter="$LUA_FILTER" \
  --bibliography="$BIB_FILE" \
  --citeproc \
  --metadata suppress-tightlist=true \
  "${PANDOC_OPTIONS[@]}" \
  -o "$OUTPUT"

if [ $? -eq 0 ]; then
  echo "✅ Export complete"
  open "$OUTPUT"
else
  echo "❌ Pandoc failed to export"
fi
