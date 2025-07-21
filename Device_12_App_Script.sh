#!/bin/bash

# =============================
# Academic Toolkit Installer (Platypus-Compatible)
# =============================

echo "📦 Starting Academic Toolkit Installation..."
sleep 1

# --- Close Zotero if running ---
echo "🛑 Closing Zotero (if running)..."
osascript -e 'tell application "Zotero" to quit'
sleep 3

# --- PATH SETUP ---
echo "🔧 Setting up paths..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZOTERO_SUPPORT_PATH="$HOME/Library/Application Support/Zotero"
ZOTERO_PROFILE_BASE="$ZOTERO_SUPPORT_PATH/Profiles"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
TEMPLATE_PREFS_FILE="$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user/prefs.js"
EXTENSIONS_DIR="$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user/extensions"
VAULT_NAME="Template"
SOURCE_VAULT="$SCRIPT_DIR/Template"
DEST_VAULT="$HOME/Documents/Obsidian Vaults/$VAULT_NAME"

# --- Make sure Homebrew is in PATH ---
echo "🔍 Verifying Homebrew path..."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# --- Install Homebrew if missing ---
if ! command -v brew &> /dev/null; then
    echo "🔄 Homebrew not found. Installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew installed but not available in PATH. Aborting."
        exit 1
    else
        echo "✅ Homebrew installed successfully."
    fi
else
    echo "✅ Homebrew already installed."
fi

# --- Install Pandoc ---
echo "📦 Checking Pandoc..."
if ! command -v pandoc &> /dev/null; then
    echo "📥 Installing Pandoc..."
    brew install pandoc
else
    echo "✅ Pandoc already installed."
fi

# --- Install Zotero ---
echo "📦 Checking Zotero..."
if [ ! -d "/Applications/Zotero.app" ]; then
    echo "📥 Installing Zotero..."
    brew install --cask zotero
else
    echo "✅ Zotero already installed."
fi

# --- Handle Zotero Profile ---
echo "🧠 Preparing Zotero profile data..."
if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
    echo "⚠️ Zotero config exists. Attempting merge..."

    PROFILE_DIR=$(find "$ZOTERO_PROFILE_BASE" -type d -depth 1 | head -n 1)
    if [ -n "$PROFILE_DIR" ]; then
        echo "📁 Found Zotero profile: $PROFILE_DIR"

        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        mkdir -p "$TARGET_EXT_DIR"

        if [ -d "$EXTENSIONS_DIR" ]; then
            echo "📦 Installing Zotero extensions..."
            for plugin in "$EXTENSIONS_DIR"/*.xpi; do
                [ -e "$plugin" ] || continue
                cp "$plugin" "$TARGET_EXT_DIR/"
                echo "✅ Installed: $(basename "$plugin")"
            done
        else
            echo "⚠️ No extensions found in template. Skipping plugins."
        fi

        echo "📝 Replacing prefs.js..."
        rm -f "$PROFILE_DIR/prefs.js"
        cp "$TEMPLATE_PREFS_FILE" "$PROFILE_DIR/prefs.js"
        echo "✅ prefs.js updated."
    else
        echo "❌ Could not locate Zotero profile folder."
    fi
elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    echo "📂 No Zotero config found. Copying full template..."
    cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
    echo "✅ Zotero profile initialized."
else
    echo "⚠️ No Zotero template present. Skipping config."
fi

# --- Install Obsidian ---
echo "📦 Checking Obsidian..."
if [ ! -d "/Applications/Obsidian.app" ]; then
    echo "📥 Installing Obsidian..."
    brew install --cask obsidian
else
    echo "✅ Obsidian already installed."
fi

# --- Copy Obsidian Vault ---
echo "📁 Setting up Obsidian vault..."
if [ ! -d "$DEST_VAULT" ] && [ -d "$SOURCE_VAULT" ]; then
    mkdir -p "$(dirname "$DEST_VAULT")"
    cp -R "$SOURCE_VAULT" "$DEST_VAULT"
    echo "✅ Vault copied to: $DEST_VAULT"
elif [ -d "$DEST_VAULT" ]; then
    echo "⚠️ Vault already exists. Skipping."
else
    echo "⚠️ Vault template not found. Skipping."
fi

# --- Zotero Manual Instructions ---
echo ""
echo "📄 Manual Zotero Steps:"
echo "1️⃣ Export Zotero library as 'my_library.bib' using BetterBibTeX"
echo "2️⃣ Save to: Obsidian Vault → 00 - Assets/Sources/"
echo "3️⃣ Zotmoov Preferences → Set path to the same folder"

# --- Obsidian Manual Instructions ---
echo ""
echo "⚙️ Manual Obsidian Plugin Setup:"
echo "1️⃣ Open Obsidian → Settings → Zotero Integration → Custom DB"
echo "2️⃣ Paste Zotero API Key"
echo "3️⃣ In Pandoc Reference List → Enable Zotero source"
echo "4️⃣ Set .bib path: 00 - Assets/Sources/my_library.bib"

# --- Done ---
echo ""
echo "🎉 All done! Academic Toolkit installed successfully."
echo "✅ Follow manual steps above to complete configuration."
