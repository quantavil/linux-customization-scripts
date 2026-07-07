#!/usr/bin/env python3
"""Aikular PDF parser.

Extracts structured Markdown (outline.md + context.md) from a PDF and renders
PNG images of pages that carry visual information (figures, charts, scans,
vector diagrams) so an image-capable AI backend can read them directly by path.

Text-only pages stay lean text. Only pages that need eyes get a PNG, unless
--images all is passed.
"""
import sys
import os
import re
import argparse
import unicodedata
from dataclasses import dataclass, field
from collections import Counter

import fitz  # PyMuPDF

SOFT_HYPHEN = "\u00ad"

DOMAIN_RE = re.compile(r"\b[\w-]+\.(?:in|com|org|net|io|co)\b", re.IGNORECASE)
PAGE_OF_RE = re.compile(r"^page\s+\d+\s+of\s+\d+$", re.IGNORECASE)

WATERMARK_KEYWORDS = (
    "subscribe", "subscription", "telegram", "guidely",
    "mock test", "all in one", "pdf course", "topic-wise",
)

# Render tuning
DEFAULT_DPI = 150
MAX_EDGE_PX = 1800          # cap long edge so image-token cost stays sane
SPARSE_CHAR_LIMIT = 25      # below this a page is treated as image-only
IMAGE_AREA_FRAC = 0.12      # a raster covering >12% of the page is a real figure
VECTOR_DRAW_LIMIT = 25      # many vector paths implies a drawn chart/diagram
MIN_HEADING_LEN = 4


def norm(s):
    """NFKC-normalise and strip soft hyphens / ligature artefacts."""
    if not s:
        return ""
    return unicodedata.normalize("NFKC", s).replace(SOFT_HYPHEN, "")


@dataclass
class DocCtx:
    """Per-document parsing state. Passed explicitly so the parser is reentrant."""
    body_size: float = 10.0
    boilerplate: set = field(default_factory=set)


def get_body_size(doc):
    """Most common rounded font size across the document = baseline body size."""
    font_sizes = []
    for page in doc:
        try:
            blocks = page.get_text("dict").get("blocks", [])
        except Exception as e:
            print(f"Warning: body-size text dict failed on a page: {e}", file=sys.stderr)
            continue
        for block in blocks:
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    size = span.get("size")
                    if size is not None:
                        font_sizes.append(round(size, 1))
    if font_sizes:
        return Counter(font_sizes).most_common(1)[0][0]
    return 10.0


def detect_boilerplate(doc):
    """Text lines appearing on >40% of pages are headers/footers, not content."""
    line_page_count = Counter()
    page_count = len(doc)
    for page in doc:
        try:
            blocks = page.get_text("dict").get("blocks", [])
        except Exception:
            continue
        seen = set()
        for block in blocks:
            for line in block.get("lines", []):
                text = norm("".join(s.get("text", "") for s in line.get("spans", []))).strip()
                if text:
                    seen.add(text)
        for t in seen:
            line_page_count[t] += 1
    threshold = max(3, int(page_count * 0.4))
    return {t for t, c in line_page_count.items() if c >= threshold}


def line_text(line):
    return norm("".join(s.get("text", "") for s in line.get("spans", []))).strip()


def is_watermark_text(text, ctx):
    """True if the line is a watermark, promo link, boilerplate, or noise."""
    t = norm(text).strip()
    tl = t.lower()
    if not tl:
        return True
    if "@" in tl:
        return True
    if "http" in tl or "www." in tl or DOMAIN_RE.search(tl):
        return True
    if any(k in tl for k in WATERMARK_KEYWORDS):
        return True
    if PAGE_OF_RE.match(tl):
        return True
    if t in ctx.boilerplate:
        return True
    return False


def is_bold_span(span):
    return "bold" in span.get("font", "").lower() or bool(span.get("flags", 0) & 16)


def find_heading_in_block(block, ctx):
    """Return heading text found by font size, else None."""
    for line in block.get("lines", []):
        spans = line.get("spans", [])
        if not spans:
            continue
        max_size = max(s.get("size", 0.0) for s in spans)
        if round(max_size, 1) > ctx.body_size + 2.5:
            text = line_text(line)
            if len(text) > 3 and not is_watermark_text(text, ctx):
                return text
    return None


