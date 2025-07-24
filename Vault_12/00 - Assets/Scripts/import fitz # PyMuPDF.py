import tkinter as tk
from tkinter import filedialog
import fitz  # PyMuPDF
import re
import os
from tqdm import tqdm
import nltk
from nltk.corpus import names

# Download NLTK names dataset if not already downloaded
nltk.download('names')

# Load list of common male and female names from NLTK
valid_first_names = set(names.words())

# Define custom underline color (normalized RGB for #a28ae5)
custom_color = (162 / 255, 138 / 255, 229 / 255)

# Function to extract text from the PDF
def extract_text_from_pdf(pdf_input_path):
    text = ""
    doc = fitz.open(pdf_input_path)

    # Progress bar
    pbar = tqdm(total=len(doc), desc="Extracting text", unit="page")

    for page_num in range(len(doc)):
        page = doc[page_num]
        text += page.get_text()
        pbar.update(1)

    pbar.close()
    return text

# Function to extract names using regex and validate using NLTK's name list
def extract_names(text):
    # Regex pattern for names (First Last or First M. Last)
    name_pattern = re.compile(
        r'\b([A-Z][a-z]+(?:\s[A-Z][a-z]+|(?:\s[A-Z]\.)?(?:\s[A-Z][a-z]+)))\b'
    )
    raw_names = set(re.findall(name_pattern, text))

    # Validate extracted names using NLTK's list of common names
    filtered_names = {
        name for name in raw_names
        if name.split()[0] in valid_first_names
    }
    return list(filtered_names)

# Function to underline detected names in the PDF
def underline_names_in_pdf(pdf_input_path, pdf_output_path, names_to_underline):
    doc = fitz.open(pdf_input_path)

    # Prepare progress bar
    pbar = tqdm(total=len(doc), desc="Underlining names", unit="page")

    for page_index in range(len(doc)):
        page = doc[page_index]

        # Get all words on the page
        all_words_on_page = page.get_text("words")

        if not all_words_on_page:
            pbar.update(1)
            continue  # Skip empty pages

        # Loop through words and underline matched names
        for word in all_words_on_page:
            x0, y0, x1, y1, text, *_ = word  # Extract word coordinates and text

            # Check if the word matches any of the names
            for name in names_to_underline:
                if text.strip() in name.split():  # Partial matching for multi-word names
                    underline_rect = fitz.Rect(x0, y0, x1, y1)

                    # Add underline annotation with custom color
                    underline_annot = page.add_underline_annot(underline_rect)
                    underline_annot.set_colors(stroke=custom_color)
                    underline_annot.update()

        pbar.update(1)

    pbar.close()
    doc.save(pdf_output_path, garbage=4, deflate=True)
    print(f"Output saved to: {pdf_output_path}")

# Main execution block
if __name__ == "__main__":
    # Use Tkinter to prompt for the PDF file
    root = tk.Tk()
    root.withdraw()  # Hide the main Tkinter window

    pdf_input_path = filedialog.askopenfilename(
        filetypes=[("PDF files", "*.pdf")],
        title="Select a PDF file to extract and underline names"
    )

    if not pdf_input_path:
        print("No file chosen. Exiting.")
    else:
        # Extract text from the PDF
        print(f"Selected file: {pdf_input_path}")
        extracted_text = extract_text_from_pdf(pdf_input_path)

        if not extracted_text.strip():
            print("No readable text found in the PDF. It might be scanned or encrypted.")
        else:
            # Extract names
            extracted_names = extract_names(extracted_text)

            if extracted_names:
                base, ext = os.path.splitext(pdf_input_path)
                pdf_output_path = base + "_underlined_names" + ext

                # Underline the names in the PDF
                underline_names_in_pdf(pdf_input_path, pdf_output_path, extracted_names)
            else:
                print("No valid names found in the PDF.")
