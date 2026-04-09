# Platform Awareness — Update Log

Append-only record of platform change evaluations. Each entry documents what was found, what's relevant, and what action was taken.

---

## 2026-03-27 — Initial Baseline

**Claude Code Version:** 2.1.85
**Index Pages:** 72
**Tracked Docs:** 12 key pages cached
**Action:** Initial snapshot created. Feature reference and model reference baselined.

## 2026-03-27 — Check Updates

**Version:** 2.1.85 → 2.1.86 (1 new release)
**New pages:** none
**Key changes:** Token efficiency improvements, VCS directory exclusions, --resume fixes
**Action:** Minor changes detected. No action needed.

## 2026-03-27 — Check Updates (2nd run)

**Version:** 2.1.86 → 2.1.86 (no change)
**New pages:** none
**Action:** No significant changes. Toolkit is current.

## 2026-03-27 — Deep Dive Update

**Version:** 2.1.86 → 2.1.86 (0 new releases)
**Index:** 72 → 72 pages (0 new, 0 removed)
**Docs changed:** 0 of 12 tracked (all matched cached snapshots)
**Changelog entries:** 0 new versions analyzed
**Model changes:** 1M context window GA for Opus 4.6 and Sonnet 4.6 (March 13)

### Findings
- **[model]:** 1M token context window now GA (not beta) for Opus 4.6 and Sonnet 4.6 since March 13 — Moderate
- **[model]:** Media limit increased from 100 to 600 images/PDF pages per request at 1M context — Minor
- **[model]:** Dedicated 1M rate limits removed; standard limits now apply across all context lengths — Minor
- **[api]:** Models API now returns capability fields (`max_input_tokens`, `max_tokens`, `capabilities`) — Minor
- **[api]:** Extended thinking display control (`thinking.display: "omitted"`) added March 16 — Minor
- **[docs]:** All 12 tracked docs unchanged since initial snapshot — Minor
- **[index]:** No new or removed documentation pages — Minor

### Actions Taken
- Updated model-reference.md: Opus 4.6 "200K tokens" → "200K (1M GA)", Sonnet 4.6 "200K (1M beta)" → "200K (1M GA)"
- Updated feature-reference.md: version "2.1.85" → "2.1.86"
- Updated last-checked.json: set `last_deep_dive_date` to "2026-03-27"
- Snapshots confirmed current — no doc content updates needed
- New docs now tracked: none

### Recommended Follow-Up
1. No urgent actions needed. Toolkit is current with Claude Code v2.1.86.
2. Next deep dive recommended in ~30 days or after a significant Anthropic announcement.

## 2026-03-27 — External Sources Research + Skill Enhancement

**Triggered by:** User identified gaps in deep dive — missing X/Twitter sources, community discoveries (/dream), and product boundary confusion (Desktop Cowork vs CLI).

### External Source Findings

**Anthropic Blog / Press (16 major announcements found, Feb 2025 — Mar 2026):**
- Feb 2025: Claude Code research preview (with Sonnet 3.7)
- May 2025: GA + Claude 4 + SDK
- Sep 2025: Hooks, Checkpoints, VS Code 2.0
- Oct 2025: Plugins, Web interface
- Dec 2025: Slack integration
- Jan 2026: Cowork (Desktop agent for non-developers) — **NOT Claude Code CLI**
- Feb 2026: Agent teams + Opus 4.6
- Feb 2026: Remote Control (mobile)
- Mar 2026: Channels, Auto Mode, Computer Use (Cowork — **NOT CLI**)

**X/Twitter discoveries:**
- Voice mode (Mar 3, 2026) — announced by Thariq Shihipar (Anthropic engineer), not via blog
- Code Review built-in (Mar 9, 2026) — announced by Boris Cherny (@bcherny)
- Claude Code is 100% self-written — confirmed by Boris Cherny

**Piebald-AI / Community discoveries:**
- `/dream` (AutoDream) — memory consolidation agent. Infrastructure in binary since v2.1.78, UI toggle in v2.1.81, but `/dream` command broken through v2.1.85. Not in changelog or docs. Server-side feature flag `tengu_onyx_plover`. **Do not adopt.**

**Product boundary clarifications applied:**
- Computer Use = Desktop/Cowork only, not CLI
- Dispatch = Desktop only
- Cowork = Desktop app for non-developers
- Cloud scheduled tasks = claude.ai/code (web), not CLI `/loop`

### Changelog Deep Analysis (v0.2.21 — v2.1.86)

Full changelog analyzed. 60+ major features cataloged across 4 eras:
- **Foundation (0.2.x):** MCP, commands, thinking mode, auto-compact, session resume
- **Automation (1.0.x):** Hooks, custom agents, SDK, PDF, permissions
- **Platform (2.0.x):** Plugins, Skills, Desktop, VS Code, sandbox, plan mode
- **Scale (2.1.x):** Tasks, auto-memory, worktrees, 1M context, channels, agent teams

10 most pivotal versions identified: 0.2.31, 0.2.44, 1.0.0, 1.0.38, 1.0.60, 2.0.0, 2.0.12, 2.0.20, 2.1.16, 2.1.32

~60 built-in commands and 5 bundled skills cataloged.

### Actions Taken

1. **Created `references/external-sources.md`** — Full source catalog with verification protocol and product boundary guide
2. **Updated `references/feature-reference.md`** — Added Section 14 (Undocumented/Community-Discovered: /dream, /security-review, /insights) and Section 15 (Ecosystem Awareness: Computer Use, Dispatch, Cowork, Slack, Cloud Tasks)
3. **Updated `references/last-checked.json`** — Added `tracked_sources` array with 6 external sources and last-checked dates
4. **Updated `SKILL.md`** — Data Sources section now includes official + community sources with link to external-sources.md
5. **Updated `commands/deep-dive-updates.md`** — Added Step 5b (External Source Check) with WebSearch queries, Piebald-AI check, verification protocol, and categorization criteria. Updated Step 7 report template with External Source Findings section.
6. **Updated `update-log.md`** — This entry

### Recommended Follow-Up
1. **Monitor `/dream`** — Watch for it to land in a future release. When working, could help maintain our auto-memory quality.
2. **Test `/security-review`** — May complement our `/security-audit` skill. Run it locally to see what it does.
3. **Test `/insights`** — Undocumented command found in docs but not changelog. Check if it works.
4. **Consider `includeGitInstructions: false`** — Would save ~2-3K system prompt tokens since we have our own git workflow.
