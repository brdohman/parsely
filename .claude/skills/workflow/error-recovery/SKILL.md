---
name: error-recovery
description: "Structured recovery templates for common agent failure modes. Use when an agent fails mid-task due to context exhaustion, build failure, or unclear requirements."
user-invocable: false
---

# Error Recovery Templates

When an agent fails, the coordinator spawns a NEW agent with a recovery prompt. The recovery prompt must be under 500 words and include only what the new agent needs.

## Context Exhaustion

Agent ran out of context before completing the task.

**Recovery prompt template:**
```
Task ID: [task-id]
Story: [story-id]
What was attempted: [1-2 sentences from the last implementation comment, or STARTING comment if no impl comment exists]
What remains: [list unchecked items from task checklist]
Files already created/modified: [list from git diff or last comment]
Error: Agent exhausted context before completing.

Pick up where the previous agent left off. Read the task via TaskGet, check what files exist, and complete the remaining checklist items. Do NOT redo work that's already done.
```

**Key rule:** Never paste the failed agent's full output. Summarize in 2-3 sentences.

## Build Failure

Agent's code doesn't compile.

**Recovery prompt template:**
```
Task ID: [task-id]
Build error: [paste ONLY the error message, not full build log — typically 3-10 lines]
File with error: [path]
What the task is doing: [1 sentence from task description]

Fix the build error. Read the file, fix the issue, rebuild. If the fix requires understanding other files, read only what's needed.
```

**Key rule:** Paste the error message, not the full xcodebuild output. The error is usually 3-10 lines. The full log can be 500+ lines.

## Test Failure

Tests fail after implementation.

**Recovery prompt template:**
```
Task ID: [task-id]
Failing test: [TestClassName/testMethodName]
Test error: [assertion failure message — 1-3 lines]
Test file: [path]
Implementation file: [path]

Read the failing test, understand what it expects, read the implementation, and fix the mismatch. Run the test again to verify.
```

## Unclear Requirements

Agent couldn't determine what to build from the task description.

**Recovery approach:** Don't spawn a recovery agent. Instead:
1. Read the task description
2. Identify what's ambiguous
3. Add a comment to the task: `type: "note"`, content: "BLOCKED: [what's unclear]"
4. Set `metadata.blocked: true`
5. Ask the user to clarify via AskUserQuestion

## Merge Conflict

Agent's changes conflict with another agent's concurrent work.

**Recovery prompt template:**
```
Task ID: [task-id]
Conflicting files: [list from git status]
This task's intent: [1 sentence]

Resolve the merge conflicts in the listed files. Keep both sides' changes where possible. If the conflict is semantic (both sides changed the same logic), read both versions and pick the correct one based on the task description. Rebuild after resolving.
```

## Recovery Rules

1. **Max 500 words** in the recovery prompt. Anything longer defeats the purpose.
2. **Never paste full error logs.** Extract the relevant 3-10 lines.
3. **Never paste file contents.** The recovery agent can read files itself.
4. **Include the task ID** so the recovery agent can TaskGet for full context.
5. **State what's done and what remains.** Don't make the recovery agent figure out where the previous agent stopped.
