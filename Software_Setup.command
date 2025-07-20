#!/bin/bash

# =============================
# Academic Toolkit Installer
# =============================

# --- COLORS ---
green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
reset="\033[0m"

ZOTERO_SUPPORT_PATH="$HOME/Library/Application Support/Zotero"
TEMPLATE_ZOTERO_PATH="./Zotero"
VAULT_NAME="TemplateVault"
SOURCE_VAULT="./TemplateVault"
DEST_VAULT="$HOME/Documents/Obsidian Vaults/$VAULT_NAME"

# --- Mode Selection ---
echo -e "\nChoose integration mode:"
echo "1) Full Setup (Install everything and use provided configs)"
echo "2) Partial Setup (Keep your Zotero/Obsidian configs, just install tools)"
echo "3) Cancel"
read -p "Enter 1, 2, or 3: " mode

if [ "$mode" == "3" ]; then
    echo -e "${red}❌ Cancelled by user.${reset}"
    exit 1
fi

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
if [ "$mode" == "1" ]; then
    if [ -d "$ZOTERO_SUPPORT_PATH" ]; then
        echo -e "${yellow}⚠️ Zotero config exists at $ZOTERO_SUPPORT_PATH. Skipping copy.${reset}"
    elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
        echo -e "${yellow}📁 Copying Zotero config...${reset}"
        cp -R "$TEMPLATE_ZOTERO_PATH" "$ZOTERO_SUPPORT_PATH"
        echo -e "${green}✅ Zotero config copied.${reset}"
    else
        echo -e "${red}⚠️ Zotero template not found. Skipping.${reset}"
    fi
fi

if [ ! -d "/Applications/Zotero.app" ]; then
    echo -e "${yellow}📦 Installing Zotero...${reset}"
    brew install --cask zotero
else
    echo -e "${green}✅ Zotero already installed.${reset}"
fi

# --- 4. Obsidian ---
if [ "$mode" == "1" ]; then
    if [ -d "$DEST_VAULT" ]; then
        echo -e "${yellow}⚠️ Obsidian vault '${VAULT_NAME}' already exists. Skipping copy.${reset}"
    elif [ -d "$SOURCE_VAULT" ]; then
        echo -e "${yellow}📂 Copying Obsidian vault...${reset}"
        mkdir -p "$(dirname \"$DEST_VAULT\")"
        cp -R "$SOURCE_VAULT" "$DEST_VAULT"
        echo -e "${green}✅ Vault copied to: $DEST_VAULT${reset}"
    else
        echo -e "${red}⚠️ Vault template not found. Skipping.${reset}"
    fi
fi

if [ ! -d "/Applications/Obsidian.app" ]; then
    echo -e "${yellow}📦 Installing Obsidian...${reset}"
    brew install --cask obsidian
else
    echo -e "${green}✅ Obsidian already installed.${reset}"
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

# --- 7. Python Setup ---
if [ -f "requirements.txt" ]; then
    echo -e "\n🐍 ${yellow}Setting up Python environment...${reset}"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo -e "${green}✅ Python environment ready. Run: source venv/bin/activate${reset}"
else
    echo -e "${yellow}⚠️ No requirements.txt found. Skipping Python setup.${reset}"
fi

# --- Complete ---
echo -e "\n🎉 ${green}Toolkit setup complete! Finish the manual steps to start using the system.${reset}"
