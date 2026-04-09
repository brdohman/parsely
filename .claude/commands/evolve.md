---
name: evolve
description: Self-audit the toolkit against Claude Code platform capabilities. Identifies unused features, outdated patterns, and improvement opportunities.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, WebFetch
---

# Evolve — Toolkit Self-Audit

Strategic self-audit that compares what Claude Code can do (feature-reference.md) against what our toolkit actually uses (.claude/ directory), identifies gaps, and recommends improvements.

**This command is READ-ONLY.** Do not edit any toolkit files. Produce a report and recommendations for the user to approve.

**Skill directory:** `.claude/skills/platform-awareness/`

---

## Step 1: Load Platform Capability Map

Read the full feature reference to understand everything Claude Code supports:
```
.claude/skills/platform-awareness/references/feature-reference.md
```

Pay close attention to:
- All extension points (agents, skills, commands, hooks, MCP, plugins, rules, memory, settings)
- All 25 hook events and 4 handler types (command, http, prompt, agent)
- All skill frontmatter fields (name, description, allowed-tools, context, agent, paths, hooks, model, effort, etc.)
- All agent frontmatter fields (model, tools, skills, mcpServers, hooks, memory, background, effort, isolation, initialPrompt, etc.)
- All settings categories (permissions, hooks, env, MCP, plugins, behavior, model, security, memory, auto mode)
- The "What We Use" inventory in each section
- The "What We Don't Use (Yet)" section with existing rationale for each deferred feature

Also read the model reference for current model capabilities:
```
.claude/skills/platform-awareness/references/model-reference.md
```

### 1b. Load External Research

Read discoveries and watchlist to incorporate findings from external source monitoring:

```
.claude/skills/platform-awareness/references/discoveries.md
```
Note features with source URLs, verification status, and relevance assessments. These are things we've already researched — don't re-research them.

```
.claude/skills/platform-awareness/references/watchlist.md
```
Note active watch items — these are specific things to evaluate during this audit. If a watchlist item's resolution condition can be checked during the audit (e.g., "test this command locally"), do it.

---

## Step 2: Audit Current Toolkit

Scan our `.claude/` directory systematically. For each category, gather counts and names.

### 2a. Agents

```bash
ls .claude/agents/*.md 2>/dev/null | wc -l
```

For each agent file, read the frontmatter (first ~30 lines) and note:
- Model setting (or absent = inherit)
- Tools/disallowedTools restrictions
- Skills preloaded
- MCP servers
- Hooks scoped to agent
- Memory scope
- Permission mode
- Max turns
- Any use of: background, effort, isolation, initialPrompt

### 2b. Skills

```bash
find .claude/skills -name "SKILL.md" | wc -l
```

For each SKILL.md, read the frontmatter and note:
- Which frontmatter fields are used (name, description, allowed-tools, disable-model-invocation, context, agent, paths, hooks, model, effort, shell, user-invocable, argument-hint)
- Whether it uses `$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`, or `$N` substitutions
- Whether it uses `` !`command` `` dynamic context injection

### 2c. Commands

```bash
ls .claude/commands/*.md 2>/dev/null | wc -l
```

For each command, read the frontmatter and note which fields are used.

### 2d. Hooks

Read both settings files:
```
.claude/settings.json
.claude/settings.local.json  (if exists)
```

Extract all hook configurations. For each binding, note:
- Event name (which of the 25 events)
- Matcher pattern
- Handler type (command, http, prompt, agent)
- Whether it uses: async, timeout, statusMessage, once, if conditional

List all hook scripts:
```bash
ls .claude/hooks/*.sh 2>/dev/null
```

Also check agent frontmatter for agent-scoped hooks and skill frontmatter for skill-scoped hooks.

### 2e. MCP Servers

Read project MCP config:
```
.mcp.json
```

Note all configured servers and their transport types. Also note user-level MCP servers mentioned in feature-reference.md.

### 2f. Plugins

From settings.json, extract `enabledPlugins`. Note names and sources.

### 2g. Rules

```bash
find .claude/rules -name "*.md" | wc -l
```

Categorize by directory: global/, path/, workflow/. For path-scoped rules, check if they use `paths` frontmatter.

### 2h. Scripts

```bash
find .claude/scripts -type f | wc -l
```

### 2i. Templates

```bash
find .claude/templates -type f | wc -l
```

### 2j. Memory

