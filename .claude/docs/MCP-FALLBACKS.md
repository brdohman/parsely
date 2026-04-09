# MCP Tool → Shell Fallback Reference

When an MCP server is unavailable, agents fall back to shell commands. This table maps each MCP operation to its fallback.

## Detection

Check MCP availability at agent start:
```bash
.claude/scripts/detect-xcode-mcp.sh   # Xcode MCP (exit 0 = available)
mcp__peekaboo__permissions()            # Peekaboo (check Screen Recording + Accessibility)
```

If unavailable, use the shell fallback column.

---

## Xcode MCP → Shell

| Operation | MCP Tool | Shell Fallback |
|-----------|----------|----------------|
| Build | `BuildProject(tabId)` | `xcodebuild build -scheme [Name] -destination 'platform=macOS'` |
| Build errors | `GetBuildLog(tabId)` | Parse xcodebuild stdout/stderr |
| All diagnostics | `XcodeListNavigatorIssues(tabId)` | Parse xcodebuild stdout/stderr |
| Run all tests | `RunAllTests(tabId)` | `xcodebuild test -scheme [Name] -destination 'platform=macOS'` |
| Run specific tests | `RunSomeTests(tabId, tests)` | `xcodebuild test -scheme [Name] -only-testing:[Target]/[Class]` |
| List tests | `GetTestList(tabId)` | `xcodebuild test -scheme [Name] -list` |
| Write Swift file | `XcodeWrite(tabId, file, content)` | `Write` tool (file not auto-added to .xcodeproj) |
| Edit Swift file | `XcodeUpdate(tabId, file, ...)` | `Edit` tool (no LSP refresh) |
| File diagnostics | `XcodeRefreshCodeIssuesInFile(tabId, file)` | Build + parse errors for that file |
| Apple docs | `DocumentationSearch(tabId, query)` | `WebSearch` tool |
| Run snippet | `ExecuteSnippet(tabId, code)` | Write temp file + `swift [file]` |
| Render preview | `RenderPreview(tabId, file)` | No fallback — MCP-only capability |
| File search | `XcodeGrep(tabId, pattern)` | `Grep` tool |
| File listing | `XcodeGlob(tabId, pattern)` | `Glob` tool |

**Context savings:** MCP returns structured JSON (~100-500 tokens per operation). Shell xcodebuild output can be 2000+ tokens for the same information.

**Always use shell for:** SwiftLint (`.claude/scripts/lint.sh`), git operations, non-Swift files.

---

## Peekaboo MCP → Fallback

| Operation | MCP Tool | Fallback |
|-----------|----------|----------|
| Screenshot | `image(app, mode: "window")` | No fallback — skip visual verification |
| Element inspection | `see(app)` | No fallback — skip visual verification |
| Click element | `click(on: id)` | No fallback |
| Type text | `type(text)` | No fallback |
| Keyboard shortcut | `hotkey(keys)` | No fallback |
| Dialog detection | `dialog(action: "list")` | No fallback |

**When Peekaboo is unavailable:** Note in task comment "Visual verification skipped — Peekaboo unavailable." Rely on build success + unit tests only.

**Exception:** Visual QA agent (`visual-qa-agent.md`) requires Peekaboo — it cannot fall back. If Peekaboo is denied, it reports FAIL immediately.

---

## Aikido MCP → Fallback

| Operation | MCP Tool | Fallback |
|-----------|----------|----------|
| SAST + secrets scan | `aikido_full_scan(files)` | Note "Aikido scan unavailable — manual checks only" and proceed with grep-based security-static checks |

---

## Trivy MCP → Fallback

| Operation | MCP Tool | Fallback |
|-----------|----------|----------|
| Filesystem scan | `scan_filesystem(path)` | `trivy fs --severity HIGH,CRITICAL .` (CLI) |
| Image scan | `scan_image(image)` | `trivy image [image]` (CLI) |
| Dependency CVEs | `findings_list()` | `trivy fs --scanners vuln .` (CLI) |

Trivy CLI is installed via Brewfile. MCP plugin adds structured output but CLI works independently.
