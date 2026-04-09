# Changelog Entry Template

Use this template when appending to `docs/CHANGELOG.md` in completion mode.

Max 20 lines per entry. Prepend new entries (most recent first).

---

```markdown
## [Story ID] — [Story Title]

**Date:** YYYY-MM-DD
**Epic:** [Epic title]

### Changed
- [What changed — module or capability affected, not file paths]

### Added
- [New modules, capabilities, or interfaces introduced]

### Decisions
- ADR-NNN: [Title — if any ADRs were created during this story]

### Notes
- [Edge cases discovered, known limitations, or tech debt introduced]
```

---

## Guidelines

- Omit sections with no content (e.g., skip "Added" if nothing new was introduced).
- Use module/capability names, not file paths.
- "Changed" describes behavior changes, not code changes.
- "Notes" captures anything future agents should know that doesn't belong in a module spec.
- Keep each bullet to one line.

## CHANGELOG.md Header

If creating `docs/CHANGELOG.md` for the first time:

```markdown
# Changelog

Changes by story, most recent first. For architectural decisions, see `architecture/decisions/index.md`.

---
```
