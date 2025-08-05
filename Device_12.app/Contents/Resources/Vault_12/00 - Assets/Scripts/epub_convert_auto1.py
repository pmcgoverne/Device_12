import os
import time
import zipfile
import shutil
import subprocess
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

WATCH_DIRECTORY = "/path/to/your/watch/folder"  # <- UPDATE THIS
OUTPUT_DIRECTORY = WATCH_DIRECTORY  # PDFs will go here too

class EpubToPdfHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith(".epub") and not event.is_directory:
            self.convert_epub_to_pdf(event.src_path)

    def convert_epub_to_pdf(self, epub_path):
        epub_path = Path(epub_path)
        print(f"📘 Detected EPUB: {epub_path}")

        # 1. Make temp dir
        temp_dir = epub_path.with_suffix(".tempdir")
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        os.makedirs(temp_dir)

        # 2. Unzip EPUB
        try:
            with zipfile.ZipFile(epub_path, 'r') as zip_ref:
                zip_ref.extractall(temp_dir)
        except Exception as e:
            print(f"❌ Error unzipping EPUB: {e}")
            return

        # 3. Try to find main content file (naive but works for most EPUBs)
        html_candidates = list(temp_dir.rglob("*.xhtml")) + list(temp_dir.rglob("*.html"))
        if not html_candidates:
            print("❌ No HTML/XHTML content found in EPUB.")
            return

        main_html = html_candidates[0]
        print(f"📄 Using main file: {main_html}")

        # 4. Build output PDF path
        pdf_path = OUTPUT_DIRECTORY + "/" + epub_path.stem + ".pdf"

        # 5. Convert with wkhtmltopdf
        try:
            subprocess.run([
                "wkhtmltopdf",
                str(main_html),
                pdf_path
            ], check=True)
            print(f"✅ PDF created: {pdf_path}")
        except subprocess.CalledProcessError as e:
            print(f"❌ wkhtmltopdf failed: {e}")

        # 6. Clean up temp dir
        shutil.rmtree(temp_dir)

def main():
    observer = Observer()
    event_handler = EpubToPdfHandler()
    observer.schedule(event_handler, WATCH_DIRECTORY, recursive=False)
    observer.start()
    print(f"👀 Watching directory: {WATCH_DIRECTORY} for EPUB files...")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    main()
