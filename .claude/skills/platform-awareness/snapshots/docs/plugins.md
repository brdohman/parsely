<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/plugins.md -->

# Create plugins

> Create custom plugins to extend Claude Code with skills, agents, hooks, and MCP servers.

Plugins let you extend Claude Code with custom functionality that can be shared across projects and teams.

## When to use plugins vs standalone configuration

| Approach | Skill names | Best for |
| :------- | :---------- | :------- |
| **Standalone** (`.claude/` directory) | `/hello` | Personal workflows, project-specific customizations |
| **Plugins** | `/plugin-name:hello` | Sharing with teammates, distributing to community, versioned releases |

## Plugin structure

```text
my-plugin/
├── .claude-plugin/
│   └── plugin.json      <- Only manifest here
├── commands/            <- Legacy command files
├── agents/              <- Custom agent definitions
├── skills/              <- Agent Skills with SKILL.md files
├── output-styles/       <- Output style definitions
├── hooks/
│   └── hooks.json       <- Hook configuration
├── settings.json        <- Default settings when plugin is enabled
├── .mcp.json            <- MCP server configurations
└── .lsp.json            <- LSP server configurations
```

## Plugin manifest (plugin.json)

```json
{
  "name": "my-first-plugin",
  "description": "A greeting plugin to learn the basics",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

| Field | Purpose |
| :---- | :------ |
| `name` | Unique identifier and skill namespace. Skills prefixed with this. |
| `description` | Shown in the plugin manager. |
| `version` | Track releases using semantic versioning. |
| `author` | Optional. Helpful for attribution. |

## Test your plugin

```bash
claude --plugin-dir ./my-plugin
```

Run `/reload-plugins` to pick up changes without restarting.

Load multiple plugins:
```bash
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

## Plugin components

- **Skills** (`skills/`): Agent Skills with `SKILL.md` files
- **Agents** (`agents/`): Custom subagent definitions
- **Hooks** (`hooks/hooks.json`): Event handlers
- **MCP servers** (`.mcp.json`): External tool integrations
- **LSP servers** (`.lsp.json`): Language server configurations
- **Settings** (`settings.json`): Default settings when plugin enabled

## Environment variables

- `${CLAUDE_PLUGIN_ROOT}`: absolute path to plugin's installation directory
- `${CLAUDE_PLUGIN_DATA}`: persistent directory for plugin state that survives updates

## User configuration

```json
{
  "userConfig": {
    "api_endpoint": {
      "description": "Your team's API endpoint",
      "sensitive": false
    },
    "api_token": {
      "description": "API authentication token",
      "sensitive": true
    }
  }
}
```

Available as `${user_config.KEY}` in MCP/LSP configs and hook commands.

## Ship default settings

```json
{
  "agent": "security-reviewer"
}
```

## Convert existing configurations to plugins

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Copy `commands/`, `agents/`, `skills/` from `.claude/`
3. Move hooks from `settings.json` to `hooks/hooks.json`
4. Test with `--plugin-dir`

## Plugin security notes

Plugin subagents do NOT support `hooks`, `mcpServers`, or `permissionMode` frontmatter fields for security reasons.

## Submit to official marketplace

- Claude.ai: claude.ai/settings/plugins/submit
- Console: platform.claude.com/plugins/submit
