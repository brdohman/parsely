---
disable-model-invocation: true
description: Update the Claude toolkit with backup and rollback safety
argument-hint: [--check | --backup-only | --force]
---

# /update-toolkit

Safely update the Claude Code toolkit with automatic backup and rollback.

## Overview

Updates the toolkit from a source location while:
- Creating timestamped backups before any changes
- Showing diffs of what will change
- Verifying updates work correctly
- Auto-rolling back if verification fails

## Options

| Flag | Description |
|------|-------------|
| `--check` | Only check for updates, don't apply |
| `--backup-only` | Create backup without updating |
| `--force` | Skip confirmation prompts |
| `--source PATH` | Custom source path for updates |

## Flow

### Phase 1: Check

Compare local toolkit with source:

```
=== Update Check ===

Source: /path/to/toolkit-source

Changes detected:
  .claude/commands/
    + new-command.md (new file)
    ~ feature.md (modified)

  .claude/scripts/
    ~ setup-dev.sh (modified)

Files unchanged: 45
Files to update: 3
New files: 1
```

### Phase 2: Backup

Create timestamped backups before any changes:

```
=== Creating Backups ===

Backup location: .claude-backup-20240108-1234/
  ✓ commands/ (22 files)
  ✓ scripts/ (15 files)
  ✓ rules/ (12 files)
  ✓ settings.json

Total backup size: 1.2 MB
```

### Phase 3: Preview

Show detailed changes (with option to view diffs):

```
=== Update Preview ===

Modified files:

1. .claude/commands/feature.md
   - Added new validation step
   - Updated output format
   [View diff? y/N]

2. .claude/scripts/setup-dev.sh
   - Fixed port detection bug
   - Added better error messages
   [View diff? y/N]

Proceed with update? [y/N]
```

### Phase 4: Update

Apply changes:

```
=== Applying Updates ===

Updating .claude/:
  ✓ commands/new-command.md (created)
  ✓ commands/feature.md (updated)
  ✓ scripts/setup-dev.sh (updated)
```

### Phase 5: Verify

Run verification checks:

```
=== Verification ===

Testing scripts:
  ✓ setup-project.sh --validate-only

All verifications passed!
```

### Phase 6: Cleanup

Offer to remove backups:

```
=== Update Complete ===

Updated: 3 files
Backup: .claude-backup-20240108-1234/

Remove backup directory? [y/N]
  (You can restore with: cp -r .claude-backup-20240108-1234/.claude .)
```

## Rollback

If verification fails, automatic rollback:

```
=== Verification Failed ===

Error: Script validation failed
  Missing required file

Rolling back...
  ✓ Restored .claude/ from backup

Rollback complete. Your toolkit is unchanged.

Backup preserved at:
  .claude-backup-20240108-1234/

To investigate:
  Check the error log: .claude/logs/update-20240108-1234.log
```

## Manual Rollback

If you need to rollback manually:

```bash
# Restore .claude/
rm -rf .claude
cp -r .claude-backup-YYYYMMDD-HHMM/.claude .
```

## Backup Locations

```
project/
├── .claude-backup-YYYYMMDD-HHMM/
│   └── .claude/          # Full backup of .claude/
└── ...
```

## Verification Checks

The update is verified by:

1. **Script validation**: Run `setup-project.sh --validate-only`
2. **Syntax check**: Ensure all .md files are valid
3. **Permissions**: Verify .sh files are executable

## Logging

All operations logged to: `.claude/logs/update-{timestamp}.log`

Includes:
- Every file backed up (with path)
- Every file updated (with source)
- Verification results
- Rollback actions if triggered
- Final status

## Safety Guarantees

1. **No data loss**: Always backup before changes
2. **Atomic updates**: All-or-nothing (rollback on failure)
3. **Verification**: Updates aren't complete until verified
4. **Transparency**: Every change is logged and shown
5. **Recovery**: Clear instructions for manual rollback
