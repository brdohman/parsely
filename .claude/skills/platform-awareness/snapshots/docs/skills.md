<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/skills.md -->

# Extend Claude with skills

> Create, manage, and share skills to extend Claude's capabilities in Claude Code. Includes custom commands and bundled skills.

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`.

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, which works across multiple AI tools. Claude Code extends the standard with additional features like invocation control, subagent execution, and dynamic context injection.

**Custom commands have been merged into skills.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Your existing `.claude/commands/` files keep working. Skills add optional features: a directory for supporting files, frontmatter to control whether you or Claude invokes them, and the ability for Claude to load them automatically when relevant.

## Bundled skills

Bundled skills ship with Claude Code and are available in every session. Unlike built-in commands, which execute fixed logic directly, bundled skills are prompt-based: they give Claude a detailed playbook and let it orchestrate the work using its tools.

| Skill | Purpose |
| :---- | :------ |
| `/batch <instruction>` | Orchestrate large-scale changes across a codebase in parallel. |
| `/claude-api` | Load Claude API reference material for your project's language. |
| `/debug [description]` | Enable debug logging for the current session. |
| `/loop [interval] <prompt>` | Run a prompt repeatedly on an interval. |
| `/simplify [focus]` | Review your recently changed files for code reuse, quality, and efficiency issues. |

## Where skills live

| Location | Path | Applies to |
| :------- | :--- | :--------- |
| Enterprise | See managed settings | All users in your organization |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

When skills share the same name across levels, higher-priority locations win: enterprise > personal > project.

## Frontmatter reference

```yaml
---
name: my-skill
description: What this skill does
disable-model-invocation: true
allowed-tools: Read, Grep
---
```

| Field | Required | Description |
| :---- | :------- | :---------- |
| `name` | No | Display name for the skill. |
| `description` | Recommended | What the skill does and when to use it. |
| `argument-hint` | No | Hint shown during autocomplete. |
| `disable-model-invocation` | No | Set to `true` to prevent Claude from automatically loading this skill. |
| `user-invocable` | No | Set to `false` to hide from the `/` menu. |
| `allowed-tools` | No | Tools Claude can use without asking permission when this skill is active. |
| `model` | No | Model to use when this skill is active. |
| `effort` | No | Effort level when this skill is active. Options: `low`, `medium`, `high`, `max`. |
| `context` | No | Set to `fork` to run in a forked subagent context. |
| `agent` | No | Which subagent type to use when `context: fork` is set. |
| `hooks` | No | Hooks scoped to this skill's lifecycle. |
| `paths` | No | Glob patterns that limit when this skill is activated. |
| `shell` | No | Shell to use for inline shell commands. |

## String substitutions

| Variable | Description |
| :------- | :---------- |
| `$ARGUMENTS` | All arguments passed when invoking the skill. |
| `$ARGUMENTS[N]` | Access a specific argument by 0-based index. |
| `$N` | Shorthand for `$ARGUMENTS[N]`. |
| `${CLAUDE_SESSION_ID}` | The current session ID. |
| `${CLAUDE_SKILL_DIR}` | The directory containing the skill's `SKILL.md` file. |

## Control who invokes a skill

- **`disable-model-invocation: true`**: Only you can invoke the skill.
- **`user-invocable: false`**: Only Claude can invoke the skill.

| Frontmatter | You can invoke | Claude can invoke |
| :---------- | :------------- | :---------------- |
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

## Dynamic context injection

The `` !`<command>` `` syntax runs shell commands before the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself.

## Run skills in a subagent

Add `context: fork` to your frontmatter when you want a skill to run in isolation. The skill content becomes the prompt that drives the subagent.

## Permission rules for skills

- `Skill(name)` for exact match
- `Skill(name *)` for prefix match with any arguments

## Restrict Claude's skill access

**Disable all skills** by denying the Skill tool in `/permissions`.

**Allow or deny specific skills** using permission rules:
```
Skill(commit)
Skill(review-pr *)
Skill(deploy *)
```

**Hide individual skills** by adding `disable-model-invocation: true` to their frontmatter.
