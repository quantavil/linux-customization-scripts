#!/bin/bash

echo "Starting git-autosync setup..."
echo

# Step 1: Config file
echo "[AUTO] Creating configuration directory..."
mkdir -p "$HOME/.config/git-autosync"
CONFIG_FILE="$HOME/.config/git-autosync/repos.list"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[AUTO] Creating template repos.list..."
    cat << 'EOF' > "$CONFIG_FILE"
# Main knowledge base
# /home/username/Documents/Obsx

# Add future projects here
# /home/username/Projects/ProjectName
EOF
else
    echo "[AUTO] Found existing repos.list."
fi

echo
echo "[MANUAL] Please edit $CONFIG_FILE and add the absolute paths to your repositories, one per line."
read -p "Press Enter when done..." 

# Step 2: Sync Script
echo
echo "[AUTO] Creating git-autosync.sh script..."
mkdir -p "$HOME/.local/bin"
SCRIPT_FILE="$HOME/.local/bin/git-autosync.sh"

cat << 'EOF' > "$SCRIPT_FILE"
#!/bin/bash

CONFIG_FILE="$HOME/.config/git-autosync/repos.list"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file missing at $CONFIG_FILE" >&2
    exit 1
fi

while IFS= read -r REPO_DIR || [[ -n "$REPO_DIR" ]]; do
    [[ -z "$REPO_DIR" || "$REPO_DIR" =~ ^# ]] && continue
    REPO_DIR="${REPO_DIR/#\~/$HOME}"

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "Warning: Not a valid Git repository -> $REPO_DIR" >&2
        continue
    fi

    echo "Synchronising: $REPO_DIR"

    (
        cd "$REPO_DIR" || exit 1

        BRANCH=$(git rev-parse --abbrev-ref HEAD)

        if [[ "$BRANCH" == "HEAD" ]]; then
            echo "Warning: Detached HEAD state in $REPO_DIR. Skipping." >&2
            exit 1
        fi

        # Connectivity check
        if ! git ls-remote origin &>/dev/null; then
            echo "Error: Cannot reach remote for $REPO_DIR. Skipping." >&2
            exit 1
        fi

        # 1. Commit local changes FIRST (fixes dirty tree error)
        if [[ -n "$(git status --porcelain)" ]]; then
            git add .
            git commit -m "Auto-sync: $(date +'%Y-%m-%d %H:%M:%S')"
        fi

        # 2. Pull with rebase, LOCAL wins on conflict
        git pull --rebase -X theirs origin "$BRANCH" || {
            echo "Error: Rebase failed in $REPO_DIR. Aborting." >&2
            git rebase --abort
            exit 1
        }

        # 3. Push
        git push origin "$BRANCH" || {
            echo "Error: Push failed for $REPO_DIR." >&2
            exit 1
        }
    )

done < "$CONFIG_FILE"
EOF

chmod +x "$SCRIPT_FILE"

# Step 3 & 4: Systemd Service and Timer
echo "[AUTO] Creating systemd service and timer files..."
mkdir -p "$HOME/.config/systemd/user"
SERVICE_FILE="$HOME/.config/systemd/user/git-autosync.service"
TIMER_FILE="$HOME/.config/systemd/user/git-autosync.timer"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Automated Git Repository Synchronisation
After=network-online.target

[Service]
Type=oneshot
ExecStart=$HOME/.local/bin/git-autosync.sh
EOF

cat << 'EOF' > "$TIMER_FILE"
[Unit]
Description=Daily Git Auto-Sync Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Step 5: Deploy Pipeline
echo "[AUTO] Reloading systemd daemon..."
systemctl --user daemon-reload
echo "[AUTO] Enabling and starting git-autosync.timer..."
systemctl --user enable --now git-autosync.timer

echo
echo "Setup is complete. git-autosync will now run daily at midnight, or you can trigger it manually with:"
echo "systemctl --user start git-autosync.service"
