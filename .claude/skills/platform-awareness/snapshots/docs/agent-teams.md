<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/agent-teams.md -->

# Orchestrate teams of Claude Code sessions

> Coordinate multiple Claude Code instances working together as a team, with shared tasks, inter-agent messaging, and centralized management.

**Status: Experimental - disabled by default.**

Enable by adding to settings.json:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Requires Claude Code v2.1.32 or later.

## When to use agent teams

Best use cases:
- **Research and review**: multiple teammates investigating different aspects simultaneously
- **New modules or features**: teammates each own a separate piece
- **Debugging with competing hypotheses**: teammates test different theories in parallel
- **Cross-layer coordination**: changes spanning frontend, backend, and tests

NOT ideal for: sequential tasks, same-file edits, or work with many dependencies.

## Compare with subagents

| | Subagents | Agent teams |
| :-- | :-------- | :---------- |
| **Context** | Own context window; results return to caller | Own context window; fully independent |
| **Communication** | Report results back to main agent only | Teammates message each other directly |
| **Coordination** | Main agent manages all work | Shared task list with self-coordination |
| **Best for** | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| **Token cost** | Lower: results summarized back | Higher: each teammate is a separate Claude instance |

## Architecture

| Component | Role |
| :-------- | :--- |
| **Team lead** | Main Claude Code session that creates the team |
| **Teammates** | Separate Claude Code instances working on assigned tasks |
| **Task list** | Shared list of work items |
| **Mailbox** | Messaging system for inter-agent communication |

Storage:
- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`

## Start a team

```text
I'm designing a CLI tool. Create an agent team: one teammate on UX, one on technical architecture, one playing devil's advocate.
```

Claude creates a team with a shared task list, spawns teammates, has them explore, synthesizes findings, and cleans up.

## Display modes

| Mode | Description |
| :--- | :---------- |
| `in-process` | All teammates in main terminal. Use Shift+Down to cycle. |
| `tmux` | Each teammate in own pane. Requires tmux or iTerm2. |

Configure in settings.json:
```json
{
  "teammateMode": "in-process"
}
```

Or pass as flag: `claude --teammate-mode in-process`

## Control the team

- **Natural language**: tell the lead what you want
- **Specify teammates**: "Create a team with 4 teammates, use Sonnet for each"
- **Talk to teammates directly**: use Shift+Down to cycle (in-process) or click pane (split)
- **Assign tasks**: tell the lead which task to give which teammate
- **Shut down teammates**: "Ask the researcher teammate to shut down"
- **Clean up**: "Clean up the team" — always use the lead for cleanup

## Require plan approval for teammates

```text
Spawn an architect teammate to refactor the authentication module. Require plan approval before they make any changes.
```

The lead approves or rejects plans autonomously. Rejected teammates revise and resubmit.

## Task states

- **Pending**: not started
- **In progress**: claimed by a teammate
- **Completed**: done

Tasks can have dependencies. A pending task with unresolved dependencies cannot be claimed until dependencies complete.

## Hooks for agent teams

| Event | When |
| :---- | :--- |
| `TeammateIdle` | When a teammate is about to go idle. Exit code 2 sends feedback and keeps working. |
| `TaskCreated` | When a task is being created. Exit code 2 prevents creation. |
| `TaskCompleted` | When a task is being marked complete. Exit code 2 prevents completion. |

## How teammates share information

- **Automatic message delivery**: messages delivered automatically
- **Idle notifications**: teammates notify lead when they finish
- **Shared task list**: all agents see task status and can claim work
- **Broadcast**: send to all teammates (use sparingly - costs scale with team size)

## Best practices

1. **Give teammates enough context** in the spawn prompt (they don't inherit conversation history)
2. **Appropriate team size**: 3-5 teammates for most workflows
3. **5-6 tasks per teammate** keeps everyone productive
4. **Size tasks appropriately**: not too small (coordination overhead), not too large (risk of wasted effort)
5. **Start with research and review** if new to agent teams
6. **Avoid file conflicts**: each teammate owns different files
7. **Monitor and steer**: check in on progress

## Limitations (experimental)

- No session resumption with in-process teammates
- Task status can lag (sometimes fails to mark completed)
- Shutdown can be slow
- One team per session
- No nested teams (teammates cannot spawn their own teams)
- Lead is fixed (cannot promote a teammate)
- Permissions set at spawn (cannot set per-teammate modes at spawn time)
- Split panes require tmux or iTerm2 (not VS Code, Windows Terminal, Ghostty)

## Token usage

Each teammate has its own context window. Token usage scales linearly with team size. See agent team token costs documentation.
