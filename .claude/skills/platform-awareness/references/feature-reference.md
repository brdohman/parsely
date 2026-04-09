# Claude Code Feature Reference

**Last updated:** 2026-03-27
**Claude Code version:** 2.1.86
**Source:** https://code.claude.com/docs/llms.txt

---

## 1. Extension Points Overview

Claude Code's agentic loop can be extended at multiple levels. Each extension type plugs into a different part of the loop.

| Extension Type | What It Does | Our Usage |
|---|---|---|
| **CLAUDE.md** | Persistent context loaded every session | 1 project CLAUDE.md + 18 rules files |
| **Agents** (`.claude/agents/`) | Custom subagents with system prompts, tools, models | 17 agents |
| **Skills** (`.claude/skills/`) | Reusable knowledge, reference docs, invocable workflows | 36 skills |
| **Commands** (`.claude/commands/`) | Slash commands (merged into skills system) | 45 commands |
| **Hooks** (settings.json + `.claude/hooks/`) | Deterministic scripts on lifecycle events | 6 hook scripts, 6 event bindings |
| **MCP Servers** (`.mcp.json`) | External service connections via Model Context Protocol | 1 project-level (Xcode), 3+ user-level |
| **Plugins** | Installable packages of skills, agents, hooks, MCP | 3 enabled (CodeRabbit, swift-lsp, pyright-lsp) |
| **Rules** (`.claude/rules/`) | Scoped instructions, path-filtered or global | 18 rule files (global + path + workflow) |
| **Settings** (`settings.json`) | Permissions, hooks, env vars, behavior config | Project + user settings |
| **Memory** (CLAUDE.md + auto memory) | Persistent instructions + Claude's self-notes | Project CLAUDE.md + 1 memory file |

---

## 2. Agents (.claude/agents/)

### How Custom Agents Work

Each agent is a Markdown file with YAML frontmatter (configuration) and a body (system prompt). When Claude delegates to an agent, a new subagent instance starts with fresh context, the agent's system prompt, and only the tools/skills specified. Subagents cannot spawn sub-subagents.

### Supported Frontmatter Fields

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Unique identifier (lowercase, hyphens). Becomes the agent reference name. |
| `description` | Yes | When Claude should delegate to this agent. Claude uses this for auto-delegation. |
| `tools` | No | Allowlist of tools. Inherits all if omitted. Supports `Agent(type)` syntax. |
| `disallowedTools` | No | Denylist. Applied before `tools`. |
| `model` | No | `sonnet`, `opus`, `haiku`, full model ID, or `inherit`. Default: `inherit`. |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`. |
| `maxTurns` | No | Max agentic turns before auto-stop. |
| `skills` | No | Skills preloaded into context at startup. Full content injected, not on-demand. |
| `mcpServers` | No | MCP servers available. String refs share parent connection; inline defs are scoped. |
| `hooks` | No | Lifecycle hooks scoped to this agent. Cleaned up when agent finishes. |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local`. |
| `background` | No | `true` to always run as background task. Default: `false`. |
| `effort` | No | Effort level override: `low`, `medium`, `high`, `max` (Opus 4.6 only). |
| `isolation` | No | `worktree` to run in a temporary git worktree. Auto-cleaned if no changes. |
| `initialPrompt` | No | Auto-submitted first user turn when running as main session agent via `--agent`. |

### Scope & Priority

| Location | Scope | Priority |
|---|---|---|
| `--agents` CLI flag | Current session only | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All projects | 3 |
| Plugin `agents/` dir | Where plugin enabled | 4 (lowest) |

Same-name agents: higher priority wins.

### Built-in Agents

| Agent | Model | Tools | Purpose |
|---|---|---|---|
| **Explore** | Haiku | Read-only | Fast codebase search and analysis |
| **Plan** | Inherits | Read-only | Research for plan mode |
| **general-purpose** | Inherits | All | Complex multi-step tasks |
| **Bash** | Inherits | Terminal | Running terminal commands in separate context |
| **statusline-setup** | Sonnet | -- | Configure status line |
| **Claude Code Guide** | Haiku | -- | Answer questions about Claude Code features |

### Invocation Methods

1. **Automatic delegation** -- Claude matches task to agent descriptions
2. **Natural language** -- Name the agent in your prompt
3. **@-mention** -- `@"agent-name (agent)"` guarantees that agent runs
4. **`--agent` flag** -- Whole session uses that agent's prompt/tools/model
5. **`agent` setting** -- Default agent for every session in project settings

### What We Use: 17 Custom Agents

