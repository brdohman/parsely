# Real-Time Task State Updates

⛔ **Every state change MUST be reflected in the task JSON immediately via TaskUpdate.** External tools watch task files for real-time status. A task that stays "pending" while an agent is building it is a broken contract.

## Protocol 0: Verify After Write

⛔ **After EVERY TaskUpdate that changes `status` or `review_result`, immediately call TaskGet to confirm the write persisted.**

```
1. TaskUpdate [id] → set status: "completed" (or review_result, review_stage)
2. TaskGet [id]    → read back the task
3. IF the field you just wrote does NOT match what you set:
   → Retry the TaskUpdate (same payload)
   → TaskGet again to verify
   → Max 3 attempts. If still wrong after 3, report the error and stop.
```

This prevents a known issue where TaskUpdate succeeds at the API level but the underlying file is not updated, causing the coordinator to see stale state and wait indefinitely.

**This applies to ALL agents — implementation agents, review agents, fix agents.**

## Protocol 1: Read Before Write

**Always call `TaskGet` before `TaskUpdate`.**

TaskUpdate merges metadata. If you set `metadata.comments` without reading first, you overwrite the existing array.

```
# CORRECT
1. TaskGet [id]          -> read current metadata
2. Build new metadata    -> preserve existing fields, append to comments
3. TaskUpdate [id]       -> write merged metadata

# WRONG
1. TaskUpdate [id]       -> blindly sets metadata.comments: [newComment]
                            (destroys all previous comments)
```

The `comments` array is append-only. Always spread existing comments: `[...existing_comments, newComment]`.

## Protocol 2: Claim Before Work

⛔ **Before writing a single line of code, claim the task.**

```
1. TaskGet [id]
   - Verify: metadata.approval == "approved"
   - Verify: metadata.blocked == false
   - If either fails -> HARD STOP

2. TaskUpdate [id]:
   - status: "in_progress"
   - metadata.claimed_by: "[agent-name]-agent"
   - metadata.claimed_at: "[ISO8601 now]"
   - metadata.comments: [...existing, STARTING comment]

3. Advance parent Story to in_progress (if not already):
   - TaskGet [parent-story-id] (from metadata.parent)
   - If parent story status == "pending":
     TaskUpdate [parent-story-id]:
       - status: "in_progress"
       - metadata.comments: [...existing, "STARTED: First task claimed by [agent]"]
   - If parent story status is already "in_progress" -> skip
```

**STARTING comment (on task):**
```json
{
  "id": "C[N]",
  "timestamp": "[ISO8601]",
  "author": "[agent-name]-agent",
  "type": "note",
  "content": "STARTING: [brief plan]. Expected files: [list]."
}
```

## Protocol 3: Complete With Comments

⛔ **A task cannot be marked completed without implementation + testing comments in the SAME TaskUpdate.**

```
1. TaskGet [id]  -> read current metadata and comments

2. TaskUpdate [id] (single call):
   - status: "completed"
   - metadata.comments: [...existing, implementationComment, testingComment]
```

| Comment Type | `type` field | Required |
|---|---|---|
| Implementation | `"implementation"` | Always |
| Testing | `"testing"` | Unless `testable: false` |

If either is missing -> do NOT set status to completed.

**Implementation comments MUST include API verification status** per `.claude/rules/global/verify-claims.md`. List key APIs/frameworks used with `[VERIFIED: source]` or `[UNVERIFIED]` tags. This helps code reviewers know what to trust vs what needs checking.

## Protocol 4: Parent Advancement

After completing the last task in a story, advance the parent story.

```
1. TaskGet [parent-story-id]  -> get parent story

2. TaskList -> find all tasks where metadata.parent == [parent-story-id]

3. Check: are ALL sibling tasks status == "completed"?
   - If NO  -> stop, report "X of Y complete"
   - If YES -> continue to step 4

4. TaskGet [parent-story-id]  -> re-read before write

5. TaskUpdate [parent-story-id]:
   - metadata.review_stage: "code-review"
   - metadata.review_result: "awaiting"
   - metadata.comments: [...existing, handoffComment]
```

**Handoff comment:**
```json
{
  "id": "C[N]",
  "timestamp": "[ISO8601]",
  "author": "[agent-name]-agent",
  "type": "handoff",
  "content": "READY FOR CODE REVIEW\n\nAll [X] tasks completed:\n- [task-id]: [title]\n\nFiles changed: [list]\nTests added: [list]"
}
```

## Protocol 5: Dependency Unblocking

After completing any task or story, check if it unblocks dependents.

```
1. Read completed item's `blocks` array (from TaskGet in prior step)

2. For each blocked item ID in the array:
   a. TaskGet [blocked-id]  -> read its blockedBy list
   b. Check: are ALL items in blockedBy now completed?
   c. If YES:
      TaskUpdate [blocked-id]:
        - metadata.blocked: false
        - metadata.comments: [...existing, unblock comment]
```

**Unblock comment:**
```json
{
  "id": "C[N]",
  "timestamp": "[ISO8601]",
  "author": "[agent-name]-agent",
  "type": "note",
  "content": "UNBLOCKED: Dependency [completed-id] is now complete."
}
```

## Protocol 6: Comment Format

All comments use structured JSON. There are two variants: **base** (most comments) and **trackable** (rejections only).

### Base comment (all non-rejection types)

```json
{
  "id": "C[N]",
  "timestamp": "[ISO8601]",
  "author": "[agent-name]-agent",
  "type": "[type]",
  "content": "[structured text]"
}
```

Use this for: `note`, `implementation`, `testing`, `handoff`, `review`, `fix`.

### Trackable comment (rejection type only)

```json
{
  "id": "C[N]",
  "timestamp": "[ISO8601]",
  "author": "[agent-name]-agent",
  "type": "rejection",
  "content": "[structured text]",
  "resolved": false,
  "resolved_by": null,
  "resolved_at": null
}
```

The `resolved` fields exist only on rejections because they are actionable items that need tracking. When a developer fixes the issues, the reviewer sets `resolved: true`, `resolved_by`, and `resolved_at`. Non-rejection comments (notes, reviews, handoffs) are permanent records that are never "resolved."

### Field reference

| Field | Rule |
|---|---|
| `id` | Sequential per task. Read existing comments, use next number. |
| `timestamp` | Current time, ISO8601 with timezone (e.g., `2026-01-30T10:00:00Z`) |
| `author` | Agent name with `-agent` suffix (e.g., `macos-developer-agent`) |
| `type` | One of: `note`, `implementation`, `testing`, `handoff`, `review`, `fix`, `rejection` |
| `resolved` | **Rejection only.** Default `false`. Set `true` when issues are addressed. |
| `resolved_by` | **Rejection only.** Agent that resolved the issues. |
| `resolved_at` | **Rejection only.** ISO8601 timestamp when resolved. |

## Never

- Set `status: "in_progress"` without also setting `claimed_by` and `claimed_at`
- Set `status: "completed"` without implementation and testing comments in the same call
- Call `TaskUpdate` without a preceding `TaskGet` in the same workflow step
- Overwrite `metadata.comments` instead of appending to the existing array
- Leave a task in `pending` while actively working on it
- Complete the last sibling task without checking parent story advancement (Protocol 4)
- Complete a task without checking for blocked dependents to unblock (Protocol 5)
- Use plain string comments instead of the structured JSON object format
- Skip the STARTING comment when claiming a task
