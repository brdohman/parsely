---
name: story-context
description: "Shared context file pattern for cross-task consistency within a story. Agents read before starting and append after completing each task."
user-invocable: false
---

# Story Context File

## Problem

Each task agent starts fresh with no knowledge of what prior tasks in the same story produced. This causes naming inconsistencies, duplicated types, and architectural drift within a single story.

## Solution

A lightweight context file at `planning/notes/[epic-name]/story-[story-id]-context.md` that task agents read before starting and append to after completing.

## When to Use

- **Read:** At task start, after claiming (Protocol 2), before writing code. If the file exists, read it (~1-2K tokens).
- **Append:** At task completion, after committing, before marking complete. Add what you created/changed.
- **Skip:** If this is the first task in the story (file won't exist yet). Create it instead.

## File Format

```markdown
# Story Context: [story-id]

## Types Created
- `AccountListViewModel` (@Observable, in AccountListViewModel.swift)
- `AccountService` (actor, protocol AccountServiceProtocol)

## Naming Patterns
- ViewModels: `[Feature]ViewModel`
- Services: `[Domain]Service` with `[Domain]ServiceProtocol`
- Views: `[Feature]View` or `[Feature]Screen` (Screen for top-level navigation destinations)

## Architecture Decisions
- Using NavigationSplitView with 2-column layout (sidebar + detail)
- Sidebar selection state lives in SidebarViewModel, not individual row views
- All Core Data access goes through service actors, never direct from ViewModels

## Shared Dependencies
- `AppError` enum (in Models/AppError.swift) - use for all error handling
- `PersistenceController.shared` - singleton Core Data stack
```

## Rules

1. **Keep it short.** Target under 80 lines. This file costs ~1-2K tokens to read. Don't include code snippets or full type definitions.
2. **Facts only.** Record what exists and what patterns were established. No TODOs, no opinions.
3. **Append, don't rewrite.** Each task adds its section. Don't reorganize previous entries.
4. **The code reviewer checks consistency against this file.** If the code contradicts the context file, it's a review finding.