Check for:
- `CLAUDE.md` at project root (exists, line count)
- `.claude/memory/` files
- `~/.claude/projects/` auto-memory presence
- Whether any CLAUDE.md files use `@path` imports

### 2k. Docs

```bash
ls .claude/docs/*.md 2>/dev/null | wc -l
```

---

## Step 3: Gap Analysis

Compare Step 1 (what the platform offers) against Step 2 (what we use). Classify every platform feature into one of four categories:

### Category A: Used and Current

Features we use and our usage matches current best practices. No action needed. List these briefly for completeness.

### Category B: Used but Outdated

Features we use but our pattern is outdated or suboptimal. Examples to check:

- **Commands vs Skills:** Are any commands in `.claude/commands/` that should migrate to `.claude/skills/`? (Skills are now preferred and take precedence.)
- **Hook handler types:** Are we only using `command` hooks when `prompt` or `agent` hooks would be more appropriate for certain use cases?
- **Hook events:** Are there newer events we should bind to? Compare our 6-7 event bindings against the full list of 25 events.
- **Agent frontmatter:** Are agents missing newer fields like `skills` preloading, `model`, `effort`, `isolation`, `hooks`?
- **Skill frontmatter:** Are skills missing useful fields like `allowed-tools`, `context: fork`, `paths`, `argument-hint`, `hooks`?
- **String substitutions:** Could skills benefit from `${CLAUDE_SKILL_DIR}` instead of hardcoded paths?
- **Permission rules:** Are permission patterns using outdated syntax?
- **Settings:** Are there newer settings keys we should adopt?

### Category C: Available but Not Used

Platform features we do not use. For each, assess:

1. **Relevance** — Does this matter for a macOS app dev toolkit? (High / Medium / Low / None)
2. **Value** — What would we gain? (Specific benefit)
3. **Effort** — How hard to adopt? (Trivial / Small / Medium / Large)
4. **Risk** — What could go wrong? (None / Low / Medium / High)

Features to evaluate (reference the "What We Don't Use (Yet)" section for existing rationale):

- `context: fork` on skills — context isolation for review/analysis work
- Plugin authoring — packaging our toolkit for distribution
- Scheduled tasks (`/loop`) — periodic checks, background monitoring
- HTTP hooks — integration with external services
- Prompt hooks — LLM-powered validation in hook pipeline
- Agent hooks (type: agent) — agent-powered validation
- Chrome integration — web-based testing
- `--bare` mode — CI/CD headless builds
- `--json-schema` structured output — programmatic output consumption
- `--system-prompt` / `--append-system-prompt` — CLI prompt customization
- Remote Control / Web sessions — cloud collaboration
- Auto mode (permission classifier) — AI-classified permissions
- `--channels` — MCP channel notifications
- Worktree isolation on agents (`isolation: worktree`) — parallel agent work in isolated branches
- Agent `background: true` — background task execution
- Agent `initialPrompt` — auto-start prompts for `--agent` mode sessions
- Agent `effort` override — per-agent effort levels
- Skill `paths` frontmatter — auto-activation by file path
- `@path` imports in CLAUDE.md — modular CLAUDE.md composition
- `claudeMdExcludes` — monorepo CLAUDE.md management
- `/batch` bundled skill — large-scale parallel refactors
- `/simplify` bundled skill — code quality review
- `/debug` bundled skill — troubleshooting
- Agent persistent memory (`memory: user`) — cross-project learning
- `--from-pr` — GitHub PR-linked sessions
- `--fork-session` — branching conversations
- LSP custom configuration — custom language server setup
- Sandbox (filesystem/network) — restricted execution
- `AGENTS.md` — alternative agent instructions file
- `--fallback-model` — model fallback for headless mode
- `autoMode` classifier tuning — auto mode configuration
- Skill `shell: powershell` — (skip for macOS)
- `FileChanged` hook event — file watcher triggers
- `SubagentStart`/`SubagentStop` hook events — subagent lifecycle hooks
- `InstructionsLoaded` hook event — CLAUDE.md loading hooks
- `SessionStart`/`SessionEnd` hook events — session lifecycle hooks
- `CwdChanged` hook event — directory change hooks
- `WorktreeCreate`/`WorktreeRemove` hook events — worktree lifecycle hooks

### Category D: Deprecated Patterns

Things we do that the platform has moved past or that could be simplified:

- Are any of our patterns documented as deprecated?
- Are we doing manual work that a platform feature now automates?
- Are there redundancies between our custom implementations and built-in capabilities?

