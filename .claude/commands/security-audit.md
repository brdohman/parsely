---
description: Multi-agent security audit. 3 parallel reviewers + lead consolidator. Supports full, scope-based, pre-merge delta, or quick (static-only) modes. The sole security entry point.
argument-hint: [epic-id|scope|delta|quick] — e.g., "epic-42", "auth", "all", "delta", "quick"
---

# /security-audit

Orchestrates a 4-agent security architecture: 3 parallel specialist reviewers + 1 lead consolidator.

> For workflow state fields and comment format: see `.claude/docs/WORKFLOW-STATE.md`

## Modes

| Argument | Mode | Description |
|----------|------|-------------|
| `[epic-id]` or `[task-id]` | Full audit | All code in that item's scope reviewed by 3 agents |
| `auth`, `api`, `all` | Scope-based | Audit specific area of the codebase |
| `delta` | Pre-merge delta | Only security-sensitive changed files (fast path) |
| `quick` | Quick (static-only) | Runs only the security-static agent + Aikido. No reasoning or platform agents. Use for single-file changes or lightweight checks. |

## Review Cycle Position

```
macOS Dev -> Code Review -> QA -> Security Audit -> Product Review -> Closed
                                  [YOU ARE HERE]
                                       |
                                Handoff to PM
```

**Receives from:** QA Agent (via `review_stage: "security"`, `review_result: "awaiting"`)
**Handoff to:** PM Agent (via `review_stage: "product-review"`, `review_result: "awaiting"`)
**On rejection:** Back to macOS Dev (via `review_result: "rejected"`)

## Flow

### Step 1: Determine Mode

```
IF arg matches an epic-id or task-id:
  TaskGet [id] → extract scope (changed files from implementation comments)
  MODE = "full"

ELSE IF arg is "auth", "api", "all":
  Scope = codebase area matching keyword
  MODE = "full"

ELSE IF arg is "delta":
  MODE = "delta"

ELSE:
  Show queue: TaskList -> filter metadata.review_stage == "security" AND metadata.review_result == "awaiting"
  Display items awaiting security review. Prompt to run /security-audit [id].
```

### Step 2 (Full Audit): Spawn 3 Parallel Reviewers

Spawn all 3 from the coordinator in parallel:

```
Task(subagent_type="security", name="security-static", model="sonnet",
  "STATIC ANALYSIS REVIEW for [scope].

  Review all Swift files in scope for:
  - Hardcoded secrets (API keys, tokens, passwords in source)
  - Force unwraps on security-sensitive paths
  - Insecure randomness (arc4random instead of SecRandomCopyBytes)
  - Insecure hashing (MD5/SHA1 for security purposes)
  - SQL injection, format string vulnerabilities
  - Logging of sensitive data (print/os_log with credentials)

  Write a SECURITY-STATIC REPORT comment on epic [epic-id].
  Comment type: 'review'. Author: 'security-static-agent'.
  List findings with severity (Critical/High/Medium/Low) and file paths.
  Final response under 200 characters: 'DONE: X findings' or 'DONE: CLEAR'.")

Task(subagent_type="security", name="security-reasoning", model="opus",
  "SECURITY REASONING REVIEW for [scope].

  Deep analysis of:
  - Authentication/authorization logic correctness
  - Session management and token lifecycle
  - Race conditions in security-critical paths
  - Business logic bypass opportunities
  - Trust boundary violations (client vs server validation)
  - Privilege escalation paths

  Write a SECURITY-REASONING REPORT comment on epic [epic-id].
  Comment type: 'review'. Author: 'security-reasoning-agent'.
  List findings with severity and detailed exploitation scenario.
  Final response under 200 characters: 'DONE: X findings' or 'DONE: CLEAR'.")

Task(subagent_type="security", name="security-platform", model="sonnet",
  "PLATFORM SECURITY REVIEW for [scope].

  Review macOS/Apple platform security:
  - Keychain usage (SecItem API, not UserDefaults for secrets)
  - App Sandbox entitlements (minimal permissions)
  - App Transport Security (ATS) configuration
  - File protection attributes
  - Privacy manifest (xcprivacy) accuracy
  - Network security (certificate pinning, HTTPS enforcement)
  - Core Data encryption if sensitive data stored

  Write a SECURITY-PLATFORM REPORT comment on epic [epic-id].
  Comment type: 'review'. Author: 'security-platform-agent'.
  List findings with severity and Apple documentation references.
  Final response under 200 characters: 'DONE: X findings' or 'DONE: CLEAR'.")
```

