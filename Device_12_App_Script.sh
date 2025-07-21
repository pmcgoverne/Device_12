#!/bin/bash

# =============================
# Academic Toolkit Installer (Platypus-Compatible)
# =============================

# --- Ensure Zotero is not running ---
osascript -e 'tell application "Zotero" to quit'
sleep 3

# --- PATH SETUP ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZOTERO_SUPPORT_PATH="$HOME/Library/Application Support/Zotero"
ZOTERO_PROFILE_BASE="$ZOTERO_SUPPORT_PATH/Profiles"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
TEMPLATE_PREFS_FILE="$SCRIPT_DIR/Zotero/Profiles/8g56zk9v.user/prefs.js"
EXTENSIONS_DIR="$SCRIPT_DIR/Zotero/Profiles/8g56zk9v.user/extensions"
VAULT_NAME="Template"
SOURCE_VAULT="$SCRIPT_DIR/Template"
DEST_VAULT="$HOME/Documents/Obsidian Vaults/$VAULT_NAME"

# --- Ensure Homebrew is available ---
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v brew &> /dev/null; then
    echo "🛠 Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Source shellenv
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew was installed but still not available in PATH."
        exit 1
    fi
fi

# --- Install Pandoc ---
if ! command -v pandoc &> /dev/null; then
    echo "📦 Installing Pandoc..."
    brew install pandoc
fi

# --- Install Zotero ---
if [ ! -d "/Applications/Zotero.app" ]; then
    echo "📦 Installing Zotero..."
    brew install --cask zotero
fi

# --- Merge or Install Zotero Config ---
if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
    echo "⚙️ Zotero config exists. Merging..."

    PROFILE_DIR=$(find "$ZOTERO_PROFILE_BASE" -type d -depth 1 | head -n 1)
    if [ -n "$PROFILE_DIR" ]; then
        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        mkdir -p "$TARGET_EXT_DIR"

        if [ -d "$EXTENSIONS_DIR" ]; then
            for plugin in "$EXTENSIONS_DIR"/*.xpi; do
                [ -e "$plugin" ] || continue
                cp "$plugin" "$TARGET_EXT_DIR/"
            done
        fi

        rm -f "$PROFILE_DIR/prefs.js"
        cp "$TEMPLATE_PREFS_FILE" "$PROFILE_DIR/prefs.js"
    else
        echo "❌ No Zotero profile found."
    fi
elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    echo "📁 No Zotero config found. Copying full template..."
    cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
fi

# --- Install Obsidian ---
if [ ! -d "/Applications/Obsidian.app" ]; then
    echo "📦 Installing Obsidian..."
    brew install --cask obsidian
fi

# --- Copy Obsidian Vault ---
if [ ! -d "$DEST_VAULT" ] && [ -d "$SOURCE_VAULT" ]; then
    mkdir -p "$(dirname "$DEST_VAULT")"
    cp -R "$SOURCE_VAULT" "$DEST_VAULT"
fi

# --- Manual Zotero Setup ---
echo ""
echo "📄 Manual Zotero Setup:"
echo "1. Export Zotero library as 'my_library.bib' using BetterBibTeX"
echo "2. Save to: Obsidian Vault → 00 - Assets/Sources/"
echo "3. Zotmoov Preferences → point to the same folder"

# --- Manual Obsidian Setup ---
echo ""
echo "⚙️ Manual Obsidian Setup:"
echo "1. Settings → Zotero Integration → Custom DB"
echo "2. Paste Zotero API Key"
echo "3. Enable 'Pull Bibliography from Zotero'"
echo "4. Path: 00 - Assets/Sources/my_library.bib"

echo ""
echo "🎉 Academic Toolkit Setup Complete!"
