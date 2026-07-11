# Project: ghostty-setup

## Overview
A configuration and deployment repository for setting up a high-performance terminal and shell environment using Ghostty (terminal emulator) and Fish shell, optimized with various CLI utilities (e.g., eza, fzf, yazi, btop, fastfetch).

## Structure
```
/home/quantavil/Documents/Project/linux-customization-scripts/ghostty-setup/
├── ai              # CLI AI assistant with conversation memory using Groq API
├── config.fish     # Fish shell configuration file (aliases, tmux layouts, functions)
├── topgrade.toml   # Topgrade system updater configuration (Arch/paru, flatpak, custom scripts)
├── README.md       # Deployment and installation guide for the Ghostty + Fish environment
└── MEMORY.md       # Project memory and history
```

## Conventions
- **Fish Shell Scripts**: Keep logic fast, avoiding external subshells where builtins can be used.
- **Readability**: Code sections are clearly demarcated using header banners and comments.

## Dependencies & Setup
- Core: `fish`, `ghostty`, `yazi`, `btop`, `fastfetch`, `topgrade`, `jq`
- Optional: `firejail` (security containment), `paru`/`pacman` (package management, Arch Linux only)

## Critical Information
- Keep aliases clean and avoid breaking systems where pacman/paru/firejail are not installed.

## Insights
- Using `sed -nu '/^data: \[DONE\]/d; s/^data: //; p'` in the pipeline allows safely passing through both raw streaming lines and pretty-printed API error payloads.
- Conversation memory uses a sliding window: old messages are summarized via API, recent 4 exchanges kept verbatim. History stored as JSON in `~/.config/groq-cli/history.json`.
- Pipe and search modes bypass history to prevent one-shot transforms from polluting context.
- `tee` after the jq streaming filter captures the full response for history without breaking real-time streaming.
- Strip all reasoning blocks from non-streaming API completions using jq `gsub("<(think|reasoning)>[\\s\\S]*?</(think|reasoning)>"; "")`.
- Sanitize summary on load (`load_history`) to clean up pre-existing `<think>` blocks in `history.json`.
- To prevent EXIT trap from removing locks held by other concurrent instances, use a `HOLDS_LOCK` flag to track lock ownership.
- Parse the last HTTP status line from headers (e.g. via `awk`) to avoid silent failure on `100 Continue` responses.

## Blunders
- **Blunder**: EXIT trap unconditionally calling `unlock_history` deleted lock directories created by other concurrent instances.
  - **Fix**: Added `HOLDS_LOCK` ownership flag and only unlock if this instance acquired it.
- **Blunder**: Reading the first line of headers failed to detect 200 OK when `100 Continue` was returned first.
  - **Fix**: Parsed the last status line using `awk`.
- **Blunder**: Repetitive summary formatting loop occurred due to a persisted `<think>` block inside `history.json`'s summary field.
  - **Fix**: Added `gsub` sanitization to `load_history` to strip `<think>` tags on load.

