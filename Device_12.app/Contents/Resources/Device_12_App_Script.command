#!/bin/bash

# =============================
# Academic Toolkit Installer (Platypus-Compatible)
# Fixed for permission errors and improved logging
# =============================

echo "📦 Starting Academic Toolkit Installation..."
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
log_file="install_$timestamp.log"

# Function to log messages with timestamps
log() {
  echo "[$(date +%Y-%m-%d_%H:%M:%S)] $1"
}

# Check if we have write access to the current directory
if [[ ! -w . ]]; then
  log "⚠️ Warning: Current directory is read-only. Logging may be limited."
  exec > /dev/null 2>&1  # Disable logging to file
else
  exec > >(tee -a "$log_file") 2>&1  # Redirect output to log file
fi

# --- Close Zotero if running ---
log "🛑 Checking if Zotero is running..."
if pgrep -x "Zotero" > /dev/null; then
  log "🔻 Zotero is running. Attempting to quit..."
  osascript -e 'tell application "Zotero" to quit'
  sleep 3
  log "✅ Zotero closed."
else
  log "✅ Zotero is not running. No action needed."
fi

# Set variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
EXTENSIONS_DIR="$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user/extensions"
VAULT_NAME="Vault_12"
SOURCE_VAULT="$SCRIPT_DIR/Template"

add_brew_to_path() {
  if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    log "🔄 Added Homebrew to PATH."
  else
    log "✅ Homebrew already in PATH."
  fi
}

# --- Install Homebrew if missing ---
{
  if ! command -v brew &> /dev/null; then
    log "🔄 Homebrew not found. Installing via official script..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    add_brew_to_path() {
      if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
        log "🔄 Added Homebrew to PATH."
      else
        log "✅ Homebrew already in PATH."
      fi
    }

    if command -v brew &> /dev/null; then
      log "✅ Homebrew installed successfully."
    else
      log "❌ Homebrew installation failed. Continuing without it."
    fi
  else
    log "✅ Homebrew already installed."
  fi
} || log "⚠️ Homebrew step encountered an error."

# --- Install Pandoc ---
{
  sudo chown -R $(whoami) /usr/local/share/zsh /usr/local/share/zsh/site-functions 
  chmod u+w /usr/local/share/zsh /usr/local/share/zsh/site-functions

  if ! command -v pandoc &> /dev/null; then
    log "📦 Checking Pandoc..."
    log "📥 Installing Pandoc..."
    brew install pandoc || log "⚠️ brew failed to install Pandoc"

    if command -v pandoc &> /dev/null; then
      log "✅ Pandoc installed successfully."
    else
      log "❌ Pandoc installation failed."
    fi
  else
    log "✅ Pandoc already installed."
  fi
} || log "⚠️ Pandoc step encountered an error."

# --- Install MacTeX (for lualatex support) ---
{
  if command -v lualatex &> /dev/null; then
    log "✅ LuaLaTeX already available."
  elif [ -d "/Library/TeX" ]; then
    log "✅ MacTeX already installed at /Library/TeX."
  else
    log "📦 Installing MacTeX (includes LuaLaTeX)..."
    brew install --cask mactex || log "⚠️ brew failed to install MacTeX"

    # Update PATH for TeX binaries if not already present
    if [ -x "/Library/TeX/texbin/lualatex" ]; then
      log "✅ MacTeX installed successfully. LuaLaTeX available."
    else
      log "❌ MacTeX installation failed or lualatex not found."
    fi
  fi
} || log "⚠️ MacTeX/LuaLaTeX installation encountered an error."

# --- Install Zotero ---
{
  if [ -d "/Applications/Zotero.app" ]; then
    log "✅ Zotero already installed in /Applications. Skipping installation."
  elif ! command -v zotero &> /dev/null; then
    log "📥 Installing Zotero..."
    brew install --cask zotero || log "⚠️ brew failed to install Zotero"

    if [ -d "/Applications/Zotero.app" ] || command -v zotero &> /dev/null; then
      log "✅ Zotero installed successfully."
    else
      log "❌ Zotero installation failed."
    fi
  else
    log "✅ Zotero already installed via command-line."
  fi
} || log "⚠️ Zotero step encountered an error."


# --- Handle Zotero Profile ---
{
  if [ -d "$HOME/Library/Application Support/Zotero" ]; then
    log "⚠️ Zotero config exists. Attempting to merge..."

    PROFILE_DIR=$(find "$HOME/Library/Application Support/Zotero/Profiles" -type d -depth 1 | head -n 1)
    if [ -n "$PROFILE_DIR" ]; then
      log "📁 Found Zotero profile: $PROFILE_DIR"

      TARGET_EXT_DIR="$PROFILE_DIR/extensions"
      mkdir -p "$TARGET_EXT_DIR"

      if [ -d "$EXTENSIONS_DIR" ]; then
        log "📦 Installing Zotero extensions..."
        for plugin in "$EXTENSIONS_DIR"/*.xpi; do
          [ -e "$plugin" ] || continue
          cp "$plugin" "$TARGET_EXT_DIR/"
          echo "✅ Installed: $(basename "$plugin")"
        done
      fi

      log "📝 Replacing prefs.js..."
      rm -f "$PROFILE_DIR/prefs.js"
      cp "$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user/prefs.js" "$PROFILE_DIR/prefs.js"
      log "✅ prefs.js updated."
    else
      log "❌ Could not locate Zotero profile folder."
    fi
  elif [ -d "$TEMPLATE_ZOTERO_PATH" ]; then
    log "📂 No Zotero config found. Copying full template..."
    cp -R "$TEMPLATE_ZOTERO_PATH" "$HOME/Library/Application Support/Zotero"
    log "✅ Zotero profile initialized."
  else
    log "⚠️ No Zotero template present. Skipping config."
  fi
} || log "⚠️ Zotero profile setup encountered an error."

# --- Install Obsidian ---
{
  if [ -d "/Applications/Obsidian.app" ]; then
    log "✅ Obsidian already installed in /Applications. Skipping installation."
  elif ! command -v obsidian &> /dev/null; then
    log "📥 Installing Obsidian..."
    brew install --cask obsidian || log "⚠️ brew failed to install Obsidian"

    if [ -d "/Applications/Obsidian.app" ] || command -v obsidian &> /dev/null; then
      log "✅ Obsidian installed successfully."
    else
      log "❌ Obsidian installation failed."
    fi
  else
    log "✅ Obsidian already installed via command-line."
  fi
} || log "⚠️ Obsidian step encountered an error."


# --- Copy Obsidian Vault ---
{
  if [ ! -d "$HOME/Documents/Obsidian Vaults/$VAULT_NAME" ] && [ -d "$SOURCE_VAULT" ]; then
    log "📁 Setting up Obsidian vault..."
    mkdir -p "$(dirname "$HOME/Documents/$VAULT_NAME")"
    cp -R "$SOURCE_VAULT" "$HOME/Documents/$VAULT_NAME"
    log "✅ Vault copied to: $HOME/Documents/$VAULT_NAME"
  else
    log "⚠️ Obsidian vault setup skipped."
  fi
} || log "⚠️ Obsidian vault setup encountered an error."
