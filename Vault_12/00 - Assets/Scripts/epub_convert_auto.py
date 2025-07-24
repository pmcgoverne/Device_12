import time
import os
import subprocess
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Change these to your desired paths
WATCH_DIRECTORY = "/Users/paulmcgovern/Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary/01 - ORGANIZE"

class EpubHandler(FileSystemEventHandler):
    def on_created(self, event):
        """Called when a file is created in the watched directory."""
        if not event.is_directory and event.src_path.lower().endswith(".epub"):
            self.convert_epub_to_pdf(event.src_path)

    def on_modified(self, event):
        """Called when a file is modified in the watched directory."""
        if not event.is_directory and event.src_path.lower().endswith(".epub"):
            self.convert_epub_to_pdf(event.src_path)

    def convert_epub_to_pdf(self, epub_file_path):
        """Convert an .epub file to a .pdf using ebook-convert."""
        pdf_file_path = os.path.splitext(epub_file_path)[0] + ".pdf"

        # Use Calibre's ebook-convert to perform the conversion
        try:
            print(f"Converting {epub_file_path} to PDF...")
            subprocess.run([
                "ebook-convert",
                epub_file_path,
                pdf_file_path,
                "--disable-font-rescaling",
                "--line-height", "0",
                "--chapter-mark", "none",
                "--embed-all-fonts",
                "--preserve-cover-aspect-ratio",
                "--pdf-page-numbers",
                "--pretty-print"
            ], check=True)
            print(f"Conversion successful: {pdf_file_path}")
        except subprocess.CalledProcessError as e:
            print(f"Error converting {epub_file_path} to PDF: {e}")

def main():
    event_handler = EpubHandler()
    observer = Observer()
    observer.schedule(event_handler, WATCH_DIRECTORY, recursive=False)

    # Start the observer
    observer.start()
    print(f"Watching directory: {WATCH_DIRECTORY} for new or modified EPUB files...")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()

if __name__ == "__main__":
    main()
