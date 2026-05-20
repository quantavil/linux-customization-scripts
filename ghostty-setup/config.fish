# ==============================================================================
# NATIVE INTERACTIVE SHELL INITIALIZATION
# ==============================================================================
if status is-interactive    
    # Initialize frecency-based directory tracker
    zoxide init fish | source
end

# ==============================================================================
# SECURITY SANDBOXING DEFINITIONS
# ==============================================================================
# Force network tools and isolated modules through containment layers
alias curl="firejail curl"
alias wget="firejail wget"
alias pip="python3 -m pip"

# ==============================================================================
# CORE NAVIGATION AND FILE MANIPULATION ALIASES
# ==============================================================================
# Map standard paths to eza features with strict group structuring
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -l"
alias la="eza --icons --group-directories-first -la"
alias tree="eza --icons --tree"

# General short-hand utilities
alias cat="bat"
alias c="clear"
alias sizeof="du -sh"

# ==============================================================================
# ADVANCED PACKAGE MANAGEMENT MAPPINGS
# ==============================================================================
# Explicit bindings for core package system and AUR operations via Paru
alias update="paru -Syu"
alias install="sudo pacman -S"
alias aur="paru -S"
alias remove="sudo pacman -Rns"
alias search="paru -Ss"

# Purge local package delivery caches to reclaim storage spaces
alias cleanup="sudo paccache -rk2 && paru -Sc --noconfirm"

# ==============================================================================
# SYSTEM INSPECTION AND METRIC WRAPPERS
# ==============================================================================
alias top="btop"
alias ff="fastfetch"
alias logs="journalctl -b -p err"
alias ports="ss -tuln"
alias myip="curl -s ifconfig.me"
alias port-whisperer="bunx port-whisperer --all"

# ==============================================================================
# HIGH-PERFORMANCE LOGICAL FUNCTIONS (NATIVE FISH PIPELINES)
# ==============================================================================

# Yazi Working Directory Sync Tool
# Saves target exit paths to state variables to sync terminal path on quit
function y
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if test -f "$tmp"
        set -l cwd (command cat "$tmp")
        if test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd "$cwd"
        end
    end
    rm -f "$tmp"
end

# Orphaned Repository Packages Scrubber
# Arrays are verified natively via state checkers before firing actions
function orphans
    set -l list (pacman -Qdtq)
    if set -q list[1]
        sudo pacman -Rns $list
    else
        echo "No orphans found"
    end
end

# Interactive Fuzzy FZF Application Removal Wrapper
# Prevents execution errors if lookups are cancelled early via escape keys
function fuzzy-remove
    set -l targets (paru -Qq | fzf --multi --preview "paru -Qi {1}")
    if set -q targets[1]
        paru -Rns $targets
    end
end

# Core Storage Allocation Profile Query
# Isolates local database metadata fields to track top 30 space allocations
function pacsize
    pacman -Qi | awk '/^Name/{n=$3}/^Installed Size/{print $4,$5,n}' | sort -rh | head -30
end

# Interactive Storage Profiler via Fuzzy Target Overlays
function pacsize-fzf
    pacman -Qi | awk '/^Name/{n=$3}/^Installed Size/{print $4,$5,n}' | sort -rh | fzf
end