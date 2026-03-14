# AdGuard Home

A self-hosted, network-wide DNS server that blocks ads and trackers for every device on your network. It works by sinkholing tracking domains at the DNS level — no browser extension needed.

---

## Quick Setup

You can automate most of the installation and teardown processes using the provided scripts:

- **Apply Setup**: Run `./apply_adguard-home_setup.sh`
- **Revert Setup**: Run `./revert_adguard-home_setup.sh`

*Note: Initial web interface configuration, setting the upstream DNS/blocklists, and specific GUI configurations still require manual action. The script will automatically pause and guide you through these steps.*

---

## Installation

```bash
paru -S adguardhome
sudo systemctl enable --now adguardhome
```

> **Note:** The service name is lowercase `adguardhome` (not `AdGuardHome` like the upstream binary).

---

## Fix Port 53 Conflict

On CachyOS (and most modern systemd distros), `systemd-resolved` occupies port 53. AdGuard Home needs that port. Kill it permanently by running the provided script:

```bash
chmod +x fix-port-53.sh
./fix-port-53.sh
```

Verify port 53 is free (only 5353 entries from `avahi`/`kdeconnect` are fine):

```bash
sudo ss -tulpn | grep :53
```

---

## Initial Setup Wizard

Open `http://localhost:3000` in your browser.

1. **Admin Web Interface** → set port (default 80 is fine)
2. **DNS Server** → port 53
3. Set your admin username and password
4. Click **Install**

After setup, the dashboard lives at `http://localhost`.

---

## Point Your System DNS to AdGuard Home

### Method 1: Via nmcli (Terminal)
This is the recommended, easily automated method.

```bash
# Get your active connection name
nmcli con show --active

# Apply DNS override
nmcli con mod "YOUR_CONNECTION_NAME" ipv4.dns "127.0.0.1" ipv4.ignore-auto-dns yes
nmcli con up "YOUR_CONNECTION_NAME"
```

### Method 2: Via KDE Plasma (GUI)
1. Go to **System Settings** → **Connections** → *your WiFi/Ethernet* → **IPv4 tab**
2. Set **DNS Servers** to: `127.0.0.1`
3. Click **Apply** and reconnect to the network.

---

## DNS Settings Configuration

Navigate to **Settings → DNS Settings** in the dashboard.

### Upstream DNS Servers
Use privacy-focused providers (no Google):

```text
https://dns10.quad9.net/dns-query
https://dns.cloudflare.com/dns-query
tls://9.9.9.10
tls://1.1.1.1
```

### Query Mode
Select **Parallel requests** — this queries all upstreams simultaneously and uses the fastest response. *(Load balancing is just round-robin, which can be slower if one upstream has issues.)*

### Bootstrap DNS
These are Quad9's own IPs, used only to resolve the DoH hostname initially on startup. No changes needed here, 4 Quad9 IPs across IPv4 + IPv6 is already redundant enough:

```text
9.9.9.10
149.112.112.10
2620:fe::10
2620:fe::fe:10
```

Click **Apply** to save changes.

---

## Blocklists

Navigate to **Filters → DNS Blocklists**.

Click **Add blocklist** → **Choose from the list** and enable these:
- **AdGuard DNS filter** *(usually active by default)*
- **AdAway Default Blocklist**

---

## Verify Everything Works

Test DNS resolution from your terminal:

```bash
# Should return 0.0.0.0 (blocked)
dig doubleclick.net @127.0.0.1

# Should resolve normally (upstream working)
dig archlinux.org @127.0.0.1
```

In the dashboard, check the **Query Log**. You should see live DNS requests, with blocked ones marked in red.

---

## Useful Commands

```bash
# Check service status
sudo systemctl status adguardhome

# View live logs
sudo journalctl -u adguardhome -f

# Restart the service
sudo systemctl restart adguardhome

# Update (via paru)
paru -Syu adguardhome
```

---

## Reinstall / Reset from Scratch

If you need a fresh start, run the following commands. Ensure you back up your config file (`/var/lib/AdGuardHome/AdGuardHome.yaml`) if you want to preserve blocklists and settings.

```bash
sudo systemctl stop adguardhome
paru -R adguardhome
sudo rm -rf /var/lib/AdGuardHome   # Wipes config and query log
paru -S adguardhome
sudo systemctl enable --now adguardhome
```

---

## Notes

- **Port 5353** (mDNS from avahi/kdeconnect) is totally fine — do not touch it.
- **Static IP warning** in the initial setup wizard: This only matters if other LAN devices use your machine as their DNS server. For personal, single-machine use, simply ignore it.
- **Config file** lives at `/var/lib/AdGuardHome/AdGuardHome.yaml`. Back this up if you want to preserve your blocklists and settings across reinstalls.
- **DoH upstream** (`dns10.quad9.net`) needs the bootstrap IPs to resolve on cold start — that is the only purpose of the bootstrap DNS field.