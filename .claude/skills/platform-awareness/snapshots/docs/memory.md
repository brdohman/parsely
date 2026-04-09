<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/memory.md -->

# How Claude remembers your project

> Give Claude persistent instructions with CLAUDE.md files, and let Claude accumulate learnings automatically with auto memory.

## CLAUDE.md vs auto memory

| | CLAUDE.md files | Auto memory |
| :--- | :--------------- | :---------- |
| **Who writes it** | You | Claude |
| **What it contains** | Instructions and rules | Learnings and patterns |
| **Scope** | Project, user, or org | Per working tree |
| **Loaded into** | Every session | Every session (first 200 lines or 25KB) |
| **Use for** | Coding standards, workflows, project architecture | Build commands, debugging insights, preferences |

## CLAUDE.md file locations

| Scope | Location | Purpose | Shared with |
| :---- | :------- | :------ | :---------- |
| **Managed policy** | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br/>Linux: `/etc/claude-code/CLAUDE.md` | Organization-wide | All users |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared | Team members via source control |
| **User** | `~/.claude/CLAUDE.md` | Personal preferences | Just you (all projects) |

## How CLAUDE.md files load

- Files from working directory UP TO root load at session start
- Subdirectory CLAUDE.md files load ON DEMAND when Claude reads files there
- More specific locations take precedence over broader ones
- `claudeMdExcludes` setting lets you skip specific files by path or glob

## AGENTS.md compatibility

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If your repo uses `AGENTS.md`, create a `CLAUDE.md` that imports it:
```markdown
@AGENTS.md

## Claude Code
Use plan mode for changes under `src/billing/`.
```

## Import additional files

```text
See @README for project overview and @package.json for available npm commands.
- git workflow @docs/git-instructions.md
```

- Relative paths resolve relative to the file containing the import (not CWD)
- Max depth: 5 hops
- External imports show an approval dialog first time

## Writing effective instructions

- **Size**: target under 200 lines per CLAUDE.md file
- **Structure**: use markdown headers and bullets
- **Specificity**: "Use 2-space indentation" not "Format code properly"
- **Consistency**: no contradicting rules

## Organize rules with `.claude/rules/`

Place markdown files in `.claude/rules/`. Each file covers one topic.

### Path-specific rules

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules
- All API endpoints must include input validation
```

Rules without `paths` load unconditionally. Path-scoped rules trigger when Claude reads matching files.

### Glob patterns

| Pattern | Matches |
| :------ | :------ |
| `**/*.ts` | All TypeScript files in any directory |
| `src/**/*` | All files under `src/` |
| `*.md` | Markdown files in project root |
| `src/components/*.tsx` | React components in specific directory |

## User-level rules

Personal rules in `~/.claude/rules/` apply to every project. User-level rules load before project rules.

## Load from additional directories

`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` enables loading CLAUDE.md from `--add-dir` directories.

## Auto memory

Auto memory requires Claude Code v2.1.59 or later.

### Storage location

`~/.claude/projects/<project>/memory/`

```text
~/.claude/projects/<project>/memory/
├── MEMORY.md          # Concise index, loaded into every session
├── debugging.md       # Detailed notes
├── api-conventions.md # API design decisions
```

### How it works

- First 200 lines of `MEMORY.md` (or 25KB) loaded at session start
- Topic files (debugging.md, etc.) loaded ON DEMAND
- Claude reads/writes memory files during your session

### Enable/disable auto memory

```json
{
  "autoMemoryEnabled": false
}
```

Or set `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

### Custom location

```json
{
  "autoMemoryDirectory": "~/my-custom-memory-dir"
}
```

## View with `/memory`

The `/memory` command lists all CLAUDE.md and rules files loaded in your current session, lets you toggle auto memory, and provides a link to open the auto memory folder.

## Troubleshooting

- Run `/memory` to verify CLAUDE.md files are being loaded
- CLAUDE.md content is delivered as a user message, not system prompt - Claude reads it and tries to follow it
- For system prompt level, use `--append-system-prompt`
- After `/compact`, Claude re-reads CLAUDE.md from disk fresh - instructions in CLAUDE.md persist through compaction
- Use `InstructionsLoaded` hook to log exactly which instruction files load

## Managed CLAUDE.md for teams

Managed CLAUDE.md files (in managed policy locations) cannot be excluded by `claudeMdExcludes`. They always apply.

| Concern | Configure in |
| :------ | :---------- |
| Block specific tools, commands, or file paths | Managed settings: `permissions.deny` |
| Enforce sandbox isolation | Managed settings: `sandbox.enabled` |
| Code style and quality guidelines | Managed CLAUDE.md |
| Data handling and compliance reminders | Managed CLAUDE.md |
