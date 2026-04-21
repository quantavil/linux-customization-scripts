#!/bin/bash

# Apply AdGuard Home Setup

echo "[AUTO] Installing AdGuard Home..."
paru -S --needed --noconfirm adguardhome
sudo systemctl enable --now adguardhome

echo ""
echo "[AUTO] Fixing Port 53 Conflict..."
if [ -f "./fix-port-53.sh" ]; then
    chmod +x fix-port-53.sh
    ./fix-port-53.sh
else
    echo "Warning: fix-port-53.sh not found in the current directory."
    echo "Port 53 conflict might not be resolved. Make sure systemd-resolved is disabled."
fi

echo ""
echo "[MANUAL] Verifying port 53"
echo "Check the output below to ensure port 53 is free."
echo "(Note: entries for 5353 from avahi/kdeconnect are fine):"
sudo ss -tulpn | grep :53
read -p "Press Enter to continue if port 53 is free..."

echo ""
echo "[MANUAL] Initial Setup Wizard"
echo "Open http://localhost:3000 in your browser."
echo "1. Admin Web Interface → port 80"
echo "2. DNS Server → port 53"
echo "3. Set admin username and password"
echo "4. Click Install"
read -p "Press Enter when done..."

echo ""
echo "Choose how to point your system DNS to AdGuard Home:"
echo "1) Terminal (nmcli) [Recommended - Automated]"
echo "2) GUI (KDE Plasma) [Manual]"
read -p "Enter choice [1]: " dns_choice
dns_choice=${dns_choice:-1}

if [ "$dns_choice" = "1" ]; then
    echo "[AUTO] Applying DNS override via nmcli..."
    active_con=$(nmcli -t -f NAME,TYPE con show --active | grep -E '802-11-wireless|802-3-ethernet' | head -n 1 | cut -d: -f1)
    if [ -n "$active_con" ]; then
        nmcli con mod "$active_con" ipv4.dns "127.0.0.1" ipv4.ignore-auto-dns yes
        nmcli con up "$active_con"
        echo "Applied to connection: $active_con"
    else
        echo "Error: Could not detect active connection."
    fi
else
    echo ""
    echo "[MANUAL] Apply DNS via KDE Plasma"
    echo "1. System Settings → Connections → your WiFi/Ethernet → IPv4 tab"
    echo "2. DNS Servers: 127.0.0.1"
    echo "3. Apply and reconnect"
    read -p "Press Enter when done..."
fi

echo ""
echo "[MANUAL] DNS Settings & Blocklists Configuration"
echo "Open the dashboard at http://localhost"
echo ""
echo "**DNS Settings (Settings → DNS Settings):**"
echo "1. Upstream DNS Servers:"
echo "   https://dns10.quad9.net/dns-query"
echo "   https://dns.cloudflare.com/dns-query"
echo "   tls://9.9.9.10"
echo "   tls://1.1.1.1"
echo "2. Query Mode: Parallel requests"
echo "3. Bootstrap DNS:"
echo "   9.9.9.10"
echo "   149.112.112.10"
echo "   2620:fe::10"
echo "   2620:fe::fe:10"
echo "     (Click Apply)"
echo ""
echo "**Blocklists (Filters → DNS Blocklists):**"
echo "1. Add blocklist → Choose from the list"
echo "2. Enable 'AdGuard DNS filter' and 'AdAway Default Blocklist'"
read -p "Press Enter when done..."

echo ""
echo "[AUTO] Verifying Everything Works..."
echo "Testing a blocked domain (doubleclick.net) - should return 0.0.0.0:"
dig doubleclick.net @127.0.0.1 +short
echo "Testing a normal domain (archlinux.org) - should resolve normally:"
dig archlinux.org @127.0.0.1 +short
echo ""
echo "[MANUAL] You can also go to the Query Log in the dashboard to see live DNS requests."
read -p "Press Enter to finish setup..."
echo "Setup Complete!"
