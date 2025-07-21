import tkinter as tk
from tkinter import filedialog
import fitz
import os
from tqdm import tqdm

def underline_first_word_each_page(pdf_input_path, pdf_output_path,
                                   top_margin=50, bottom_margin=50,
                                   left_margin=50, right_margin=50):
    """
    Underlines the first word of each page TWICE:
    - A grey underline annotation.
    - A white underline annotation layered slightly above.

    Skips text too close to the page edges (headers/footers).
    """
    doc = fitz.open(pdf_input_path)

    # Define colors for underline (normalized RGB)
    grey_color = (170/255, 170/255, 170/255)  # Grey (#aaaaaa)
    white_color = (1, 1, 1)  # White (#ffffff)

    # Prepare progress bar
    pbar = tqdm(total=len(doc), desc="Processing pages", unit="page")

    for page_index in range(len(doc)):
        page = doc[page_index]
        page_width, page_height = page.rect.width, page.rect.height

        # Get all words on the page
        all_words_on_page = page.get_text("words")

        if not all_words_on_page:
            pbar.update(1)
            continue  # Skip empty pages

        # Sort words by their position: first by y (top to bottom), then by x (left to right)
        all_words_on_page.sort(key=lambda item: (item[1], item[0]))

        # Find the first word that is NOT in the margin areas
        first_valid_word = None
        for word in all_words_on_page:
            x0, y0, x1, y1, text, *_ = word  # Extract word coordinates and text
            
            # Check if the word falls outside margin areas
            if (y0 >= top_margin and y1 <= (page_height - bottom_margin) and
                x0 >= left_margin and x1 <= (page_width - right_margin)):
                first_valid_word = word
                break  # Stop at the first valid word

        if first_valid_word:
            x0, y0, x1, y1, text, *_ = first_valid_word
            underline_rect = fitz.Rect(x0, y0, x1, y1)

            # First underline annotation (grey)
            grey_underline_annot = page.add_underline_annot(underline_rect)
            grey_underline_annot.set_colors(stroke=grey_color)
            grey_underline_annot.update()

        pbar.update(1)

    pbar.close()
    doc.save(pdf_output_path, garbage=4, deflate=True)
    print(f"Output saved to: {pdf_output_path}")

if __name__ == "__main__":
    # Use Tkinter to prompt for the PDF file
    root = tk.Tk()
    root.withdraw()  # Hide the main Tkinter window

    pdf_input_path = filedialog.askopenfilename(
        filetypes=[("PDF files", "*.pdf")],
        title="Select a PDF file to underline the first word on each page"
    )

    if not pdf_input_path:
        print("No file chosen. Exiting.")
    else:
        base, ext = os.path.splitext(pdf_input_path)
        pdf_output_path = base + "_first_word_double_underlined" + ext

        underline_first_word_each_page(pdf_input_path, pdf_output_path)
