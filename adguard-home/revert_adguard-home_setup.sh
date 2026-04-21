#!/bin/bash
cd "$(dirname "$0")" || exit 1

# Revert AdGuard Home Setup

echo "[AUTO] Removing AdGuard Home..."
sudo systemctl stop adguardhome
paru -R --noconfirm adguardhome
sudo rm -rf /var/lib/AdGuardHome

echo ""
echo "Choose how to revert your system DNS override:"
echo "1) Terminal (nmcli) [Recommended - Automated]"
echo "2) GUI (KDE Plasma) [Manual]"
read -p "Enter choice [1]: " dns_choice
dns_choice=${dns_choice:-1}

if [ "$dns_choice" = "1" ]; then
    echo "[AUTO] Restoring auto DNS via nmcli..."
    active_con=$(nmcli -t -f NAME,TYPE con show --active | grep -E '802-11-wireless|802-3-ethernet' | head -n 1 | cut -d: -f1)
    if [ -n "$active_con" ]; then
        nmcli con mod "$active_con" ipv4.dns "" ipv4.ignore-auto-dns no
        nmcli con up "$active_con"
        echo "Restored for connection: $active_con"
    else
        echo "Error: Could not detect active connection."
    fi
else
    echo ""
    echo "[MANUAL] Revert DNS via KDE Plasma"
    echo "1. System Settings → Connections → your WiFi/Ethernet → IPv4 tab"
    echo "2. Remove 127.0.0.1 from DNS Servers"
    echo "3. Ensure Method is set back to 'Automatic'"
    echo "4. Apply and reconnect"
    read -p "Press Enter when done..."
fi

echo ""
echo "Do you want to restore systemd-resolved to handle port 53 again?"
read -p "Enter choice [y/N]: " restore_resolved
if [[ "$restore_resolved" =~ ^[Yy]$ ]]; then
    echo "[AUTO] Restoring systemd-resolved..."
    sudo systemctl unmask systemd-resolved
    sudo systemctl enable --now systemd-resolved
    sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    echo "systemd-resolved restored."
fi

echo ""
echo "Revert Complete!"
