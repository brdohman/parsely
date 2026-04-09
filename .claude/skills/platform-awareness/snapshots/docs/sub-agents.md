<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/sub-agents.md -->

# Create custom subagents

> Create and use specialized AI subagents in Claude Code for task-specific workflows and improved context management.

Subagents are specialized AI assistants that handle specific types of tasks. Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions.

## Built-in subagents

| Agent | Model | Purpose |
| :---- | :---- | :------ |
| Explore | Haiku | Read-only codebase exploration |
| Plan | Inherits | Codebase research during plan mode |
| general-purpose | Inherits | Complex multi-step tasks |
| Bash | Inherits | Running terminal commands |
| statusline-setup | Sonnet | `/statusline` configuration |
| Claude Code Guide | Haiku | Questions about Claude Code features |

## Subagent scope

| Location | Scope | Priority |
| :------- | :---- | :------- |
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin's `agents/` directory | Where plugin is enabled | 4 (lowest) |

## Supported frontmatter fields

```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
permissionMode: default
maxTurns: 20
memory: user
background: false
---
```

| Field | Required | Description |
| :---- | :------- | :---------- |
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all tools if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | Model: `sonnet`, `opus`, `haiku`, full model ID, or `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, or `plan` |
| `maxTurns` | No | Maximum number of agentic turns |
| `skills` | No | Skills to preload into the subagent's context at startup |
| `mcpServers` | No | MCP servers available to this subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | Set to `true` to always run as a background task |
| `effort` | No | Effort level. Options: `low`, `medium`, `high`, `max` |
| `isolation` | No | Set to `worktree` to run in a temporary git worktree |
| `initialPrompt` | No | Auto-submitted as the first user turn when agent runs as main session |

## Restrict which subagents can be spawned

Use `Agent(agent_type)` syntax in the `tools` field:
```yaml
tools: Agent(worker, researcher), Read, Bash
```

## Permission modes

| Mode | Behavior |
| :--- | :------- |
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts |
| `bypassPermissions` | Skip permission prompts |
| `plan` | Plan mode (read-only exploration) |

## Persistent memory

| Scope | Location | Use when |
| :---- | :------- | :------- |
| `user` | `~/.claude/agent-memory/<name>/` | across all projects |
| `project` | `.claude/agent-memory/<name>/` | project-specific, shareable |
| `local` | `.claude/agent-memory-local/<name>/` | project-specific, not checked in |

## Disable specific subagents

```json
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

## Hook events for subagents

| Event | When it fires |
| :---- | :------------ |
| `SubagentStart` | When a subagent begins execution |
| `SubagentStop` | When a subagent completes |
| `PreToolUse` | Before the subagent uses a tool |
| `PostToolUse` | After the subagent uses a tool |

## Invoke subagents

- **Natural language**: name the subagent in your prompt
- **@-mention**: `@"code-reviewer (agent)"` guarantees the subagent runs
- **Session-wide**: `claude --agent code-reviewer`
- **Default**: set `agent` in `.claude/settings.json`

## Foreground vs Background

- **Foreground**: blocks the main conversation until complete. Permission prompts pass through.
- **Background**: runs concurrently. Claude Code prompts for permissions upfront. Press Ctrl+B to background a running task.

Set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` to disable all background task functionality.

## Chain subagents

```text
Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them
```

## Note: subagents cannot spawn sub-subagents

Subagents cannot spawn other subagents. For nested delegation, use Skills or chain subagents from the main conversation.
