#!/bin/bash
# Revert CachyOS Hackable Bluetooth Fix

echo "Reverting CachyOS Bluetooth Hackable Fix..."

# 1. Revert Patch 1 (BR/EDR Classic Bluetooth)
echo "[1/4] Reverting Classic Bluetooth Patch..."
echo "admin0" | sudo -S sed -i 's/^ControllerMode = bredr/#ControllerMode = dual/' /etc/bluetooth/main.conf

# 2. Remove script
echo "[2/4] Removing restart script..."
echo "admin0" | sudo -S rm -f /usr/local/bin/bt-restart

# 3. Remove Desktop Integrations
echo "[3/4] Removing Desktop Shortcuts and Autostart..."
rm -f ~/.local/share/applications/restart-bluetooth.desktop
rm -f ~/.config/autostart/restart-bluetooth-login.desktop

# 4. Remove Polkit rule
echo "[4/4] Removing Polkit authorization..."
echo "admin0" | sudo -S rm -f /etc/polkit-1/rules.d/10-restart-bluetooth.rules

echo "admin0" | sudo -S systemctl restart bluetooth

echo "============================================="
echo "Revert Complete!"