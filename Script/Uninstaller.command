#!/bin/bash
set -euo pipefail

# =============================
# Device_12 Uninstaller
# Reverses installations/changes from the Device_12 installer
# Options:
#   --dry-run       : print actions without changing system
#   --aggressive    : remove MacTeX residues (/Library/TeX, /usr/local/texlive)
#   --remove-brew   : attempt to uninstall Homebrew entirely
# =============================

DRY_RUN=0
AGGRESSIVE=0
REMOVE_BREW=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --aggressive) AGGRESSIVE=1 ;;
    --remove-brew) REMOVE_BREW=1 ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

log() { printf "[%s] %s\n" "$(date +%Y-%m-%d_%H:%M:%S)" "$*"; }

# Match installer values
VAULT_NAME="Vault_12"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_ZOTERO_PATH="$SCRIPT_DIR/Zotero"
EXTENSIONS_DIR="$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user/extensions"

# --- Helpers ---------------------------------------------------------------

brew_exists() {
  command -v brew >/dev/null 2>&1 || [[ -x /opt/homebrew/bin/brew ]] || [[ -x /usr/local/bin/brew ]]
}

brew_cmd() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    echo "/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    echo "/usr/local/bin/brew"
  else
    echo ""
  fi
}

remove_path_lines() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home
  target_home="$(dscl . -read "/Users/$target_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  [[ -z "$target_home" ]] && target_home="$HOME"

  local line_si='if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi'
  local line_intel='if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi'

  for rc in "$target_home/.zprofile" "$target_home/.zshrc"; do
    if [[ -f "$rc" ]]; then
      log "🧹 Reverting PATH lines in $rc"
      run "/usr/bin/sed -i '' -e '/$(echo "$line_si" | sed 's/[].*^$[]/\\&/g')/d' -e '/$(echo "$line_intel" | sed 's/[].*^$[]/\\&/g')/d' \"$rc\""
    fi
  done
}

close_app() {
  local app_name="$1"
  if pgrep -x "$app_name" >/dev/null 2>&1; then
    log "🛑 Closing $app_name…"
    run "osascript -e 'tell application \"$app_name\" to quit'"
    sleep 2
  fi
}

rm_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    log "🗑️ Removing $path"
    run "rm -rf \"$path\""
  fi
}

# --- Start -----------------------------------------------------------------

log "🧼 Starting Device_12 Uninstall (dry-run=$DRY_RUN, aggressive=$AGGRESSIVE, remove-brew=$REMOVE_BREW)"

# 1) Close apps we’ll remove
close_app "Zotero"
close_app "Obsidian"

# 2) Uninstall casks / formulae via Homebrew
if brew_exists; then
  BREW="$(brew_cmd)"
  log "🍺 Using Homebrew at: $BREW"

  # Uninstall apps (ignore errors if not installed)
  log "📦 Uninstalling casks and formulae (Zotero, Obsidian, MacTeX, Pandoc)…"
  run "$BREW list --cask >/dev/null 2>&1 && $BREW uninstall --cask --force zotero || true"
  run "$BREW list --cask >/dev/null 2>&1 && $BREW uninstall --cask --force obsidian || true"
  run "$BREW list --cask >/dev/null 2>&1 && $BREW uninstall --cask --force mactex || true"
  run "$BREW list --formula >/dev/null 2>&1 && $BREW uninstall --force pandoc || true"
  run "$BREW cleanup || true"
else
  log "ℹ️ Homebrew not detected. Skipping brew-based uninstalls."
fi

# 3) Extra removal of app bundles (in case non-brew installs / leftover links)
rm_if_exists "/Applications/Zotero.app"
rm_if_exists "/Applications/Obsidian.app"

# 4) Obsidian vault(s) created by installer
#    The installer had a slight path inconsistency; remove both possibilities.
rm_if_exists "$HOME/Documents/$VAULT_NAME"
rm_if_exists "$HOME/Documents/Obsidian Vaults/$VAULT_NAME"

