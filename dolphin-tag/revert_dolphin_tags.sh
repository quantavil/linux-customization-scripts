#!/bin/bash
# Dolphin File Manager — Tag Toggle Reverter (Full Reset)

echo "Full Reset: Dolphin Tag Toggle Feature..."

# 1. Clear all xdg tags from files
echo "[1/5] Clearing all xdg tags from files..."
CLEARED=0
while IFS= read -r FILE; do
    setfattr -x user.xdg.tags "$FILE" 2>/dev/null && ((CLEARED++))
done < <(getfattr -R --absolute-names -n user.xdg.tags "$HOME" 2>/dev/null | grep "^/" || true)
echo "       Cleared tags from $CLEARED file(s)."

# 2. Remove toggle-tag.sh
echo "[2/5] Removing toggle-tag.sh..."
rm -f ~/.local/bin/toggle-tag.sh

# 3. Remove KDE Service Menu
echo "[3/5] Removing KDE service menu..."
rm -f ~/.local/share/kio/servicemenus/toggle_tags.desktop

# 4. Purge Baloo index (removes stale cached tags)
echo "[4/5] Purging Baloo index..."
if command -v balooctl6 &>/dev/null; then
    balooctl6 disable 2>/dev/null
    rm -rf ~/.local/share/baloo/index ~/.local/share/baloo/index-lock
    echo "       Baloo index purged and disabled."
else
    echo "       balooctl6 not found, skipping."
fi

# 5. Refresh KDE cache + restart Dolphin
echo "[5/5] Refreshing KDE cache and restarting Dolphin..."
kbuildsycoca6 2>/dev/null
if pgrep -x dolphin &>/dev/null; then
    killall dolphin 2>/dev/null
    echo "       Dolphin was restarted. Reopen it manually."
else
    echo "       Dolphin was not running."
fi

echo "============================================="
echo "Full Reset Complete!"
echo "All tags cleared, Baloo index purged, menu removed."
