---
disable-model-invocation: true
description: Finalize an epic after Human UAT. Verifies all work is done (including bugs/fixes from UAT), runs final checks, and merges the epic branch. Run this when you're satisfied with UAT.
argument-hint: [epic-id] (required - the Epic to complete)
---

# /complete-epic

Finalize an epic after Human UAT. Verifies all UAT-spawned work is resolved, runs final verification, and handles git finalization (local squash merge or PR with human-confirmed merge).

> For workflow state fields and comment format: see `.claude/docs/WORKFLOW-STATE.md`

## When to Run

After `/build-epic` presents Human UAT and you've finished testing. This could be immediately (everything looks good) or after multiple sessions of filing bugs, reworking UI, adding polish, etc.

```
/build-epic completes → Human UAT (you test, file bugs, rework) → /complete-epic
```

## Pre-Conditions

1. Epic has `review_stage: "human-uat"`
2. Epic is on an `epic/*` branch

**If pre-conditions not met**, report status and stop.

---

## Flow

### Step 1: Assess UAT State

```
TaskGet [epic-id]
# Verify review_stage == "human-uat"

TaskList -> find ALL items under this epic (stories, tasks, bugs, techdebt)
# Categorize:
#   - Original stories/tasks: should all be completed
#   - UAT-spawned bugs: check status
#   - UAT-spawned techdebt: check status
#   - UAT-spawned tasks (polish, rework): check status
```

Report to user:

```
"Epic UAT Status:
  Original work:     [X]/[Y] stories completed ✓
  Bugs filed in UAT: [N] total — [M] completed, [K] open
  Tech debt filed:   [N] total — [M] completed, [K] open
  Other UAT tasks:   [N] total — [M] completed, [K] open

  [If all clean]: Everything looks good. Ready to finalize?
  [If open items]: There are [K] open items from UAT. How would you like to proceed?
    (a) These are tracked for later — finalize anyway
    (b) I need to fix these first — stop here"
```

