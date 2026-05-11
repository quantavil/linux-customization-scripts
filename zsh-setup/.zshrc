# ── History ──────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY SHARE_HISTORY APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# ── Tab completion ──────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ── Prompt ──────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Smart cd ────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── Security ────────────────────────────────────────────────────
alias curl='firejail curl'             # sandbox outbound curl
alias wget='firejail wget'             # sandbox outbound wget
alias pip='python3 -m pip'             # sandbox pip installs

# ── Aliases: files & navigation ─────────────────────────────────
alias ls="eza --icons --group-directories-first"  # list files with icons
alias ll="eza --icons --group-directories-first -l"  # long format
alias la="eza --icons --group-directories-first -la"  # all files including hidden
alias tree="eza --icons --tree"  # directory tree view
alias cat="bat"  # syntax-highlighted cat
alias c="clear"  # clear terminal
alias sizeof="du -sh"  # show directory size

# ── Aliases: package management (paru wraps pacman + AUR) ──────
alias update="paru -Syu"  # full system upgrade
alias install="sudo pacman -S"  # install from official repos
alias aur="paru -S"  # install from AUR
alias remove="sudo pacman -Rns"  # remove package and dependencies
alias search="paru -Ss"  # search packages
alias orphans='pacman -Qdtq | sudo pacman -Rns - 2>/dev/null || echo "No orphans"'  # remove unused dependencies
alias cleanup="sudo paccache -rk2 && paru -Sc --noconfirm"  # clean package cache
alias fuzzy-remove='paru -Rns $(paru -Qq | fzf --multi --preview "paru -Qi {1}")'  # interactive package removal

# ── Aliases: system ─────────────────────────────────────────────
alias top="btop"  # interactive process monitor
alias ff="fastfetch"  # system info display
alias logs="journalctl -b -p err"  # show boot error logs
alias ports="ss -tuln"  # list listening ports
alias myip="curl -s ifconfig.me"  # show public IP
alias port-whisperer="bunx port-whisperer --all"  # show all active ports with process info

# ── FZF ─────────────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# ── Plugins (syntax-highlighting must be last) ──────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Greeting ────────────────────────────────────────────────────
fastfetch
