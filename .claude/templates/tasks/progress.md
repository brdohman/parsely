# Project Progress Tracker Template

This template tracks which phases have been planned/completed from planning documents.

---

## Usage

1. **When to Create:** After creating planning documents in `planning/`
2. **When to Read:** Before running `/epic` - determines which phase to plan next
3. **When to Update:** After `/epic` creates an epic - mark phase as "Planned"
4. **Auto-Detection:** If no phase specified, `/epic` reads this file and picks first "Not Started" phase
5. **Manual Override:** User can run `/epic phase-3` to skip ahead

---

## Template Structure

Copy this structure to `planning/progress.md` for your project:

```markdown
# Project Progress Tracker

## Project Info

| Field | Value |
|-------|-------|
| **Project Name** | [PROJECT_NAME] |
| **Project Code** | [PROJECT_CODE] |
| **Platform** | macOS [VERSION]+ |
| **Started** | [YYYY-MM-DD] |
| **Last Updated** | [YYYY-MM-DD] |
| **Updated By** | [claude/human] |

---

## Planning Documents Status

| Document | Location | Status | Last Reviewed | Notes |
|----------|----------|--------|---------------|-------|
| PRD | `planning/docs/PRD.md` | [Complete] / [In Progress] / [Not Started] | [DATE] | |
| Technical Spec | `planning/docs/TECHNICAL_SPEC.md` | [Complete] / [In Progress] / [Not Started] | [DATE] | |
| UI Spec | `planning/docs/UI_SPEC.md` | [Complete] / [In Progress] / [Not Started] | [DATE] | |
| Data Schema | `planning/docs/DATA_SCHEMA.md` | [Complete] / [In Progress] / [Not Started] | [DATE] | |
| Implementation Guide | `planning/docs/IMPLEMENTATION_GUIDE.md` | [Complete] / [In Progress] / [Not Started] | [DATE] | |

---

## Phases from IMPLEMENTATION_GUIDE.md

| Phase | Epic ID | Status | Created | Started | Completed |
|-------|---------|--------|---------|---------|-----------|
| Phase 1: [Name] | [PROJECT]-100 | Not Started | | | |
| Phase 2: [Name] | [PROJECT]-200 | Not Started | | | |
| Phase 3: [Name] | [PROJECT]-300 | Not Started | | | |
| Phase 4: [Name] | [PROJECT]-400 | Not Started | | | |

### Status Legend

| Status | Meaning |
|--------|---------|
| Not Started | Phase not yet planned |
| Planned | Epic created, awaiting approval |
| Approved | Human approved, ready to build |
| In Progress | Stories/tasks being implemented |
| Done | All tasks completed |

---

## Epic Summary

| Epic ID | Title | Stories | Tasks | Points | Status |
|---------|-------|---------|-------|--------|--------|
| [PROJECT]-100 | [Phase 1 Title] | 0 | 0 | 0 | Not Started |
| [PROJECT]-200 | [Phase 2 Title] | 0 | 0 | 0 | Not Started |
| [PROJECT]-300 | [Phase 3 Title] | 0 | 0 | 0 | Not Started |
| [PROJECT]-400 | [Phase 4 Title] | 0 | 0 | 0 | Not Started |

---

## Dependencies

| Epic | Depends On | Blocks |
|------|------------|--------|
| [PROJECT]-100 | - | [PROJECT]-200 |
| [PROJECT]-200 | [PROJECT]-100 | [PROJECT]-300 |
| [PROJECT]-300 | [PROJECT]-200 | [PROJECT]-400 |
| [PROJECT]-400 | [PROJECT]-300 | - |

---

## Next Action

**Next Phase to Plan:** [Phase X: Name]

**Blocking Issues:** [None / List blockers]

**Notes:** [Any context for next session]

---

## Session Log

| Date | Action | By | Notes |
|------|--------|-----|-------|
| [DATE] | Created progress tracker | [agent/human] | Initial setup |
| | | | |

```

---

## Fields Reference

### Project Info Fields

| Field | Description | Example |
|-------|-------------|---------|
| Project Name | Human-readable project name | "MyApp Pro" |
| Project Code | Short code for IDs | "MYAPP" |
| Platform | Target platform and minimum version | "macOS 14.0+" |
| Started | Project start date | 2026-01-30 |
| Last Updated | Last modification date | 2026-01-30 |
| Updated By | Who made the last update | "claude" |

### Phase Status Values

| Status | When to Use |
|--------|-------------|
| Not Started | Phase has no epic yet |
| Planned | Epic created via `/epic` |
| Approved | Human ran `/approve-epic` |
| In Progress | At least one task in_progress |
| Done | All stories and tasks completed |

---

## /epic Command Integration

When `/epic` runs, it:

1. **Reads** this file to find next "Not Started" phase
2. **Creates** epic for that phase
3. **Updates** this file:
   - Changes phase status to "Planned"
   - Adds epic ID to phase row
   - Updates "Created" date
   - Updates "Last Updated" timestamp
   - Adds entry to Session Log

---

## Validation Checklist

Before using this template, verify:

- [ ] All planning documents exist (or marked "Not Started" if not applicable)
- [ ] Phase names match IMPLEMENTATION_GUIDE.md
- [ ] Epic IDs follow PROJECT-X00 convention
- [ ] Dependencies accurately reflect phase order
