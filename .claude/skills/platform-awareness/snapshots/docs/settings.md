<\!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/settings.md -->
     1→> ## Documentation Index
     2→> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
     3→> Use this file to discover all available pages before exploring further.
     4→
     5→# Claude Code settings
     6→
     7→> Configure Claude Code with global and project-level settings, and environment variables.
     8→
     9→Claude Code offers a variety of settings to configure its behavior to meet your needs. You can configure Claude Code by running the `/config` command when using the interactive REPL, which opens a tabbed Settings interface where you can view status information and modify configuration options.
    10→
    11→## Configuration scopes
    12→
    13→Claude Code uses a **scope system** to determine where configurations apply and who they're shared with. Understanding scopes helps you decide how to configure Claude Code for personal use, team collaboration, or enterprise deployment.
    14→
    15→### Available scopes
    16→
    17→| Scope       | Location                                                                           | Who it affects                       | Shared with team?      |
    18→| :---------- | :--------------------------------------------------------------------------------- | :----------------------------------- | :--------------------- |
    19→| **Managed** | Server-managed settings, plist / registry, or system-level `managed-settings.json` | All users on the machine             | Yes (deployed by IT)   |
    20→| **User**    | `~/.claude/` directory                                                             | You, across all projects             | No                     |
    21→| **Project** | `.claude/` in repository                                                           | All collaborators on this repository | Yes (committed to git) |
    22→| **Local**   | `.claude/settings.local.json`                                                      | You, in this repository only         | No (gitignored)        |
    23→
    24→### When to use each scope
    25→
    26→**Managed scope** is for:
    27→
    28→* Security policies that must be enforced organization-wide
    29→* Compliance requirements that can't be overridden
    30→* Standardized configurations deployed by IT/DevOps
    31→
    32→**User scope** is best for:
    33→
    34→* Personal preferences you want everywhere (themes, editor settings)
    35→* Tools and plugins you use across all projects
    36→* API keys and authentication (stored securely)
    37→
    38→**Project scope** is best for:
    39→
    40→* Team-shared settings (permissions, hooks, MCP servers)
    41→* Plugins the whole team should have
    42→* Standardizing tooling across collaborators
    43→
    44→**Local scope** is best for:
    45→
    46→* Personal overrides for a specific project
    47→* Testing configurations before sharing with the team
    48→* Machine-specific settings that won't work for others
    49→
    50→### How scopes interact
    51→
    52→When the same setting is configured in multiple scopes, more specific scopes take precedence:
    53→
    54→1. **Managed** (highest) - can't be overridden by anything
    55→2. **Command line arguments** - temporary session overrides
    56→3. **Local** - overrides project and user settings
    57→4. **Project** - overrides user settings
    58→5. **User** (lowest) - applies when nothing else specifies the setting
    59→
    60→For example, if a permission is allowed in user settings but denied in project settings, the project setting takes precedence and the permission is blocked.
    61→
    62→### What uses scopes
    63→
    64→Scopes apply to many Claude Code features:
    65→
    66→| Feature         | User location             | Project location                   | Local location                 |
    67→| :-------------- | :------------------------ | :--------------------------------- | :----------------------------- |
    68→| **Settings**    | `~/.claude/settings.json` | `.claude/settings.json`            | `.claude/settings.local.json`  |
    69→| **Subagents**   | `~/.claude/agents/`       | `.claude/agents/`                  | None                           |
    70→| **MCP servers** | `~/.claude.json`          | `.mcp.json`                        | `~/.claude.json` (per-project) |
    71→| **Plugins**     | `~/.claude/settings.json` | `.claude/settings.json`            | `.claude/settings.local.json`  |
    72→| **CLAUDE.md**   | `~/.claude/CLAUDE.md`     | `CLAUDE.md` or `.claude/CLAUDE.md` | None                           |
    73→
    74→***
    75→
    76→## Settings files
    77→
    78→The `settings.json` file is the official mechanism for configuring Claude
    79→Code through hierarchical settings:
    80→
    81→* **User settings** are defined in `~/.claude/settings.json` and apply to all
    82→  projects.
    83→* **Project settings** are saved in your project directory:
    84→  * `.claude/settings.json` for settings that are checked into source control and shared with your team
    85→  * `.claude/settings.local.json` for settings that are not checked in, useful for personal preferences and experimentation. Claude Code will configure git to ignore `.claude/settings.local.json` when it is created.
    86→* **Managed settings**: For organizations that need centralized control, Claude Code supports multiple delivery mechanisms for managed settings. All use the same JSON format and cannot be overridden by user or project settings:
    87→
    88→  * **Server-managed settings**: delivered from Anthropic's servers via the Claude.ai admin console. See [server-managed settings](/en/server-managed-settings).
    89→  * **MDM/OS-level policies**: delivered through native device management on macOS and Windows:
    90→    * macOS: `com.anthropic.claudecode` managed preferences domain (deployed via configuration profiles in Jamf, Kandji, or other MDM tools)
    91→    * Windows: `HKLM\SOFTWARE\Policies\ClaudeCode` registry key with a `Settings` value (REG\_SZ or REG\_EXPAND\_SZ) containing JSON (deployed via Group Policy or Intune)
    92→    * Windows (user-level): `HKCU\SOFTWARE\Policies\ClaudeCode` (lowest policy priority, only used when no admin-level source exists)
    93→  * **File-based**: `managed-settings.json` and `managed-mcp.json` deployed to system directories:
    94→
    95→    * macOS: `/Library/Application Support/ClaudeCode/`
    96→    * Linux and WSL: `/etc/claude-code/`
    97→    * Windows: `C:\Program Files\ClaudeCode\`
    98→
    99→    <Warning>
   100→      The legacy Windows path `C:\ProgramData\ClaudeCode\managed-settings.json` is no longer supported as of v2.1.75. Administrators who deployed settings to that location must migrate files to `C:\Program Files\ClaudeCode\managed-settings.json`.
   101→    </Warning>
   102→
   103→    File-based managed settings also support a drop-in directory at `managed-settings.d/` in the same system directory alongside `managed-settings.json`. This lets separate teams deploy independent policy fragments without coordinating edits to a single file.
   104→
   105→    Following the systemd convention, `managed-settings.json` is merged first as the base, then all `*.json` files in the drop-in directory are sorted alphabetically and merged on top. Later files override earlier ones for scalar values; arrays are concatenated and de-duplicated; objects are deep-merged. Hidden files starting with `.` are ignored.
   106→
   107→    Use numeric prefixes to control merge order, for example `10-telemetry.json` and `20-security.json`.
   108→
   109→  See [managed settings](/en/permissions#managed-only-settings) and [Managed MCP configuration](/en/mcp#managed-mcp-configuration) for details.
   110→
   111→  <Note>
   112→    Managed deployments can also restrict **plugin marketplace additions** using
   113→    `strictKnownMarketplaces`. For more information, see [Managed marketplace restrictions](/en/plugin-marketplaces#managed-marketplace-restrictions).
   114→  </Note>
   115→* **Other configuration** is stored in `~/.claude.json`. This file contains your preferences (theme, notification settings, editor mode), OAuth session, [MCP server](/en/mcp) configurations for user and local scopes, per-project state (allowed tools, trust settings), and various caches. Project-scoped MCP servers are stored separately in `.mcp.json`.
   116→
   117→<Note>
   118→  Claude Code automatically creates timestamped backups of configuration files and retains the five most recent backups to prevent data loss.
   119→</Note>
   120→
   121→```JSON Example settings.json theme={null}
   122→{
   123→  "$schema": "https://json.schemastore.org/claude-code-settings.json",
   124→  "permissions": {
   125→    "allow": [
   126→      "Bash(npm run lint)",
   127→      "Bash(npm run test *)",
   128→      "Read(~/.zshrc)"
   129→    ],
   130→    "deny": [
   131→      "Bash(curl *)",
   132→      "Read(./.env)",
   133→      "Read(./.env.*)",
   134→      "Read(./secrets/**)"
   135→    ]
   136→  },
   137→  "env": {
   138→    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
   139→    "OTEL_METRICS_EXPORTER": "otlp"
   140→  },
   141→  "companyAnnouncements": [
   142→    "Welcome to Acme Corp! Review our code guidelines at docs.acme.com",
   143→    "Reminder: Code reviews required for all PRs",
   144→    "New security policy in effect"
   145→  ]
   146→}
   147→```
   148→
   149→The `$schema` line in the example above points to the [official JSON schema](https://json.schemastore.org/claude-code-settings.json) for Claude Code settings. Adding it to your `settings.json` enables autocomplete and inline validation in VS Code, Cursor, and any other editor that supports JSON schema validation.
   150→
   151→### Available settings
   152→
   153→`settings.json` supports a number of options:
   154→
   155→| Key                               | Description                                                                                                                                                                                                                                                                                                                                           | Example                                                                 |
   156→| :-------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------- |
   157→| `apiKeyHelper`                    | Custom script, to be executed in `/bin/sh`, to generate an auth value. This value will be sent as `X-Api-Key` and `Authorization: Bearer` headers for model requests                                                                                                                                                                                  | `/bin/generate_temp_api_key.sh`                                         |
   158→| `autoMemoryDirectory`             | Custom directory for [auto memory](/en/memory#storage-location) storage. Accepts `~/`-expanded paths. Not accepted in project settings (`.claude/settings.json`) to prevent shared repos from redirecting memory writes to sensitive locations. Accepted from policy, local, and user settings                                                        | `"~/my-memory-dir"`                                                     |
   159→| `cleanupPeriodDays`               | Sessions inactive for longer than this period are deleted at startup (default: 30 days).<br /><br />Setting to `0` deletes all existing transcripts at startup and disables session persistence entirely. No new `.jsonl` files are written, `/resume` shows no conversations, and hooks receive an empty `transcript_path`.                          | `20`                                                                    |
   160→| `companyAnnouncements`            | Announcement to display to users at startup. If multiple announcements are provided, they will be cycled through at random.                                                                                                                                                                                                                           | `["Welcome to Acme Corp! Review our code guidelines at docs.acme.com"]` |
   161→| `env`                             | Environment variables that will be applied to every session                                                                                                                                                                                                                                                                                           | `{"FOO": "bar"}`                                                        |
   162→| `attribution`                     | Customize attribution for git commits and pull requests. See [Attribution settings](#attribution-settings)                                                                                                                                                                                                                                            | `{"commit": "🤖 Generated with Claude Code", "pr": ""}`                 |
   163→| `includeCoAuthoredBy`             | **Deprecated**: Use `attribution` instead. Whether to include the `co-authored-by Claude` byline in git commits and pull requests (default: `true`)                                                                                                                                                                                                   | `false`                                                                 |
   164→| `includeGitInstructions`          | Include built-in commit and PR workflow instructions and the git status snapshot in Claude's system prompt (default: `true`). Set to `false` to remove both, for example when using your own git workflow skills. The `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` environment variable takes precedence over this setting when set                         | `false`                                                                 |
   165→| `permissions`                     | See table below for structure of permissions.                                                                                                                                                                                                                                                                                                         |                                                                         |
   166→| `autoMode`                        | Customize what the [auto mode](/en/permission-modes#eliminate-prompts-with-auto-mode) classifier blocks and allows. Contains `environment`, `allow`, and `soft_deny` arrays of prose rules. See [Configure the auto mode classifier](/en/permissions#configure-the-auto-mode-classifier). Not read from shared project settings                       | `{"environment": ["Trusted repo: github.example.com/acme"]}`            |
   167→| `disableAutoMode`                 | Set to `"disable"` to prevent [auto mode](/en/permission-modes#eliminate-prompts-with-auto-mode) from being activated. Removes `auto` from the `Shift+Tab` cycle and rejects `--permission-mode auto` at startup. Most useful in [managed settings](/en/permissions#managed-settings) where users cannot override it                                  | `"disable"`                                                             |
   168→| `useAutoModeDuringPlan`           | Whether plan mode uses auto mode semantics when auto mode is available. Default: `true`. Not read from shared project settings. Appears in `/config` as "Use auto mode during plan"                                                                                                                                                                   | `false`                                                                 |
   169→| `disableDeepLinkRegistration`     | Set to `"disable"` to prevent Claude Code from registering the `claude-cli://` protocol handler with the operating system on startup. Deep links let external tools open a Claude Code session with a pre-filled prompt via `claude-cli://open?q=...`. Useful in environments where protocol handler registration is restricted or managed separately | `"disable"`                                                             |
   170→| `hooks`                           | Configure custom commands to run at lifecycle events. See [hooks documentation](/en/hooks) for format                                                                                                                                                                                                                                                 | See [hooks](/en/hooks)                                                  |
   171→| `defaultShell`                    | Default shell for input-box `!` commands. Accepts `"bash"` (default) or `"powershell"`. Setting `"powershell"` routes interactive `!` commands through PowerShell on Windows. Requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`. See [PowerShell tool](/en/tools-reference#powershell-tool)                                                                | `"powershell"`                                                          |
   172→| `disableAllHooks`                 | Disable all [hooks](/en/hooks) and any custom [status line](/en/statusline)                                                                                                                                                                                                                                                                           | `true`                                                                  |
   173→| `allowManagedHooksOnly`           | (Managed settings only) Prevent loading of user, project, and plugin hooks. Only allows managed hooks and SDK hooks. See [Hook configuration](#hook-configuration)                                                                                                                                                                                    | `true`                                                                  |
   174→| `allowedHttpHookUrls`             | Allowlist of URL patterns that HTTP hooks may target. Supports `*` as a wildcard. When set, hooks with non-matching URLs are blocked. Undefined = no restriction, empty array = block all HTTP hooks. Arrays merge across settings sources. See [Hook configuration](#hook-configuration)                                                             | `["https://hooks.example.com/*"]`                                       |
   175→| `httpHookAllowedEnvVars`          | Allowlist of environment variable names HTTP hooks may interpolate into headers. When set, each hook's effective `allowedEnvVars` is the intersection with this list. Undefined = no restriction. Arrays merge across settings sources. See [Hook configuration](#hook-configuration)                                                                 | `["MY_TOKEN", "HOOK_SECRET"]`                                           |
   176→| `allowManagedPermissionRulesOnly` | (Managed settings only) Prevent user and project settings from defining `allow`, `ask`, or `deny` permission rules. Only rules in managed settings apply. See [Managed-only settings](/en/permissions#managed-only-settings)                                                                                                                          | `true`                                                                  |
   177→| `allowManagedMcpServersOnly`      | (Managed settings only) Only `allowedMcpServers` from managed settings are respected. `deniedMcpServers` still merges from all sources. Users can still add MCP servers, but only the admin-defined allowlist applies. See [Managed MCP configuration](/en/mcp#managed-mcp-configuration)                                                             | `true`                                                                  |
   178→| `model`                           | Override the default model to use for Claude Code                                                                                                                                                                                                                                                                                                     | `"claude-sonnet-4-6"`                                                   |
   179→| `availableModels`                 | Restrict which models users can select via `/model`, `--model`, Config tool, or `ANTHROPIC_MODEL`. Does not affect the Default option. See [Restrict model selection](/en/model-config#restrict-model-selection)                                                                                                                                      | `["sonnet", "haiku"]`                                                   |
   180→| `modelOverrides`                  | Map Anthropic model IDs to provider-specific model IDs such as Bedrock inference profile ARNs. Each model picker entry uses its mapped value when calling the provider API. See [Override model IDs per version](/en/model-config#override-model-ids-per-version)                                                                                     | `{"claude-opus-4-6": "arn:aws:bedrock:..."}`                            |
   181→| `effortLevel`                     | Persist the [effort level](/en/model-config#adjust-effort-level) across sessions. Accepts `"low"`, `"medium"`, or `"high"`. Written automatically when you run `/effort low`, `/effort medium`, or `/effort high`. Supported on Opus 4.6 and Sonnet 4.6                                                                                               | `"medium"`                                                              |
   182→| `otelHeadersHelper`               | Script to generate dynamic OpenTelemetry headers. Runs at startup and periodically (see [Dynamic headers](/en/monitoring-usage#dynamic-headers))                                                                                                                                                                                                      | `/bin/generate_otel_headers.sh`                                         |
   183→| `statusLine`                      | Configure a custom status line to display context. See [`statusLine` documentation](/en/statusline)                                                                                                                                                                                                                                                   | `{"type": "command", "command": "~/.claude/statusline.sh"}`             |
   184→| `fileSuggestion`                  | Configure a custom script for `@` file autocomplete. See [File suggestion settings](#file-suggestion-settings)                                                                                                                                                                                                                                        | `{"type": "command", "command": "~/.claude/file-suggestion.sh"}`        |
   185→| `respectGitignore`                | Control whether the `@` file picker respects `.gitignore` patterns. When `true` (default), files matching `.gitignore` patterns are excluded from suggestions                                                                                                                                                                                         | `false`                                                                 |
   186→| `outputStyle`                     | Configure an output style to adjust the system prompt. See [output styles documentation](/en/output-styles)                                                                                                                                                                                                                                           | `"Explanatory"`                                                         |
   187→| `agent`                           | Run the main thread as a named subagent. Applies that subagent's system prompt, tool restrictions, and model. See [Invoke subagents explicitly](/en/sub-agents#invoke-subagents-explicitly)                                                                                                                                                           | `"code-reviewer"`                                                       |
   188→| `forceLoginMethod`                | Use `claudeai` to restrict login to Claude.ai accounts, `console` to restrict login to Claude Console (API usage billing) accounts                                                                                                                                                                                                                    | `claudeai`                                                              |
   189→| `forceLoginOrgUUID`               | Specify the UUID of an organization to automatically select it during login, bypassing the organization selection step. Requires `forceLoginMethod` to be set                                                                                                                                                                                         | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`                                |
   190→| `enableAllProjectMcpServers`      | Automatically approve all MCP servers defined in project `.mcp.json` files                                                                                                                                                                                                                                                                            | `true`                                                                  |
   191→| `enabledMcpjsonServers`           | List of specific MCP servers from `.mcp.json` files to approve                                                                                                                                                                                                                                                                                        | `["memory", "github"]`                                                  |
   192→| `disabledMcpjsonServers`          | List of specific MCP servers from `.mcp.json` files to reject                                                                                                                                                                                                                                                                                         | `["filesystem"]`                                                        |
   193→| `channelsEnabled`                 | (Managed settings only) Allow [channels](/en/channels) for Team and Enterprise users. Unset or `false` blocks channel message delivery regardless of what users pass to `--channels`                                                                                                                                                                  | `true`                                                                  |
   194→| `allowedChannelPlugins`           | (Managed settings only) Allowlist of channel plugins that may push messages. Replaces the default Anthropic allowlist when set. Undefined = fall back to the default, empty array = block all channel plugins. Requires `channelsEnabled: true`. See [Restrict which channel plugins can run](/en/channels#restrict-which-channel-plugins-can-run)    | `[{ "marketplace": "claude-plugins-official", "plugin": "telegram" }]`  |
   195→| `allowedMcpServers`               | When set in managed-settings.json, allowlist of MCP servers users can configure. Undefined = no restrictions, empty array = lockdown. Applies to all scopes. Denylist takes precedence. See [Managed MCP configuration](/en/mcp#managed-mcp-configuration)                                                                                            | `[{ "serverName": "github" }]`                                          |
   196→| `deniedMcpServers`                | When set in managed-settings.json, denylist of MCP servers that are explicitly blocked. Applies to all scopes including managed servers. Denylist takes precedence over allowlist. See [Managed MCP configuration](/en/mcp#managed-mcp-configuration)                                                                                                 | `[{ "serverName": "filesystem" }]`                                      |
   197→| `strictKnownMarketplaces`         | When set in managed-settings.json, allowlist of plugin marketplaces users can add. Undefined = no restrictions, empty array = lockdown. Applies to marketplace additions only. See [Managed marketplace restrictions](/en/plugin-marketplaces#managed-marketplace-restrictions)                                                                       | `[{ "source": "github", "repo": "acme-corp/plugins" }]`                 |
   198→| `blockedMarketplaces`             | (Managed settings only) Blocklist of marketplace sources. Blocked sources are checked before downloading, so they never touch the filesystem. See [Managed marketplace restrictions](/en/plugin-marketplaces#managed-marketplace-restrictions)                                                                                                        | `[{ "source": "github", "repo": "untrusted/plugins" }]`                 |
   199→| `pluginTrustMessage`              | (Managed settings only) Custom message appended to the plugin trust warning shown before installation. Use this to add organization-specific context, for example to confirm that plugins from your internal marketplace are vetted.                                                                                                                  | `"All plugins from our marketplace are approved by IT"`                 |
   200→| `awsAuthRefresh`                  | Custom script that modifies the `.aws` directory (see [advanced credential configuration](/en/amazon-bedrock#advanced-credential-configuration))                                                                                                                                                                                                      | `aws sso login --profile myprofile`                                     |
   201→| `awsCredentialExport`             | Custom script that outputs JSON with AWS credentials (see [advanced credential configuration](/en/amazon-bedrock#advanced-credential-configuration))                                                                                                                                                                                                  | `/bin/generate_aws_grant.sh`                                            |
   202→| `alwaysThinkingEnabled`           | Enable [extended thinking](/en/common-workflows#use-extended-thinking-thinking-mode) by default for all sessions. Typically configured via the `/config` command rather than editing directly                                                                                                                                                         | `true`                                                                  |
   203→| `plansDirectory`                  | Customize where plan files are stored. Path is relative to project root. Default: `~/.claude/plans`                                                                                                                                                                                                                                                   | `"./plans"`                                                             |
   204→| `showClearContextOnPlanAccept`    | Show the "clear context" option on the plan accept screen. Defaults to `false`. Set to `true` to restore the option                                                                                                                                                                                                                                   | `true`                                                                  |
   205→| `spinnerVerbs`                    | Customize the action verbs shown in the spinner and turn duration messages. Set `mode` to `"replace"` to use only your verbs, or `"append"` to add them to the defaults                                                                                                                                                                               | `{"mode": "append", "verbs": ["Pondering", "Crafting"]}`                |
   206→| `language`                        | Configure Claude's preferred response language (e.g., `"japanese"`, `"spanish"`, `"french"`). Claude will respond in this language by default. Also sets the [voice dictation](/en/voice-dictation#change-the-dictation-language) language                                                                                                            | `"japanese"`                                                            |
   207→| `voiceEnabled`                    | Enable push-to-talk [voice dictation](/en/voice-dictation). Written automatically when you run `/voice`. Requires a Claude.ai account                                                                                                                                                                                                                 | `true`                                                                  |
   208→| `autoUpdatesChannel`              | Release channel to follow for updates. Use `"stable"` for a version that is typically about one week old and skips versions with major regressions, or `"latest"` (default) for the most recent release                                                                                                                                               | `"stable"`                                                              |
   209→| `spinnerTipsEnabled`              | Show tips in the spinner while Claude is working. Set to `false` to disable tips (default: `true`)                                                                                                                                                                                                                                                    | `false`                                                                 |
   210→| `spinnerTipsOverride`             | Override spinner tips with custom strings. `tips`: array of tip strings. `excludeDefault`: if `true`, only show custom tips; if `false` or absent, custom tips are merged with built-in tips                                                                                                                                                          | `{ "excludeDefault": true, "tips": ["Use our internal tool X"] }`       |
   211→| `prefersReducedMotion`            | Reduce or disable UI animations (spinners, shimmer, flash effects) for accessibility                                                                                                                                                                                                                                                                  | `true`                                                                  |
   212→| `fastModePerSessionOptIn`         | When `true`, fast mode does not persist across sessions. Each session starts with fast mode off, requiring users to enable it with `/fast`. The user's fast mode preference is still saved. See [Require per-session opt-in](/en/fast-mode#require-per-session-opt-in)                                                                                | `true`                                                                  |
   213→| `teammateMode`                    | How [agent team](/en/agent-teams) teammates display: `auto` (picks split panes in tmux or iTerm2, in-process otherwise), `in-process`, or `tmux`. See [set up agent teams](/en/agent-teams#set-up-agent-teams)                                                                                                                                        | `"in-process"`                                                          |
   214→| `feedbackSurveyRate`              | Probability (0–1) that the [session quality survey](/en/data-usage#session-quality-surveys) appears when eligible. Set to `0` to suppress entirely. Useful when using Bedrock, Vertex, or Foundry where the default sample rate does not apply                                                                                                        | `0.05`                                                                  |
   215→
   216→### Global config settings
   217→
   218→These settings are stored in `~/.claude.json` rather than `settings.json`. Adding them to `settings.json` will trigger a schema validation error.
   219→
   220→| Key                          | Description                                                                                                                                                                                                                                                                                                          | Example |
   221→| :--------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------ |
   222→| `autoConnectIde`             | Automatically connect to a running IDE when Claude Code starts from an external terminal. Default: `false`. Appears in `/config` as **Auto-connect to IDE (external terminal)** when running outside a VS Code or JetBrains terminal                                                                                 | `true`  |
   223→| `autoInstallIdeExtension`    | Automatically install the Claude Code IDE extension when running from a VS Code terminal. Default: `true`. Appears in `/config` as **Auto-install IDE extension** when running inside a VS Code or JetBrains terminal. You can also set the [`CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL`](/en/env-vars) environment variable | `false` |
   224→| `editorMode`                 | Key binding mode for the input prompt: `"normal"` or `"vim"`. Default: `"normal"`. Written automatically when you run `/vim`. Appears in `/config` as **Key binding mode**                                                                                                                                           | `"vim"` |
   225→| `showTurnDuration`           | Show turn duration messages after responses, e.g. "Cooked for 1m 6s". Default: `true`. Appears in `/config` as **Show turn duration**                                                                                                                                                                                | `false` |
   226→| `terminalProgressBarEnabled` | Show the terminal progress bar in supported terminals: ConEmu, Ghostty 1.2.0+, and iTerm2 3.6.6+. Default: `true`. Appears in `/config` as **Terminal progress bar**                                                                                                                                                 | `false` |
   227→
   228→### Worktree settings
   229→
   230→Configure how `--worktree` creates and manages git worktrees. Use these settings to reduce disk usage and startup time in large monorepos.
   231→
   232→| Key                           | Description                                                                                                                                                  | Example                               |
   233→| :---------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------ |
   234→| `worktree.symlinkDirectories` | Directories to symlink from the main repository into each worktree to avoid duplicating large directories on disk. No directories are symlinked by default   | `["node_modules", ".cache"]`          |
   235→| `worktree.sparsePaths`        | Directories to check out in each worktree via git sparse-checkout (cone mode). Only the listed paths are written to disk, which is faster in large monorepos | `["packages/my-app", "shared/utils"]` |
   236→
   237→To copy gitignored files like `.env` into new worktrees, use a [`.worktreeinclude` file](/en/common-workflows#copy-gitignored-files-to-worktrees) in your project root instead of a setting.
   238→
   239→### Permission settings
   240→
   241→| Keys                           | Description                                                                                                                                                                                                                                      | Example                                                                |
   242→| :----------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------- |
   243→| `allow`                        | Array of permission rules to allow tool use. See [Permission rule syntax](#permission-rule-syntax) below for pattern matching details                                                                                                            | `[ "Bash(git diff *)" ]`                                               |
   244→| `ask`                          | Array of permission rules to ask for confirmation upon tool use. See [Permission rule syntax](#permission-rule-syntax) below                                                                                                                     | `[ "Bash(git push *)" ]`                                               |
   245→| `deny`                         | Array of permission rules to deny tool use. Use this to exclude sensitive files from Claude Code access. See [Permission rule syntax](#permission-rule-syntax) and [Bash permission limitations](/en/permissions#tool-specific-permission-rules) | `[ "WebFetch", "Bash(curl *)", "Read(./.env)", "Read(./secrets/**)" ]` |
   246→| `additionalDirectories`        | Additional [working directories](/en/permissions#working-directories) that Claude has access to                                                                                                                                                  | `[ "../docs/" ]`                                                       |
   247→| `defaultMode`                  | Default [permission mode](/en/permission-modes) when opening Claude Code                                                                                                                                                                         | `"acceptEdits"`                                                        |
   248→| `disableBypassPermissionsMode` | Set to `"disable"` to prevent `bypassPermissions` mode from being activated. Disables the `--dangerously-skip-permissions` flag. Most useful in [managed settings](/en/permissions#managed-settings) where users cannot override it              | `"disable"`                                                            |
   249→
   250→### Permission rule syntax
   251→
   252→Permission rules follow the format `Tool` or `Tool(specifier)`. Rules are evaluated in order: deny rules first, then ask, then allow. The first matching rule wins.
   253→
   254→Quick examples:
   255→
   256→| Rule                           | Effect                                   |
   257→| :----------------------------- | :--------------------------------------- |
   258→| `Bash`                         | Matches all Bash commands                |
   259→| `Bash(npm run *)`              | Matches commands starting with `npm run` |
   260→| `Read(./.env)`                 | Matches reading the `.env` file          |
   261→| `WebFetch(domain:example.com)` | Matches fetch requests to example.com    |
   262→
   263→For the complete rule syntax reference, including wildcard behavior, tool-specific patterns for Read, Edit, WebFetch, MCP, and Agent rules, and security limitations of Bash patterns, see [Permission rule syntax](/en/permissions#permission-rule-syntax).
   264→
   265→### Sandbox settings
   266→
   267→Configure advanced sandboxing behavior. Sandboxing isolates bash commands from your filesystem and network. See [Sandboxing](/en/sandboxing) for details.
   268→
   269→| Keys                                   | Description                                                                                                                                                                                                                                                                                                                                     | Example                         |
   270→| :------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------ |
   271→| `enabled`                              | Enable bash sandboxing (macOS, Linux, and WSL2). Default: false                                                                                                                                                                                                                                                                                 | `true`                          |
   272→| `failIfUnavailable`                    | Exit with an error at startup if `sandbox.enabled` is true but the sandbox cannot start (missing dependencies, unsupported platform, or platform restrictions). When false (default), a warning is shown and commands run unsandboxed. Intended for managed settings deployments that require sandboxing as a hard gate                         | `true`                          |
   273→| `autoAllowBashIfSandboxed`             | Auto-approve bash commands when sandboxed. Default: true                                                                                                                                                                                                                                                                                        | `true`                          |
   274→| `excludedCommands`                     | Commands that should run outside of the sandbox                                                                                                                                                                                                                                                                                                 | `["git", "docker"]`             |
   275→| `allowUnsandboxedCommands`             | Allow commands to run outside the sandbox via the `dangerouslyDisableSandbox` parameter. When set to `false`, the `dangerouslyDisableSandbox` escape hatch is completely disabled and all commands must run sandboxed (or be in `excludedCommands`). Useful for enterprise policies that require strict sandboxing. Default: true               | `false`                         |
   276→| `filesystem.allowWrite`                | Additional paths where sandboxed commands can write. Arrays are merged across all settings scopes: user, project, and managed paths are combined, not replaced. Also merged with paths from `Edit(...)` allow permission rules. See [path prefixes](#sandbox-path-prefixes) below.                                                              | `["/tmp/build", "~/.kube"]`     |
   277→| `filesystem.denyWrite`                 | Paths where sandboxed commands cannot write. Arrays are merged across all settings scopes. Also merged with paths from `Edit(...)` deny permission rules.                                                                                                                                                                                       | `["/etc", "/usr/local/bin"]`    |
   278→| `filesystem.denyRead`                  | Paths where sandboxed commands cannot read. Arrays are merged across all settings scopes. Also merged with paths from `Read(...)` deny permission rules.                                                                                                                                                                                        | `["~/.aws/credentials"]`        |
   279→| `filesystem.allowRead`                 | Paths to re-allow reading within `denyRead` regions. Takes precedence over `denyRead`. Arrays are merged across all settings scopes. Use this to create workspace-only read access patterns.                                                                                                                                                    | `["."]`                         |
   280→| `filesystem.allowManagedReadPathsOnly` | (Managed settings only) Only `allowRead` paths from managed settings are respected. `allowRead` entries from user, project, and local settings are ignored. Default: false                                                                                                                                                                      | `true`                          |
   281→| `network.allowUnixSockets`             | Unix socket paths accessible in sandbox (for SSH agents, etc.)                                                                                                                                                                                                                                                                                  | `["~/.ssh/agent-socket"]`       |
   282→| `network.allowAllUnixSockets`          | Allow all Unix socket connections in sandbox. Default: false                                                                                                                                                                                                                                                                                    | `true`                          |
   283→| `network.allowLocalBinding`            | Allow binding to localhost ports (macOS only). Default: false                                                                                                                                                                                                                                                                                   | `true`                          |
   284→| `network.allowedDomains`               | Array of domains to allow for outbound network traffic. Supports wildcards (e.g., `*.example.com`).                                                                                                                                                                                                                                             | `["github.com", "*.npmjs.org"]` |
   285→| `network.allowManagedDomainsOnly`      | (Managed settings only) Only `allowedDomains` and `WebFetch(domain:...)` allow rules from managed settings are respected. Domains from user, project, and local settings are ignored. Non-allowed domains are blocked automatically without prompting the user. Denied domains are still respected from all sources. Default: false             | `true`                          |
   286→| `network.httpProxyPort`                | HTTP proxy port used if you wish to bring your own proxy. If not specified, Claude will run its own proxy.                                                                                                                                                                                                                                      | `8080`                          |
   287→| `network.socksProxyPort`               | SOCKS5 proxy port used if you wish to bring your own proxy. If not specified, Claude will run its own proxy.                                                                                                                                                                                                                                    | `8081`                          |
   288→| `enableWeakerNestedSandbox`            | Enable weaker sandbox for unprivileged Docker environments (Linux and WSL2 only). **Reduces security.** Default: false                                                                                                                                                                                                                          | `true`                          |
   289→| `enableWeakerNetworkIsolation`         | (macOS only) Allow access to the system TLS trust service (`com.apple.trustd.agent`) in the sandbox. Required for Go-based tools like `gh`, `gcloud`, and `terraform` to verify TLS certificates when using `httpProxyPort` with a MITM proxy and custom CA. **Reduces security** by opening a potential data exfiltration path. Default: false | `true`                          |
   290→
   291→#### Sandbox path prefixes
   292→
   293→Paths in `filesystem.allowWrite`, `filesystem.denyWrite`, `filesystem.denyRead`, and `filesystem.allowRead` support these prefixes:
   294→
   295→| Prefix            | Meaning                                                                                | Example                                                                   |
   296→| :---------------- | :------------------------------------------------------------------------------------- | :------------------------------------------------------------------------ |
   297→| `/`               | Absolute path from filesystem root                                                     | `/tmp/build` stays `/tmp/build`                                           |
   298→| `~/`              | Relative to home directory                                                             | `~/.kube` becomes `$HOME/.kube`                                           |
   299→| `./` or no prefix | Relative to the project root for project settings, or to `~/.claude` for user settings | `./output` in `.claude/settings.json` resolves to `<project-root>/output` |
   300→
   301→The older `//path` prefix for absolute paths still works. If you previously used single-slash `/path` expecting project-relative resolution, switch to `./path`. This syntax differs from [Read and Edit permission rules](/en/permissions#read-and-edit), which use `//path` for absolute and `/path` for project-relative. Sandbox filesystem paths use standard conventions: `/tmp/build` is an absolute path.
   302→
   303→**Configuration example:**
   304→
   305→```json  theme={null}
   306→{
   307→  "sandbox": {
   308→    "enabled": true,
   309→    "autoAllowBashIfSandboxed": true,
   310→    "excludedCommands": ["docker"],
   311→    "filesystem": {
   312→      "allowWrite": ["/tmp/build", "~/.kube"],
   313→      "denyRead": ["~/.aws/credentials"]
   314→    },
   315→    "network": {
   316→      "allowedDomains": ["github.com", "*.npmjs.org", "registry.yarnpkg.com"],
   317→      "allowUnixSockets": [
   318→        "/var/run/docker.sock"
   319→      ],
   320→      "allowLocalBinding": true
   321→    }
   322→  }
   323→}
   324→```
   325→
   326→**Filesystem and network restrictions** can be configured in two ways that are merged together:
   327→
   328→* **`sandbox.filesystem` settings** (shown above): Control paths at the OS-level sandbox boundary. These restrictions apply to all subprocess commands (e.g., `kubectl`, `terraform`, `npm`), not just Claude's file tools.
   329→* **Permission rules**: Use `Edit` allow/deny rules to control Claude's file tool access, `Read` deny rules to block reads, and `WebFetch` allow/deny rules to control network domains. Paths from these rules are also merged into the sandbox configuration.
   330→
   331→### Attribution settings
   332→
   333→Claude Code adds attribution to git commits and pull requests. These are configured separately:
   334→
   335→* Commits use [git trailers](https://git-scm.com/docs/git-interpret-trailers) (like `Co-Authored-By`) by default,  which can be customized or disabled
   336→* Pull request descriptions are plain text
   337→
   338→| Keys     | Description                                                                                |
   339→| :------- | :----------------------------------------------------------------------------------------- |
   340→| `commit` | Attribution for git commits, including any trailers. Empty string hides commit attribution |
   341→| `pr`     | Attribution for pull request descriptions. Empty string hides pull request attribution     |
   342→
   343→**Default commit attribution:**
   344→
   345→```text  theme={null}
   346→🤖 Generated with [Claude Code](https://claude.com/claude-code)
   347→
   348→   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   349→```
   350→
   351→**Default pull request attribution:**
   352→
   353→```text  theme={null}
   354→🤖 Generated with [Claude Code](https://claude.com/claude-code)
   355→```
   356→
   357→**Example:**
   358→
   359→```json  theme={null}
   360→{
   361→  "attribution": {
   362→    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>",
   363→    "pr": ""
   364→  }
   365→}
   366→```
   367→
   368→<Note>
   369→  The `attribution` setting takes precedence over the deprecated `includeCoAuthoredBy` setting. To hide all attribution, set `commit` and `pr` to empty strings.
   370→</Note>
   371→
   372→### File suggestion settings
   373→
   374→Configure a custom command for `@` file path autocomplete. The built-in file suggestion uses fast filesystem traversal, but large monorepos may benefit from project-specific indexing such as a pre-built file index or custom tooling.
   375→
   376→```json  theme={null}
   377→{
   378→  "fileSuggestion": {
   379→    "type": "command",
   380→    "command": "~/.claude/file-suggestion.sh"
   381→  }
   382→}
   383→```
   384→
   385→The command runs with the same environment variables as [hooks](/en/hooks), including `CLAUDE_PROJECT_DIR`. It receives JSON via stdin with a `query` field:
   386→
   387→```json  theme={null}
   388→{"query": "src/comp"}
   389→```
   390→
   391→Output newline-separated file paths to stdout (currently limited to 15):
   392→
   393→```text  theme={null}
   394→src/components/Button.tsx
   395→src/components/Modal.tsx
   396→src/components/Form.tsx
   397→```
   398→
   399→**Example:**
   400→
   401→```bash  theme={null}
   402→#!/bin/bash
   403→query=$(cat | jq -r '.query')
   404→your-repo-file-index --query "$query" | head -20
   405→```
   406→
   407→### Hook configuration
   408→
   409→These settings control which hooks are allowed to run and what HTTP hooks can access. The `allowManagedHooksOnly` setting can only be configured in [managed settings](#settings-files). The URL and env var allowlists can be set at any settings level and merge across sources.
   410→
   411→**Behavior when `allowManagedHooksOnly` is `true`:**
   412→
   413→* Managed hooks and SDK hooks are loaded
   414→* User hooks, project hooks, and plugin hooks are blocked
   415→
   416→**Restrict HTTP hook URLs:**
   417→
   418→Limit which URLs HTTP hooks can target. Supports `*` as a wildcard for matching. When the array is defined, HTTP hooks targeting non-matching URLs are silently blocked.
   419→
   420→```json  theme={null}
   421→{
   422→  "allowedHttpHookUrls": ["https://hooks.example.com/*", "http://localhost:*"]
   423→}
   424→```
   425→
   426→**Restrict HTTP hook environment variables:**
   427→
   428→Limit which environment variable names HTTP hooks can interpolate into header values. Each hook's effective `allowedEnvVars` is the intersection of its own list and this setting.
   429→
   430→```json  theme={null}
   431→{
   432→  "httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
   433→}
   434→```
   435→
   436→### Settings precedence
   437→
   438→Settings apply in order of precedence. From highest to lowest:
   439→
   440→1. **Managed settings** ([server-managed](/en/server-managed-settings), [MDM/OS-level policies](#configuration-scopes), or [managed settings](/en/settings#settings-files))
   441→   * Policies deployed by IT through server delivery, MDM configuration profiles, registry policies, or managed settings files
   442→   * Cannot be overridden by any other level, including command line arguments
   443→   * Within the managed tier, precedence is: server-managed > MDM/OS-level policies > file-based (`managed-settings.d/*.json` + `managed-settings.json`) > HKCU registry (Windows only). Only one managed source is used; sources do not merge across tiers. Within the file-based tier, drop-in files and the base file are merged together.
   444→
   445→2. **Command line arguments**
   446→   * Temporary overrides for a specific session
   447→
   448→3. **Local project settings** (`.claude/settings.local.json`)
   449→   * Personal project-specific settings
   450→
   451→4. **Shared project settings** (`.claude/settings.json`)
   452→   * Team-shared project settings in source control
   453→
   454→5. **User settings** (`~/.claude/settings.json`)
   455→   * Personal global settings
   456→
   457→This hierarchy ensures that organizational policies are always enforced while still allowing teams and individuals to customize their experience. The same precedence applies whether you run Claude Code from the CLI, the [VS Code extension](/en/vs-code), or a [JetBrains IDE](/en/jetbrains).
   458→
   459→For example, if your user settings allow `Bash(npm run *)` but a project's shared settings deny it, the project setting takes precedence and the command is blocked.
   460→
   461→<Note>
   462→  **Array settings merge across scopes.** When the same array-valued setting (such as `sandbox.filesystem.allowWrite` or `permissions.allow`) appears in multiple scopes, the arrays are **concatenated and deduplicated**, not replaced. This means lower-priority scopes can add entries without overriding those set by higher-priority scopes, and vice versa. For example, if managed settings set `allowWrite` to `["/opt/company-tools"]` and a user adds `["~/.kube"]`, both paths are included in the final configuration.
   463→</Note>
   464→
   465→### Verify active settings
   466→
   467→Run `/status` inside Claude Code to see which settings sources are active and where they come from. The output shows each configuration layer (managed, user, project) along with its origin, such as `Enterprise managed settings (remote)`, `Enterprise managed settings (plist)`, `Enterprise managed settings (HKLM)`, or `Enterprise managed settings (file)`. If a settings file contains errors, `/status` reports the issue so you can fix it.
   468→
   469→### Key points about the configuration system
   470→
   471→* **Memory files (`CLAUDE.md`)**: Contain instructions and context that Claude loads at startup
   472→* **Settings files (JSON)**: Configure permissions, environment variables, and tool behavior
   473→* **Skills**: Custom prompts that can be invoked with `/skill-name` or loaded by Claude automatically
   474→* **MCP servers**: Extend Claude Code with additional tools and integrations
   475→* **Precedence**: Higher-level configurations (Managed) override lower-level ones (User/Project)
   476→* **Inheritance**: Settings are merged, with more specific settings adding to or overriding broader ones
   477→
   478→### System prompt
   479→
   480→Claude Code's internal system prompt is not published. To add custom instructions, use `CLAUDE.md` files or the `--append-system-prompt` flag.
   481→
   482→### Excluding sensitive files
   483→
   484→To prevent Claude Code from accessing files containing sensitive information like API keys, secrets, and environment files, use the `permissions.deny` setting in your `.claude/settings.json` file:
   485→
   486→```json  theme={null}
   487→{
   488→  "permissions": {
   489→    "deny": [
   490→      "Read(./.env)",
   491→      "Read(./.env.*)",
   492→      "Read(./secrets/**)",
   493→      "Read(./config/credentials.json)",
   494→      "Read(./build)"
   495→    ]
   496→  }
   497→}
   498→```
   499→
   500→This replaces the deprecated `ignorePatterns` configuration. Files matching these patterns are excluded from file discovery and search results, and read operations on these files are denied.
   501→
   502→## Subagent configuration
   503→
   504→Claude Code supports custom AI subagents that can be configured at both user and project levels. These subagents are stored as Markdown files with YAML frontmatter:
   505→
   506→* **User subagents**: `~/.claude/agents/` - Available across all your projects
   507→* **Project subagents**: `.claude/agents/` - Specific to your project and can be shared with your team
   508→
   509→Subagent files define specialized AI assistants with custom prompts and tool permissions. Learn more about creating and using subagents in the [subagents documentation](/en/sub-agents).
   510→
   511→## Plugin configuration
   512→
   513→Claude Code supports a plugin system that lets you extend functionality with skills, agents, hooks, and MCP servers. Plugins are distributed through marketplaces and can be configured at both user and repository levels.
   514→
   515→### Plugin settings
   516→
   517→Plugin-related settings in `settings.json`:
   518→
   519→```json  theme={null}
   520→{
   521→  "enabledPlugins": {
   522→    "formatter@acme-tools": true,
   523→    "deployer@acme-tools": true,
   524→    "analyzer@security-plugins": false
   525→  },
   526→  "extraKnownMarketplaces": {
   527→    "acme-tools": {
   528→      "source": "github",
   529→      "repo": "acme-corp/claude-plugins"
   530→    }
   531→  }
   532→}
   533→```
   534→
   535→#### `enabledPlugins`
   536→
   537→Controls which plugins are enabled. Format: `"plugin-name@marketplace-name": true/false`
   538→
   539→**Scopes**:
   540→
   541→* **User settings** (`~/.claude/settings.json`): Personal plugin preferences
   542→* **Project settings** (`.claude/settings.json`): Project-specific plugins shared with team
   543→* **Local settings** (`.claude/settings.local.json`): Per-machine overrides (not committed)
   544→* **Managed settings** (`managed-settings.json`): Organization-wide policy overrides that block installation at all scopes and hide the plugin from the marketplace
   545→
   546→**Example**:
   547→
   548→```json  theme={null}
   549→{
   550→  "enabledPlugins": {
   551→    "code-formatter@team-tools": true,
   552→    "deployment-tools@team-tools": true,
   553→    "experimental-features@personal": false
   554→  }
   555→}
   556→```
   557→
   558→#### `extraKnownMarketplaces`
   559→
   560→Defines additional marketplaces that should be made available for the repository. Typically used in repository-level settings to ensure team members have access to required plugin sources.
   561→
   562→**When a repository includes `extraKnownMarketplaces`**:
   563→
   564→1. Team members are prompted to install the marketplace when they trust the folder
   565→2. Team members are then prompted to install plugins from that marketplace
   566→3. Users can skip unwanted marketplaces or plugins (stored in user settings)
   567→4. Installation respects trust boundaries and requires explicit consent
   568→
   569→**Example**:
   570→
   571→```json  theme={null}
   572→{
   573→  "extraKnownMarketplaces": {
   574→    "acme-tools": {
   575→      "source": {
   576→        "source": "github",
   577→        "repo": "acme-corp/claude-plugins"
   578→      }
   579→    },
   580→    "security-plugins": {
   581→      "source": {
   582→        "source": "git",
   583→        "url": "https://git.example.com/security/plugins.git"
   584→      }
   585→    }
   586→  }
   587→}
   588→```
   589→
   590→**Marketplace source types**:
   591→
   592→* `github`: GitHub repository (uses `repo`)
   593→* `git`: Any git URL (uses `url`)
   594→* `directory`: Local filesystem path (uses `path`, for development only)
   595→* `hostPattern`: regex pattern to match marketplace hosts (uses `hostPattern`)
   596→* `settings`: inline marketplace declared directly in settings.json without a separate hosted repository (uses `name` and `plugins`)
   597→
   598→Use `source: 'settings'` to declare a small set of plugins inline without setting up a hosted marketplace repository. Plugins listed here must reference external sources such as GitHub or npm. You still need to enable each plugin separately in `enabledPlugins`.
   599→
   600→```json  theme={null}
   601→{
   602→  "extraKnownMarketplaces": {
   603→    "team-tools": {
   604→      "source": {
   605→        "source": "settings",
   606→        "name": "team-tools",
   607→        "plugins": [
   608→          {
   609→            "name": "code-formatter",
   610→            "source": {
   611→              "source": "github",
   612→              "repo": "acme-corp/code-formatter"
   613→            }
   614→          }
   615→        ]
   616→      }
   617→    }
   618→  }
   619→}
   620→```
   621→
   622→#### `strictKnownMarketplaces`
   623→
   624→**Managed settings only**: Controls which plugin marketplaces users are allowed to add. This setting can only be configured in [managed settings](/en/settings#settings-files) and provides administrators with strict control over marketplace sources.
   625→
   626→**Managed settings file locations**:
   627→
   628→* **macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
   629→* **Linux and WSL**: `/etc/claude-code/managed-settings.json`
   630→* **Windows**: `C:\Program Files\ClaudeCode\managed-settings.json`
   631→
   632→**Key characteristics**:
   633→
   634→* Only available in managed settings (`managed-settings.json`)
   635→* Cannot be overridden by user or project settings (highest precedence)
   636→* Enforced BEFORE network/filesystem operations (blocked sources never execute)
   637→* Uses exact matching for source specifications (including `ref`, `path` for git sources), except `hostPattern`, which uses regex matching
   638→
   639→**Allowlist behavior**:
   640→
   641→* `undefined` (default): No restrictions - users can add any marketplace
   642→* Empty array `[]`: Complete lockdown - users cannot add any new marketplaces
   643→* List of sources: Users can only add marketplaces that match exactly
   644→
   645→**All supported source types**:
   646→
   647→The allowlist supports multiple marketplace source types. Most sources use exact matching, while `hostPattern` uses regex matching against the marketplace host.
   648→
   649→1. **GitHub repositories**:
   650→
   651→```json  theme={null}
   652→{ "source": "github", "repo": "acme-corp/approved-plugins" }
   653→{ "source": "github", "repo": "acme-corp/security-tools", "ref": "v2.0" }
   654→{ "source": "github", "repo": "acme-corp/plugins", "ref": "main", "path": "marketplace" }
   655→```
   656→
   657→Fields: `repo` (required), `ref` (optional: branch/tag/SHA), `path` (optional: subdirectory)
   658→
   659→2. **Git repositories**:
   660→
   661→```json  theme={null}
   662→{ "source": "git", "url": "https://gitlab.example.com/tools/plugins.git" }
   663→{ "source": "git", "url": "https://bitbucket.org/acme-corp/plugins.git", "ref": "production" }
   664→{ "source": "git", "url": "ssh://git@git.example.com/plugins.git", "ref": "v3.1", "path": "approved" }
   665→```
   666→
   667→Fields: `url` (required), `ref` (optional: branch/tag/SHA), `path` (optional: subdirectory)
   668→
   669→3. **URL-based marketplaces**:
   670→
   671→```json  theme={null}
   672→{ "source": "url", "url": "https://plugins.example.com/marketplace.json" }
   673→{ "source": "url", "url": "https://cdn.example.com/marketplace.json", "headers": { "Authorization": "Bearer ${TOKEN}" } }
   674→```
   675→
   676→Fields: `url` (required), `headers` (optional: HTTP headers for authenticated access)
   677→
   678→<Note>
   679→  URL-based marketplaces only download the `marketplace.json` file. They do not download plugin files from the server. Plugins in URL-based marketplaces must use external sources (GitHub, npm, or git URLs) rather than relative paths. For plugins with relative paths, use a Git-based marketplace instead. See [Troubleshooting](/en/plugin-marketplaces#plugins-with-relative-paths-fail-in-url-based-marketplaces) for details.
   680→</Note>
   681→
   682→4. **NPM packages**:
   683→
   684→```json  theme={null}
   685→{ "source": "npm", "package": "@acme-corp/claude-plugins" }
   686→{ "source": "npm", "package": "@acme-corp/approved-marketplace" }
   687→```
   688→
   689→Fields: `package` (required, supports scoped packages)
   690→
   691→5. **File paths**:
   692→
   693→```json  theme={null}
   694→{ "source": "file", "path": "/usr/local/share/claude/acme-marketplace.json" }
   695→{ "source": "file", "path": "/opt/acme-corp/plugins/marketplace.json" }
   696→```
   697→
   698→Fields: `path` (required: absolute path to marketplace.json file)
   699→
   700→6. **Directory paths**:
   701→
   702→```json  theme={null}
   703→{ "source": "directory", "path": "/usr/local/share/claude/acme-plugins" }
   704→{ "source": "directory", "path": "/opt/acme-corp/approved-marketplaces" }
   705→```
   706→
   707→Fields: `path` (required: absolute path to directory containing `.claude-plugin/marketplace.json`)
   708→
   709→7. **Host pattern matching**:
   710→
   711→```json  theme={null}
   712→{ "source": "hostPattern", "hostPattern": "^github\\.example\\.com$" }
   713→{ "source": "hostPattern", "hostPattern": "^gitlab\\.internal\\.example\\.com$" }
   714→```
   715→
   716→Fields: `hostPattern` (required: regex pattern to match against the marketplace host)
   717→
   718→Use host pattern matching when you want to allow all marketplaces from a specific host without enumerating each repository individually. This is useful for organizations with internal GitHub Enterprise or GitLab servers where developers create their own marketplaces.
   719→
   720→Host extraction by source type:
   721→
   722→* `github`: always matches against `github.com`
   723→* `git`: extracts hostname from the URL (supports both HTTPS and SSH formats)
   724→* `url`: extracts hostname from the URL
   725→* `npm`, `file`, `directory`: not supported for host pattern matching
   726→
   727→**Configuration examples**:
   728→
   729→Example: allow specific marketplaces only:
   730→
   731→```json  theme={null}
   732→{
   733→  "strictKnownMarketplaces": [
   734→    {
   735→      "source": "github",
   736→      "repo": "acme-corp/approved-plugins"
   737→    },
   738→    {
   739→      "source": "github",
   740→      "repo": "acme-corp/security-tools",
   741→      "ref": "v2.0"
   742→    },
   743→    {
   744→      "source": "url",
   745→      "url": "https://plugins.example.com/marketplace.json"
   746→    },
   747→    {
   748→      "source": "npm",
   749→      "package": "@acme-corp/compliance-plugins"
   750→    }
   751→  ]
   752→}
   753→```
   754→
   755→Example - Disable all marketplace additions:
   756→
   757→```json  theme={null}
   758→{
   759→  "strictKnownMarketplaces": []
   760→}
   761→```
   762→
   763→Example: allow all marketplaces from an internal git server:
   764→
   765→```json  theme={null}
   766→{
   767→  "strictKnownMarketplaces": [
   768→    {
   769→      "source": "hostPattern",
   770→      "hostPattern": "^github\\.example\\.com$"
   771→    }
   772→  ]
   773→}
   774→```
   775→
   776→**Exact matching requirements**:
   777→
   778→Marketplace sources must match **exactly** for a user's addition to be allowed. For git-based sources (`github` and `git`), this includes all optional fields:
   779→
   780→* The `repo` or `url` must match exactly
   781→* The `ref` field must match exactly (or both be undefined)
   782→* The `path` field must match exactly (or both be undefined)
   783→
   784→Examples of sources that **do NOT match**:
   785→
   786→```json  theme={null}
   787→// These are DIFFERENT sources:
   788→{ "source": "github", "repo": "acme-corp/plugins" }
   789→{ "source": "github", "repo": "acme-corp/plugins", "ref": "main" }
   790→
   791→// These are also DIFFERENT:
   792→{ "source": "github", "repo": "acme-corp/plugins", "path": "marketplace" }
   793→{ "source": "github", "repo": "acme-corp/plugins" }
   794→```
   795→
   796→**Comparison with `extraKnownMarketplaces`**:
   797→
   798→| Aspect                | `strictKnownMarketplaces`            | `extraKnownMarketplaces`             |
   799→| --------------------- | ------------------------------------ | ------------------------------------ |
   800→| **Purpose**           | Organizational policy enforcement    | Team convenience                     |
   801→| **Settings file**     | `managed-settings.json` only         | Any settings file                    |
   802→| **Behavior**          | Blocks non-allowlisted additions     | Auto-installs missing marketplaces   |
   803→| **When enforced**     | Before network/filesystem operations | After user trust prompt              |
   804→| **Can be overridden** | No (highest precedence)              | Yes (by higher precedence settings)  |
   805→| **Source format**     | Direct source object                 | Named marketplace with nested source |
   806→| **Use case**          | Compliance, security restrictions    | Onboarding, standardization          |
   807→
   808→**Format difference**:
   809→
   810→`strictKnownMarketplaces` uses direct source objects:
   811→
   812→```json  theme={null}
   813→{
   814→  "strictKnownMarketplaces": [
   815→    { "source": "github", "repo": "acme-corp/plugins" }
   816→  ]
   817→}
   818→```
   819→
   820→`extraKnownMarketplaces` requires named marketplaces:
   821→
   822→```json  theme={null}
   823→{
   824→  "extraKnownMarketplaces": {
   825→    "acme-tools": {
   826→      "source": { "source": "github", "repo": "acme-corp/plugins" }
   827→    }
   828→  }
   829→}
   830→```
   831→
   832→**Using both together**:
   833→
   834→`strictKnownMarketplaces` is a policy gate: it controls what users may add but does not register any marketplaces. To both restrict and pre-register a marketplace for all users, set both in `managed-settings.json`:
   835→
   836→```json  theme={null}
   837→{
   838→  "strictKnownMarketplaces": [
   839→    { "source": "github", "repo": "acme-corp/plugins" }
   840→  ],
   841→  "extraKnownMarketplaces": {
   842→    "acme-tools": {
   843→      "source": { "source": "github", "repo": "acme-corp/plugins" }
   844→    }
   845→  }
   846→}
   847→```
   848→
   849→With only `strictKnownMarketplaces` set, users can still add the allowed marketplace manually via `/plugin marketplace add`, but it is not available automatically.
   850→
   851→**Important notes**:
   852→
   853→* Restrictions are checked BEFORE any network requests or filesystem operations
   854→* When blocked, users see clear error messages indicating the source is blocked by managed policy
   855→* The restriction applies only to adding NEW marketplaces; previously installed marketplaces remain accessible
   856→* Managed settings have the highest precedence and cannot be overridden
   857→
   858→See [Managed marketplace restrictions](/en/plugin-marketplaces#managed-marketplace-restrictions) for user-facing documentation.
   859→
   860→### Managing plugins
   861→
   862→Use the `/plugin` command to manage plugins interactively:
   863→
   864→* Browse available plugins from marketplaces
   865→* Install/uninstall plugins
   866→* Enable/disable plugins
   867→* View plugin details (commands, agents, hooks provided)
   868→* Add/remove marketplaces
   869→
   870→Learn more about the plugin system in the [plugins documentation](/en/plugins).
   871→
   872→## Environment variables
   873→
   874→Environment variables let you control Claude Code behavior without editing settings files. Any variable can also be configured in [`settings.json`](#available-settings) under the `env` key to apply it to every session or roll it out to your team.
   875→
   876→See the [environment variables reference](/en/env-vars) for the full list.
   877→
   878→## Tools available to Claude
   879→
   880→Claude Code has access to a set of tools for reading, editing, searching, running commands, and orchestrating subagents. Tool names are the exact strings you use in permission rules and hook matchers.
   881→
   882→See the [tools reference](/en/tools-reference) for the full list and Bash tool behavior details.
   883→
   884→## See also
   885→
   886→* [Permissions](/en/permissions): permission system, rule syntax, tool-specific patterns, and managed policies
   887→* [Authentication](/en/authentication): set up user access to Claude Code
   888→* [Troubleshooting](/en/troubleshooting): solutions for common configuration issues
   889→