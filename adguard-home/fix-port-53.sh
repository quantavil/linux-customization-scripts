#!/bin/bash

# Disable and mask so it never respawns
sudo systemctl disable --now systemd-resolved
sudo systemctl mask systemd-resolved

# Stop lingering socket units
sudo systemctl stop systemd-resolved-monitor.socket systemd-resolved-varlink.socket

# Point resolv.conf to AdGuard Home
sudo rm /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

# Restart AdGuard Home
sudo systemctl restart adguardhome
