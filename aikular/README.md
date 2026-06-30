# Aikular: Okular & agy PDF Analysis Pipeline

Aikular is a local productivity pipeline that integrates the **Okular** PDF reader with the CLI AI assistant **agy** (`antigravity-cli`). It allows you to right-click any PDF in Dolphin (or launch it from the terminal), automatically extracting structural page text and formatting tables into clean Markdown while stripping out repeating promotional watermarks, email stamps, and branding links. It opens Okular for visual reference side-by-side with a new **Ghostty** terminal running `agy` pre-seeded with the document context map.

---

## 📂 File Directory

This folder contains all the self-contained components of the Aikular pipeline:

```
linux-customization-scripts/aikular/
├── aikular.sh        # Launcher orchestrator script
├── aikular_parser.py # PDF-to-Markdown parser & watermark filter
├── aikular-clean.sh  # Cache cleanup script
├── aikular.desktop   # Dolphin right-click context menu integration
└── README.md         # This manual
```

---

## 🚀 System Installation

Follow these steps to install and register Aikular on your Arch/CachyOS system:

### 1. Copy Files to Local System Paths
The scripts must be copied to your local user executable path (`~/.local/bin/`), and the KIO action must be copied to the KDE service menus configuration folder (`~/.local/share/kio/servicemenus/`):

```bash
# Copy executable scripts
cp aikular.sh aikular_parser.py aikular-clean.sh ~/.local/bin/

# Copy Dolphin context menu integration
mkdir -p ~/.local/share/kio/servicemenus/
cp aikular.desktop ~/.local/share/kio/servicemenus/
```

### 2. Grant Executable Permissions
Grant execute privileges to all deployed scripts:
```bash
chmod +x ~/.local/bin/aikular.sh
chmod +x ~/.local/bin/aikular_parser.py
chmod +x ~/.local/bin/aikular-clean.sh
chmod +x ~/.local/share/kio/servicemenus/aikular.desktop
```

### 3. Rebuild KDE Sycoca Cache
Instruct KDE Plasma 6 to reload Dolphin service menus so the right-click option appears immediately without logging out:
```bash
kbuildsycoca6
```

---

## 📖 How to Use

### A. Graphical Use (Dolphin)
1. Open the **Dolphin** file manager.
2. Right-click any PDF file.
3. Select **Open with Aikular (Okular & agy)** from the context menu.
4. Okular will launch in the background, and Ghostty will launch a terminal pre-seeded with `agy` connected directly to your parsed PDF context.

### B. Terminal Use (Fish Shell)
You can run the pipeline directly from your terminal:
```bash
# General usage
aikular.sh /path/to/document.pdf

# Force re-parse (bypass existing cache and re-extract text/tables)
aikular.sh --refresh /path/to/document.pdf
```

### C. Cleaning the Cache
The parsed text caches are saved to speed up subsequent launches. If you want to delete these caches to free up space:
```bash
# Clean cache for a single PDF
aikular-clean.sh /path/to/document.pdf

# Clean all cache subfolders in a folder
aikular-clean.sh /path/to/directory/
```

---

## 🔧 How to Configure

You can customize Aikular's behavior by modifying the scripts. Here is what you can adjust:

### 1. Watermark & Branding Filters
If you encounter new watermark strings or other promotional noise in your study PDFs, edit the `is_watermark_text(text)` function inside `aikular_parser.py`:

```python
def is_watermark_text(text):
    t_lower = text.lower().strip()
    # Add new keywords here (e.g. "my-custom-watermark")
    watermark_keywords = [
        "subscribe", "subscription", "telegram", "guidely",
        "mock test", "all in one", "pdf course", "my-custom-watermark"
    ]
    if any(keyword in t_lower for keyword in watermark_keywords):
        return True
    return False
```
*Note: Any line matching these keywords will be completely removed from `context.md` to optimize LLM context window space.*

### 2. Agy Prompt Customization
To change the instructions given to the AI when a session starts, modify the `SEED_PROMPT` variable inside `aikular.sh`:

```bash
SEED_PROMPT="You are analyzing the PDF: $PDF_NAME.
Document map: $OUTLINE_PATH — read this FIRST.
Full content: $CONTEXT_PATH (pages separated by <!-- page: N --> markers).
The PDF is open in Okular for visual reference.
Always cite [Page N] when answering."
```

### 3. Change System Username / Hardcoded Paths
If you deploy these scripts on another system, make sure the absolute path inside `aikular.desktop` points to your correct user directory:
```ini
Exec=/home/<your_username>/.local/bin/aikular.sh %f
```
*(Open `aikular.desktop` and replace `/home/quantavil/` with your user's home path).*
