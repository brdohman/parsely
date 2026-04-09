---
name: github
description: "GitHub CLI patterns for PRs, issues, and repository management."
---

# GitHub Skill

GitHub CLI patterns for the 5WTH Tracker workflow.

## When to Use

- Creating pull requests
- Checking PR status
- Viewing CI checks
- Managing branches

## PR Workflow

### Create PR
```bash
gh pr create --title "[title]" --body "[body]"
```

### PR with Template
```bash
gh pr create --title "feat(dashboard): add user dashboard" --body "$(cat <<EOF
## Summary
- Added user dashboard component
- Integrated with user service
- Added loading and error states

## Tasks
- [task-t4] Create user service
- [task-t5] Add API routes

## Test Coverage
- 87% overall
- All critical rules covered
EOF
)"
```

## Common Commands

```bash
# Pull Requests
gh pr create              # Create PR
gh pr view                # View current PR
gh pr checks              # View CI status
gh pr merge               # Merge PR
gh pr close               # Close without merge

# Issues
gh issue create           # Create issue
gh issue list             # List issues
gh issue view [number]    # View issue

# Repository
gh repo view              # View repo info
gh repo clone [repo]      # Clone repo

# Actions
gh run list               # List workflow runs
gh run view [id]          # View run details
gh run watch [id]         # Watch run in real-time
```

## Branch Strategy

```
main (always deployable)
├── phase-1-[name]
│   ├── commit: step 1.1
│   ├── commit: step 1.2
│   └── (merge when phase complete)
├── phase-2-[name]
│   └── ...
```

## Commit Convention

```
<type>(<scope>): <description> (task-xxx)
```

Types: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`

## Official Docs

https://cli.github.com/manual/
