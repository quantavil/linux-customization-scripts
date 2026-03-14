
## Quick Setup (Script)

Run the apply script to install everything automatically. It will ask you to choose between AUR and upstream for uosc.

```bash
bash mpv/apply_mpv_setup.sh
```

To revert all changes:

```bash
bash mpv/revert_mpv_setup.sh
```

---

## Manual Setup

Here is the streamlined, automated setup for CachyOS.

### 1. Installation

Since you are on an Arch-based distribution, managing this via the AUR is the absolute least manual approach. It handles future updates automatically.

**Primary Method (AUR):**

```bash
paru -S mpv-uosc

```

**Alternative Method (Official Script):**
If you prefer upstream delivery, the developer provides a one-line installer. It requires `curl` and `unzip`.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/unix.sh)"

```

### 2. Configure mpv

You must disable the default UI to prevent overlapping. Open your mpv configuration:

```bash
micro ~/.config/mpv/mpv.conf

```

Add these lines to integrate uosc and retain your preferred playback persistence:

```ini
osd-bar=no
border=no
save-position-on-quit=yes
watch-later-options=start,speed,volume

```

### 3. Custom Keybindings

Set up your custom shortcuts for the unified menu and video filters.

```bash
micro ~/.config/mpv/input.conf

```

Paste your binds:

```plaintext
p script-binding uosc/items
i vf toggle negate

```

### 4. Thumbfast


```bash
mkdir -p ~/.config/mpv/scripts
curl -L https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua -o ~/.config/mpv/scripts/thumbfast.lua

```

### 5. Configuration 

While it works out of the box, you can force hardware decoding for thumbnail generation to reduce CPU load.

Create the configuration file:

```bash
mkdir -p ~/.config/mpv/script-opts
micro ~/.config/mpv/script-opts/thumbfast.conf

```

Paste these parameters:

```ini
# Enable hardware decoding
hwdec=yes

# Set maximum thumbnail dimensions
max_height=200
max_width=200

# Spawn thumbnailer on file load for faster initial previews
spawn_first=yes

```

---

## Manual Setup (Zip Method)

### 1. Prerequisites

Ensure `mpv` is installed and you have the following files downloaded:

- `uosc.zip` (The main script package).
    
- `uosc.conf` (The configuration file).
    


### 2. Directory Structure

Create the necessary folder hierarchy within your mpv configuration directory:

```bash
mkdir -p ~/.config/mpv/scripts
mkdir -p ~/.config/mpv/script-opts
mkdir -p ~/.config/mpv/fonts
```

---

### 3. Installation Steps

#### Step A: Extract the Script

Navigate to your mpv config directory and unzip the package:

```bash
cd ~/.config/mpv
unzip ~/Downloads/uosc.zip
```

#### Step B: Configure the Default mpv Behavior

To prevent the default mpv UI from overlapping with `uosc`, you must modify `mpv.conf`. Run the following command:

```bash
echo -e "save-position-on-quit=yes\nwatch-later-options=start,speed,volume" >> ~/.config/mpv/mpv.conf
```
Or edit `~/.config/mpv/mpv.conf` manually:

```ini
# Disable default UI for uosc
osc=no
osd-bar=no
border=no

# Persistence settings
save-position-on-quit=yes
watch-later-options=start,speed,volume

```
#### Step C: Install the `uosc.conf`

Move your custom configuration file to the `script-opts` folder:

```bash
mv ~/Downloads/uosc.conf ~/.config/mpv/script-opts/
```

---

### 4. Custom Keybindings (`input.conf`)

Create or edit your `input.conf` file:

```bash
kwrite ~/.config/mpv/input.conf
```

Paste the following configuration:

```plaintext
# --- uosc specific bindings ---
# Opens unified menu for Playlist and File Browser
p script-binding uosc/items

# --- Video Filters ---
# Toggle Invert Colors (Negate)
i vf toggle negate

```

---

### 5. Summary of Controls

| **Action**                | **Key** | **Description**                                                        |
| ------------------------- | ------- | ---------------------------------------------------------------------- |
| **Menu (Playlist/Files)** | `p`     | Opens the `uosc` item menu to switch between playlist and local files. |
| **Invert Colors**         | `i`     | Toggles the `negate` video filter.                                     |
