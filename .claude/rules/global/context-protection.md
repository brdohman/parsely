# Context Protection Rules

✅ **Run agents in FOREGROUND (no `run_in_background`).** Agents return a minimal result directly (~1-5 tokens: "DONE", "PASS", or "FAIL"). All details go into task metadata comments. No polling needed.

⛔ NEVER call TaskOutput — it injects ~8K tokens of agent transcript per call.

✅ **For context/status checks:** Use `.claude/scripts/task` CLI (~50 tokens per call).
  - `task summary` — overview of all tasks
  - `task field [id] [jq-path]` — read any metadata field
  - `task check [id]` — quick status check
  Run `.claude/scripts/task help` for all commands. Prefer over TaskGet (~500 tokens/call).

⛔ The coordinator must NOT read or edit source code files (.swift, .xib, .storyboard).
Delegate all source file operations to agents. The coordinator orchestrates — it does not implement.

⚠️ Do NOT read progress.md for status checks mid-session. Use `.claude/scripts/task summary` for project status.
Only read progress.md at epic start (to confirm phase status) and epic end (to update completion).

⚠️ Before starting a new epic, check stale task file count:
`ls ~/.claude/tasks/${CLAUDE_CODE_TASK_LIST_ID}/*.json 2>/dev/null | wc -l`
If >20 files exist from a prior epic, remind the user to clear old tasks first.
Accumulated task files inflate every TaskList/TaskGet call.
