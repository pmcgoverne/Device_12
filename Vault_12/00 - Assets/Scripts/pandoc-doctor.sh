#!/bin/bash

INPUT="$1"
CHOICE="$2"

TEMPLATE_DIR="/Users/paulmcgovern/.local/share/pandoc/templates"
OUTPUT="/Users/paulmcgovern/output.pdf"
LUA_FILTER="/Users/paulmcgovern/wikicite.lua"  # optional — remove if not using


case "$CHOICE" in
  Abstract)
    TEMPLATE="$TEMPLATE_DIR/abstract.tex"
    ;;
  Essay)
    TEMPLATE="$TEMPLATE_DIR/essay.tex"
    ;;
  Manuscript)
    TEMPLATE="$TEMPLATE_DIR/term_paper.tex"
    ;;
  *)
    echo "❌ Unknown template choice: $CHOICE"
    exit 1
    ;;
esac

echo "📄 Input: $INPUT"
echo "📑 Using template: $TEMPLATE"
echo "📤 Exporting to: $OUTPUT"

pandoc "$INPUT" \
  --from markdown \
  --to pdf \
  --template="$TEMPLATE" \
  --pdf-engine=lualatex \
  -o "$OUTPUT"

if [ $? -eq 0 ]; then
  echo "✅ Export complete"
  open "$OUTPUT"
else
  echo "❌ Pandoc failed to export"
fi
