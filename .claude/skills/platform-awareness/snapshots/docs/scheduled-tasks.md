<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/scheduled-tasks.md -->

# Run prompts on a schedule

> Use /loop and the cron scheduling tools to run prompts repeatedly, poll for status, or set one-time reminders within a Claude Code session.

Requires Claude Code v2.1.72 or later.

Tasks are **session-scoped**: they live in the current Claude Code process and are gone when you exit.

## Compare scheduling options

| | Cloud | Desktop | `/loop` |
| :-- | :---- | :------ | :------ |
| Runs on | Anthropic cloud | Your machine | Your machine |
| Requires machine on | No | Yes | Yes |
| Requires open session | No | No | Yes |
| Persistent across restarts | Yes | Yes | No |
| Access to local files | No (fresh clone) | Yes | Yes |
| MCP servers | Connectors per task | Config files + connectors | Inherits from session |
| Minimum interval | 1 hour | 1 minute | 1 minute |

## Schedule a recurring prompt with /loop

```text
/loop 5m check if the deployment finished and tell me what happened
```

### Interval syntax

| Form | Example | Parsed interval |
| :--- | :------ | :-------------- |
| Leading token | `/loop 30m check the build` | every 30 minutes |
| Trailing `every` clause | `/loop check the build every 2 hours` | every 2 hours |
| No interval | `/loop check the build` | defaults to every 10 minutes |

Supported units: `s` (seconds), `m` (minutes), `h` (hours), `d` (days).

### Loop over another command

```text
/loop 20m /review-pr 1234
```

## Set a one-time reminder

```text
remind me at 3pm to push the release branch
in 45 minutes, check whether the integration tests passed
```

## Manage scheduled tasks

```text
what scheduled tasks do I have?
cancel the deploy check job
```

### Underlying tools

| Tool | Purpose |
| :--- | :------ |
| `CronCreate` | Schedule a new task. Accepts 5-field cron expression, prompt, and recurs/one-shot flag. |
| `CronList` | List all scheduled tasks with IDs, schedules, and prompts. |
| `CronDelete` | Cancel a task by ID. |

Max 50 scheduled tasks per session.

## How scheduled tasks run

- Scheduler checks every second for due tasks
- Tasks fire between your turns, not while Claude is mid-response
- If Claude is busy when a task comes due, prompt waits until current turn ends
- All times interpreted in **local timezone**

### Jitter

- Recurring tasks fire up to 10% of their period late (max 15 minutes)
- One-shot tasks scheduled for top/bottom of hour fire up to 90 seconds early
- Offset derived from task ID (same task always gets same offset)

### Three-day expiry

Recurring tasks automatically expire 3 days after creation. The task fires once more, then deletes itself.

## Cron expression reference

Standard 5-field format: `minute hour day-of-month month day-of-week`

| Example | Meaning |
| :------ | :------ |
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour on the hour |
| `7 * * * *` | Every hour at 7 minutes past |
| `0 9 * * *` | Every day at 9am local |
| `0 9 * * 1-5` | Weekdays at 9am local |
| `30 14 15 3 *` | March 15 at 2:30pm local |

Day-of-week: `0` or `7` = Sunday, `6` = Saturday.
Extended syntax (`L`, `W`, `?`, `MON`) NOT supported.

## Disable scheduled tasks

Set `CLAUDE_CODE_DISABLE_CRON=1` to disable the scheduler entirely.

## Limitations

- Tasks only fire while Claude Code is running and idle
- No catch-up for missed fires (fires once when Claude becomes idle)
- No persistence across restarts

For durable scheduling:
- Cloud scheduled tasks (Anthropic-managed infrastructure)
- GitHub Actions (schedule trigger in CI)
- Desktop scheduled tasks (run locally, persists across restarts)
