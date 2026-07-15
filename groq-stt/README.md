# Groq Whisper STT for Wayland

A lightweight, toggle-based speech-to-text (STT) script for Linux (KDE Wayland) using the Groq API and Whisper. Press a shortcut to start recording, press again to stop — your transcript lands in the clipboard instantly.

## Features

- **Toggle Recording:** Press a shortcut to start, press again to stop and transcribe.
- **Auto-Stop Fuse:** Automatically stops recording after a configurable duration (default: 60s).
- **Opus Compression:** Compresses audio before upload (~1.9 MB WAV → ~100 KB Opus) for faster transcription.
- **Clipboard Integration:** Transcripts are automatically copied to the system clipboard via `wl-copy`.
- **Desktop Notifications:** Visual feedback at every stage — recording, transcribing, copied.
- **High Speed:** Groq's fast inference + Opus compression = near-instant results.
- **Clean Process Hygiene:** Fuse timers are killed on manual stop, lockfile prevents race conditions during transcription.

## Prerequisites

### Dependencies

```bash
# Arch Linux / CachyOS
sudo pacman -S pipewire-audio curl jq wl-clipboard libnotify opus-tools
```

| Package | Purpose |
|---|---|
| `pw-record` | PipeWire audio recording |
| `curl` | API requests to Groq |
| `jq` | JSON response parsing |
| `wl-copy` | Wayland clipboard |
| `notify-send` | Desktop notifications |
| `opusenc` | WAV → Opus compression before upload |

### Verify all dependencies

```bash
for cmd in pw-record curl jq wl-copy notify-send opusenc; do
    command -v "$cmd" && echo "$cmd ✓" || echo "$cmd ✗ MISSING"
done
```

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/quantavil/linux-setup.git
   cd linux-setup/groq-stt
   ```

   Or save `stt.sh` directly to `~/stt.sh`.

2. **Make it executable:**

   ```bash
   chmod +x ~/stt.sh
   ```

3. **Configure your API key:**

   **Option A — Environment variable (recommended):**

   Add to your `~/.bashrc` or `~/.zshrc`:

   ```bash
   export GROQ_API_KEY="gsk_your_actual_key_here"
   ```

   **Option B — Edit the script directly:**

   ```bash
   API_KEY="${GROQ_API_KEY:-gsk_your_actual_key_here}"
   ```

## Usage

### Terminal (test first)

```bash
~/stt.sh        # 🎙 starts recording — speak something
~/stt.sh        # ⏳ stops → compresses → transcribes → 📋 copied
```

You should see a **"📋 Copied to clipboard"** notification and a log line like:

```
Compressed: 1.9M → 96K
```

### KDE keyboard shortcut (recommended)

1. **System Settings** → search **Shortcuts** → **Shortcuts**
2. Scroll to bottom → **Add Command**
3. Paste the full path: `/home/quantavil/stt.sh`
4. Click the shortcut box → press your combo (e.g., `Alt + L`)
5. **Apply**

Now press the shortcut anywhere to dictate.

## Configuration

Edit the variables at the top of `stt.sh`:

| Variable | Default | Description |
|---|---|---|
| `MODEL` | `whisper-large-v3-turbo` | Groq Whisper model |
| `LANGUAGE` | `en` | Target language (forces English/romanized output) |
| `MAX_DURATION` | `60` | Auto-stop recording after N seconds |

## How It Works

```
1st press  →  pw-record starts  →  PID saved  →  fuse timer spawned
2nd press  →  pw-record killed  →  fuse killed
           →  WAV compressed to Opus via opusenc
           →  Opus uploaded to Groq API
           →  JSON validated  →  transcript parsed
           →  wl-copy  →  notification  →  cleanup
```

### State files

All state files live in `$XDG_RUNTIME_DIR` (typically `/run/user/1000/`):

| File | Purpose |
|---|---|
| `groq_stt.pid` | Stores recorder PID + fuse PID |
| `groq_stt.wav` | Raw recorded audio |
| `groq_stt.opus` | Compressed audio (uploaded to API) |
| `groq_stt.lock` | Prevents re-trigger during transcription |

## Troubleshooting

| Problem | Fix |
|---|---|
| Script does nothing | `rm -f $XDG_RUNTIME_DIR/groq_stt.*` to clear stuck state |
| `opusenc` not found | `sudo pacman -S opus-tools` |
| Clipboard empty after shortcut | Ensure `WAYLAND_DISPLAY` is set — the script handles this automatically |
| "API returned non-JSON" error | Groq is down or rate-limited — try again in a few seconds |
| Notification but no clipboard paste | Some apps need `Ctrl+Shift+V` for plain text paste |

## License

This project is licensed under the [MIT License](LICENSE).
