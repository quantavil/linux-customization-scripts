# Dolphin Tag Toggle

Adds a right-click menu to Dolphin file manager for toggling emoji tags (✅, ❌, ⭐) on files using extended attributes (`user.xdg.tags`). Includes a "Clear All Tags" option.

---

## What the scripts do

### `apply_dolphin_tags.sh`
1. Checks that the `attr` package is installed (exits with error if not)
2. Creates `~/.local/bin/toggle-tag.sh` — the core script that adds/removes/clears tags on files using `setfattr`/`getfattr`
3. Creates `~/.local/share/kio/servicemenus/toggle_tags.desktop` — KDE service menu that adds tag buttons to Dolphin's right-click menu
4. Enables Baloo file indexer if disabled (required for Dolphin's "Tags" column)
5. Refreshes KDE config cache (`kbuildsycoca6`)

### `revert_dolphin_tags.sh`
1. Scans `$HOME` and strips `user.xdg.tags` from all tagged files
2. Removes `~/.local/bin/toggle-tag.sh`
3. Removes `~/.local/share/kio/servicemenus/toggle_tags.desktop`
4. Purges Baloo index and disables Baloo
5. Kills Dolphin (reopen manually for a clean state)

---

## Prerequisites (Manual)

Install the `attr` package (provides `getfattr`/`setfattr`):

```bash
sudo dnf install attr
```

---

## 🚀 Install

```bash
chmod +x apply_dolphin_tags.sh
./apply_dolphin_tags.sh
```

## 🗑️ Revert

```bash
chmod +x revert_dolphin_tags.sh
./revert_dolphin_tags.sh
```

> **Note:** Revert disables Baloo. To re-enable manually: `balooctl6 enable`

---

## Show Tags in Dolphin

After installing:
1. Open Dolphin → **View** → **Details** view mode
2. Right-click the column header → check **Tags**

---

## Customization

To add or change tag emojis, add new `[Desktop Action]` blocks in `~/.local/share/kio/servicemenus/toggle_tags.desktop`. Re-run `kbuildsycoca6` after changes.
