---
description: Show infrastructure status, workflow state, and recommended next action
argument-hint: [--infra | --tasks | --all]
---

# /status

Show current project status including infrastructure configuration and workflow state.

## Options

| Flag | Description |
|------|-------------|
| `--infra` | Show only infrastructure status |
| `--tasks` | Show only Tasks/workflow status |
| `--all` | Show everything (default) |

## Output Format

```
═══════════════════════════════════════════════════════
                    PROJECT STATUS
═══════════════════════════════════════════════════════

Infrastructure
──────────────
Xcode Project:
  Scheme:      ✓ AppName
  Build:       ✓ Succeeds
  Tests:       ✓ 45 passing

Code Quality:
  SwiftLint:   ✓ Configured
  GitHub:      ✓ Connected (github.com/org/repo)

Data Storage:
  Core Data:   ✓ Model configured
  Keychain:    ✓ Available

Workflow
────────
Tasks:         ✓ Available

Task Summary:
  Open:        12
  In Progress: 2
  Blocked:     1

Review Queues:
  Code Review: 2
  QA:          1
  Product:     0

Current Work:
  → task-042: Implement user authentication (in_progress)
  → task-043: Add login view validation (in_progress)

Ready to Build (approved):
  • task-044: Create password reset flow
  • task-045: Add session management
  • task-046: Implement logout

═══════════════════════════════════════════════════════
Recommended: /build task-044 to start next task
═══════════════════════════════════════════════════════
```

## Checks Performed

### Infrastructure Checks

1. **Xcode Project:**
   ```bash
   # Check for Xcode project
   ls *.xcodeproj 2>/dev/null || ls *.xcworkspace 2>/dev/null
   ```
   Shows project name if found.

2. **Build Status:**
   ```bash
   xcodebuild build -scheme AppName -destination 'platform=macOS' -quiet 2>&1
   ```
   Returns success or build errors.

3. **SwiftLint:**
   ```bash
   [ -f ".swiftlint.yml" ] && swiftlint lint --quiet 2>/dev/null
   ```

4. **GitHub:**
   ```bash
   git remote get-url origin 2>/dev/null
   ```

5. **Data Storage:**
   ```bash
   # Core Data - check for model
   find . -name "*.xcdatamodeld" -type d 2>/dev/null

   # Check for Keychain usage
   grep -r "Keychain" app/ 2>/dev/null
   ```

### Workflow Checks

6. **Task Summary:**
   Use `TaskList` to get all tasks and categorize by status:
   - Count tasks by status (open, in_progress, closed)
   - Identify blocked tasks (those with `metadata.blocked == true`)

7. **Review Queues:**
   Use `TaskList` to count tasks by review state fields:
   - `metadata.review_stage == "code-review" AND metadata.review_result == "awaiting"` - pending code review
   - `metadata.review_stage == "qa" AND metadata.review_result == "awaiting"` - pending QA
   - `metadata.review_stage == "product-review" AND metadata.review_result == "awaiting"` - pending product review

8. **Current Work:**
   Use `TaskList` to find tasks with status `in_progress`

9. **Ready Tasks:**
   Use `TaskList` to find tasks with:
   - Status `open`
   - `metadata.approval == "approved"`
   - `metadata.blocked == false`

## Task Tool Usage

```typescript
// Get all tasks
TaskList()

// Filter by status
TaskList({ status: "in_progress" })

// Get specific task details
TaskGet({ task_id: "task-042" })
```

## Recommended Actions

Based on status, suggest next action:

| Situation | Recommendation |
|-----------|----------------|
| No infrastructure | "Run `/init-macos-project` or `/setup` to configure" |
| Tasks in progress | "Continue with `/build` on current task" |
| Tasks ready | "Run `/build task-XXX` to start next task" |
| All tasks done | "Run `/feature` to plan next feature" |
| Blocked tasks exist | "Review blocked tasks" |
| Items in review queue | "Run `/code-review`, `/qa`, or `/product-review`" |

## Integration with Other Commands

- Shows Xcode project and build status
- Reflects task state from Claude Code Tasks
- Recommends `/build`, `/feature`, or setup commands as appropriate

## Logging

Status checks are not logged by default (read-only operation).
For debugging, redirect output: `/status > .claude/logs/status-check.log`
