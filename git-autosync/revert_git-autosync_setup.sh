#!/bin/bash

echo "Starting git-autosync teardown..."
echo

# Stop and disable systemd timer
echo "[AUTO] Stopping and disabling systemd timer..."
systemctl --user disable --now git-autosync.timer 2>/dev/null || true

# Remove systemd unit files
echo "[AUTO] Removing systemd service and timer files..."
rm -f "$HOME/.config/systemd/user/git-autosync.timer"
rm -f "$HOME/.config/systemd/user/git-autosync.service"

# Reload daemon
echo "[AUTO] Reloading systemd daemon..."
systemctl --user daemon-reload

# Remove sync script
echo "[AUTO] Removing execution script..."
rm -f "$HOME/.local/bin/git-autosync.sh"

echo
# Ask about removing config
echo "[MANUAL] Do you want to remove the configuration directory and repos.list? (y/N)"
read -r -p "Press Enter for 'N': " choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "[AUTO] Removing configuration directory..."
    rm -rf "$HOME/.config/git-autosync"
else
    echo "[AUTO] Keeping configuration directory."
fi

echo
echo "Teardown complete."
