Everything comes from pacman. No git clones, no curl scripts, no manual font downloads.

---

## Step 1: Install

```bash
sudo pacman -S zsh starship ttf-jetbrains-mono-nerd \
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  fzf bat eza zoxide fastfetch wl-clipboard firejail bun
```


| Package                   | Purpose                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `starship`                | Prompt with git info, icons, command timer                                         |
| `eza`                     | Modern `ls` with icons and colors                                                  |
| `bat`                     | `cat` with syntax highlighting and line numbers                                    |
| `fzf`                     | Fuzzy finder — `Ctrl+R` for history search                                         |
| `zoxide`                  | Smart `cd` — learns your frequent directories                                      |
| `fastfetch`               | System info splash on terminal open                                                |
| `zsh-autosuggestions`     | Ghost text completions from history                                                |
| `zsh-syntax-highlighting` | Valid commands turn green, invalid turn red                                        |
| `wl-clipboard`            | Command-line copy/paste bridge for Wayland                                         |
| `firejail`                | Runtime sandbox — limits what a script can do if it turns malicious                |
| `bun`                     | Fast JavaScript package manager — required for port-whisperer                     |


---

## Step 2: Konsole Appearance

**Install Catppuccin Mocha colorscheme:**

```bash
mkdir -p ~/.local/share/konsole
curl -Lo ~/.local/share/konsole/Catppuccin-Mocha.colorscheme \
  https://raw.githubusercontent.com/catppuccin/konsole/main/Catppuccin-Mocha.colorscheme
```

**Apply in Konsole:**

1. **Settings → Edit Current Profile → Appearance**
2. Select **Catppuccin-Mocha** from the color scheme list
3. Click **Edit Font** → **JetBrainsMono Nerd Font**, size **12**
4. **OK → Apply**

---

## Step 3: Set Zsh as Default

```bash
chsh -s /usr/bin/zsh
```

Log out and back in.

---

## Step 4: Configure Starship

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

---

## Step 5: Setup `~/.zshrc`

Copy the provided `.zshrc` replacement to your home directory:

```bash
cp .zshrc ~/.zshrc
```

---

## Step 6: Verify

```bash
source ~/.zshrc
```

| Test                            | Expected                               |
| ------------------------------- | -------------------------------------- |
| Terminal opens                  | Fastfetch shows system info splash     |
| Prompt                          | Icons, git branch inside repos, colors |
| `ls`                            | File icons, colored, directories first |
| `cat ~/.zshrc`                  | Syntax-highlighted with line numbers   |
| Type `git cl` → **Right Arrow** | Autosuggestion completes from history  |
| `Ctrl+R`                        | FZF fuzzy history search               |
| `z` + partial path              | Jumps to most-used matching directory  |
| Mistype a command               | Turns red as you type                  |


---

### **The Issue**
Even though you changed your system default shell to **Zsh** (using `chsh`), **Konsole** was configured to ignore that setting. CachyOS had **hardcoded** the command `/bin/fish` directly into the Konsole profile settings, forcing Fish to open every time.

### **The Solution**
You manually overrode the Konsole profile settings:
1. Opened **Konsole Settings** → **Edit Current Profile**.
2. Changed the **Command** from `/bin/fish` to `/bin/zsh`.

### **Current Status: ✅ Fixed**
* **`echo $0` says `/bin/zsh`:** This proves you are currently running Zsh. The fix worked.
* **`echo $SHELL` says `/bin/fish`:** This is just a leftover text variable from when you first logged into your session. It will update to Zsh automatically next time you restart your computer, but it does not affect functionality right now.

---

## Bonus: Package Size Queries

```bash
# Top 30 largest packages
pacman -Qi | awk '/^Name/{n=$3}/^Installed Size/{print $4,$5,n}' | sort -rh | head -30

# Search with fzf
pacman -Qi | awk '/^Name/{n=$3}/^Installed Size/{print $4,$5,n}' | sort -rh | fzf
```