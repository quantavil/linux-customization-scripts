#!/usr/bin/env python3
import sys
import os
import fitz  # PyMuPDF
from collections import Counter

def get_body_size(doc):
    """
    Computes the most common font size in the document to establish a baseline body text size.
    """
    font_sizes = []
    for page in doc:
        try:
            blocks = page.get_text("dict").get("blocks", [])
        except Exception as e:
            print(f"Warning: Failed to retrieve text dict for body size computation: {e}", file=sys.stderr)
            continue
            
        for block in blocks:
            if "lines" in block:
                for line in block.get("lines", []):
                    for span in line.get("spans", []):
                        size = span.get("size")
                        if size is not None:
                            font_sizes.append(round(size, 1))
                            
    if font_sizes:
        size_counts = Counter(font_sizes)
        return size_counts.most_common(1)[0][0]
    return 10.0

def is_watermark_text(text):
    """
    Checks if the text looks like a watermark (email, URL, brand info, or copyright notice).
    """
    t_lower = text.lower().strip()
    if not t_lower:
        return True
    if "@" in t_lower:
        return True
    if "www." in t_lower or "http" in t_lower or ".in" in t_lower or ".com" in t_lower or ".org" in t_lower or ".net" in t_lower:
        return True
    # Common watermark terms (specifically targets Guidely PDF watermarks)
    watermark_keywords = [
        "subscribe", "subscription", "telegram", "guidely",
        "mock test", "all in one", "pdf course"
    ]
    if any(keyword in t_lower for keyword in watermark_keywords):
        return True
    return False

def find_heading_in_block(block, body_size):
    """
    Scans a block for a single heading line. Returns the joined text of the heading line if found, else None.
    """
    for line in block.get("lines", []):
        line_spans = line.get("spans", [])
        if not line_spans:
            continue
            
        max_size = max(span.get("size", 0.0) for span in line_spans)
        if round(max_size, 1) > body_size + 2.5:
            heading_text = "".join(span.get("text", "") for span in line_spans).strip()
            if len(heading_text) > 3 and not is_watermark_text(heading_text):
                return heading_text
    return None

def extract_metadata_and_toc(doc, body_size):
    """
    Extracts basic document metadata and generates a table of contents outline.
    """
    title = doc.metadata.get("title") or "Untitled Document"
    author = doc.metadata.get("author") or "Unknown Author"
    page_count = len(doc)
    
    # Try native TOC first
    try:
        native_toc = doc.get_toc()
    except Exception as e:
        print(f"Warning: Failed to retrieve native TOC: {e}", file=sys.stderr)
        native_toc = None
        
    toc_lines = []
    if native_toc:
        for lvl, title_text, pno in native_toc:
            indent = "  " * (lvl - 1)
            toc_lines.append(f"{indent}- [Page {pno}] {title_text}")
    else:
        # Fallback to font size heuristic
        for page_num in range(1, page_count + 1):
            page = doc[page_num - 1]
            try:
                blocks = page.get_text("dict").get("blocks", [])
            except Exception as e:
                print(f"Warning: Failed to retrieve text dict for TOC heuristic: {e}", file=sys.stderr)
                continue
            for block in blocks:
                heading_text = find_heading_in_block(block, body_size)
                if heading_text:
                    toc_lines.append(f"- [Page {page_num}] {heading_text}")
                    break  # Move to the next page once one heading is found
                        
    return title, author, page_count, toc_lines

def join_lines(lines_list):
    """
    Joins individual text lines back into paragraph blocks.
    Preserves line-ending hyphens for compound words (e.g. self-contained).
    """
    block_text = ""
    for part in lines_list:
        part_stripped = part.strip()
        if not part_stripped:
            continue
        if block_text:
            if block_text.endswith("-"):
                # Preserve the hyphen for compound words, joining directly
                block_text = block_text + part_stripped
            else:
                block_text += " " + part_stripped
        else:
            block_text = part_stripped
    return block_text

def format_table_markdown(table):
    """
    Formats a PyMuPDF Table object into a Github-Flavored Markdown table.
    Escapes literal pipe characters to prevent breaking markdown syntax.
    """
    try:
        data = table.extract()
    except Exception as e:
        print(f"Warning: Failed to extract table data: {e}", file=sys.stderr)
        return ""
        
    if not data or len(data) == 0:
        return ""
        
    headers = [str(x or "").replace("\n", " ").replace("|", "\\|").strip() for x in data[0]]
    rows = []
    for r in data[1:]:
        rows.append([str(x or "").replace("\n", " ").replace("|", "\\|").strip() for x in r])
        
    # Markdown construction
    md = "| " + " | ".join(headers) + " |\n"
    md += "| " + " | ".join(["---"] * len(headers)) + " |\n"
    for row in rows:
        md += "| " + " | ".join(row) + " |\n"
    return md

