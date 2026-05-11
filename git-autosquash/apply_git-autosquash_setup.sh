#!/bin/bash

echo "Starting git-autosquash setup..."
echo

# Step 1: Repo list
echo "[AUTO] Creating configuration directory..."
mkdir -p "$HOME/.config/git-autosquash"
REPOS_FILE="$HOME/.config/git-autosquash/repos.list"

if [[ ! -f "$REPOS_FILE" ]]; then
    echo "[AUTO] Creating template repos.list..."
    cat << 'EOF' > "$REPOS_FILE"
# Only add repos whose old history is disposable.
# NOT the same as git-autosync — be selective.

# /home/username/Documents/Obsx
# /home/username/Projects/SomeProject
EOF
else
    echo "[AUTO] Found existing repos.list."
fi

echo
echo "[MANUAL] Please edit $REPOS_FILE and add the absolute paths to the repositories you want squashed."
read -p "Press Enter when done..."

# Step 2: Choose schedule
echo
echo "[MANUAL] Choose a squash schedule:"
echo "  1) Daily at 3 AM"
echo "  2) Weekly (Sunday 3 AM)"
echo "  3) Biweekly (1st & 15th at 3 AM)"
echo
read -p "Enter choice [1-3, default=2]: " SCHEDULE_CHOICE

case "${SCHEDULE_CHOICE:-2}" in
    1) ON_CALENDAR="*-*-* 03:00:00"; SCHEDULE_DESC="daily at 3 AM" ;;
    2) ON_CALENDAR="Sun 03:00:00"; SCHEDULE_DESC="weekly (Sunday 3 AM)" ;;
    3) ON_CALENDAR="*-*-1,15 03:00:00"; SCHEDULE_DESC="biweekly (1st & 15th at 3 AM)" ;;
    *)
        echo "Invalid choice, defaulting to weekly."
        ON_CALENDAR="Sun 03:00:00"
        SCHEDULE_DESC="weekly (Sunday 3 AM)"
        ;;
esac

echo "[AUTO] Schedule set to: $SCHEDULE_DESC"

# Step 3: Squash Script
echo
echo "[AUTO] Creating git-squash-history.sh script..."
mkdir -p "$HOME/.local/bin"
SCRIPT_FILE="$HOME/.local/bin/git-squash-history.sh"

cat << 'SCRIPTEOF' > "$SCRIPT_FILE"
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
SCRIPTEOF

chmod +x "$SCRIPT_FILE"

# Step 4: Systemd Service and Timer
echo "[AUTO] Creating systemd service and timer files..."
mkdir -p "$HOME/.config/systemd/user"
SERVICE_FILE="$HOME/.config/systemd/user/git-squash-history.service"
TIMER_FILE="$HOME/.config/systemd/user/git-squash-history.timer"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Git History Squasher
After=network-online.target

[Service]
Type=oneshot
ExecStart=$HOME/.local/bin/git-squash-history.sh
EOF

cat << EOF > "$TIMER_FILE"
[Unit]
Description=Git Squash Timer

[Timer]
OnCalendar=$ON_CALENDAR
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Step 5: Deploy Pipeline
echo "[AUTO] Reloading systemd daemon..."
systemctl --user daemon-reload
echo "[AUTO] Enabling and starting git-squash-history.timer..."
systemctl --user enable --now git-squash-history.timer

echo
echo "Setup complete!"
echo "  Schedule  : $SCHEDULE_DESC"
echo "  Repo list : $REPOS_FILE"
echo "  Settings  : Edit KEEP_DAYS and KEEP_MIN at the top of $SCRIPT_FILE"
echo
echo "Trigger manually with:"
echo "  systemctl --user start git-squash-history.service"
