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
- Conversation memory uses a sliding window: old messages are summarized via API, recent 4 exchanges kept verbatim. History stored as JSON in `~/.config/groq-cli/history_<session>.json`.
- Pipe and search modes bypass history to prevent one-shot transforms from polluting context.
- `tee` after the jq streaming filter captures the full response for history without breaking real-time streaming.

## Blunders
- None recorded yet.
