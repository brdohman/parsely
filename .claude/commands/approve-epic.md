---
disable-model-invocation: true
description: Approve an epic and all its stories/tasks for implementation. Signals that the full plan has been reviewed and is ready to build.
argument-hint: <epic-name-or-id> (required - epic to approve)
---

# /approve-epic

Approve an epic — including all its stories and tasks — for implementation. This is the human gate that signals the entire plan has been reviewed and is ready to build.

## When to Use

After the planning phase is complete:
1. Epic created (via `/epic` or `/feature`)
2. Stories and tasks broken out (via `/write-stories-and-tasks`)
3. Human has reviewed the epic, stories, and tasks
4. Everything looks good — run `/approve-epic` to green-light the whole plan

## Arguments

- `<epic-name-or-id>` (required) - The epic to approve. Can be:
  - A task ID (e.g., `1`, `42`)
  - Part of the epic title (e.g., `"Foundation"`, `"Authentication"`)

## Flow

1. **Find the epic**
   ```typescript
   // If argument looks like a number, try direct ID lookup first
   if (isNumeric(argument)) {
     const epic = TaskGet({ id: argument })
     if (epic.metadata.type === "epic") {
       // Found by ID
     }
   }

   // Otherwise, search by title
   const allTasks = TaskList()
   const matchingEpics = allTasks.filter(t =>
     t.metadata.type === "epic" &&
     t.subject.toLowerCase().includes(argument.toLowerCase())
   )

   // If no match found, report and stop
   // If multiple matches found, list them and ask user to be more specific
   // If exactly one match, use it
   ```

2. **Show what will be approved** - Display the epic and its full tree:
   ```
   Approving: [epic-id] [epic-title]
     Stories: [N]
     Tasks: [N]
   ```

3. **Approve the entire tree**
   ```typescript
   // Update epic
   const epicMeta = epic.metadata
   TaskUpdate({
     id: epic.id,
     metadata: {
       ...epicMeta,
       approval: "approved"
     }
   })

   // Get all tasks to find stories and tasks in hierarchy
   const allTasks = TaskList()

   // Find stories under this epic
   const stories = allTasks.filter(t =>
     t.metadata.type === "story" &&
     t.metadata.parent === epic.id
   )

   let storyCount = 0
   let taskCount = 0

   // Update each story and its tasks
   for (const story of stories) {
     TaskUpdate({
       id: story.id,
       metadata: {
         ...story.metadata,
         approval: "approved"
       }
     })
     storyCount++

     // Find tasks under this story
     const tasks = allTasks.filter(t =>
       t.metadata.type === "task" &&
       t.metadata.parent === story.id
     )

     for (const task of tasks) {
       TaskUpdate({
         id: task.id,
         metadata: {
           ...task.metadata,
           approval: "approved"
         }
       })
       taskCount++
     }
   }

   // Add approval comment to epic
   const existingComments = epicMeta.comments || []
   TaskUpdate({
     id: epic.id,
     metadata: {
       ...epicMeta,
       approval: "approved",
       comments: [
         ...existingComments,
         {
           id: `C${existingComments.length + 1}`,
           timestamp: new Date().toISOString(),
           author: "human",
           type: "approval",
           content: `APPROVED via /approve-epic\n- 1 epic\n- ${storyCount} stories\n- ${taskCount} tasks`
         }
       ]
     }
   })
   ```

4. **Report results**

## Output Format

### Success
```
Approved: [task-id] [epic-title]

  - 1 epic
  - 3 stories
  - 14 tasks

All items approved for implementation. Run /build to start.
```

### Epic not found
```
No epic found matching "[argument]".

Available epics:
  - [id]: [title] (pending)
  - [id]: [title] (approved)
```

### Multiple matches
```
Multiple epics match "[argument]":
  - [id]: [title]
  - [id]: [title]

Please be more specific or use the task ID.
```

### Already approved
```
[task-id] [epic-title] is already approved.

  - Stories: 3 approved
  - Tasks: 14 approved

Nothing to do. Run /build to start implementation.
```

## Fields Updated

| Issue Type | Field Changed | New Value |
|------------|---------------|-----------|
| Epic | `metadata.approval` | `"approved"` |
| Story | `metadata.approval` | `"approved"` |
| Task | `metadata.approval` | `"approved"` |

## Task Commands Reference

```typescript
TaskGet({ id: "[id]" })
TaskList()
TaskUpdate({ id: "[id]", metadata: { ... } })
```
