---
disable-model-invocation: true
description: Add ideas to the backlog for future consideration
argument-hint: add <title> (e.g., "add Dark mode support")
---

# /backlog Command

Capture ideas and features for future consideration without derailing current work.

## Signature

```
/backlog add <title>
```

**Arguments:**
- `add` - Subcommand to add a new item
- `<title>` - Brief title for the backlog item

**Examples:**
```
/backlog add Dark mode support
/backlog add Keyboard shortcuts for power users
/backlog add Export data to CSV
```

---
disable-model-invocation: true

## Execution Flow

### Step 1: Validate Arguments

If no `add` subcommand or title provided:
```
Usage: /backlog add <title>

Examples:
  /backlog add Dark mode support
  /backlog add Export to CSV

To view the backlog, open: planning/backlog.md
```

### Step 2: Ask Clarifying Questions

Use `AskUserQuestion` to gather details:

```
AskUserQuestion({
  questions: [
    {
      header: "Category",
      question: "What type of backlog item is this?",
      options: [
        { label: "feature (Recommended)", description: "New user-facing functionality" },
        { label: "enhancement", description: "Improvement to existing feature" },
        { label: "tech-debt", description: "Code/architecture improvements" },
        { label: "research", description: "Needs investigation first" }
      ],
      multiSelect: false
    },
    {
      header: "Priority",
      question: "How valuable would this be?",
      options: [
        { label: "medium (Recommended)", description: "Valuable but not urgent - good default" },
        { label: "high", description: "Would significantly improve the product" },
        { label: "low", description: "Nice to have someday" }
      ],
      multiSelect: false
    }
  ]
})
```

### Step 3: Ask for Notes (Optional)

```
AskUserQuestion({
  questions: [
    {
      header: "Notes",
      question: "Any additional context? (Select 'Skip' to add without notes)",
      options: [
        { label: "Skip (Recommended)", description: "Add item without additional notes" },
        { label: "Add notes", description: "I want to add a brief description or rationale" }
      ],
      multiSelect: false
    }
  ]
})
```

If user selects "Add notes", ask them to type it (they'll use "Other" option or you can prompt for text).

### Step 4: Check/Create Backlog File

```
1. Check if planning/backlog.md exists
2. If not, read .claude/templates/backlog.md
3. Create planning/backlog.md from template
```

### Step 5: Generate Item ID

Read existing backlog and find highest BL-XXX number, then increment:
- If no items exist: `BL-001`
- If highest is `BL-015`: next is `BL-016`

### Step 6: Append Item

Add new item to `planning/backlog.md` after the `<!-- New items are added below this line -->` marker:

```markdown
- [ ] **BL-XXX**: [Title]
  - Category: [category] | Priority: [priority] | Added: [YYYY-MM-DD]
  - Notes: [notes or "—"]
```

### Step 7: Confirm

```
Added to backlog:

  BL-XXX: [Title]
  Category: [category] | Priority: [priority]

View full backlog: planning/backlog.md
```

---
disable-model-invocation: true

## File Location

| File | Purpose |
|------|---------|
| `planning/backlog.md` | Active backlog (created on first use) |
| `.claude/templates/backlog.md` | Template for new backlogs |

---
disable-model-invocation: true

## Example Output

After running `/backlog add Dark mode support`:

```markdown
- [ ] **BL-001**: Dark mode support
  - Category: feature | Priority: medium | Added: 2026-01-31
  - Notes: —
```

After running `/backlog add Refactor API client` with notes:

```markdown
- [ ] **BL-002**: Refactor API client
  - Category: tech-debt | Priority: high | Added: 2026-01-31
  - Notes: Current implementation mixes concerns. Should separate auth from requests.
```

---
disable-model-invocation: true

## Promoting Items

When ready to work on a backlog item:

1. Mark it done in `planning/backlog.md`: `[x]`
2. Run `/feature` or create planning docs
3. Reference the backlog ID in the epic for traceability

---
disable-model-invocation: true

## Cross-References

- **Template:** `.claude/templates/backlog.md`
- **Feature workflow:** `/feature` command
- **Epic creation:** `/epic` command