| Agent | Model | Key Skills | MCP |
|---|---|---|---|
| `macos-developer` | sonnet | swiftui, core-data, design-system, scenes, crash-recovery | xcode |
| `staff-engineer` | sonnet | core-data, security, architecture, best-practices | xcode, aikido |
| `qa` | sonnet | test-generator, crash-recovery | xcode, peekaboo |
| `build-engineer` | sonnet | github, xcode-build | xcode, peekaboo |
| `pm` | sonnet | peekaboo | peekaboo |
| `designer-agent` | sonnet | design-system, ui-review, scenes | xcode, peekaboo |
| `planning` | opus | -- | -- |
| `discovery` | opus | -- | -- |
| `security-audit` | sonnet | security, review-cycle | aikido, trivy |
| `security-static` | sonnet | security | aikido |
| `security-reasoning` | opus | security | -- |
| `security-platform` | sonnet | security | -- |
| `data-architect-agent` | sonnet | core-data | xcode |
| `documentation` | sonnet | architecture | -- |
| `rca` | sonnet | -- | -- |
| `visual-qa` | sonnet | peekaboo | peekaboo, xcode |
| `ui-audit` | sonnet | design-system, ui-review | -- |

Common patterns: All use `permissionMode: bypassPermissions`. Most use `maxTurns: 30-50`. Two agents use `memory: project` (macos-developer, rca). One agent uses `disallowedTools` (pm: no Edit). One agent uses agent-scoped `hooks` (qa: Stop hook).

---

## 3. Skills (.claude/skills/)

### How Skills Work

A skill is a directory with `SKILL.md` as entrypoint. The markdown body contains instructions Claude follows when the skill is active. Skills can include supporting files (templates, references, scripts).

