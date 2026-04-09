---
name: platform-awareness
description: Track Claude Code platform updates, model changes, and new features. Manages cached documentation snapshots and produces change reports.
disable-model-invocation: true
user-invocable: false
---

# Platform Awareness Skill

## Purpose

Self-contained system for tracking Claude Code platform changes with zero external dependencies. Fetches public documentation, diffs against cached snapshots, and reports what changed — so the toolkit can stay current with new models, features, and deprecations.

## Commands

| Command | When to Use | Time |
|---------|-------------|------|
| `/check-updates` | Quick scan for new releases or model changes | ~30 sec |
| `/deep-dive-updates` | Full analysis of all tracked sources | Monthly or after significant releases |
| `/evolve` | Self-audit: compare platform capabilities against toolkit usage | When planning improvements |

## Key Files

| File | Purpose |
|------|---------|
| `references/feature-reference.md` | What we know Claude Code can do |
| `references/model-reference.md` | Known models, context windows, deprecations |
| `references/last-checked.json` | Timestamps, tracked docs, tracked sources for change detection |
| `references/external-sources.md` | Where to look beyond official docs (blog, X, Piebald-AI, etc.) |
| `references/discoveries.md` | What we've found — organized by topic with source URLs |
| `references/watchlist.md` | Items to actively check next deep dive |
| `snapshots/` | Cached doc pages used for diffing |
| `update-log.md` | Audit trail of detected changes and user approvals |

## Data Sources

### Official (authoritative)
- `https://code.claude.com/docs/llms.txt` — canonical index of Claude Code docs
- `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` — release changelog
- `https://platform.claude.com/docs/en/release-notes/overview` — model/API release notes
- `https://www.anthropic.com/news` — Anthropic blog (major launches)

### Community (verify before adopting)
- `https://x.com/bcherny` — Claude Code creator, previews + confirmations
- `https://x.com/AnthropicAI` — Official Anthropic X account
- `https://github.com/Piebald-AI/claude-code-system-prompts` — Reverse-engineered system prompts (catches undocumented features)
- `https://releasebot.io/updates/anthropic/claude-code` — Release aggregator

See `references/external-sources.md` for full source catalog with verification protocol.

## How It Works

1. **Fetch** — Pull current versions of tracked sources
2. **Diff** — Compare against cached snapshots in `snapshots/`
3. **Categorize** — Tag changes: new model, deprecation, feature, breaking change
4. **Report** — Present a human-readable summary of what changed
5. **Approve** — User reviews and confirms the report is accurate
6. **Update** — Snapshots and reference files updated, entry added to `update-log.md`

No changes are written until the user approves. The skill never auto-modifies toolkit files.

## When to Run

- `/check-updates` — Anytime before starting a new epic or when model selection questions arise
- `/deep-dive-updates` — Monthly cadence, or immediately after an Anthropic release announcement
- `/evolve` — When planning toolkit improvements or after a major platform shift