def find_first_bold_line(blocks, ctx):
    """Fallback for uniform-font PDFs: first non-watermark, mostly-bold line."""
    for block in blocks:
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            spans = line.get("spans", [])
            if not spans:
                continue
            text = line_text(line)
            if len(text) < MIN_HEADING_LEN or is_watermark_text(text, ctx):
                continue
            total = sum(len(s.get("text", "")) for s in spans)
            bold = sum(len(s.get("text", "")) for s in spans if is_bold_span(s))
            if total > 0 and bold / total > 0.7:
                return text
    return None


def detect_heading_level(spans, ctx):
    """Return (is_heading, level in {1,2})."""
    if not spans:
        return False, 0
    text = norm("".join(s.get("text", "") for s in spans)).strip()
    if is_watermark_text(text, ctx):
        return False, 0

    max_size = max(s.get("size", 0.0) for s in spans)
    bold_chars = sum(len(s.get("text", "")) for s in spans if is_bold_span(s))
    total_chars = sum(len(s.get("text", "")) for s in spans)
    is_bold_line = total_chars > 0 and (bold_chars / total_chars) > 0.7

    if max_size >= ctx.body_size + 4.5:
        return True, 1
    if max_size >= ctx.body_size + 1.5:
        return True, 2
    if max_size >= ctx.body_size and is_bold_line and total_chars < 80:
        return True, 2
    return False, 0


def join_lines(parts):
    """Join wrapped lines into a paragraph, de-hyphenating soft line breaks.

    'informa-' + 'tion' -> 'information' (soft break, lowercase both sides).
    'well-' + 'Known'  -> 'well-Known'   (kept: proper noun boundary).
    """
    out = ""
    for part in parts:
        p = part.strip()
        if not p:
            continue
        if not out:
            out = p
            continue
        if out.endswith("-"):
            prev = out[:-1]
            if prev and prev[-1].isalpha() and prev[-1].islower() and p[:1].islower():
                out = prev + p          # de-hyphenate
            else:
                out = out + p           # keep hyphen (compound / proper noun / digit)
        else:
            out += " " + p
    return out


def get_table_objs(page):
    try:
        tf = page.find_tables()
    except Exception as e:
        print(f"Warning: find_tables failed: {e}", file=sys.stderr)
        return []
    if hasattr(tf, "tables"):
        return list(tf.tables)
    try:
        return list(tf)
    except Exception:
        return []


def format_table_markdown(table):
    """PyMuPDF Table -> GitHub-flavoured Markdown, escaping literal pipes."""
    try:
        data = table.extract()
    except Exception as e:
        print(f"Warning: table extract failed: {e}", file=sys.stderr)
        return ""
    if not data:
        return ""

    def cell(x):
        return norm(str(x or "")).replace("\n", " ").replace("|", "\\|").strip()

    headers = [cell(x) for x in data[0]]
    if not headers:
        return ""
    md = "| " + " | ".join(headers) + " |\n"
    md += "| " + " | ".join(["---"] * len(headers)) + " |\n"
    for row in data[1:]:
        md += "| " + " | ".join(cell(x) for x in row) + " |\n"
    return md


def extract_page_content(page, ctx, table_rects):
    """Structured Markdown text for a page. Lines inside table_rects are skipped
    (they are emitted separately as Markdown tables) to avoid duplication."""
    try:
        blocks = page.get_text("dict").get("blocks", [])
    except Exception as e:
        print(f"Warning: page text dict failed: {e}", file=sys.stderr)
        return ""

    text_blocks = [b for b in blocks if b.get("type") == 0]
    # Reading order: top-to-bottom, then left-to-right. Helps single-column PDFs.
    text_blocks.sort(key=lambda b: (round(b.get("bbox", [0, 0])[1]), round(b.get("bbox", [0, 0])[0])))

    out = []
    for block in text_blocks:
        para = []
        for line in block.get("lines", []):
            spans = line.get("spans", [])
            if not spans:
                continue
            try:
                lb = fitz.Rect(line["bbox"])
                if any(lb.intersects(r) for r in table_rects):
                    continue
            except Exception:
                pass

            txt = line_text(line)
            if not txt or is_watermark_text(txt, ctx):
                continue

            is_heading, level = detect_heading_level(spans, ctx)
            if is_heading:
                if para:
                    joined = join_lines(para).strip()
                    if joined:
                        out.append(joined)
                    para = []
                out.append(f"{'#' * level} {txt}")
            else:
                para.append(txt)

        if para:
            joined = join_lines(para).strip()
            if joined:
                out.append(joined)

    return "\n\n".join(i.strip() for i in out if i.strip())