Wait for all 3 to complete.

### Step 2b (Full Audit): Run 3rd-Party Scans

After sub-agents complete, run Aikido and Trivy scans from the coordinator:

**Aikido full project scan:**
```
Run aikido_full_scan via MCP on the full project source directory.
Scope: all Swift files in app/[AppName]/ (not just changed files — this is the epic-level deep scan).
Pass the results to the lead consolidator agent in the spawn prompt.
If Aikido MCP is unavailable, note "Aikido full scan skipped — MCP unavailable" and continue.

⛔ SAVE OUTPUT: echo "<full aikido output>" | .claude/scripts/save-review.sh aikido
```

**Trivy filesystem vulnerability scan:**
```
Run scan_filesystem via Trivy MCP:
  target: app project root (absolute path)
  scanType: ["vuln", "secret", "license"]
  severities: ["CRITICAL", "HIGH", "MEDIUM"]
  outputFormat: "json"

Pass findings summary to the lead consolidator agent.
If Trivy MCP is unavailable, note "Trivy scan skipped — MCP unavailable" and continue.

⛔ SAVE OUTPUT: echo "<full trivy output>" | .claude/scripts/save-review.sh trivy
```

**Trivy SBOM generation:**
```
Run scan_filesystem via Trivy MCP:
  target: app project root (absolute path)
  scanType: ["vuln"]
  outputFormat: "cyclonedx"

Save SBOM output. This is an artifact for supply chain tracking, not a pass/fail gate.
If Trivy MCP is unavailable, skip SBOM generation.
```

### Step 2 (Delta): Pre-Merge Delta Check

```bash
git diff --name-only main...HEAD | .claude/scripts/security-scope.sh
```

**If output is `CLEAR`:**
```
Output: "No security-sensitive files changed. CLEAR to merge."
Done — no agents needed.
```

**If output is `SECURITY_REVIEW_REQUIRED`:**

Spawn 2 agents (reasoning skipped for delta — no deep logic review needed):

```
Task(subagent_type="security", name="security-static", model="sonnet",
  "DELTA STATIC REVIEW. Only review these flagged files: [flagged file list].

  Write SECURITY-STATIC REPORT comment on epic [epic-id].
  Final response under 200 characters.")

Task(subagent_type="security", name="security-platform", model="sonnet",
  "DELTA PLATFORM REVIEW. Only review these flagged files: [flagged file list].
  Write SECURITY-PLATFORM REPORT comment on epic [epic-id].
  Final response under 200 characters.")
```

Wait for both to complete.

### Step 3: Spawn Lead Consolidator

```
Task(subagent_type="security", name="security-audit", model="sonnet",
  "CONSOLIDATE SECURITY REPORTS for epic [epic-id].

  1. TaskGet [epic-id] — read all report comments
  2. Find comments authored by security-static-agent, security-reasoning-agent, security-platform-agent
  3. Deduplicate findings (same issue reported by multiple reviewers)
  4. Assign final severity to each unique finding:
     - Critical: Exploitable vulnerability, data exposure
     - High: Security weakness requiring fix before release
     - Medium: Hardening improvement, defense-in-depth
     - Low: Best practice suggestion
  5. Make PASS/FAIL decision:
     - FAIL if any Critical or High findings
     - PASS if only Medium/Low (note them as recommendations)
  6. Write SECURITY AUDIT SUMMARY comment on epic [epic-id]
  7. Update workflow state (Step 4 below)

  Final response under 200 characters: 'PASS' or 'FAIL: X critical, Y high'.")
```

### Step 4: Lead Agent Updates Workflow State

The lead consolidator agent performs the TaskUpdate:

