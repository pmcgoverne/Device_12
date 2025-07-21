#!/bin/bash

# =============================
# Academic Toolkit Installer
# =============================

# --- Ensure Zotero is not running ---
echo -e "\n🛑 Closing Zotero if running..."
osascript -e 'tell application "Zotero" to quit'
sleep 3  # give it a moment to close

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

# --- 1. Homebrew ---
if ! command -v brew &> /dev/null; then
    echo -e "\n🛠 Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew was installed but is not in PATH."
        echo "👉 Restart Terminal or source brew manually, then rerun."
        exit 1
    else
        echo "✅ Homebrew installed and available."
    fi
else
    echo "✅ Homebrew already installed."
fi

# --- 2. Pandoc ---
if ! command -v pandoc &> /dev/null; then
    echo "📦 Installing Pandoc..."
    brew install pandoc
else
    echo "✅ Pandoc already installed."
fi

# --- 3. Zotero ---
if [ ! -d "/Applications/Zotero.app" ]; then
    echo "📦 Installing Zotero..."
    brew install --cask zotero
else
    echo "✅ Zotero already installed."
fi

if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
    echo "⚠️ Zotero config exists. Merging plugins and preferences..."

    PROFILE_DIR=$(find "$ZOTERO_PROFILE_BASE" -type d -depth 1 | head -n 1)
    if [ -z "$PROFILE_DIR" ]; then
        echo "❌ Zotero profile folder not found. Cannot install extensions."
    else
        echo "🔍 Found Zotero profile: $PROFILE_DIR"

        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        mkdir -p "$TARGET_EXT_DIR"

        if [ -d "$EXTENSIONS_DIR" ]; then
            echo "🤚 Found plugins to install from script directory:"
            for plugin in "$EXTENSIONS_DIR"/*.xpi; do
                [ -e "$plugin" ] || continue
                plugin_name=$(basename "$plugin")
                cp "$plugin" "$TARGET_EXT_DIR/$plugin_name"
                echo "✅ Copied plugin: $plugin_name"
            done
        else
            echo "❌ No 'extensions/' folder found in script directory. Skipping plugin copy."
        fi

        echo "📄 Overwriting Zotero prefs.js with template version..."
        rm -f "$PROFILE_DIR/prefs.js"
        cp "$TEMPLATE_PREFS_FILE" "$PROFILE_DIR/prefs.js"
        if [ -f "$PROFILE_DIR/prefs.js" ]; then
            echo "✅ prefs.js replaced with template."
        else
            echo "❌ Failed to replace prefs.js."
        fi
    fi
elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    echo "📁 No Zotero config found. Copying full template..."
    cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
    echo "✅ Zotero config copied fresh."
else
    echo "❌ Zotero template not found. Skipping."
fi

# --- 4. Obsidian ---
if [ ! -d "/Applications/Obsidian.app" ]; then
    echo "📦 Installing Obsidian..."
    brew install --cask obsidian
else
    echo "✅ Obsidian already installed."
fi

if [ -d "$DEST_VAULT" ]; then
    echo "⚠️ Obsidian vault '$VAULT_NAME' already exists. Skipping copy."
elif [ -d "$SOURCE_VAULT" ]; then
    echo "📂 Copying Obsidian vault..."
    mkdir -p "$(dirname \"$DEST_VAULT\")"
    cp -R "$SOURCE_VAULT" "$DEST_VAULT"
    echo "✅ Vault copied to: $DEST_VAULT"
else
    echo "⚠️ Vault template not found. Skipping."
fi

# --- 5. Zotero Plugin Instructions ---
echo -e "\n📄 Manual Zotero Setup:"
echo "1. Export Zotero library as 'my_library.bib' using BetterBibTeX"
echo "2. Save it to: Obsidian Vault → 00 - Assets/Sources/"
echo "3. In Zotero: Preferences → Zotmoov → Set to same folder"

# --- 6. Obsidian Plugin Configuration ---
echo -e "\n⚙️ Manual Obsidian Plugin Setup:"
echo "1. Open Settings → Zotero Integration → Custom Database"
echo "2. Paste API Key from Zotero"
echo "3. In Pandoc Reference List → Enable 'Pull Bibliography from Zotero'"
echo "4. Set path: 00 - Assets/Sources/my_library.bib"

# --- 7. Done ---
echo -e "\n🎉 Toolkit setup complete! Finish the manual steps to start using the system."
