# Agent Teams Setup & Reference

Agent Teams is an **experimental** Claude Code feature that allows multiple persistent Claude Code instances to work as a coordinated team.

## Setup

### 1. Enable Agent Teams

Add to `~/.claude/settings.json` (user-level, NOT project `.claude/settings.json`):

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or set the environment variable per-session:
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### 2. Verify

Start Claude Code. You should see team-related keyboard shortcuts available (`Shift+Tab` for delegate mode, `Ctrl+T` for task list).

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Shift+Up/Down` | Select teammate |
| `Shift+Tab` | Toggle delegate mode |
| `Ctrl+T` | Toggle task list |
| `Enter` | View selected teammate's session |
| `Escape` | Interrupt teammate |

## When to Use Agent Teams vs Subagents

### Use Agent Teams (`/build-epic-team`) When:
- Building entire epics where teammates benefit from persistent context
- Work requires discussion between agents (e.g., interface contracts)
- You want teammates to learn the codebase as they work through tasks
- Cross-layer coordination is valuable (dev discusses with reviewer)

### Use Subagents (`/build-epic`) When:
- You want proven, stable behavior
- Tasks are independent and don't benefit from discussion
- You prefer explicit coordinator control over self-organization
- Simpler epics with straightforward tasks

### Either Works Fine For:
- Medium-sized epics (10-15 tasks)
- Standard MVVM features
- Typical review cycles

## How Teams Coordinate

1. **Shared Task State:** All teammates read/write Claude Tasks. A dev marks a task complete, the reviewer sees it appear in their queue.
2. **Peer Messaging:** Teammates can message each other directly. A dev can ask another dev about an interface, or a reviewer can flag something for QA.
3. **Self-Claiming:** Teammates find available work via TaskList and claim it via TaskUpdate. No coordinator assignment needed.
4. **Delegate Mode:** The lead (you) can enter delegate mode where you only coordinate, not implement.

## Known Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| No session resumption | Can't resume team after closing | Use `/backup` before ending |
| Task status lag | Teammates may not see changes immediately | Nudge teammates to re-check |
| One team per session | Can't run multiple teams | Use separate terminals |
| No nested teams | Teammates can't spawn their own teams | They can still use subagents |
| Fixed lead | Can't transfer leadership | Plan accordingly |
| Split panes need tmux/iTerm2 | In-process mode is default | Install tmux if you want split view |

## Fallback Strategy

If Agent Teams becomes unstable mid-epic:
1. All work is persisted in Claude Tasks (task state survives team cleanup)
2. Clean up the team
3. Switch to `/build-epic` to finish remaining work with subagents
4. No work is lost

## Related

- **Team story command:** `.claude/commands/build-story-team.md` (start here to test teams)
- **Team epic command:** `.claude/commands/build-epic-team.md`
- **Subagent story command:** `.claude/commands/build-story.md`
- **Subagent epic command:** `.claude/commands/build-epic.md`
- **Subagent patterns:** `.claude/skills/workflow/spawn-subagents/SKILL.md`
