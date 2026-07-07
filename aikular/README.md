# Aikular: Okular & AI PDF Analysis Pipeline

Aikular is a local productivity pipeline that pairs the **Okular** PDF reader with CLI AI assistants like **agy** (`antigravity-cli`) or **opencode**. Right-click any PDF in Dolphin (or launch from the terminal) and it extracts structural page text into clean Markdown, formats tables, and strips repeating promotional watermarks, email stamps and branding links.

Crucially, `agy` and `opencode` can read **images** directly but cannot read PDFs. So for any page that carries visual information (a figure, chart, table image, scanned page, or a chart drawn as vector paths), Aikular renders a PNG and drops its absolute path into `context.md`. The AI reads that PNG with its own image-read tool. No OCR needed: a multimodal backend reading the page render *is* OCR, plus diagram and chart comprehension for free.

Okular opens for human reference side-by-side with a **Ghostty** terminal running the selected AI assistant, pre-seeded with the document context map.

---

## How the visual handling works

During parsing, each page is classified:

- **text** — enough extractable text, no significant figure. Text only, no render.
- **has_figure** — good text *and* a large raster image or a dense vector drawing. Text plus a rendered PNG.
- **visual** — little or no extractable text (scan or full-page figure). Rendered PNG, flagged so the AI reads the image instead of assuming the page is empty.

A page is rendered when any of these hold: extractable characters `< 25`, a single raster image covers `> 12%` of the page, or the page has `>= 25` vector drawing ops. Renders are capped at a 1800 px long edge to keep image-token cost sane, and cached under `<cache>/images/page_NNN.png`.

This parse-time classification is a **hint, not ground truth**. It will sometimes miss a figure or misjudge a page. So the AI is not limited to the pre-rendered set: it can rasterise any page on demand with `aikular-render` (below) and read the result. The seed prompt instructs it to render a page rather than ever claim a page is empty.

In `context.md` each page is tagged, e.g.:

```
<!-- page: 12 | visual | chars=6 raster=1 draw=54 -->
```

and visual pages carry an absolute PNG path the backend opens directly.

---

## File Directory

```
aikular/
├── aikular           # Launcher orchestrator (Bash)
├── aikular_parser.py # PDF-to-Markdown parser, watermark filter, page renderer
├── aikular-render    # On-demand page-to-PNG tool the AI calls itself
├── aikular-clean     # Cache cleanup (Bash)
├── aikular.desktop   # Dolphin right-click context menu integration
└── README.md         # This manual
```

---

## System Installation

### 1. Ensure `~/.local/bin` is in your Fish PATH
```bash
fish_add_path ~/.local/bin
```

### 2. Install the PyMuPDF dependency
The parser needs PyMuPDF (imports as `fitz`):
```bash
# Arch / CachyOS
sudo pacman -S python-pymupdf
# or, per-user
pip install --user pymupdf
```

### 3. Copy files to local paths
```bash
cp aikular aikular_parser.py aikular-render aikular-clean ~/.local/bin/
mkdir -p ~/.local/share/kio/servicemenus/
cp aikular.desktop ~/.local/share/kio/servicemenus/
```

### 4. Grant executable permissions
```bash
chmod +x ~/.local/bin/aikular ~/.local/bin/aikular_parser.py \
         ~/.local/bin/aikular-render ~/.local/bin/aikular-clean
chmod +x ~/.local/share/kio/servicemenus/aikular.desktop
```

### 5. Rebuild the KDE Sycoca cache
```bash
kbuildsycoca6
```

---

## How to Use

### A. Graphical (Dolphin)
Right-click any PDF, choose **Open with Aikular**. Okular launches in the background; Ghostty launches a terminal running the selected backend, connected to your parsed context.

### B. Terminal (Fish shell)
```bash
# Standard: parse if needed, render only visual pages, open Okular + terminal
aikular /path/to/document.pdf

# Force re-parse (clears cache first)
aikular --refresh /path/to/document.pdf

# Render EVERY page to PNG (lets the AI eyeball any page)
aikular --images /path/to/document.pdf

# Skip all rendering (text only, smallest cache)
aikular --no-images /path/to/document.pdf
```

Changing `--images` / `--no-images` on an already-cached PDF requires `--refresh` to take effect.

### C. On-demand page rendering (the AI, or you)
The AI calls this itself when it needs to see a page, so a wrong parse-time guess is never a dead end. It writes into the same cache images folder and prints the PNG path(s):
```bash
aikular-render /path/to/document.pdf 12          # single page
aikular-render /path/to/document.pdf 12,14,20     # several
aikular-render /path/to/document.pdf 12-15        # range
aikular-render /path/to/document.pdf all          # every page
# zoom into a region (PDF points), sharper:
aikular-render /path/to/document.pdf 12 --bbox 60,400,540,700 --dpi 220
```
Cropped renders are saved as `page_NNN_crop.png` so they never clobber the full-page render.

### D. Cleaning the cache
```bash
aikular --clean /path/to/document.pdf
# or directly
aikular-clean /path/to/document.pdf
aikular-clean /path/to/directory/     # cleans all .aikular subfolders
```

---

## How to Configure

### 1. Watermark & branding filters
Add new promotional strings to `WATERMARK_KEYWORDS` in `aikular_parser.py`:
```python
WATERMARK_KEYWORDS = (
    "subscribe", "subscription", "telegram", "guidely",
    "mock test", "all in one", "pdf course", "topic-wise",
    "my-custom-watermark",
)
```
Any matching line is dropped from `context.md`. Domain-like tokens (`.in`, `.com`, `www.`, `http`) and email addresses are stripped automatically.

### 2. Render tuning
Constants at the top of `aikular_parser.py`:
```python
DEFAULT_DPI = 150        # base render DPI (raise for dense small text)
MAX_EDGE_PX = 1800       # cap long edge; lower to cut image-token cost
SPARSE_CHAR_LIMIT = 25   # below this a page is treated as image-only
IMAGE_AREA_FRAC = 0.12   # raster must cover this fraction to count as a figure
VECTOR_DRAW_LIMIT = 25   # vector ops above this imply a drawn chart
```
Override DPI per run: `python3 aikular_parser.py in.pdf out --images auto --dpi 220`.

### 3. Seed prompt
Edit `SEED_PROMPT` inside `aikular`. It instructs the AI to read the referenced PNG paths and never claim a page is empty before checking its image.

### 4. Hardcoded path in the desktop file
`aikular.desktop` still hardcodes an absolute path. Set it to your home:
```ini
Exec=/home/<your_username>/.local/bin/aikular %f
```

### 5. Switch AI backend (agy vs opencode)
```bash
aikular --backend   # show current
aikular --switch    # toggle
```
Saved in `~/.config/aikular/backend`.

---

## Notes on behaviour

- **No OCR.** Image-capable backends read page renders directly. The trade-off: text on image-only pages is not in `context.md`, so those pages are found by page number, not keyword search. Fine for born-digital study material; if you need full-text search over scanned books, add a text-indexing pass separately.
- **Concurrent runs** on the same PDF are serialised with a `flock` lock beside the cache directory.
- **Session persistence** is best-effort. `ghostty -e` can return before the backend writes its session row, so the first launch may not capture an id; subsequent launches reuse it reliably.
