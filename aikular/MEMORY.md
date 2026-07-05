# Project: aikular

## Overview
Aikular is a CLI tool and wrapper designed to parse PDFs and start interactive AI analysis sessions using `okular` (for visual PDF display) and an AI terminal backend (`agy` or `opencode`) inside `ghostty` with shell integration (`fish`).

## Structure
```
aikular/
├── README.md           # Project documentation and setup
├── aikular             # Main entry point (Bash script)
├── aikular-clean       # Cache cleanup utility (Bash script)
├── aikular.desktop     # Desktop entry file for system integration
└── aikular_parser.py   # PDF text extraction and parsing engine (Python)
```

## Conventions
- **Shell**: Bash is used for wrapper scripts; Fish shell is used for launching the interactive AI CLI.
- **Cache**: Parses visual text and structure, saving files to `<pdf_dir>/.aikular/<pdf_stem>/` (if writable) or `/tmp/aikular-${USER}/...`.
- **Backend**: Can toggle between Google's `agy` tool and `opencode`. Supports persistent sessions by storing session/conversation IDs in the cache folder.

## Dependencies & Setup
- Requires: `python3`, `okular`, `ghostty`, `fish`, `sqlite3`, and either `agy` or `opencode`.
- Config file: `~/.config/aikular/backend` tracks the active backend (either `agy` or `opencode`).

## Critical Information
- Launches detached okular process: `setsid okular ...`
- Uses `ghostty` to spawn terminal session, passing a fish prompt.

## Insights
- Conversation/session persistence requires querying local databases for `agy` (`~/.gemini/antigravity-cli/conversations/`) and `opencode` (`~/.local/share/opencode/opencode.db`) right after the Ghostty process completes to save the session ID.

## Blunders
- (None yet recorded)
