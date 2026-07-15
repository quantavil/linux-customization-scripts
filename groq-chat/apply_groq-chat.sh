#!/bin/bash
# Groq CLI Assistant — Installer
set -euo pipefail

echo "Installing Groq CLI Assistant..."

# Check dependencies
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is required but not installed." >&2
        exit 1
    fi
done

mkdir -p "$HOME/.local/bin"
cp ai "$HOME/.local/bin/ai"
chmod +x "$HOME/.local/bin/ai"

echo "Successfully installed 'ai' to ~/.local/bin/ai"
echo "Make sure ~/.local/bin is in your PATH."
echo "Run 'ai --configure' or 'ai hello' to set up your API key."
