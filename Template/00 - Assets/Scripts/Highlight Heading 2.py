import fitz  # PyMuPDF
from PIL import Image
from surya.layout import LayoutPredictor
import torch
import re
import argparse
from concurrent.futures import ThreadPoolExecutor


def _preprocess_page(args):
    """
    Rasterize a page, extract text spans, and compute scale factors.
    Returns (index, image, spans, (x_scale, y_scale)).
    """
    idx, page, zoom = args
    # Rasterize at given zoom
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

    # Scaling factors
    x_scale = page.rect.width / img.width
    y_scale = page.rect.height / img.height

    # Extract text spans for font-size and regex fallback
    spans = []
    for block in page.get_text("dict").get("blocks", []):
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                bbox = span.get("bbox")
                spans.append({
                    "rect": fitz.Rect(bbox),
                    "size": span.get("size", 0),
                    "text": span.get("text", "").strip(),
                })
    return idx, img, spans, (x_scale, y_scale)


def detect_and_highlight_headings(
    input_pdf_path: str,
    output_pdf_path: str,
    device: str = "cpu",
    zoom: float = 2.0,
    max_workers: int = 32,
):
    """
    Detects and highlights section headers across the PDF using concurrent preprocessing
    and batch layout inference for maximal efficiency.
    """
    # Open PDF and Surya predictor
    doc = fitz.open(input_pdf_path)
    predictor = LayoutPredictor(device=device)
    num_pages = len(doc)

    # Prepare containers
    images = [None] * num_pages
    spans_per_page = [None] * num_pages
    scales = [None] * num_pages

    # Regex for fallback
    heading_pattern = re.compile(r'^(?:Section|SECTION)\s+\d+', re.IGNORECASE)

    # Concurrent preprocessing: rasterize & extract spans
    pages = [doc[i] for i in range(num_pages)]
    tasks = [(i, pages[i], zoom) for i in range(num_pages)]
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        for idx, img, spans, scale in executor.map(_preprocess_page, tasks):
            images[idx] = img
            spans_per_page[idx] = spans
            scales[idx] = scale

    # Batch layout detection
    print(f"Running batch layout inference on {num_pages} pages...")
    layouts = predictor(images)

    # Collect all detected headers globally
    global_detected = []  # entries: {'page','rect','size'}

    # Surya detections
    for idx, layout in enumerate(layouts):
        spans = spans_per_page[idx]
        x_scale, y_scale = scales[idx]
        for box in layout.bboxes:
            if box.label == "SectionHeader":
                x0, y0 = box.polygon[0]
                x2, y2 = box.polygon[2]
                rect = fitz.Rect(x0 * x_scale, y0 * y_scale,
                                 x2 * x_scale, y2 * y_scale)
                sizes = [s["size"] for s in spans if rect.intersects(s["rect"])]
                avg_size = sum(sizes) / len(sizes) if sizes else 0
                global_detected.append({"page": idx, "rect": rect, "size": avg_size})

    # Regex fallback detections
    for idx in range(num_pages):
        page = pages[idx]
        spans = spans_per_page[idx]
        x_scale, y_scale = scales[idx]
        for block in page.get_text("dict").get("blocks", []):
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                text_line = "".join(s.get("text", "") for s in line.get("spans", [])).strip()
                if heading_pattern.match(text_line):
                    coords = [s["bbox"] for s in line.get("spans", [])]
                    x0s, y0s, x1s, y1s = zip(*coords)
                    r = fitz.Rect(min(x0s), min(y0s), max(x1s), max(y1s))
                    rect = fitz.Rect(r.x0 * x_scale, r.y0 * y_scale,
                                     r.x1 * x_scale, r.y1 * y_scale)
                    if not any(d["page"] == idx and d["rect"].intersects(rect)
                               for d in global_detected):
                        max_size = max((s.get("size", 0) for s in line.get("spans", [])), default=0)
                        global_detected.append({"page": idx, "rect": rect, "size": max_size})

    if not global_detected:
        print("No section headers detected in document.")
        return

    # Determine global hierarchy levels by font-size ranking
    unique_sizes = sorted({d["size"] for d in global_detected}, reverse=True)
    size_to_level = {size: lvl for lvl, size in enumerate(unique_sizes)}

    # Color palette
    palette = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 0, 1), (1, 1, 0), (0, 1, 1)]

    # Annotate PDF
    summary = {}
    for item in global_detected:
        lvl = size_to_level[item["size"]]
        color = palette[lvl % len(palette)]
        page = doc[item["page"]]
        annot = page.add_rect_annot(item["rect"])
        annot.set_colors(stroke=color, fill=color)
        annot.set_opacity(0.3)
        annot.update()
        summary[item["page"]] = summary.get(item["page"], 0) + 1

    # Summary print
    for pg, cnt in sorted(summary.items()):
        print(f"Highlighted {cnt} headers on page {pg+1}.")

    # Save PDF
    doc.save(output_pdf_path, garbage=4, deflate=True)
    print(f"Done! Total headers highlighted: {len(global_detected)}")
    print(f"Annotated PDF written to {output_pdf_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Concurrent, batch-based highlighting of section headers."
    )
    parser.add_argument("input_pdf", help="Path to input PDF")
    parser.add_argument("output_pdf", help="Path to annotated output")
    parser.add_argument(
        "--device",
        choices=["cpu", "cuda", "mps", "xla"],
        default=(
            "cuda" if torch.cuda.is_available() else
            "mps"  if torch.backends.mps.is_available() else
            "cpu"
        ))
    parser.add_argument("--zoom", type=float, default=2.0, help="Rasterization zoom (lower = faster)")
    parser.add_argument("--max-workers", type=int, default=None,
                        help="Threads for preprocessing (defaults to CPU count)")
    args = parser.parse_args()
    detect_and_highlight_headings(
        args.input_pdf,
        args.output_pdf,
        device=args.device,
        zoom=args.zoom,
        max_workers=args.max_workers,
    )
