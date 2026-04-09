<\!-- Snapshot: 2026-03-27 | Source: https://code.claude.com/docs/en/mcp.md -->
     1→> ## Documentation Index
     2→> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
     3→> Use this file to discover all available pages before exploring further.
     4→
     5→# Connect Claude Code to tools via MCP
     6→
     7→> Learn how to connect Claude Code to your tools with the Model Context Protocol.
     8→
     9→export const MCPServersTable = ({platform = "all"}) => {
    10→  const ifYouAreAnAiAgentReadingThisYouShouldInsteadFetch = 'https://api.anthropic.com/mcp-registry/docs';
    11→  const [servers, setServers] = useState([]);
    12→  const [loading, setLoading] = useState(true);
    13→  const [error, setError] = useState(null);
    14→  useEffect(() => {
    15→    const fetchServers = async () => {
    16→      try {
    17→        setLoading(true);
    18→        const allServers = [];
    19→        let cursor = null;
    20→        do {
    21→          const url = new URL('https://api.anthropic.com/mcp-registry/v0/servers');
    22→          url.searchParams.set('version', 'latest');
    23→          url.searchParams.set('visibility', 'commercial');
    24→          url.searchParams.set('limit', '100');
    25→          if (cursor) {
    26→            url.searchParams.set('cursor', cursor);
    27→          }
    28→          const response = await fetch(url);
    29→          if (!response.ok) {
    30→            throw new Error(`Failed to fetch MCP registry: ${response.status}`);
    31→          }
    32→          const data = await response.json();
    33→          allServers.push(...data.servers);
    34→          cursor = data.metadata?.nextCursor || null;
    35→        } while (cursor);
    36→        const transformedServers = allServers.map(item => {
    37→          const server = item.server;
    38→          const meta = item._meta?.['com.anthropic.api/mcp-registry'] || ({});
    39→          const worksWith = meta.worksWith || [];
    40→          const availability = {
    41→            claudeCode: worksWith.includes('claude-code'),
    42→            mcpConnector: worksWith.includes('claude-api'),
    43→            claudeDesktop: worksWith.includes('claude-desktop')
    44→          };
    45→          const remotes = server.remotes || [];
    46→          const httpRemote = remotes.find(r => r.type === 'streamable-http');
    47→          const sseRemote = remotes.find(r => r.type === 'sse');
    48→          const preferredRemote = httpRemote || sseRemote;
    49→          const remoteUrl = preferredRemote?.url || meta.url;
    50→          const remoteType = preferredRemote?.type;
    51→          const isTemplatedUrl = remoteUrl?.includes('{');
    52→          let setupUrl;
    53→          if (isTemplatedUrl && meta.requiredFields) {
    54→            const urlField = meta.requiredFields.find(f => f.field === 'url');
    55→            setupUrl = urlField?.sourceUrl || meta.documentation;
    56→          }
    57→          const urls = {};
    58→          if (!isTemplatedUrl) {
    59→            if (remoteType === 'streamable-http') {
    60→              urls.http = remoteUrl;
    61→            } else if (remoteType === 'sse') {
    62→              urls.sse = remoteUrl;
    63→            }
    64→          }
    65→          let envVars = [];
    66→          if (server.packages && server.packages.length > 0) {
    67→            const npmPackage = server.packages.find(p => p.registryType === 'npm');
    68→            if (npmPackage) {
    69→              urls.stdio = `npx -y ${npmPackage.identifier}`;
    70→              if (npmPackage.environmentVariables) {
    71→                envVars = npmPackage.environmentVariables;
    72→              }
    73→            }
    74→          }
    75→          return {
    76→            name: meta.displayName || server.title || server.name,
    77→            description: meta.oneLiner || server.description,
    78→            documentation: meta.documentation,
    79→            urls: urls,
    80→            envVars: envVars,
    81→            availability: availability,
    82→            customCommands: meta.claudeCodeCopyText ? {
    83→              claudeCode: meta.claudeCodeCopyText
    84→            } : undefined,
    85→            setupUrl: setupUrl
    86→          };
    87→        });
    88→        setServers(transformedServers);
    89→        setError(null);
    90→      } catch (err) {
    91→        setError(err.message);
    92→        console.error('Error fetching MCP registry:', err);
    93→      } finally {
    94→        setLoading(false);
    95→      }
    96→    };
    97→    fetchServers();
    98→  }, []);
    99→  const generateClaudeCodeCommand = server => {
   100→    if (server.customCommands && server.customCommands.claudeCode) {
   101→      return server.customCommands.claudeCode;
   102→    }
   103→    const serverSlug = server.name.toLowerCase().replace(/[^a-z0-9]/g, '-');
   104→    if (server.urls.http) {
   105→      return `claude mcp add ${serverSlug} --transport http ${server.urls.http}`;
   106→    }
   107→    if (server.urls.sse) {
   108→      return `claude mcp add ${serverSlug} --transport sse ${server.urls.sse}`;
   109→    }
   110→    if (server.urls.stdio) {
   111→      const envFlags = server.envVars && server.envVars.length > 0 ? server.envVars.map(v => `--env ${v.name}=YOUR_${v.name}`).join(' ') : '';
   112→      const baseCommand = `claude mcp add ${serverSlug} --transport stdio`;
   113→      return envFlags ? `${baseCommand} ${envFlags} -- ${server.urls.stdio}` : `${baseCommand} -- ${server.urls.stdio}`;
   114→    }
   115→    return null;
   116→  };
   117→  if (loading) {
   118→    return <div>Loading MCP servers...</div>;
   119→  }
   120→  if (error) {
   121→    return <div>Error loading MCP servers: {error}</div>;
   122→  }
   123→  const filteredServers = servers.filter(server => {
   124→    if (platform === "claudeCode") {
   125→      return server.availability.claudeCode;
   126→    } else if (platform === "mcpConnector") {
   127→      return server.availability.mcpConnector;
   128→    } else if (platform === "claudeDesktop") {
   129→      return server.availability.claudeDesktop;
   130→    } else if (platform === "all") {
   131→      return true;
   132→    } else {
   133→      throw new Error(`Unknown platform: ${platform}`);
   134→    }
   135→  });
   136→  return <>
   137→      <style jsx>{`
   138→        .cards-container {
   139→          display: grid;
   140→          gap: 1rem;
   141→          margin-bottom: 2rem;
   142→        }
   143→        .server-card {
   144→          border: 1px solid var(--border-color, #e5e7eb);
   145→          border-radius: 6px;
   146→          padding: 1rem;
   147→        }
   148→        .command-row {
   149→          display: flex;
   150→          align-items: center;
   151→          gap: 0.25rem;
   152→        }
   153→        .command-row code {
   154→          font-size: 0.75rem;
   155→          overflow-x: auto;
   156→        }
   157→      `}</style>
   158→
   159→      <div className="cards-container">
   160→        {filteredServers.map(server => {
   161→    const claudeCodeCommand = generateClaudeCodeCommand(server);
   162→    const mcpUrl = server.urls.http || server.urls.sse;
   163→    const commandToShow = platform === "claudeCode" ? claudeCodeCommand : mcpUrl;
   164→    return <div key={server.name} className="server-card">
   165→              <div>
   166→                {server.documentation ? <a href={server.documentation}>
   167→                    <strong>{server.name}</strong>
   168→                  </a> : <strong>{server.name}</strong>}
   169→              </div>
   170→
   171→              <p style={{
   172→      margin: '0.5rem 0',
   173→      fontSize: '0.9rem'
   174→    }}>
   175→                {server.description}
   176→              </p>
   177→
   178→              {server.setupUrl && <p style={{
   179→      margin: '0.25rem 0',
   180→      fontSize: '0.8rem',
   181→      fontStyle: 'italic',
   182→      opacity: 0.7
   183→    }}>
   184→                  Requires user-specific URL.{' '}
   185→                  <a href={server.setupUrl} style={{
   186→      textDecoration: 'underline'
   187→    }}>
   188→                    Get your URL here
   189→                  </a>.
   190→                </p>}
   191→
   192→              {commandToShow && !server.setupUrl && <>
   193→                <p style={{
   194→      display: 'block',
   195→      fontSize: '0.75rem',
   196→      fontWeight: 500,
   197→      minWidth: 'fit-content',
   198→      marginTop: '0.5rem',
   199→      marginBottom: 0
   200→    }}>
   201→                  {platform === "claudeCode" ? "Command" : "URL"}
   202→                </p>
   203→                <div className="command-row">
   204→                  <code>
   205→                    {commandToShow}
   206→                  </code>
   207→                </div>
   208→              </>}
   209→            </div>;
   210→  })}
   211→      </div>
   212→    </>;
   213→};
   214→
   215→Claude Code can connect to hundreds of external tools and data sources through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction), an open source standard for AI-tool integrations. MCP servers give Claude Code access to your tools, databases, and APIs.
   216→
   217→## What you can do with MCP
   218→
   219→With MCP servers connected, you can ask Claude Code to:
   220→
   221→* **Implement features from issue trackers**: "Add the feature described in JIRA issue ENG-4521 and create a PR on GitHub."
   222→* **Analyze monitoring data**: "Check Sentry and Statsig to check the usage of the feature described in ENG-4521."
   223→* **Query databases**: "Find emails of 10 random users who used feature ENG-4521, based on our PostgreSQL database."
   224→* **Integrate designs**: "Update our standard email template based on the new Figma designs that were posted in Slack"
   225→* **Automate workflows**: "Create Gmail drafts inviting these 10 users to a feedback session about the new feature."
   226→* **React to external events**: An MCP server can also act as a [channel](/en/channels) that pushes messages into your session, so Claude reacts to Telegram messages, Discord chats, or webhook events while you're away.
   227→
   228→## Popular MCP servers
   229→
   230→Here are some commonly used MCP servers you can connect to Claude Code:
   231→
   232→<Warning>
   233→  Use third party MCP servers at your own risk - Anthropic has not verified
   234→  the correctness or security of all these servers.
   235→  Make sure you trust MCP servers you are installing.
   236→  Be especially careful when using MCP servers that could fetch untrusted
   237→  content, as these can expose you to prompt injection risk.
   238→</Warning>
   239→
   240→<MCPServersTable platform="claudeCode" />
   241→
   242→<Note>
   243→  **Need a specific integration?** [Find hundreds more MCP servers on GitHub](https://github.com/modelcontextprotocol/servers), or build your own using the [MCP SDK](https://modelcontextprotocol.io/quickstart/server).
   244→</Note>
   245→
   246→## Installing MCP servers
   247→
   248→MCP servers can be configured in three different ways depending on your needs:
   249→
   250→### Option 1: Add a remote HTTP server
   251→
   252→HTTP servers are the recommended option for connecting to remote MCP servers. This is the most widely supported transport for cloud-based services.
   253→
   254→```bash  theme={null}
   255→# Basic syntax
   256→claude mcp add --transport http <name> <url>
   257→
   258→# Real example: Connect to Notion
   259→claude mcp add --transport http notion https://mcp.notion.com/mcp
   260→
   261→# Example with Bearer token
   262→claude mcp add --transport http secure-api https://api.example.com/mcp \
   263→  --header "Authorization: Bearer your-token"
   264→```
   265→
   266→### Option 2: Add a remote SSE server
   267→
   268→<Warning>
   269→  The SSE (Server-Sent Events) transport is deprecated. Use HTTP servers instead, where available.
   270→</Warning>
   271→
   272→```bash  theme={null}
   273→# Basic syntax
   274→claude mcp add --transport sse <name> <url>
   275→
   276→# Real example: Connect to Asana
   277→claude mcp add --transport sse asana https://mcp.asana.com/sse
   278→
   279→# Example with authentication header
   280→claude mcp add --transport sse private-api https://api.company.com/sse \
   281→  --header "X-API-Key: your-key-here"
   282→```
   283→
   284→### Option 3: Add a local stdio server
   285→
   286→Stdio servers run as local processes on your machine. They're ideal for tools that need direct system access or custom scripts.
   287→
   288→```bash  theme={null}
   289→# Basic syntax
   290→claude mcp add [options] <name> -- <command> [args...]
   291→
   292→# Real example: Add Airtable server
   293→claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
   294→  -- npx -y airtable-mcp-server
   295→```
   296→
   297→<Note>
   298→  **Important: Option ordering**
   299→
   300→  All options (`--transport`, `--env`, `--scope`, `--header`) must come **before** the server name. The `--` (double dash) then separates the server name from the command and arguments that get passed to the MCP server.
   301→
   302→  For example:
   303→
   304→  * `claude mcp add --transport stdio myserver -- npx server` → runs `npx server`
   305→  * `claude mcp add --transport stdio --env KEY=value myserver -- python server.py --port 8080` → runs `python server.py --port 8080` with `KEY=value` in environment
   306→
   307→  This prevents conflicts between Claude's flags and the server's flags.
   308→</Note>
   309→
   310→### Managing your servers
   311→
   312→Once configured, you can manage your MCP servers with these commands:
   313→
   314→```bash  theme={null}
   315→# List all configured servers
   316→claude mcp list
   317→
   318→# Get details for a specific server
   319→claude mcp get github
   320→
   321→# Remove a server
   322→claude mcp remove github
   323→
   324→# (within Claude Code) Check server status
   325→/mcp
   326→```
   327→
   328→### Dynamic tool updates
   329→
   330→Claude Code supports MCP `list_changed` notifications, allowing MCP servers to dynamically update their available tools, prompts, and resources without requiring you to disconnect and reconnect. When an MCP server sends a `list_changed` notification, Claude Code automatically refreshes the available capabilities from that server.
   331→
   332→### Push messages with channels
   333→
   334→An MCP server can also push messages directly into your session so Claude can react to external events like CI results, monitoring alerts, or chat messages. To enable this, your server declares the `claude/channel` capability and you opt it in with the `--channels` flag at startup. See [Channels](/en/channels) to use an officially supported channel, or [Channels reference](/en/channels-reference) to build your own.
   335→
   336→<Tip>
   337→  Tips:
   338→
   339→  * Use the `--scope` flag to specify where the configuration is stored:
   340→    * `local` (default): Available only to you in the current project (was called `project` in older versions)
   341→    * `project`: Shared with everyone in the project via `.mcp.json` file
   342→    * `user`: Available to you across all projects (was called `global` in older versions)
   343→  * Set environment variables with `--env` flags (for example, `--env KEY=value`)
   344→  * Configure MCP server startup timeout using the MCP\_TIMEOUT environment variable (for example, `MCP_TIMEOUT=10000 claude` sets a 10-second timeout)
   345→  * Claude Code will display a warning when MCP tool output exceeds 10,000 tokens. To increase this limit, set the `MAX_MCP_OUTPUT_TOKENS` environment variable (for example, `MAX_MCP_OUTPUT_TOKENS=50000`)
   346→  * Use `/mcp` to authenticate with remote servers that require OAuth 2.0 authentication
   347→</Tip>
   348→
   349→<Warning>
   350→  **Windows Users**: On native Windows (not WSL), local MCP servers that use `npx` require the `cmd /c` wrapper to ensure proper execution.
   351→
   352→  ```bash  theme={null}
   353→  # This creates command="cmd" which Windows can execute
   354→  claude mcp add --transport stdio my-server -- cmd /c npx -y @some/package
   355→  ```
   356→
   357→  Without the `cmd /c` wrapper, you'll encounter "Connection closed" errors because Windows cannot directly execute `npx`. (See the note above for an explanation of the `--` parameter.)
   358→</Warning>
   359→
   360→### Plugin-provided MCP servers
   361→
   362→[Plugins](/en/plugins) can bundle MCP servers, automatically providing tools and integrations when the plugin is enabled. Plugin MCP servers work identically to user-configured servers.
   363→
   364→**How plugin MCP servers work**:
   365→
   366→* Plugins define MCP servers in `.mcp.json` at the plugin root or inline in `plugin.json`
   367→* When a plugin is enabled, its MCP servers start automatically
   368→* Plugin MCP tools appear alongside manually configured MCP tools
   369→* Plugin servers are managed through plugin installation (not `/mcp` commands)
   370→
   371→**Example plugin MCP configuration**:
   372→
   373→In `.mcp.json` at plugin root:
   374→
   375→```json  theme={null}
   376→{
   377→  "mcpServers": {
   378→    "database-tools": {
   379→      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
   380→      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
   381→      "env": {
   382→        "DB_URL": "${DB_URL}"
   383→      }
   384→    }
   385→  }
   386→}
   387→```
   388→
   389→Or inline in `plugin.json`:
   390→
   391→```json  theme={null}
   392→{
   393→  "name": "my-plugin",
   394→  "mcpServers": {
   395→    "plugin-api": {
   396→      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
   397→      "args": ["--port", "8080"]
   398→    }
   399→  }
   400→}
   401→```
   402→
   403→**Plugin MCP features**:
   404→
   405→* **Automatic lifecycle**: At session startup, servers for enabled plugins connect automatically. If you enable or disable a plugin during a session, run `/reload-plugins` to connect or disconnect its MCP servers
   406→* **Environment variables**: use `${CLAUDE_PLUGIN_ROOT}` for bundled plugin files and `${CLAUDE_PLUGIN_DATA}` for [persistent state](/en/plugins-reference#persistent-data-directory) that survives plugin updates
   407→* **User environment access**: Access to same environment variables as manually configured servers
   408→* **Multiple transport types**: Support stdio, SSE, and HTTP transports (transport support may vary by server)
   409→
   410→**Viewing plugin MCP servers**:
   411→
   412→```bash  theme={null}
   413→# Within Claude Code, see all MCP servers including plugin ones
   414→/mcp
   415→```
   416→
   417→Plugin servers appear in the list with indicators showing they come from plugins.
   418→
   419→**Benefits of plugin MCP servers**:
   420→
   421→* **Bundled distribution**: Tools and servers packaged together
   422→* **Automatic setup**: No manual MCP configuration needed
   423→* **Team consistency**: Everyone gets the same tools when plugin is installed
   424→
   425→See the [plugin components reference](/en/plugins-reference#mcp-servers) for details on bundling MCP servers with plugins.
   426→
   427→## MCP installation scopes
   428→
   429→MCP servers can be configured at three different scope levels, each serving distinct purposes for managing server accessibility and sharing. Understanding these scopes helps you determine the best way to configure servers for your specific needs.
   430→
   431→### Local scope
   432→
   433→Local-scoped servers represent the default configuration level and are stored in `~/.claude.json` under your project's path. These servers remain private to you and are only accessible when working within the current project directory. This scope is ideal for personal development servers, experimental configurations, or servers containing sensitive credentials that shouldn't be shared.
   434→
   435→<Note>
   436→  The term "local scope" for MCP servers differs from general local settings. MCP local-scoped servers are stored in `~/.claude.json` (your home directory), while general local settings use `.claude/settings.local.json` (in the project directory). See [Settings](/en/settings#settings-files) for details on settings file locations.
   437→</Note>
   438→
   439→```bash  theme={null}
   440→# Add a local-scoped server (default)
   441→claude mcp add --transport http stripe https://mcp.stripe.com
   442→
   443→# Explicitly specify local scope
   444→claude mcp add --transport http stripe --scope local https://mcp.stripe.com
   445→```
   446→
   447→### Project scope
   448→
   449→Project-scoped servers enable team collaboration by storing configurations in a `.mcp.json` file at your project's root directory. This file is designed to be checked into version control, ensuring all team members have access to the same MCP tools and services. When you add a project-scoped server, Claude Code automatically creates or updates this file with the appropriate configuration structure.
   450→
   451→```bash  theme={null}
   452→# Add a project-scoped server
   453→claude mcp add --transport http paypal --scope project https://mcp.paypal.com/mcp
   454→```
   455→
   456→The resulting `.mcp.json` file follows a standardized format:
   457→
   458→```json  theme={null}
   459→{
   460→  "mcpServers": {
   461→    "shared-server": {
   462→      "command": "/path/to/server",
   463→      "args": [],
   464→      "env": {}
   465→    }
   466→  }
   467→}
   468→```
   469→
   470→For security reasons, Claude Code prompts for approval before using project-scoped servers from `.mcp.json` files. If you need to reset these approval choices, use the `claude mcp reset-project-choices` command.
   471→
   472→### User scope
   473→
   474→User-scoped servers are stored in `~/.claude.json` and provide cross-project accessibility, making them available across all projects on your machine while remaining private to your user account. This scope works well for personal utility servers, development tools, or services you frequently use across different projects.
   475→
   476→```bash  theme={null}
   477→# Add a user server
   478→claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
   479→```
   480→
   481→### Choosing the right scope
   482→
   483→Select your scope based on:
   484→
   485→* **Local scope**: Personal servers, experimental configurations, or sensitive credentials specific to one project
   486→* **Project scope**: Team-shared servers, project-specific tools, or services required for collaboration
   487→* **User scope**: Personal utilities needed across multiple projects, development tools, or frequently used services
   488→
   489→<Note>
   490→  **Where are MCP servers stored?**
   491→
   492→  * **User and local scope**: `~/.claude.json` (in the `mcpServers` field or under project paths)
   493→  * **Project scope**: `.mcp.json` in your project root (checked into source control)
   494→  * **Managed**: `managed-mcp.json` in system directories (see [Managed MCP configuration](#managed-mcp-configuration))
   495→</Note>
   496→
   497→### Scope hierarchy and precedence
   498→
   499→MCP server configurations follow a clear precedence hierarchy. When servers with the same name exist at multiple scopes, the system resolves conflicts by prioritizing local-scoped servers first, followed by project-scoped servers, and finally user-scoped servers. This design ensures that personal configurations can override shared ones when needed.
   500→
   501→If a server is configured both locally and through a [claude.ai connector](#use-mcp-servers-from-claude-ai), the local configuration takes precedence and the connector entry is skipped.
   502→
   503→### Environment variable expansion in `.mcp.json`
   504→
   505→Claude Code supports environment variable expansion in `.mcp.json` files, allowing teams to share configurations while maintaining flexibility for machine-specific paths and sensitive values like API keys.
   506→
   507→**Supported syntax:**
   508→
   509→* `${VAR}` - Expands to the value of environment variable `VAR`
   510→* `${VAR:-default}` - Expands to `VAR` if set, otherwise uses `default`
   511→
   512→**Expansion locations:**
   513→Environment variables can be expanded in:
   514→
   515→* `command` - The server executable path
   516→* `args` - Command-line arguments
   517→* `env` - Environment variables passed to the server
   518→* `url` - For HTTP server types
   519→* `headers` - For HTTP server authentication
   520→
   521→**Example with variable expansion:**
   522→
   523→```json  theme={null}
   524→{
   525→  "mcpServers": {
   526→    "api-server": {
   527→      "type": "http",
   528→      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
   529→      "headers": {
   530→        "Authorization": "Bearer ${API_KEY}"
   531→      }
   532→    }
   533→  }
   534→}
   535→```
   536→
   537→If a required environment variable is not set and has no default value, Claude Code will fail to parse the config.
   538→
   539→## Practical examples
   540→
   541→{/* ### Example: Automate browser testing with Playwright
   542→
   543→  ```bash
   544→  claude mcp add --transport stdio playwright -- npx -y @playwright/mcp@latest
   545→  ```
   546→
   547→  Then write and run browser tests:
   548→
   549→  ```text
   550→  Test if the login flow works with test@example.com
   551→  ```
   552→  ```text
   553→  Take a screenshot of the checkout page on mobile
   554→  ```
   555→  ```text
   556→  Verify that the search feature returns results
   557→  ``` */}
   558→
   559→### Example: Monitor errors with Sentry
   560→
   561→```bash  theme={null}
   562→claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
   563→```
   564→
   565→Authenticate with your Sentry account:
   566→
   567→```text  theme={null}
   568→/mcp
   569→```
   570→
   571→Then debug production issues:
   572→
   573→```text  theme={null}
   574→What are the most common errors in the last 24 hours?
   575→```
   576→
   577→```text  theme={null}
   578→Show me the stack trace for error ID abc123
   579→```
   580→
   581→```text  theme={null}
   582→Which deployment introduced these new errors?
   583→```
   584→
   585→### Example: Connect to GitHub for code reviews
   586→
   587→```bash  theme={null}
   588→claude mcp add --transport http github https://api.githubcopilot.com/mcp/
   589→```
   590→
   591→Authenticate if needed by selecting "Authenticate" for GitHub:
   592→
   593→```text  theme={null}
   594→/mcp
   595→```
   596→
   597→Then work with GitHub:
   598→
   599→```text  theme={null}
   600→Review PR #456 and suggest improvements
   601→```
   602→
   603→```text  theme={null}
   604→Create a new issue for the bug we just found
   605→```
   606→
   607→```text  theme={null}
   608→Show me all open PRs assigned to me
   609→```
   610→
   611→### Example: Query your PostgreSQL database
   612→
   613→```bash  theme={null}
   614→claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
   615→  --dsn "postgresql://readonly:pass@prod.db.com:5432/analytics"
   616→```
   617→
   618→Then query your database naturally:
   619→
   620→```text  theme={null}
   621→What's our total revenue this month?
   622→```
   623→
   624→```text  theme={null}
   625→Show me the schema for the orders table
   626→```
   627→
   628→```text  theme={null}
   629→Find customers who haven't made a purchase in 90 days
   630→```
   631→
   632→## Authenticate with remote MCP servers
   633→
   634→Many cloud-based MCP servers require authentication. Claude Code supports OAuth 2.0 for secure connections.
   635→
   636→<Steps>
   637→  <Step title="Add the server that requires authentication">
   638→    For example:
   639→
   640→    ```bash  theme={null}
   641→    claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
   642→    ```
   643→  </Step>
   644→
   645→  <Step title="Use the /mcp command within Claude Code">
   646→    In Claude code, use the command:
   647→
   648→    ```text  theme={null}
   649→    /mcp
   650→    ```
   651→
   652→    Then follow the steps in your browser to login.
   653→  </Step>
   654→</Steps>
   655→
   656→<Tip>
   657→  Tips:
   658→
   659→  * Authentication tokens are stored securely and refreshed automatically
   660→  * Use "Clear authentication" in the `/mcp` menu to revoke access
   661→  * If your browser doesn't open automatically, copy the provided URL and open it manually
   662→  * If the browser redirect fails with a connection error after authenticating, paste the full callback URL from your browser's address bar into the URL prompt that appears in Claude Code
   663→  * OAuth authentication works with HTTP servers
   664→</Tip>
   665→
   666→### Use a fixed OAuth callback port
   667→
   668→Some MCP servers require a specific redirect URI registered in advance. By default, Claude Code picks a random available port for the OAuth callback. Use `--callback-port` to fix the port so it matches a pre-registered redirect URI of the form `http://localhost:PORT/callback`.
   669→
   670→You can use `--callback-port` on its own (with dynamic client registration) or together with `--client-id` (with pre-configured credentials).
   671→
   672→```bash  theme={null}
   673→# Fixed callback port with dynamic client registration
   674→claude mcp add --transport http \
   675→  --callback-port 8080 \
   676→  my-server https://mcp.example.com/mcp
   677→```
   678→
   679→### Use pre-configured OAuth credentials
   680→
   681→Some MCP servers don't support automatic OAuth setup via Dynamic Client Registration. If you see an error like "Incompatible auth server: does not support dynamic client registration," the server requires pre-configured credentials. Claude Code also supports servers that use a Client ID Metadata Document (CIMD) instead of Dynamic Client Registration, and discovers these automatically. If automatic discovery fails, register an OAuth app through the server's developer portal first, then provide the credentials when adding the server.
   682→
   683→<Steps>
   684→  <Step title="Register an OAuth app with the server">
   685→    Create an app through the server's developer portal and note your client ID and client secret.
   686→
   687→    Many servers also require a redirect URI. If so, choose a port and register a redirect URI in the format `http://localhost:PORT/callback`. Use that same port with `--callback-port` in the next step.
   688→  </Step>
   689→
   690→  <Step title="Add the server with your credentials">
   691→    Choose one of the following methods. The port used for `--callback-port` can be any available port. It just needs to match the redirect URI you registered in the previous step.
   692→
   693→    <Tabs>
   694→      <Tab title="claude mcp add">
   695→        Use `--client-id` to pass your app's client ID. The `--client-secret` flag prompts for the secret with masked input:
   696→
   697→        ```bash  theme={null}
   698→        claude mcp add --transport http \
   699→          --client-id your-client-id --client-secret --callback-port 8080 \
   700→          my-server https://mcp.example.com/mcp
   701→        ```
   702→      </Tab>
   703→
   704→      <Tab title="claude mcp add-json">
   705→        Include the `oauth` object in the JSON config and pass `--client-secret` as a separate flag:
   706→
   707→        ```bash  theme={null}
   708→        claude mcp add-json my-server \
   709→          '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"clientId":"your-client-id","callbackPort":8080}}' \
   710→          --client-secret
   711→        ```
   712→      </Tab>
   713→
   714→      <Tab title="claude mcp add-json (callback port only)">
   715→        Use `--callback-port` without a client ID to fix the port while using dynamic client registration:
   716→
   717→        ```bash  theme={null}
   718→        claude mcp add-json my-server \
   719→          '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"callbackPort":8080}}'
   720→        ```
   721→      </Tab>
   722→
   723→      <Tab title="CI / env var">
   724→        Set the secret via environment variable to skip the interactive prompt:
   725→
   726→        ```bash  theme={null}
   727→        MCP_CLIENT_SECRET=your-secret claude mcp add --transport http \
   728→          --client-id your-client-id --client-secret --callback-port 8080 \
   729→          my-server https://mcp.example.com/mcp
   730→        ```
   731→      </Tab>
   732→    </Tabs>
   733→  </Step>
   734→
   735→  <Step title="Authenticate in Claude Code">
   736→    Run `/mcp` in Claude Code and follow the browser login flow.
   737→  </Step>
   738→</Steps>
   739→
   740→<Tip>
   741→  Tips:
   742→
   743→  * The client secret is stored securely in your system keychain (macOS) or a credentials file, not in your config
   744→  * If the server uses a public OAuth client with no secret, use only `--client-id` without `--client-secret`
   745→  * `--callback-port` can be used with or without `--client-id`
   746→  * These flags only apply to HTTP and SSE transports. They have no effect on stdio servers
   747→  * Use `claude mcp get <name>` to verify that OAuth credentials are configured for a server
   748→</Tip>
   749→
   750→### Override OAuth metadata discovery
   751→
   752→If your MCP server's standard OAuth metadata endpoints return errors but the server exposes a working OIDC endpoint, you can point Claude Code at a specific metadata URL to bypass the default discovery chain. By default, Claude Code first checks RFC 9728 Protected Resource Metadata at `/.well-known/oauth-protected-resource`, then falls back to RFC 8414 authorization server metadata at `/.well-known/oauth-authorization-server`.
   753→
   754→Set `authServerMetadataUrl` in the `oauth` object of your server's config in `.mcp.json`:
   755→
   756→```json  theme={null}
   757→{
   758→  "mcpServers": {
   759→    "my-server": {
   760→      "type": "http",
   761→      "url": "https://mcp.example.com/mcp",
   762→      "oauth": {
   763→        "authServerMetadataUrl": "https://auth.example.com/.well-known/openid-configuration"
   764→      }
   765→    }
   766→  }
   767→}
   768→```
   769→
   770→The URL must use `https://`. This option requires Claude Code v2.1.64 or later.
   771→
   772→### Use dynamic headers for custom authentication
   773→
   774→If your MCP server uses an authentication scheme other than OAuth (such as Kerberos, short-lived tokens, or an internal SSO), use `headersHelper` to generate request headers at connection time. Claude Code runs the command and merges its output into the connection headers.
   775→
   776→```json  theme={null}
   777→{
   778→  "mcpServers": {
   779→    "internal-api": {
   780→      "type": "http",
   781→      "url": "https://mcp.internal.example.com",
   782→      "headersHelper": "/opt/bin/get-mcp-auth-headers.sh"
   783→    }
   784→  }
   785→}
   786→```
   787→
   788→The command can also be inline:
   789→
   790→```json  theme={null}
   791→{
   792→  "mcpServers": {
   793→    "internal-api": {
   794→      "type": "http",
   795→      "url": "https://mcp.internal.example.com",
   796→      "headersHelper": "echo '{\"Authorization\": \"Bearer '\"$(get-token)\"'\"}'"
   797→    }
   798→  }
   799→}
   800→```
   801→
   802→**Requirements:**
   803→
   804→* The command must write a JSON object of string key-value pairs to stdout
   805→* The command runs in a shell with a 10-second timeout
   806→* Dynamic headers override any static `headers` with the same name
   807→
   808→The helper runs fresh on each connection (at session start and on reconnect). There is no caching, so your script is responsible for any token reuse.
   809→
   810→Claude Code sets these environment variables when executing the helper:
   811→
   812→| Variable                      | Value                      |
   813→| :---------------------------- | :------------------------- |
   814→| `CLAUDE_CODE_MCP_SERVER_NAME` | the name of the MCP server |
   815→| `CLAUDE_CODE_MCP_SERVER_URL`  | the URL of the MCP server  |
   816→
   817→Use these to write a single helper script that serves multiple MCP servers.
   818→
   819→<Note>
   820→  `headersHelper` executes arbitrary shell commands. When defined at project or local scope, it only runs after you accept the workspace trust dialog.
   821→</Note>
   822→
   823→## Add MCP servers from JSON configuration
   824→
   825→If you have a JSON configuration for an MCP server, you can add it directly:
   826→
   827→<Steps>
   828→  <Step title="Add an MCP server from JSON">
   829→    ```bash  theme={null}
   830→    # Basic syntax
   831→    claude mcp add-json <name> '<json>'
   832→
   833→    # Example: Adding an HTTP server with JSON configuration
   834→    claude mcp add-json weather-api '{"type":"http","url":"https://api.weather.com/mcp","headers":{"Authorization":"Bearer token"}}'
   835→
   836→    # Example: Adding a stdio server with JSON configuration
   837→    claude mcp add-json local-weather '{"type":"stdio","command":"/path/to/weather-cli","args":["--api-key","abc123"],"env":{"CACHE_DIR":"/tmp"}}'
   838→
   839→    # Example: Adding an HTTP server with pre-configured OAuth credentials
   840→    claude mcp add-json my-server '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"clientId":"your-client-id","callbackPort":8080}}' --client-secret
   841→    ```
   842→  </Step>
   843→
   844→  <Step title="Verify the server was added">
   845→    ```bash  theme={null}
   846→    claude mcp get weather-api
   847→    ```
   848→  </Step>
   849→</Steps>
   850→
   851→<Tip>
   852→  Tips:
   853→
   854→  * Make sure the JSON is properly escaped in your shell
   855→  * The JSON must conform to the MCP server configuration schema
   856→  * You can use `--scope user` to add the server to your user configuration instead of the project-specific one
   857→</Tip>
   858→
   859→## Import MCP servers from Claude Desktop
   860→
   861→If you've already configured MCP servers in Claude Desktop, you can import them:
   862→
   863→<Steps>
   864→  <Step title="Import servers from Claude Desktop">
   865→    ```bash  theme={null}
   866→    # Basic syntax 
   867→    claude mcp add-from-claude-desktop 
   868→    ```
   869→  </Step>
   870→
   871→  <Step title="Select which servers to import">
   872→    After running the command, you'll see an interactive dialog that allows you to select which servers you want to import.
   873→  </Step>
   874→
   875→  <Step title="Verify the servers were imported">
   876→    ```bash  theme={null}
   877→    claude mcp list 
   878→    ```
   879→  </Step>
   880→</Steps>
   881→
   882→<Tip>
   883→  Tips:
   884→
   885→  * This feature only works on macOS and Windows Subsystem for Linux (WSL)
   886→  * It reads the Claude Desktop configuration file from its standard location on those platforms
   887→  * Use the `--scope user` flag to add servers to your user configuration
   888→  * Imported servers will have the same names as in Claude Desktop
   889→  * If servers with the same names already exist, they will get a numerical suffix (for example, `server_1`)
   890→</Tip>
   891→
   892→## Use MCP servers from Claude.ai
   893→
   894→If you've logged into Claude Code with a [Claude.ai](https://claude.ai) account, MCP servers you've added in Claude.ai are automatically available in Claude Code:
   895→
   896→<Steps>
   897→  <Step title="Configure MCP servers in Claude.ai">
   898→    Add servers at [claude.ai/settings/connectors](https://claude.ai/settings/connectors). On Team and Enterprise plans, only admins can add servers.
   899→  </Step>
   900→
   901→  <Step title="Authenticate the MCP server">
   902→    Complete any required authentication steps in Claude.ai.
   903→  </Step>
   904→
   905→  <Step title="View and manage servers in Claude Code">
   906→    In Claude Code, use the command:
   907→
   908→    ```text  theme={null}
   909→    /mcp
   910→    ```
   911→
   912→    Claude.ai servers appear in the list with indicators showing they come from Claude.ai.
   913→  </Step>
   914→</Steps>
   915→
   916→To disable claude.ai MCP servers in Claude Code, set the `ENABLE_CLAUDEAI_MCP_SERVERS` environment variable to `false`:
   917→
   918→```bash  theme={null}
   919→ENABLE_CLAUDEAI_MCP_SERVERS=false claude
   920→```
   921→
   922→## Use Claude Code as an MCP server
   923→
   924→You can use Claude Code itself as an MCP server that other applications can connect to:
   925→
   926→```bash  theme={null}
   927→# Start Claude as a stdio MCP server
   928→claude mcp serve
   929→```
   930→
   931→You can use this in Claude Desktop by adding this configuration to claude\_desktop\_config.json:
   932→
   933→```json  theme={null}
   934→{
   935→  "mcpServers": {
   936→    "claude-code": {
   937→      "type": "stdio",
   938→      "command": "claude",
   939→      "args": ["mcp", "serve"],
   940→      "env": {}
   941→    }
   942→  }
   943→}
   944→```
   945→
   946→<Warning>
   947→  **Configuring the executable path**: The `command` field must reference the Claude Code executable. If the `claude` command is not in your system's PATH, you'll need to specify the full path to the executable.
   948→
   949→  To find the full path:
   950→
   951→  ```bash  theme={null}
   952→  which claude
   953→  ```
   954→
   955→  Then use the full path in your configuration:
   956→
   957→  ```json  theme={null}
   958→  {
   959→    "mcpServers": {
   960→      "claude-code": {
   961→        "type": "stdio",
   962→        "command": "/full/path/to/claude",
   963→        "args": ["mcp", "serve"],
   964→        "env": {}
   965→      }
   966→    }
   967→  }
   968→  ```
   969→
   970→  Without the correct executable path, you'll encounter errors like `spawn claude ENOENT`.
   971→</Warning>
   972→
   973→<Tip>
   974→  Tips:
   975→
   976→  * The server provides access to Claude's tools like View, Edit, LS, etc.
   977→  * In Claude Desktop, try asking Claude to read files in a directory, make edits, and more.
   978→  * Note that this MCP server is only exposing Claude Code's tools to your MCP client, so your own client is responsible for implementing user confirmation for individual tool calls.
   979→</Tip>
   980→
   981→## MCP output limits and warnings
   982→
   983→When MCP tools produce large outputs, Claude Code helps manage the token usage to prevent overwhelming your conversation context:
   984→
   985→* **Output warning threshold**: Claude Code displays a warning when any MCP tool output exceeds 10,000 tokens
   986→* **Configurable limit**: You can adjust the maximum allowed MCP output tokens using the `MAX_MCP_OUTPUT_TOKENS` environment variable
   987→* **Default limit**: The default maximum is 25,000 tokens
   988→
   989→To increase the limit for tools that produce large outputs:
   990→
   991→```bash  theme={null}
   992→# Set a higher limit for MCP tool outputs
   993→export MAX_MCP_OUTPUT_TOKENS=50000
   994→claude
   995→```
   996→
   997→This is particularly useful when working with MCP servers that:
   998→
   999→* Query large datasets or databases
  1000→* Generate detailed reports or documentation
  1001→* Process extensive log files or debugging information
  1002→
  1003→<Warning>
  1004→  If you frequently encounter output warnings with specific MCP servers, consider increasing the limit or configuring the server to paginate or filter its responses.
  1005→</Warning>
  1006→
  1007→## Respond to MCP elicitation requests
  1008→
  1009→MCP servers can request structured input from you mid-task using elicitation. When a server needs information it can't get on its own, Claude Code displays an interactive dialog and passes your response back to the server. No configuration is required on your side: elicitation dialogs appear automatically when a server requests them.
  1010→
  1011→Servers can request input in two ways:
  1012→
  1013→* **Form mode**: Claude Code shows a dialog with form fields defined by the server (for example, a username and password prompt). Fill in the fields and submit.
  1014→* **URL mode**: Claude Code opens a browser URL for authentication or approval. Complete the flow in the browser, then confirm in the CLI.
  1015→
  1016→To auto-respond to elicitation requests without showing a dialog, use the [`Elicitation` hook](/en/hooks#elicitation).
  1017→
  1018→If you're building an MCP server that uses elicitation, see the [MCP elicitation specification](https://modelcontextprotocol.io/docs/learn/client-concepts#elicitation) for protocol details and schema examples.
  1019→
  1020→## Use MCP resources
  1021→
  1022→MCP servers can expose resources that you can reference using @ mentions, similar to how you reference files.
  1023→
  1024→### Reference MCP resources
  1025→
  1026→<Steps>
  1027→  <Step title="List available resources">
  1028→    Type `@` in your prompt to see available resources from all connected MCP servers. Resources appear alongside files in the autocomplete menu.
  1029→  </Step>
  1030→
  1031→  <Step title="Reference a specific resource">
  1032→    Use the format `@server:protocol://resource/path` to reference a resource:
  1033→
  1034→    ```text  theme={null}
  1035→    Can you analyze @github:issue://123 and suggest a fix?
  1036→    ```
  1037→
  1038→    ```text  theme={null}
  1039→    Please review the API documentation at @docs:file://api/authentication
  1040→    ```
  1041→  </Step>
  1042→
  1043→  <Step title="Multiple resource references">
  1044→    You can reference multiple resources in a single prompt:
  1045→
  1046→    ```text  theme={null}
  1047→    Compare @postgres:schema://users with @docs:file://database/user-model
  1048→    ```
  1049→  </Step>
  1050→</Steps>
  1051→
  1052→<Tip>
  1053→  Tips:
  1054→
  1055→  * Resources are automatically fetched and included as attachments when referenced
  1056→  * Resource paths are fuzzy-searchable in the @ mention autocomplete
  1057→  * Claude Code automatically provides tools to list and read MCP resources when servers support them
  1058→  * Resources can contain any type of content that the MCP server provides (text, JSON, structured data, etc.)
  1059→</Tip>
  1060→
  1061→## Scale with MCP Tool Search
  1062→
  1063→Tool search keeps MCP context usage low by deferring tool definitions until Claude needs them. Only tool names load at session start, so adding more MCP servers has minimal impact on your context window.
  1064→
  1065→### How it works
  1066→
  1067→Tool search is enabled by default. MCP tools are deferred rather than loaded into context upfront, and Claude uses a search tool to discover relevant ones when a task needs them. Only the tools Claude actually uses enter context. From your perspective, MCP tools work exactly as before.
  1068→
  1069→If you prefer threshold-based loading, set `ENABLE_TOOL_SEARCH=auto` to load schemas upfront when they fit within 10% of the context window and defer only the overflow. See [Configure tool search](#configure-tool-search) for all options.
  1070→
  1071→### For MCP server authors
  1072→
  1073→If you're building an MCP server, the server instructions field becomes more useful with Tool Search enabled. Server instructions help Claude understand when to search for your tools, similar to how [skills](/en/skills) work.
  1074→
  1075→Add clear, descriptive server instructions that explain:
  1076→
  1077→* What category of tasks your tools handle
  1078→* When Claude should search for your tools
  1079→* Key capabilities your server provides
  1080→
  1081→Claude Code truncates tool descriptions and server instructions at 2KB each. Keep them concise to avoid truncation, and put critical details near the start.
  1082→
  1083→### Configure tool search
  1084→
  1085→Tool search is enabled by default: MCP tools are deferred and discovered on demand. When `ANTHROPIC_BASE_URL` points to a non-first-party host, tool search is disabled by default because most proxies do not forward `tool_reference` blocks. Set `ENABLE_TOOL_SEARCH` explicitly if your proxy does. This feature requires models that support `tool_reference` blocks: Sonnet 4 and later, or Opus 4 and later. Haiku models do not support tool search.
  1086→
  1087→Control tool search behavior with the `ENABLE_TOOL_SEARCH` environment variable:
  1088→
  1089→| Value      | Behavior                                                                                                                       |
  1090→| :--------- | :----------------------------------------------------------------------------------------------------------------------------- |
  1091→| (unset)    | All MCP tools deferred and loaded on demand. Falls back to loading upfront when `ANTHROPIC_BASE_URL` is a non-first-party host |
  1092→| `true`     | All MCP tools deferred, including for non-first-party `ANTHROPIC_BASE_URL`                                                     |
  1093→| `auto`     | Threshold mode: tools load upfront if they fit within 10% of the context window, deferred otherwise                            |
  1094→| `auto:<N>` | Threshold mode with a custom percentage, where `<N>` is 0-100 (e.g., `auto:5` for 5%)                                          |
  1095→| `false`    | All MCP tools loaded upfront, no deferral                                                                                      |
  1096→
  1097→```bash  theme={null}
  1098→# Use a custom 5% threshold
  1099→ENABLE_TOOL_SEARCH=auto:5 claude
  1100→
  1101→# Disable tool search entirely
  1102→ENABLE_TOOL_SEARCH=false claude
  1103→```
  1104→
  1105→Or set the value in your [settings.json `env` field](/en/settings#available-settings).
  1106→
  1107→You can also disable the MCPSearch tool specifically using the `disallowedTools` setting:
  1108→
  1109→```json  theme={null}
  1110→{
  1111→  "permissions": {
  1112→    "deny": ["MCPSearch"]
  1113→  }
  1114→}
  1115→```
  1116→
  1117→## Use MCP prompts as commands
  1118→
  1119→MCP servers can expose prompts that become available as commands in Claude Code.
  1120→
  1121→### Execute MCP prompts
  1122→
  1123→<Steps>
  1124→  <Step title="Discover available prompts">
  1125→    Type `/` to see all available commands, including those from MCP servers. MCP prompts appear with the format `/mcp__servername__promptname`.
  1126→  </Step>
  1127→
  1128→  <Step title="Execute a prompt without arguments">
  1129→    ```text  theme={null}
  1130→    /mcp__github__list_prs
  1131→    ```
  1132→  </Step>
  1133→
  1134→  <Step title="Execute a prompt with arguments">
  1135→    Many prompts accept arguments. Pass them space-separated after the command:
  1136→
  1137→    ```text  theme={null}
  1138→    /mcp__github__pr_review 456
  1139→    ```
  1140→
  1141→    ```text  theme={null}
  1142→    /mcp__jira__create_issue "Bug in login flow" high
  1143→    ```
  1144→  </Step>
  1145→</Steps>
  1146→
  1147→<Tip>
  1148→  Tips:
  1149→
  1150→  * MCP prompts are dynamically discovered from connected servers
  1151→  * Arguments are parsed based on the prompt's defined parameters
  1152→  * Prompt results are injected directly into the conversation
  1153→  * Server and prompt names are normalized (spaces become underscores)
  1154→</Tip>
  1155→
  1156→## Managed MCP configuration
  1157→
  1158→For organizations that need centralized control over MCP servers, Claude Code supports two configuration options:
  1159→
  1160→1. **Exclusive control with `managed-mcp.json`**: Deploy a fixed set of MCP servers that users cannot modify or extend
  1161→2. **Policy-based control with allowlists/denylists**: Allow users to add their own servers, but restrict which ones are permitted
  1162→
  1163→These options allow IT administrators to:
  1164→
  1165→* **Control which MCP servers employees can access**: Deploy a standardized set of approved MCP servers across the organization
  1166→* **Prevent unauthorized MCP servers**: Restrict users from adding unapproved MCP servers
  1167→* **Disable MCP entirely**: Remove MCP functionality completely if needed
  1168→
  1169→### Option 1: Exclusive control with managed-mcp.json
  1170→
  1171→When you deploy a `managed-mcp.json` file, it takes **exclusive control** over all MCP servers. Users cannot add, modify, or use any MCP servers other than those defined in this file. This is the simplest approach for organizations that want complete control.
  1172→
  1173→System administrators deploy the configuration file to a system-wide directory:
  1174→
  1175→* macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
  1176→* Linux and WSL: `/etc/claude-code/managed-mcp.json`
  1177→* Windows: `C:\Program Files\ClaudeCode\managed-mcp.json`
  1178→
  1179→<Note>
  1180→  These are system-wide paths (not user home directories like `~/Library/...`) that require administrator privileges. They are designed to be deployed by IT administrators.
  1181→</Note>
  1182→
  1183→The `managed-mcp.json` file uses the same format as a standard `.mcp.json` file:
  1184→
  1185→```json  theme={null}
  1186→{
  1187→  "mcpServers": {
  1188→    "github": {
  1189→      "type": "http",
  1190→      "url": "https://api.githubcopilot.com/mcp/"
  1191→    },
  1192→    "sentry": {
  1193→      "type": "http",
  1194→      "url": "https://mcp.sentry.dev/mcp"
  1195→    },
  1196→    "company-internal": {
  1197→      "type": "stdio",
  1198→      "command": "/usr/local/bin/company-mcp-server",
  1199→      "args": ["--config", "/etc/company/mcp-config.json"],
  1200→      "env": {
  1201→        "COMPANY_API_URL": "https://internal.company.com"
  1202→      }
  1203→    }
  1204→  }
  1205→}
  1206→```
  1207→
  1208→### Option 2: Policy-based control with allowlists and denylists
  1209→
  1210→Instead of taking exclusive control, administrators can allow users to configure their own MCP servers while enforcing restrictions on which servers are permitted. This approach uses `allowedMcpServers` and `deniedMcpServers` in the [managed settings file](/en/settings#settings-files).
  1211→
  1212→<Note>
  1213→  **Choosing between options**: Use Option 1 (`managed-mcp.json`) when you want to deploy a fixed set of servers with no user customization. Use Option 2 (allowlists/denylists) when you want to allow users to add their own servers within policy constraints.
  1214→</Note>
  1215→
  1216→#### Restriction options
  1217→
  1218→Each entry in the allowlist or denylist can restrict servers in three ways:
  1219→
  1220→1. **By server name** (`serverName`): Matches the configured name of the server
  1221→2. **By command** (`serverCommand`): Matches the exact command and arguments used to start stdio servers
  1222→3. **By URL pattern** (`serverUrl`): Matches remote server URLs with wildcard support
  1223→
  1224→**Important**: Each entry must have exactly one of `serverName`, `serverCommand`, or `serverUrl`.
  1225→
  1226→#### Example configuration
  1227→
  1228→```json  theme={null}
  1229→{
  1230→  "allowedMcpServers": [
  1231→    // Allow by server name
  1232→    { "serverName": "github" },
  1233→    { "serverName": "sentry" },
  1234→
  1235→    // Allow by exact command (for stdio servers)
  1236→    { "serverCommand": ["npx", "-y", "@modelcontextprotocol/server-filesystem"] },
  1237→    { "serverCommand": ["python", "/usr/local/bin/approved-server.py"] },
  1238→
  1239→    // Allow by URL pattern (for remote servers)
  1240→    { "serverUrl": "https://mcp.company.com/*" },
  1241→    { "serverUrl": "https://*.internal.corp/*" }
  1242→  ],
  1243→  "deniedMcpServers": [
  1244→    // Block by server name
  1245→    { "serverName": "dangerous-server" },
  1246→
  1247→    // Block by exact command (for stdio servers)
  1248→    { "serverCommand": ["npx", "-y", "unapproved-package"] },
  1249→
  1250→    // Block by URL pattern (for remote servers)
  1251→    { "serverUrl": "https://*.untrusted.com/*" }
  1252→  ]
  1253→}
  1254→```
  1255→
  1256→#### How command-based restrictions work
  1257→
  1258→**Exact matching**:
  1259→
  1260→* Command arrays must match **exactly** - both the command and all arguments in the correct order
  1261→* Example: `["npx", "-y", "server"]` will NOT match `["npx", "server"]` or `["npx", "-y", "server", "--flag"]`
  1262→
  1263→**Stdio server behavior**:
  1264→
  1265→* When the allowlist contains **any** `serverCommand` entries, stdio servers **must** match one of those commands
  1266→* Stdio servers cannot pass by name alone when command restrictions are present
  1267→* This ensures administrators can enforce which commands are allowed to run
  1268→
  1269→**Non-stdio server behavior**:
  1270→
  1271→* Remote servers (HTTP, SSE, WebSocket) use URL-based matching when `serverUrl` entries exist in the allowlist
  1272→* If no URL entries exist, remote servers fall back to name-based matching
  1273→* Command restrictions do not apply to remote servers
  1274→
  1275→#### How URL-based restrictions work
  1276→
  1277→URL patterns support wildcards using `*` to match any sequence of characters. This is useful for allowing entire domains or subdomains.
  1278→
  1279→**Wildcard examples**:
  1280→
  1281→* `https://mcp.company.com/*` - Allow all paths on a specific domain
  1282→* `https://*.example.com/*` - Allow any subdomain of example.com
  1283→* `http://localhost:*/*` - Allow any port on localhost
  1284→
  1285→**Remote server behavior**:
  1286→
  1287→* When the allowlist contains **any** `serverUrl` entries, remote servers **must** match one of those URL patterns
  1288→* Remote servers cannot pass by name alone when URL restrictions are present
  1289→* This ensures administrators can enforce which remote endpoints are allowed
  1290→
  1291→<Accordion title="Example: URL-only allowlist">
  1292→  ```json  theme={null}
  1293→  {
  1294→    "allowedMcpServers": [
  1295→      { "serverUrl": "https://mcp.company.com/*" },
  1296→      { "serverUrl": "https://*.internal.corp/*" }
  1297→    ]
  1298→  }
  1299→  ```
  1300→
  1301→  **Result**:
  1302→
  1303→  * HTTP server at `https://mcp.company.com/api`: ✅ Allowed (matches URL pattern)
  1304→  * HTTP server at `https://api.internal.corp/mcp`: ✅ Allowed (matches wildcard subdomain)
  1305→  * HTTP server at `https://external.com/mcp`: ❌ Blocked (doesn't match any URL pattern)
  1306→  * Stdio server with any command: ❌ Blocked (no name or command entries to match)
  1307→</Accordion>
  1308→
  1309→<Accordion title="Example: Command-only allowlist">
  1310→  ```json  theme={null}
  1311→  {
  1312→    "allowedMcpServers": [
  1313→      { "serverCommand": ["npx", "-y", "approved-package"] }
  1314→    ]
  1315→  }
  1316→  ```
  1317→
  1318→  **Result**:
  1319→
  1320→  * Stdio server with `["npx", "-y", "approved-package"]`: ✅ Allowed (matches command)
  1321→  * Stdio server with `["node", "server.js"]`: ❌ Blocked (doesn't match command)
  1322→  * HTTP server named "my-api": ❌ Blocked (no name entries to match)
  1323→</Accordion>
  1324→
  1325→<Accordion title="Example: Mixed name and command allowlist">
  1326→  ```json  theme={null}
  1327→  {
  1328→    "allowedMcpServers": [
  1329→      { "serverName": "github" },
  1330→      { "serverCommand": ["npx", "-y", "approved-package"] }
  1331→    ]
  1332→  }
  1333→  ```
  1334→
  1335→  **Result**:
  1336→
  1337→  * Stdio server named "local-tool" with `["npx", "-y", "approved-package"]`: ✅ Allowed (matches command)
  1338→  * Stdio server named "local-tool" with `["node", "server.js"]`: ❌ Blocked (command entries exist but doesn't match)
  1339→  * Stdio server named "github" with `["node", "server.js"]`: ❌ Blocked (stdio servers must match commands when command entries exist)
  1340→  * HTTP server named "github": ✅ Allowed (matches name)
  1341→  * HTTP server named "other-api": ❌ Blocked (name doesn't match)
  1342→</Accordion>
  1343→
  1344→<Accordion title="Example: Name-only allowlist">
  1345→  ```json  theme={null}
  1346→  {
  1347→    "allowedMcpServers": [
  1348→      { "serverName": "github" },
  1349→      { "serverName": "internal-tool" }
  1350→    ]
  1351→  }
  1352→  ```
  1353→
  1354→  **Result**:
  1355→
  1356→  * Stdio server named "github" with any command: ✅ Allowed (no command restrictions)
  1357→  * Stdio server named "internal-tool" with any command: ✅ Allowed (no command restrictions)
  1358→  * HTTP server named "github": ✅ Allowed (matches name)
  1359→  * Any server named "other": ❌ Blocked (name doesn't match)
  1360→</Accordion>
  1361→
  1362→#### Allowlist behavior (`allowedMcpServers`)
  1363→
  1364→* `undefined` (default): No restrictions - users can configure any MCP server
  1365→* Empty array `[]`: Complete lockdown - users cannot configure any MCP servers
  1366→* List of entries: Users can only configure servers that match by name, command, or URL pattern
  1367→
  1368→#### Denylist behavior (`deniedMcpServers`)
  1369→
  1370→* `undefined` (default): No servers are blocked
  1371→* Empty array `[]`: No servers are blocked
  1372→* List of entries: Specified servers are explicitly blocked across all scopes
  1373→
  1374→#### Important notes
  1375→
  1376→* **Option 1 and Option 2 can be combined**: If `managed-mcp.json` exists, it has exclusive control and users cannot add servers. Allowlists/denylists still apply to the managed servers themselves.
  1377→* **Denylist takes absolute precedence**: If a server matches a denylist entry (by name, command, or URL), it will be blocked even if it's on the allowlist
  1378→* Name-based, command-based, and URL-based restrictions work together: a server passes if it matches **either** a name entry, a command entry, or a URL pattern (unless blocked by denylist)
  1379→
  1380→<Note>
  1381→  **When using `managed-mcp.json`**: Users cannot add MCP servers through `claude mcp add` or configuration files. The `allowedMcpServers` and `deniedMcpServers` settings still apply to filter which managed servers are actually loaded.
  1382→</Note>
  1383→