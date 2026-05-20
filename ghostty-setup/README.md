My bad. Let's fix the naming to make it explicitly a Ghostty and Fish guide, and drop the redundant code wall since your `config.fish` is already locked in.

# Ghostty + Fish High-Performance Environment Deployment Guide

## Step 1: Core Stack Installation

Install the native shell, GPU terminal, micro text editor, asynchronous file manager, fonts, and utilities in one transaction:

```bash
sudo pacman -S ghostty fish yazi micro ttf-jetbrains-mono-nerd \
  fzf bat eza zoxide fastfetch wl-clipboard firejail bun

```

---

## Step 2: Configure System Shell Registry

Whitelist the Fish binary paths in the system security register and set it as your default login shell:

```bash
# Whitelist binaries in PAM system security register
echo "/usr/bin/fish" | sudo tee -a /etc/shells
echo "/bin/fish" | sudo tee -a /etc/shells

# Set default login shell for your user account
sudo chsh -s /usr/bin/fish $USER

```

---

## Step 3: Deployment of Profiles and Configuration Files

### 1. Ghostty Terminal Profile (`~/.config/ghostty/config`)

Create the directory and write the configuration parameters to enforce the native Catppuccin theme, JetBrainsMono font, and borderless layout:

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

### 2. Zero-Overhead Shell Prompt (`~/.config/fish/functions/fish_prompt.fish`)

Deploy the prompt logic to eliminate external process forking by rendering path definitions and Git status tracking entirely within internal shell memory:

```bash
mkdir -p ~/.config/fish/functions

cat << 'EOF' > ~/.config/fish/functions/fish_prompt.fish
function fish_prompt
    set -l mauve (set_color cba6f7)
    set -l blue (set_color 89b4fa)
    set -l green (set_color a6e3a1)
    set -l normal (set_color normal)

    # Path rendering + native Git status tracking + prompt indicator
    echo -n -s $mauve (prompt_pwd) $normal $green (fish_vcs_prompt) $normal $blue " ❯ " $normal
end
EOF

```

### 3. Environment Initializations & Wrappers (`~/.config/fish/config.fish`)

Open the configuration file using `micro`:

```bash
micro ~/.config/fish/config.fish

```

Populate this file with the complete, fully commented configuration script containing your aliases, security sandboxing, and high-performance functions (Yazi wrapper, orphans scrubber, fuzzy-remove, and pacsize utilities) generated in the previous turn.

---

## Step 4: System Synchronization

```bash
source ~/.config/fish/config.fish

```

Log completely out of your active desktop session and log back in to apply the new user shells and path layers. Open **Ghostty** directly from your application runner to register the clean, accelerated workspace.