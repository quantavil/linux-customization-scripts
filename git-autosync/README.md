# Git Auto-Sync

Here is the stepwise implementation for a highly scalable auto-synchronisation pipeline. It uses a central configuration file to manage multiple repository paths and dynamically detects the active branch for each.

## Quick Setup

You can automate the setup and teardown of this pipeline using the provided shell scripts:

- **Setup:** Run `./apply_git-autosync_setup.sh` to configure the directory structure, install the sync script, and set up the systemd timers. 
  - **Manual Step:** During setup, the script will pause for you to manually add your absolute repository paths to `~/.config/git-autosync/repos.list`.
- **Teardown:** Run `./revert_git-autosync_setup.sh` to cleanly disable and remove the systemd service, timer, and sync script. You will be prompted if you'd like to retain or delete your configuration files.

Alternatively, follow the detailed manual instructions below.

---

## Manual Implementation Guide

### 1. Create the Configuration List

Store the target repositories in a dedicated list file. This allows you to add or remove repositories without modifying the core script.

```bash
mkdir -p ~/.config/git-autosync
micro ~/.config/git-autosync/repos.list
```

Add your absolute repository paths, one per line. You can include comments:

```text
# Main knowledge base
/home/quantavil/Documents/Obsx

# Add future projects here
#/home/quantavil/Projects/Chronos
#/home/quantavil/Projects/QuantFlow
```

### 2. Create the Synchronisation Script

Write the master script that iterates through the list.

```bash
mkdir -p ~/.local/bin
micro ~/.local/bin/git-autosync.sh
```

Paste the following logic. It handles dynamic branch resolution, skips invalid directories, and cleanly aborts conflicting rebases.

```bash
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
```

Make it executable:

```bash
chmod +x ~/.local/bin/git-autosync.sh
```

### 3. Configure the Systemd Service

Define the background task.

```bash
mkdir -p ~/.config/systemd/user/
micro ~/.config/systemd/user/git-autosync.service
```

Add the following configuration (replace `$HOME` with your home directory path, or use `%h` for the implicit home directory):

```ini
[Unit]
Description=Automated Git Repository Synchronisation
After=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/git-autosync.sh
```

### 4. Configure the Systemd Timer

Define the execution schedule.

```bash
micro ~/.config/systemd/user/git-autosync.timer
```

```ini
[Unit]
Description=Daily Git Auto-Sync Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

**Note:** `OnCalendar=daily` schedules the task for midnight (00:00:00). `Persistent=true` ensures that if your Fedora machine is asleep or powered off at midnight, the sync will trigger immediately upon the next boot.

### 5. Deploy the Pipeline

Reload the daemon and activate the timer.

```bash
systemctl --user daemon-reload
systemctl --user enable --now git-autosync.timer
```

### 6. Manual Trigger

Execute the service directly using `systemctl`. This bypasses the timer and runs your synchronisation script immediately.

```bash
systemctl --user start git-autosync.service
```

To verify the execution and view the script's output, check the recent journal logs for this specific service:

```bash
journalctl --user -u git-autosync.service -n 20 --no-pager
```

---

## Conflict Resolution Note

The `-X theirs` flag handles this automatically. Here's what happens:

```text
1 month offline, 50 local changes accumulated
                    ↓
        Connect to internet
                    ↓
        Script runs automatically
                    ↓
    Step 1: git add . && git commit     ← bundles all local changes
    Step 2: git pull --rebase -X theirs ← local wins every conflict silently
    Step 3: git push                    ← pushes everything up
                    ↓
                 ✓ Done
```

Even if someone pushed changes to the **same files** from another device (like your phone) during that month, `-X theirs` auto-resolves every conflict by keeping **your local version** without ever stopping to ask.

### One Caveat

The remote changes that conflict **will be silently overwritten** by your local version. Since this setup prefers your local edits, that's exactly what you want—just be aware that the other device's conflicting edits are discarded, not merged.