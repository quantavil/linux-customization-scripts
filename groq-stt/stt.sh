#!/usr/bin/env bash
set -uo pipefail

# ── Groq Whisper STT — Wayland Toggle ─────────────────────
#
# First press  → starts recording  🎙
# Second press → stops, compresses, transcribes, copies 📋
# Fuse         → auto-stops after MAX_DURATION seconds ⏰
#
# Dependencies:
#   sudo pacman -S pipewire-audio curl jq wl-clipboard libnotify opus-tools

# ── Configuration ──────────────────────────────────────────────
API_KEY="${GROQ_API_KEY:-gsk_your_actual_key_here}"
MODEL="whisper-large-v3-turbo"
LANGUAGE="en"
MAX_DURATION=60
SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# ── State files (per-user runtime dir) ─────────────────────────
PID_FILE="$XDG_RUNTIME_DIR/groq_stt.pid"
AUDIO_WAV="$XDG_RUNTIME_DIR/groq_stt.wav"
AUDIO_OPUS="$XDG_RUNTIME_DIR/groq_stt.opus"
LOCK_FILE="$XDG_RUNTIME_DIR/groq_stt.lock"

# ── Helpers ────────────────────────────────────────────────────
log()    { printf '[STT %s] %s\n' "$(date +%T)" "$*" >&2; }
die()    { log "FATAL: $1"; notify-send -u critical "Groq STT Error" "$1"; exit 1; }
notify() { log "$1 — $2"; notify-send "$1" "$2"; }
cleanup(){ rm -f "$PID_FILE" "$AUDIO_WAV" "$AUDIO_OPUS" "$LOCK_FILE"; }

# ── Dependency check ──────────────────────────────────────────
for cmd in pw-record curl jq wl-copy notify-send opusenc; do
    command -v "$cmd" &>/dev/null || die "Missing: $cmd"
done

# ══════════════════════════════════════════════════════════════
# STOP path — PID file exists → stop recording & transcribe
# ══════════════════════════════════════════════════════════════
if [[ -f "$PID_FILE" ]]; then
    read -r REC_PID FUSE_PID < "$PID_FILE"
    rm -f "$PID_FILE"

    # Kill the fuse timer so it doesn't linger
    [[ -n "${FUSE_PID:-}" && "${FUSE_PID}" != "$$" ]] && kill "$FUSE_PID" 2>/dev/null

    # Stop the recorder
    if kill -0 "$REC_PID" 2>/dev/null; then
        kill "$REC_PID" 2>/dev/null
        sleep 0.3
        log "Stopped recording (PID $REC_PID)"
    else
        log "Stale PID $REC_PID — nothing to stop"
        cleanup; exit 1
    fi

    # Prevent double-transcription race
    [[ -f "$LOCK_FILE" ]] && die "Transcription already in progress"
    touch "$LOCK_FILE"

    [[ ! -f "$AUDIO_WAV" ]] && { cleanup; die "No audio file found"; }

    notify "⏳ Transcribing…" "Compressing & uploading…"

    # ── Compress WAV → Opus ────────────────────────────────────
    if opusenc "$AUDIO_WAV" "$AUDIO_OPUS" 2>/dev/null; then
        UPLOAD="$AUDIO_OPUS"
        log "Compressed: $(du -h "$AUDIO_WAV" | cut -f1) → $(du -h "$AUDIO_OPUS" | cut -f1)"
    else
        UPLOAD="$AUDIO_WAV"
        log "opusenc failed — uploading raw WAV"
    fi

    # ── API call ───────────────────────────────────────────────
    CURL_ARGS=(
        -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions"
        -H "Authorization: Bearer $API_KEY"
        -F "file=@$UPLOAD"
        -F "model=$MODEL"
        -F "response_format=json"
    )
    [[ -n "$LANGUAGE" ]] && CURL_ARGS+=(-F "language=$LANGUAGE")

    RESPONSE=$(/usr/bin/curl "${CURL_ARGS[@]}") || { cleanup; die "curl failed — check network"; }
    log "API response: $RESPONSE"

    # ── Validate JSON (catches HTML 502/503 pages) ─────────────
    if ! printf '%s' "$RESPONSE" | jq empty 2>/dev/null; then
        cleanup; die "API returned non-JSON: ${RESPONSE:0:200}"
    fi

    # ── Parse response ─────────────────────────────────────────
    IFS=$'\t' read -r TEXT ERROR < <(
        printf '%s' "$RESPONSE" | jq -r '[ (.text // ""), (.error.message // "") ] | @tsv'
    )

    [[ -n "$ERROR" ]] && { cleanup; die "API: $ERROR"; }
    [[ -z "$TEXT" ]]  && { cleanup; die "Empty transcript (silence or noise?)"; }

    TEXT="${TEXT#"${TEXT%%[![:space:]]*}"}"

    log "Transcript: $TEXT"
    echo "$TEXT"
    wl-copy -- "$TEXT"
    notify "📋 Copied to clipboard" "$TEXT"
    cleanup
    exit 0
fi

# ══════════════════════════════════════════════════════════════
# START path — no PID file → begin recording
# ══════════════════════════════════════════════════════════════
[[ -f "$LOCK_FILE" ]] && die "Transcription in progress — please wait"
rm -f "$AUDIO_WAV" "$AUDIO_OPUS"

pw-record --rate 16000 --channels 1 --format s16 "$AUDIO_WAV" &>/dev/null &
REC_PID=$!
sleep 0.2

kill -0 "$REC_PID" 2>/dev/null || die "pw-record failed to start"

# ── Fuse: auto-stop after MAX_DURATION ─────────────────────────
(
    sleep "$MAX_DURATION"
    if [[ -f "$PID_FILE" ]] && [[ "$(cut -d' ' -f1 < "$PID_FILE")" == "$REC_PID" ]]; then
        notify-send -u warning "⏰ STT Fuse" "Auto-stop: exceeded ${MAX_DURATION}s"
        exec "$SELF"
    fi
) &>/dev/null &
FUSE_PID=$!
disown

echo "$REC_PID $FUSE_PID" > "$PID_FILE"
notify "🎙 Recording…" "Press shortcut again to stop (max ${MAX_DURATION}s)"