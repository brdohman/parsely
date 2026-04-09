---
name: xcode-mcp
description: Xcode 26.3 MCP bridge integration. Dual-mode build, test, preview, diagnostics, and documentation tools. Requires Xcode 26.3+ running with project loaded.
user-invocable: false
allowed-tools: [Read, Glob, Grep, Bash, "mcp__xcode__*"]
---

# Xcode MCP Integration

Xcode 26.3+ exposes 20 native tools via the Model Context Protocol (`xcrun mcpbridge`). When Xcode is running with the project loaded, prefer MCP tools over shell scripts for structured output and lower context burn.

## Availability Detection

At the start of any task involving build, test, or code operations:

```bash
.claude/scripts/detect-xcode-mcp.sh
```

- Exit 0 → use MCP tools (preferred path)
- Exit 1 → use shell scripts (fallback path)

Cache the result for the session. Do not re-check per operation.

## Tab Identifier (Required for All MCP Calls)

Every Xcode MCP tool requires a `tabIdentifier` parameter. Get it once per session:

```
mcp__xcode__XcodeListWindows()
```

Extract the `tabIdentifier` for your project workspace. If this call fails, Xcode is not ready — fall back to shell scripts for the entire session.

## Tool Reference

### Build & Test

| MCP Tool | Shell Fallback | When to Use |
|----------|---------------|-------------|
| `BuildProject(tabIdentifier)` | `.claude/scripts/build.sh` | Compile check after implementation |
| `GetBuildLog(tabIdentifier)` | Parse xcodebuild stdout | Read structured build errors |
| `RunAllTests(tabIdentifier)` | `.claude/scripts/test.sh` | Full test suite |
| `RunSomeTests(tabIdentifier, tests)` | `.claude/scripts/test.sh [TestClass]` | Targeted story-level tests |
| `GetTestList(tabIdentifier)` | N/A (new capability) | Discover available test targets |

### Diagnostics

| MCP Tool | Shell Fallback | When to Use |
|----------|---------------|-------------|
| `XcodeListNavigatorIssues(tabIdentifier)` | Build + parse stdout | All project warnings/errors without rebuilding |
| `XcodeRefreshCodeIssuesInFile(tabIdentifier, file)` | N/A (new) | Targeted diagnostics for a single file |

### Intelligence (MCP-Only Capabilities)

| MCP Tool | Purpose |
|----------|---------|
| `ExecuteSnippet(tabIdentifier, code)` | Swift REPL — validate logic without a full build cycle |
| `RenderPreview(tabIdentifier, file)` | Capture SwiftUI preview as screenshot for visual QA |
| `DocumentationSearch(tabIdentifier, query)` | Semantic search across Apple docs + WWDC transcripts |

### File Operations

| MCP Tool | Standard Equivalent | When to Prefer MCP |
|----------|--------------------|--------------------|
| `XcodeRead(tabIdentifier, file)` | `Read` tool | Swift source files in Xcode project |
| `XcodeWrite(tabIdentifier, file, content)` | `Write` tool | New Swift files (auto-adds to project) |
| `XcodeUpdate(tabIdentifier, file, ...)` | `Edit` tool | Modify Swift files (triggers LSP refresh) |
| `XcodeGlob(tabIdentifier, pattern)` | `Glob` tool | Project-aware file search |
| `XcodeGrep(tabIdentifier, pattern)` | `Grep` tool | Project-indexed content search |
| `XcodeLS(tabIdentifier, path)` | `Bash(ls)` | Directory listing |
| `XcodeMakeDir(tabIdentifier, path)` | `Bash(mkdir)` | Create directories |
| `XcodeRM(tabIdentifier, file)` | `Bash(rm)` | Remove files |
| `XcodeMV(tabIdentifier, from, to)` | `Bash(mv)` | Move/rename files |

**Prefer standard tools** (`Read`, `Write`, `Edit`, `Glob`, `Grep`) for non-Swift files: `.md`, `.sh`, `.json`, planning docs, configs.

**Prefer MCP file ops** for Swift source files when Xcode is running — they keep the Xcode project navigator and source index in sync.

### Workspace

| MCP Tool | Purpose |
|----------|---------|
| `XcodeListWindows()` | List open Xcode windows and get `tabIdentifier` |

## Dual-Mode Pattern

```
1. Check MCP availability (once per session):
   .claude/scripts/detect-xcode-mcp.sh

2. If available:
   a. XcodeListWindows → get tabIdentifier
   b. Use MCP tools for build/test/diagnostics
   c. If any MCP call fails unexpectedly → fall back to shell for that operation

3. If not available:
   a. Use .claude/scripts/build.sh, test.sh, lint.sh
   b. Use standard Read/Write/Edit/Glob/Grep tools
```

## Context Efficiency

MCP tools return structured JSON, significantly reducing context burn:

| Operation | Shell Output | MCP Output | Savings |
|-----------|-------------|------------|---------|
| Build result | ~1000-5000 tokens | ~100-300 tokens | 70-95% |
| Test results | ~500-3000 tokens | ~100-500 tokens | 60-85% |
| Diagnostics | Build + parse (~2000+) | ~50-200 tokens | 90%+ |
| Test discovery | N/A | ~50-200 tokens | New capability |

## ExecuteSnippet Patterns

Use the Swift REPL for quick validation before committing to implementation:

```swift
// Validate date formatting
import Foundation
let fmt = DateFormatter()
fmt.dateStyle = .medium
print(fmt.string(from: Date()))

// Test regex
let pattern = #/^[A-Z]{2}-\d{4}$/#
print("AB-1234".wholeMatch(of: pattern) != nil)

// Verify algorithm logic
func fibonacci(_ n: Int) -> Int {
    guard n > 1 else { return n }
    var a = 0, b = 1
    for _ in 2...n { (a, b) = (b, a + b) }
    return b
}
print(fibonacci(10))
```

## RenderPreview for Visual QA

Capture SwiftUI preview screenshots without running the app:

```
mcp__xcode__RenderPreview(tabIdentifier: "...", file: "app/AppName/AppName/Views/ItemListView.swift")
```

Use for:
- Verifying layout matches design spec
- Checking all view states (idle, loading, loaded, error) via preview variants
- Validating light/dark mode appearance
- Including visual evidence in QA review comments

## DocumentationSearch for Apple APIs

Query Apple's full documentation corpus and WWDC transcripts:

```
mcp__xcode__DocumentationSearch(tabIdentifier: "...", query: "NSPersistentContainer background context")
```

Prefer over `WebSearch` for Apple platform APIs — it uses semantic search with MLX embeddings and includes WWDC session content.

## When NOT to Use MCP

| Operation | Why Shell/Standard |
|-----------|--------------------|
| SwiftLint | No MCP equivalent — always use `.claude/scripts/lint.sh` |
| Git operations | Use git CLI directly |
| Archive/notarize | Release workflow, often headless — use `.claude/scripts/archive.sh` |
| CI/CD | MCP requires GUI Xcode — shell scripts for CI |
| Non-Swift files | Standard `Read`/`Write`/`Edit` are simpler for .md, .sh, .json |
| Planning docs | Standard tools — these aren't part of the Xcode project |
