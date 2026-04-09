# Task Hygiene

> ⛔ **Mandatory companion rule:** `.claude/rules/global/task-state-updates.md` — exact protocols for every TaskUpdate call.

## Before Starting Work

1. Find next available task using TaskList:
   - Filter: `status: "pending"`, `metadata.approval == "approved"`, `metadata.blocked == false`
2. Claim task with TaskUpdate:
   ```
   TaskUpdate: { id: "<task-id>", status: "in_progress" }
   ```
3. **Never work without claiming**

## During Work

- Discover new work with TaskCreate:
  ```
  TaskCreate: {
    title: "Found: [description]",
    type: "task",
    description: "[what was discovered]",
    metadata: {
      discovered_from: "<parent-task-id>"
    }
  }
  ```
- Add blocking relationships if found
- Keep task description updated via TaskUpdate

## After Completing

1. Update task status:
   ```
   TaskUpdate: { id: "<task-id>", status: "completed" }
   ```
2. Use TaskList to find next available task

## Commit Messages

Include task ID in all commits:
```
feat(scope): description (task-xxx)
```

This enables orphan detection and traceability.

## Never

- Work on blocked tasks
- Leave tasks in_progress across sessions
- Skip claiming before work
- Complete tasks that are not done
- Work without a task
