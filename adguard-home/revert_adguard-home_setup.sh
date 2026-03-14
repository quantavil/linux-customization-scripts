#!/bin/bash

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
    active_con=$(nmcli -t -f NAME con show --active | head -n 1)
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
echo "Revert Complete!"
echo "Note: if you used fix-port-53.sh in the past and wish to restore systemd-resolved on port 53, you will need to revert those changes manually."
