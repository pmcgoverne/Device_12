#!/usr/bin/env python3
import argparse
import fitz           # PyMuPDF
import torch
from PIL import Image
from tqdm import tqdm
from surya.layout import LayoutPredictor

def hex_to_rgb01(hex_code: str) -> tuple[float, float, float]:
    """
    Convert a hex color (“#RRGGBB” or “RRGGBB”) into a (r, g, b) tuple
    with values in [0.0, 1.0].
    """
    h = hex_code.lstrip("#")
    if len(h) != 6:
        raise ValueError(f"Invalid hex color: {hex_code}")
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def map_box_to_pdf(box, page, x_scale, y_scale):
    x0, y0 = box.polygon[0]
    x2, y2 = box.polygon[2]
    return fitz.Rect(x0 * x_scale, y0 * y_scale, x2 * x_scale, y2 * y_scale)

def main():
    parser = argparse.ArgumentParser(
        description="Highlight every Surya layout box with a distinct color per label."
    )
    parser.add_argument(
        "input_pdf", help="Path to the source PDF"
    )
    parser.add_argument(
        "output_pdf", help="Path to save the annotated PDF"
    )
    parser.add_argument(
        "--device",
        choices=["cpu", "cuda", "mps", "xla"],
        default=(
            "cuda" if torch.cuda.is_available() else
            "mps"  if torch.backends.mps.is_available() else
            "cpu"
        ),
        help="Torch device to run Surya on"
    )
    parser.add_argument(
        "--zoom",
        type=float,
        default=2.0,
        help="Rasterization zoom factor (higher → finer detection, slower)"
    )
    args = parser.parse_args()

    # initialize Surya
    print(f"Using device: {args.device}")
    predictor = LayoutPredictor(device=args.device)
    torch.backends.cudnn.benchmark = True

    # open PDF
    doc = fitz.open(args.input_pdf)
    num_pages = len(doc)

    # 1) rasterize all pages & record scales
    pages = []
    for page in tqdm(doc, desc="Rasterizing pages", unit="page"):
        mat = fitz.Matrix(args.zoom, args.zoom)
        pix = page.get_pixmap(matrix=mat)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        pages.append({
            "page": page,
            "img": img,
            "x_scale": page.rect.width / img.width,
            "y_scale": page.rect.height / img.height,
        })

    # 2) batch layout inference
    print(f"Running batch layout inference on {num_pages} pages…")
    images = [p["img"] for p in pages]
    with torch.inference_mode():
        if args.device.startswith("cuda"):
            with torch.cuda.amp.autocast():
                layouts = predictor(images)
        else:
            layouts = predictor(images)

    # 3) collect all labels
    labels = set()
    for layout in layouts:
        for box in layout.bboxes:
            labels.add(box.label)
    labels = sorted(labels)
    print("Detected labels:", labels)

    # 4) prepare a palette of hex colors (extend or cycle as needed)
    palette_hex = [
        "#e6194b", "#3cb44b", "#4363d8", "#f58231",
        "#911eb4", "#46f0f0", "#f032e6", "#bcf60c",
        "#fabebe", "#008080", "#e6beff", "#9a6324"
    ]
    # map each label to a color
    label_to_color = {
        label: hex_to_rgb01(palette_hex[i % len(palette_hex)])
        for i, label in enumerate(labels)
    }

    # 5) annotate each box
    for p, layout in tqdm(zip(pages, layouts),
                          total=num_pages,
                          desc="Annotating boxes", unit="page"):
        page = p["page"]
        xs, ys = p["x_scale"], p["y_scale"]
        for box in layout.bboxes:
            rect = map_box_to_pdf(box, page, xs, ys)
            color = label_to_color.get(box.label, (1, 1, 1))
            annot = page.add_rect_annot(rect)
            annot.set_colors(stroke=color, fill=color)
            annot.set_opacity(0.2)
            annot.set_info(title=box.label)  # stash the label here
            annot.update()


    # 6) save annotated PDF
    doc.save(args.output_pdf, garbage=4, deflate=True)
    print(f"Saved annotated PDF to {args.output_pdf}")

if __name__ == "__main__":
    main()
