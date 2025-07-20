import os
import time
import shutil
import subprocess
from pathlib import Path

# === CONFIGURATION ===
WATCH_FOLDER = Path.home() / "Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/01 - ORGANIZE"
DEST_FOLDER = Path.home() / "Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/03 - Assets/Sources"
POLL_INTERVAL = 5  # seconds

seen_files = set(os.listdir(WATCH_FOLDER))

def ask_user_macos(filename):
    """Use AppleScript to show a native dialog box on macOS."""
    script = f'''
    display dialog "Do you want to move this to your Sources folder?\\n\\n{filename}" buttons {{"No", "Yes"}} default button "Yes"
    '''
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    return "Yes" in result.stdout

print(f"📂 Watching {WATCH_FOLDER} for new PDFs...")

try:
    while True:
        time.sleep(POLL_INTERVAL)
        current_files = set(os.listdir(WATCH_FOLDER))
        new_files = current_files - seen_files

        for filename in new_files:
            if filename.lower().endswith(".pdf"):
                full_path = WATCH_FOLDER / filename

                if ask_user_macos(filename):
                    try:
                        DEST_FOLDER.mkdir(parents=True, exist_ok=True)
                        shutil.move(str(full_path), str(DEST_FOLDER / filename))
                        print(f"✅ Moved: {filename}")
                    except Exception as e:
                        print(f"❌ Error moving file: {e}")
                else:
                    print(f"⏩ Skipped: {filename}")

        seen_files = current_files

except KeyboardInterrupt:
    print("\n👋 Watcher stopped.")
