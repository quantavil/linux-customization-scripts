#!/bin/bash
# Revert MPV uosc + thumbfast Setup

echo "========================================="
echo "  Reverting MPV uosc + thumbfast Setup"
echo "========================================="
echo ""

# --- 1. Remove uosc (based on how it was installed) ---
echo "How was uosc installed?"
echo "  1) AUR (paru)"
echo "  2) Official upstream script"
echo ""
read -rp "Pick [1/2]: " choice

case "$choice" in
    1)
        echo "[1/4] Removing uosc via paru..."
        paru -Rns --noconfirm mpv-uosc
        ;;
    2)
        echo "[1/4] Removing uosc upstream files..."
        rm -rf ~/.config/mpv/scripts/uosc
        rm -f ~/.config/mpv/script-opts/uosc.conf
        rm -rf ~/.config/mpv/fonts/uosc_icons.otf
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# --- 2. Remove mpv.conf ---
echo "[2/4] Removing mpv.conf..."
rm -f ~/.config/mpv/mpv.conf

# --- 3. Remove input.conf ---
echo "[3/4] Removing input.conf..."
rm -f ~/.config/mpv/input.conf

# --- 4. Remove thumbfast ---
echo "[4/4] Removing thumbfast..."
rm -f ~/.config/mpv/scripts/thumbfast.lua
rm -f ~/.config/mpv/script-opts/thumbfast.conf

echo ""
echo "========================================="
echo "  Revert Complete!"
echo "========================================="
