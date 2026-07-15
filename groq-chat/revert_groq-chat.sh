#!/bin/bash
# Groq CLI Assistant — Uninstaller
set -euo pipefail

echo "Uninstalling Groq CLI Assistant..."
rm -f "$HOME/.local/bin/ai"

read -p "Do you want to delete conversation history and configuration under ~/.config/groq-cli? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/groq-cli"
    echo "Configuration and history deleted."
fi

echo "Uninstallation complete."
