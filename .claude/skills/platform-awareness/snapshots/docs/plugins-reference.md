<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/plugins-reference.md -->

# Plugins reference

> Complete technical reference for Claude Code plugin system, including schemas, CLI commands, and component specifications.

## Plugin components reference

### Skills

- **Location**: `skills/` or `commands/` directory in plugin root
- **File format**: Skills are directories with `SKILL.md`; commands are simple markdown files
- Plugin agents support: `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, and `isolation` frontmatter. The only valid `isolation` value is `"worktree"`. `hooks`, `mcpServers`, and `permissionMode` NOT supported for security.

### Hook events supported in plugins

| Event | When it fires |
| :---- | :------------ |
| `SessionStart` | When a session begins or resumes |
| `UserPromptSubmit` | When you submit a prompt |
| `PreToolUse` | Before a tool call executes |
| `PermissionRequest` | When a permission dialog appears |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `Notification` | When Claude Code sends a notification |
| `SubagentStart` | When a subagent is spawned |
| `SubagentStop` | When a subagent finishes |
| `TaskCreated` | When a task is being created via `TaskCreate` |
| `TaskCompleted` | When a task is being marked as completed |
| `Stop` | When Claude finishes responding |
| `StopFailure` | When the turn ends due to an API error |
| `TeammateIdle` | When an agent team teammate is about to go idle |
| `InstructionsLoaded` | When a CLAUDE.md or rules file is loaded |
| `ConfigChange` | When a configuration file changes |
| `CwdChanged` | When the working directory changes |
| `FileChanged` | When a watched file changes on disk |
| `WorktreeCreate` | When a worktree is being created |
| `WorktreeRemove` | When a worktree is being removed |
| `PreCompact` | Before context compaction |
| `PostCompact` | After context compaction completes |
| `Elicitation` | When an MCP server requests user input |
| `ElicitationResult` | After a user responds to an MCP elicitation |
| `SessionEnd` | When a session terminates |

### Hook types
- `command`: execute shell commands or scripts
- `http`: send the event JSON as a POST request to a URL
- `prompt`: evaluate a prompt with an LLM
- `agent`: run an agentic verifier with tools

## Plugin manifest schema

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

### Required fields

| Field | Type | Description |
| :---- | :--- | :---------- |
| `name` | string | Unique identifier (kebab-case, no spaces) |

### Metadata fields

| Field | Type | Description |
| :---- | :--- | :---------- |
| `version` | string | Semantic version |
| `description` | string | Brief explanation |
| `author` | object | Author information |
| `homepage` | string | Documentation URL |
| `repository` | string | Source code URL |
| `license` | string | License identifier |
| `keywords` | array | Discovery tags |

### Component path fields

| Field | Type | Description |
| :---- | :--- | :---------- |
| `commands` | string\|array | Custom command files/directories |
| `agents` | string\|array | Custom agent files |
| `skills` | string\|array | Custom skill directories |
| `hooks` | string\|array\|object | Hook config paths or inline config |
| `mcpServers` | string\|array\|object | MCP config paths or inline config |
| `outputStyles` | string\|array | Custom output style files/directories |
| `lspServers` | string\|array\|object | Language Server Protocol configs |
| `userConfig` | object | User-configurable values prompted at enable time |
| `channels` | array | Channel declarations for message injection |

## Environment variables

- **`${CLAUDE_PLUGIN_ROOT}`**: absolute path to plugin's installation directory. Changes when plugin updates.
- **`${CLAUDE_PLUGIN_DATA}`**: persistent directory for plugin state that survives updates. Location: `~/.claude/plugins/data/{id}/`.

## Plugin installation scopes

| Scope | Settings file | Use case |
| :---- | :------------ | :------- |
| `user` | `~/.claude/settings.json` | Personal plugins (default) |
| `project` | `.claude/settings.json` | Team plugins via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | Managed settings | Managed plugins (read-only) |

## CLI commands reference

### plugin install
```bash
claude plugin install <plugin> [options]
# Options: -s, --scope <scope>  (user, project, local)
```

### plugin uninstall
```bash
claude plugin uninstall <plugin> [options]
# Options: -s, --scope, --keep-data
# Aliases: remove, rm
```

### plugin enable
```bash
claude plugin enable <plugin> [options]
```

### plugin disable
```bash
claude plugin disable <plugin> [options]
```

### plugin update
```bash
claude plugin update <plugin> [options]
```

## LSP server configuration

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

| Field | Description |
| :---- | :---------- |
| `command` | The LSP binary to execute (must be in PATH) |
| `extensionToLanguage` | Maps file extensions to language identifiers |
| `args` | Command-line arguments |
| `transport` | `stdio` (default) or `socket` |
| `env` | Environment variables |
| `initializationOptions` | Options during initialization |
| `settings` | Settings via `workspace/didChangeConfiguration` |
| `startupTimeout` | Max time for server startup (ms) |
| `shutdownTimeout` | Max time for graceful shutdown (ms) |
| `restartOnCrash` | Whether to auto-restart on crash |
| `maxRestarts` | Maximum restart attempts |

## Available official LSP plugins

| Plugin | Language server | Install command |
| :----- | :-------------- | :-------------- |
| `pyright-lsp` | Pyright (Python) | `pip install pyright` or `npm install -g pyright` |
| `typescript-lsp` | TypeScript Language Server | `npm install -g typescript-language-server typescript` |
| `rust-lsp` | rust-analyzer | See rust-analyzer docs |

## Version management

Follow semantic versioning: `MAJOR.MINOR.PATCH`

- MAJOR: Breaking changes
- MINOR: New features (backward-compatible)
- PATCH: Bug fixes

## File locations reference

| Component | Default Location | Purpose |
| :-------- | :--------------- | :------ |
| Manifest | `.claude-plugin/plugin.json` | Plugin metadata |
| Commands | `commands/` | Skill Markdown files (legacy) |
| Agents | `agents/` | Subagent Markdown files |
| Skills | `skills/` | Skills with `<name>/SKILL.md` |
| Output styles | `output-styles/` | Output style definitions |
| Hooks | `hooks/hooks.json` | Hook configuration |
| MCP servers | `.mcp.json` | MCP server definitions |
| LSP servers | `.lsp.json` | Language server configurations |
| Settings | `settings.json` | Default configuration |

## Common issues

| Issue | Cause | Solution |
| :---- | :---- | :------- |
| Plugin not loading | Invalid `plugin.json` | Run `claude plugin validate` |
| Commands not appearing | Wrong directory structure | Ensure `commands/` at root, not in `.claude-plugin/` |
| Hooks not firing | Script not executable | Run `chmod +x script.sh` |
| MCP server fails | Missing `${CLAUDE_PLUGIN_ROOT}` | Use variable for all plugin paths |
| LSP `Executable not found` | Language server not installed | Install the binary |
