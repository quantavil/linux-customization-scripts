# CachyOS Bluetooth Hackable Fix

Sets Classic Bluetooth mode and auto-restarts the bluetooth daemon on every login (boot, sleep/wake, lock/unlock) for reliable headset connections.

## What it does:
1. **Classic Bluetooth Patch** — Sets `ControllerMode = bredr` in `/etc/bluetooth/main.conf` (disables LE for better headset reliability).
2. **Polkit Rule** — Allows `wheel` group to manage `bluetooth.service` without sudo password.
3. **Restart Script** — `/usr/local/bin/bt-restart` restarts bluetooth with success/failure desktop notification.
4. **Desktop Integration** — App launcher (pin to panel) + autostart entry (15s delayed restart on every login).

---

## 🚀 Install

```bash
chmod +x apply_cachyos_fix.sh
./apply_cachyos_fix.sh
```

## 🗑️ Revert

```bash
chmod +x revert_cachyos_fix.sh
./revert_cachyos_fix.sh
```

## Pin to Panel
1. Press `Meta` key → search **Restart Bluetooth** → right-click → **Pin to Task Manager**.
2. Click it anytime your headphones won't connect.
