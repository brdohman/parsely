---
name: peekaboo
description: Peekaboo MCP server for macOS screen capture and UI automation. Provides 22 tools for screenshots, element interaction, dialog handling, and visual QA. Requires Peekaboo MCP server running with Screen Recording + Accessibility permissions.
user-invocable: false
allowed-tools: [Read, Glob, Grep, Bash, "mcp__peekaboo__*"]
---

# Peekaboo MCP Integration

Peekaboo is an MCP server for macOS screen capture and UI automation. It provides 22 tools for taking screenshots, interacting with UI elements by ID, driving user journeys, recovering from system dialogs, and capturing visual evidence for QA reviews.

## Availability Detection

At the start of any task requiring visual verification or UI automation:

1. Check `.mcp.json` in the repo root for a `peekaboo` server entry.
2. Attempt a lightweight probe call:
   ```
   mcp__peekaboo__permissions()
   ```
   - Success (Screen Recording + Accessibility granted) -> use Peekaboo tools
   - Failure or missing -> skip visual checks, note in task comments

Cache the result for the session. Do not re-check per operation.

**Required macOS permissions:**
- Screen Recording (for `see`, `image`, and all screenshot operations)
- Accessibility (for `click`, `type`, `hotkey`, `drag`, and all interaction operations)

## Tool Reference

### Observation

| Tool | Key Parameters | Purpose |
|------|---------------|---------|
| `see` | `--app`, `--mode` (full/window), `--json-output` | Screenshot + element map with IDs (B1, T1, etc.) |
| `image` | `--app`, `--mode` (full/window), `--path` | Capture screenshot to file |
| `list` | apps, windows | Enumerate running apps and windows |

### Interaction

| Tool | Key Parameters | Purpose |
|------|---------------|---------|
| `click` | `--on [id/query]`, `--snapshot` | Click element by ID or accessibility label |
| `type` | `--text`, `--clear`, `--delay-ms` | Type text into focused element |
| `hotkey` | modifier combo (e.g., `cmd,shift,t`) | Press keyboard shortcut |
| `scroll` | direction, element | Scroll in direction within element |
| `drag` | source, destination | Drag and drop between elements |
| `move` | position or element | Move cursor to position or element |
| `swipe` | two points | Swipe gesture between two positions |
| `paste` | -- | Atomic clipboard set + paste + restore |

### App & Window Management

| Tool | Key Parameters | Purpose |
|------|---------------|---------|
| `app` | `launch/quit/relaunch/switch/list` | App lifecycle management |
| `window` | `list/move/resize/focus` | Window management |
| `dock` | launch, right-click | Dock interaction |
| `space` | list, switch | macOS Spaces management |

### System Interaction

| Tool | Key Parameters | Purpose |
|------|---------------|---------|
| `dialog` | `list/click/input/dismiss` | System dialog interaction |
| `menu` | app, menu item path | Menu bar interaction |
| `clipboard` | `get/set/clear` | Clipboard management |

### Utility

| Tool | Key Parameters | Purpose |
|------|---------------|---------|
| `sleep` | duration (seconds) | Pause execution between actions |
| `permissions` | -- | Check Screen Recording + Accessibility status |

## Agent Tool Access Matrix

Not all agents need all Peekaboo tools. Restrict usage to what each role requires:

| Agent | Allowed Tools | Use Cases |
|-------|--------------|-----------|
| QA | see, image, click, type, hotkey, scroll, app, dialog, window, list, sleep | Journey walkthroughs, state verification, screenshot evidence, dialog recovery |
| Designer | image, see, app, window, list | Screenshot existing state, verify design specs, compare layouts |
| Build Engineer | dialog, app, image, window | Dialog recovery during xcodebuild, build environment screenshots |
| macOS Developer | image, see, app, window | Post-build visual sanity check (optional, not required) |
| PM | image, see, app, window, list | Product review visual walkthrough, feature verification |

## Context Efficiency

Screenshots are the primary context cost. Minimize by targeting specific windows:

| Capture Mode | Approximate Token Cost | When to Use |
|-------------|----------------------|-------------|
| Full screen | ~4-6K tokens | Avoid unless checking multi-window layout |
| Window mode (single app) | ~2-3K tokens | Default for most operations |
| Element-targeted `see` | ~1-2K tokens (JSON map) | When you need element IDs, not visual evidence |

**Rules:**
- Always use window mode (`--mode window`) over full screen
- Capture screenshots only at verification checkpoints, not after every action
- Use `see` (JSON element map) when you need to find element IDs for interaction
- Use `image` (screenshot file) when you need visual evidence for review comments
- Limit to 3-5 screenshots per QA session unless investigating a specific visual bug

## Screenshot Validation Protocol

⛔ **MANDATORY for every screenshot used as evidence.** A screenshot that doesn't show the target app is worthless. Agents MUST validate every capture.

### The Problem

Agents call `image` or `see`, get back a file path, and claim "visually verified" — but the screenshot may show the macOS menu bar, a different app, or a partially obscured window. This passes silently because nobody checks.

### The Protocol (3 Steps)

**Step 1: Pre-capture — Verify app is running and focus it**

```
1. mcp__peekaboo__list(item_type: "application_windows", app: "[AppName]",
     include_window_details: ["ids", "bounds", "off_screen"])
   → Verify: at least 1 window exists, not off-screen, has reasonable bounds (width > 200, height > 200)
   → If no windows: STOP — app is not running or has no visible windows. Launch it first.

2. mcp__peekaboo__window(action: "focus", app: "[AppName]")
   → Brings the app window to front

3. mcp__peekaboo__sleep(duration: 1)
   → Wait for window to settle after focus
```

**Step 2: Capture — Target the specific app**

