# Module Specification Template

Use this template when creating a new module specification in `docs/modules/`.

Filename: `docs/modules/[module-name].md` (lowercase, hyphenated)

Max 150 lines. If longer, the module may need to be split.

---

```markdown
# Module: [Name]

**Purpose:** [One sentence — what this module is responsible for]
**Boundary:** [What this module owns exclusively — no other module should do this]
**Last verified:** [YYYY-MM-DD — date the documentation agent last confirmed this matches code]

## Public Interface

[List functions/methods/properties that other modules may call. Use the actual Swift signatures.]

```swift
// Example:
func authenticate(credentials: Credentials) async throws -> Session
func validateSession(token: String) async -> Bool
func refresh(token: RefreshToken) async throws -> Session
```

## Dependencies

[What this module depends on — other modules, frameworks, services]

- **[Module/Framework]:** [What it's used for]

## Invariants

[Things that must ALWAYS be true. Each should be verifiable via grep or code inspection.]

- [Invariant 1 — include what grep pattern would detect a violation]
- [Invariant 2]
- [Invariant 3]

## State Management

[How this module manages state — actor isolation, singletons, value types, etc. Include concurrency model.]

## Error Handling

[How errors propagate from this module — error types thrown, recovery expectations for callers]

## Known Gotchas

[Non-obvious behavior, edge cases, common mistakes agents should avoid]

- [Gotcha 1]
- [Gotcha 2]

## Related ADRs

[Links to architectural decisions that shaped this module]

- ADR-NNN: [Title — one line summary of relevance]
```

---

## Guidelines

- **Purpose** is one sentence. If you need two, the module does too much.
- **Boundary** defines ownership. Other agents check this before touching related code.
- **Public Interface** uses actual Swift signatures, not prose descriptions.
- **Invariants** are the most valuable section. Each must be machine-verifiable.
- **Known Gotchas** prevents agents from repeating past mistakes.
- **Related ADRs** enables progressive disclosure — agents load the ADR only when they need decision context.
- Omit sections that don't apply (e.g., skip "State Management" for stateless utility modules).
