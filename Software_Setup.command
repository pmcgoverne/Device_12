#!/bin/bash

# =============================
# Academic Toolkit Installer
# =============================

# --- COLORS ---
green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
reset="\033[0m"


# Always resolve template paths relative to the script's location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZOTERO_SUPPORT_PATH="$HOME/Library/Application Support/Zotero"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
VAULT_NAME="Template"
SOURCE_VAULT="$SCRIPT_DIR/Template"
DEST_VAULT="$HOME/Documents/Obsidian Vaults/$VAULT_NAME"


# --- 1. Homebrew ---
if ! command -v brew &> /dev/null; then
    echo -e "${yellow}🛠 Installing Homebrew...${reset}"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to path without needing user to restart terminal
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo -e "${red}❌ Homebrew was installed but still not available in PATH.${reset}"
        echo -e "${yellow}👉 Please restart Terminal or source brew manually, then rerun this script.${reset}"
        exit 1
    else
        echo -e "${green}✅ Homebrew installed and available.${reset}"
    fi
else
    echo -e "${green}✅ Homebrew already installed.${reset}"
fi

# --- 2. Pandoc ---
if ! command -v pandoc &> /dev/null; then
    echo -e "${yellow}📦 Installing Pandoc...${reset}"
    brew install pandoc
else
    echo -e "${green}✅ Pandoc already installed.${reset}"
fi

# --- 3. Zotero ---
ZOTERO_PROFILE_BASE="$HOME/Library/Application Support/Zotero/Profiles"

if [ ! -d "/Applications/Zotero.app" ]; then
    echo -e "${yellow}📦 Installing Zotero...${reset}"
    brew install --cask zotero
else
    echo -e "${green}✅ Zotero already installed.${reset}"
fi

if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
    echo -e "${yellow}⚠️ Zotero config exists. Attempting non-destructive plugin merge...${reset}"

    # Detect profile directory (first *.user folder inside Profiles/)
     PROFILE_DIR=$(find "$ZOTERO_PROFILE_BASE" -type d -depth 1 | head -n 1)
    if [ -z "$PROFILE_DIR" ]; then
        echo -e "${red}❌ Zotero profile folder not found. Cannot install extensions.${reset}"
    else
        echo -e "${yellow}🔍 Found Zotero profile: $PROFILE_DIR${reset}"


        # 1. Copy new extensions into the profile's 'extensions/' dir
        TEMPLATE_EXT_DIR="$TEMPLATE_ZOTERO_PATH/extensions"
        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        if [ -d "$TEMPLATE_EXT_DIR" ]; then
            mkdir -p "$TARGET_EXT_DIR"
            for plugin in "$TEMPLATE_EXT_DIR"/*.xpi; do
                plugin_name=$(basename "$plugin")
                if [ ! -f "$TARGET_EXT_DIR/$plugin_name" ]; then
                    cp "$plugin" "$TARGET_EXT_DIR/"
                    echo -e "${green}✅ Copied plugin: $plugin_name${reset}"
                else
                    echo -e "${yellow}⚠️ Plugin already exists: $plugin_name (skipped)${reset}"
                fi
            done
        fi

        # 2. Update prefs.js with necessary lines (if not already present)
        PREFS_FILE="$PROFILE_DIR/prefs.js"
        if [ -f "$PREFS_FILE" ]; then
            echo -e "${yellow}🛠 Updating prefs.js safely...${reset}"

            declare -A NEW_PREFS=(
                ["extensions.zotero.translators.better-bibtex.autoExport"]="true"
                ["extensions.zotero.translators.better-bibtex.quickCopyMode"]="\"citation key\""
                ["extensions.zotmoov.file_behavior"]="\"copy\""
            )

            for key in "${!NEW_PREFS[@]}"; do
                value="${NEW_PREFS[$key]}"
                if grep -q "user_pref(\"$key\"" "$PREFS_FILE"; then
                    echo -e "${yellow}⚠️ Pref already exists: $key (skipped)${reset}"
                else
                    echo "user_pref(\"$key\", $value);" >> "$PREFS_FILE"
                    echo -e "${green}✅ Added pref: $key = $value${reset}"
                fi
            done
        else
            echo -e "${red}❌ prefs.js not found in: $PROFILE_DIR${reset}"
        fi
    fi
elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    echo -e "${yellow}📁 No Zotero config found. Copying full template...${reset}"
    cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
    echo -e "${green}✅ Zotero config copied fresh.${reset}"
else
    echo -e "${red}⚠️ Zotero template not found. Skipping.${reset}"
fi



# --- 4. Obsidian ---
if [ ! -d "/Applications/Obsidian.app" ]; then
    echo -e "${yellow}📦 Installing Obsidian...${reset}"
    brew install --cask obsidian
else
    echo -e "${green}✅ Obsidian already installed.${reset}"
fi

if [ -d "$DEST_VAULT" ]; then
    echo -e "${yellow}⚠️ Obsidian vault '${VAULT_NAME}' already exists. Skipping copy.${reset}"
elif [ -d "$SOURCE_VAULT" ]; then
    echo -e "${yellow}📂 Copying Obsidian vault...${reset}"
    mkdir -p "$(dirname "$DEST_VAULT")"
    cp -R "$SOURCE_VAULT" "$DEST_VAULT"
    echo -e "${green}✅ Vault copied to: $DEST_VAULT${reset}"
else
    echo -e "${red}⚠️ Vault template not found. Skipping.${reset}"
fi




# --- 5. Zotero Plugin Instructions ---
echo -e "\n📄 ${yellow}Manual Zotero Setup:${reset}"
echo -e "1. Export Zotero library as 'my_library.bib' using BetterBibTeX"
echo -e "2. Save it to: Obsidian Vault → 00 - Assets/Sources/"
echo -e "3. In Zotero: Preferences → Zotmoov → Set to same folder"

# --- 6. Obsidian Plugin Configuration ---
echo -e "\n⚙️ ${yellow}Manual Obsidian Plugin Setup:${reset}"
echo -e "1. Open Settings → Zotero Integration → Custom Database"
echo -e "2. Paste API Key from Zotero"
echo -e "3. In Pandoc Reference List → Enable 'Pull Bibliography from Zotero'"
echo -e "4. Set path: 00 - Assets/Sources/my_library.bib"

# --- Complete ---
echo -e "\n🎉 ${green}Toolkit setup complete! Finish the manual steps to start using the system.${reset}"
