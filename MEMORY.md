# Project: linux-customization-scripts

## Overview
A collection of standalone utilities, configuration scripts, and customization setups for Linux desktop environments (e.g., Ghostty, MPV, Dolphin, Wireguard, AdGuard, Git automation). The scripts are written in Bash, Fish, Python, etc.

## Structure
- `adguard-home/`       # AdGuard Home setup scripts
- `aikular/`            # Custom markdown note helper (Python parser/render scripts)
- `browser-shortcuts/`  # Custom browser shortcuts and keys
- `bt/`                 # Bluetooth configuration helper
- `copyparty/`          # Setup for file-sharing web server (copyparty)
- `dolphin-tag/`        # Tagging support scripts for Dolphin file manager
- `ghostty-setup/`      # Setup/config files for Ghostty & Fish (includes lightweight 'ai' Groq CLI)
- `git-autosquash/`     # Git auto-squashing scripts
- `git-autosync/`       # Automated git sync utilities
- `mpv/`                # MPV media player configurations
- `ms-fonts/`           # Microsoft Fonts installation helpers
- `shortcut/`           # Custom keyboard/launcher shortcuts
- `wgcf/`               # Cloudflare WARP (wgcf) setup scripts
- `MEMORY.md`           # This memory file

## Conventions
- Every customization/feature has its own subdirectory.
- Scripts are modular and typically include an apply script (e.g., `apply_*.sh`) and a revert script (e.g., `revert_*.sh`).
- Use minimal and direct implementations.

## Dependencies & Setup
- Shell environments: Bash/Fish.
- Python 3.x is used for some utilities (e.g. `aikular`).
- `jq` and `curl` for the `ai` command CLI.

## Critical Information
- None currently.

## Insights
- Keep scripts focused and surgical to avoid breaking systems.
- Streaming responses with curl & jq can be done efficiently in a single line pipeline. Use `sed -nu '/^data: \[DONE\]/d; s/^data: //; p'` before `jq -j --unbuffered` to gracefully handle both SSE lines and pretty-printed API error JSON.
- In `jq`, negation of `.prop` must be written as `(.prop | not)` since `not .prop` is parsed as `(not) .prop`.
- Non-streaming API calls (like summarization) can contain `<think>` blocks. Strip them using jq `sub("<(think|reasoning)>[\\s\\S]*?</(think|reasoning)>"; "")` before saving to history.

## Blunders
- **Blunder**: `jq: error: Cannot index boolean with string ("started")` during streaming.
  - **Root Cause**: Outer `if` lacked `else .` returning false, and `not .started` evaluated as `(not) .started`.
  - **Fix**: Added `else .` to return state, and wrapped negation as `(.started | not)`.