def detect_heading_level(line_spans, body_size):
    """
    Detects if the line represents a heading and returns a tuple (is_heading, h_level).
    is_heading is a boolean, and h_level is the level of heading (1 or 2).
    """
    if not line_spans:
        return False, 0
        
    line_text = "".join(span.get("text", "") for span in line_spans).strip()
    if is_watermark_text(line_text):
        return False, 0
        
    max_size = max(span.get("size", 0.0) for span in line_spans)
    
    # Calculate character bold ratio
    bold_chars = 0
    total_chars = 0
    for span in line_spans:
        text = span.get("text", "")
        font = span.get("font", "").lower()
        font_flags = span.get("flags", 0)
        
        # In PyMuPDF flags, bitmask 16 stands for Bold, bitmask 2 for Italic
        is_bold = "bold" in font or bool(font_flags & 16)
        
        bold_chars += len(text) if is_bold else 0
        total_chars += len(text)
        
    is_bold_line = total_chars > 0 and (bold_chars / total_chars) > 0.7
    
    if max_size >= body_size + 4.5:
        return True, 1
    elif max_size >= body_size + 1.5:
        return True, 2
    elif max_size >= body_size and is_bold_line and total_chars < 80:
        return True, 2
        
    return False, 0

def extract_page_content(page, body_size):
    """
    Extracts text blocks from a page, identifies headings, and structures them into markdown.
    """
    try:
        blocks = page.get_text("dict").get("blocks", [])
    except Exception as e:
        print(f"Warning: Failed to retrieve page text blocks: {e}", file=sys.stderr)
        return ""
        
    page_content = []
    for block in blocks:
        if block.get("type") == 0:  # text block
            block_lines = block.get("lines", [])
            if not block_lines:
                continue
            
            current_para = []
            for line in block_lines:
                line_spans = line.get("spans", [])
                if not line_spans:
                    continue
                    
                line_text = "".join(span.get("text", "") for span in line_spans).strip()
                if not line_text or is_watermark_text(line_text):
                    continue
                    
                is_heading, h_level = detect_heading_level(line_spans, body_size)
                
                if is_heading:
                    # Flush current paragraph first
                    if current_para:
                        text_to_add = join_lines(current_para)
                        if text_to_add:
                            page_content.append(text_to_add.strip())
                        current_para = []
                    
                    # Add heading
                    prefix = "#" * h_level
                    page_content.append(f"{prefix} {line_text}")
                else:
                    current_para.append(line_text)
                    
            # Flush any remaining paragraph lines in this block
            if current_para:
                text_to_add = join_lines(current_para)
                if text_to_add:
                    page_content.append(text_to_add.strip())
                    
    # Join page content blocks simply with double newlines
    cleaned_items = [item.strip() for item in page_content if item.strip()]
    return "\n\n".join(cleaned_items)

def parse_pdf(pdf_path, output_dir):
    """
    Parses the target PDF and generates structured outline.md and context.md files.
    """
    # 1. Input validations
    if not os.path.isfile(pdf_path):
        raise FileNotFoundError(f"PDF path '{pdf_path}' does not exist or is not a file.")
        
    # 2. Output directory setup
    try:
        os.makedirs(output_dir, exist_ok=True)
    except OSError as e:
        raise OSError(f"Failed to create output directory '{output_dir}': {e}")
        
    # 3. Open document and parse using context manager
    try:
        doc = fitz.open(pdf_path)
    except Exception as e:
        raise RuntimeError(f"Failed to open PDF file '{pdf_path}': {e}")
        
    with doc:
        page_count = len(doc)
        body_size = get_body_size(doc)
        
        # 4. Generate outline.md
        title, author, _, toc_lines = extract_metadata_and_toc(doc, body_size)
        outline_path = os.path.join(output_dir, "outline.md")
        try:
            with open(outline_path, "w", encoding="utf-8") as f:
                f.write(f"# {title}\n\n")
                f.write(f"**Pages**: {page_count} | **Author**: {author}\n\n")
                f.write("## Table of Contents\n\n")
                if toc_lines:
                    f.write("\n".join(toc_lines) + "\n")
                else:
                    f.write("*No table of contents could be generated.*\n")
                f.write("\n## Notes\n\n")
                f.write("- Full content is in `context.md` with page tags like `<!-- page: N -->`.\n")
                f.write("- Tables are formatted as markdown tables.\n")
        except OSError as e:
            raise OSError(f"Failed to write to outline file '{outline_path}': {e}")
            
        # 5. Generate context.md
        context_path = os.path.join(output_dir, "context.md")
        try:
            with open(context_path, "w", encoding="utf-8") as f:
                for page_num in range(1, page_count + 1):
                    page = doc[page_num - 1]
                    f.write(f"<!-- page: {page_num} -->\n")
                    f.write(f"# Page {page_num}\n\n")
                    
                    # Extract tables
                    table_markdowns = []
                    try:
                        tables = page.find_tables()
                        for table in tables:
                            md = format_table_markdown(table)
                            if md:
                                table_markdowns.append(md)
                    except Exception as e:
                        print(f"Warning: Failed to extract tables from page {page_num}: {e}", file=sys.stderr)
                        
                    # Extract plain text
                    text = extract_page_content(page, body_size)
                    if text:
                        f.write(text)
                        f.write("\n\n")
                        
                    if table_markdowns:
                        f.write("### Extracted Tables\n\n")
                        for tb_md in table_markdowns:
                            f.write(tb_md + "\n\n")
                            
                    f.write("---\n")
        except OSError as e:
            raise OSError(f"Failed to write to context file '{context_path}': {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: aikular_parser.py <pdf_path> <output_dir>")
        sys.exit(1)
        
    try:
        parse_pdf(sys.argv[1], sys.argv[2])
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
