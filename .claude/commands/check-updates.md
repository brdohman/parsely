---
name: check-updates
description: Quick scan for Claude Code platform changes — version, new docs, changelog entries
disable-model-invocation: true
allowed-tools: Bash, WebFetch, Read, Write, Edit, Glob, Grep
---

# Check for Claude Code Platform Updates

Run a quick scan (~30 seconds) to detect platform changes since last check. No modifications to the toolkit — report only.

**Skill directory:** `${CLAUDE_SKILL_DIR}/../platform-awareness/`

## Step 1: Read Current State

Read the last-checked state file:
```
.claude/skills/platform-awareness/references/last-checked.json
```

Read the cached llms.txt index:
```
.claude/skills/platform-awareness/snapshots/llms-index.txt
```

Note the `claude_code_version`, `last_check_date`, `index_page_count`, and `changelog_last_version`.

## Step 2: Check Current Version

Run `claude --version` via Bash to get the currently installed version. Compare to `claude_code_version` from last-checked.json.

## Step 3: Check Documentation Index

Fetch the current llms.txt index:
```
WebFetch: https://code.claude.com/docs/llms.txt
Prompt: "Return the COMPLETE content. List every documentation page entry with its URL and description. Do not summarize."
```

Compare against the cached `snapshots/llms-index.txt`:
- Count total pages (compare to `index_page_count`)
- Identify NEW pages (present in fetched but not in cached)
- Identify REMOVED pages (present in cached but not in fetched)
- Identify pages with changed descriptions

## Step 4: Check Changelog (if version changed)

Only if version differs from last check:

Fetch recent releases from GitHub API:
```
WebFetch: https://api.github.com/repos/anthropics/claude-code/releases?per_page=10
Prompt: "Return the tag_name, published_at, and body for each release. Format as a list."
```

Extract entries newer than `changelog_last_version`. Summarize key changes in each.

## Step 5: Produce Report

Format the report as:

```markdown
# Platform Update Check — [today's date]

## Version
- **Installed:** [current version]
- **Last checked:** [last version] on [last date]
- **Delta:** [X new releases / no change]

## Documentation Index
- **Pages:** [current count] (was [previous count])
- **New pages:** [list with titles, or "none"]
- **Removed pages:** [list, or "none"]

## Key Changelog Entries (since [last version])
[For each new version, list the highlights — focus on features relevant to our toolkit:
hooks, skills, agents, MCP, settings, permissions, memory, plugins]

## Relevance to Our Toolkit
[For each significant change, note whether it affects our .claude/ configuration:
- "hooks.md: New event type X — may affect our git-guards hook"
- "skills: New frontmatter field Y — could improve our build commands"
- "No toolkit-relevant changes detected"]

## Recommendation
[One of:
- "No significant changes. Toolkit is current."
- "Minor changes detected. No action needed."
- "Significant changes found. Run /deep-dive-updates for full analysis."
- "Breaking changes possible. Run /deep-dive-updates before next build."]
```

## Step 6: Update State

Update `last-checked.json` with:
- `claude_code_version`: current version
- `last_check_date`: today's date
- `index_page_count`: current count

Update `snapshots/llms-index.txt` with the freshly fetched index content.

Do NOT update individual doc snapshots — that's `/deep-dive-updates` territory.

## Step 7: Log Entry

Append a brief entry to `update-log.md`:

```markdown
## [date] — Check Updates

**Version:** [old] → [new] ([X] new releases)
**New pages:** [list or "none"]
**Action:** [recommendation from report]
```

$ARGUMENTS