**PASS:**
```
TaskGet [id]   # read before write

TaskUpdate [id]
  metadata.review_stage: "product-review"
  metadata.review_result: "awaiting"
  metadata.last_updated_at: "[ISO8601]"
  metadata.comments: [...existing, {
    "id": "C[N]", "timestamp": "[ISO8601]", "author": "security-audit-agent", "type": "review",
    "content": "SECURITY AUDIT PASSED\n\n**Reviewers:** static, reasoning, platform\n**3rd-party tools:** Aikido=[ran/unavailable], Trivy=[ran/unavailable]\n**Findings:** [N] total ([breakdown by severity])\n\n**Aikido scan:** [clean / N findings]\n**Trivy scan:** [clean / N dependency CVEs]\n**Trivy SBOM:** [generated / skipped]\n\n**Recommendations (non-blocking):**\n- [Medium/Low items]\n\n**Decision:** PASS — no critical or high severity findings.\n\nHandoff: PM Agent will perform final review via /product-review"
  }]
```

**FAIL:**
```
TaskGet [id]   # read before write

TaskUpdate [id]
  metadata.review_stage: "security"
  metadata.review_result: "rejected"
  metadata.last_updated_at: "[ISO8601]"
  metadata.comments: [...existing, {
    "id": "C[N]", "timestamp": "[ISO8601]", "author": "security-audit-agent", "type": "rejection",
    "content": "REJECTED - SECURITY AUDIT\n\n**Reviewers:** static, reasoning, platform\n**3rd-party tools:** Aikido=[ran/unavailable], Trivy=[ran/unavailable]\n**Findings:** [N] total ([breakdown by severity])\n\n**Aikido scan:** [N findings — breakdown]\n**Trivy scan:** [N dependency CVEs — breakdown]\n\n**Critical/High issues (blocking):**\n1. [Severity]: [title] — [file] — [source: sub-agent or tool] — [remediation]\n2. [Severity]: [title] — [file] — [source: sub-agent or tool] — [remediation]\n\n**Blocking bug tasks created:**\n- [task-id]: [title]\n\n**Next action:** macOS Developer Agent to fix security issues and resubmit via /fix",
    "resolved": false, "resolved_by": null, "resolved_at": null
  }]
```

On FAIL, also create blocking bug tasks:
```
TaskCreate for each Critical/High finding:
  title: "SECURITY: [vulnerability title]"
  type: "bug"
  description: "[detailed description with file path, line, remediation]"
  parentId: [epic-id or story-id]
  metadata: {
    schema_version: "2.0",
    type: "bug",
    priority: "P0" (Critical) or "P1" (High),
    approval: "approved",
    blocked: false,
    labels: ["security"],
    comments: []
  }
```

## Security Checklist (Agent Reference)

### Static Analysis Focus
- [ ] No hardcoded secrets in source
- [ ] No force unwraps on security paths
- [ ] Secure randomness (SecRandomCopyBytes)
- [ ] No sensitive data in logs
- [ ] Input validation on all boundaries

### Reasoning Focus
- [ ] Auth/authz logic correct
- [ ] No business logic bypass
- [ ] Race condition free on security paths
- [ ] Trust boundaries enforced

### Platform Focus
- [ ] Keychain for all credentials (not UserDefaults)
- [ ] Minimal sandbox entitlements
- [ ] ATS enforced (no exceptions without justification)
- [ ] Privacy manifest accurate
- [ ] HTTPS enforced, certificate validation intact

## Field Reference

| Fields | Meaning | Your Action |
|--------|---------|-------------|
| `review_stage: "security"`, `review_result: "awaiting"` | Ready for audit | Run /security-audit [id] |
| `review_stage: "product-review"`, `review_result: "awaiting"` | Passed to PM | Lead sets this on PASS |
| `review_stage: "security"`, `review_result: "rejected"` | Back to dev | Lead sets this on FAIL |

## Task Tool Reference

```
# Find items awaiting security audit
TaskList -> filter:
  - metadata.review_stage == "security" AND metadata.review_result == "awaiting"

# Get item details
TaskGet [id]

# PASS — route to product review
TaskUpdate [id]
  - Set metadata.review_stage to "product-review"
  - Set metadata.review_result to "awaiting"
  - Add review comment to metadata.comments

# FAIL — reject at security stage
TaskUpdate [id]
  - Keep metadata.review_stage as "security"
  - Set metadata.review_result to "rejected"
  - Add rejection comment to metadata.comments
  - Create blocking bug tasks for Critical/High findings
```
