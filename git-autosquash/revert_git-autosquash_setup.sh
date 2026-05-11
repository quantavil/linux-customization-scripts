#!/bin/bash

echo "Reverting git-autosquash setup..."
echo

# Step 1: Disable and remove systemd units
echo "[AUTO] Disabling git-squash-history.timer..."
systemctl --user disable --now git-squash-history.timer 2>/dev/null

echo "[AUTO] Removing systemd service and timer files..."
rm -f "$HOME/.config/systemd/user/git-squash-history.service"
rm -f "$HOME/.config/systemd/user/git-squash-history.timer"

echo "[AUTO] Reloading systemd daemon..."
systemctl --user daemon-reload

# Step 2: Remove the squash script
echo "[AUTO] Removing git-squash-history.sh..."
rm -f "$HOME/.local/bin/git-squash-history.sh"

# Step 3: Optionally remove config
echo
read -p "Delete configuration directory (~/.config/git-autosquash/)? [y/N]: " DELETE_CONFIG

if [[ "$DELETE_CONFIG" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/git-autosquash"
    echo "[AUTO] Configuration deleted."
else
    echo "[AUTO] Configuration retained at ~/.config/git-autosquash/"
fi

echo
echo "Teardown complete."
