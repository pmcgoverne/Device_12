import os
import time
import subprocess

WATCH_FOLDER = "/Users/paulmcgovern/Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/03 - Assets/Sources"  # change this
POLL_INTERVAL = 5  # seconds

def open_in_zotero(file_path):
    try:
        subprocess.run(["open", "-a", "Zotero", file_path])  # macOS
        # On Windows use: subprocess.run(["start", "", file_path], shell=True)
        # On Linux use: subprocess.run(["xdg-open", file_path])
        print(f"Imported: {file_path}")
    except Exception as e:
        print(f"Error opening {file_path}: {e}")

def watch_folder():
    seen_files = set(os.listdir(WATCH_FOLDER))
    print("Watching for new PDFs in", WATCH_FOLDER)
    while True:
        time.sleep(POLL_INTERVAL)
        current_files = set(os.listdir(WATCH_FOLDER))
        new_files = current_files - seen_files
        for f in new_files:
            if f.lower().endswith(".pdf"):
                full_path = os.path.join(WATCH_FOLDER, f)
                open_in_zotero(full_path)
        seen_files = current_files

if __name__ == "__main__":
    watch_folder()
