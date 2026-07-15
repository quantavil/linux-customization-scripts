# Ghostty + Fish Environment Setup Guide

## Step 1: Install Packages

Install the required shell, terminal, fonts, and CLI utilities:

```bash
sudo pacman -S ghostty fish yazi micro ttf-jetbrains-mono-nerd \
  fzf bat eza zoxide fastfetch wl-clipboard firejail bun tmux topgrade jq
```

---

## Step 2: Set Fish as the Default Shell

Add Fish to `/etc/shells` and configure it as your default login shell:

```bash
# Add Fish to /etc/shells
echo "/usr/bin/fish" | sudo tee -a /etc/shells
echo "/bin/fish" | sudo tee -a /etc/shells

# Set Fish as default login shell
sudo chsh -s /usr/bin/fish $USER
```

---

## Step 3: Configure Applications

### 1. Ghostty Config (`~/.config/ghostty/config`)

Configure Ghostty with the Catppuccin Mocha theme, JetBrainsMono font, Fish shell, and borderless window layout:

```bash
mkdir -p ~/.config/ghostty

cat << 'EOF' > ~/.config/ghostty/config
theme = Catppuccin Mocha
font-family = "JetBrainsMono Nerd Font"
font-size = 12
command = /usr/bin/fish
window-decoration = false
EOF
```

### 2. Fish Prompt (`~/.config/fish/functions/fish_prompt.fish`)

Configure a clean prompt with native Git integration:

```bash
mkdir -p ~/.config/fish/functions

cat << 'EOF' > ~/.config/fish/functions/fish_prompt.fish
function fish_prompt
    set -l mauve (set_color cba6f7)
    set -l blue (set_color 89b4fa)
    set -l green (set_color a6e3a1)
    set -l normal (set_color normal)

    # Output prompt with pwd, native Git status, and indicator
    echo -n -s $mauve (prompt_pwd) $normal $green (fish_vcs_prompt) $normal $blue " ❯ " $normal
end
EOF
```

### 3. Fish Shell Config (`~/.config/fish/config.fish`)

Open the Fish configuration file to configure aliases, utility functions (Yazi wrapper, orphan package scrubbers, size tools), and tmux integrations:

```bash
micro ~/.config/fish/config.fish
```

### 4. Tmux Layout Commands

The Fish configuration includes aliases for custom tmux pane layouts:
- `wd2c`: 2 columns split evenly down the middle.
- `wd3g`: 3-pane grid.
- `wd4g`: 4-pane balanced 2x2 grid.

### 5. Tmux Configuration (`~/.tmux.conf` or `~/.config/tmux/tmux.conf`)

Configure tmux to support mouse scrolling, True Color, and 1-based window/pane indexing:

```tmux
set -g mouse on
set -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB"
set -g base-index 1
setw -g pane-base-index 1
```

### 6. Topgrade Config (`~/.config/topgrade.toml`)

Copy the Topgrade configuration file to automate system updates (e.g. system packages, flatpaks, custom update scripts):

```bash
cp topgrade.toml ~/.config/topgrade.toml
```



## Step 4: Apply Configuration

```bash
source ~/.config/fish/config.fish
```

Finally, log out of your session and log back in to apply shell/path changes. Open **Ghostty** to start using the new environment.