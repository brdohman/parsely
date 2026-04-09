# Discoveries Reference

Persistent record of features, announcements, and insights found through external source monitoring. Organized by topic so findings are easy to locate regardless of when they were discovered.

**Last updated:** 2026-03-28

---

## How to use this file

- **During deep dives:** After finding something new, add or update the relevant entry here before writing to the update log
- **When investigating a feature:** Check here first — we may already have source URLs and context
- **When the watchlist changes:** Cross-reference with `watchlist.md` to see if a watched item should move to "confirmed" here

### Entry format

Each entry includes: what it is, verification status, source URLs, date found, and notes. Entries are grouped by category and sorted by relevance within each group.

---

## Undocumented / Partially-Shipped Features

### /dream (AutoDream) — Memory Consolidation

**Status:** Broken / Partial (as of v2.1.86)
**Discovered:** 2026-03-27
**Watchlist:** Yes — monitoring for working release

A background sub-agent that consolidates auto-memory files in four phases: orient (scan existing memory), gather signal (check logs and transcripts), consolidate (merge into topic files, convert relative dates, delete stale facts), and prune (keep MEMORY.md under 200 lines).

**Timeline:**
- v2.1.78 (Mar 18, 2026) — Agent system prompt first appeared in binary
- v2.1.81 — UI toggle visible in `/memory`, `autoDreamEnabled` setting exists
- v2.1.85 (Mar 26) — Still returning "Unknown skill: dream" (GitHub #38461)
- v2.1.86 (Mar 27) — Unconfirmed whether PR #39299 fix landed

**Triggering conditions:** Auto mode requires 24+ hours AND 5+ sessions since last consolidation. Server-side feature flag: `tengu_onyx_plover`.

**Sources:**
- System prompt: https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/agent-prompt-dream-memory-consolidation.md
- GitHub Issue (broken): https://github.com/anthropics/claude-code/issues/38461
- GitHub Issue (gaps): https://github.com/anthropics/claude-code/issues/38493
- Community PR to fix: https://github.com/anthropics/claude-code/pull/39299
- Ray Amjad YouTube explainer: https://youtu.be/OnQ4BGN8B-s
- DEV.to deep dive: https://dev.to/akari_iku/does-claude-code-need-sleep-inside-the-unreleased-auto-dream-feature-2n7m
- ClaudeFast guide: https://claudefa.st/blog/guide/mechanics/auto-dream
- Claude's Corner Substack: https://claudescorner.substack.com/p/a-hidden-dream-command-and-the-tools
- Sakeeb Rahman Threads discovery: https://www.threads.com/@sakeeb.rahman/post/DWSKjMoESz2/

**Relevance to us:** High when working — our auto-memory will accumulate bloat over time. AutoDream would solve this automatically. Until it ships, manual memory curation via `/memory` is the workaround.

---

### /security-review — Built-in Security Scan

**Status:** Likely available (~v2.1.70), needs CLI test
**Discovered:** 2026-03-27
**Watchlist:** Yes — needs CLI test

Built-in security scan of pending branch changes. Found via changelog fix references (implying it exists) but no explicit "Added" entry.

**Sources:**
- Changelog references fixes to `/security-review` around v2.1.70

**Relevance to us:** Medium — could complement our custom `/security-audit` skill. Our skill spawns 3 parallel reviewers + consolidator; the built-in might be lighter-weight for quick checks.

---

### /insights — Session Analysis Report

**Status:** Unknown — found in docs command reference but no changelog entry
**Discovered:** 2026-03-27
**Watchlist:** Yes — needs CLI test

Generates a report analyzing Claude Code sessions. No further details found.

**Sources:**
- Listed in commands docs page but absent from changelog

**Relevance to us:** Low-medium — could be useful for understanding session patterns and optimizing our workflow.

---

## Major Feature Announcements

### Voice Mode (Push-to-Talk)

**Status:** Confirmed CLI feature (v2.1.69+)
**Discovered:** 2026-03-27

Push-to-talk voice dictation via spacebar. `/voice` command to toggle. Rolling out gradually — initially 5% of users.

**Sources:**
- TechCrunch (Mar 3, 2026): https://techcrunch.com/2026/03/03/claude-code-rolls-out-a-voice-mode-capability/
- 9to5Mac: https://9to5mac.com/2026/03/03/anthropic-adding-voice-mode-to-claude-code-in-gradual-rollout/
- Announced by Thariq Shihipar (Anthropic engineer) on X — not via blog

**Relevance to us:** Low — preference-dependent. Already enabled in user settings (`voiceEnabled: true`).

---

### Code Review (Built-in Multi-Agent)

**Status:** Confirmed CLI feature
**Discovered:** 2026-03-27

Team of agents that deep-reviews every PR. Built into Claude Code.

**Sources:**
- Boris Cherny (@bcherny) on X (~Mar 9, 2026): https://x.com/bcherny/status/2031089411820228645
- Docs page: https://code.claude.com/docs/en/code-review

**Relevance to us:** Medium — we already have our own `/code-review` skill that spawns staff-engineer + CodeRabbit in parallel. The built-in version might eventually supersede our custom implementation.

---

### Auto Mode (Permission Classifier)

**Status:** Confirmed CLI feature (research preview, v2.1.83+)
**Discovered:** 2026-03-27

AI safety classifier that auto-approves safe tool calls and blocks dangerous ones (mass file deletions, data exfiltration). Middle ground between manual approval and `bypassPermissions`.

**Sources:**
- Anthropic blog (Mar 24, 2026): https://claude.com/blog/auto-mode
- TechCrunch: https://techcrunch.com/2026/03/24/anthropic-hands-claude-code-more-control-but-keeps-it-on-a-leash/
- Docs: https://code.claude.com/docs/en/permission-modes

**Relevance to us:** Medium — could replace `bypassPermissions` on our agents with a safer approach. Currently listed in "What We Don't Use (Yet)" in feature-reference.md.

---

### Channels (Telegram, Discord, iMessage)

**Status:** Confirmed CLI feature (research preview, v2.1.80+)
**Discovered:** 2026-03-27

MCP-based message injection. Control Claude Code sessions from messaging apps. CI/build results can push into sessions.

**Sources:**
- VentureBeat (Mar 20, 2026): https://venturebeat.com/orchestration/anthropic-just-shipped-an-openclaw-killer-called-claude-code-channels
- Docs: https://code.claude.com/docs/en/channels

**Relevance to us:** Low-medium — personal use app, no team collaboration needed. Could be useful for monitoring long builds from phone.

---

### Agent Teams

**Status:** Confirmed CLI feature (experimental, v2.1.32+)
**Discovered:** 2026-03-27

Multiple Claude Code sessions coordinating as a team. Shared task list, peer-to-peer messaging, independent context windows.

**Sources:**
- TechCrunch (Feb 5, 2026): https://techcrunch.com/2026/02/05/anthropic-releases-opus-4-6-with-new-agent-teams/
- Docs: https://code.claude.com/docs/en/agent-teams

**Relevance to us:** Already enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). We have `/build-story-team` and `/build-epic-team` commands.

