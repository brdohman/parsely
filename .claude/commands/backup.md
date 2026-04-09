---
disable-model-invocation: true
description: Archive task state to planning/backups/{timestamp} for historical records after epic completion
argument-hint: [name] - optional backup name, defaults to timestamp
---

# /backup

Archive all task JSON files from the current session to a git-trackable directory. Use after completing an epic to preserve a snapshot of all task state for historical reference.

**Note:** This is an archival tool, not a session persistence mechanism. Tasks persist across sessions automatically via `CLAUDE_CODE_TASK_LIST_ID`.

**Schema Version:** v2.0 - Archives preserve full task metadata including `schema_version` field.

## Usage

```
/backup                  # Archive to planning/backups/{timestamp}
/backup cashflow-100     # Archive to planning/backups/cashflow-100
```

## When to Use

- After an epic passes human UAT and is marked completed
- Before major refactoring of task structure
- As a historical record of task state at a point in time

## How It Works

Claude Code stores tasks at `~/.claude/tasks/{task-list-id}/*.json`. This command copies those files to `planning/backups/` so they can be committed to git.

## Steps

### 1. Find Task Directory

```bash
# Use the CLAUDE_CODE_TASK_LIST_ID if set, otherwise find most recent
TASK_DIR="${CLAUDE_CODE_TASK_LIST_ID:-$(ls -t ~/.claude/tasks/ | head -1)}"
```

### 2. Create Archive

```bash
# Determine archive name
BACKUP_NAME=${ARGUMENT:-$(date +%Y%m%d-%H%M%S)}

# Create archive directory
mkdir -p planning/backups/$BACKUP_NAME

# Copy all task files
cp ~/.claude/tasks/$TASK_DIR/*.json planning/backups/$BACKUP_NAME/

# Update latest symlink
cd planning/backups && rm -f latest && ln -s $BACKUP_NAME latest
```

### 3. Compact Active Task Metadata (Optional)

After archiving, compact completed items to reduce context cost on future TaskGet calls. Only compact items with `status: "completed"`.

For each completed task/story JSON file in the active task directory:
1. Read the full `metadata.comments` array
2. Keep only the **last comment** (the one that marks final state: PASSED, COMPLETED, etc.)
3. Add a `comment_archive` field pointing to the backup: `"planning/backups/{name}/{id}.json"`
4. Write the compacted metadata back

```bash
# For each completed task file
for f in ~/.claude/tasks/$TASK_DIR/*.json; do
  STATUS=$(jq -r '.status' "$f")
  if [ "$STATUS" = "completed" ]; then
    LAST_COMMENT=$(jq '.metadata.comments[-1]' "$f")
    ARCHIVE_PATH="planning/backups/$BACKUP_NAME/$(basename $f)"
    jq --arg archive "$ARCHIVE_PATH" --argjson last "$LAST_COMMENT" \
      '.metadata.comments = [$last] | .metadata.comment_archive = $archive' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done
```

This preserves the full history in the backup while keeping active task files lean. Historical comments can always be recovered from the archive.

**Skip compaction with `--no-compact`.**

### 4. Show Summary

```
Archive complete: planning/backups/{name}/

Files archived: [N]
Files compacted: [N] (completed items, comments reduced to final state)

To persist: git add planning/backups && git commit -m "archive: [name] task state"
```