def page_visual_stats(page):
    """Return (char_count, has_big_raster, n_vector_drawings)."""
    char_count = len(page.get_text("text").strip())
    page_area = abs(page.rect.width * page.rect.height) or 1.0

    has_big_raster = False
    try:
        for img in page.get_images(full=True):
            xref = img[0]
            try:
                rects = page.get_image_rects(xref)
            except Exception:
                rects = []
            if any(abs(r.width * r.height) / page_area > IMAGE_AREA_FRAC for r in rects):
                has_big_raster = True
                break
    except Exception:
        pass

    try:
        n_draw = len(page.get_drawings())
    except Exception:
        n_draw = 0

    return char_count, has_big_raster, n_draw


def should_render(stats):
    char_count, has_big_raster, n_draw = stats
    return char_count < SPARSE_CHAR_LIMIT or has_big_raster or n_draw >= VECTOR_DRAW_LIMIT


def render_page_png(page, out_path, dpi=DEFAULT_DPI, max_edge=MAX_EDGE_PX):
    """Render a page to PNG, capping the long edge to control token cost."""
    rect = page.rect
    long_pts = max(rect.width, rect.height) or 1.0
    target_dpi = min(dpi, max_edge * 72.0 / long_pts)
    zoom = target_dpi / 72.0
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)
    pix.save(out_path)
    return pix.width, pix.height


def extract_metadata_and_toc(doc, ctx):
    title = norm(doc.metadata.get("title") or "").replace("_", " ").strip() or "Untitled Document"
    author = norm(doc.metadata.get("author") or "").strip() or "Unknown Author"
    page_count = len(doc)

    try:
        native_toc = doc.get_toc()
    except Exception as e:
        print(f"Warning: native TOC failed: {e}", file=sys.stderr)
        native_toc = None

    toc_lines = []
    if native_toc:
        for lvl, title_text, pno in native_toc:
            toc_lines.append(f"{'  ' * (lvl - 1)}- [Page {pno}] {norm(title_text).strip()}")
    else:
        for page_num in range(1, page_count + 1):
            page = doc[page_num - 1]
            try:
                blocks = page.get_text("dict").get("blocks", [])
            except Exception as e:
                print(f"Warning: TOC heuristic text dict failed on page {page_num}: {e}", file=sys.stderr)
                continue
            heading = None
            for block in blocks:
                heading = find_heading_in_block(block, ctx)
                if heading:
                    break
            if not heading:
                heading = find_first_bold_line(blocks, ctx)
            if heading:
                toc_lines.append(f"- [Page {page_num}] {heading}")

    return title, author, page_count, toc_lines


