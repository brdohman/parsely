---
name: deep-dive-updates
description: Full platform analysis — diffs all tracked docs, detects new features, categorizes changes by impact, recommends toolkit updates
disable-model-invocation: true
allowed-tools: Bash, WebFetch, Read, Write, Edit, Glob, Grep
---

# Deep Dive Platform Updates

Full analysis of all tracked Claude Code documentation and platform sources. Diffs every tracked doc against its cached snapshot, categorizes changes by impact, and produces an actionable report with toolkit recommendations.

**When to use:** Monthly cadence, or immediately after an Anthropic release announcement. For a quick scan, use `/check-updates` instead.

**Skill directory:** `.claude/skills/platform-awareness/`

**Estimated tool calls:** ~16-20 (1 version check + 1 index + 1 changelog + 12 doc fetches + 1 API release notes + new page fetches)

---

## Step 1: Read Current State

Read ALL of these to establish the baseline for comparison:

1. **Last-checked state:**
   ```
   .claude/skills/platform-awareness/references/last-checked.json
   ```
   Note `claude_code_version`, `last_check_date`, `last_deep_dive_date`, `index_page_count`, `changelog_last_version`, the full `tracked_docs` array, and the `tracked_sources` array.

2. **Cached llms.txt index:**
   ```
   .claude/skills/platform-awareness/snapshots/llms-index.txt
   ```

3. **List tracked doc snapshots:**
   ```
   ls .claude/skills/platform-awareness/snapshots/docs/
   ```
   Confirm the files on disk match the `tracked_docs` array in last-checked.json.

4. **Watchlist — check what we're monitoring:**
   ```
   .claude/skills/platform-awareness/references/watchlist.md
   ```
   Read the active watch items. For each item, note its resolution condition — you will check these during Steps 2-5b.

5. **Discoveries — review existing knowledge:**
   ```
   .claude/skills/platform-awareness/references/discoveries.md
   ```
   Skim to avoid re-researching things already documented.

---

## Step 2: Version + Index Check

### 2a. Version check

Run via Bash:
```bash
claude --version
```
Compare the installed version against `claude_code_version` from last-checked.json. Note the delta.

### 2b. Fetch live documentation index

```
WebFetch: https://code.claude.com/docs/llms.txt
Prompt: "Return the COMPLETE content. List every documentation page entry with its URL and description. Do not summarize or omit anything."
```

### 2c. Compare against cached index

Compare the fetched index against `snapshots/llms-index.txt`:
- Count total pages in the live index vs `index_page_count`
- Identify **new pages** (present in live, absent in cached)
- Identify **removed pages** (present in cached, absent in live)
- Note pages with changed descriptions

Record these findings — you will need them in Step 5 and Step 7.

---

## Step 3: Changelog Deep Dive

### 3a. Fetch the full changelog

```
WebFetch: https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
Prompt: "Return the COMPLETE changelog content. Include every version entry with its full details. Do not summarize or truncate."
```

If the content is truncated and saved to a file, read that file to get the full content.

### 3b. Read cached changelog

Read the cached version:
```
.claude/skills/platform-awareness/snapshots/changelog.md
```

### 3c. Extract new entries

Identify all version entries in the fetched changelog that are NEWER than `changelog_last_version` from last-checked.json.

For each new version entry, categorize changes into:
- **Hooks:** New events, changed behavior, new hook options
- **Agents:** New frontmatter fields, delegation changes, built-in agent updates
- **Skills/Commands:** New frontmatter fields, loading changes, resolution order
- **MCP:** Protocol changes, new capabilities, server config changes
- **Settings:** New configuration keys, permission changes, env var additions
- **Plugins:** New plugin capabilities, registry changes
- **Memory:** New memory features, scope changes
- **CLI:** New flags, changed defaults, workflow changes
- **Other:** Everything else

---

## Step 4: Doc-by-Doc Diff (THE KEY STEP)

This is the core of the deep dive. For EACH file listed in `tracked_docs` from last-checked.json (currently 12 docs), perform a paired comparison.

### For each tracked doc:

**4a. Read the cached snapshot:**
```
.claude/skills/platform-awareness/snapshots/docs/{filename}
```

**4b. Fetch the live version:**
```
WebFetch: https://code.claude.com/docs/en/{filename-without-extension}
Prompt: "Return the COMPLETE page content including all headings, tables, code examples, and configuration options. Do not summarize."
```

Note: The URL path uses the filename without the `.md` extension. For example, `hooks.md` maps to `https://code.claude.com/docs/en/hooks`.

