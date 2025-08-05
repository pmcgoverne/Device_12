#!/usr/bin/env python3
import argparse
import re

import fitz  # PyMuPDF
import torch
from PIL import Image
from tqdm import tqdm
from surya.layout import LayoutPredictor


def hex_to_rgb01(hex_code: str) -> tuple[float, float, float]:
    h = hex_code.lstrip("#")
    r = int(h[0:2], 16) / 255.0
    g = int(h[2:4], 16) / 255.0
    b = int(h[4:6], 16) / 255.0
    return (r, g, b)


def extract_text_spans(page):
    spans = []
    for block in page.get_text("dict")["blocks"]:
        if block["type"] != 0:
            continue
        for line in block["lines"]:
            for span in line["spans"]:
                spans.append({
                    "rect": fitz.Rect(span["bbox"]),
                    "size": span["size"],
                })
    return spans


def map_box_to_pdf(box, page, x_scale, y_scale):
    x0, y0 = box.polygon[0]
    x2, y2 = box.polygon[2]
    return fitz.Rect(x0 * x_scale, y0 * y_scale,
                     x2 * x_scale, y2 * y_scale)


def main():
    parser = argparse.ArgumentParser(
        description="Highlight SectionHeaders, skipping anything in the common header/footer bands."
    )
    parser.add_argument("input_pdf", help="Source PDF")
    parser.add_argument("output_pdf", help="Annotated PDF output")
    parser.add_argument(
        "--device",
        choices=["cpu", "cuda", "mps", "xla"],
        default=(
            "cuda" if torch.cuda.is_available() else
            "mps"  if torch.backends.mps.is_available() else
            "cpu"
        ),
    )
    parser.add_argument("--zoom", type=float, default=2.0,
                        help="Rasterization zoom factor")
    args = parser.parse_args()

    # 1) Load and rasterize pages
    print(f"Using device: {args.device}")
    predictor = LayoutPredictor(device=args.device)
    torch.backends.cudnn.benchmark = True

    doc = fitz.open(args.input_pdf)
    num_pages = len(doc)
    page_data = []
    for page in tqdm(doc, desc="Rasterizing pages", unit="page"):
        pix = page.get_pixmap(matrix=fitz.Matrix(args.zoom, args.zoom))
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        page_data.append({
            "page": page,
            "img": img,
            "x_scale": page.rect.width  / img.width,
            "y_scale": page.rect.height / img.height,
        })

    # 2) Batch layout inference
    print(f"Running batch layout inference on {num_pages} pages…")
    images = [d["img"] for d in page_data]
    with torch.inference_mode():
        if args.device.startswith("cuda"):
            with torch.cuda.amp.autocast():
                layouts = predictor(images)
        else:
            layouts = predictor(images)

    # 3) Determine common header/footer bands
    header_bottoms = []
    footer_tops = []
    for d, layout in zip(page_data, layouts):
        page = d["page"]
        xs, ys = d["x_scale"], d["y_scale"]
        for box in layout.bboxes:
            if box.label == "PageHeader":
                r = map_box_to_pdf(box, page, xs, ys)
                header_bottoms.append(r.y1)
            elif box.label == "PageFooter":
                r = map_box_to_pdf(box, page, xs, ys)
                footer_tops.append(r.y0)
    if header_bottoms:
        common_header_y = max(header_bottoms)
    else:
        common_header_y = 0
    if footer_tops:
        common_footer_y = min(footer_tops)
    else:
        common_footer_y = doc[0].rect.height

    # 4) Collect SectionHeader entries, skipping those in header/footer bands
    heading_entries = []
    for d, layout in tqdm(zip(page_data, layouts),
                          total=num_pages,
                          desc="Collecting SectionHeaders"):
        page = d["page"]
        xs, ys = d["x_scale"], d["y_scale"]
        spans = extract_text_spans(page)

        for box in layout.bboxes:
            if box.label != "SectionHeader":
                continue
            rect = map_box_to_pdf(box, page, xs, ys)

            # skip if it lies within the common header band
            if rect.y1 <= common_header_y:
                continue
            # skip if it lies within the common footer band
            if rect.y0 >= common_footer_y:
                continue

            # compute avg font size for level ranking
            sizes = [s["size"] for s in spans if rect.intersects(s["rect"])]
            avg_size = (sum(sizes)/len(sizes)) if sizes else 0
            heading_entries.append({
                "page": page,
                "rect": rect,
                "font_size": avg_size,
            })

    # 5) Global ranking of font_size → level
    unique_sizes = sorted({h["font_size"] for h in heading_entries},
                          reverse=True)
    size_to_level = {size: idx for idx, size in enumerate(unique_sizes)}

    # 6) Annotate with a simple hex palette
    palette_hex = [
        "#000000",  #
        "#404040",  ##
        "#808080",  ###
        "#999999",  ####
        "#a0a0a0",  #####
    ]    
    palette = [hex_to_rgb01(hx) for hx in palette_hex]

    for h in tqdm(heading_entries, desc="Annotating headers", unit="hdr"):
        lvl = size_to_level[h["font_size"]]
        color = palette[lvl % len(palette)]
        ann = h["page"].add_rect_annot(h["rect"])
        ann.set_colors(stroke=color, fill=color)
        ann.set_opacity(0.3)
        ann.update()

    # 7) Save
    doc.save(args.output_pdf, garbage=4, deflate=True)
    print(f"Done — highlighted {len(heading_entries)} headers.")
    print(f"Written to {args.output_pdf}")


if __name__ == "__main__":
    main()
