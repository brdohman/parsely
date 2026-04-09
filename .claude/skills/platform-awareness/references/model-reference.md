# Model Reference

## Current Models

| Model | ID | Context Window | Notes |
|-------|----|----------------|-------|
| Claude Opus 4.6 | claude-opus-4-6 | 200K (1M GA) | Most capable. Used for: complex tasks, planning, discovery, architecture |
| Claude Sonnet 4.6 | claude-sonnet-4-6 | 200K (1M GA) | Fast + capable. Used for: standard implementation, review, most agent work |
| Claude Haiku 4.5 | claude-haiku-4-5-20251001 | 200K tokens | Fastest, cheapest. Used for: micro tasks, simple single-file changes |

## Deprecated / Retiring Models

| Model | Status | Retirement Date |
|-------|--------|-----------------|
| Claude Haiku 3 | Deprecated | April 19, 2026 |
| Claude Opus 3 | Retired | January 5, 2026 |
| Claude Sonnet 3.7 | Retired | February 19, 2026 |
| Claude Haiku 3.5 | Retired | February 19, 2026 |

## Our Model Selection Rules (from CLAUDE.md)

- **Haiku** — Micro tasks (`task_tier: "micro"`), single-file changes, simple additions
- **Sonnet** — Standard tasks (default), most implementation and review work
- **Opus** — Tasks with `complexity: "high"`, deep architectural decisions, planning/discovery

## Model-Specific Behaviors We Depend On

- `@Observable` macro support in code generation (all current models)
- `async/await` pattern preference (all current models)
- SwiftUI macOS 26 Tahoe awareness (verify on model updates)
- Context window management: 200K total with ~41K overhead = ~156K effective usable

## Key Dates

- Last updated: 2026-03-27
- Source: https://platform.claude.com/docs/en/release-notes/overview
