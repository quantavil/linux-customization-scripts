# Groq CLI Assistant (`ai`)

A lightweight CLI assistant with conversation memory and web search capabilities using the Groq API (`curl` + `jq`).

## Features
- **Fast Inference**: Uses Groq's high-speed API.
- **Conversation Memory**: Automatically preserves context between prompts.
- **Automatic Summarization**: Automatically condenses conversation history when it exceeds context limits (~20k tokens) to save tokens while keeping recent exchanges.
- **Interactive REPL Mode**: Supports a live interactive chat environment.
- **Web Search**: Integrates Google Search capabilities (using the `-s` / `--search` flag).
- **POSIX Compliant**: Built strictly with shell scripts, `curl`, and `jq`.

## Prerequisites
Ensure `curl` and `jq` are installed:
```bash
sudo pacman -S curl jq
```

## Installation

Run the application setup script:
```bash
./apply_groq-chat.sh
```

Alternatively, copy the `ai` script manually to your path and make it executable:
```bash
mkdir -p ~/.local/bin
cp ai ~/.local/bin/ai
chmod +x ~/.local/bin/ai
```

## Configuration

On first run, the script will guide you through the interactive setup to save your API key and select a default model (using `fzf` if available):
```bash
ai hello
```

You can reconfigure the API key and default model at any time:
```bash
ai --configure
```

You can also override the configuration using the `GROQ_API_KEY` environment variable in your shell:
```bash
export GROQ_API_KEY="your_groq_api_key"
```

## Usage

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

### Conversation Memory

The assistant automatically remembers conversation context between invocations.

```bash
# Start a new conversation (clears history)
ai -n hello there

# Clear history without a query
ai -n

# Check current conversation info (messages, context size, age)
ai --status
```

### Interactive Chat Mode

Enter a REPL for multi-turn conversations without retyping `ai`:
```bash
ai -i
```
Type `exit`, `quit`, `bye`, or press `Ctrl+D` to leave.

---

> **Note**: Piped input and web search (`-s`) skip history to avoid polluting conversation context. Conversations idle for more than 3 hours will display a warning.
