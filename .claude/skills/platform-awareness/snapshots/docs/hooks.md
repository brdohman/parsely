<\!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/hooks.md -->
     1→# Hooks Reference - Complete Documentation
     2→
     3→## Documentation Index
     4→Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
     5→
     6→# Hooks reference
     7→
     8→Reference for Claude Code hook events, configuration schema, JSON input/output formats, exit codes, async hooks, HTTP hooks, prompt hooks, and MCP tool hooks.
     9→
    10→> For a quickstart guide with examples, see [Automate workflows with hooks](/en/hooks-guide).
    11→
    12→Hooks are user-defined shell commands, HTTP endpoints, or LLM prompts that execute automatically at specific points in Claude Code's lifecycle. Use this reference to look up event schemas, configuration options, JSON input/output formats, and advanced features like async hooks, HTTP hooks, and MCP tool hooks. If you're setting up hooks for the first time, start with the [guide](/en/hooks-guide) instead.
    13→
    14→## Hook lifecycle
    15→
    16→Hooks fire at specific points during a Claude Code session. When an event fires and a matcher matches, Claude Code passes JSON context about the event to your hook handler. For command hooks, input arrives on stdin. For HTTP hooks, it arrives as the POST request body. Your handler can then inspect the input, take action, and optionally return a decision. Some events fire once per session, while others fire repeatedly inside the agentic loop.
    17→
    18→[Hook lifecycle diagram showing: SessionStart → PreToolUse, PermissionRequest, PostToolUse, SubagentStart/Stop, TaskCreated, TaskCompleted → Stop or StopFailure → TeammateIdle, PreCompact, PostCompact, SessionEnd, plus async events like WorktreeCreate/Remove, Notification, ConfigChange, InstructionsLoaded, CwdChanged, FileChanged]
    19→
    20→The table below summarizes when each event fires. The [Hook events](#hook-events) section documents the full input schema and decision control options for each one.
    21→
    22→| Event                | When it fires                                                                                                                                          |
    23→| :------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
    24→| `SessionStart`       | When a session begins or resumes                                                                                                                       |
    25→| `UserPromptSubmit`   | When you submit a prompt, before Claude processes it                                                                                                   |
    26→| `PreToolUse`         | Before a tool call executes. Can block it                                                                                                              |
    27→| `PermissionRequest`  | When a permission dialog appears                                                                                                                       |
    28→| `PostToolUse`        | After a tool call succeeds                                                                                                                             |
    29→| `PostToolUseFailure` | After a tool call fails                                                                                                                                |
    30→| `Notification`       | When Claude Code sends a notification                                                                                                                  |
    31→| `SubagentStart`      | When a subagent is spawned                                                                                                                             |
    32→| `SubagentStop`       | When a subagent finishes                                                                                                                               |
    33→| `TaskCreated`        | When a task is being created via `TaskCreate`                                                                                                          |
    34→| `TaskCompleted`      | When a task is being marked as completed                                                                                                               |
    35→| `Stop`               | When Claude finishes responding                                                                                                                        |
    36→| `StopFailure`        | When the turn ends due to an API error. Output and exit code are ignored                                                                               |
    37→| `TeammateIdle`       | When an [agent team](/en/agent-teams) teammate is about to go idle                                                                                     |
    38→| `InstructionsLoaded` | When a CLAUDE.md or `.claude/rules/*.md` file is loaded into context. Fires at session start and when files are lazily loaded during a session         |
    39→| `ConfigChange`       | When a configuration file changes during a session                                                                                                     |
    40→| `CwdChanged`         | When the working directory changes, for example when Claude executes a `cd` command. Useful for reactive environment management with tools like direnv |
    41→| `FileChanged`        | When a watched file changes on disk. The `matcher` field specifies which filenames to watch                                                            |
    42→| `WorktreeCreate`     | When a worktree is being created via `--worktree` or `isolation: "worktree"`. Replaces default git behavior                                            |
    43→| `WorktreeRemove`     | When a worktree is being removed, either at session exit or when a subagent finishes                                                                   |
    44→| `PreCompact`         | Before context compaction                                                                                                                              |
    45→| `PostCompact`        | After context compaction completes                                                                                                                     |
    46→| `Elicitation`        | When an MCP server requests user input during a tool call                                                                                              |
    47→| `ElicitationResult`  | After a user responds to an MCP elicitation, before the response is sent back to the server                                                            |
    48→| `SessionEnd`         | When a session terminates                                                                                                                              |
    49→
    50→### How a hook resolves
    51→
    52→To see how these pieces fit together, consider this `PreToolUse` hook that blocks destructive shell commands. The `matcher` narrows to Bash tool calls and the `if` condition narrows further to commands starting with `rm`, so `block-rm.sh` only spawns when both filters match:
    53→
    54→```json
    55→{
    56→  "hooks": {
    57→    "PreToolUse": [
    58→      {
    59→        "matcher": "Bash",
    60→        "hooks": [
    61→          {
    62→            "type": "command",
    63→            "if": "Bash(rm *)",
    64→            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm.sh"
    65→          }
    66→        ]
    67→      }
    68→    ]
    69→  }
    70→}
    71→```
    72→
    73→The script reads the JSON input from stdin, extracts the command, and returns a `permissionDecision` of `"deny"` if it contains `rm -rf`:
    74→
    75→```bash
    76→#!/bin/bash
    77→# .claude/hooks/block-rm.sh
    78→COMMAND=$(jq -r '.tool_input.command')
    79→
    80→if echo "$COMMAND" | grep -q 'rm -rf'; then
    81→  jq -n '{
    82→    hookSpecificOutput: {
    83→      hookEventName: "PreToolUse",
    84→      permissionDecision: "deny",
    85→      permissionDecisionReason: "Destructive command blocked by hook"
    86→    }
    87→  }'
    88→else
    89→  exit 0  # allow the command
    90→fi
    91→```
    92→
    93→Now suppose Claude Code decides to run `Bash "rm -rf /tmp/build"`. Here's what happens:
    94→
    95→**Hook resolution flow:**
    96→
    97→1. **Event fires**: The `PreToolUse` event fires. Claude Code sends the tool input as JSON on stdin to the hook:
    98→```json
    99→{ "tool_name": "Bash", "tool_input": { "command": "rm -rf /tmp/build" }, ... }
   100→```
   101→
   102→2. **Matcher checks**: The matcher `"Bash"` matches the tool name, so this hook group activates. If you omit the matcher or use `"*"`, the group activates on every occurrence of the event.
   103→
   104→3. **If condition checks**: The `if` condition `"Bash(rm *)"` matches because the command starts with `rm`, so this handler spawns. If the command had been `npm test`, the `if` check would fail and `block-rm.sh` would never run, avoiding the process spawn overhead. The `if` field is optional; without it, every handler in the matched group runs.
   105→
   106→4. **Hook handler runs**: The script inspects the full command and finds `rm -rf`, so it prints a decision to stdout:
   107→```json
   108→{
   109→  "hookSpecificOutput": {
   110→    "hookEventName": "PreToolUse",
   111→    "permissionDecision": "deny",
   112→    "permissionDecisionReason": "Destructive command blocked by hook"
   113→  }
   114→}
   115→```
   116→If the command had been a safer `rm` variant like `rm file.txt`, the script would hit `exit 0` instead, which tells Claude Code to allow the tool call with no further action.
   117→
   118→5. **Claude Code acts on the result**: Claude Code reads the JSON decision, blocks the tool call, and shows Claude the reason.
   119→
   120→The [Configuration](#configuration) section below documents the full schema, and each [hook event](#hook-events) section documents what input your command receives and what output it can return.
   121→
   122→## Configuration
   123→
   124→Hooks are defined in JSON settings files. The configuration has three levels of nesting:
   125→
   126→1. Choose a [hook event](#hook-events) to respond to, like `PreToolUse` or `Stop`
   127→2. Add a [matcher group](#matcher-patterns) to filter when it fires, like "only for the Bash tool"
   128→3. Define one or more [hook handlers](#hook-handler-fields) to run when matched
   129→
   130→See [How a hook resolves](#how-a-hook-resolves) above for a complete walkthrough with an annotated example.
   131→
   132→> This page uses specific terms for each level: **hook event** for the lifecycle point, **matcher group** for the filter, and **hook handler** for the shell command, HTTP endpoint, prompt, or agent that runs. "Hook" on its own refers to the general feature.
   133→
   134→### Hook locations
   135→
   136→Where you define a hook determines its scope:
   137→
   138→| Location                                                   | Scope                         | Shareable                          |
   139→| :--------------------------------------------------------- | :---------------------------- | :--------------------------------- |
   140→| `~/.claude/settings.json`                                  | All your projects             | No, local to your machine          |
   141→| `.claude/settings.json`                                    | Single project                | Yes, can be committed to the repo  |
   142→| `.claude/settings.local.json`                              | Single project                | No, gitignored                     |
   143→| Managed policy settings                                    | Organization-wide             | Yes, admin-controlled              |
   144→| [Plugin](/en/plugins) `hooks/hooks.json`                   | When plugin is enabled        | Yes, bundled with the plugin       |
   145→| [Skill](/en/skills) or [agent](/en/sub-agents) frontmatter | While the component is active | Yes, defined in the component file |
   146→
   147→For details on settings file resolution, see [settings](/en/settings). Enterprise administrators can use `allowManagedHooksOnly` to block user, project, and plugin hooks. See [Hook configuration](/en/settings#hook-configuration).
   148→
   149→### Matcher patterns
   150→
   151→The `matcher` field is a regex string that filters when hooks fire. Use `"*"`, `""`, or omit `matcher` entirely to match all occurrences. Each event type matches on a different field:
   152→
   153→| Event                                                                                                          | What the matcher filters                | Example matcher values                                                                                                    |
   154→| :------------------------------------------------------------------------------------------------------------- | :-------------------------------------- | :------------------------------------------------------------------------------------------------------------------------ |
   155→| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`                                         | tool name                               | `Bash`, `Edit\|Write`, `mcp__.*`                                                                                          |
   156→| `SessionStart`                                                                                                 | how the session started                 | `startup`, `resume`, `clear`, `compact`                                                                                   |
   157→| `SessionEnd`                                                                                                   | why the session ended                   | `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`                                  |
   158→| `Notification`                                                                                                 | notification type                       | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`                                                  |
   159→| `SubagentStart`                                                                                                | agent type                              | `Bash`, `Explore`, `Plan`, or custom agent names                                                                          |
   160→| `PreCompact`, `PostCompact`                                                                                    | what triggered compaction               | `manual`, `auto`                                                                                                          |
   161→| `SubagentStop`                                                                                                 | agent type                              | same values as `SubagentStart`                                                                                            |
   162→| `ConfigChange`                                                                                                 | configuration source                    | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`                                        |
   163→| `CwdChanged`                                                                                                   | no matcher support                      | always fires on every directory change                                                                                    |
   164→| `FileChanged`                                                                                                  | filename (basename of the changed file) | `.envrc`, `.env`, any filename you want to watch                                                                          |
   165→| `StopFailure`                                                                                                  | error type                              | `rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, `unknown` |
   166→| `InstructionsLoaded`                                                                                           | load reason                             | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`                                              |
   167→| `Elicitation`                                                                                                  | MCP server name                         | your configured MCP server names                                                                                          |
   168→| `ElicitationResult`                                                                                            | MCP server name                         | same values as `Elicitation`                                                                                              |
   169→| `UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove` | no matcher support                      | always fires on every occurrence                                                                                          |
   170→
   171→The matcher is a regex, so `Edit|Write` matches either tool and `Notebook.*` matches any tool starting with Notebook. The matcher runs against a field from the [JSON input](#hook-input-and-output) that Claude Code sends to your hook on stdin. For tool events, that field is `tool_name`. Each [hook event](#hook-events) section lists the full set of matcher values and the input schema for that event.
   172→
   173→This example runs a linting script only when Claude writes or edits a file:
   174→
   175→```json
   176→{
   177→  "hooks": {
   178→    "PostToolUse": [
   179→      {
   180→        "matcher": "Edit|Write",
   181→        "hooks": [
   182→          {
   183→            "type": "command",
   184→            "command": "/path/to/lint-check.sh"
   185→          }
   186→        ]
   187→      }
   188→    ]
   189→  }
   190→}
   191→```
   192→
   193→`UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, and `CwdChanged` don't support matchers and always fire on every occurrence. If you add a `matcher` field to these events, it is silently ignored.
   194→
   195→For tool events, you can filter more narrowly by setting the [`if` field](#common-fields) on individual hook handlers. `if` uses [permission rule syntax](/en/permissions) to match against the tool name and arguments together, so `"Bash(git *)"` runs only for `git` commands and `"Edit(*.ts)"` runs only for TypeScript files.
   196→
   197→#### Match MCP tools
   198→
   199→[MCP](/en/mcp) server tools appear as regular tools in tool events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`), so you can match them the same way you match any other tool name.
   200→
   201→MCP tools follow the naming pattern `mcp__<server>__<tool>`, for example:
   202→
   203→* `mcp__memory__create_entities`: Memory server's create entities tool
   204→* `mcp__filesystem__read_file`: Filesystem server's read file tool
   205→* `mcp__github__search_repositories`: GitHub server's search tool
   206→
   207→Use regex patterns to target specific MCP tools or groups of tools:
   208→
   209→* `mcp__memory__.*` matches all tools from the `memory` server
   210→* `mcp__.*__write.*` matches any tool containing "write" from any server
   211→
   212→This example logs all memory server operations and validates write operations from any MCP server:
   213→
   214→```json
   215→{
   216→  "hooks": {
   217→    "PreToolUse": [
   218→      {
   219→        "matcher": "mcp__memory__.*",
   220→        "hooks": [
   221→          {
   222→            "type": "command",
   223→            "command": "echo 'Memory operation initiated' >> ~/mcp-operations.log"
   224→          }
   225→        ]
   226→      },
   227→      {
   228→        "matcher": "mcp__.*__write.*",
   229→        "hooks": [
   230→          {
   231→            "type": "command",
   232→            "command": "/home/user/scripts/validate-mcp-write.py"
   233→          }
   234→        ]
   235→      }
   236→    ]
   237→  }
   238→}
   239→```
   240→
   241→### Hook handler fields
   242→
   243→Each object in the inner `hooks` array is a hook handler: the shell command, HTTP endpoint, LLM prompt, or agent that runs when the matcher matches. There are four types:
   244→
   245→* **[Command hooks](#command-hook-fields)** (`type: "command"`): run a shell command. Your script receives the event's [JSON input](#hook-input-and-output) on stdin and communicates results back through exit codes and stdout.
   246→* **[HTTP hooks](#http-hook-fields)** (`type: "http"`): send the event's JSON input as an HTTP POST request to a URL. The endpoint communicates results back through the response body using the same [JSON output format](#json-output) as command hooks.
   247→* **[Prompt hooks](#prompt-and-agent-hook-fields)** (`type: "prompt"`): send a prompt to a Claude model for single-turn evaluation. The model returns a yes/no decision as JSON. See [Prompt-based hooks](#prompt-based-hooks).
   248→* **[Agent hooks](#prompt-and-agent-hook-fields)** (`type: "agent"`): spawn a subagent that can use tools like Read, Grep, and Glob to verify conditions before returning a decision. See [Agent-based hooks](#agent-based-hooks).
   249→
   250→#### Common fields
   251→
   252→These fields apply to all hook types:
   253→
   254→| Field           | Required | Description                                                                                                                                                                                                                                                                                                                                                                          |
   255→| :-------------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   256→| `type`          | yes      | `"command"`, `"http"`, `"prompt"`, or `"agent"`                                                                                                                                                                                                                                                                                                                                      |
   257→| `if`            | no       | Permission rule syntax to filter when this hook runs, such as `"Bash(git *)"` or `"Edit(*.ts)"`. The hook only spawns if the tool call matches the pattern. Only evaluated on tool events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, and `PermissionRequest`. On other events, a hook with `if` set never runs. Uses the same syntax as [permission rules](/en/permissions) |
   258→| `timeout`       | no       | Seconds before canceling. Defaults: 600 for command, 30 for prompt, 60 for agent                                                                                                                                                                                                                                                                                                     |
   259→| `statusMessage` | no       | Custom spinner message displayed while the hook runs                                                                                                                                                                                                                                                                                                                                 |
   260→| `once`          | no       | If `true`, runs only once per session then is removed. Skills only, not agents. See [Hooks in skills and agents](#hooks-in-skills-and-agents)                                                                                                                                                                                                                                        |
   261→
   262→#### Command hook fields
   263→
   264→In addition to the [common fields](#common-fields), command hooks accept these fields:
   265→
   266→| Field     | Required | Description                                                                                                                                                                                                                           |
   267→| :-------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   268→| `command` | yes      | Shell command to execute                                                                                                                                                                                                              |
   269→| `async`   | no       | If `true`, runs in the background without blocking. See [Run hooks in the background](#run-hooks-in-the-background)                                                                                                                   |
   270→| `shell`   | no       | Shell to use for this hook. Accepts `"bash"` (default) or `"powershell"`. Setting `"powershell"` runs the command via PowerShell on Windows. Does not require `CLAUDE_CODE_USE_POWERSHELL_TOOL` since hooks spawn PowerShell directly |
   271→
   272→#### HTTP hook fields
   273→
   274→In addition to the [common fields](#common-fields), HTTP hooks accept these fields:
   275→
   276→| Field            | Required | Description                                                                                                                                                                                      |
   277→| :--------------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   278→| `url`            | yes      | URL to send the POST request to                                                                                                                                                                  |
   279→| `headers`        | no       | Additional HTTP headers as key-value pairs. Values support environment variable interpolation using `$VAR_NAME` or `${VAR_NAME}` syntax. Only variables listed in `allowedEnvVars` are resolved  |
   280→| `allowedEnvVars` | no       | List of environment variable names that may be interpolated into header values. References to unlisted variables are replaced with empty strings. Required for any env var interpolation to work |
   281→
   282→Claude Code sends the hook's [JSON input](#hook-input-and-output) as the POST request body with `Content-Type: application/json`. The response body uses the same [JSON output format](#json-output) as command hooks.
   283→
   284→Error handling differs from command hooks: non-2xx responses, connection failures, and timeouts all produce non-blocking errors that allow execution to continue. To block a tool call or deny a permission, return a 2xx response with a JSON body containing `decision: "block"` or a `hookSpecificOutput` with `permissionDecision: "deny"`.
   285→
   286→This example sends `PreToolUse` events to a local validation service, authenticating with a token from the `MY_TOKEN` environment variable:
   287→
   288→```json
   289→{
   290→  "hooks": {
   291→    "PreToolUse": [
   292→      {
   293→        "matcher": "Bash",
   294→        "hooks": [
   295→          {
   296→            "type": "http",
   297→            "url": "http://localhost:8080/hooks/pre-tool-use",
   298→            "timeout": 30,
   299→            "headers": {
   300→              "Authorization": "Bearer $MY_TOKEN"
   301→            },
   302→            "allowedEnvVars": ["MY_TOKEN"]
   303→          }
   304→        ]
   305→      }
   306→    ]
   307→  }
   308→}
   309→```
   310→
   311→#### Prompt and agent hook fields
   312→
   313→In addition to the [common fields](#common-fields), prompt and agent hooks accept these fields:
   314→
   315→| Field    | Required | Description                                                                                 |
   316→| :------- | :------- | :------------------------------------------------------------------------------------------ |
   317→| `prompt` | yes      | Prompt text to send to the model. Use `$ARGUMENTS` as a placeholder for the hook input JSON |
   318→| `model`  | no       | Model to use for evaluation. Defaults to a fast model                                       |
   319→
   320→All matching hooks run in parallel, and identical handlers are deduplicated automatically. Command hooks are deduplicated by command string, and HTTP hooks are deduplicated by URL. Handlers run in the current directory with Claude Code's environment. The `$CLAUDE_CODE_REMOTE` environment variable is set to `"true"` in remote web environments and not set in the local CLI.
   321→
   322→### Reference scripts by path
   323→
   324→Use environment variables to reference hook scripts relative to the project or plugin root, regardless of the working directory when the hook runs:
   325→
   326→* `$CLAUDE_PROJECT_DIR`: the project root. Wrap in quotes to handle paths with spaces.
   327→* `${CLAUDE_PLUGIN_ROOT}`: the plugin's installation directory, for scripts bundled with a [plugin](/en/plugins). Changes on each plugin update.
   328→* `${CLAUDE_PLUGIN_DATA}`: the plugin's [persistent data directory](/en/plugins-reference#persistent-data-directory), for dependencies and state that should survive plugin updates.
   329→
   330→**Project scripts example:**
   331→This example uses `$CLAUDE_PROJECT_DIR` to run a style checker from the project's `.claude/hooks/` directory after any `Write` or `Edit` tool call:
   332→
   333→```json
   334→{
   335→  "hooks": {
   336→    "PostToolUse": [
   337→      {
   338→        "matcher": "Write|Edit",
   339→        "hooks": [
   340→          {
   341→            "type": "command",
   342→            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh"
   343→          }
   344→        ]
   345→      }
   346→    ]
   347→  }
   348→}
   349→```
   350→
   351→**Plugin scripts example:**
   352→Define plugin hooks in `hooks/hooks.json` with an optional top-level `description` field. When a plugin is enabled, its hooks merge with your user and project hooks.
   353→
   354→This example runs a formatting script bundled with the plugin:
   355→
   356→```json
   357→{
   358→  "description": "Automatic code formatting",
   359→  "hooks": {
   360→    "PostToolUse": [
   361→      {
   362→        "matcher": "Write|Edit",
   363→        "hooks": [
   364→          {
   365→            "type": "command",
   366→            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
   367→            "timeout": 30
   368→          }
   369→        ]
   370→      }
   371→    ]
   372→  }
   373→}
   374→```
   375→
   376→See the [plugin components reference](/en/plugins-reference#hooks) for details on creating plugin hooks.
   377→
   378→### Hooks in skills and agents
   379→
   380→In addition to settings files and plugins, hooks can be defined directly in [skills](/en/skills) and [subagents](/en/sub-agents) using frontmatter. These hooks are scoped to the component's lifecycle and only run when that component is active.
   381→
   382→All hook events are supported. For subagents, `Stop` hooks are automatically converted to `SubagentStop` since that is the event that fires when a subagent completes.
   383→
   384→Hooks use the same configuration format as settings-based hooks but are scoped to the component's lifetime and cleaned up when it finishes.
   385→
   386→This skill defines a `PreToolUse` hook that runs a security validation script before each `Bash` command:
   387→
   388→```yaml
   389→---
   390→name: secure-operations
   391→description: Perform operations with security checks
   392→hooks:
   393→  PreToolUse:
   394→    - matcher: "Bash"
   395→      hooks:
   396→        - type: command
   397→          command: "./scripts/security-check.sh"
   398→---
   399→```
   400→
   401→Agents use the same format in their YAML frontmatter.
   402→
   403→### The `/hooks` menu
   404→
   405→Type `/hooks` in Claude Code to open a read-only browser for your configured hooks. The menu shows every hook event with a count of configured hooks, lets you drill into matchers, and shows the full details of each hook handler. Use it to verify configuration, check which settings file a hook came from, or inspect a hook's command, prompt, or URL.
   406→
   407→The menu displays all four hook types: `command`, `prompt`, `agent`, and `http`. Each hook is labeled with a `[type]` prefix and a source indicating where it was defined:
   408→
   409→* `User`: from `~/.claude/settings.json`
   410→* `Project`: from `.claude/settings.json`
   411→* `Local`: from `.claude/settings.local.json`
   412→* `Plugin`: from a plugin's `hooks/hooks.json`
   413→* `Session`: registered in memory for the current session
   414→* `Built-in`: registered internally by Claude Code
   415→
   416→Selecting a hook opens a detail view showing its event, matcher, type, source file, and the full command, prompt, or URL. The menu is read-only: to add, modify, or remove hooks, edit the settings JSON directly or ask Claude to make the change.
   417→
   418→### Disable or remove hooks
   419→
   420→To remove a hook, delete its entry from the settings JSON file.
   421→
   422→To temporarily disable all hooks without removing them, set `"disableAllHooks": true` in your settings file. There is no way to disable an individual hook while keeping it in the configuration.
   423→
   424→The `disableAllHooks` setting respects the managed settings hierarchy. If an administrator has configured hooks through managed policy settings, `disableAllHooks` set in user, project, or local settings cannot disable those managed hooks. Only `disableAllHooks` set at the managed settings level can disable managed hooks.
   425→
   426→Direct edits to hooks in settings files are normally picked up automatically by the file watcher.
   427→
   428→## Hook input and output
   429→
   430→Command hooks receive JSON data via stdin and communicate results through exit codes, stdout, and stderr. HTTP hooks receive the same JSON as the POST request body and communicate results through the HTTP response body. This section covers fields and behavior common to all events. Each event's section under [Hook events](#hook-events) includes its specific input schema and decision control options.
   431→
   432→### Common input fields
   433→
   434→Hook events receive these fields as JSON, in addition to event-specific fields documented in each [hook event](#hook-events) section. For command hooks, this JSON arrives via stdin. For HTTP hooks, it arrives as the POST request body.
   435→
   436→| Field             | Description                                                                                                                                                                                                                           |
   437→| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   438→| `session_id`      | Current session identifier                                                                                                                                                                                                            |
   439→| `transcript_path` | Path to conversation JSON                                                                                                                                                                                                             |
   440→| `cwd`             | Current working directory when the hook is invoked                                                                                                                                                                                    |
   441→| `permission_mode` | Current [permission mode](/en/permissions#permission-modes): `"default"`, `"plan"`, `"acceptEdits"`, `"auto"`, `"dontAsk"`, or `"bypassPermissions"`. Not all events receive this field: see each event's JSON example below to check |
   442→| `hook_event_name` | Name of the event that fired                                                                                                                                                                                                          |
   443→
   444→When running with `--agent` or inside a subagent, two additional fields are included:
   445→
   446→| Field        | Description                                                                                                                                                                                                                          |
   447→| :----------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   448→| `agent_id`   | Unique identifier for the subagent. Present only when the hook fires inside a subagent call. Use this to distinguish subagent hook calls from main-thread calls.                                                                     |
   449→| `agent_type` | Agent name (for example, `"Explore"` or `"security-reviewer"`). Present when the session uses `--agent` or the hook fires inside a subagent. For subagents, the subagent's type takes precedence over the session's `--agent` value. |
   450→
   451→For example, a `PreToolUse` hook for a Bash command receives this on stdin:
   452→
   453→```json
   454→{
   455→  "session_id": "abc123",
   456→  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
   457→  "cwd": "/home/user/my-project",
   458→  "permission_mode": "default",
   459→  "hook_event_name": "PreToolUse",
   460→  "tool_name": "Bash",
   461→  "tool_input": {
   462→    "command": "npm test"
   463→  }
   464→}
   465→```
   466→
   467→The `tool_name` and `tool_input` fields are event-specific. Each [hook event](#hook-events) section documents the additional fields for that event.
   468→
   469→### Exit code output
   470→
   471→The exit code from your hook command tells Claude Code whether the action should proceed, be blocked, or be ignored.
   472→
   473→**Exit 0** means success. Claude Code parses stdout for [JSON output fields](#json-output). JSON output is only processed on exit 0. For most events, stdout is only shown in verbose mode (`Ctrl+O`). The exceptions are `UserPromptSubmit` and `SessionStart`, where stdout is added as context that Claude can see and act on.
   474→
   475→**Exit 2** means a blocking error. Claude Code ignores stdout and any JSON in it. Instead, stderr text is fed back to Claude as an error message. The effect depends on the event: `PreToolUse` blocks the tool call, `UserPromptSubmit` rejects the prompt, and so on. See [exit code 2 behavior](#exit-code-2-behavior-per-event) for the full list.
   476→
   477→**Any other exit code** is a non-blocking error. stderr is shown in verbose mode (`Ctrl+O`) and execution continues.
   478→
   479→For example, a hook command script that blocks dangerous Bash commands:
   480→
   481→```bash
   482→#!/bin/bash
   483→# Reads JSON input from stdin, checks the command
   484→command=$(jq -r '.tool_input.command' < /dev/stdin)
   485→
   486→if [[ "$command" == rm* ]]; then
   487→  echo "Blocked: rm commands are not allowed" >&2
   488→  exit 2  # Blocking error: tool call is prevented
   489→fi
   490→
   491→exit 0  # Success: tool call proceeds
   492→```
   493→
   494→#### Exit code 2 behavior per event
   495→
   496→Exit code 2 is the way a hook signals "stop, don't do this." The effect depends on the event, because some events represent actions that can be blocked (like a tool call that hasn't happened yet) and others represent things that already happened or can't be prevented.
   497→
   498→| Hook event           | Can block? | What happens on exit 2                                                        |
   499→| :------------------- | :--------- | :---------------------------------------------------------------------------- |
   500→| `PreToolUse`         | Yes        | Blocks the tool call                                                          |
   501→| `PermissionRequest`  | Yes        | Denies the permission                                                         |
   502→| `UserPromptSubmit`   | Yes        | Blocks prompt processing and erases the prompt                                |
   503→| `Stop`               | Yes        | Prevents Claude from stopping, continues the conversation                     |
   504→| `SubagentStop`       | Yes        | Prevents the subagent from stopping                                           |
   505→| `TeammateIdle`       | Yes        | Prevents the teammate from going idle (teammate continues working)            |
   506→| `TaskCreated`        | Yes        | Prevents the task from being created                                          |
   507→| `TaskCompleted`      | Yes        | Prevents the task from being marked as completed                              |
   508→| `ConfigChange`       | Yes        | Blocks the configuration change from taking effect (except `policy_settings`) |
   509→| `StopFailure`        | No         | Output and exit code are ignored                                              |
   510→| `PostToolUse`        | No         | Shows stderr to Claude (tool already ran)                                     |
   511→| `PostToolUseFailure` | No         | Shows stderr to Claude (tool already failed)                                  |
   512→| `Notification`       | No         | Shows stderr to user only                                                     |
   513→| `SubagentStart`      | No         | Shows stderr to user only                                                     |
   514→| `SessionStart`       | No         | Shows stderr to user only                                                     |
   515→| `SessionEnd`         | No         | Shows stderr to user only                                                     |
   516→| `CwdChanged`         | No         | Shows stderr to user only                                                     |
   517→| `FileChanged`        | No         | Shows stderr to user only                                                     |
   518→| `PreCompact`         | No         | Shows stderr to user only                                                     |
   519→| `PostCompact`        | No         | Shows stderr to user only                                                     |
   520→| `Elicitation`        | Yes        | Denies the elicitation                                                        |
   521→| `ElicitationResult`  | Yes        | Blocks the response (action becomes decline)                                  |
   522→| `WorktreeCreate`     | Yes        | Any non-zero exit code causes worktree creation to fail                       |
   523→| `WorktreeRemove`     | No         | Failures are logged in debug mode only                                        |
   524→| `InstructionsLoaded` | No         | Exit code is ignored                                                          |
   525→
   526→### HTTP response handling
   527→
   528→HTTP hooks use HTTP status codes and response bodies instead of exit codes and stdout:
   529→
   530→* **2xx with an empty body**: success, equivalent to exit code 0 with no output
   531→* **2xx with a plain text body**: success, the text is added as context
   532→* **2xx with a JSON body**: success, parsed using the same [JSON output](#json-output) schema as command hooks
   533→* **Non-2xx status**: non-blocking error, execution continues
   534→* **Connection failure or timeout**: non-blocking error, execution continues
   535→
   536→Unlike command hooks, HTTP hooks cannot signal a blocking error through status codes alone. To block a tool call or deny a permission, return a 2xx response with a JSON body containing the appropriate decision fields.
   537→
   538→### JSON output
   539→
   540→Exit codes let you allow or block, but JSON output gives you finer-grained control. Instead of exiting with code 2 to block, exit 0 and print a JSON object to stdout. Claude Code reads specific fields from that JSON to control behavior, including [decision control](#decision-control) for blocking, allowing, or escalating to the user.
   541→
   542→> You must choose one approach per hook, not both: either use exit codes alone for signaling, or exit 0 and print JSON for structured control. Claude Code only processes JSON on exit 0. If you exit 2, any JSON is ignored.
   543→
   544→Your hook's stdout must contain only the JSON object. If your shell profile prints text on startup, it can interfere with JSON parsing. See [JSON validation failed](/en/hooks-guide#json-validation-failed) in the troubleshooting guide.
   545→
   546→The JSON object supports three kinds of fields:
   547→
   548→* **Universal fields** like `continue` work across all events. These are listed in the table below.
   549→* **Top-level `decision` and `reason`** are used by some events to block or provide feedback.
   550→* **`hookSpecificOutput`** is a nested object for events that need richer control. It requires a `hookEventName` field set to the event name.
   551→
   552→| Field            | Default | Description                                                                                                                |
   553→| :--------------- | :------ | :------------------------------------------------------------------------------------------------------------------------- |
   554→| `continue`       | `true`  | If `false`, Claude stops processing entirely after the hook runs. Takes precedence over any event-specific decision fields |
   555→| `stopReason`     | none    | Message shown to the user when `continue` is `false`. Not shown to Claude                                                  |
   556→| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode output                                                                           |
   557→| `systemMessage`  | none    | Warning message shown to the user                                                                                          |
   558→
   559→To stop Claude entirely regardless of event type:
   560→
   561→```json
   562→{ "continue": false, "stopReason": "Build failed, fix errors before continuing" }
   563→```
   564→
   565→#### Decision control
   566→
   567→Not every event supports blocking or controlling behavior through JSON. The events that do each use a different set of fields to express that decision. Use this table as a quick reference before writing a hook:
   568→
   569→| Events                                                                                                                      | Decision pattern               | Key fields                                                                                                                                                          |
   570→| :-------------------------------------------------------------------------------------------------------------------------- | :----------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   571→| UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop, ConfigChange                                         | Top-level `decision`           | `decision: "block"`, `reason`                                                                                                                                       |
   572→| TeammateIdle, TaskCreated, TaskCompleted                                                                                    | Exit code or `continue: false` | Exit code 2 blocks the action with stderr feedback. JSON `{"continue": false, "stopReason": "..."}` also stops the teammate entirely, matching `Stop` hook behavior |
   573→| PreToolUse                                                                                                                  | `hookSpecificOutput`           | `permissionDecision` (allow/deny/ask), `permissionDecisionReason`                                                                                                   |
   574→| PermissionRequest                                                                                                           | `hookSpecificOutput`           | `decision.behavior` (allow/deny)                                                                                                                                    |
   575→| WorktreeCreate                                                                                                              | path return                    | Command hook prints path on stdout; HTTP hook returns `hookSpecificOutput.worktreePath`. Hook failure or missing path fails creation                                |
   576→| Elicitation                                                                                                                 | `hookSpecificOutput`           | `action` (accept/decline/cancel), `content` (form field values for accept)                                                                                          |
   577→| ElicitationResult                                                                                                           | `hookSpecificOutput`           | `action` (accept/decline/cancel), `content` (form field values override)                                                                                            |
   578→| WorktreeRemove, Notification, SessionEnd, PreCompact, PostCompact, InstructionsLoaded, StopFailure, CwdChanged, FileChanged | None                           | No decision control. Used for side effects like logging or cleanup                                                                                                  |
   579→
   580→Here are examples of each pattern in action:
   581→
   582→**Top-level decision** (used by `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SubagentStop`, and `ConfigChange`). The only value is `"block"`. To allow the action to proceed, omit `decision` from your JSON, or exit 0 without any JSON at all:
   583→
   584→```json
   585→{
   586→  "decision": "block",
   587→  "reason": "Test suite must pass before proceeding"
   588→}
   589→```
   590→
   591→**PreToolUse** (uses `hookSpecificOutput` for richer control: allow, deny, or escalate to the user. You can also modify tool input before it runs or inject additional context for Claude. See [PreToolUse decision control](#pretooluse-decision-control) for the full set of options.):
   592→
   593→```json
   594→{
   595→  "hookSpecificOutput": {
   596→    "hookEventName": "PreToolUse",
   597→    "permissionDecision": "deny",
   598→    "permissionDecisionReason": "Database writes are not allowed"
   599→  }
   600→}
   601→```
   602→
   603→**PermissionRequest** (uses `hookSpecificOutput` to allow or deny a permission request on behalf of the user. When allowing, you can also modify the tool's input or apply permission rules so the user isn't prompted again. See [PermissionRequest decision control](#permissionrequest-decision-control) for the full set of options.):
   604→
   605→```json
   606→{
   607→  "hookSpecificOutput": {
   608→    "hookEventName": "PermissionRequest",
   609→    "decision": {
   610→      "behavior": "allow",
   611→      "updatedInput": {
   612→        "command": "npm run lint"
   613→      }
   614→    }
   615→  }
   616→}
   617→```
   618→
   619→For extended examples including Bash command validation, prompt filtering, and auto-approval scripts, see [What you can automate](/en/hooks-guide#what-you-can-automate) in the guide and the [Bash command validator reference implementation](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py).
   620→
   621→## Hook events
   622→
   623→Each event corresponds to a point in Claude Code's lifecycle where hooks can run. The sections below are ordered to match the lifecycle: from session setup through the agentic loop to session end. Each section describes when the event fires, what matchers it supports, the JSON input it receives, and how to control behavior through output.
   624→
   625→### SessionStart
   626→
   627→Runs when Claude Code starts a new session or resumes an existing session. Useful for loading development context like existing issues or recent changes to your codebase, or setting up environment variables. For static context that does not require a script, use [CLAUDE.md](/en/memory) instead.
   628→
   629→SessionStart runs on every session, so keep these hooks fast. Only `type: "command"` hooks are supported.
   630→
   631→The matcher value corresponds to how the session was initiated:
   632→
   633→| Matcher   | When it fires                          |
   634→| :-------- | :------------------------------------- |
   635→| `startup` | New session                            |
   636→| `resume`  | `--resume`, `--continue`, or `/resume` |
   637→| `clear`   | `/clear`                               |
   638→| `compact` | Auto or manual compaction              |
   639→
   640→#### SessionStart input
   641→
   642→In addition to the [common input fields](#common-input-fields), SessionStart hooks receive `source`, `model`, and optionally `agent_type`. The `source` field indicates how the session started: `"startup"` for new sessions, `"resume"` for resumed sessions, `"clear"` after `/clear`, or `"compact"` after compaction. The `model` field contains the model identifier. If you start Claude Code with `claude --agent <name>`, an `agent_type` field contains the agent name.
   643→
   644→```json
   645→{
   646→  "session_id": "abc123",
   647→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
   648→  "cwd": "/Users/...",
   649→  "hook_event_name": "SessionStart",
   650→  "source": "startup",
   651→  "model": "claude-sonnet-4-6"
   652→}
   653→```
   654→
   655→#### SessionStart decision control
   656→
   657→Any text your hook script prints to stdout is added as context for Claude. In addition to the [JSON output fields](#json-output) available to all hooks, you can return these event-specific fields:
   658→
   659→| Field               | Description                                                               |
   660→| :------------------ | :------------------------------------------------------------------------ |
   661→| `additionalContext` | String added to Claude's context. Multiple hooks' values are concatenated |
   662→
   663→```json
   664→{
   665→  "hookSpecificOutput": {
   666→    "hookEventName": "SessionStart",
   667→    "additionalContext": "My additional context here"
   668→  }
   669→}
   670→```
   671→
   672→#### Persist environment variables
   673→
   674→SessionStart hooks have access to the `CLAUDE_ENV_FILE` environment variable, which provides a file path where you can persist environment variables for subsequent Bash commands.
   675→
   676→To set individual environment variables, write `export` statements to `CLAUDE_ENV_FILE`. Use append (`>>`) to preserve variables set by other hooks:
   677→
   678→```bash
   679→#!/bin/bash
   680→
   681→if [ -n "$CLAUDE_ENV_FILE" ]; then
   682→  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
   683→  echo 'export DEBUG_LOG=true' >> "$CLAUDE_ENV_FILE"
   684→  echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
   685→fi
   686→
   687→exit 0
   688→```
   689→
   690→To capture all environment changes from setup commands, compare the exported variables before and after:
   691→
   692→```bash
   693→#!/bin/bash
   694→
   695→ENV_BEFORE=$(export -p | sort)
   696→
   697→# Run your setup commands that modify the environment
   698→source ~/.nvm/nvm.sh
   699→nvm use 20
   700→
   701→if [ -n "$CLAUDE_ENV_FILE" ]; then
   702→  ENV_AFTER=$(export -p | sort)
   703→  comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
   704→fi
   705→
   706→exit 0
   707→```
   708→
   709→Any variables written to this file will be available in all subsequent Bash commands that Claude Code executes during the session.
   710→
   711→> `CLAUDE_ENV_FILE` is available for SessionStart, [CwdChanged](#cwdchanged), and [FileChanged](#filechanged) hooks. Other hook types do not have access to this variable.
   712→
   713→### InstructionsLoaded
   714→
   715→Fires when a `CLAUDE.md` or `.claude/rules/*.md` file is loaded into context. This event fires at session start for eagerly-loaded files and again later when files are lazily loaded, for example when Claude accesses a subdirectory that contains a nested `CLAUDE.md` or when conditional rules with `paths:` frontmatter match. The hook does not support blocking or decision control. It runs asynchronously for observability purposes.
   716→
   717→The matcher runs against `load_reason`. For example, use `"matcher": "session_start"` to fire only for files loaded at session start, or `"matcher": "path_glob_match|nested_traversal"` to fire only for lazy loads.
   718→
   719→#### InstructionsLoaded input
   720→
   721→In addition to the [common input fields](#common-input-fields), InstructionsLoaded hooks receive these fields:
   722→
   723→| Field               | Description                                                                                                                                                                                                   |
   724→| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   725→| `file_path`         | Absolute path to the instruction file that was loaded                                                                                                                                                         |
   726→| `memory_type`       | Scope of the file: `"User"`, `"Project"`, `"Local"`, or `"Managed"`                                                                                                                                           |
   727→| `load_reason`       | Why the file was loaded: `"session_start"`, `"nested_traversal"`, `"path_glob_match"`, `"include"`, or `"compact"`. The `"compact"` value fires when instruction files are re-loaded after a compaction event |
   728→| `globs`             | Path glob patterns from the file's `paths:` frontmatter, if any. Present only for `path_glob_match` loads                                                                                                     |
   729→| `trigger_file_path` | Path to the file whose access triggered this load, for lazy loads                                                                                                                                             |
   730→| `parent_file_path`  | Path to the parent instruction file that included this one, for `include` loads                                                                                                                               |
   731→
   732→```json
   733→{
   734→  "session_id": "abc123",
   735→  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
   736→  "cwd": "/Users/my-project",
   737→  "hook_event_name": "InstructionsLoaded",
   738→  "file_path": "/Users/my-project/CLAUDE.md",
   739→  "memory_type": "Project",
   740→  "load_reason": "session_start"
   741→}
   742→```
   743→
   744→#### InstructionsLoaded decision control
   745→
   746→InstructionsLoaded hooks have no decision control. They cannot block or modify instruction loading. Use this event for audit logging, compliance tracking, or observability.
   747→
   748→### UserPromptSubmit
   749→
   750→Runs when the user submits a prompt, before Claude processes it. This allows you to add additional context based on the prompt/conversation, validate prompts, or block certain types of prompts.
   751→
   752→#### UserPromptSubmit input
   753→
   754→In addition to the [common input fields](#common-input-fields), UserPromptSubmit hooks receive the `prompt` field containing the text the user submitted.
   755→
   756→```json
   757→{
   758→  "session_id": "abc123",
   759→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
   760→  "cwd": "/Users/...",
   761→  "permission_mode": "default",
   762→  "hook_event_name": "UserPromptSubmit",
   763→  "prompt": "Write a function to calculate the factorial of a number"
   764→}
   765→```
   766→
   767→#### UserPromptSubmit decision control
   768→
   769→`UserPromptSubmit` hooks can control whether a user prompt is processed and add context. All [JSON output fields](#json-output) are available.
   770→
   771→There are two ways to add context to the conversation on exit code 0:
   772→
   773→* **Plain text stdout**: any non-JSON text written to stdout is added as context
   774→* **JSON with `additionalContext`**: use the JSON format below for more control. The `additionalContext` field is added as context
   775→
   776→Plain stdout is shown as hook output in the transcript. The `additionalContext` field is added more discretely.
   777→
   778→To block a prompt, return a JSON object with `decision` set to `"block"`:
   779→
   780→| Field               | Description                                                                                                        |
   781→| :------------------ | :----------------------------------------------------------------------------------------------------------------- |
   782→| `decision`          | `"block"` prevents the prompt from being processed and erases it from context. Omit to allow the prompt to proceed |
   783→| `reason`            | Shown to the user when `decision` is `"block"`. Not added to context                                               |
   784→| `additionalContext` | String added to Claude's context                                                                                   |
   785→
   786→```json
   787→{
   788→  "decision": "block",
   789→  "reason": "Explanation for decision",
   790→  "hookSpecificOutput": {
   791→    "hookEventName": "UserPromptSubmit",
   792→    "additionalContext": "My additional context here"
   793→  }
   794→}
   795→```
   796→
   797→> The JSON format isn't required for simple use cases. To add context, you can print plain text to stdout with exit code 0. Use JSON when you need to block prompts or want more structured control.
   798→
   799→### PreToolUse
   800→
   801→Runs after Claude creates tool parameters and before processing the tool call. Matches on tool name: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `ExitPlanMode`, and any [MCP tool names](#match-mcp-tools).
   802→
   803→Use [PreToolUse decision control](#pretooluse-decision-control) to allow, deny, or ask for permission to use the tool.
   804→
   805→#### PreToolUse input
   806→
   807→In addition to the [common input fields](#common-input-fields), PreToolUse hooks receive `tool_name`, `tool_input`, and `tool_use_id`. The `tool_input` fields depend on the tool:
   808→
   809→##### Bash
   810→
   811→Executes shell commands.
   812→
   813→| Field               | Type    | Example            | Description                                   |
   814→| :------------------ | :------ | :----------------- | :-------------------------------------------- |
   815→| `command`           | string  | `"npm test"`       | The shell command to execute                  |
   816→| `description`       | string  | `"Run test suite"` | Optional description of what the command does |
   817→| `timeout`           | number  | `120000`           | Optional timeout in milliseconds              |
   818→| `run_in_background` | boolean | `false`            | Whether to run the command in background      |
   819→
   820→##### Write
   821→
   822→Creates or overwrites a file.
   823→
   824→| Field       | Type   | Example               | Description                        |
   825→| :---------- | :----- | :-------------------- | :--------------------------------- |
   826→| `file_path` | string | `"/path/to/file.txt"` | Absolute path to the file to write |
   827→| `content`   | string | `"file content"`      | Content to write to the file       |
   828→
   829→##### Edit
   830→
   831→Replaces a string in an existing file.
   832→
   833→| Field         | Type    | Example               | Description                        |
   834→| :------------ | :------ | :-------------------- | :--------------------------------- |
   835→| `file_path`   | string  | `"/path/to/file.txt"` | Absolute path to the file to edit  |
   836→| `old_string`  | string  | `"original text"`     | Text to find and replace           |
   837→| `new_string`  | string  | `"replacement text"`  | Replacement text                   |
   838→| `replace_all` | boolean | `false`               | Whether to replace all occurrences |
   839→
   840→##### Read
   841→
   842→Reads file contents.
   843→
   844→| Field       | Type   | Example               | Description                                |
   845→| :---------- | :----- | :-------------------- | :----------------------------------------- |
   846→| `file_path` | string | `"/path/to/file.txt"` | Absolute path to the file to read          |
   847→| `offset`    | number | `10`                  | Optional line number to start reading from |
   848→| `limit`     | number | `50`                  | Optional number of lines to read           |
   849→
   850→##### Glob
   851→
   852→Finds files matching a glob pattern.
   853→
   854→| Field     | Type   | Example          | Description                                                            |
   855→| :-------- | :----- | :--------------- | :--------------------------------------------------------------------- |
   856→| `pattern` | string | `"**/*.ts"`      | Glob pattern to match files against                                    |
   857→| `path`    | string | `"/path/to/dir"` | Optional directory to search in. Defaults to current working directory |
   858→
   859→##### Grep
   860→
   861→Searches file contents with regular expressions.
   862→
   863→| Field         | Type    | Example          | Description                                                                           |
   864→| :------------ | :------ | :--------------- | :------------------------------------------------------------------------------------ |
   865→| `pattern`     | string  | `"TODO.*fix"`    | Regular expression pattern to search for                                              |
   866→| `path`        | string  | `"/path/to/dir"` | Optional file or directory to search in                                               |
   867→| `glob`        | string  | `"*.ts"`         | Optional glob pattern to filter files                                                 |
   868→| `output_mode` | string  | `"content"`      | `"content"`, `"files_with_matches"`, or `"count"`. Defaults to `"files_with_matches"` |
   869→| `-i`          | boolean | `true`           | Case insensitive search                                                               |
   870→| `multiline`   | boolean | `false`          | Enable multiline matching                                                             |
   871→
   872→##### WebFetch
   873→
   874→Fetches and processes web content.
   875→
   876→| Field    | Type   | Example                       | Description                          |
   877→| :------- | :----- | :---------------------------- | :----------------------------------- |
   878→| `url`    | string | `"https://example.com/api"`   | URL to fetch content from            |
   879→| `prompt` | string | `"Extract the API endpoints"` | Prompt to run on the fetched content |
   880→
   881→##### WebSearch
   882→
   883→Searches the web.
   884→
   885→| Field             | Type   | Example                        | Description                                       |
   886→| :---------------- | :----- | :----------------------------- | :------------------------------------------------ |
   887→| `query`           | string | `"react hooks best practices"` | Search query                                      |
   888→| `allowed_domains` | array  | `["docs.example.com"]`         | Optional: only include results from these domains |
   889→| `blocked_domains` | array  | `["spam.example.com"]`         | Optional: exclude results from these domains      |
   890→
   891→##### Agent
   892→
   893→Spawns a [subagent](/en/sub-agents).
   894→
   895→| Field           | Type   | Example                    | Description                                  |
   896→| :-------------- | :----- | :------------------------- | :------------------------------------------- |
   897→| `prompt`        | string | `"Find all API endpoints"` | The task for the agent to perform            |
   898→| `description`   | string | `"Find API endpoints"`     | Short description of the task                |
   899→| `subagent_type` | string | `"Explore"`                | Type of specialized agent to use             |
   900→| `model`         | string | `"sonnet"`                 | Optional model alias to override the default |
   901→
   902→##### AskUserQuestion
   903→
   904→Asks the user one to four multiple-choice questions.
   905→
   906→| Field       | Type   | Example                                                                                                            | Description                                                                                                                                                                                      |
   907→| :---------- | :----- | :----------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   908→| `questions` | array  | `[{"question": "Which framework?", "header": "Framework", "options": [{"label": "React"}], "multiSelect": false}]` | Questions to present, each with a `question` string, short `header`, `options` array, and optional `multiSelect` flag                                                                            |
   909→| `answers`   | object | `{"Which framework?": "React"}`                                                                                    | Optional. Maps question text to the selected option label. Multi-select answers join labels with commas. Claude does not set this field; supply it via `updatedInput` to answer programmatically |
   910→
   911→#### PreToolUse decision control
   912→
   913→`PreToolUse` hooks can control whether a tool call proceeds. Unlike other hooks that use a top-level `decision` field, PreToolUse returns its decision inside a `hookSpecificOutput` object. This gives it richer control: three outcomes (allow, deny, or ask) plus the ability to modify tool input before execution.
   914→
   915→| Field                      | Description                                                                                                                                                                                                                             |
   916→| :------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   917→| `permissionDecision`       | `"allow"` skips the permission prompt. `"deny"` prevents the tool call. `"ask"` prompts the user to confirm. [Deny and ask rules](/en/permissions#manage-permissions) still apply when a hook returns `"allow"`                         |
   918→| `permissionDecisionReason` | For `"allow"` and `"ask"`, shown to the user but not Claude. For `"deny"`, shown to Claude                                                                                                                                              |
   919→| `updatedInput`             | Modifies the tool's input parameters before execution. Replaces the entire input object, so include unchanged fields alongside modified ones. Combine with `"allow"` to auto-approve, or `"ask"` to show the modified input to the user |
   920→| `additionalContext`        | String added to Claude's context before the tool executes                                                                                                                                                                               |
   921→
   922→When a hook returns `"ask"`, the permission prompt displayed to the user includes a label identifying where the hook came from: for example, `[User]`, `[Project]`, `[Plugin]`, or `[Local]`. This helps users understand which configuration source is requesting confirmation.
   923→
   924→```json
   925→{
   926→  "hookSpecificOutput": {
   927→    "hookEventName": "PreToolUse",
   928→    "permissionDecision": "allow",
   929→    "permissionDecisionReason": "My reason here",
   930→    "updatedInput": {
   931→      "field_to_modify": "new value"
   932→    },
   933→    "additionalContext": "Current environment: production. Proceed with caution."
   934→  }
   935→}
   936→```
   937→
   938→`AskUserQuestion` and `ExitPlanMode` require user interaction and normally block in [non-interactive mode](/en/headless) with the `-p` flag. Returning `permissionDecision: "allow"` together with `updatedInput` satisfies that requirement: the hook reads the tool's input from stdin, collects the answer through your own UI, and returns it in `updatedInput` so the tool runs without prompting. Returning `"allow"` alone is not sufficient for these tools. For `AskUserQuestion`, echo back the original `questions` array and add an [`answers`](#askuserquestion) object mapping each question's text to the chosen answer.
   939→
   940→> PreToolUse previously used top-level `decision` and `reason` fields, but these are deprecated for this event. Use `hookSpecificOutput.permissionDecision` and `hookSpecificOutput.permissionDecisionReason` instead. The deprecated values `"approve"` and `"block"` map to `"allow"` and `"deny"` respectively. Other events like PostToolUse and Stop continue to use top-level `decision` and `reason` as their current format.
   941→
   942→### PermissionRequest
   943→
   944→Runs when the user is shown a permission dialog.
   945→Use [PermissionRequest decision control](#permissionrequest-decision-control) to allow or deny on behalf of the user.
   946→
   947→Matches on tool name, same values as PreToolUse.
   948→
   949→#### PermissionRequest input
   950→
   951→PermissionRequest hooks receive `tool_name` and `tool_input` fields like PreToolUse hooks, but without `tool_use_id`. An optional `permission_suggestions` array contains the "always allow" options the user would normally see in the permission dialog. The difference is when the hook fires: PermissionRequest hooks run when a permission dialog is about to be shown to the user, while PreToolUse hooks run before tool execution regardless of permission status.
   952→
   953→```json
   954→{
   955→  "session_id": "abc123",
   956→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
   957→  "cwd": "/Users/...",
   958→  "permission_mode": "default",
   959→  "hook_event_name": "PermissionRequest",
   960→  "tool_name": "Bash",
   961→  "tool_input": {
   962→    "command": "rm -rf node_modules",
   963→    "description": "Remove node_modules directory"
   964→  },
   965→  "permission_suggestions": [
   966→    {
   967→      "type": "addRules",
   968→      "rules": [{ "toolName": "Bash", "ruleContent": "rm -rf node_modules" }],
   969→      "behavior": "allow",
   970→      "destination": "localSettings"
   971→    }
   972→  ]
   973→}
   974→```
   975→
   976→#### PermissionRequest decision control
   977→
   978→`PermissionRequest` hooks can allow or deny permission requests. In addition to the [JSON output fields](#json-output) available to all hooks, your hook script can return a `decision` object with these event-specific fields:
   979→
   980→| Field                | Description                                                                                                                                                         |
   981→| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   982→| `behavior`           | `"allow"` grants the permission, `"deny"` denies it                                                                                                                 |
   983→| `updatedInput`       | For `"allow"` only: modifies the tool's input parameters before execution. Replaces the entire input object, so include unchanged fields alongside modified ones    |
   984→| `updatedPermissions` | For `"allow"` only: array of [permission update entries](#permission-update-entries) to apply, such as adding an allow rule or changing the session permission mode |
   985→| `message`            | For `"deny"` only: tells Claude why the permission was denied                                                                                                       |
   986→| `interrupt`          | For `"deny"` only: if `true`, stops Claude                                                                                                                          |
   987→
   988→```json
   989→{
   990→  "hookSpecificOutput": {
   991→    "hookEventName": "PermissionRequest",
   992→    "decision": {
   993→      "behavior": "allow",
   994→      "updatedInput": {
   995→        "command": "npm run lint"
   996→      }
   997→    }
   998→  }
   999→}
  1000→```
  1001→
  1002→#### Permission update entries
  1003→
  1004→The `updatedPermissions` output field and the [`permission_suggestions` input field](#permissionrequest-input) both use the same array of entry objects. Each entry has a `type` that determines its other fields, and a `destination` that controls where the change is written.
  1005→
  1006→| `type`              | Fields                             | Effect                                                                                                                                                                      |
  1007→| :------------------ | :--------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  1008→| `addRules`          | `rules`, `behavior`, `destination` | Adds permission rules. `rules` is an array of `{toolName, ruleContent?}` objects. Omit `ruleContent` to match the whole tool. `behavior` is `"allow"`, `"deny"`, or `"ask"` |
  1009→| `replaceRules`      | `rules`, `behavior`, `destination` | Replaces all rules of the given `behavior` at the `destination` with the provided `rules`                                                                                   |
  1010→| `removeRules`       | `rules`, `behavior`, `destination` | Removes matching rules of the given `behavior`                                                                                                                              |
  1011→| `setMode`           | `mode`, `destination`              | Changes the permission mode. Valid modes are `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, and `plan`                                                           |
  1012→| `addDirectories`    | `directories`, `destination`       | Adds working directories. `directories` is an array of path strings                                                                                                         |
  1013→| `removeDirectories` | `directories`, `destination`       | Removes working directories                                                                                                                                                 |
  1014→
  1015→The `destination` field on every entry determines whether the change stays in memory or persists to a settings file.
  1016→
  1017→| `destination`     | Writes to                                       |
  1018→| :---------------- | :---------------------------------------------- |
  1019→| `session`         | in-memory only, discarded when the session ends |
  1020→| `localSettings`   | `.claude/settings.local.json`                   |
  1021→| `projectSettings` | `.claude/settings.json`                         |
  1022→| `userSettings`    | `~/.claude/settings.json`                       |
  1023→
  1024→A hook can echo one of the `permission_suggestions` it received as its own `updatedPermissions` output, which is equivalent to the user selecting that "always allow" option in the dialog.
  1025→
  1026→### PostToolUse
  1027→
  1028→Runs immediately after a tool completes successfully.
  1029→
  1030→Matches on tool name, same values as PreToolUse.
  1031→
  1032→#### PostToolUse input
  1033→
  1034→`PostToolUse` hooks fire after a tool has already executed successfully. The input includes both `tool_input`, the arguments sent to the tool, and `tool_response`, the result it returned. The exact schema for both depends on the tool.
  1035→
  1036→```json
  1037→{
  1038→  "session_id": "abc123",
  1039→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1040→  "cwd": "/Users/...",
  1041→  "permission_mode": "default",
  1042→  "hook_event_name": "PostToolUse",
  1043→  "tool_name": "Write",
  1044→  "tool_input": {
  1045→    "file_path": "/path/to/file.txt",
  1046→    "content": "file content"
  1047→  },
  1048→  "tool_response": {
  1049→    "filePath": "/path/to/file.txt",
  1050→    "success": true
  1051→  },
  1052→  "tool_use_id": "toolu_01ABC123..."
  1053→}
  1054→```
  1055→
  1056→#### PostToolUse decision control
  1057→
  1058→`PostToolUse` hooks can provide feedback to Claude after tool execution. In addition to the [JSON output fields](#json-output) available to all hooks, your hook script can return these event-specific fields:
  1059→
  1060→| Field                  | Description                                                                                |
  1061→| :--------------------- | :----------------------------------------------------------------------------------------- |
  1062→| `decision`             | `"block"` prompts Claude with the `reason`. Omit to allow the action to proceed            |
  1063→| `reason`               | Explanation shown to Claude when `decision` is `"block"`                                   |
  1064→| `additionalContext`    | Additional context for Claude to consider                                                  |
  1065→| `updatedMCPToolOutput` | For [MCP tools](#match-mcp-tools) only: replaces the tool's output with the provided value |
  1066→
  1067→```json
  1068→{
  1069→  "decision": "block",
  1070→  "reason": "Explanation for decision",
  1071→  "hookSpecificOutput": {
  1072→    "hookEventName": "PostToolUse",
  1073→    "additionalContext": "Additional information for Claude"
  1074→  }
  1075→}
  1076→```
  1077→
  1078→### PostToolUseFailure
  1079→
  1080→Runs when a tool execution fails. This event fires for tool calls that throw errors or return failure results. Use this to log failures, send alerts, or provide corrective feedback to Claude.
  1081→
  1082→Matches on tool name, same values as PreToolUse.
  1083→
  1084→#### PostToolUseFailure input
  1085→
  1086→PostToolUseFailure hooks receive the same `tool_name` and `tool_input` fields as PostToolUse, along with error information as top-level fields:
  1087→
  1088→```json
  1089→{
  1090→  "session_id": "abc123",
  1091→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1092→  "cwd": "/Users/...",
  1093→  "permission_mode": "default",
  1094→  "hook_event_name": "PostToolUseFailure",
  1095→  "tool_name": "Bash",
  1096→  "tool_input": {
  1097→    "command": "npm test",
  1098→    "description": "Run test suite"
  1099→  },
  1100→  "tool_use_id": "toolu_01ABC123...",
  1101→  "error": "Command exited with non-zero status code 1",
  1102→  "is_interrupt": false
  1103→}
  1104→```
  1105→
  1106→| Field          | Description                                                                     |
  1107→| :------------- | :------------------------------------------------------------------------------ |
  1108→| `error`        | String describing what went wrong                                               |
  1109→| `is_interrupt` | Optional boolean indicating whether the failure was caused by user interruption |
  1110→
  1111→#### PostToolUseFailure decision control
  1112→
  1113→`PostToolUseFailure` hooks can provide context to Claude after a tool failure. In addition to the [JSON output fields](#json-output) available to all hooks, your hook script can return these event-specific fields:
  1114→
  1115→| Field               | Description                                                   |
  1116→| :------------------ | :------------------------------------------------------------ |
  1117→| `additionalContext` | Additional context for Claude to consider alongside the error |
  1118→
  1119→```json
  1120→{
  1121→  "hookSpecificOutput": {
  1122→    "hookEventName": "PostToolUseFailure",
  1123→    "additionalContext": "Additional information about the failure for Claude"
  1124→  }
  1125→}
  1126→```
  1127→
  1128→### Notification
  1129→
  1130→Runs when Claude Code sends notifications. Matches on notification type: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`. Omit the matcher to run hooks for all notification types.
  1131→
  1132→Use separate matchers to run different handlers depending on the notification type. This configuration triggers a permission-specific alert script when Claude needs permission approval and a different notification when Claude has been idle:
  1133→
  1134→```json
  1135→{
  1136→  "hooks": {
  1137→    "Notification": [
  1138→      {
  1139→        "matcher": "permission_prompt",
  1140→        "hooks": [
  1141→          {
  1142→            "type": "command",
  1143→            "command": "/path/to/permission-alert.sh"
  1144→          }
  1145→        ]
  1146→      },
  1147→      {
  1148→        "matcher": "idle_prompt",
  1149→        "hooks": [
  1150→          {
  1151→            "type": "command",
  1152→            "command": "/path/to/idle-notification.sh"
  1153→          }
  1154→        ]
  1155→      }
  1156→    ]
  1157→  }
  1158→}
  1159→```
  1160→
  1161→#### Notification input
  1162→
  1163→In addition to the [common input fields](#common-input-fields), Notification hooks receive `message` with the notification text, an optional `title`, and `notification_type` indicating which type fired.
  1164→
  1165→```json
  1166→{
  1167→  "session_id": "abc123",
  1168→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1169→  "cwd": "/Users/...",
  1170→  "hook_event_name": "Notification",
  1171→  "message": "Claude needs your permission to use Bash",
  1172→  "title": "Permission needed",
  1173→  "notification_type": "permission_prompt"
  1174→}
  1175→```
  1176→
  1177→Notification hooks cannot block or modify notifications. In addition to the [JSON output fields](#json-output) available to all hooks, you can return `additionalContext` to add context to the conversation:
  1178→
  1179→| Field               | Description                      |
  1180→| :------------------ | :------------------------------- |
  1181→| `additionalContext` | String added to Claude's context |
  1182→
  1183→### SubagentStart
  1184→
  1185→Runs when a Claude Code subagent is spawned via the Agent tool. Supports matchers to filter by agent type name (built-in agents like `Bash`, `Explore`, `Plan`, or custom agent names from `.claude/agents/`).
  1186→
  1187→#### SubagentStart input
  1188→
  1189→In addition to the [common input fields](#common-input-fields), SubagentStart hooks receive `agent_id` with the unique identifier for the subagent and `agent_type` with the agent name (built-in agents like `"Bash"`, `"Explore"`, `"Plan"`, or custom agent names).
  1190→
  1191→```json
  1192→{
  1193→  "session_id": "abc123",
  1194→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1195→  "cwd": "/Users/...",
  1196→  "hook_event_name": "SubagentStart",
  1197→  "agent_id": "agent-abc123",
  1198→  "agent_type": "Explore"
  1199→}
  1200→```
  1201→
  1202→SubagentStart hooks cannot block subagent creation, but they can inject context into the subagent. In addition to the [JSON output fields](#json-output) available to all hooks, you can return:
  1203→
  1204→| Field               | Description                            |
  1205→| :------------------ | :------------------------------------- |
  1206→| `additionalContext` | String added to the subagent's context |
  1207→
  1208→```json
  1209→{
  1210→  "hookSpecificOutput": {
  1211→    "hookEventName": "SubagentStart",
  1212→    "additionalContext": "Follow security guidelines for this task"
  1213→  }
  1214→}
  1215→```
  1216→
  1217→### SubagentStop
  1218→
  1219→Runs when a Claude Code subagent has finished responding. Matches on agent type, same values as SubagentStart.
  1220→
  1221→#### SubagentStop input
  1222→
  1223→In addition to the [common input fields](#common-input-fields), SubagentStop hooks receive `stop_hook_active`, `agent_id`, `agent_type`, `agent_transcript_path`, and `last_assistant_message`. The `agent_type` field is the value used for matcher filtering. The `transcript_path` is the main session's transcript, while `agent_transcript_path` is the subagent's own transcript stored in a nested `subagents/` folder. The `last_assistant_message` field contains the text content of the subagent's final response, so hooks can access it without parsing the transcript file.
  1224→
  1225→```json
  1226→{
  1227→  "session_id": "abc123",
  1228→  "transcript_path": "~/.claude/projects/.../abc123.jsonl",
  1229→  "cwd": "/Users/...",
  1230→  "permission_mode": "default",
  1231→  "hook_event_name": "SubagentStop",
  1232→  "stop_hook_active": false,
  1233→  "agent_id": "def456",
  1234→  "agent_type": "Explore",
  1235→  "agent_transcript_path": "~/.claude/projects/.../abc123/subagents/agent-def456.jsonl",
  1236→  "last_assistant_message": "Analysis complete. Found 3 potential issues..."
  1237→}
  1238→```
  1239→
  1240→SubagentStop hooks use the same decision control format as [Stop hooks](#stop-decision-control).
  1241→
  1242→### TaskCreated
  1243→
  1244→Runs when a task is being created via the `TaskCreate` tool. Use this to enforce naming conventions, require task descriptions, or prevent certain tasks from being created.
  1245→
  1246→When a `TaskCreated` hook exits with code 2, the task is not created and the stderr message is fed back to the model as feedback. To stop the teammate entirely instead of re-running it, return JSON with `{"continue": false, "stopReason": "..."}`. TaskCreated hooks do not support matchers and fire on every occurrence.
  1247→
  1248→#### TaskCreated input
  1249→
  1250→In addition to the [common input fields](#common-input-fields), TaskCreated hooks receive `task_id`, `task_subject`, and optionally `task_description`, `teammate_name`, and `team_name`.
  1251→
  1252→```json
  1253→{
  1254→  "session_id": "abc123",
  1255→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1256→  "cwd": "/Users/...",
  1257→  "permission_mode": "default",
  1258→  "hook_event_name": "TaskCreated",
  1259→  "task_id": "task-001",
  1260→  "task_subject": "Implement user authentication",
  1261→  "task_description": "Add login and signup endpoints",
  1262→  "teammate_name": "implementer",
  1263→  "team_name": "my-project"
  1264→}
  1265→```
  1266→
  1267→| Field              | Description                                           |
  1268→| :----------------- | :---------------------------------------------------- |
  1269→| `task_id`          | Identifier of the task being created                  |
  1270→| `task_subject`     | Title of the task                                     |
  1271→| `task_description` | Detailed description of the task. May be absent       |
  1272→| `teammate_name`    | Name of the teammate creating the task. May be absent |
  1273→| `team_name`        | Name of the team. May be absent                       |
  1274→
  1275→#### TaskCreated decision control
  1276→
  1277→TaskCreated hooks support two ways to control task creation:
  1278→
  1279→* **Exit code 2**: the task is not created and the stderr message is fed back to the model as feedback.
  1280→* **JSON `{"continue": false, "stopReason": "..."}`**: stops the teammate entirely, matching `Stop` hook behavior. The `stopReason` is shown to the user.
  1281→
  1282→This example blocks tasks whose subjects don't follow the required format:
  1283→
  1284→```bash
  1285→#!/bin/bash
  1286→INPUT=$(cat)
  1287→TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')
  1288→
  1289→if [[ ! "$TASK_SUBJECT" =~ ^\[TICKET-[0-9]+\] ]]; then
  1290→  echo "Task subject must start with a ticket number, e.g. '[TICKET-123] Add feature'" >&2
  1291→  exit 2
  1292→fi
  1293→
  1294→exit 0
  1295→```
  1296→
  1297→### TaskCompleted
  1298→
  1299→Runs when a task is being marked as completed. This fires in two situations: when any agent explicitly marks a task as completed through the TaskUpdate tool, or when an [agent team](/en/agent-teams) teammate finishes its turn with in-progress tasks. Use this to enforce completion criteria like passing tests or lint checks before a task can close.
  1300→
  1301→When a `TaskCompleted` hook exits with code 2, the task is not marked as completed and the stderr message is fed back to the model as feedback. To stop the teammate entirely instead of re-running it, return JSON with `{"continue": false, "stopReason": "..."}`. TaskCompleted hooks do not support matchers and fire on every occurrence.
  1302→
  1303→#### TaskCompleted input
  1304→
  1305→In addition to the [common input fields](#common-input-fields), TaskCompleted hooks receive `task_id`, `task_subject`, and optionally `task_description`, `teammate_name`, and `team_name`.
  1306→
  1307→```json
  1308→{
  1309→  "session_id": "abc123",
  1310→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1311→  "cwd": "/Users/...",
  1312→  "permission_mode": "default",
  1313→  "hook_event_name": "TaskCompleted",
  1314→  "task_id": "task-001",
  1315→  "task_subject": "Implement user authentication",
  1316→  "task_description": "Add login and signup endpoints",
  1317→  "teammate_name": "implementer",
  1318→  "team_name": "my-project"
  1319→}
  1320→```
  1321→
  1322→| Field              | Description                                             |
  1323→| :----------------- | :------------------------------------------------------ |
  1324→| `task_id`          | Identifier of the task being completed                  |
  1325→| `task_subject`     | Title of the task                                       |
  1326→| `task_description` | Detailed description of the task. May be absent         |
  1327→| `teammate_name`    | Name of the teammate completing the task. May be absent |
  1328→| `team_name`        | Name of the team. May be absent                         |
  1329→
  1330→#### TaskCompleted decision control
  1331→
  1332→TaskCompleted hooks support two ways to control task completion:
  1333→
  1334→* **Exit code 2**: the task is not marked as completed and the stderr message is fed back to the model as feedback.
  1335→* **JSON `{"continue": false, "stopReason": "..."}`**: stops the teammate entirely, matching `Stop` hook behavior. The `stopReason` is shown to the user.
  1336→
  1337→This example runs tests and blocks task completion if they fail:
  1338→
  1339→```bash
  1340→#!/bin/bash
  1341→INPUT=$(cat)
  1342→TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')
  1343→
  1344→# Run the test suite
  1345→if ! npm test 2>&1; then
  1346→  echo "Tests not passing. Fix failing tests before completing: $TASK_SUBJECT" >&2
  1347→  exit 2
  1348→fi
  1349→
  1350→exit 0
  1351→```
  1352→
  1353→### Stop
  1354→
  1355→Runs when the main Claude Code agent has finished responding. Does not run if the stoppage occurred due to a user interrupt. API errors fire [StopFailure](#stopfailure) instead.
  1356→
  1357→#### Stop input
  1358→
  1359→In addition to the [common input fields](#common-input-fields), Stop hooks receive `stop_hook_active` and `last_assistant_message`. The `stop_hook_active` field is `true` when Claude Code is already continuing as a result of a stop hook. Check this value or process the transcript to prevent Claude Code from running indefinitely. The `last_assistant_message` field contains the text content of Claude's final response, so hooks can access it without parsing the transcript file.
  1360→
  1361→```json
  1362→{
  1363→  "session_id": "abc123",
  1364→  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1365→  "cwd": "/Users/...",
  1366→  "permission_mode": "default",
  1367→  "hook_event_name": "Stop",
  1368→  "stop_hook_active": true,
  1369→  "last_assistant_message": "I've completed the refactoring. Here's a summary..."
  1370→}
  1371→```
  1372→
  1373→#### Stop decision control
  1374→
  1375→`Stop` and `SubagentStop` hooks can control whether Claude continues. In addition to the [JSON output fields](#json-output) available to all hooks, your hook script can return these event-specific fields:
  1376→
  1377→| Field      | Description                                                                |
  1378→| :--------- | :------------------------------------------------------------------------- |
  1379→| `decision` | `"block"` prevents Claude from stopping. Omit to allow Claude to stop      |
  1380→| `reason`   | Required when `decision` is `"block"`. Tells Claude why it should continue |
  1381→
  1382→```json
  1383→{
  1384→  "decision": "block",
  1385→  "reason": "Must be provided when Claude is blocked from stopping"
  1386→}
  1387→```
  1388→
  1389→### StopFailure
  1390→
  1391→Runs instead of [Stop](#stop) when the turn ends due to an API error. Output and exit code are ignored. Use this to log failures, send alerts, or take recovery actions when Claude cannot complete a response due to rate limits, authentication problems, or other API errors.
  1392→
  1393→#### StopFailure input
  1394→
  1395→In addition to the [common input fields](#common-input-fields), StopFailure hooks receive `error`, optional `error_details`, and optional `last_assistant_message`. The `error` field identifies the error type and is used for matcher filtering.
  1396→
  1397→| Field                    | Description                                                                                                                                                                                                                                      |
  1398→| :----------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  1399→| `error`                  | Error type: `rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, or `unknown`                                                                                                         |
  1400→| `error_details`          | Additional details about the error, when available                                                                                                                                                                                               |
  1401→| `last_assistant_message` | The rendered error text shown in the conversation. Unlike `Stop` and `SubagentStop`, where this field holds Claude's conversational output, for `StopFailure` it contains the API error string itself, such as `"API Error: Rate limit reached"` |
  1402→
  1403→```json
  1404→{
  1405→  "session_id": "abc123",
  1406→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1407→  "cwd": "/Users/...",
  1408→  "hook_event_name": "StopFailure",
  1409→  "error": "rate_limit",
  1410→  "error_details": "429 Too Many Requests",
  1411→  "last_assistant_message": "API Error: Rate limit reached"
  1412→}
  1413→```
  1414→
  1415→StopFailure hooks have no decision control. They run for notification and logging purposes only.
  1416→
  1417→### TeammateIdle
  1418→
  1419→Runs when an [agent team](/en/agent-teams) teammate is about to go idle after finishing its turn. Use this to enforce quality gates before a teammate stops working, such as requiring passing lint checks or verifying that output files exist.
  1420→
  1421→When a `TeammateIdle` hook exits with code 2, the teammate receives the stderr message as feedback and continues working instead of going idle. To stop the teammate entirely instead of re-running it, return JSON with `{"continue": false, "stopReason": "..."}`. TeammateIdle hooks do not support matchers and fire on every occurrence.
  1422→
  1423→#### TeammateIdle input
  1424→
  1425→In addition to the [common input fields](#common-input-fields), TeammateIdle hooks receive `teammate_name` and `team_name`.
  1426→
  1427→```json
  1428→{
  1429→  "session_id": "abc123",
  1430→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1431→  "cwd": "/Users/...",
  1432→  "permission_mode": "default",
  1433→  "hook_event_name": "TeammateIdle",
  1434→  "teammate_name": "researcher",
  1435→  "team_name": "my-project"
  1436→}
  1437→```
  1438→
  1439→| Field           | Description                                   |
  1440→| :-------------- | :-------------------------------------------- |
  1441→| `teammate_name` | Name of the teammate that is about to go idle |
  1442→| `team_name`     | Name of the team                              |
  1443→
  1444→#### TeammateIdle decision control
  1445→
  1446→TeammateIdle hooks support two ways to control teammate behavior:
  1447→
  1448→* **Exit code 2**: the teammate receives the stderr message as feedback and continues working instead of going idle.
  1449→* **JSON `{"continue": false, "stopReason": "..."}`**: stops the teammate entirely, matching `Stop` hook behavior. The `stopReason` is shown to the user.
  1450→
  1451→This example checks that a build artifact exists before allowing a teammate to go idle:
  1452→
  1453→```bash
  1454→#!/bin/bash
  1455→
  1456→if [ ! -f "./dist/output.js" ]; then
  1457→  echo "Build artifact missing. Run the build before stopping." >&2
  1458→  exit 2
  1459→fi
  1460→
  1461→exit 0
  1462→```
  1463→
  1464→### ConfigChange
  1465→
  1466→Runs when a configuration file changes during a session. Use this to audit settings changes, enforce security policies, or block unauthorized modifications to configuration files.
  1467→
  1468→ConfigChange hooks fire for changes to settings files, managed policy settings, and skill files. The `source` field in the input tells you which type of configuration changed, and the optional `file_path` field provides the path to the changed file.
  1469→
  1470→The matcher filters on the configuration source:
  1471→
  1472→| Matcher            | When it fires                             |
  1473→| :----------------- | :---------------------------------------- |
  1474→| `user_settings`    | `~/.claude/settings.json` changes         |
  1475→| `project_settings` | `.claude/settings.json` changes           |
  1476→| `local_settings`   | `.claude/settings.local.json` changes     |
  1477→| `policy_settings`  | Managed policy settings change            |
  1478→| `skills`           | A skill file in `.claude/skills/` changes |
  1479→
  1480→This example logs all configuration changes for security auditing:
  1481→
  1482→```json
  1483→{
  1484→  "hooks": {
  1485→    "ConfigChange": [
  1486→      {
  1487→        "hooks": [
  1488→          {
  1489→            "type": "command",
  1490→            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/audit-config-change.sh"
  1491→          }
  1492→        ]
  1493→      }
  1494→    ]
  1495→  }
  1496→}
  1497→```
  1498→
  1499→#### ConfigChange input
  1500→
  1501→In addition to the [common input fields](#common-input-fields), ConfigChange hooks receive `source` and optionally `file_path`. The `source` field indicates which configuration type changed, and `file_path` provides the path to the specific file that was modified.
  1502→
  1503→```json
  1504→{
  1505→  "session_id": "abc123",
  1506→  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  1507→  "cwd": "/Users/...",
  1508→  "hook_event_name": "ConfigChange",
  1509→  "source": "project_settings",
  1510→  "file_path": "/Users/.../my-project/.claude/settings.json"
  1511→}
  1512→```
  1513→
  1514→#### ConfigChange decision control
  1515→
  1516→ConfigChange hooks can block configuration changes from taking effect. Use exit code 2 or a JSON `decision` to prevent the change. When blocked, the new settings are not applied to the running session.
  1517→
  1518→[Note: The content continues but was truncated in the original document. The remaining sections cover CwdChanged, FileChanged, PreCompact, PostCompact, Elicitation, ElicitationResult, WorktreeCreate, WorktreeRemove, and SessionEnd events.]
  1519→
  1520→---
  1521→
  1522→This is the complete documentation reference for Claude Code hooks, covering all hook events, configuration options, input/output formats, and decision control mechanisms. The documentation provides comprehensive guidance on setting up and managing hooks across all lifecycle points in Claude Code sessions.