---

### Remote Control (Mobile Access)

**Status:** Confirmed CLI feature (v2.1.51+)
**Discovered:** 2026-03-27

Connect claude.ai or mobile app to a running local session via encrypted bridge. Monitor and approve from phone.

**Sources:**
- WinBuzzer (Feb 25, 2026): https://winbuzzer.com/2026/02/28/anthropic-remote-control-claude-code-mobile-access-xcxwbn/
- Docs: https://code.claude.com/docs/en/remote-control

**Relevance to us:** Low — personal use, local terminal is primary interface. Listed in "What We Don't Use (Yet)".

---

## Ecosystem Features (NOT Claude Code CLI)

### Computer Use (Cowork / Desktop)

**Status:** Desktop/Cowork only — NOT Claude Code CLI
**Discovered:** 2026-03-27

Keyboard/mouse control of macOS desktop. Requires Desktop app, Pro/Max plan, accessibility + screen recording permissions.

**Sources:**
- Ruben Hassid guide: https://ruben.substack.com/p/claude-computer
- Engadget (Mar 24, 2026): https://www.engadget.com/ai/claude-code-and-cowork-can-now-use-your-computer-210000126.html

**Relevance to us:** None directly — different product. Awareness only.

---

### Cowork (Desktop Agent for Non-Developers)

**Status:** Desktop only — NOT Claude Code CLI
**Discovered:** 2026-03-27

Agentic capabilities for non-developers. Produces documents, organizes files, synthesizes research without terminal.

**Sources:**
- TechCrunch (Jan 12, 2026): https://techcrunch.com/2026/01/12/anthropics-new-cowork-tool-offers-claude-code-without-the-code/

**Relevance to us:** None — different product.

---

### Cloud Scheduled Tasks

**Status:** claude.ai/code (Web) — NOT local CLI /loop
**Discovered:** 2026-03-27

Cron-scheduled prompts running on Anthropic cloud infrastructure. No local machine required.

**Sources:**
- PlainEnglish: https://plainenglish.io/artificial-intelligence/claude-code-s-scheduled-cloud-tasks-change-everything
- Docs: https://code.claude.com/docs/en/web-scheduled-tasks

**Relevance to us:** Low — we're local-only. The CLI `/loop` and `/schedule` commands serve our needs.

---

## Community Resources

### Piebald-AI System Prompt Archive

**Type:** Ongoing reference
**Discovered:** 2026-03-27

Community-maintained archive of reverse-engineered Claude Code system prompts. Updated when new versions ship. Valuable for catching undocumented features (like /dream) before official announcement.

**URL:** https://github.com/Piebald-AI/claude-code-system-prompts
**Changelog:** https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/CHANGELOG.md

---

### Releasebot.io — Claude Code Tracker

**Type:** Ongoing reference
**Discovered:** 2026-03-27

Aggregated Claude Code release tracking. Supplements the official changelog.

**URL:** https://releasebot.io/updates/anthropic/claude-code

---

### Claude Code Self-Written Confirmation

**Type:** Factoid
**Discovered:** 2026-03-27

Boris Cherny confirmed Claude Code is 100% self-written (by Claude). Interesting context for understanding the tool's development model.

**Source:** Boris Cherny (@bcherny) on X, ~January 2026

---

### Charly Wargnier — 2026 Feature Aggregation

**Type:** Community summary
**Discovered:** 2026-03-27

Comprehensive aggregation of all 2026 Claude Code features posted on X.

**Source:** https://x.com/DataChaz/status/2033096562805485969
