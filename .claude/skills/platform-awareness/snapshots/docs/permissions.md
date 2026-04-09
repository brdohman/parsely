<!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/permissions.md -->

# Configure permissions

> Control what Claude Code can access and do with fine-grained permission rules, modes, and managed policies.

## Permission system

| Tool type | Example | Approval required | "Yes, don't ask again" behavior |
| :-------- | :------ | :---------------- | :------------------------------ |
| Read-only | File reads, Grep | No | N/A |
| Bash commands | Shell execution | Yes | Permanently per project directory and command |
| File modification | Edit/write files | Yes | Until session end |

Rules are evaluated in order: **deny -> ask -> allow**. The first matching rule wins.

## Permission modes

| Mode | Description |
| :--- | :---------- |
| `default` | Standard behavior: prompts for permission on first use |
| `acceptEdits` | Automatically accepts file edit permissions |
| `plan` | Plan Mode: Claude can analyze but not modify or execute |
| `auto` | Auto-approves with background safety checks (research preview) |
| `dontAsk` | Auto-denies tools unless pre-approved |
| `bypassPermissions` | Skips permission prompts (protected dirs still prompt) |

Protected directories that always prompt in bypassPermissions: `.git`, `.claude`, `.vscode`, `.idea` (except `.claude/commands`, `.claude/agents`, `.claude/skills`).

## Permission rule syntax

Format: `Tool` or `Tool(specifier)`

### Wildcard patterns

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Bash(git * main)",
      "Bash(* --version)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

Space before `*` matters: `Bash(ls *)` matches `ls -la` but not `lsof`.

## Tool-specific rules

### Bash
- `Bash(npm run build)` - exact command match
- `Bash(npm run test *)` - prefix match
- `Bash(npm *)` - any npm command
- `Bash(* install)` - any command ending with install
- `Bash(git * main)` - commands like `git checkout main`

### Read and Edit
Read/Edit rules follow gitignore specification with four pattern types:

| Pattern | Meaning | Example |
| :------ | :------ | :------ |
| `//path` | Absolute path from filesystem root | `Read(//Users/alice/secrets/**)` |
| `~/path` | Path from home directory | `Read(~/Documents/*.pdf)` |
| `/path` | Path relative to project root | `Edit(/src/**/*.ts)` |
| `path` or `./path` | Path relative to current directory | `Read(*.env)` |

Note: `/Users/alice/file` is NOT absolute - it's relative to project root. Use `//Users/alice/file` for absolute.

In gitignore: `*` matches files in a single directory, `**` matches recursively.

### WebFetch
- `WebFetch(domain:example.com)` - matches fetch requests to example.com

### MCP
- `mcp__puppeteer` - any tool from the `puppeteer` server
- `mcp__puppeteer__puppeteer_navigate` - specific tool

### Agent (subagents)
- `Agent(Explore)` - Explore subagent
- `Agent(my-custom-agent)` - custom subagent

## Extend permissions with hooks

PreToolUse hooks run before the permission prompt. Hook output can:
- Deny the tool call (exit code 2)
- Force a prompt
- Skip the prompt (allow)

Note: Skipping the prompt does NOT bypass permission rules. Deny rules still evaluated.

## Working directories

- **Startup**: `--add-dir <path>` CLI argument
- **During session**: `/add-dir` command
- **Persistent**: `additionalDirectories` in settings files

## Managed settings

### Managed-only settings

| Setting | Description |
| :------ | :---------- |
| `allowManagedPermissionRulesOnly` | Prevents user/project from defining allow/ask/deny rules |
| `allowManagedHooksOnly` | Prevents loading of user/project/plugin hooks |
| `allowManagedMcpServersOnly` | Only managed MCP servers respected |
| `allowedChannelPlugins` | Allowlist of channel plugins |
| `blockedMarketplaces` | Blocklist of marketplace sources |
| `sandbox.network.allowManagedDomainsOnly` | Only managed domains allowed |
| `sandbox.filesystem.allowManagedReadPathsOnly` | Only managed read paths respected |
| `strictKnownMarketplaces` | Controls which plugin marketplaces users can add |

## Configure auto mode classifier

The `autoMode` settings block tells the classifier which infrastructure your organization trusts.

```json
{
  "autoMode": {
    "environment": [
      "Source control: github.example.com/acme-corp and all repos under it",
      "Trusted cloud buckets: s3://acme-build-artifacts",
      "Trusted internal domains: *.corp.example.com",
      "Key internal services: Jenkins at ci.example.com"
    ]
  }
}
```

Environment template:
```json
{
  "autoMode": {
    "environment": [
      "Organization: {COMPANY_NAME}. Primary use: {PRIMARY_USE_CASE}",
      "Source control: {SOURCE_CONTROL}",
      "Cloud provider(s): {CLOUD_PROVIDERS}",
      "Trusted cloud buckets: {TRUSTED_BUCKETS}",
      "Trusted internal domains: {TRUSTED_DOMAINS}",
      "Key internal services: {SERVICES}",
      "Additional context: {EXTRA}"
    ]
  }
}
```

CLI commands for inspection:
```bash
claude auto-mode defaults  # built-in rules
claude auto-mode config    # effective config
claude auto-mode critique  # AI feedback on custom rules
```

**Warning**: Setting `allow` or `soft_deny` REPLACES the entire default list for that section. Always run `claude auto-mode defaults` first and copy the defaults before customizing.

## Settings precedence

1. **Managed settings** (cannot be overridden)
2. **Command line arguments**
3. **Local project settings** (`.claude/settings.local.json`)
4. **Shared project settings** (`.claude/settings.json`)
5. **User settings** (`~/.claude/settings.json`)

If a tool is denied at any level, no other level can allow it.
