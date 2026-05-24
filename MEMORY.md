# Project: linux-customization-scripts

## Overview
A collection of modular, independent scripts, configurations, and automation tools designed to customize, optimize, and enhance a Linux desktop system environment (e.g., Ghostty, Fish shell, Tmux, network tools, and media utilities) based on Arch Linux.

## Structure
```
/home/quantavil/Documents/Project/linux-customization-scripts/
├── adguard-home/         # AdGuard Home DNS server installer and configs
├── browser-shortcuts/    # Custom web browser shortcut mappings
├── bt/                   # Bluetooth connection automation utilities
├── copyparty/            # Copyparty media/file server setups
├── dolphin-tag/          # File tagging helper tools for Dolphin file manager
├── ghostty-setup/        # Ghostty terminal emulator configuration and fish shell integrations
│   ├── config.fish       # Core Fish interactive setup and tmux workspace profiles
│   ├── README.md         # Deployment steps
│   └── MEMORY.md         # Localized component memory
├── git-autosquash/       # Git autosquash automation utility
├── git-autosync/         # Automatic git synchronization tools
├── mpv/                  # MPV media player configurations and setup scripts
├── ms-fonts/             # Microsoft Core Fonts installation helper
├── shortcut/             # System keyboard shortcut utilities
└── wgcf/                 # WireGuard Cloudflare WARP client setup script
```

## Conventions
- **Modular Autonomy**: Each subdirectory is a self-contained component with apply and revert scripts.
- **Safe Execution**: Automation scripts should prompt user on steps requiring manual configurations rather than silently assuming/failing.

## Dependencies & Setup
- Varies by module; core configurations rely on pacman/paru (Arch Linux).
- Key tools include Ghostty, Fish, Tmux, Zoxide, Eza, Bat, Fzf.

## Critical Information
- Ensure stateful custom functions avoid side-effects across shell restarts.

## Insights
- Keep functions in config.fish optimized by utilizing Fish builtins rather than launching subshells where possible.

## Blunders
- None recorded yet.
