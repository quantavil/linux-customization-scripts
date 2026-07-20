#!/bin/bash
# Revert MPV material-osc + thumbfast Setup

echo "========================================="
echo "  Reverting MPV material-osc + thumbfast Setup"
echo "========================================="
echo ""

echo "[1/3] Removing material-osc files..."
rm -f ~/.config/mpv/scripts/material-osc.lua
rm -rf ~/.config/mpv/scripts/material-osc/

echo "[2/3] Removing thumbfast..."
rm -f ~/.config/mpv/scripts/thumbfast.lua

echo "[3/3] Removing mpv.conf..."
rm -f ~/.config/mpv/mpv.conf

# Clean up directories if they are empty
rmdir ~/.config/mpv/scripts &>/dev/null
rmdir ~/.config/mpv &>/dev/null

echo ""
echo "========================================="
echo "  Revert Complete!"
echo "========================================="
