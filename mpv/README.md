# MPV Player Setup

Streamlined, modern configuration for `mpv` on Linux utilizing the Material Design theme skin.

## Quick Setup (Script)

Run the apply script to install everything automatically:

```bash
bash mpv/apply_mpv_setup.sh
```

To revert all changes:

```bash
bash mpv/revert_mpv_setup.sh
```

---

## Manual Setup

### 1. Installation

Install the main `mpv` player from your system's package manager:

**Arch Linux / CachyOS:**
```bash
sudo pacman -S mpv
```

### 2. Install material-osc & thumbfast

Create the configuration directories:
```bash
mkdir -p ~/.config/mpv/scripts
```

Download the latest version of **material-osc** from the [GitHub Releases](https://github.com/brahmkshatriya/material-osc/releases) page, extract it, and place `material-osc.lua` and the `material-osc/` folder inside `~/.config/mpv/scripts/`.

Download **thumbfast** for on-the-fly timeline thumbnail previews:
```bash
curl -L https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua -o ~/.config/mpv/scripts/thumbfast.lua
```

### 3. Configure mpv.conf

Create/edit `~/.config/mpv/mpv.conf` to disable the default player UI (preventing overlap) and enable smooth synchronization:

```ini
# Recommended settings for material-osc
video-sync=display-resample
force-window=yes

# Disable default OSC to avoid overlap with material-osc
osc=no
```

---

## Layout Structure

The final layout of your `~/.config/mpv` directory should look like this:

```text
mpv/
├── mpv.conf
└── scripts/
    ├── material-osc.lua
    ├── thumbfast.lua
    └── material-osc/
        ├── GoogleSansFlex.ttf
        └── MaterialSymbolsRoundedUnfilled.ttf
```
