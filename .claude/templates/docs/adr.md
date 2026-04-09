# ADR Template

Use this template when creating a new Architecture Decision Record in `docs/architecture/decisions/`.

Filename: `docs/architecture/decisions/adr-NNN-[kebab-case-title].md`

Max 60 lines. If longer, break the decision into smaller ADRs.

Number sequentially. Check `docs/architecture/decisions/index.md` for the next available number.

---

```markdown
# ADR-NNN: [Present tense verb phrase]

**Status:** proposed | accepted | deprecated | superseded by ADR-XXX
**Date:** YYYY-MM-DD
**Story:** [story-id that prompted this decision]
**Deciders:** [agent or human who made the call]

## Context

[What forces are at play? What problem are we solving? Keep to 3-5 sentences.]

## Decision

[What did we decide? Be specific — include module names, patterns, constraints. This is the part agents reference most.]

## Consequences

**Positive:** [What gets better — 1-3 bullets]
**Negative:** [What trade-offs we accept — 1-3 bullets]

## Alternatives Considered

[What else we looked at and why we rejected it — 1-2 sentences per alternative]
```

---

## Guidelines

- **Title** uses present tense imperative: "Use actor isolation for AuthManager", not "We decided to use actors"
- **Status** transitions: proposed → accepted → (deprecated | superseded). Never delete — only supersede.
- **Context** explains WHY, not WHAT. Agents need the "why" to avoid undoing the decision.
- **Decision** is concrete and actionable. Include module names and specific constraints.
- **Alternatives** prevents agents from revisiting rejected approaches.
- After creating an ADR, update `docs/architecture/decisions/index.md`.

## Index Entry Format

Add one row to the index table:

```markdown
| NNN | [Title] | accepted | YYYY-MM-DD | [Module(s) affected] |
```

## Superseding an ADR

When a decision is replaced:
1. Create the new ADR with full content
2. Compress the old ADR to 5 lines:
   ```markdown
   # ADR-NNN: [Original title]

   **Status:** Superseded by ADR-XXX
   **Date:** YYYY-MM-DD
   **Archived:** YYYY-MM-DD
   ```
3. Update the index: change status to "superseded by ADR-XXX"
