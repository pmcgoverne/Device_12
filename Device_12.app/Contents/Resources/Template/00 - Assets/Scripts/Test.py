#!/usr/bin/env python
"""
Pick a PDF with a GUI dialog, verify that the bytes your script will read
match the raw file on disk, then open it with PyMuPDF.

Requires only the standard library plus PyMuPDF (pip install pymupdf).
"""

from __future__ import annotations

import hashlib
import pathlib
import sys
import tkinter as tk
from tkinter import filedialog, messagebox

import fitz  # PyMuPDF


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def choose_file() -> pathlib.Path | None:
    root = tk.Tk()
    root.withdraw()                       # hide the root window
    path = filedialog.askopenfilename(
        title="Select a PDF",
        filetypes=[("PDF files", "*.pdf")],
    )
    root.destroy()
    return pathlib.Path(path) if path else None


def verify_and_open(path: pathlib.Path) -> None:
    raw = path.read_bytes()
    raw_digest = md5(raw)

    with path.open("rb") as f:            # how your code will read it
        stream = f.read()
    stream_digest = md5(stream)

    if stream_digest != raw_digest:
        raise ValueError(
            f"Byte mismatch detected:\n"
            f"  on‑disk:  {raw_digest}\n"
            f"  in‑code:  {stream_digest}"
        )

    doc = fitz.open(stream=stream, filetype="pdf")
    messagebox.showinfo(
        "Success",
        f"{path.name} opened successfully — {doc.page_count} pages",
    )
    doc.close()


def main() -> None:
    path = choose_file()
    if path is None:
        sys.exit("No file selected — exiting.")

    try:
        verify_and_open(path)
    except (fitz.FileDataError, ValueError, OSError) as err:
        messagebox.showerror("Error", str(err))
        sys.exit(1)


if __name__ == "__main__":
    main()