**4c. Compare the two versions.** Focus on STRUCTURAL differences, not cosmetic ones. WebFetch returns AI-processed content, not raw text — so you cannot do a literal line-by-line diff. Instead, look for:

- **New headings/sections** added to the page
- **New table rows** (new options, new parameters, new events)
- **New code examples** demonstrating new features
- **New configuration keys or values**
- **Changed default values or behavior descriptions**
- **Deprecation notices or migration guidance**
- **Removed sections or features**

**4d. Categorize each change found:**

| Category | Criteria | Action Likely? |
|----------|----------|----------------|
| **Minor** | Typo fix, rewording, formatting, example cleanup | No |
| **Moderate** | New option/parameter, new example, behavior clarification, expanded docs | Could improve toolkit |
| **Major** | New extension point, new hook event, deprecation, breaking change, new capability | Likely needs toolkit update |

**4e. Record findings** for this doc: filename, category (Minor/Moderate/Major), summary of each change, whether it is relevant to our toolkit, and recommended action.

### Processing order

Process the docs in this priority order (highest-impact docs first):
1. `hooks.md` — our most customized extension point
2. `settings.md` — permissions and config
3. `sub-agents.md` — agent delegation is core to our workflow
4. `skills.md` — skills drive all our commands
5. `plugins.md` and `plugins-reference.md` — plugin system
6. `mcp.md` — MCP server connections
7. `agent-teams.md` — team coordination
8. `memory.md` — memory and context
9. `permissions.md` — permission model
10. `scheduled-tasks.md` — automation
11. `features-overview.md` — general feature catalog

---

## Step 5: New Page Analysis

For any new pages detected in Step 2 (present in live index but absent in cached):

**5a.** Fetch each new page:
```
WebFetch: https://code.claude.com/docs/en/{page-path}
Prompt: "Return the COMPLETE page content. Include all headings, configuration options, code examples, and details."
```

**5b.** For each new page, assess:
- **What it covers** (one sentence summary)
- **Relevance to our toolkit** — High / Medium / Low / None
  - High: Directly extends a capability we use (hooks, agents, skills, MCP)
  - Medium: Related to our workflow but not directly used yet
  - Low: Interesting but not applicable to our macOS dev toolkit
  - None: Completely unrelated

**5c.** If relevance is High or Medium:
- Save the content to `snapshots/docs/{filename}.md`
- The filename will be added to `tracked_docs` in Step 8

---

## Step 5b: External Source Check

Check community and social sources for features not captured by official docs or changelog. Read `references/external-sources.md` for the full source catalog and verification protocol.

### 5b-1. Search for recent Anthropic announcements

Run 3 WebSearch queries (can be parallel):

1. `"claude code" new feature site:anthropic.com` (blog posts since last deep dive)
2. `"claude code" announcement` (general recent coverage, limit to ~30 days)
3. `bcherny claude code OR AnthropicAI claude code` (creator + official X announcements)

### 5b-2. Check Piebald-AI system prompt archive

```
WebFetch: https://raw.githubusercontent.com/Piebald-AI/claude-code-system-prompts/main/CHANGELOG.md
Prompt: "Return the complete changelog. List every entry with dates and what system prompt changes were detected."
```

Look for new agent prompts, new tool definitions, or undocumented features added since the last deep dive.

### 5b-3. Verify each finding

For EACH feature found in external sources, apply the verification protocol:

| Check | Method | Required? |
|-------|--------|-----------|
| **Product boundary** | Is this Claude Code CLI, or Desktop/Cowork/claude.ai? | Yes — skip non-CLI features (record in Ecosystem Awareness only) |
| **Changelog confirmation** | Does it appear in CHANGELOG.md? | Yes for "Confirmed" status |
| **Version check** | Is the required version <= our installed version? | Yes before recommending adoption |
| **CLI test** | Can we run the command locally? | Recommended for undocumented features |

### 5b-4. Check watchlist items

Read `references/watchlist.md`. For each active watch item, check its resolution condition using version, changelog, or CLI test. If resolved, note the outcome.

### 5b-5. Categorize and record findings

| Category | Criteria | Where to record |
|----------|----------|-----------------|
| **Confirmed CLI feature** | In changelog + works in our version | `discoveries.md` (update or add entry) + `feature-reference.md` |
| **Undocumented but present** | In binary (Piebald-AI) but not in changelog/docs | `discoveries.md` + feature-reference.md Section 14 + `watchlist.md` (if needs monitoring) |
| **Desktop/Cowork only** | Only works in Desktop app | `discoveries.md` (Ecosystem section) + feature-reference.md Section 15 |
| **Rumored/broken** | Reported but not working | `discoveries.md` + feature-reference.md Section 14 with "Do not adopt" + `watchlist.md` |
| **New thing to monitor** | Interesting but needs more investigation | `watchlist.md` with clear resolution condition |

