# Watchlist

Items to actively check during the next `/check-updates` or `/deep-dive-updates`. Each item has a clear condition for resolution — when the condition is met, move the finding to `discoveries.md` with updated status and remove from this list.

**Last updated:** 2026-03-28

---

## How to use this file

1. **At the start of every deep dive:** Read this file first. Check each item's resolution condition.
2. **When an item resolves:** Update its entry in `discoveries.md`, then remove it from here.
3. **When you discover something new to monitor:** Add it here with a clear resolution condition.

---

## Active Watch Items

### /dream (AutoDream) — Waiting for working release

**Watching since:** 2026-03-27
**Current status:** Broken — returns "Unknown skill: dream" through v2.1.85
**Resolution condition:** `/dream` command works without error in a released version

**How to check:**
1. Run `claude --version` — note if version > 2.1.86
2. Check Claude Code CHANGELOG.md for any "dream" or "memory consolidation" entry
3. Check GitHub issue #38461 — is it closed?
4. If version bumped: test `/dream` locally

**Why we care:** Auto-memory bloat prevention. When working, this would maintain our memory quality automatically.

**Tracking:** discoveries.md → "/dream (AutoDream)"

---

### /security-review — Needs CLI test

**Watching since:** 2026-03-27
**Current status:** Likely available (~v2.1.70) but untested
**Resolution condition:** Tested locally — confirmed working or confirmed nonexistent

**How to check:**
1. Type `/security-review` in Claude Code
2. If it works: document what it does, how it compares to our `/security-audit`
3. If "Unknown command": mark as not available

**Why we care:** Could complement our custom `/security-audit` skill for lighter-weight quick checks.

**Tracking:** discoveries.md → "/security-review"

---

### /insights — Needs CLI test

**Watching since:** 2026-03-27
**Current status:** Found in docs command reference but no changelog "Added" entry
**Resolution condition:** Tested locally — confirmed working or confirmed nonexistent

**How to check:**
1. Type `/insights` in Claude Code
2. If it works: document what it generates
3. If "Unknown command": mark as not available

**Why we care:** Session analysis could help optimize our workflow patterns.

**Tracking:** discoveries.md → "/insights"

---

### includeGitInstructions: false — Evaluate token savings

**Watching since:** 2026-03-27
**Current status:** Available setting (v2.1.69+), not yet evaluated
**Resolution condition:** Tested locally — measured token savings, confirmed our git workflow still works without built-in instructions

**How to check:**
1. Add `"includeGitInstructions": false` to project `settings.json`
2. Start a session, run `/context` to see token savings
3. Test that `/commit` and git operations still work correctly with our custom git workflow rules
4. If savings significant (~2-3K tokens) and no breakage: adopt permanently

**Why we care:** We have our own git workflow in CLAUDE.md and `.claude/rules/workflow/git-workflow.md`. The built-in git instructions are redundant and cost system prompt tokens.

**Tracking:** feature-reference.md → Section 13 "What We Don't Use (Yet)"

---

### Conditional hooks (if: field) — Evaluate for our hooks

**Watching since:** 2026-03-27
**Current status:** Available since v2.1.85, not yet adopted
**Resolution condition:** Evaluated whether our existing hooks would benefit from `if:` conditionals

**How to check:**
1. Review our 6 hook scripts in `.claude/hooks/`
2. For each PreToolUse hook: could an `if:` field narrow the trigger and avoid spawning the script unnecessarily?
3. Example: `git-guards.sh` matches all `Bash` — could narrow with `"if": "Bash(git *)"`
4. If valuable: update `settings.json` hooks with `if:` fields

**Why we care:** Reduces hook execution overhead. Scripts only spawn when the `if:` condition matches, not on every matching tool event.

**Tracking:** feature-reference.md → Section 13 "What We Don't Use (Yet)"

---

### Agent effort override — Evaluate per-agent effort levels

**Watching since:** 2026-03-27
**Current status:** Available since v2.1.80 (`effort` frontmatter on agents/skills)
**Resolution condition:** Decided whether to set per-agent effort or keep global `effortLevel: "high"`

**How to check:**
1. Review our 17 agent definitions — which ones would benefit from different effort levels?
2. Haiku agents (micro tasks) → `effort: low` could save tokens
3. Opus agents (planning, discovery) → `effort: max` could improve quality
4. Test a few agents with effort overrides and compare output quality

**Why we care:** Global `effortLevel: "high"` may be overkill for simple agents and insufficient for complex ones. Per-agent tuning could optimize both cost and quality.

**Tracking:** feature-reference.md → Section 13 "What We Don't Use (Yet)"

---

## Resolved Items

_Move items here when their resolution condition is met. Include the date resolved and outcome._

_(none yet)_