# 5) Revert Zotero profile changes
ZOTERO_APPDATA="$HOME/Library/Application Support/Zotero"
if [[ -d "$ZOTERO_APPDATA" ]]; then
  log "🧩 Cleaning Zotero profile (best-effort)…"

  # If the installer’s full template was copied (strong hint: directories match structure)
  if [[ -d "$ZOTERO_APPDATA/Profiles/8g56zk9v.user" && -d "$TEMPLATE_ZOTERO_PATH/Profiles/8g56zk9v.user" ]]; then
    # If a marker existed we'd use it, but since the original installer didn't create one,
    # do NOT nuke the whole Zotero unless a clear template copy is detected.
    # Remove extensions that came from the template:
    if [[ -d "$EXTENSIONS_DIR" ]]; then
      for plugin in "$EXTENSIONS_DIR"/*.xpi; do
        [[ -e "$plugin" ]] || continue
        base="$(basename "$plugin")"
        # Remove matching plugin files from the active profile(s)
        while IFS= read -r -d '' prof; do
          run "rm -f \"$prof/extensions/$base\" || true"
        done < <(find "$ZOTERO_APPDATA/Profiles" -type d -maxdepth 1 -mindepth 1 -print0 2>/dev/null || true)
      done
    fi

    # prefs.js was replaced by the installer; we cannot reconstruct the original.
    # As a cautious step, we leave prefs.js in place. If you want a hard reset, uncomment:
    # while IFS= read -r -d '' prof; do
    #   run "rm -f \"$prof/prefs.js\""
    # done < <(find "$ZOTERO_APPDATA/Profiles" -type d -maxdepth 1 -mindepth 1 -print0 2>/dev/null || true)
  fi
fi

# 6) Revert PATH lines added by installer
remove_path_lines

# 7) Aggressive MacTeX cleanup (optional, huge dirs)
if [[ $AGGRESSIVE -eq 1 ]]; then
  log "🪓 Aggressive MacTeX cleanup enabled."
  # Common MacTeX locations
  # NOTE: These may require sudo; prompt if needed.
  for p in "/Library/TeX" "/usr/local/texlive" "/Applications/TeX" "$HOME/Library/texmf"; do
    if [[ -e "$p" ]]; then
      if [[ -w "$p" ]]; then
        rm_if_exists "$p"
      else
        log "🔐 Removing $p with sudo"
        run "sudo rm -rf \"$p\""
      fi
    fi
  done

  # Forget known pkg receipts if present (no-op if missing)
  if command -v pkgutil >/dev/null 2>&1; then
    for rid in \
      "org.tug.mactex.*" \
      "org.macports.texlive*" ; do
      run "pkgutil --pkgs | /usr/bin/grep -E '^${rid}$' | xargs -I {} sudo pkgutil --forget {} || true"
    done
  fi
fi

# 8) Optionally remove Homebrew entirely
if [[ $REMOVE_BREW -eq 1 && $(brew_cmd) != "" ]]; then
  BREW="$(brew_cmd)"
  log "🧨 Removing Homebrew (per --remove-brew)…"
  # Use official uninstall script if available
  run "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\" || true"

  # Fallback manual cleanup (paths differ by arch)
  for d in "/opt/homebrew" "/usr/local/Homebrew" "/usr/local/Caskroom" "/usr/local/Cellar" "/usr/local/bin/brew"; do
    if [[ -e "$d" ]]; then
      if [[ -w "$d" ]]; then
        rm_if_exists "$d"
      else
        log "🔐 Removing $d with sudo"
        run "sudo rm -rf \"$d\""
      fi
    fi
  done
fi

log "✅ Uninstall complete."
if [[ $DRY_RUN -eq 1 ]]; then
  log "This was a DRY RUN. Re-run without --dry-run to apply changes."
fi

# Notes for future-proofing:
# • Consider adding a marker file (e.g., ~/.device_12_marker) during install so the uninstaller
#   can safely detect and fully remove resources it created (especially Zotero profile).
# • If you want prefs.js restored, have the installer back it up first, then restore here.
