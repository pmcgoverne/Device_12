#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INPUT="$1"
TEMPLATE="$2"
OUTPUT="/tmp/pandoc_diagnostic_output.pdf"

echo "🩺 Running Pandoc Diagnostics..."
echo "Input Markdown: $INPUT"
echo "Template: $TEMPLATE"
echo "Output: $OUTPUT"
echo "---------------------------"

# 1. Check if pandoc is installed
echo -n "🔍 Checking pandoc... "
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}not found!${NC}"
    exit 1
else
    echo -e "${GREEN}found!${NC}"
    pandoc --version | head -n 1
fi

# 2. Check for lualatex
echo -n "🔍 Checking for lualatex... "
if ! command -v lualatex &> /dev/null; then
    echo -e "${RED}not found!${NC} (you may need MacTeX or TeX Live)"
else
    echo -e "${GREEN}found!${NC}"
    lualatex --version | head -n 1
fi

# 3. Test basic export
echo -n "🔧 Testing basic Pandoc PDF export... "
echo "# Test PDF" | pandoc --pdf-engine=lualatex -o "$OUTPUT"
if [ $? -ne 0 ]; then
    echo -e "${RED}failed!${NC} (Pandoc cannot generate PDFs)"
else
    echo -e "${GREEN}passed!${NC}"
fi

# 4. Template inspection
if [[ -f "$TEMPLATE" ]]; then
    echo -e "📄 Inspecting template: $TEMPLATE"
    BAD_LINE=$(grep -n 'options\.textemplate' "$TEMPLATE")
    if [[ -n "$BAD_LINE" ]]; then
        echo -e "${RED}❌ ERROR:${NC} Found invalid line in template:"
        echo "$BAD_LINE"
    else
        echo -e "${GREEN}✅ Template looks clean (no JS injection)${NC}"
    fi
else
    echo -e "${RED}⚠️ WARNING:${NC} Template file not found at $TEMPLATE"
fi

# 5. Inspect Markdown for embedded math with JS-style syntax
if [[ -f "$INPUT" ]]; then
    echo -e "📄 Inspecting markdown for malformed LaTeX..."
    BAD_MATH=$(grep -En '\$\([^$]*\{.*\?[^\$]*\}\)' "$INPUT")
    if [[ -n "$BAD_MATH" ]]; then
        echo -e "${RED}⚠️ WARNING:${NC} Markdown has suspicious math-like syntax:"
        echo "$BAD_MATH"
    else
        echo -e "${GREEN}✅ Markdown syntax looks clean${NC}"
    fi
else
    echo -e "${RED}⚠️ WARNING:${NC} Markdown file not found at $INPUT"
fi

# 6. Try full export with template (if both files exist)
if [[ -f "$INPUT" && -f "$TEMPLATE" ]]; then
    echo -e "🧪 Attempting full export with template..."
    pandoc "$INPUT" \
        --template="$TEMPLATE" \
        --pdf-engine=lualatex \
        -o "$OUTPUT"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🎉 SUCCESS:${NC} PDF exported to $OUTPUT"
    else
        echo -e "${RED}❌ FAILURE:${NC} PDF generation failed. Check template and math blocks."
    fi
fi

echo "🩺 Diagnostic complete."
