#!/bin/bash
# Dolphin File Manager — Tag Toggle Installer

echo "Installing Dolphin Tag Toggle Feature..."

# 1. Check for attr dependency
echo "[1/5] Checking dependencies..."
if ! command -v getfattr &>/dev/null || ! command -v setfattr &>/dev/null; then
    echo "ERROR: 'attr' package is not installed."
    echo "       Install it first:  sudo dnf install attr"
    exit 1
fi
echo "       attr tools found."

# 2. Create toggle-tag.sh
echo "[2/5] Creating toggle-tag.sh..."
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/toggle-tag.sh
#!/bin/bash

# Usage: toggle-tag.sh <TAG_ICON|CLEAR> <FILE_PATHS...>

TAG="$1"
shift

for FILE in "$@"; do
    # 1. Handle Clear Action
    if [ "$TAG" == "CLEAR" ]; then
        setfattr -x user.xdg.tags "$FILE" 2>/dev/null
        continue
    fi

    # 2. Handle Toggle Logic
    CURRENT_TAGS=$(getfattr --absolute-names --only-values -n user.xdg.tags "$FILE" 2>/dev/null || true)

    if [ -z "$CURRENT_TAGS" ]; then
        # No existing tags — just set the new one
        setfattr -n user.xdg.tags -v "$TAG" "$FILE"
        continue
    fi

    # Pad with commas for accurate matching
    PADDED_TAGS=",$CURRENT_TAGS,"

    if [[ "$PADDED_TAGS" == *",$TAG,"* ]]; then
        # REMOVE tag
        NEW_TAGS="${PADDED_TAGS//,$TAG,/,}"
        NEW_TAGS="${NEW_TAGS#,}"
        NEW_TAGS="${NEW_TAGS%,}"

        if [ -z "$NEW_TAGS" ]; then
            setfattr -x user.xdg.tags "$FILE" 2>/dev/null
        else
            setfattr -n user.xdg.tags -v "$NEW_TAGS" "$FILE"
        fi
    else
        # ADD tag
        setfattr -n user.xdg.tags -v "$CURRENT_TAGS,$TAG" "$FILE"
    fi
done
EOF
chmod +x ~/.local/bin/toggle-tag.sh

# 3. Create KDE Service Menu
echo "[3/5] Creating KDE service menu..."
mkdir -p ~/.local/share/kio/servicemenus
cat << EOF > ~/.local/share/kio/servicemenus/toggle_tags.desktop
[Desktop Entry]
Type=Service
MimeType=all/allfiles;
Actions=ToggleCheck;ToggleCross;ToggleStar;ClearTags;
X-KDE-Priority=TopLevel

[Desktop Action ToggleCheck]
Name=Tag: ✅
Icon=checkmark
Exec=$HOME/.local/bin/toggle-tag.sh "✅" %F

[Desktop Action ToggleCross]
Name=Tag: ❌
Icon=dialog-cancel
Exec=$HOME/.local/bin/toggle-tag.sh "❌" %F

[Desktop Action ToggleStar]
Name=Tag: ⭐
Icon=starred
Exec=$HOME/.local/bin/toggle-tag.sh "⭐" %F

[Desktop Action ClearTags]
Name=Clear All Tags
Icon=edit-clear
Exec=$HOME/.local/bin/toggle-tag.sh "CLEAR" %F
EOF
chmod +x ~/.local/share/kio/servicemenus/toggle_tags.desktop

# 4. Ensure Baloo is enabled (required for Dolphin's tag column)
echo "[4/5] Ensuring Baloo file indexer is enabled..."
if command -v balooctl6 &>/dev/null; then
    if balooctl6 status 2>&1 | grep -qi "disabled"; then
        balooctl6 enable 2>/dev/null || true
        echo "       Baloo enabled."
    else
        echo "       Baloo is already enabled."
    fi
else
    echo "WARNING: balooctl6 not found. Dolphin's 'Show Tags' column requires Baloo."
fi

# 5. Refresh KDE cache
echo "[5/5] Refreshing KDE cache..."
kbuildsycoca6 2>/dev/null || true

echo "============================================="
echo "Installation Complete!"
echo "Right-click any file in Dolphin to see the tag menu."
