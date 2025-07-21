#!/usr/bin/env python3
import time
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Set to your actual Downloads folder
DOWNLOADS_FOLDER = "/Users/paulmcgovern/Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/01 - ORGANIZE"
UNDERLINER_SCRIPT = "/Users/paulmcgovern/Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/03 - Assets/Scripts/underliner_auto.py"

class PDFHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory and event.src_path.lower().endswith(".pdf"):
            new_pdf = event.src_path
            print(f"New PDF detected: {new_pdf}")  # Debugging output

            # Run the Underliner script on the new PDF
            command = f'python "{UNDERLINER_SCRIPT}" "{new_pdf}"'
            print(f"Running command: {command}")  # Debugging output
            os.system(command)

if __name__ == "__main__":
    event_handler = PDFHandler()
    observer = Observer()
    observer.schedule(event_handler, DOWNLOADS_FOLDER, recursive=False)
    observer.start()
    print(f"Watching for new PDFs in: {DOWNLOADS_FOLDER}")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()