Skills follow the [Agent Skills](https://agentskills.io) open standard. Claude Code extends it with invocation control, subagent execution, and dynamic context injection.

### Discovery & Loading

- **Session start**: Skill names + descriptions loaded (low context cost)
- **When invoked**: Full SKILL.md content loaded into conversation
- **In subagents**: Skills listed in `skills:` field are fully preloaded at startup (not on-demand)
- **Path-scoped**: Skills with `paths` frontmatter only activate for matching files
- **Nested discovery**: Skills in subdirectory `.claude/skills/` found when working in that subdirectory

Budget: Descriptions scale at 2% of context window (fallback: 16,000 chars). Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET`.

### Frontmatter Reference

| Field | Required | Description |
|---|---|---|
| `name` | No | Display name and `/slash-command`. Defaults to directory name. Lowercase, hyphens, max 64 chars. |
| `description` | Recommended | What it does and when to use it. Claude uses this for auto-invocation. |
| `argument-hint` | No | Hint shown during autocomplete, e.g. `[issue-number]`. |
| `disable-model-invocation` | No | `true` = only user can invoke. Removes from Claude's context entirely. Default: `false`. |
| `user-invocable` | No | `false` = hidden from `/` menu. Background knowledge only. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without permission when skill is active. |
| `model` | No | Model override when skill is active. |
| `effort` | No | Effort level override: `low`, `medium`, `high`, `max`. |
| `context` | No | `fork` = run in forked subagent context. |
| `agent` | No | Which subagent type when `context: fork`. Options: `Explore`, `Plan`, `general-purpose`, or custom. |
| `hooks` | No | Hooks scoped to skill lifecycle. |
| `paths` | No | Glob patterns limiting auto-activation to matching files. |
| `shell` | No | Shell for `` !`command` `` blocks: `bash` (default) or `powershell`. |

### String Substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments passed when invoking. Appended as `ARGUMENTS: <value>` if not present in content. |
| `$ARGUMENTS[N]` | Specific argument by 0-based index. |
| `$N` | Shorthand for `$ARGUMENTS[N]`. |
| `${CLAUDE_SESSION_ID}` | Current session ID. |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md. |

### Dynamic Context Injection

The `` !`<command>` `` syntax runs shell commands before content is sent to Claude. Output replaces the placeholder. This is preprocessing, not Claude execution.

### Bundled Skills

| Skill | Purpose |
|---|---|
| `/simplify` | Review changed files for reuse, quality, efficiency; fix issues. 3 parallel review agents. |
| `/batch <instruction>` | Orchestrate large-scale changes in parallel git worktrees. 5-30 units, one agent per unit. |
| `/debug [description]` | Enable debug logging, troubleshoot by reading session debug log. |
| `/loop [interval] <prompt>` | Run a prompt repeatedly on interval. Polling, babysitting, periodic re-runs. |
| `/claude-api` | Load Claude API reference for project language + Agent SDK reference. |

### Scope Hierarchy

| Location | Scope | Priority |
|---|---|---|
| Enterprise (managed settings) | All org users | Highest |
| `~/.claude/skills/` | All your projects | 2 |
| `.claude/skills/` | This project | 3 |
| Plugin `skills/` dir | Where plugin enabled | Namespaced (no conflict) |

### What We Use: 36 Skills

**Architecture & Design:**
- `architecture/` -- SOLID, DRY, Clean Architecture, design patterns
- `design-system/` -- Component library, spacing, typography, color, HIG decisions (+ 5 reference files)
- `macos-ui-review/` -- Liquid Glass, HIG compliance, accessibility, SwiftUI patterns (+ 5 reference files)

**Best Practices:**
- `macos-best-practices/` -- Code organization, data persistence, concurrency, Swift language (+ 4 reference files)
- `security/` -- Secure storage, biometric auth, network security, platform specifics (+ 4 reference files)

**Generators:**
- `generators/networking-layer/` -- Alamofire patterns + 5 Swift templates
- `generators/test-generator/` -- XCTest patterns

**Tooling:**
- `tooling/claude-tasks/` -- Task tool patterns
- `tooling/core-data/` -- Core Data patterns
- `tooling/github/` -- GitHub CLI patterns
- `tooling/keychain/` -- Keychain secure storage
- `tooling/macos-crash-recovery/` -- App crash recovery
- `tooling/macos-dnd/` -- Do Not Disturb patterns
- `tooling/macos-scenes/` -- Scene management
- `tooling/peekaboo/` -- Peekaboo MCP screen capture
- `tooling/skill-creator/` -- Skill authoring helper (+ scripts + references)
- `tooling/swift/` -- Swift language patterns
- `tooling/swiftdata/` -- SwiftData patterns (+ 4 reference files)
- `tooling/swiftui/` -- SwiftUI patterns
- `tooling/xcode-build/` -- Xcode build patterns
- `tooling/xcode-mcp/` -- Xcode MCP bridge

**Workflow:**
- `workflow/agent-shared-context/` -- Shared context for all agents
- `workflow/complete-task/` -- Task completion protocol
- `workflow/epic-notes/` -- Epic note patterns
- `workflow/error-recovery/` -- Error recovery patterns
- `workflow/plan-tasks/` -- Task planning
- `workflow/review-cycle/` -- Review cycle protocol
- `workflow/spawn-subagents/` -- Subagent spawning patterns
- `workflow/story-context/` -- Story context loading
- `workflow/submit-for-review/` -- Review submission
- `workflow/v2-schema-reference/` -- Task schema v2.0
- `workflow/validate-task/` -- Task validation
- `workflow/workflow-comments/` -- Comment format
- `workflow/workflow-state/` -- Workflow state management
- `workflow/xctest-patterns/` -- XCTest patterns

**Platform Awareness:**
- `platform-awareness/` -- This skill. Tracks Claude Code platform changes. (+ references/)

---

## 4. Commands (.claude/commands/)

### How Commands Work

Commands are Markdown files at `.claude/commands/foo.md` that create `/foo`. They have been merged into the skills system -- same frontmatter, same behavior. Skills take precedence if both share a name.

Commands support the same frontmatter fields as skills (see Section 3). Files in `.claude/commands/` continue to work indefinitely.

### What We Use: 45 Commands

**Project Setup (4):** `init-macos-project`, `setup`, `update-toolkit`, `status`

**Planning (7):** `discover`, `epic`, `feature`, `write-stories-and-tasks`, `external-review`, `approve-epic`, `backlog`

**Design (3):** `design`, `ui-polish`, `design-review`

**Build (6):** `build`, `build-story`, `build-epic`, `build-loop`, `build-story-team`, `build-epic-team`, `fix`

**Review (8):** `code-review`, `review-loop`, `qa`, `qa-loop`, `product-review`, `pm-loop`, `security-audit`, `ui-audit`

**Workflow (6):** `ticket-update`, `validate-task`, `complete-task`, `complete-epic`, `workflow-audit`, `workflow-fix`

**Testing (2):** `test`, `checkpoint`

**Release (4):** `archive`, `commit`, `pr`, `backup`

**Docs (1):** `docs`

**Maintenance (3):** `learn`, `techdebt`, `clear-context-prompt`

---

## 5. Hooks (.claude/hooks/ and settings.json)

### Hook Events (Complete List -- 25 Events)

| Event | Can Block | Matcher Input | When It Fires |
|---|---|---|---|
| `SessionStart` | No | `startup`, `resume`, `clear`, `compact` | New session or resume |
| `SessionEnd` | No | `clear`, `resume`, `logout`, `prompt_input_exit`, etc. | Session terminates |
| `InstructionsLoaded` | No | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` | CLAUDE.md or rule loaded |
| `UserPromptSubmit` | Yes | (none) | User submits prompt |
| `PreToolUse` | Yes | Tool name (e.g., `Bash`, `Edit\|Write`, `mcp__.*`) | Before tool execution |
| `PermissionRequest` | Yes | (none) | Permission dialog shown |
| `PostToolUse` | No | Tool name | After successful tool execution |
| `PostToolUseFailure` | No | Tool name | After tool failure |
| `Notification` | No | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` | Notification sent |
| `SubagentStart` | No | Agent type name | Subagent spawned |
| `SubagentStop` | Yes | Agent type name | Subagent finished |
| `TaskCreated` | Yes | (none) | Task via TaskCreate tool |
| `TaskCompleted` | Yes | (none) | Task marked complete |
| `Stop` | Yes | (none) | Main agent finished turn |
| `StopFailure` | No | `rate_limit`, `authentication_failed`, `billing_error`, etc. | API error during turn |
| `TeammateIdle` | Yes | (none) | Agent team teammate idle |
| `PreCompact` | No | `manual`, `auto` | Before context compaction |
| `PostCompact` | No | `manual`, `auto` | After compaction |
| `CwdChanged` | No | (none) | Working directory changed |
| `FileChanged` | No | Filename (basename) | Watched file changed |
| `ConfigChange` | Yes | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` | Config file changed |
| `WorktreeCreate` | Yes | (none) | Worktree created |
| `WorktreeRemove` | No | (none) | Worktree removed |
| `Elicitation` | Yes | MCP server name | MCP server requests user input |
| `ElicitationResult` | Yes | MCP server name | User responds to MCP elicitation |

### Hook Handler Types

| Type | Format | Key Fields |
|---|---|---|
| **command** | Shell script | `command`, `async` (bool), `shell` (`bash`/`powershell`) |
| **http** | POST to endpoint | `url`, `headers`, `allowedEnvVars` |
| **prompt** | LLM evaluation | `prompt`, `model` (default: fast) |
| **agent** | LLM agent evaluation | `prompt`, `model` (default: fast) |

### Common Hook Fields

| Field | Description |
|---|---|
| `type` | `command`, `http`, `prompt`, or `agent` |
| `if` | Permission rule syntax conditional (tool events only) |
| `timeout` | Seconds before cancellation |
| `statusMessage` | Custom spinner message |
| `once` | Run once per session (skills only) |

### Exit Codes (Command Hooks)

| Code | Meaning |
|---|---|
| **0** | Success. Parse stdout for JSON output. |
| **2** | Block action. Stderr sent to Claude/user. Tool call blocked (if blocking event). |
| **Other** | Non-blocking error. Stderr shown in verbose mode. |

### JSON Output Format

```json
{
  "continue": true,
  "stopReason": "reason message",
  "suppressOutput": false,
  "systemMessage": "warning message",
  "decision": "block",
  "reason": "explanation",
  "hookSpecificOutput": { ... }
}
```

### Hook Configuration Locations

| Location | Scope |
|---|---|
| `~/.claude/settings.json` | All projects (user) |
| `.claude/settings.json` | This project (shared) |
| `.claude/settings.local.json` | This project (gitignored) |
| Managed policy settings | Organization-wide |
| Plugin `hooks/hooks.json` | When plugin enabled |
| Skill/agent frontmatter | While component active |

### Environment Variables Available in Hooks

- `$CLAUDE_PROJECT_DIR` -- Project root
- `${CLAUDE_PLUGIN_ROOT}` -- Plugin installation directory
- `${CLAUDE_PLUGIN_DATA}` -- Plugin persistent data directory
- `$CLAUDE_ENV_FILE` -- Environment variable file (SessionStart, CwdChanged, FileChanged only)
- `$CLAUDE_CODE_REMOTE` -- `true` in web environments

### What We Use: 6 Hook Scripts, Bound to 6 Events

**Project settings.json hooks:**

| Event | Matcher | Hook Script | Purpose |
|---|---|---|---|
| `PreToolUse` | `Bash` | `git-guards.sh` | Gitleaks, SwiftLint, branch protection |
| `PreToolUse` | `TaskUpdate` | `review-gate.sh` | Enforce review stage transitions |
| `PostToolUse` | `Bash` | `design-skill-suggest.sh` | Suggest design system skill on build errors |
| `TaskCompleted` | (none) | `validate-task-completion.sh` | Block completion without proper comments |
| `Notification` | (none) | macOS notification via `osascript` | Alert user when attention needed |
| `ConfigChange` | (none) | `audit-config-change.sh` | Log config file changes |
| `TeammateIdle` | (none) | `validate-teammate-idle.sh` | Enforce teammate completion |

**User settings.json hooks:**

| Event | Matcher | Purpose |
|---|---|---|
| `PreCompact` | (none) | `bd prime` command |
| `SessionStart` | (none) | `bd prime` command |
| `PreToolUse` | (none) | Usage tracking |
| `PreToolUse` | `Read` | Claude docs helper hook check |
| `Stop` | (none) | Usage tracking |

---

## 6. MCP Servers

### How MCP Servers Are Configured

MCP (Model Context Protocol) servers connect Claude to external services and tools. Configured in `.mcp.json` at project root or `~/.claude/.mcp.json` for user-level.

### Transport Types

| Type | Description |
|---|---|
| `stdio` | Spawns local process, communicates via stdin/stdout |
| `http` | Connects to HTTP endpoint with streamable HTTP transport |
| `sse` | Server-sent events (legacy, prefer `http`) |
| `ws` | WebSocket connection |

### Scope Hierarchy

| Level | Location | Priority |
|---|---|---|
| Local override | `.mcp.json` (gitignored entries) | Highest |
| Project | `.mcp.json` | 2 |
| User | `~/.claude/.mcp.json` | 3 |

Same-name servers: higher priority wins. Managed setting `allowManagedMcpServersOnly` restricts to managed servers only.

### Tool Search

On by default (`ENABLE_TOOL_SEARCH=true`). Idle MCP tools consume minimal context -- full JSON schemas deferred until Claude needs them. Run `/mcp` to see token costs per server.

### What We Use

**Project-level (`.mcp.json`):**

| Server | Type | Purpose |
|---|---|---|
| `xcode` | stdio (`xcrun mcpbridge`) | 20+ Xcode build/test/read/write tools |

**User-level / system-level (available to all projects):**

| Server | Purpose |
|---|---|
| `peekaboo` | Screen capture, element inspection, UI interaction |
| `aikido` | SAST and secrets scanning |
| `trivy` | SPM CVE scanning, SBOM generation |
| `screenshot-website-fast` | Web page screenshot capture |
| `vercel` | Vercel deployment management |

---

## 7. Plugins

### What Plugins Are

Plugins are installable packages that bundle skills, agents, hooks, MCP servers, and LSP servers into a single unit. Plugin skills are namespaced (`/plugin-name:skill-name`) to prevent conflicts.

### Plugin Structure

```
my-plugin/
  .claude-plugin/
    plugin.json          # Manifest: name, description, version, author
  commands/              # Slash commands
  agents/                # Custom agents
  skills/                # Agent Skills with SKILL.md
  hooks/
    hooks.json           # Hook configurations
  .mcp.json              # MCP server configurations
  .lsp.json              # LSP server configurations
  settings.json          # Default settings (currently only `agent` key)
```

### Plugin Management

- Install: `claude plugin install <name>@<marketplace>`
- List: `claude plugin list`
- Remove: `claude plugin remove <name>`
- Reload: `/reload-plugins` in session
- Test locally: `claude --plugin-dir ./my-plugin`

### Security Restrictions

Plugin agents cannot use `hooks`, `mcpServers`, or `permissionMode` frontmatter fields (silently ignored).

### Marketplace Distribution

Plugins distributed via marketplace registries. Official marketplace submission via claude.ai or platform.claude.com.

### What We Use: 3 Plugins

| Plugin | Source | Purpose |
|---|---|---|
| `coderabbit@claude-plugins-official` | Official marketplace | AI code review (`/coderabbit:review`) |
| `swift-lsp@claude-plugins-official` | Official marketplace | Swift language server protocol (real-time diagnostics) |
| `pyright-lsp@claude-plugins-official` | Official marketplace | Python language server protocol |

---

## 8. Settings

### Settings File Hierarchy (Precedence Order)

| Priority | Location | Scope | Overridable |
|---|---|---|---|
| 1 (highest) | Managed settings (plist/registry/system-level) | Organization | No |
| 2 | `--` CLI flags | Session | -- |
| 3 | `.claude/settings.local.json` | Project (gitignored) | -- |
| 4 | `.claude/settings.json` | Project (shared) | -- |
| 5 (lowest) | `~/.claude/settings.json` | User | -- |

### Key Settings Categories

| Category | Key Settings |
|---|---|
| **Permissions** | `permissions.allow[]`, `permissions.deny[]`, `permissions.ask[]` |
| **Hooks** | `hooks.PreToolUse[]`, `hooks.PostToolUse[]`, `hooks.TaskCompleted[]`, etc. |
| **Environment** | `env.*` (environment variables injected into session) |
| **MCP** | `allowedMcpServers`, `deniedMcpServers`, `allowManagedMcpServersOnly` |
| **Plugins** | `enabledPlugins.*` |
| **Behavior** | `defaultMode`, `agent`, `teammateMode`, `statusLine` |
| **Model** | `effortLevel`, `alwaysThinkingEnabled` |
| **Security** | `disableBypassPermissionsMode`, `disableAutoMode`, `sandbox.*` |
| **Memory** | `autoMemoryEnabled`, `autoMemoryDirectory`, `claudeMdExcludes` |
| **Auto Mode** | `autoMode.environment[]`, `autoMode.allow[]`, `autoMode.soft_deny[]` |

### Managed-Only Settings

| Setting | Description |
|---|---|
| `allowManagedPermissionRulesOnly` | Only managed permission rules apply |
| `allowManagedHooksOnly` | Only managed + SDK hooks run |
| `allowManagedMcpServersOnly` | Only managed MCP servers |
| `allowedChannelPlugins` | Allowlist of channel plugins |
| `blockedMarketplaces` | Blocked marketplace sources |
| `sandbox.network.allowManagedDomainsOnly` | Only managed domain allowlist |
| `sandbox.filesystem.allowManagedReadPathsOnly` | Only managed read paths |
| `strictKnownMarketplaces` | Restrict marketplace additions |

### What We Configure

**Project `.claude/settings.json`:**
- `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` -- Enable agent teams
- `hooks` -- 6 event bindings (PreToolUse, PostToolUse, TaskCompleted, Notification, ConfigChange, TeammateIdle)
- `permissions.allow` -- Read, Write, Edit, Glob, Grep, Bash, Task, WebFetch, WebSearch, `mcp__xcode__*`
- `permissions.deny` -- .env files, secrets, credentials, destructive git, task file edits
- `permissions.ask` -- `git push *`, `git reset *`

**User `~/.claude/settings.json`:**
- `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"`
- `hooks` -- PreCompact, SessionStart, PreToolUse (usage tracking + docs helper), Stop
- `statusLine` -- Custom status line command
- `enabledPlugins` -- pyright-lsp, swift-lsp, coderabbit
- `alwaysThinkingEnabled: true`
- `effortLevel: "high"`
- `voiceEnabled: true`
- `skipDangerousModePermissionPrompt: true`

---

## 9. Memory System

### CLAUDE.md Hierarchy

| Scope | Location | Loaded |
|---|---|---|
| **Managed policy** | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | Always, cannot exclude |
| **User** | `~/.claude/CLAUDE.md` | Every session |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Every session |
| **Nested** | `./subdir/CLAUDE.md` | On-demand when working in subdir |

Loading: walks up directory tree from cwd. Subdirectory CLAUDE.md files load on-demand.

### Rules System (.claude/rules/)

- Global rules: loaded every session
- Path-specific rules: `paths` frontmatter with glob patterns, loaded when matching files accessed
- User rules: `~/.claude/rules/` (all projects, lower priority)
- Supports symlinks for cross-project sharing

### @path Imports

CLAUDE.md files can import other files with `@path/to/file` syntax. Relative paths resolve from the file containing the import. Max depth: 5 hops. First-time external imports require approval dialog.

### Auto Memory

- Location: `~/.claude/projects/<project>/memory/`
- Entrypoint: `MEMORY.md` (first 200 lines or 25KB loaded per session)
- Topic files loaded on-demand by Claude
- Toggle: `/memory` command or `autoMemoryEnabled` setting
- Override directory: `autoMemoryDirectory` setting
- Disable: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`

### --add-dir

Gives Claude access to additional directories. Skills from `--add-dir` directories are loaded. CLAUDE.md from `--add-dir` directories NOT loaded unless `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`.

### What We Use

- `CLAUDE.md` at project root (212 lines) -- tech stack, rules, workflow, delegation, review cycle
- `.claude/rules/global/` -- 11 rule files (accessibility, context-protection, dependency-security, error-handling, localization, logging, performance, swift-strict, task-hygiene, task-state-updates, testing-requirements)
- `.claude/rules/path/` -- 4 path-scoped rules (api-clients, core-data-migrations, menus, swiftui-views)
- `.claude/rules/workflow/` -- 3 workflow rules (git-workflow, task-completion, task-planning)
- `.claude/memory/feedback_preexisting_test_failures.md` -- Project-level memory
- `~/.claude/projects/.../memory/MEMORY.md` -- Auto memory (user-level)

---

## 10. Permissions System

### Permission Modes

| Mode | Description |
|---|---|
| `default` | Standard prompting for first use of each tool |
| `acceptEdits` | Auto-accept file edit permissions for session |
| `plan` | Read-only analysis, no modifications |
| `auto` | AI classifier auto-approves safe actions (research preview) |
| `dontAsk` | Auto-deny unless pre-approved via rules |
| `bypassPermissions` | Skip prompts (still protects .git, .claude, .vscode, .idea) |

### Permission Rule Syntax

Format: `Tool` or `Tool(specifier)`. Evaluated: deny -> ask -> allow (first match wins).

| Pattern | Example | Matches |
|---|---|---|
| Tool name only | `Bash` | All uses of Bash |
| Exact specifier | `Bash(npm run build)` | Exact command |
| Wildcard | `Bash(npm run *)` | Commands starting with `npm run` |
| Read/Edit paths | `Read(./.env)`, `Edit(/src/**/*.ts)` | Gitignore-style paths |
| Absolute path | `Read(//Users/alice/secrets/**)` | Absolute filesystem path |
| Home path | `Read(~/.zshrc)` | Home directory relative |
| WebFetch domain | `WebFetch(domain:example.com)` | Domain filter |
| MCP tools | `mcp__puppeteer__*` | All tools from MCP server |
| Agent control | `Agent(Explore)` | Control subagent access |
| Skill control | `Skill(deploy *)` | Control skill access |

### Settings Precedence for Permissions

Managed > CLI flags > Local project > Shared project > User. If denied at any level, cannot be overridden.

### What We Configure

**Allow:** Read, Write, Edit, Glob, Grep, Bash, Task, WebFetch, WebSearch, `mcp__xcode__*`
**Deny:** `.env`, `.env.*`, `secrets/**`, `*credentials*`, `*secret*`, `rm -rf /`, force push main/master, `git reset --hard`, task file writes
**Ask:** `git push *`, `git reset *`

---

## 11. CLI & Headless

### Key CLI Flags

| Flag | Purpose |
|---|---|
| `--model <name>` | Set model (alias: `sonnet`, `opus`, `haiku`, or full ID) |
| `--agent <name>` | Run session as specified agent |
| `--agents <json>` | Define dynamic subagents for session |
| `--add-dir <path>` | Add working directories |
| `-p` / `--print` | Non-interactive (headless) mode |
| `-c` / `--continue` | Continue most recent conversation |
| `-r` / `--resume <id>` | Resume specific session |
| `--bare` | Minimal mode: skip hooks, skills, plugins, MCP, memory, CLAUDE.md |
| `--allowedTools` | Auto-approve specific tools |
| `--disallowedTools` | Remove tools entirely |
| `--tools` | Restrict available tools |
| `--output-format` | `text`, `json`, `stream-json` |
| `--json-schema` | Structured output conforming to schema |
| `--max-turns` | Limit agentic turns (print mode) |
| `--max-budget-usd` | Spending cap (print mode) |
| `--append-system-prompt` | Add to default system prompt |
| `--system-prompt` | Replace entire system prompt |
| `--permission-mode` | Set permission mode |
| `--dangerously-skip-permissions` | Bypass permissions |
| `--mcp-config` | Load MCP servers from file |
| `--plugin-dir` | Load plugin from directory |
| `--worktree` / `-w` | Start in isolated git worktree |
| `--effort` | Set effort level (`low`, `medium`, `high`, `max`) |
| `--chrome` | Enable Chrome browser integration |
| `--debug` | Enable debug logging |
| `--verbose` | Full turn-by-turn output |
| `--teammate-mode` | Agent team display: `auto`, `in-process`, `tmux` |
| `--remote` | Create web session on claude.ai |
| `--remote-control` / `--rc` | Enable remote control from claude.ai |
| `--teleport` | Resume web session locally |
| `--from-pr` | Resume sessions linked to GitHub PR |
| `--channels` | MCP channel notifications |

### Headless Mode / Agent SDK

- `claude -p "query"` -- Run non-interactively, print response, exit
- `--bare` -- Skip all auto-discovery for fast CI/CD
- `--output-format json` -- Structured output with session ID and metadata
- `--output-format stream-json` -- Real-time streaming with partial messages
- `--json-schema` -- Validated structured output matching JSON Schema
- Agent SDK available as Python and TypeScript packages
- Supports `--continue` and `--resume` for multi-turn workflows

### Agent Teams (Experimental)

- Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in env or settings
- Lead session coordinates teammates, shared task list, peer messaging
- Display modes: `in-process` (default) or `tmux` (split panes)
- Teammates have independent context windows
- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`
- Hooks: `TeammateIdle`, `TaskCreated`, `TaskCompleted`
- Limitations: no session resume, no nested teams, one team per session

### What We Use

- `--model` for coordinator model selection at spawn time
- Agent teams enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `/build-story-team` and `/build-epic-team` commands for team-based builds
- `--agent` not used (agents spawned via Task tool instead)
- Headless mode not currently used in our workflow

---

## 12. What We Use (Summary)

| Claude Code Feature | Our Files |
|---|---|
| **CLAUDE.md** | `CLAUDE.md` (root) |
| **Rules (global)** | `.claude/rules/global/` (11 files) |
| **Rules (path)** | `.claude/rules/path/` (4 files) |
| **Rules (workflow)** | `.claude/rules/workflow/` (3 files) |
| **Agents** | `.claude/agents/` (17 agents) |
| **Skills** | `.claude/skills/` (36 skills across 8 categories) |
| **Commands** | `.claude/commands/` (45 commands) |
| **Hooks (project)** | `.claude/hooks/` (6 scripts), `settings.json` (6 event bindings) |
| **Hooks (user)** | `~/.claude/settings.json` (4 event bindings) |
| **MCP (project)** | `.mcp.json` (xcode) |
| **MCP (user)** | peekaboo, aikido, trivy, screenshot-website-fast, vercel |
| **Plugins** | coderabbit, swift-lsp, pyright-lsp (all official marketplace) |
| **Permissions** | `settings.json` allow/deny/ask arrays |
| **Environment** | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` |
| **Memory** | `.claude/memory/` (1 file), auto memory enabled |
| **Templates** | `.claude/templates/` (task templates, doc templates, PR template, lint config) |
| **Scripts** | `.claude/scripts/` (22 helper scripts) |
| **Config** | `.claude/config/git.conf` |
| **Docs** | `.claude/docs/` (5 workflow docs) |

---

## 13. What We Don't Use (Yet)

| Feature | Status | Why Not |
|---|---|---|
| **`context: fork` on skills** | Available | Not needed -- our agents already provide context isolation via `skills:` preloading |
| **Plugin authoring** | Available | We consume plugins but haven't packaged our toolkit as one. Future consideration for distribution. |
| **Plugin marketplaces** | Available | Same as above -- we use official marketplace only |
| **Scheduled tasks (`/loop`)** | Available | Our workflow is human-initiated per epic. No polling use case identified yet. |
| **HTTP hooks** | Available | All our hooks are command-type shell scripts. HTTP hooks would require a running server. |
| **Prompt hooks** | Available | We use shell scripts for deterministic validation. Prompt hooks add LLM latency/cost. |
| **Agent hooks (type: agent)** | Available | Same as prompt hooks -- deterministic scripts preferred for our gate-keeping use cases. |
| **Chrome integration** | Available | macOS native app -- no web testing needed. Visual QA uses Peekaboo MCP instead. |
| **`--bare` mode** | Available | No CI/CD pipeline yet. Would use for headless builds if we add GitHub Actions. |
| **`--json-schema` structured output** | Available | No programmatic consumption of Claude output. Would use if integrating with external systems. |
| **`--system-prompt` / `--append-system-prompt`** | Available | We use CLAUDE.md + agent system prompts instead. CLI flags are for headless/SDK use. |
| **Remote Control** | Available | Personal use app -- no team collaboration via claude.ai needed. |
| **Web sessions (`--remote`)** | Available | Same as remote control -- local terminal is primary interface. |
| **`--teleport`** | Available | No web sessions to teleport. |
| **Auto mode (permission classifier)** | Research preview | Experimental. We use `bypassPermissions` on agents, explicit allow/deny for coordinator. |
| **`--channels`** | Research preview | MCP channel notifications. Too new, no use case identified. |
| **Worktree isolation on agents** | Available (`isolation: worktree`) | Our agents work in the epic branch directly. Worktrees would add merge complexity. |
| **Agent `background: true`** | Available | We run agents in foreground for synchronous completion tracking. |
| **Agent `initialPrompt`** | Available | We don't use `--agent` as session mode. Agents are spawned as subagents. |
| **Agent `effort` override** | Available | We use user-level `effortLevel: "high"` globally instead of per-agent. |
| **Skill `paths` frontmatter** | Available | Our path-scoped rules handle this. Skills are invoked explicitly or via agent preloading. |
| **Skill `shell: powershell`** | Available | macOS only. |
| **`claudeMdExcludes`** | Available | Single-project repo, no monorepo CLAUDE.md conflicts. |
| **`@path` imports in CLAUDE.md** | Available | Our CLAUDE.md is self-contained. Rules split into `.claude/rules/` instead. |
| **AGENTS.md** | Available | We use CLAUDE.md directly. |
| **Sandbox** (filesystem/network) | Available | Personal use app, `bypassPermissions` mode. Sandbox for CI/container use. |
| **`--from-pr`** | Available | No GitHub PR-linked sessions yet. Would use with `/pr` integration. |
| **LSP custom configuration** | Available | Using official marketplace plugins for Swift and Python LSP. |
| **`autoMode` classifier tuning** | Available | Not using auto mode. |
| **`--fallback-model`** | Available | Not using headless mode where this applies. |
| **`/batch`** | Bundled skill | Interesting for large refactors. Not yet integrated into our workflow. |
| **Agent persistent memory (`memory: user`)** | Available | We use `memory: project` on 2 agents. User-scope would help cross-project learning. |
| **`--fork-session`** | Available | No branching conversation workflow needed yet. |
| **Status line** | Available | Configured at user level (`~/.claude/settings.json`). |
| **`/debug`** | Bundled skill | Available for troubleshooting. Not routinely used. |

---

## 14. Undocumented / Community-Discovered Features

Features found via community sources (Piebald-AI system prompt archive, GitHub issues, X/Twitter) that are not in the official changelog or docs. **Always verify before adopting.**

| Feature | Status | Version | Source | Notes |
|---------|--------|---------|--------|-------|
| **`/dream` (AutoDream)** | Broken / Partial | v2.1.78+ (infra), v2.1.81+ (UI toggle) | Piebald-AI, GitHub #38461 | Memory consolidation agent: orient, gather, consolidate, prune. Toggle visible in `/memory` but `/dream` returns "Unknown skill" through v2.1.85. Auto mode behind server-side flag `tengu_onyx_plover`. PR #39299 filed to fix. **Do not adopt yet.** |
| **`/security-review`** | Likely available | ~v2.1.70 | Changelog fixes imply it exists | Built-in security scan of pending branch changes. Not officially documented. May complement our `/security-audit` skill. **Needs CLI test.** |
| **`/insights`** | Unknown | Unknown | Not in changelog | Listed in docs command reference but no changelog "Added" entry. **Needs CLI test.** |

### Verification Status Key
- **Confirmed** — In changelog + works in our version
- **Likely available** — Changelog fixes reference it, but no "Added" entry
- **Broken / Partial** — Infrastructure exists but command doesn't work
- **Unknown** — Found in docs but not changelog, untested

---

## 15. Ecosystem Awareness (Non-CLI)

Features in the broader Anthropic ecosystem that are NOT Claude Code CLI features. Tracked for awareness only — not actionable for our toolkit.

| Feature | Product | Launched | What It Does |
|---------|---------|----------|-------------|
| **Computer Use** | Claude Desktop (Cowork) | March 24, 2026 | Keyboard/mouse control of macOS desktop. Requires Desktop app, Pro/Max plan, accessibility permissions. |
| **Dispatch** | Claude Desktop | ~Jan 2026 | Send tasks from phone to desktop Claude session. Requires Desktop app + mobile app. |
| **Cowork** | Claude Desktop | Jan 12, 2026 | Agentic capabilities for non-developers via Desktop app. Produces documents, organizes files, synthesizes research. |
| **Slack Integration** | Claude in Slack | Dec 8, 2025 | @mention Claude in Slack threads to spin up coding sessions. Research preview. |
| **Cloud Scheduled Tasks** | claude.ai/code (Web) | ~March 2026 | Cron-scheduled prompts that run on Anthropic cloud infrastructure without local machine. |
| **Claude.ai Connectors** | claude.ai | Various | Slack, Gmail, and other cloud connectors. Available in Claude Code via `--channels` but the connectors themselves are a claude.ai feature. |

### Why Track These?
- User may ask about them (we should know the boundary)
- Some may migrate to CLI features in future versions
- Ecosystem context helps understand Anthropic's direction
