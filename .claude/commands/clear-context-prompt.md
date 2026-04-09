---
disable-model-invocation: true
description: Generate a handoff prompt for continuing work after clearing context. Use before running /clear to create continuity for the next session.
argument-hint: focus area (optional) - e.g., "security fixes", "phase 2 build", "design review"
---

# Clear Context Prompt Command

Generate a comprehensive handoff prompt that enables the next session to pick up exactly where you left off.

## When to Use

- Before clearing context in Claude Code (`/clear`)
- When switching to a different task and want to return later
- At end of work session to capture state
- When handing off to a different agent/session

## Process

1. **Read current state files:**
   - Use `.claude/scripts/task summary` to get task overview
   - `planning/features/*.md` — What we're building
   - `planning/notes/[epic-name]/progress.md` — Phase progress (if exists)
   - Recent git commits — What's been done

2. **Identify:**
   - Current task/phase
   - What's completed in this session
   - What's in progress (partially done)
   - What's next (immediate next steps)
   - Any blockers or decisions needed

3. **Generate handoff prompt** with:
   - Context summary
   - File locations
   - Git state (branch, recent commits)
   - Completed items
   - In-progress items
   - Next steps with specifics
   - Any commands to run

## Output Format

Generate a markdown prompt like this:

```markdown
---
disable-model-invocation: true

## [Task/Feature Name] - Handoff Prompt

### Context

[1-2 sentence summary of what we're working on]

**PRD:** `planning/prd/[name].md`
**Design:** `planning/design/screens.md`
**Branch:** `[branch-name]`

### Current Phase

[Phase X: Name] - [Status: In Progress / Blocked / Ready for Review]

### What's Done (This Session)

- ✅ [Completed item 1]
- ✅ [Completed item 2]
- ✅ [Completed item 3]

### What's In Progress

- 🟡 [Partially done item] — [what's left to do]

### What's Next

1. **[Next task]**
   - Location: `[file path]`
   - Details: [specific guidance]

2. **[Following task]**
   - Location: `[file path]`
   - Details: [specific guidance]

### Quick Start Commands

```bash
# Check current state
git status
git log --oneline -5

# Build and run (if applicable)
xcodebuild build -scheme AppName -destination 'platform=macOS'
```

### Notes

- [Any important context, decisions made, or blockers]
- [Things to watch out for]
- [Deferred items and why]

---
disable-model-invocation: true
```

## Gathering Information

### From PROGRESS.md
- Current phase (PRD, Design, Build Phase X, Test, Ship)
- What's marked complete vs in progress
- Next step indicator

### From Git
```bash
# Current branch
git branch --show-current

# Recent commits (what was done)
git log --oneline -5

# Uncommitted changes (what's in progress)
git status --short

# Changed files
git diff --name-only
```

### From Context
- What the user has been working on in this conversation
- Any errors encountered and how they were resolved
- Decisions made during the session

## Example Output

```markdown
---
disable-model-invocation: true

## Invoice Dashboard - Handoff Prompt

### Context

Building an invoice management macOS app. Currently iterating based on feedback.

**PRD:** `planning/prd/invoice-dashboard.md`
**Design:** `planning/design/screens.md`
**Branch:** `main`

### Current Phase

Build - Complete, Iterating

### What's Done (This Session)

- ✅ Dashboard with invoice stats and list
- ✅ InvoiceService for CRUD operations
- ✅ Sample data generators with realistic invoice data
- ✅ Create invoice sheet

### What's In Progress

- 🟡 Status filter — Picker added, need to wire up filtering logic

### What's Next

1. **Wire up status filter**
   - Location: `Sources/Views/Invoices/InvoiceFiltersView.swift`
   - Details: Filter invoice list by status (draft, sent, paid, overdue)

2. **Add export button**
   - Location: `Sources/Views/Dashboard/DashboardView.swift`
   - Details: Export invoice list to CSV

### Quick Start Commands

```bash
# Build and run
xcodebuild build -scheme AppName -destination 'platform=macOS'
open AppName.xcodeproj
```

### Notes

- Using SwiftUI Picker for the filter dropdown
- Export will use NSSavePanel for file location
- Deferred: Email integration

---
disable-model-invocation: true
```

## Variations

### For Bug Fixes / Code Reviews

Include:
- Issue/review document location
- Which issues are fixed
- Which issues remain (with priority)
- Test commands if applicable

### For Design Work

Include:
- Which screens are designed
- Which screens need revision
- User feedback received
- Design decisions made

### For PRD Work

Include:
- Discovery questions answered
- Open questions remaining
- Scope decisions made
- Ready for design or not

## Tips for Good Handoffs

1. **Be specific about file paths** — Don't make next session hunt for files
2. **Include the "why"** — Not just what to do, but context for decisions
3. **Note any gotchas** — Things that caused problems or need attention
4. **List commands** — Make it easy to get back to working state
5. **Prioritize next steps** — What's most important to do first
