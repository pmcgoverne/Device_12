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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

        # --- Copy extensions ---
        TEMPLATE_EXT_DIR="$TEMPLATE_ZOTERO_PATH/extensions"
        TARGET_EXT_DIR="$PROFILE_DIR/extensions"
        if [ -d "$TEMPLATE_EXT_DIR" ]; then
            mkdir -p "$TARGET_EXT_DIR"
            for plugin in "$TEMPLATE_EXT_DIR"/*.xpi; do
                plugin_name=$(basename "$plugin")
                if [ ! -f "$TARGET_EXT_DIR/$plugin_name" ]; then
                    cp "$plugin" "$TARGET_EXT_DIR/"
                    echo -e "${green}✅ Plugin copied: $plugin_name${reset}"
                else
                    echo -e "${yellow}⚠️ Plugin exists: $plugin_name (skipped)${reset}"
                fi
            done
        fi

        # --- Patch prefs.js ---
        PREFS_FILE="$PROFILE_DIR/prefs.js"
        if [ -f "$PREFS_FILE" ]; then
            echo -e "${yellow}🛠 Updating prefs.js safely...${reset}"

            PREF_ENTRIES=(
            'extensions.ui.dictionary.hidden=true'
            'extensions.ui.extension.hidden=false'
            'extensions.ui.locale.hidden=true'
            'extensions.webextensions.uuids="{\"better-bibtex@iris-advies.com\":\"080aa77d-f3cc-4fc4-8313-e844d9e587b8\",\"zoteroAddons@ytshen.com\":\"0ca0d2ca-f67e-4f27-8103-e1923f5fcf40\",\"zoterostyle@polygon.org\":\"1501bc36-a038-44d2-b897-c86612447157\",\"zotmoov@wileyy.com\":\"cfd1a221-24a7-41a0-9a6d-dc306806c3db\"}"'
            'extensions.zotero.Zotero.AddonItem.key="8NL6WMFP"'
            'extensions.zotero.attachmentRenameTemplate="@{{ if {{ authorsCount > 2 }} }}\n{{ authors max=\"1\" suffix=\" et al\" }}\n{{ else }}\n{{ authors join=\"_\" }}\n{{ endif }}\n_{{ year }}"'
            'extensions.zotero.downloadAssociatedFiles=false'
            'extensions.zotero.httpServer.localAPI.enabled=true'
            'extensions.zotero.lastSelectedPrefPane="zotero-prefpane-general"'
            'extensions.zotero.sourceList.persist="{\"L1\":true,\"P1\":false}"'
            'extensions.zotero.translators.better-bibtex.citekeyFormat="authEtal2(sep = \\"_\\").lower + \\"_\\" + year"'
            'extensions.zotero.translators.better-bibtex.citekeyFormatEditing="authEtal2(sep=\\"_\\").lower + \\"_\\" + year"'
            'extensions.zotero.translators.better-bibtex.path.git="/opt/homebrew/bin/git"'
            'extensions.zotero.translators.better-bibtex.path.texstudio=""'
            'extensions.zotero.translators.better-bibtex.platform="mac"'
            'extensions.zotero.zoteroaddons.firstInstalledVersion="2.1.1"'
            'extensions.zotero.zoteroaddons.guideStatus=1'
            'extensions.zotero.zoterostyle.annotationColors="[[\\"green\\",\\"#5fb236\\"],[\\"yellow\\",\\"#ffd400\\"],[\\"red\\",\\"#ff6666\\"],[\\"🧠_Term\\",\\"#f19837\\"],[\\"👤_Person\\",\\"#a28ae5\\"],[\\"📄_Document\\",\\"#2ea8e5\\"],[\\"🎟️_Event\\",\\"#e56eee\\"],[\\"🗃️_Group\\",\\"#3f51b5\\"],[\\"#_Part\\",\\"#000000\\"],[\\"#_Chapter\\",\\"#404040\\"],[\\"#_Index\\",\\"#aaaaaa\\"]]"'
            'extensions.zotero.zoterostyle.annotationColorsGroups="[[\\"Obsidian Markup\\",[[\\"green\\",\\"#5fb236\\"],[\\"yellow\\",\\"#ffd400\\"],[\\"red\\",\\"#ff6666\\"],[\\"🧠_Term\\",\\"#f19837\\"],[\\"👤_Person\\",\\"#a28ae5\\"],[\\"📄_Document\\",\\"#2ea8e5\\"],[\\"🎟️_Event\\",\\"#e56eee\\"],[\\"🗃️_Group\\",\\"#3f51b5\\"],[\\"#_Part\\",\\"#000000\\"],[\\"#_Chapter\\",\\"#404040\\"],[\\"#_Index\\",\\"#aaaaaa\\"]]]]"'
            'extensions.zotmoov.file_behavior="copy"'
            )

            for entry in "${PREF_ENTRIES[@]}"; do
                key="${entry%%=*}"
                value="${entry#*=}"

                if grep -q "user_pref(\"$key\"" "$PREFS_FILE"; then
                    echo -e "${yellow}⚠️ Pref already exists: $key (skipped)${reset}"
                else
                    echo "user_pref(\"$key\", $value);" >> "$PREFS_FILE"
                    echo -e "${green}✅ Added pref: $key = $value${reset}"
                fi
            done
        else
            echo -e "${red}❌ prefs.js not found. Cannot update plugin settings.${reset}"
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

# --- 7. Done ---
echo -e "\n🎉 ${green}Toolkit setup complete! Finish the manual steps to start using the system.${reset}"
