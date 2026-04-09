---
description: Requires agents to distinguish verified facts from training-data assumptions
---

# Verify Technical Claims

## When This Applies

When any agent writes a technical recommendation to a planning document, spec, or implementation comment — including framework choices, API patterns, library versions, and architectural decisions.

## The Rule

⛔ **Do not present training-data assumptions as verified facts.**

When you recommend a specific API, framework, library version, or architectural pattern, ask yourself: "Am I confident this is current, or am I relying on training data?"

- **If you just searched the web or read a current document:** Mark as verified.
- **If you're working from training knowledge:** Mark as `[UNVERIFIED]`.

## How to Mark Claims

In planning documents and specs:

```markdown
Use CloudKit for real-time sync between devices. [VERIFIED: developer.apple.com/cloudkit, accessed 2026-03-31]

SwiftData supports automatic CloudKit sync via NSPersistentCloudKitContainer. [UNVERIFIED — from training data, needs verification]
```

In task comments and implementation:

```
IMPLEMENTATION NOTE: Used NavigationStack with path-based navigation.
This pattern is current per Apple's SwiftUI docs. [VERIFIED]
```

## What Happens to UNVERIFIED Claims

The coordinator routes `[UNVERIFIED]` claims to the Research Agent for verification. This can happen:
- During `/discover` Phase 4.5 (automatic research validation)
- During code review (staff engineer flags unverified patterns)
- On-demand via `/research`

## When to Verify vs When Training Data Is Fine

| Situation | Action |
|---|---|
| Recommending a specific API or framework | **Verify** — APIs change, deprecate, evolve |
| Suggesting a library version | **Verify** — versions change frequently |
| Describing how an API works (parameters, behavior) | **Verify** — signatures and behavior change |
| General Swift language patterns (optionals, closures, enums) | Training data is fine — language fundamentals are stable |
| MVVM architecture, SOLID principles | Training data is fine — patterns don't change |
| Recommending a specific iOS/macOS version feature | **Verify** — features move between versions |
| Suggesting a third-party library | **Verify** — libraries get abandoned, forked, or replaced |

## For Developer Agents

When implementing code and you hit a compile error that suggests an API has changed:

1. **Do not guess.** Don't try 5 variations hoping one compiles.
2. **Search for the current API.** Use WebSearch if available, or report to coordinator for research.
3. **If you don't have WebSearch:** Report the error with `[NEEDS_RESEARCH: API may have changed — "[specific API]" not found/deprecated]` in your implementation comment. The coordinator will spawn a research agent.

## Never

- Present an API signature from training data as if you just looked it up
- Recommend a library version without checking if it's current
- Describe framework behavior with confidence when you haven't verified it recently
- Ignore compile errors by guessing at alternative APIs — research the correct one
