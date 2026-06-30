#!/bin/bash
set -eo pipefail

# Helper function to print to stderr and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Helper to send notification if notify-send is available, fallback to stderr
notify() {
    local title="$1"
    local message="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Aikular" "$title" "$message" || true
    else
        echo "[$title] $message" >&2
    fi
}

# Check for essential utility tools
for tool in python3 realpath md5sum cut dirname basename setsid; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        error_exit "Required system tool '$tool' is not installed."
    fi
done

# Parse arguments
REFRESH=false
if [[ "$1" == "--refresh" ]]; then
    REFRESH=true
    shift
fi

PDF_PATH="$1"
if [[ -z "$PDF_PATH" ]]; then
    echo "Usage: aikular.sh [--refresh] <pdf_path>" >&2
    exit 1
fi

# Resolve absolute path of PDF
ABS_PDF_PATH=$(realpath "$PDF_PATH")
PDF_DIR=$(dirname "$ABS_PDF_PATH")
PDF_NAME=$(basename "$ABS_PDF_PATH")
PDF_STEM="${PDF_NAME%.*}"

# Check if target is a valid PDF
if [[ ! -f "$ABS_PDF_PATH" || ( "${PDF_NAME,,}" != *.pdf ) ]]; then
    error_exit "File '$PDF_PATH' does not exist or is not a PDF."
fi

# Determine output directory
if [[ -w "$PDF_DIR" ]]; then
    OUTPUT_DIR="$PDF_DIR/.aikular/$PDF_STEM"
else
    # Fallback to /tmp on read-only folders
    DIR_HASH=$(echo -n "$PDF_DIR" | md5sum | cut -d' ' -f1 | cut -c1-8)
    OUTPUT_DIR="/tmp/aikular-${USER}/${PDF_STEM}-${DIR_HASH}"
fi

OUTLINE_PATH="$OUTPUT_DIR/outline.md"
CONTEXT_PATH="$OUTPUT_DIR/context.md"

# Determine parser script path dynamically or fallback to hardcoded user bin
PARSER_SCRIPT="${BASH_SOURCE[0]%/*}/aikular_parser.py"
if [[ ! -f "$PARSER_SCRIPT" ]]; then
    PARSER_SCRIPT="$HOME/.local/bin/aikular_parser.py"
fi

if [[ ! -f "$PARSER_SCRIPT" ]]; then
    error_exit "Parser script not found at '$PARSER_SCRIPT'"
fi

# Clean cache if refresh requested
if [[ "$REFRESH" == true ]]; then
    rm -rf "$OUTPUT_DIR"
fi

# Check if cache exists
if [[ ! -f "$CONTEXT_PATH" ]]; then
    notify "Parsing PDF..." "$PDF_NAME"
    if ! python3 "$PARSER_SCRIPT" "$ABS_PDF_PATH" "$OUTPUT_DIR"; then
        rm -rf "$OUTPUT_DIR"
        error_exit "PDF parsing failed. Cleaned up corrupt cache."
    fi
fi

# Validate UI/Terminal dependencies
for tool in okular ghostty fish agy; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        error_exit "Required application '$tool' is not installed or not in PATH."
    fi
done

# Spawn Okular detached
setsid okular "$ABS_PDF_PATH" >/dev/null 2>&1 &

# Seed prompt for agy
SEED_PROMPT="You are analyzing the PDF: $PDF_NAME.
Document map: $OUTLINE_PATH — read this FIRST.
Full content: $CONTEXT_PATH (pages separated by <!-- page: N --> markers).
The PDF is open in Okular for visual reference.
Always cite [Page N] when answering."

# Launch Ghostty with safe env passing to avoid quoting issues in fish -c
notify "Ready" "Okular + agy session started"
export SEED_PROMPT
ghostty --title="aikular: $PDF_STEM" --working-directory="$PDF_DIR" -e fish -c 'agy --dangerously-skip-permissions -i "$SEED_PROMPT"'
