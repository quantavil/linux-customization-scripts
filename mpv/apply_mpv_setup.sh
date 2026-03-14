#!/bin/bash
# MPV uosc + thumbfast Setup Script

echo "========================================="
echo "  MPV uosc + thumbfast Setup"
echo "========================================="
echo ""

# --- 1. Install uosc (user picks method) ---
echo "How would you like to install uosc?"
echo "  1) AUR (paru -S mpv-uosc)  [recommended]"
echo "  2) Official upstream script (curl installer)"
echo ""
read -rp "Pick [1/2]: " choice

case "$choice" in
    1)
        echo "[1/5] Installing uosc via AUR..."
        paru -S --noconfirm mpv-uosc
        ;;
    2)
        echo "[1/5] Installing uosc via official script..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/unix.sh)"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# --- 2. Create directories ---
echo "[2/5] Creating mpv config directories..."
mkdir -p ~/.config/mpv/scripts
mkdir -p ~/.config/mpv/script-opts
mkdir -p ~/.config/mpv/fonts

# --- 3. Configure mpv.conf ---
echo "[3/5] Writing mpv.conf..."
cat <<'EOF' > ~/.config/mpv/mpv.conf
osd-bar=no
border=no
save-position-on-quit=yes
watch-later-options=start,speed,volume
EOF

# --- 4. Configure input.conf ---
echo "[4/5] Writing input.conf..."
cat <<'EOF' > ~/.config/mpv/input.conf
p script-binding uosc/items
i vf toggle negate
EOF

# --- 5. Install & configure thumbfast ---
echo "[5/5] Installing thumbfast..."
curl -L https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua -o ~/.config/mpv/scripts/thumbfast.lua

cat <<'EOF' > ~/.config/mpv/script-opts/thumbfast.conf
# Enable hardware decoding
hwdec=yes

# Set maximum thumbnail dimensions
max_height=200
max_width=200

# Spawn thumbnailer on file load for faster initial previews
spawn_first=yes
EOF

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