---

## Step 4: Assess Model Selection

Read our CLAUDE.md model selection rules and compare against current model capabilities from model-reference.md:

- Are we using the right model for each agent type?
- Are context window assumptions still correct (200K total, ~41K overhead, ~156K usable)?
- Are there new models we should consider?
- Are any models we reference deprecated or retiring?
- Is the Haiku/Sonnet/Opus tier assignment still optimal?
- Should any agents switch models based on their actual workload?

---

## Step 5: Security and Permissions Review

Audit our security posture:

- **Permission scope:** Are allow/deny/ask rules appropriately restrictive?
- **Skill tool restrictions:** Do skills with `allowed-tools` have the right set? Too permissive? Too restrictive?
- **Agent permissions:** All agents use `permissionMode: bypassPermissions` — is this still appropriate for each?
- **Hook safety:** Are hooks properly scoped? Could any hook be exploited?
- **MCP server access:** Are MCP servers appropriately restricted?
- **Plugin security:** Are plugin restrictions (no hooks, no mcpServers, no permissionMode) properly enforced?
- **Secrets protection:** Are deny rules covering all sensitive file patterns?
- **Managed settings:** Should any settings move to managed (organization) level?

---

## Step 5b: Research Verification

Before recommending features for adoption, verify that the top candidates actually work as expected. This prevents recommending features that are documented but broken, Desktop-only, behind feature flags, or misunderstood.

### What to verify

From the gap analysis (Step 3, Categories B and C), select the **top 5-8 highest-impact candidates** — the ones most likely to become Quick Wins or Enhancements. Skip features already marked "Do not adopt" in discoveries.md or features with clear "not relevant" rationale.

### Verification methods

For each candidate, use the appropriate verification method:

| Feature type | How to verify |
|-------------|--------------|
| **Slash command** | Run it locally: type the command in Claude Code and check if it works |
| **Setting/config key** | Check it exists in the JSON schema: `WebFetch https://json.schemastore.org/claude-code-settings.json` or test by adding to settings |
| **Frontmatter field** | Read the official docs page for that component (agents, skills, hooks) and confirm the field is documented |
| **CLI flag** | Run `claude --help` or test the flag directly |
| **Hook event** | Confirm it's in the hooks docs; test with a simple echo script if practical |
| **Feature behind env var** | Check if the env var is documented; test by setting it |

### Verification output

For each verified candidate, record:

| Field | Value |
|-------|-------|
| Feature | Name |
| Verified | Yes / No / Partial |
| How verified | What method was used |
| Works in our version | Yes / No / Untested |
| Caveats | Anything unexpected discovered during verification |
| Recommendation | Adopt / Defer / Skip — with reason |

### Product boundary check

For EVERY candidate, confirm it's a Claude Code CLI feature, not Desktop/Cowork/claude.ai only. Use the product boundary guide in `references/external-sources.md`.

### Update discoveries and watchlist

- If a watchlist item was tested and resolved: update `watchlist.md` (move to Resolved) and `discoveries.md` (update status)
- If a new caveat or finding emerged: add a note to `discoveries.md`
- If a feature needs more investigation than this audit allows: add to `watchlist.md` with a clear resolution condition

---

## Step 6: Produce Evolution Report

Compile all findings into this structured report. Print the full report to the conversation.

