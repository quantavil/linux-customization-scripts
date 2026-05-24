# Project: ghostty-setup

## Overview
A configuration and deployment repository for setting up a high-performance terminal and shell environment using Ghostty (terminal emulator) and Fish shell, optimized with various CLI utilities (e.g., eza, fzf, yazi, btop, fastfetch).

## Structure
```
/home/quantavil/Documents/Project/linux-customization-scripts/ghostty-setup/
├── config.fish     # Fish shell configuration file (aliases, tmux layouts, functions)
├── README.md       # Deployment and installation guide for the Ghostty + Fish environment
└── MEMORY.md       # Project memory and history
```

## Conventions
- **Fish Shell Scripts**: Keep logic fast, avoiding external subshells where builtins can be used.
- **Readability**: Code sections are clearly demarcated using header banners and comments.

## Dependencies & Setup
- Core: `fish`, `ghostty`, `yazi`, `btop`, `fastfetch`
- Optional: `firejail` (security containment), `paru`/`pacman` (package management, Arch Linux only)

## Critical Information
- Keep aliases clean and avoid breaking systems where pacman/paru/firejail are not installed.

## Insights
- None recorded yet.

## Blunders
- None recorded yet.
