#!/bin/bash
set -euo pipefail

echo "[AUTO] Stopping and disabling systemd timer..."
if systemctl --user is-enabled git-squash-history.timer &>/dev/null; then
    systemctl --user disable --now git-squash-history.timer
fi

echo "[AUTO] Removing systemd unit files..."
rm -f "$HOME/.config/systemd/user/git-squash-history.service"
rm -f "$HOME/.config/systemd/user/git-squash-history.timer"

echo "[AUTO] Reloading systemd daemon..."
systemctl --user daemon-reload

echo "[AUTO] Removing engine script..."
rm -f "$HOME/.local/bin/git-squash-history.sh"

echo
read -p "Delete repository configuration directory (~/.config/git-autosquash)? [y/N]: " DELETE_CONFIG
if [[ "$DELETE_CONFIG" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/git-autosquash"
    echo "[AUTO] Configuration directory purged."
else
    echo "[AUTO] Configuration directory retained."
fi

echo "Teardown complete."
