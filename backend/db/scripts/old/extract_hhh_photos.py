#!/usr/bin/env python3
"""
Extract 'Photo of household head' images from PAH survey PDFs.

Outputs:
  - Images saved to backend/static/hhh_photos/ as PAH{pah}_{uuid}.{ext}
  - backend/db/scripts/002_hhh_photos.sql with UPDATE statements (run separately on production)
"""

import os
import re
import glob
import uuid

import fitz  # PyMuPDF

PDF_DIR = "/mnt/c/Users/Andy Fleming/Western Power Company/WPC Working - Documents/TEN Environmental and Social/E.45 RAP/RAP Survey Forms/Socio-Asset Forms"
OUTPUT_DIR = "/home/andy/ngonye_rap/backend/static/hhh_photos"
SQL_OUTPUT = "/home/andy/ngonye_rap/backend/db/scripts/002_hhh_photos.sql"

TARGET_TEXT = "photo of household head"
# Vertical search window in PDF points (72 pts = 1 inch). 300 pts ≈ 4 inches.
Y_SEARCH_WINDOW = 300

EXT_MAP = {
    "jpeg": "jpg", "jpg": "jpg", "png": "png",
    "jp2": "jp2", "jxr": "jxr",
    "pnm": "jpg", "pgm": "jpg", "ppm": "jpg", "pbm": "jpg",
}


def extract_pah(filename: str):
    stem = os.path.splitext(os.path.basename(filename))[0]
    m = re.match(r"^PAH\s+(\d+)", stem, re.IGNORECASE)
    if not m:
        return None
    return m.group(1).zfill(3)


def _best_image_below(page, text_y1, doc):
    """Return extracted image dict for the image closest below text_y1 on page."""
    page_images = page.get_images(full=True)
    if not page_images:
        return None

    # Build list of (top_y, xref) for each image using get_image_rects
    positioned = []
    for img_info in page_images:
        xref = img_info[0]
        rects = page.get_image_rects(xref)
        for rect in rects:
            if rect.y0 >= text_y1 and rect.y0 <= text_y1 + Y_SEARCH_WINDOW:
                positioned.append((rect.y0, xref))

    if positioned:
        positioned.sort(key=lambda x: x[0])
        return doc.extract_image(positioned[0][1])

    # Fallback: any image on the page below the text (no window limit)
    below = []
    for img_info in page_images:
        xref = img_info[0]
        rects = page.get_image_rects(xref)
        for rect in rects:
            if rect.y0 >= text_y1:
                below.append((rect.y0, xref))
    if below:
        below.sort(key=lambda x: x[0])
        return doc.extract_image(below[0][1])

    # Last resort: only one image on page, assume it's the one
    if len(page_images) == 1:
        return doc.extract_image(page_images[0][0])

    return None


def find_hhh_image(doc):
    for page_num in range(len(doc)):
        page = doc[page_num]
        # Only text blocks needed for label search; images are accessed via get_images()
        text_blocks = [b for b in page.get_text("blocks") if b[6] == 0]

        text_match = None
        for b in text_blocks:
            if TARGET_TEXT in b[4].lower():
                text_match = b
                break

        if text_match is None:
            continue

        text_y1 = text_match[3]

        # Same-page: find image below the matching text
        result = _best_image_below(page, text_y1, doc)
        if result:
            return result

        # Cross-page fallback: text near page bottom → try top of next page
        page_height = page.rect.height
        if text_y1 > page_height * 0.8 and page_num + 1 < len(doc):
            next_page = doc[page_num + 1]
            result = _best_image_below(next_page, -1, doc)  # -1 = any y
            if result:
                return result

    return None


def make_filename(pah: str, ext: str) -> str:
    short_uid = str(uuid.uuid4()).split("-")[0]
    return f"PAH{pah}_{short_uid}.{ext}"


def write_sql(results: list):
    lines = ["begin;\n\n"]
    for pah, filename in results:
        lines.append(
            f"UPDATE public.person\n"
            f"  SET photo_file = '{filename}'\n"
            f"  WHERE household_head = true\n"
            f"    AND pah = '{pah}';\n\n"
        )
    lines.append("commit;\n")
    with open(SQL_OUTPUT, "w") as f:
        f.writelines(lines)
    print(f"\nSQL written → {SQL_OUTPUT}")


def main():
    pdf_files = sorted(glob.glob(os.path.join(PDF_DIR, "PAH *_socio_asset.pdf")))
    if not pdf_files:
        print(f"No PDFs found in:\n  {PDF_DIR}")
        return

    print(f"Found {len(pdf_files)} PDFs\n")
    results = []
    skipped = []

    for pdf_path in pdf_files:
        pah = extract_pah(pdf_path)
        if pah is None:
            skipped.append((os.path.basename(pdf_path), "Could not parse PAH from filename"))
            continue

        try:
            doc = fitz.open(pdf_path)
        except Exception as e:
            skipped.append((pah, f"Could not open PDF: {e}"))
            print(f"  SKIP  PAH {pah}: {e}")
            continue

        img_dict = find_hhh_image(doc)
        doc.close()

        if img_dict is None:
            skipped.append((pah, "Photo of household head not found"))
            print(f"  SKIP  PAH {pah}: target photo not found")
            continue

        ext = EXT_MAP.get(img_dict.get("ext", "jpg").lower(), "jpg")
        filename = make_filename(pah, ext)
        out_path = os.path.join(OUTPUT_DIR, filename)

        try:
            with open(out_path, "wb") as f:
                f.write(img_dict["image"])
        except Exception as e:
            skipped.append((pah, f"Could not write image: {e}"))
            print(f"  SKIP  PAH {pah}: {e}")
            continue

        results.append((pah, filename))
        print(f"  OK    PAH {pah} → {filename}")

    write_sql(results)

    print(f"\nDone: {len(results)} extracted, {len(skipped)} skipped.")
    if skipped:
        print("\nSkipped:")
        for item, reason in skipped:
            print(f"  PAH {item}: {reason}")


if __name__ == "__main__":
    main()
