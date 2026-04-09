# Parsely

A macOS app for viewing and exploring JSONL (JSON Lines) files. Built because I couldn't find one that didn't make me want to punch my monitor.

![Parsely Screenshot](screenshot.png)

## Why This Exists

I've been teaching myself to fine-tune models, and with the release of Gemma 4, I wanted to train on my own datasets: lectures, writings, LinkedIn posts. That means working with a lot of JSONL files.

Preparing training data by hand wasn't feasible, so I built prompts in Claude Code to analyze and clean my datasets. Claude is a great model, but I still needed to check its work. No code review tool or security analyzer can tell me whether my data was properly parsed. That's on me to verify.

The problem was actually looking at the files. TextMate, VS Code, TextEdit: each one hit me with a massive wall of single-line JSON stretching infinitely to the right. Completely unusable. I searched for a decent native Mac viewer, tried a few, and nothing fit what I needed: a simple app that parses each line, gives me a collapsible JSON tree, and lets me search across lines.

Now, is it possible that a perfect JSONL viewer for Mac exists, or a plugin for an app I already have, and I simply failed at searching the internet? Absolutely. If you find one, please don't tell me. I've already built this and I'm emotionally invested.

## What It Does

- **Line-by-line JSONL parsing** with error handling for malformed lines
- **Collapsible JSON trees** with syntax highlighting (strings, numbers, booleans, null)
- **Multi-file tabs** — open multiple JSONL files and switch between them
- **Real-time search** across all lines in a file
- **Jump to line** (Cmd+G)
- **Pretty-print export** — copy any line as formatted JSON to clipboard (Cmd+Shift+C)
- **Drag and drop** — drop `.jsonl` or `.ndjson` files directly into the app
- **Native macOS** — SwiftUI, no Electron, no web views

## Install

Download the latest `Parsely-1.0.dmg` from [Releases](../../releases), open it, and drag Parsely to your Applications folder.

> **Note:** This app is not notarized with Apple. On first launch, macOS will warn you that it "can't be opened because Apple cannot check it for malicious software." Right-click the app, then click Open, then click Open again to bypass this. You only need to do this once.

## Supported File Types

| Extension | MIME Type |
|-----------|-----------|
| `.jsonl` | `application/x-ndjson` |
| `.ndjson` | `application/x-ndjson` |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+O | Open file |
| Cmd+G | Jump to line |
| Cmd+Shift+C | Copy line as pretty JSON |
| Cmd+W | Close window |
| Cmd+[ | Previous tab |
| Cmd+] | Next tab |
| Option+Up | Previous line |
| Option+Down | Next line |
| Arrow keys | Navigate lines (when sidebar is focused) |

## Example Files

The `jsonl-example-files/` directory includes sample files you can use to test the app:

- `sample_products.jsonl` — Product catalog with nested arrays
- `sample_events.jsonl` — Analytics events with nested objects
- `sample_weather.jsonl` — Weather data with flat records
- `sample_malformed.jsonl` — Mix of valid and broken lines to demonstrate error handling
- `sample_completely_broken.jsonl` — Every line fails to parse

## How It Was Built

This was built entirely with [Claude Code](https://claude.ai/claude-code) in a single session. The speed was possible because of a reusable `.claude/` directory I maintain for building native macOS and iOS apps. It contains specialized agents — a macOS developer, a designer, a QA engineer — along with skills that stay current on modern Swift patterns, SwiftUI best practices, and Human Interface Guidelines. Point it at a new Xcode project and it already knows how to write, review, and test native Mac apps. This `.claude/` dir is added to this repo.

**Tech stack:** Swift, SwiftUI, @Observable, async/await, macOS 14.0+

## Requirements

- macOS 14.0 (Sonoma) or later

## License

MIT
