# Git AutoSquash

Automated history compaction utility designed to compress old commits into a single parentless root commit object using Git plumbing tools, preserving current working states and recent history entries.

## Management Automations

### Setup Engine Execution
Deploys configuration frameworks, compiling targets, and schedules user-level runtime parameters:
```bash
./apply_git-autosquash_setup.sh

```

### Teardown Engine Execution

Uninstalls runtime units, handles systemd state changes, and provides interactive control over config purging:

```bash
./revert_git-autosquash_setup.sh

```

---

## Manual Architecture Breakdown

### 1. File Configuration

Define specific absolute system target structures inside `~/.config/git-autosquash/repos.list`:

```text
/home/quantavil/Documents/Obsx

```

### 2. Systemd Runtime Configuration

`~/.config/systemd/user/git-squash-history.service`:

```ini
[Unit]
Description=Git History Squasher
After=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/git-squash-history.sh

```

`~/.config/systemd/user/git-squash-history.timer`:

```ini
[Unit]
Description=Git Squash Timer

[Timer]
OnCalendar=Sun 03:00:00
Persistent=true

[Install]
WantedBy=timers.target

```

### 3. Runtime Verification

Evaluate logs directly via the systemd user journal:

```bash
journalctl --user -u git-squash-history.service -n 50 --no-pager

```
