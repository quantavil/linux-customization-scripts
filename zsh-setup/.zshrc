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
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -l"
alias la="eza --icons --group-directories-first -la"
alias tree="eza --icons --tree"
alias cat="bat"
alias c="clear"
alias sizeof="du -sh"

# ── Aliases: package management (paru wraps pacman + AUR) ──────
alias update="paru -Syu"
alias install="sudo pacman -S"
alias aur="paru -S"
alias remove="sudo pacman -Rns"
alias search="paru -Ss"
alias orphans='pacman -Qdtq | sudo pacman -Rns - 2>/dev/null || echo "No orphans"'
alias cleanup="sudo paccache -rk2 && paru -Sc --noconfirm"
alias fuzzy-remove='paru -Rns $(paru -Qq | fzf --multi --preview "paru -Qi {1}")'  # search → pick → delete

# ── Aliases: system ─────────────────────────────────────────────
alias top="btop"
alias ff="fastfetch"
alias logs="journalctl -b -p err"
alias ports="ss -tuln"
alias myip="curl -s ifconfig.me"

# ── FZF ─────────────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# ── Plugins (syntax-highlighting must be last) ──────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Greeting ────────────────────────────────────────────────────
fastfetch
