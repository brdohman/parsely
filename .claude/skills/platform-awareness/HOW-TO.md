# Platform Awareness — How To Use

## Quick Start

Platform Awareness tracks Claude Code platform changes so this toolkit stays current. It fetches documentation from `code.claude.com` and the Claude Code GitHub repo, diffs the content against cached snapshots, and reports what changed — new hook events, new frontmatter fields, model launches, deprecations, and anything else that might require a toolkit update. Run `/check-updates` periodically to catch changes early; use `/deep-dive-updates` when you need the full picture; use `/evolve` when planning improvements.

---

## Commands

### /check-updates — Quick Scan (~30 seconds)

**When to run:** Before starting a new epic, when model selection questions come up, or any time you want to confirm the toolkit is current.

**What it does:** Checks the installed Claude Code version against the last-known version, fetches the live documentation index (`llms.txt`), counts new/removed pages, and fetches recent GitHub release entries if the version has changed.

**What it produces:** A short report showing version delta, new/removed doc pages, and a recommendation: no action needed, minor changes, or "run `/deep-dive-updates`." Updates `last-checked.json` and `snapshots/llms-index.txt`. Appends a one-line entry to `update-log.md`.

**Example:** Just type `/check-updates` — no arguments needed.

---

### /deep-dive-updates — Full Analysis (~5 minutes)

**When to run:** Monthly, or immediately after an Anthropic release announcement. Also run when `/check-updates` says "significant changes found."

**What it does:** Fetches all 12 tracked documentation pages and diffs each against its cached snapshot. Also fetches the full changelog, model release notes, and any new doc pages detected in the index. Categorizes every finding as Minor, Moderate, or Major. Produces a structured impact report with specific recommended actions.

**What it produces:** A full Impact Report with sections for new pages, per-doc changes, changelog highlights (grouped by area: Hooks, Agents, Skills, MCP, Settings, etc.), model/API changes, and a priority-ordered action list. Refreshes all snapshots and updates `last-checked.json`. Updates `feature-reference.md` and `model-reference.md` if Major changes are found. Appends a detailed entry to `update-log.md`.

**Example:** `/deep-dive-updates`

**Tip:** Run `/check-updates` first. If it says "significant changes found" or the version has bumped multiple releases, then run this.

---

### /evolve — Self-Audit (~3 minutes)

**When to run:** After `/deep-dive-updates`, when planning a toolkit improvement epic, or any time you want to understand how much of the Claude Code platform the toolkit actually uses.

**What it does:** Reads `feature-reference.md` to map everything the platform supports, then audits the entire `.claude/` directory — counting agents, skills, commands, hooks, MCP servers, plugins, rules, scripts, and templates. Performs a gap analysis across four categories: (A) used and current, (B) used but outdated, (C) available but not yet adopted, (D) deprecated patterns. Also audits model selection and security posture.

**What it produces:** A Toolkit Evolution Report with a full inventory table, platform coverage percentages, findings organized as Quick Wins / Enhancements / Refactors, a model selection table, and a security assessment. Appends a summary entry to `update-log.md`. **Read-only** — does not modify any toolkit files.

**Example:** `/evolve`

**Tip:** Run after `/deep-dive-updates` so `feature-reference.md` is current before the gap analysis runs. The findings feed directly into task creation for improvement epics.

---

## Recommended Workflow

1. Run `/check-updates` periodically (weekly or after updating Claude Code)
2. If changes detected → run `/deep-dive-updates` for full analysis
3. After deep dive → run `/evolve` to find improvement opportunities
4. Review recommendations → approve or defer each one
5. Implement approved changes (use `/feature` or `/epic` as appropriate)

---

## File Layout

```
.claude/skills/platform-awareness/
├── SKILL.md                         # Skill manifest (metadata, data sources overview)
├── HOW-TO.md                        # This file
├── update-log.md                    # Append-only audit trail of all checks and findings
├── references/
│   ├── feature-reference.md         # Comprehensive map of Claude Code capabilities
│   ├── model-reference.md           # Known models, context windows, deprecation status
│   └── last-checked.json            # Timestamps, version, page count, tracked doc list
└── snapshots/
    ├── llms-index.txt               # Cached documentation index (updated by /check-updates)
    ├── changelog.md                 # Cached Claude Code changelog (updated by /deep-dive-updates)
    └── docs/
        ├── hooks.md                 # Snapshot of hooks documentation
        ├── skills.md                # Snapshot of skills documentation
        ├── sub-agents.md            # Snapshot of sub-agents documentation
        ├── mcp.md                   # Snapshot of MCP documentation
        ├── settings.md              # Snapshot of settings documentation
        ├── plugins.md               # Snapshot of plugins documentation
        ├── plugins-reference.md     # Snapshot of plugins reference documentation
        ├── memory.md                # Snapshot of memory documentation
        ├── permissions.md           # Snapshot of permissions documentation
        ├── agent-teams.md           # Snapshot of agent teams documentation
        ├── scheduled-tasks.md       # Snapshot of scheduled tasks documentation
        └── features-overview.md     # Snapshot of features overview documentation
```

---

## Maintenance

- Snapshots are updated automatically: `/check-updates` updates `llms-index.txt` only; `/deep-dive-updates` updates all snapshots including per-doc files.
- `feature-reference.md` is updated by `/deep-dive-updates` only when **Major** changes are found.
- `update-log.md` is append-only — never delete entries. It is the audit trail for all platform checks.
- To re-baseline (force full re-check as if starting fresh): delete `snapshots/` contents and set `last_deep_dive_date: null` in `last-checked.json`, then run `/deep-dive-updates`.
- The `tracked_docs` array in `last-checked.json` controls which pages are fetched and diffed by `/deep-dive-updates`. New high/medium relevance pages discovered during a run are automatically added.

---

## Data Sources

| Source | URL | Used By |
|--------|-----|---------|
| Documentation index | `https://code.claude.com/docs/llms.txt` | `/check-updates`, `/deep-dive-updates` |
| Claude Code changelog | `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` | `/deep-dive-updates` |
| GitHub release metadata | `https://api.github.com/repos/anthropics/claude-code/releases?per_page=10` | `/check-updates` (version delta), `/deep-dive-updates` |
| Platform release notes | `https://platform.claude.com/docs/en/release-notes/overview` | `/deep-dive-updates` (model/API changes) |
| Individual doc pages | `https://code.claude.com/docs/en/{page}` | `/deep-dive-updates` (per tracked doc) |

---

## Troubleshooting

- **"WebFetch failed":** Check internet connection. All sources are public URLs — no authentication required.
- **"No changes detected" but you know there were updates:** Check `last-checked.json` — the `last_check_date` may already be today. Delete `snapshots/llms-index.txt` to force a fresh index comparison, or set `changelog_last_version` to an older version to re-scan changelog entries.
- **Snapshot too large / WebFetch truncated:** Some doc pages (especially `hooks.md`) are 90KB+. WebFetch may truncate long pages. This is expected — structural changes (new headings, new table rows, new configuration options) are still detected even from truncated content.
- **`feature-reference.md` appears outdated:** If the version in the file header doesn't match the current installed version, run `/deep-dive-updates` to refresh it before running `/evolve`.
- **`/evolve` reports incorrect counts:** The audit uses Bash `ls` and `find` to count files. If counts look wrong, verify the `.claude/` directory structure hasn't been reorganized since the skill was written.
