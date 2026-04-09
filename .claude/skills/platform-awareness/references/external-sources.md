# External Sources for Platform Monitoring

**Last updated:** 2026-03-27

Sources beyond the official Claude Code documentation at code.claude.com/docs. Used during deep dives to catch announcements, community discoveries, and ecosystem changes that don't appear in the docs or changelog.

---

## Verification Protocol

Before recording any externally-discovered feature as a Claude Code CLI capability:

1. **Changelog check** — Does it appear in the Claude Code CHANGELOG.md?
2. **Docs check** — Is it on code.claude.com/docs?
3. **CLI test** — Can we run the command / check the setting locally in our version?
4. **GitHub issues** — Are people using it in Claude Code CLI specifically?

Features that only exist in Desktop/Cowork (Computer Use, Dispatch) or claude.ai (web chat) go in the "Ecosystem Awareness" section of the feature reference — informational only, not actionable for our toolkit.

### Product Boundary Guide

| Product | Scope for us? | How to tell |
|---------|--------------|-------------|
| **Claude Code CLI** | Primary | `claude` terminal command, changelog at github.com/anthropics/claude-code |
| **Claude Code VS Code / JetBrains** | Partially — same engine | Same changelog, extensions wrap the CLI |
| **Claude Code Web** | Partially — same features, different runtime | Runs on Anthropic cloud, some features web-only (e.g., cloud scheduled tasks) |
| **Claude Desktop (Cowork)** | No — different product | Separate app, Computer Use, Dispatch, different feature set |
| **Claude.ai** | No | Chat interface, not agentic coding |
| **Claude API** | Only when it affects Claude Code | Model changes, context window, pricing |

---

## Official Sources

### 1. Claude Code Changelog (GitHub)
- **URL:** https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
- **What it covers:** Every version release with features, fixes, and changes
- **Check frequency:** Every deep dive + after version bumps
- **Signal:** New version entries since `changelog_last_version` in last-checked.json
- **Reliability:** Authoritative — this IS the source of truth for what shipped

### 2. Claude Code Documentation Index
- **URL:** https://code.claude.com/docs/llms.txt
- **What it covers:** All official documentation pages with descriptions
- **Check frequency:** Every deep dive
- **Signal:** New pages added, pages removed, description changes
- **Reliability:** Authoritative

### 3. Anthropic API Release Notes
- **URL:** https://platform.claude.com/docs/en/release-notes/overview
- **What it covers:** Model launches, deprecations, API features, context window changes, pricing
- **Check frequency:** Every deep dive
- **Signal:** New model versions, retired models, new API capabilities
- **Reliability:** Authoritative

### 4. Anthropic Blog
- **URL:** https://www.anthropic.com/news (or anthropic.com/blog)
- **What it covers:** Major feature launches, product announcements, research
- **Check frequency:** Every deep dive (WebSearch for "site:anthropic.com claude code")
- **Signal:** Blog posts about Claude Code features — these are the "big" announcements
- **Reliability:** Authoritative but covers only major launches, not incremental features

---

## Social / Community Sources

### 5. @AnthropicAI on X (Twitter)
- **URL:** https://x.com/AnthropicAI
- **What it covers:** Official announcements, often same day as blog posts
- **Check frequency:** Every deep dive (WebSearch for "@AnthropicAI claude code")
- **Signal:** Feature announcements, sometimes 1-2 days before blog post
- **Reliability:** Official but brief — need to follow up with docs/changelog to confirm details
- **Note:** X content behind paywall — use WebSearch to find coverage of tweets

### 6. Boris Cherny (@bcherny) on X
- **URL:** https://x.com/bcherny
- **What it covers:** Claude Code creator. Drops previews, confirms features, shares tips
- **Check frequency:** Every deep dive (WebSearch for "@bcherny claude code")
- **Signal:** Feature previews before official announcements, engineering decisions, roadmap hints
- **Reliability:** First-party but informal — features mentioned may be in development

### 7. Thariq Shihipar and other Anthropic engineers on X
- **What it covers:** Individual feature rollouts (e.g., voice mode was announced by Thariq)
- **Check frequency:** Covered by general "claude code" WebSearch during deep dives
- **Signal:** Gradual rollout announcements, feature flags being enabled
- **Reliability:** First-party but may describe features in limited rollout

---

## Technical / Community Sources

### 8. Piebald-AI System Prompt Archive (GitHub)
- **URL:** https://github.com/Piebald-AI/claude-code-system-prompts
- **What it covers:** Reverse-engineered Claude Code system prompts — catches undocumented features
- **Check frequency:** Every deep dive (check CHANGELOG.md in the repo)
- **Signal:** New agent prompts, new system prompt sections, new tool definitions
- **Reliability:** Community-maintained reverse engineering. Accurate for what's in the binary, but features may be behind feature flags or broken (e.g., /dream)
- **Verification:** Always cross-check with official changelog before treating as available

### 9. Releasebot.io
- **URL:** https://releasebot.io/updates/anthropic/claude-code
- **What it covers:** Aggregated Claude Code release tracking
- **Check frequency:** Optional — supplements the changelog
- **Signal:** Release frequency, aggregated view of changes
- **Reliability:** Third-party aggregator — derived from official sources

### 10. GitHub Issues (anthropics/claude-code)
- **URL:** https://github.com/anthropics/claude-code/issues
- **What it covers:** Bug reports, feature requests, community-discovered issues
- **Check frequency:** When investigating specific features (targeted search, not full scan)
- **Signal:** Broken features, feature requests that hint at roadmap, community workarounds
- **Reliability:** Mixed — community-filed, but Anthropic engineers respond

---

## Press / Analysis Sources

### 11. TechCrunch
- **Check frequency:** Covered by WebSearch during deep dives
- **Signal:** Major launches covered — agent teams, auto mode, channels, computer use
- **Reliability:** Accurate for announcements, may oversimplify technical details

### 12. VentureBeat
- **Check frequency:** Covered by WebSearch during deep dives
- **Signal:** Enterprise/platform features — channels, plugins
- **Reliability:** Good for enterprise-facing features

### 13. Community blogs (DEV.to, Substack, Medium)
- **Check frequency:** Surface naturally during WebSearch for specific features
- **Signal:** Deep dives into specific features, tutorials, hidden feature discoveries
- **Reliability:** Varies — verify claims against official sources
- **Notable authors:**
  - Ruben Hassid (ruben.substack.com) — Claude ecosystem guides
  - Claude's Corner (claudescorner.substack.com) — Claude Code tips and discoveries
  - ClaudeFast (claudefa.st/blog) — Guides and mechanics

---

## Deep Dive Integration

During a deep dive, add the following after the doc-by-doc diff (Step 4) and before the impact report (Step 7):

### Step: External Source Check
1. WebSearch: `"claude code" site:anthropic.com/news` (blog posts since last deep dive)
2. WebSearch: `"claude code" new feature announcement` (recent ~30 days)
3. WebSearch: `@bcherny claude code` (creator's announcements)
4. WebFetch: Piebald-AI CHANGELOG.md (new system prompt discoveries)
5. For each feature found:
   - Verify against Claude Code changelog (is it in a released version?)
   - Verify it's Claude Code CLI, not Desktop/Cowork/claude.ai
   - Check if we can test it locally (`claude --version` matches required version?)
   - Categorize: Confirmed CLI feature / Desktop-only / Undocumented-but-present / Rumored
