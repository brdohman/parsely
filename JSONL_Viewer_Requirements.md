# JSONL Viewer -- macOS App Requirements

## Purpose
A lightweight native macOS app that makes JSONL files easy to read. Each line of a JSONL file is a complete JSON object. This app displays each line as a structured, readable card instead of a raw wall of text.

## Core Behavior

### File Opening
- Open `.jsonl` files via File > Open, drag-and-drop onto the app window, or drag-and-drop onto the Dock icon
- Register as a handler for `.jsonl` file associations so users can double-click to open

### Line List (Left Sidebar)
- Scrollable list of all lines in the file
- Each row shows a compact preview: line number and a truncated summary (first 80 chars of the JSON)
- Single-click a line to display its contents in the detail view
- Highlight the currently selected line
- Show total line count at the bottom of the sidebar (e.g. "76 lines")

### Detail View (Main Panel)
- Displays the selected line's JSON as a structured key-value layout, NOT raw JSON
- Each top-level key is displayed as a bold label on its own row
- Each value is displayed below or beside its key with full text wrapping (no horizontal scrolling, ever)
- Long string values (like prompts or completions) wrap naturally within the width of the panel
- The detail view should never be wider than the window. All content reflows on window resize.
- Nested JSON objects and arrays should be collapsible/expandable with indentation
- Syntax coloring for value types: strings, numbers, booleans, nulls each get a distinct color

### Search and Filter
- Search bar at the top of the window
- Searches across all keys and values in all lines
- Matching lines are filtered in the sidebar list
- Search term is highlighted in the detail view

## Technical Constraints
- Native macOS app using SwiftUI
- Target macOS 14+
- No external dependencies or frameworks
- Single-window app using NavigationSplitView (sidebar + detail)
- Handle files with 10,000+ lines without lag (lazy loading)

## Nice to Have (Not Required for V1)
- Cmd+G to jump to a specific line number
- Light/dark mode support (follow system)
- Copy individual values by right-clicking a field
- Export a single line as pretty-printed JSON to clipboard
- Keyboard arrow keys to navigate between lines