```markdown
# Toolkit Evolution Report — [date]

## Toolkit Inventory

| Category | Count | Details |
|----------|-------|---------|
| Agents | [N] | [list names] |
| Skills | [N] | [list names by category] |
| Commands | [N] | [list names by category] |
| Hooks (project) | [N] | [events: list which events are bound] |
| Hooks (user) | [N] | [events: list which events are bound] |
| Hook scripts | [N] | [list names] |
| MCP Servers | [N] | [list names and scope] |
| Plugins | [N] | [list names] |
| Rules | [N] | [breakdown: global/path/workflow] |
| Scripts | [N] | |
| Templates | [N] | |
| Memory files | [N] | |
| Docs | [N] | |

## Platform Coverage

**Extension points used:** [X] of [Y] available
**Hook events used:** [X] of 25
**Hook handler types used:** [X] of 4 (command, http, prompt, agent)
**Skill frontmatter fields used:** [X] of [Y] available
**Agent frontmatter fields used:** [X] of [Y] available
**Settings categories configured:** [X] of [Y] available
**Overall coverage score:** [percentage]

## Findings

### Quick Wins (< 30 min each)
[Config changes, frontmatter additions, small improvements. High impact-to-effort ratio.]

1. **[Finding title]**
   - What: [what to change]
   - Why: [specific benefit]
   - Effort: trivial / small
   - Files affected: [list]

### Enhancements (1-2 hours each)
[New skills, hooks, or configurations leveraging unused features.]

1. **[Finding title]**
   - What: [what to build]
   - Why: [specific benefit]
   - Effort: medium
   - Prerequisite: [if any]

### Refactors (half day+)
[Architectural changes to align with new patterns or improve structure.]

1. **[Finding title]**
   - What: [what to restructure]
   - Why: [specific benefit]
   - Effort: large
   - Risk: [migration risk assessment]

### No Action Needed
[Features we correctly choose NOT to use, with justification. Reference the "What We Don't Use (Yet)" section where applicable.]

- **[Feature]:** Not relevant because [reason]

## Research Verification Results

[For each candidate verified in Step 5b:]

| Feature | Verified | Method | Works | Caveats | Recommendation |
|---------|----------|--------|-------|---------|----------------|
| [name] | [Yes/No/Partial] | [how] | [Yes/No] | [any issues] | [Adopt/Defer/Skip] |

**Watchlist items resolved:** [list or "none"]
**New items added to watchlist:** [list or "none"]
**Discoveries updated:** [list or "none"]

## Model Selection Assessment

| Agent | Current Model | Recommended | Rationale |
|-------|--------------|-------------|-----------|
| [name] | [current] | [same/change] | [why] |

**Context window notes:** [any changes to assumptions]
**New models available:** [list or "none"]
**Deprecated models:** [list or "none"]

## Security Assessment

| Area | Status | Finding |
|------|--------|---------|
| Permission rules | [OK/Review] | [detail] |
| Agent permissions | [OK/Review] | [detail] |
| Skill tool restrictions | [OK/Review] | [detail] |
| Hook safety | [OK/Review] | [detail] |
| MCP access | [OK/Review] | [detail] |
| Secrets protection | [OK/Review] | [detail] |

## Recommended Priority Order

[Rank ALL findings from Quick Wins, Enhancements, and Refactors by impact-to-effort ratio. This is the suggested execution order.]

1. **[Finding]** — [effort] — [expected impact]
2. **[Finding]** — [effort] — [expected impact]
3. **[Finding]** — [effort] — [expected impact]
...
```

---

## Step 7: Append to update-log.md

Append an entry to:
```
.claude/skills/platform-awareness/update-log.md
```

Format:
```markdown
## [date] — Evolve Self-Audit

**Toolkit:** [X] agents, [Y] skills, [Z] commands, [W] hook bindings
**Coverage:** [X]% of platform features used
**Findings:** [N] quick wins, [N] enhancements, [N] refactors
**Action:** Report presented to user for prioritization
```

---

## Step 8: Present to User

Show the Evolution Report from Step 6. Then ask:

- "Which findings would you like to pursue?"
- "Should I create tasks for any of these improvements?"

Do NOT make any changes to toolkit files. This command produces analysis only.

---

## Important Notes for the Executing Agent

- **READ-ONLY.** Do not edit any toolkit files. The only write is the update-log.md append in Step 7.
- **Be honest about gaps** but also about features we correctly DO NOT use. Not everything needs adoption. A feature that adds complexity without clear benefit for our macOS app dev toolkit is correctly skipped.
- **Prioritize by impact-to-effort ratio.** A trivial config change that improves every agent session is worth more than a large refactor with marginal gains.
- **Consider our specific use case.** We build macOS Swift/SwiftUI apps using an agile workflow with Claude Code Tasks. Features designed for web apps, monorepos, or CI/CD pipelines may not apply.
- **Reference existing rationale.** The "What We Don't Use (Yet)" section in feature-reference.md documents why features were previously deferred. If the rationale still holds, say so. If circumstances have changed, explain what changed.
- **If feature-reference.md appears outdated** (version mismatch, missing known features), note this prominently and recommend running `/deep-dive-updates` first.
- **Count carefully.** Use Glob and Bash to get accurate counts rather than relying on numbers from feature-reference.md, which may be stale.
- **Frontmatter audit should be thorough.** For agents and skills, actually read each file's frontmatter to check field usage. Do not assume from memory.

$ARGUMENTS
