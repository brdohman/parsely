---
description: Commit changes with conventional message including task ID. Enforces pre-commit gate. Delegates to Build Engineer agent.
argument-hint: message (optional, auto-generated)
disable-model-invocation: true
---

# /commit

Git commit with pre-commit gate and task reference.

## Delegation

**IMMEDIATELY delegate to Build Engineer agent.**

## Flow

1. **Pre-commit Gate** (BLOCKING):
   - Swift compiles: `xcodebuild build`
   - Lint passes: `swiftlint`
   - Unit tests pass: `xcodebuild test`

2. **If gate FAILS**:
   - Show what failed
   - NO commit allowed
   - "Fix issues and run /commit again"

3. **If gate PASSES**:
   - Get current task from Claude Code Tasks context using `TaskList` (filter for in_progress)
   - Generate commit message with task ID:
     ```bash
     git commit -m "feat(viewmodel): add user authentication (task-42)"
     ```

## Commit Message Convention

Format: `<type>(<scope>): <description> (task-xxx)`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `test`: Adding tests
- `docs`: Documentation
- `refactor`: Code refactoring
- `chore`: Maintenance

Scopes:
- `view`: SwiftUI views
- `viewmodel`: View models
- `model`: Data models
- `service`: Network/business services
- `core-data`: Core Data persistence
- `ui`: UI components and styling
- `test`: Test infrastructure

Examples:
```bash
git commit -m "feat(viewmodel): add login state management (task-42)"
git commit -m "fix(service): handle network timeout (task-bug-1)"
git commit -m "test(model): add user entity tests (task-23)"
git commit -m "refactor(core-data): simplify fetch requests (task-15)"
```

## Output Format

### Pass
```
Pre-commit gate passed

Commit created:
  feat(viewmodel): add user authentication (task-42)

Files committed:
  - app/AppName/AppName/ViewModels/AuthViewModel.swift
  - app/AppName/AppNameTests/ViewModelTests/AuthViewModelTests.swift

Task [task-42] linked to commit abc123.

Run `/checkpoint` before pushing.
```

### Fail
```
Pre-commit gate FAILED

Failures:
- Swift: 2 compiler errors
- SwiftLint: 3 violations

Cannot commit until issues fixed.

Fix issues and run `/commit` again.
```

## Pre-commit Checks

```bash
xcodebuild build -scheme YourScheme -destination 'platform=macOS'  # Swift compile
swiftlint                                                           # SwiftLint
xcodebuild test -scheme YourScheme -destination 'platform=macOS'   # Unit tests
```

## Task Tool Usage

```typescript
// Find current in-progress task
TaskList({ status: "in_progress" })

// Get task details for commit message context
TaskGet({ task_id: "task-42" })

// After successful commit, optionally update task with commit reference
TaskUpdate({
  task_id: "task-42",
  metadata: {
    commits: ["abc123def456"]
  }
})
```

## Linking Commits to Tasks

The commit message format `(task-xxx)` enables:
- Traceability from code to task
- Automated task detection in PRs
- Orphan commit detection (commits without task references)

When reviewing git history:
```bash
git log --oneline | grep -oE 'task-[0-9]+'
```
