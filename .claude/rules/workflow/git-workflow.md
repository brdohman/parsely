# Git Workflow

## Branch Strategy

One branch per epic, created automatically when work begins.

```
main (always buildable, protected)
├── epic/[epic-id]-[name]       <- created by /build-epic or first /build
│   ├── feat(scope): task 1     <- commits reference task IDs
│   ├── feat(scope): task 2
│   └── merge back via PR when epic complete
```

## Branch Lifecycle

### 1. Branch Creation (Automatic)
When `/build-epic` or `/build` starts the first task in an epic:
1. Read epic metadata for `branch` field (e.g., `epic/PROJECT-100-foundation`)
2. Check current branch: `git branch --show-current`
3. If not on the epic branch:
   - If branch exists: `git checkout epic/[epic-id]-[name]`
   - If branch doesn't exist: `git checkout -b epic/[epic-id]-[name]` from `base_branch` (default: main)
4. Confirm: "Working on branch: epic/[epic-id]-[name]"

### 2. During Development
- All task commits go to the epic branch
- Commit after each task completion: `/commit`
- Include task ID in every commit message

### 3. Epic Completion -> Squash Merge (Remote or Local)
When human UAT is complete, user runs `/complete-epic [epic-id]`:
1. `/complete-epic` verifies all UAT work is resolved, runs final checks
2. Build-engineer reads config from `.claude/config/git.conf`
3. **If no remote:** squash merge locally → commit with epic summary → delete branch
4. **If remote configured:** push → create PR → wait for CI + CodeRabbit → **report results to user** → merge only on user confirmation
5. Verify clean state on `base_branch`

**The PR is never auto-merged.** The user always confirms before merge. This allows reviewing CodeRabbit findings, CI results, and the PR diff on GitHub before closing.

### Remote Configuration

Set in `.claude/config/git.conf`:
```
REMOTE_NAME=origin    # push + PR + auto-merge
REMOTE_NAME=          # local only (no push)
```

### 4. After Merge
- Epic branch deleted automatically by finalization
- Tag the release if archiving: handled by `/archive`
- Start next epic from main

## Commit Convention

```
<type>(<scope>): <description> (task-<id>)

[optional body]
```

Types: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`
Scopes: `view`, `viewmodel`, `model`, `service`, `core-data`, `ui`, `test`

Examples:
```
feat(viewmodel): add user authentication (task-42)
fix(view): handle empty state in sidebar (task-43)
test(service): add sync service unit tests (task-44)
```

## Pre-Commit Checks

Enforced by `.claude/hooks/git-guards.sh`:
- Gitleaks secret scanning (blocks on findings)
- SwiftLint passes (blocks on errors)
- Build check (optional, enable with `CLAUDE_PRE_COMMIT_BUILD=true`)

## Enforcement

The git strategy is enforced through hooks, scripts, and agent instructions:

| Rule | Enforced By | Mechanism |
|-|-|-|
| Branch per epic | `scripts/ensure-epic-branch.sh` | Called at epic/story start by coordinator |
| No commits to main | `hooks/git-guards.sh` (PreToolUse) | Blocks with exit 2 when epic branches exist |
| Commit per task | `hooks/validate-task-completion.sh` (TaskCompleted) | Blocks completion if uncommitted Swift changes |
| Commit message format | `hooks/git-guards.sh` (PreToolUse) | Warns on missing conventional format or task ref |
| Agent commits own work | `agents/macos-developer-agent.md` | Git Workflow section requires commit before complete |
| Branch validation on /commit | `agents/build-engineer-agent.md` | Step 0 checks branch before committing |

## Hotfix Process

For urgent fixes on a released version:
1. Branch from main: `git checkout -b hotfix/[description]`
2. Fix the issue, commit with `fix(scope): description`
3. Push and create PR to main
4. After merge, tag if needed

## Never

- Commit directly to main during development (use epic branches)
- Force push to main/master
- Commit .env files, secrets, or API keys
- Skip pre-commit checks with --no-verify
- Leave epic branches unmerged after completion
- Skip Git Finalization after epic UAT approval
- Start a new epic while a stale epic branch exists
