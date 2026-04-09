# Architecture Overview Template

Use this template when creating `docs/architecture/overview.md` for the first time. Update incrementally as modules are added.

Max 200 lines. This is loaded at epic start for context.

---

```markdown
# Architecture Overview

**App:** [App name]
**Last updated:** YYYY-MM-DD

## Module Map

[List every significant module with its purpose and boundary. One line each.]

| Module | Purpose | Boundary |
|---|---|---|
| [Name] | [One sentence] | [What it owns exclusively] |

## Data Flow

[How data moves through the app. Describe the pipeline, not the files.]

```
[Source] → [Processing layer] → [Storage layer] → [Presentation layer]
```

[Brief prose explanation of the flow, focusing on boundaries between layers.]

## Key Boundaries

[The most important architectural rules. Agents check these before making cross-module changes.]

- **Views** only depend on ViewModels (never Services or Models directly)
- **ViewModels** access Services via protocols (never concrete implementations)
- **Services** never import Views or ViewModels
- [App-specific boundaries]

## Concurrency Model

[How the app handles concurrency — actor isolation, MainActor usage, background processing patterns.]

## Persistence Strategy

[Core Data, SQLite, UserDefaults — what's used where and why.]

## Active ADRs

[List ADRs that affect the overall architecture. Agents load individual ADRs on demand.]

| ADR | Title | Affects |
|---|---|---|
| NNN | [Title] | [Which modules/boundaries] |
```

---

## Guidelines

- **Module Map** is the most referenced section. Keep it as a scannable table.
- **Key Boundaries** are rules that every agent should know. These prevent cross-module violations.
- **Active ADRs** only lists architecture-level decisions. Module-specific ADRs belong in module specs.
- Update this document in capture mode whenever a new module is added.
- Do NOT list every file or class — only significant modules that have their own specs.