def parse_pdf(pdf_path, output_dir, images_mode="auto", dpi=DEFAULT_DPI):
    if not os.path.isfile(pdf_path):
        raise FileNotFoundError(f"PDF path '{pdf_path}' does not exist or is not a file.")
    try:
        os.makedirs(output_dir, exist_ok=True)
    except OSError as e:
        raise OSError(f"Failed to create output directory '{output_dir}': {e}")

    try:
        doc = fitz.open(pdf_path)
    except Exception as e:
        raise RuntimeError(f"Failed to open PDF '{pdf_path}': {e}")

    with doc:
        if doc.needs_pass:
            if not doc.authenticate(""):
                raise RuntimeError(f"PDF '{pdf_path}' is encrypted and needs a password.")

        page_count = len(doc)
        ctx = DocCtx(body_size=get_body_size(doc), boilerplate=detect_boilerplate(doc))

        images_dir = os.path.join(output_dir, "images")
        # outline.md
        title, author, _, toc_lines = extract_metadata_and_toc(doc, ctx)
        outline_path = os.path.join(output_dir, "outline.md")
        try:
            with open(outline_path, "w", encoding="utf-8") as f:
                f.write(f"# {title}\n\n")
                f.write(f"**Pages**: {page_count} | **Author**: {author}\n\n")
                f.write("## Table of Contents\n\n")
                f.write(("\n".join(toc_lines) + "\n") if toc_lines
                        else "*No table of contents could be generated.*\n")
                f.write("\n## Notes\n\n")
                f.write("- Full text is in `context.md`, pages tagged `<!-- page: N -->`.\n")
                f.write("- Tables are Markdown tables.\n")
                f.write("- Visual pages (figures, charts, scans) reference an absolute PNG path.\n")
                f.write("  Read that PNG with your image/file read tool to see the page.\n")
                f.write("- The per-page chars/raster/draw counts are heuristic HINTS, not ground truth.\n")
                f.write("- To view ANY page (including ones with no PNG), run `aikular-render <pdf> <pages>`\n")
                f.write("  and read the path(s) it prints. Never assume a page is empty before rendering it.\n")
        except OSError as e:
            raise OSError(f"Failed to write outline '{outline_path}': {e}")

        # context.md
        context_path = os.path.join(output_dir, "context.md")
        rendered = 0
        try:
            with open(context_path, "w", encoding="utf-8") as f:
                for page_num in range(1, page_count + 1):
                    page = doc[page_num - 1]

                    tables = get_table_objs(page)
                    table_rects = []
                    for t in tables:
                        try:
                            table_rects.append(fitz.Rect(t.bbox))
                        except Exception:
                            pass

                    text = extract_page_content(page, ctx, table_rects)

                    stats = page_visual_stats(page)
                    if images_mode == "all":
                        do_render = True
                    elif images_mode == "none":
                        do_render = False
                    else:
                        do_render = should_render(stats)

                    png_abs = None
                    if do_render:
                        os.makedirs(images_dir, exist_ok=True)
                        png_abs = os.path.abspath(os.path.join(images_dir, f"page_{page_num:03d}.png"))
                        try:
                            render_page_png(page, png_abs, dpi=dpi)
                            rendered += 1
                        except Exception as e:
                            print(f"Warning: render failed page {page_num}: {e}", file=sys.stderr)
                            png_abs = None

                    char_count, has_raster, n_draw = stats
                    tag = "visual" if char_count < SPARSE_CHAR_LIMIT else ("has_figure" if png_abs else "text")
                    f.write(f"<!-- page: {page_num} | {tag} | chars={char_count} raster={int(has_raster)} draw={n_draw} -->\n")
                    f.write(f"# Page {page_num}\n\n")

                    if text:
                        f.write(text + "\n\n")

                    tbl_md = [format_table_markdown(t) for t in tables]
                    tbl_md = [m for m in tbl_md if m]
                    if tbl_md:
                        f.write("### Extracted Tables\n\n")
                        for m in tbl_md:
                            f.write(m + "\n\n")

                    if png_abs:
                        if char_count < SPARSE_CHAR_LIMIT:
                            note = "This page has little or no extractable text. Read its image directly:"
                        else:
                            note = "This page contains a figure/chart. Read its image if the question concerns the visual:"
                        f.write(f"*[{note}]*\n\n")
                        f.write(f"`{png_abs}`\n\n")

                    f.write("---\n")
        except OSError as e:
            raise OSError(f"Failed to write context '{context_path}': {e}")

        print(f"Parsed {page_count} pages, rendered {rendered} page image(s).", file=sys.stderr)


def main():
    p = argparse.ArgumentParser(description="Parse a PDF into outline.md + context.md with page renders.")
    p.add_argument("pdf_path")
    p.add_argument("output_dir")
    p.add_argument("--images", choices=["auto", "all", "none"], default="auto",
                   help="auto = render only visual pages (default); all = every page; none = text only.")
    p.add_argument("--dpi", type=int, default=DEFAULT_DPI)
    args = p.parse_args()
    try:
        parse_pdf(args.pdf_path, args.output_dir, images_mode=args.images, dpi=args.dpi)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
