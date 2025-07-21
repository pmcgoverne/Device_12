#!/bin/bash

# =============================
# Academic Toolkit Installer
# =============================

# --- COLORS ---
green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
reset="\033[0m"

# --- PATH SETUP ---
SCRIPT_DIR="$(cd \"$(dirname \"$0\")\" && pwd)"
ZOTERO_SUPPORT_PATH="$HOME/Library/Application Support/Zotero"
ZOTERO_PROFILE_BASE="$ZOTERO_SUPPORT_PATH/Profiles"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
VAULT_NAME="Template"
SOURCE_VAULT="$SCRIPT_DIR/Template"
DEST_VAULT="$HOME/Documents/Obsidian Vaults/$VAULT_NAME"

# --- 1. Homebrew ---
if ! command -v brew &> /dev/null; then
    echo -e "${yellow}🛠 Installing Homebrew...${reset}"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo -e "${red}❌ Homebrew was installed but is not in PATH.${reset}"
        echo -e "${yellow}👉 Restart Terminal or source brew manually, then rerun.${reset}"
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
if [ ! -d "/Applications/Zotero.app" ]; then
    echo -e "${yellow}📦 Installing Zotero...${reset}"
    brew install --cask zotero
else
    echo -e "${green}✅ Zotero already installed.${reset}"
fi

if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
    echo -e "${yellow}⚠️ Zotero config exists. Merging plugins and preferences...${reset}"

    PROFILE_DIR=$(find "$ZOTERO_PROFILE_BASE" -type d -depth 1 | head -n 1)
    if [ -z "$PROFILE_DIR" ]; then
        echo -e "${red}❌ Zotero profile folder not found. Cannot install extensions.${reset}"
    else
        echo -e "${yellow}🔍 Found Zotero profile: $PROFILE_DIR${reset}"

        TEMPLATE_EXT_DIR=$(find "$TEMPLATE_ZOTERO_PATH" -type d -iname "extensions" | head -n 1)
        echo -e "${yellow}📁 Using template extensions folder: $TEMPLATE_EXT_DIR${reset}"

        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        mkdir -p "$TARGET_EXT_DIR"

        if [ -d "$TEMPLATE_EXT_DIR" ]; then
            echo -e "${yellow}🤚 Found plugins to install:${reset}"
            ls "$TEMPLATE_EXT_DIR"/*.xpi 2>/dev/null || echo "None found"

            for plugin in "$TEMPLATE_EXT_DIR"/*.xpi; do
                if [ ! -e "$plugin" ]; then
                    echo -e "${red}❌ No .xpi plugin files found. Skipping.${reset}"
                    break
                fi

                plugin_name=$(basename "$plugin")
                if [ ! -f "$TARGET_EXT_DIR/$plugin_name" ]; then
                    cp "$plugin" "$TARGET_EXT_DIR/"
                    echo -e "${green}✅ Copied plugin: $plugin_name${reset}"
                else
                    echo -e "${yellow}⚠️ Plugin exists: $plugin_name (skipped)${reset}"
                fi
            done

            echo -e "${yellow}🧹 Clearing Zotero startup cache to refresh extensions...${reset}"
            rm -f "$PROFILE_DIR/extensions.json"
            rm -rf "$PROFILE_DIR/startupCache" "$PROFILE_DIR/startupCache.*"

            if [ -f "$TEMPLATE_ZOTERO_PATH/prefs.js" ]; then
                echo -e "${yellow}📄 Overwriting Zotero prefs.js with template version...${reset}"
                cp "$TEMPLATE_ZOTERO_PATH/prefs.js" "$PROFILE_DIR/prefs.js"
                echo -e "${green}✅ prefs.js replaced with template.${reset}"
            fi

            echo -e "${yellow}🚀 Launching Zotero briefly to initialize extensions...${reset}"
            open -a "Zotero"
            sleep 8
            osascript -e 'tell application "Zotero" to quit'
            echo -e "${green}✅ Zotero extensions initialized and ready.${reset}"
        else
            echo -e "${red}❌ No 'extensions/' folder found in Zotero template directory. Skipping plugin copy.${reset}"
        fi
    fi
elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    echo -e "${yellow}📁 No Zotero config found. Copying full template...${reset}"
    cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
    echo -e "${green}✅ Zotero config copied fresh.${reset}"
else
    echo -e "${red}❌ Zotero template not found. Skipping.${reset}"
fi

# --- 4. Obsidian ---
if [ ! -d "/Applications/Obsidian.app" ]; then
    echo -e "${yellow}📦 Installing Obsidian...${reset}"
    brew install --cask obsidian
else
    echo -e "${green}✅ Obsidian already installed.${reset}"
fi

if [ -d "$DEST_VAULT" ]; then
    echo -e "${yellow}⚠️ Obsidian vault '$VAULT_NAME' already exists. Skipping copy.${reset}"
elif [ -d "$SOURCE_VAULT" ]; then
    echo -e "${yellow}📂 Copying Obsidian vault...${reset}"
    mkdir -p "$(dirname \"$DEST_VAULT\")"
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

# --- 7. Done ---
echo -e "\n🎉 ${green}Toolkit setup complete! Finish the manual steps to start using the system.${reset}"
