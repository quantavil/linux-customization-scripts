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

### 7. Groq CLI Assistant (`~/.local/bin/ai`)

Copy the `ai` script to your local bin directory and make it executable:

```bash
mkdir -p ~/.local/bin
cp ai ~/.local/bin/ai
chmod +x ~/.local/bin/ai
```

On first run, the script will guide you through the interactive setup to save your API key and select a default model (using `fzf` if available):

```bash
ai hello
```

Alternatively, you can manually trigger configuration or change the configured key/model at any time:

```bash
ai --configure
```

You can also override the stored configuration by setting the environment variable in your shell:

```fish
set -gx GROQ_API_KEY "your_actual_groq_api_key"
```

Query the assistant directly, pipe inputs to it, or run a live web search using the `-s` / `--search` flag:

```bash
# General query (continues conversation)
ai explain quantum computing in one sentence

# Follow-up (remembers previous context)
ai can you elaborate on that?

# Web search (no history saved)
ai -s what is the current weather in New York

# Piped input (no history saved)
echo "write a quick python function to reverse a string" | ai
```

#### Conversation Memory

The assistant automatically remembers conversation context between invocations. When context grows too large (~20K tokens), older messages are summarized into bullet points while recent exchanges are kept verbatim.

```bash
# Start a new conversation (clears history)
ai -n hello there

# Just clear history without a query
ai -n

# Check current conversation info
ai --status
```

#### Interactive Chat Mode

Enter a REPL for multi-turn conversations without retyping `ai`:

```bash
ai -i
```

Type `exit`, `quit`, `bye`, or press Ctrl+D to leave.

> **Note:** Piped input and web search (`-s`) skip history to avoid polluting conversation context with one-off queries. Conversations idle for more than 3 hours show a warning.

---

## Step 4: Apply Configuration

```bash
source ~/.config/fish/config.fish
```

Finally, log out of your session and log back in to apply shell/path changes. Open **Ghostty** to start using the new environment.