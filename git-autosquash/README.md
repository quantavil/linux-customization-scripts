# Git AutoSquash

A scheduled companion to [git-autosync](../git-autosync/). It compresses old commit history into a single archive snapshot while preserving recent commits, keeping your repositories lean without losing any file state.

Unlike `git-autosync`, this tool uses its **own** `repos.list` — not every repository should have its history squashed.

## Quick Setup

You can automate the setup and teardown of this pipeline using the provided shell scripts:

- **Setup:** Run `./apply_git-autosquash_setup.sh` to configure the repo list, install the squash script, and set up the systemd timer.
  - **Manual Step:** During setup, the script will pause for you to add the repositories you want squashed to `~/.config/git-autosquash/repos.list`.
- **Teardown:** Run `./revert_git-autosquash_setup.sh` to cleanly disable and remove the systemd service, timer, and squash script. You will be prompted if you'd like to retain or delete your configuration files.

Alternatively, follow the detailed manual instructions below.

---

## Manual Implementation Guide

### 1. Create the Repository List

Add **only** the repositories whose history you want squashed. One absolute path per line.

```bash
mkdir -p ~/.config/git-autosquash
micro ~/.config/git-autosquash/repos.list
```

```text
# Obsidian vault — safe to squash
/home/quantavil/Documents/Obsx

# NOT every repo belongs here — only repos where old history is disposable
# /home/quantavil/Projects/SomeProject
```

### 2. Create the Squash Script

```bash
mkdir -p ~/.local/bin
micro ~/.local/bin/git-squash-history.sh
```

Paste the following logic. Tune the settings at the top of the script to your preference.

```bash
#!/bin/bash
# ─────────────────────────────────────────────────────────
#  git-squash-history.sh
#  Squash old commits → Force push
#  Expects a clean working tree (run git-autosync first)
# ─────────────────────────────────────────────────────────

# ── Settings (edit these) ─────────────────────────────────
KEEP_DAYS=30   # squash commits older than this many days
KEEP_MIN=50    # always keep at least this many recent commits

REPOS_FILE="$HOME/.config/git-autosquash/repos.list"
# ──────────────────────────────────────────────────────────

if [[ ! -f "$REPOS_FILE" ]]; then
    echo "Error: Repo list missing at $REPOS_FILE" >&2
    exit 1
fi

echo "Settings: KEEP_DAYS=$KEEP_DAYS  KEEP_MIN=$KEEP_MIN"
echo ""

while IFS= read -r REPO_DIR || [[ -n "$REPO_DIR" ]]; do
    [[ -z "$REPO_DIR" || "$REPO_DIR" =~ ^# ]] && continue
    REPO_DIR="${REPO_DIR/#\~/$HOME}"

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "Warning: Not a git repo → $REPO_DIR" >&2
        continue
    fi

    echo "════════════════════════════════════"
    echo "Processing: $REPO_DIR"
    echo "════════════════════════════════════"

    (
        cd "$REPO_DIR" || exit 1

        BRANCH=$(git rev-parse --abbrev-ref HEAD)

        if [[ "$BRANCH" == "HEAD" ]]; then
            echo "Warning: Detached HEAD, skipping." >&2
            exit 1
        fi

        # ── Commit any dirty files before squashing ──────────
        if [[ -n "$(git status --porcelain)" ]]; then
            echo "→ Committing uncommitted changes..."
            git add .
            git commit -m "Auto-commit before squash: $(date +'%Y-%m-%d %H:%M:%S')"
        else
            echo "→ Working tree clean."
        fi

        # ── STEP 1: Fetch latest refs from remote ─────────────
        if ! git ls-remote origin &>/dev/null; then
            echo "✗ Cannot reach remote. Skipping $REPO_DIR" >&2
            exit 1
        fi

        git fetch origin "$BRANCH" -q

        # ── STEP 2: Find cutoff commit ────────────────────────
        CUTOFF_HASH=$(git log --before="${KEEP_DAYS} days ago" \
                      --format="%H" | head -1)

        if [[ -z "$CUTOFF_HASH" ]]; then
            echo "ℹ No commits older than ${KEEP_DAYS} days. Nothing to squash."
            exit 0
        fi

        # ── STEP 3: Safety check — keep at least KEEP_MIN ─────
        RECENT_COUNT=$(git rev-list "$CUTOFF_HASH"..HEAD --count)

        if [[ "$RECENT_COUNT" -lt "$KEEP_MIN" ]]; then
            echo "ℹ Only $RECENT_COUNT recent commits (min: $KEEP_MIN). Skipping."
            exit 0
        fi

        TOTAL_BEFORE=$(git rev-list --count HEAD)
        ARCHIVE_DATE=$(git log "$CUTOFF_HASH" -1 \
                       --format="%ci" | cut -d' ' -f1)

        echo "→ Total commits   : $TOTAL_BEFORE"
        echo "→ Recent (kept)   : $RECENT_COUNT"
        echo "→ To be squashed  : $((TOTAL_BEFORE - RECENT_COUNT))"
        echo "→ Archive up to   : $ARCHIVE_DATE"

        # ── STEP 4: Create orphan base ────────────────────────
        git checkout --orphan squash-base -q
        git rm -rf . -q

        # ── STEP 5: Restore state at the cutoff point ─────────
        git checkout "$CUTOFF_HASH" -- . 2>/dev/null

        # ── STEP 6: Commit as single archive snapshot ─────────
        git add -A
        git commit -q \
            -m "chore: squashed history up to ${ARCHIVE_DATE}" \
            --allow-empty

        SQUASH_BASE=$(git rev-parse HEAD)

        # ── STEP 7: Replay recent commits on top ──────────────
        git checkout -q "$BRANCH"

        git rebase --onto "$SQUASH_BASE" "$CUTOFF_HASH" "$BRANCH" \
            -X theirs -q || {
            echo "✗ Rebase onto squash base failed. Rolling back." >&2
            git rebase --abort
            git branch -D squash-base 2>/dev/null
            exit 1
        }

        # ── STEP 8: Cleanup ──────────────────────────────────
        git branch -D squash-base 2>/dev/null
        git reflog expire --expire=now --all -q
        git gc --prune=now -q

        TOTAL_AFTER=$(git rev-list --count HEAD)
        echo "✓ Squash done: $TOTAL_BEFORE → $TOTAL_AFTER commits"

        # ── STEP 9: Force push squashed history ───────────────
        git push origin "$BRANCH" --force && \
            echo "✓ Force pushed to origin/$BRANCH" || {
            echo "✗ Force push failed." >&2
            exit 1
        }
    )

done < "$REPOS_FILE"

echo ""
echo "════════════════════════════════════"
echo "All repos processed."
echo "════════════════════════════════════"
```

