#!/bin/bash
set -euo pipefail

echo "[AUTO] Creating configuration directory..."
mkdir -p "$HOME/.config/git-autosquash"
REPOS_FILE="$HOME/.config/git-autosquash/repos.list"

if [[ ! -f "$REPOS_FILE" ]]; then
    cat << 'EOF' > "$REPOS_FILE"
# Absolute paths to repositories where old history is disposable.
# /home/username/Documents/Obsx
EOF
fi

echo "[MANUAL] Edit $REPOS_FILE with target repo paths."
read -p "Press Enter when done..."

echo -e "\n[MANUAL] Choose a squash schedule:\n 1) Daily\n 2) Weekly (Sun)\n 3) Biweekly (1st & 15th)"
read -p "Choice [1-3, default=2]: " SCHEDULE_CHOICE

case "${SCHEDULE_CHOICE:-2}" in
    1) ON_CALENDAR="*-*-* 03:00:00" ;;
    2) ON_CALENDAR="Sun 03:00:00" ;;
    3) ON_CALENDAR="*-*-1,15 03:00:00" ;;
    *) ON_CALENDAR="Sun 03:00:00" ;;
esac

mkdir -p "$HOME/.local/bin"
SCRIPT_FILE="$HOME/.local/bin/git-squash-history.sh"

cat << 'SCRIPTEOF' > "$SCRIPT_FILE"
#!/bin/bash
set -eo pipefail

KEEP_DAYS=30
KEEP_MIN=50
REPOS_FILE="$HOME/.config/git-autosquash/repos.list"

[[ ! -f "$REPOS_FILE" ]] && { echo "Error: Missing $REPOS_FILE" >&2; exit 1; }

EXIT_STATUS=0

while IFS= read -r REPO_DIR || [[ -n "$REPO_DIR" ]]; do
    [[ -z "$REPO_DIR" || "$REPO_DIR" =~ ^# ]] && continue
    REPO_DIR="${REPO_DIR/#\~/$HOME}"

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "Warning: Not a git repo -> $REPO_DIR" >&2
        continue
    fi

    echo "Processing: $REPO_DIR"

    (
        cd "$REPO_DIR"
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        [[ "$BRANCH" == "HEAD" ]] && { echo "Error: Detached HEAD" >&2; exit 1; }

        git ls-remote origin &>/dev/null || { echo "Error: Remote unreachable" >&2; exit 1; }
        git fetch origin "$BRANCH" -q

        TMP_DIR=$(mktemp -d)
        git worktree add --detach "$TMP_DIR" "$BRANCH" -q

        (
            cd "$TMP_DIR"
            TOTAL_COMMITS=$(git rev-list --count HEAD)

            if [[ "$TOTAL_COMMITS" -le "$KEEP_MIN" ]]; then
                echo "Info: Total commits ($TOTAL_COMMITS) <= KEEP_MIN ($KEEP_MIN). Skipping."
                exit 0
            fi

            TIME_CUTOFF_HASH=$(git log --before="${KEEP_DAYS} days ago" -n 1 --format="%H")
            if [[ -z "$TIME_CUTOFF_HASH" ]]; then
                echo "Info: No commits older than $KEEP_DAYS days. Skipping."
                exit 0
            fi

            TIME_RETAINED_COUNT=$(git rev-list "$TIME_CUTOFF_HASH"..HEAD --count)

            if [[ "$TIME_RETAINED_COUNT" -lt "$KEEP_MIN" ]]; then
                CUTOFF_HASH=$(git rev-parse "HEAD~$KEEP_MIN")
                echo "-> Time window has only $TIME_RETAINED_COUNT commits. Shifting cutoff to keep last $KEEP_MIN commits."
            else
                CUTOFF_HASH="$TIME_CUTOFF_HASH"
                echo "-> Time window has $TIME_RETAINED_COUNT commits (>= $KEEP_MIN). Using 30-day cutoff."
            fi

            TOTAL_BEFORE=$(git rev-list --count HEAD)
            ARCHIVE_DATE=$(git log "$CUTOFF_HASH" -1 --format="%ci" | cut -d' ' -f1)

            SQUASH_BASE=$(git commit-tree "$CUTOFF_HASH^{tree}" -m "chore: squashed history up to ${ARCHIVE_DATE}")

            git rebase --onto "$SQUASH_BASE" "$CUTOFF_HASH" HEAD -X theirs -q

            git reflog expire --expire=now --all -q
            git gc --prune=now -q
            git push origin HEAD:"$BRANCH" --force -q
            echo "Success: $TOTAL_BEFORE -> $(git rev-list --count HEAD) commits."
        )

        # Fixed: Removed -q switch, descriptors handled via redirection
        git worktree remove "$TMP_DIR" --force &>/dev/null
        rm -rf "$TMP_DIR"

        git fetch origin "$BRANCH" -q
        git reset --soft "origin/$BRANCH"

    ) || EXIT_STATUS=$((EXIT_STATUS + 1))
done < "$REPOS_FILE"

exit "$EXIT_STATUS"
SCRIPTEOF

chmod +x "$SCRIPT_FILE"

mkdir -p "$HOME/.config/systemd/user"
SERVICE_FILE="$HOME/.config/systemd/user/git-squash-history.service"
TIMER_FILE="$HOME/.config/systemd/user/git-squash-history.timer"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Git History Squasher
After=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/git-squash-history.sh
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

systemctl --user daemon-reload
systemctl --user enable --now git-squash-history.timer
echo "Setup complete."