### 5b-6. Update state

- Update `last-checked.json` → `tracked_sources[].last_checked` with today's date for each source checked
- Move resolved watchlist items to the "Resolved Items" section of `watchlist.md`
- Update `discoveries.md` entries that changed status (e.g., broken -> working)

---

## Step 6: Model & API Changes

### 6a. Fetch release notes

```
WebFetch: https://platform.claude.com/docs/en/release-notes/overview
Prompt: "Return all release note entries. For each, include the date, model names, and description of changes. Focus on model launches, deprecations, context window changes, and API feature additions."
```

### 6b. Compare against model reference

Read:
```
.claude/skills/platform-awareness/references/model-reference.md
```

Check for:
- **New models launched** — not yet in our reference
- **Models deprecated or retired** — status changes since our reference
- **Context window changes** — any model with updated limits
- **New API features** — capabilities we might leverage
- **Pricing changes** — if mentioned in release notes

---

## Step 7: Produce Impact Report

Compile all findings into this structured report. Print the report to the conversation.

```markdown
# Deep Dive Update Report — [today's date]

## Summary
- **Version:** [old from last-checked.json] -> [current installed] ([X] new releases)
- **Index:** [old page count] -> [new page count] pages
- **Doc changes detected:** [X] of [Y] tracked docs had meaningful changes
- **Changelog entries analyzed:** [X] new versions since [last version]
- **Overall assessment:** [No action needed / Minor tweaks recommended / Significant updates needed / Breaking changes detected]

## New Documentation Pages

[For each new page detected in Step 2/5:]

### [Page title]
- **URL:** https://code.claude.com/docs/en/[path]
- **Covers:** [one sentence]
- **Relevance:** [High/Medium/Low/None]
- **Recommendation:** [Start tracking / Awareness only / Skip]

[If no new pages: "No new pages detected."]

## Documentation Changes

[For each tracked doc that had changes, ordered by impact category (Major first):]

### [filename] — [Major/Moderate/Minor]
**What changed:**
- [Bullet point for each change detected]

**Relevant to our toolkit:** [Yes/No] — [brief explanation of why]

**Recommended action:** [One of:]
- No action needed
- Update feature-reference.md to reflect new capability
- Update [specific toolkit file] to use new option/feature
- Create a task to implement [specific change]
- Review for potential breaking change in [our file]

[If no docs changed: "All tracked docs match their cached snapshots."]

## Changelog Highlights (v[old] -> v[new])

### Toolkit-Relevant Changes
[Changes that directly affect features we use, grouped by area:]

**Hooks:**
- v[X]: [change] — affects [our file/configuration]

**Agents:**
- v[X]: [change] — affects [our file/configuration]

[Continue for each area with relevant changes]

### Awareness Only
[Changes that are good to know but do not require action:]
- v[X]: [change]

[If no new changelog entries: "No new releases since last check."]

## Model & API Changes

[Findings from Step 6:]
- **New models:** [list or "none"]
- **Deprecations/retirements:** [list or "none"]
- **Context window changes:** [list or "none"]
- **API features:** [list or "none"]

[If no changes: "No model or API changes detected."]

## External Source Findings

[Findings from Step 5b, organized by verification status:]

### Confirmed CLI Features (in changelog, works in our version)
[For each confirmed feature not already in our feature-reference:]
- **[Feature name]** (v[version]) — [what it does]. Source: [where found]

### Undocumented but Present (in binary, not in changelog/docs)
[For each undocumented feature:]
- **[Feature name]** — [what it does]. Status: [working/broken/behind feature flag]. Source: [Piebald-AI/GitHub issue/etc.]

### Ecosystem Only (Desktop/Cowork/claude.ai — NOT Claude Code CLI)
[For each non-CLI feature found in announcements:]
- **[Feature name]** ([product]) — [what it does]. Not applicable to our CLI toolkit.

[If no external findings: "No new features found beyond official docs and changelog."]

## Recommended Actions

[Priority-ordered list of concrete actions. Each must be specific and actionable.]

1. **[High]** [specific action] — because [specific reason]
2. **[Medium]** [specific action] — because [specific reason]
3. **[Low]** [specific action] — because [specific reason]

[If nothing to do: "No actions needed. Toolkit is current with Claude Code v[version]."]
```