Make it executable:

```bash
chmod +x ~/.local/bin/git-squash-history.sh
```

### 3. Configure the Systemd Service

```bash
mkdir -p ~/.config/systemd/user/
micro ~/.config/systemd/user/git-squash-history.service
```

```ini
[Unit]
Description=Git History Squasher
After=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/git-squash-history.sh
```

### 4. Configure the Systemd Timer

Choose a schedule:

| Schedule | `OnCalendar` value |
|---|---|
| Daily at 3 AM | `*-*-* 03:00:00` |
| Weekly (Sunday 3 AM) | `Sun 03:00:00` |
| Biweekly (1st & 15th at 3 AM) | `*-*-1,15 03:00:00` |

```bash
micro ~/.config/systemd/user/git-squash-history.timer
```

```ini
[Unit]
Description=Git Squash Timer

[Timer]
OnCalendar=Sun 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

**Note:** `Persistent=true` ensures that if the machine is off or asleep at the scheduled time, the squash will trigger immediately on the next boot.

### 5. Deploy the Pipeline

```bash
systemctl --user daemon-reload
systemctl --user enable --now git-squash-history.timer
```

### 6. Manual Trigger

```bash
systemctl --user start git-squash-history.service
```

To verify the output:

```bash
journalctl --user -u git-squash-history.service -n 20 --no-pager
```

---

## Configuration Reference

All settings are at the top of `~/.local/bin/git-squash-history.sh`:

| Variable | Default | Description |
|---|---|---|
| `KEEP_DAYS` | `30` | Squash commits older than this many days |
| `KEEP_MIN` | `50` | Always keep at least this many recent commits, even if they're older than `KEEP_DAYS` |

The timer schedule is set in `~/.config/systemd/user/git-squash-history.timer` via the `OnCalendar` directive.

---

## Full Flow Visualised

```
BEFORE SQUASH:
  [old1]─[old2]─[old3]──...──[old500]─[recent1]─[recent2]─[recent3]
  ←────── older than 30 days ────────→ ←──── last 30 days ─────────→

STEP 1 — guard:
  dirty tree? → abort (run git-autosync first)

STEP 2 — fetch:
  origin/main ──→ refs updated ✓

STEP 3 — squash old into one:
  [📦 archive "up to 2024-01-01"]─[recent1]─[recent2]─[recent3]

STEP 4 — force push:
  origin/main ← updated ✓
```

---

## How It Fits With Your Existing Pipeline

| Script | Runs | Config | Job |
|---|---|---|---|
| `git-autosync.sh` | Daily | `~/.config/git-autosync/repos.list` | commit + pull + push |
| `git-squash-history.sh` | Configurable | `~/.config/git-autosquash/repos.list` | fetch + squash + force push |

Each tool has its **own** `repos.list` — only add repos to the squash list if you're okay discarding their old commit history.