# Project: aikular

## Overview
Aikular is a CLI tool and wrapper that parses PDFs and starts interactive AI analysis sessions using `okular` (visual PDF display) and an AI terminal backend (`agy` or `opencode`) inside `ghostty` with `fish`. Because the backends read images directly but not PDFs, Aikular renders visual pages to PNG and references them by absolute path in `context.md`.

## Structure
```
aikular/
├── README.md           # Documentation and setup
├── aikular             # Main entry point (Bash)
├── aikular-render      # On-demand page-to-PNG tool the AI calls (Python)
├── aikular-clean       # Cache cleanup (Bash)
├── aikular.desktop     # Desktop entry for KDE integration
└── aikular_parser.py   # PDF text extraction, table dedup, and page renderer (Python)
```

## Conventions
- **Shell**: Bash for wrappers; Fish for launching the interactive AI CLI.
- **Cache**: `<pdf_dir>/.aikular/<pdf_stem>/` if writable, else `/tmp/aikular-${USER}/...`. Page PNGs live in `<cache>/images/page_NNN.png`.
- **Backend**: toggles between `agy` and `opencode`; persists session ids in the cache folder.

## Dependencies & Setup
- Requires: `python3` + `pymupdf` (fitz), `okular`, `ghostty`, `fish`, `sqlite3`, `flock`, `find`, and either `agy` or `opencode`.
- Config: `~/.config/aikular/backend`.

## Image handling
- No OCR. Multimodal backend reads page renders directly.
- Page tags in context.md: `text` (no render), `has_figure` (text + PNG), `visual` (sparse text, PNG is primary). These are HINTS, not authoritative.
- Pre-render triggers (auto mode): chars `< 25`, or a raster covering `> 12%` of the page, or `>= 25` vector draw ops. `--images` renders all, `--no-images` renders none.
- On-demand: `aikular-render <pdf> <pages> [--dpi] [--bbox]` lets the AI rasterise ANY page itself, so a wrong parse-time guess is never a dead end. It mirrors the launcher's cache-dir logic and writes to `<cache>/images/`, printing PNG paths to stdout. bbox crops save as `page_NNN_crop.png`.
- Launcher resolves `aikular-render`'s absolute path and bakes it, plus the PDF path, into the seed prompt so PATH issues and wrong-guess dead-ends are avoided.
- Long edge capped at 1800 px to bound image-token cost.

## Critical Information
- Detached okular: `setsid okular ...`.
- `flock` on `<cache>.lock` serialises concurrent parses of the same PDF.
- Parser is reentrant: no module globals; boilerplate/body-size carried in a `DocCtx` dataclass.

## Fixes recorded
- Table cell text no longer duplicated: lines inside table bboxes are skipped in body extraction, tables emitted once as Markdown.
- Soft line-break hyphens de-hyphenated (`informa-`+`tion` -> `information`); compound/proper-noun boundaries preserved.
- Text NFKC-normalised, soft hyphens (U+00AD) stripped.
- Encrypted PDFs: attempt empty-password auth, error clearly if it fails.
- Block reading order sorted top-to-bottom then left-to-right (helps single-column PDFs; true multi-column still not column-detected).
- Watermark domain match tightened to a word-boundary regex instead of bare `.in` substring.

## Insights
- Session persistence requires querying local DBs after the ghostty process, but `ghostty -e` can return early, so the first session may be missed. A backend flag emitting its own session id would remove the race.
- `agy`/`opencode` file-read tools are image-aware, so path references beat MCP/base64 for simplicity.

## Blunders
- (None yet recorded)