```
4. mcp__peekaboo__see(app_target: "[AppName]", path: "[output-path].png")
   → ALWAYS use app_target parameter — never capture without it
   → This scopes the capture to the app's windows only
```

**Step 3: Post-capture — Validate the screenshot shows the app**

```
5. mcp__peekaboo__analyze(
     image_path: "[output-path].png",
     question: "Does this screenshot show the [AppName] application window with its UI content visible? Describe what you see in 1-2 sentences. If this only shows a menu bar, desktop, or a different application, say 'INVALID'."
   )
   → If response contains "INVALID" or doesn't describe app-specific UI:
     - Retry from Step 1 (max 2 retries)
     - If still failing after retries: report "SCREENSHOT VALIDATION FAILED — captured image does not show [AppName]. Manual verification required." and save the failed screenshot with suffix `-INVALID` for debugging.
   → If response describes app UI content: proceed, screenshot is valid
```

### Quick Reference

| Step | Tool | Purpose | Failure Action |
|------|------|---------|----------------|
| 1a | `list` | Verify windows exist | Launch app |
| 1b | `window(focus)` | Bring to front | Report focus failure |
| 2 | `see(app_target)` | Capture scoped to app | Never skip app_target |
| 3 | `analyze` | Validate content | Retry or mark INVALID |

### When to Use This Protocol

- **Every time** a screenshot is saved as evidence (bug before/after, product review, QA, visual QA)
- **Not needed** for throwaway screenshots during interactive exploration (e.g., finding element IDs)

---

## Common Patterns

### Launch App + Screenshot

```
1. mcp__peekaboo__app(action: "launch", app: "AppName")
2. mcp__peekaboo__sleep(duration: 2)          # wait for app to load
3. mcp__peekaboo__window(action: "focus", app: "AppName")
4. mcp__peekaboo__see(app_target: "AppName", path: "/tmp/app-launch.png")
5. mcp__peekaboo__analyze(image_path: "/tmp/app-launch.png",
     question: "Does this show the AppName application window? Describe briefly. Say INVALID if not.")
```

### Drive User Journey

```
1. mcp__peekaboo__see(app: "AppName", mode: "window")     # get element map
2. mcp__peekaboo__click(on: "B3")                          # click button by ID
3. mcp__peekaboo__sleep(duration: 1)                       # wait for transition
4. mcp__peekaboo__type(text: "search query")               # type into field
5. mcp__peekaboo__hotkey("cmd,enter")                      # submit with shortcut
6. mcp__peekaboo__image(app: "AppName", mode: "window")    # capture result state
```

### Dialog Recovery (Build Engineer)

During automated builds, macOS dialogs can block progress:

```
1. mcp__peekaboo__dialog(action: "list")           # check for blocking dialogs
2. mcp__peekaboo__dialog(action: "dismiss")         # dismiss if non-critical
   OR
   mcp__peekaboo__dialog(action: "click", button: "Allow")  # accept if required
3. mcp__peekaboo__image(mode: "full")               # screenshot evidence of dialog
```

### Visual State Verification (QA)

Verify a specific screen state matches expectations:

```
1. mcp__peekaboo__app(action: "switch", app: "AppName")
2. mcp__peekaboo__see(app: "AppName", mode: "window", json_output: true)
3. # Parse JSON to verify:
   #   - Expected elements present (buttons, labels, fields)
   #   - Element text matches expected values
   #   - No unexpected error dialogs
4. mcp__peekaboo__image(app: "AppName", mode: "window", path: "/tmp/state-check.png")
   # Attach to QA review comment as evidence
```

### Keyboard Navigation Test (QA/Accessibility)

```
1. mcp__peekaboo__app(action: "switch", app: "AppName")
2. mcp__peekaboo__hotkey("tab")           # move to next element
3. mcp__peekaboo__see(app: "AppName")     # verify focus indicator
4. mcp__peekaboo__hotkey("tab")           # continue tabbing
5. mcp__peekaboo__hotkey("space")         # activate focused element
6. mcp__peekaboo__image(app: "AppName", mode: "window")  # capture state
```

## Fallback Behavior

If Peekaboo is unavailable (MCP server not running, permissions not granted):

⚠️ **Agents MUST report Peekaboo unavailability prominently — never silently skip.**

1. **Visual QA agent:** **HARD BLOCK** — cannot function without Peekaboo. Report FAIL immediately with: "BLOCKED: Peekaboo MCP unavailable. Visual QA cannot proceed."
2. **QA agent:** WARN in review comment header: "⚠️ VISUAL QA DEGRADED: Peekaboo MCP unavailable. Only headless tests run. Manual visual check required."
3. **Designer agent:** WARN in task comment: "⚠️ Peekaboo unavailable — no screenshot captures. Working from written specs only."
4. **Build Engineer:** If dialog recovery needed, use AppleScript fallback: `osascript -e 'tell application "System Events" to click button "OK" of window 1'`
5. **macOS Developer:** WARN in task comment: "⚠️ Peekaboo unavailable — visual sanity check skipped."

**The coordinator pre-flight check (`.claude/scripts/check-mcp-deps.sh`) catches this before agents are spawned.** Agents should still check as a safety net.

## When NOT to Use Peekaboo

| Situation | Why Skip |
|-----------|----------|
| Headless CI/CD | No GUI session available |
| Unit test verification | Use `xcodebuild test` or Xcode MCP `RunSomeTests` |
| Build-only tasks | `BuildProject` or `build.sh` is sufficient |
| Reading/writing code | Use standard file tools or Xcode MCP file ops |
| Planning/documentation | No visual component to verify |
| SwiftUI preview checks | Use Xcode MCP `RenderPreview` instead (no app launch needed) |
