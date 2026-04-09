<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/features-overview.md -->

# Extend Claude Code

> Understand when to use CLAUDE.md, Skills, subagents, hooks, MCP, and plugins.

## Overview of extensions

| Feature | What it does | When to use it | Example |
| :------ | :----------- | :------------- | :------ |
| **CLAUDE.md** | Persistent context loaded every conversation | Project conventions, "always do X" rules | "Use pnpm, not npm." |
| **Skill** | Instructions, knowledge, and workflows Claude can use | Reusable content, reference docs, repeatable tasks | `/deploy` deployment checklist |
| **Subagent** | Isolated execution context that returns summarized results | Context isolation, parallel tasks, specialized workers | Research task |
| **Agent teams** | Coordinate multiple independent Claude Code sessions | Parallel research, debugging with competing hypotheses | Spawn reviewers simultaneously |
| **MCP** | Connect to external services | External data or actions | Query database, post to Slack |
| **Hook** | Deterministic script that runs on events | Predictable automation, no LLM involved | Run ESLint after every file edit |

**Plugins** are the packaging layer. A plugin bundles skills, hooks, subagents, and MCP servers into a single installable unit.

## Compare similar features

### Skill vs Subagent

| Aspect | Skill | Subagent |
| :----- | :---- | :------- |
| **What it is** | Reusable instructions, knowledge, or workflows | Isolated worker with its own context |
| **Key benefit** | Share content across contexts | Context isolation |
| **Best for** | Reference material, invocable workflows | Tasks that read many files, parallel work |

### CLAUDE.md vs Skill

| Aspect | CLAUDE.md | Skill |
| :----- | :-------- | :---- |
| **Loads** | Every session, automatically | On demand |
| **Can trigger workflows** | No | Yes, with `/<name>` |
| **Best for** | "Always do X" rules | Reference material, invocable workflows |

Rule of thumb: Keep CLAUDE.md under 200 lines. If it's growing, move reference content to skills.

### CLAUDE.md vs Rules vs Skills

| Aspect | CLAUDE.md | `.claude/rules/` | Skill |
| :----- | :-------- | :---------------- | :---- |
| **Loads** | Every session | Every session, or when matching files opened | On demand |
| **Scope** | Whole project | Can be scoped to file paths | Task-specific |
| **Best for** | Core conventions and build commands | Language-specific guidelines | Reference material, repeatable workflows |

### Subagent vs Agent team

| Aspect | Subagent | Agent team |
| :----- | :------- | :--------- |
| **Context** | Own context; results return to caller | Own context; fully independent |
| **Communication** | Reports to main agent only | Teammates message each other |
| **Coordination** | Main agent manages all work | Shared task list with self-coordination |
| **Best for** | Focused tasks where only result matters | Complex work requiring discussion |
| **Token cost** | Lower | Higher |

Transition point: if subagents need to communicate with each other, use agent teams.

Agent teams are experimental and disabled by default.

### MCP vs Skill

| Aspect | MCP | Skill |
| :----- | :-- | :---- |
| **What it is** | Protocol for connecting to external services | Knowledge, workflows, reference material |
| **Provides** | Tools and data access | Knowledge, workflows |
| **Examples** | Slack, database, browser control | Code review checklist, deploy workflow |

These work well together: MCP provides the connection, skill teaches Claude how to use it effectively.

## How features layer

- **CLAUDE.md files**: additive - all levels contribute content simultaneously
- **Skills and subagents**: override by name (managed > user > project)
- **MCP servers**: override by name (local > project > user)
- **Hooks**: merge - all registered hooks fire for matching events

## Context cost by feature

| Feature | When it loads | What loads | Context cost |
| :------ | :------------ | :--------- | :----------- |
| **CLAUDE.md** | Session start | Full content | Every request |
| **Skills** | Session start + when used | Descriptions at start, full content when used | Low (descriptions)* |
| **MCP servers** | Session start | Tool names; full schemas on demand | Low until tool used |
| **Subagents** | When spawned | Fresh context with specified skills | Isolated from main session |
| **Hooks** | On trigger | Nothing (runs externally) | Zero |

*Set `disable-model-invocation: true` to hide skill from Claude until manually invoked. Reduces context cost to zero.

## How features load

**CLAUDE.md**: loads at session start, full content in every request. Keep under ~500 lines.

**Skills**: descriptions in context at start; full content on invocation. With `disable-model-invocation: true`, nothing loads until you invoke manually.

**MCP servers**: tool names at session start, full JSON schemas deferred. Tool search is on by default. Run `/mcp` to see token costs per server.

**Subagents**: fresh isolated context at spawn. Contains system prompt, preloaded skills, CLAUDE.md, and prompt from lead. Does NOT inherit conversation history or invoked skills from parent.

**Hooks**: run externally at trigger. Zero context cost unless hook returns output added as messages.

## Common patterns

| Pattern | How it works | Example |
| :------ | :----------- | :------ |
| **Skill + MCP** | MCP provides connection; skill teaches how to use it | MCP connects to DB, skill documents schema |
| **Skill + Subagent** | Skill spawns subagents for parallel work | `/audit` kicks off security + performance subagents |
| **CLAUDE.md + Skills** | CLAUDE.md holds always-on rules; skills hold reference | CLAUDE.md says "follow API conventions," skill has the full guide |
| **Hook + MCP** | Hook triggers external actions through MCP | Post-edit hook sends Slack notification |