**Open UAT bugs block finalization by default.** Open tech debt does not (it's intentionally deferred). If the user chooses (a) for bugs, log them in the epic completion comment as "deferred by user."

### Step 2: Final Verification

Run only after user confirms ready to finalize.

**2a. Full test suite:**

```bash
xcodebuild test -scheme [AppName] -destination 'platform=macOS' -resultBundlePath TestResults.xcresult
```

⛔ **No Untracked Failures Gate:** Every test failure must be either fixed (if caused by this epic) or have a Bug/TechDebt task filed (if pre-existing). The epic CANNOT close with untracked failures. See `.claude/docs/TESTING-POLICY.md`.

**2b. Security delta check:**

```bash
.claude/scripts/security-scope.sh $(git diff --name-only main...HEAD)
```

- **CLEAR** → proceed
- **SECURITY_REVIEW_REQUIRED** → run `/security-audit delta` before proceeding

**2c. Review artifact verification:**

```bash
.claude/scripts/verify-review-artifacts.sh --level epic
```

Verify Aikido, CodeRabbit, and Trivy review outputs exist. Re-run missing scans if needed.

**2d. Documentation check:**

```
.claude/scripts/task summary
```

Verify all items have required comments (implementation, testing, handoff, review).

### Step 3: Generate Completion Summary

```
Epic Completion Summary
=======================
Epic: [epic-id] "[Epic Title]"
Stories: [N] completed | Tasks: [M] completed
UAT items: [N] bugs fixed, [N] tech debt deferred, [N] polish tasks completed

Unit Tests:        [X]/[X] passed
Integration Tests: [Y]/[Y] passed
Coverage:          [Z]%
Security Scope:    [CLEAR / passed delta audit]
Review Artifacts:  [Complete]

READY TO FINALIZE
```

### Step 4: Mark Epic Completed

```
TaskGet [epic-id]   # read before write

TaskUpdate [epic-id]:
  status: "completed"
  review_stage: null
  review_result: null
  metadata.comments: [...existing, {
    "id": "C[N]",
    "timestamp": "[ISO8601]",
    "author": "coordinator",
    "type": "review",
    "content": "EPIC COMPLETE\n\n[completion summary from Step 3]\n\nUAT bugs deferred: [list or 'none']\nTech debt deferred: [list or 'none']"
  }]
```

### Step 5: Backup

```
/backup [epic-id]-final
```

### Step 6: Git Finalization (MANDATORY)

⛔ **This MUST run before starting the next epic.** Stale epic branches block commits to main.

Delegated to the **build-engineer** agent (`subagent_type: "build-engineer"`).

#### Remote Configuration

Reads `.claude/config/git.conf`:

| `REMOTE_NAME` | Behavior |
|---|---|
| Set (e.g., `origin`) | **Remote mode:** push, create PR, wait for CI + CodeRabbit, report back for human-confirmed merge |
| Empty or missing | **Local mode:** squash merge locally, delete branch |

#### Local Path (no remote)

Spawn build-engineer:

```
subagent_type: "build-engineer", mode: "bypassPermissions"
prompt: "FINALIZE EPIC BRANCH for [epic-id] '[epic-title]'.
  Base branch: [base_branch from epic metadata, default 'main']
  1. Verify on epic/* branch, no uncommitted changes
  2. Read REMOTE_NAME from .claude/config/git.conf — expect empty (local mode)
  3. git checkout [base_branch], git merge --squash [epic-branch], commit with epic summary
  4. git branch -D [epic-branch]
  5. Verify: on [base_branch], no epic/* branches, clean git status
  Return: MERGED (local) or FAILED: <reason>"
```

#### Remote Path (with remote)

**Phase 1: Push and Create PR** (build-engineer)

```
subagent_type: "build-engineer", mode: "bypassPermissions"
prompt: "PUSH AND CREATE PR for [epic-id] '[epic-title]'.
  Base branch: [base_branch from epic metadata, default 'main']
  1. Verify on epic/* branch, no uncommitted changes
  2. Read REMOTE_NAME from .claude/config/git.conf
  3. git push -u [REMOTE_NAME] [epic-branch]
  4. Create PR: gh pr create --base [base_branch] --title 'feat(<scope>): [Epic Title] ([epic-id])' --body '[epic summary with stories list and review checklist]'
  5. Return: PR_CREATED: PR#[N] [URL] or FAILED: <reason>
  Do NOT wait for CI. Do NOT merge. Just push and create the PR."
```

**Phase 2: Wait for CI + CodeRabbit** (build-engineer)

After PR is created, spawn build-engineer to monitor:

```
subagent_type: "build-engineer", mode: "bypassPermissions"
prompt: "WAIT FOR CI on PR#[N] for [epic-id].
  Read CI_TIMEOUT and CI_POLL_INTERVAL from .claude/config/git.conf.
  1. Wait for all CI checks to complete (poll gh pr checks)
  2. Check CodeRabbit review status
  3. Return status — do NOT merge.
  Return: CI_PASSED, CI_FAILED: <details>, CI_TIMEOUT: <details>, or CR_FINDINGS: <details>"
```

**Phase 3: Report to User and Confirm Merge**

If CodeRabbit posted findings on the PR, retrieve and triage them before presenting merge options:

```
1. Retrieve PR-level CodeRabbit findings:
   gh api repos/{owner}/{repo}/pulls/{N}/comments  (inline findings)
   gh api repos/{owner}/{repo}/pulls/{N}/reviews    (review decisions)
   gh api repos/{owner}/{repo}/issues/{N}/comments  (summary comment)

2. Apply CodeRabbit Findings Triage Protocol (.claude/rules/global/coderabbit-triage.md):
   - Triage all findings (FIX, TECHDEBT, VERIFIED FIXED, RESEARCHED)
   - For uncertain findings: spawn research agent
   - Present batch table to user
```

Present results, triage table, and PR link:

```
"PR #[N] is ready: [URL]

  CI checks:  [passed / failed: details]
  CodeRabbit: [N] findings — see triage table below

  [batch table per coderabbit-triage.md]

  Options:
  (a) Fix recommended items, then merge
  (b) Merge as-is — create TechDebt for deferred items
  (c) Review first — I'll wait while you review the PR on GitHub
  (d) Abort — leave PR open, stop finalization"
```

**On (a) Merge:**

```
subagent_type: "build-engineer", mode: "bypassPermissions"
prompt: "MERGE PR#[N] for [epic-id].
  1. gh pr merge [N] --squash --delete-branch
  2. git checkout [base_branch], git pull [REMOTE_NAME] [base_branch]
  3. git branch -D [epic-branch] 2>/dev/null || true
  4. Verify: on [base_branch], no epic/* branches, clean status
  Return: MERGED (remote) or FAILED: <reason>"
```

**On (b) Review first:**

Wait for user to come back and confirm. They may run this across sessions.

**On (c) Fix issues:**

```
1. Spawn macos-developer to fix identified issues → commits to epic branch
2. git push [REMOTE_NAME] [epic-branch] → triggers CI re-run on existing PR
3. Re-run Phase 2 (wait for CI)
4. Report results again → loop back to Phase 3
```

**On (d) Abort:**

Log: "Finalization aborted. PR #[N] left open at [URL]." → STOP. User can re-run `/complete-epic` later.

### Step 7: Cleanup

After successful merge:

```
1. Verify git state:
   git branch --show-current   # must be base_branch
   git branch --list 'epic/*'  # must be empty
   git status                  # must be clean

2. Update planning/progress.md to mark epic Done with completion date

3. Tell user:
   "Epic [epic-id] finalized and merged to [base_branch].

    To free context for the next epic, type: clear all tasks
    (This removes task files. The /backup from Step 5 preserves the archive.)"
```

---

## Recovery: Stale Branch From Prior Epic

If starting a new epic and a stale `epic/*` branch exists from a completed epic:

```bash
REMOTE_NAME=$(grep '^REMOTE_NAME=' .claude/config/git.conf 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
HAS_REMOTE=false
[ -n "$REMOTE_NAME" ] && git remote get-url "$REMOTE_NAME" &>/dev/null && HAS_REMOTE=true

UNMERGED=$(git log main..<stale-branch> --oneline | wc -l | tr -d ' ')

if [ "$UNMERGED" = "0" ]; then
  git branch -D <stale-branch>
  $HAS_REMOTE && git push "$REMOTE_NAME" --delete <stale-branch> 2>/dev/null || true
elif $HAS_REMOTE; then
  git checkout <stale-branch>
  git push -u "$REMOTE_NAME" <stale-branch>
  gh pr create --base main --title "feat(<scope>): <Epic Title> (retroactive)" --body "Retroactive merge of completed epic."
  # DO NOT auto-merge — ask user to review and merge manually
  echo "PR created. Please review and merge when ready."
else
  git checkout main
  git merge --squash <stale-branch>
  git commit -m "feat(<scope>): <Epic Title> (retroactive merge)"
  git branch -D <stale-branch>
fi
```

## Never

- Skip pre-condition verification
- Complete Epic with failing tests or unresolved security issues
- Complete Epic without verifying UAT-spawned bugs are resolved (or explicitly deferred by user)
- Skip the Epic completion comment
- Auto-merge a PR without user confirmation
- Archive or clear tasks without user confirmation
- Clear tasks without running /backup first
