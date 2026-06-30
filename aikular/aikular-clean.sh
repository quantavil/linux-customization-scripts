#!/bin/bash
set -euo pipefail

# Print usage information
usage() {
    echo "Usage: $(basename "$0") <pdf_path_or_directory>"
    exit 1
}

# Handle help flags
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    usage
fi

# Gracefully check if target path exists before using realpath
if [ ! -e "$TARGET" ]; then
    echo "Error: '$TARGET' does not exist." >&2
    exit 1
fi

ABS_TARGET=$(realpath "$TARGET")

if [ -d "$ABS_TARGET" ]; then
    # Target is a directory: clean the .aikular folder inside it
    AIKULAR_DIR="$ABS_TARGET/.aikular"
    if [ -d "$AIKULAR_DIR" ]; then
        rm -rf "$AIKULAR_DIR"
        echo "Cleaned directory: $AIKULAR_DIR"
    else
        echo "No .aikular/ directory found in $ABS_TARGET"
    fi
elif [ -f "$ABS_TARGET" ]; then
    # Target is a file
    PDF_NAME=$(basename "$ABS_TARGET")
    PDF_STEM="${PDF_NAME%.*}"
    PDF_DIR=$(dirname "$ABS_TARGET")
    
    # 1. Clean local .aikular entry
    LOCAL_CACHE="$PDF_DIR/.aikular/$PDF_STEM"
    if [ -d "$LOCAL_CACHE" ]; then
        rm -rf "$LOCAL_CACHE"
        echo "Cleaned cache: $LOCAL_CACHE"
    fi
    # Clean up empty parent .aikular directory if empty
    rmdir "$PDF_DIR/.aikular" 2>/dev/null || true
    
    # 2. Clean tmp entry (namespaced by user)
    if ! command -v md5sum >/dev/null 2>&1; then
        echo "Error: md5sum command not found. Cannot calculate directory hash." >&2
        exit 1
    fi
    
    DIR_HASH=$(echo -n "$PDF_DIR" | md5sum | cut -d' ' -f1 | cut -c1-8)
    TMP_CACHE="/tmp/aikular-${USER}/${PDF_STEM}-${DIR_HASH}"
    if [ -d "$TMP_CACHE" ]; then
        rm -rf "$TMP_CACHE"
        echo "Cleaned tmp cache: $TMP_CACHE"
    fi
    # Clean up parent tmp directory if empty
    rmdir "/tmp/aikular-${USER}" 2>/dev/null || true
else
    echo "Error: '$TARGET' is not a valid file or directory." >&2
    exit 1
fi
