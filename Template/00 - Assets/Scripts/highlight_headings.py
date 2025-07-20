import fitz  # PyMuPDF
from PIL import Image
from surya.layout import LayoutPredictor

def detect_and_highlight_headings(
    input_pdf_path: str,
    output_pdf_path: str,
    device: str = "cpu",
    zoom: float = 2.0,
):
    """
    Detects headings in the PDF and highlights them with a translucent yellow box,
    while logging each detection and summarizing counts.
    """
    doc = fitz.open(input_pdf_path)
    predictor = LayoutPredictor(device=device)

    total_count = 0
    for page_number in range(len(doc)):
        page = doc[page_number]
        print(f"\n--- Page {page_number + 1} ---")
        # rasterize page
        mat = fitz.Matrix(zoom, zoom)
        pix = page.get_pixmap(matrix=mat)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        # detect layout
        layout = predictor([img])[0]

        label_counts = {}
        for box in layout.bboxes:
            label_counts[box.label] = label_counts.get(box.label, 0) + 1
        print("  Detected labels on page", page_number + 1, ":", label_counts)  
        page_count = 1

        for box in layout.bboxes:
            if box.label in {"SectionHeader"}:
                page_count += 1
                total_count += 1

                # log the detection
                x0, y0 = box.polygon[0]
                x2, y2 = box.polygon[2]
                print(f"  • Detected {box.label} at image coords "
                      f"({x0:.1f}, {y0:.1f}) – ({x2:.1f}, {y2:.1f})")

                # map to PDF coords
                x_scale = page.rect.width  / img.width
                y_scale = page.rect.height / img.height
                rect = fitz.Rect(
                    x0 * x_scale,
                    y0 * y_scale,
                    x2 * x_scale,
                    y2 * y_scale,
                )

                # draw annotation
                annot = page.add_rect_annot(rect)
                annot.set_colors(stroke=(1, 1, 0), fill=(1, 1, 0))
                annot.set_opacity(0.3)
                annot.update()

        print(f"  → Highlighted {page_count} headings on this page.")

    doc.save(output_pdf_path, garbage=4, deflate=True)
    print(f"\nDone! Total headings highlighted: {total_count}")
    print(f"Annotated PDF written to {output_pdf_path}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Detect headings in a PDF with Surya and highlight them."
    )
    parser.add_argument("input_pdf", help="Path to input PDF")
    parser.add_argument("output_pdf", help="Path to save highlighted PDF")
    parser.add_argument(
        "--device", default="cpu", help="Torch device (cpu or cuda)"
    )
    parser.add_argument(
        "--zoom", type=float, default=2.0,
        help="Zoom factor when rasterizing PDF pages"
    )
    args = parser.parse_args()

    detect_and_highlight_headings(
        args.input_pdf,
        args.output_pdf,
        device=args.device,
        zoom=args.zoom,
    )