---

## Step 8: Update All Snapshots

After presenting the report, update all cached data to reflect the current state:

### 8a. Update llms-index.txt
Write the freshly fetched index content to:
```
.claude/skills/platform-awareness/snapshots/llms-index.txt
```

### 8b. Update changelog.md
Write the freshly fetched changelog content to:
```
.claude/skills/platform-awareness/snapshots/changelog.md
```

### 8c. Update tracked doc snapshots
For each tracked doc where changes were detected in Step 4:
- Write the freshly fetched content to `snapshots/docs/{filename}`

### 8d. Add new tracked docs
For any new pages saved in Step 5c:
- The content was already saved to `snapshots/docs/` in Step 5c
- These filenames will be added to `tracked_docs` in 8e

### 8e. Update last-checked.json
Read the current file, then write the updated version:
```json
{
  "claude_code_version": "[current installed version]",
  "last_check_date": "[today's date]",
  "last_deep_dive_date": "[today's date]",
  "index_page_count": [new page count],
  "changelog_last_version": "[latest version from changelog]",
  "tracked_docs": [
    ...existing docs,
    ...any new docs added in Step 5c
  ]
}
```

---

## Step 9: Update feature-reference.md (if Major changes found)

Only if Step 4 or Step 5 identified **Major** changes that affect our understanding of Claude Code capabilities:

1. Read:
   ```
   .claude/skills/platform-awareness/references/feature-reference.md
   ```

2. Edit to reflect new features, changed capabilities, or deprecations. Specifically:
   - Add new extension points or configuration options to the relevant section
   - Update tables with new fields, events, or parameters
   - Add entries to "What We Don't Use (Yet)" for new features not yet adopted
   - Remove or mark deprecated features
   - Update the "Last updated" date and version at the top of the file

3. If model changes were found in Step 6, also update:
   ```
   .claude/skills/platform-awareness/references/model-reference.md
   ```

If no Major changes were found, skip this step.

---

## Step 10: Append to update-log.md

Append a detailed entry to:
```
.claude/skills/platform-awareness/update-log.md
```

Format:
```markdown
## [today's date] — Deep Dive Update

**Version:** [old] -> [new] ([X] new releases)
**Index:** [old count] -> [new count] pages ([X] new, [Y] removed)
**Docs changed:** [X] of [Y] tracked ([list filenames with impact category])
**Changelog entries:** [X] new versions analyzed
**Model changes:** [summary or "none"]

### Findings
[Bullet list of every meaningful finding, organized by source:]
- **[doc/changelog/index/model]:** [what was found] — [Minor/Moderate/Major]

### Actions Taken
[What was updated in this session:]
- Updated snapshots for: [list of files]
- Updated feature-reference.md: [yes/no — what changed]
- Updated model-reference.md: [yes/no — what changed]
- New docs now tracked: [list or "none"]

### Recommended Follow-Up
[Actions recommended to the user, copied from report:]
1. [action]
```

---

## Step 11: Present to User

Show the Impact Report from Step 7 to the user. Then:

- If **recommended actions** exist, ask: "Would you like me to pursue any of these recommended actions now?"
- If **no actions** are needed, state: "Toolkit is current. All snapshots have been refreshed. Next deep dive recommended in ~30 days or after a significant Anthropic announcement."

---

## Notes for the Executing Agent

- **Tool call budget:** Expect 16-20 WebFetch calls minimum. If the index reveals many new pages, budget additional calls for Step 5.
- **WebFetch behavior:** Returns AI-processed content, not raw HTML or markdown. Focus comparisons on structural differences (new headings, new config options, new table rows, new features) rather than attempting line-by-line diffs.
- **Truncated content:** If WebFetch returns truncated content saved to a file, read that file to get the full content before proceeding with comparison.
- **Actionability:** Every finding must lead to either "no action needed" or a specific, concrete recommendation. Avoid vague suggestions.
- **Comparison strategy:** When comparing a cached snapshot to fetched content, look for: new headings/sections, new table rows, new code examples showing new features, new configuration keys, deprecation notices, changed default values.
- **Order of operations:** Steps 2-6 gather data. Step 7 synthesizes. Steps 8-10 persist. Step 11 presents. Do not update snapshots (Step 8) until after the report is produced (Step 7).
- **Parallel fetching:** Steps 2, 3, and 6 are independent of each other and can be started in any order. Step 4 depends on Step 1 completing. Step 5 depends on Step 2 completing.

$ARGUMENTS
