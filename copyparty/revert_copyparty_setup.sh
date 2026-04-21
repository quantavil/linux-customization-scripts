#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
CONFIG_FILE="$CONFIG_DIR/copyparty.conf"
SERVICE_FILE="$CONFIG_DIR/systemd/user/copyparty.service"

echo "=== Copyparty Revert Script ==="
echo ""

# Check if service exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "No copyparty service file found at $SERVICE_FILE"
    echo "Nothing to revert."
    exit 0
fi

# Stop the service if running
echo "Stopping copyparty service..."
if systemctl --user is-active --quiet copyparty.service 2>/dev/null; then
    systemctl --user stop copyparty.service
    echo "✓ Service stopped."
else
    echo "Service was not running."
fi

# Disable the service
echo "Disabling copyparty service..."
systemctl --user disable copyparty.service 2>/dev/null || true
echo "✓ Service disabled."

# Reload systemd user daemon
echo "Reloading systemd user daemon..."
systemctl --user daemon-reload
echo "✓ Systemd daemon reloaded."

# Remove service file
echo "Removing service file..."
rm -f "$SERVICE_FILE"
echo "✓ Service file removed."

# Remove configuration file
if [ -f "$CONFIG_FILE" ]; then
    echo "Removing configuration file..."
    rm -f "$CONFIG_FILE"
    echo "✓ Configuration file removed."
else
    echo "No configuration file found."
fi

# Prompt to uninstall copyparty
echo ""
read -p "Do you want to uninstall copyparty from the system? (y/N): " UNINSTALL
if [[ "$UNINSTALL" =~ ^[Yy]$ ]]; then
    echo "Uninstalling copyparty..."
    paru -R --noconfirm copyparty
    echo "✓ Copyparty uninstalled."
else
    echo "Skipping copyparty uninstallation."
fi

echo ""
echo "=== Revert Complete ==="
echo ""
echo "Copyparty has been removed from systemd services."
echo "Configuration files have been deleted."
echo ""
