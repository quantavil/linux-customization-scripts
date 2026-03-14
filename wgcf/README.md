# Cloudflare WARP on CachyOS/Arch — Full Guide

## 1. Install wgcf

```bash
sudo pacman -S wgcf
```

OR

```bash
paru -S wgcf-bin
```

## 2. Generate config
```bash
mkdir ~/warp && cd ~/warp
wgcf register
wgcf generate
```

## 3. Import into NetworkManager
```bash
sudo cp wgcf-profile.conf /etc/wireguard/warp.conf
sudo nmcli connection import type wireguard file /etc/wireguard/warp.conf
```

## 4. Connect
**CLI:** `nmcli connection up warp` / `nmcli connection down warp`

**GUI:** System tray → Network icon → VPN → toggle `warp`

## 5. Verify
```bash
wgcf trace   # should show warp=on at the end
```

---

**Troubleshooting**

| Problem                    | Fix                                                                                  |
| -------------------------- | ------------------------------------------------------------------------------------ |
| Signature error on install | `paru -S wgcf-bin` instead of pacman                                                 |
| `wg-quick` not found       | `sudo pacman -S wireguard-tools`                                                     |
| VPN not in tray            | `nm-applet` or restart plasmashell                                                   |
| Want Warp+                 | Get license key from 1.1.1.1 app → `wgcf update --license-key "KEY"` then regenerate |

---

That's the complete setup. The config files (`wgcf-account.toml`, `wgcf-profile.conf`) in `~/warp` are your backup — keep them.