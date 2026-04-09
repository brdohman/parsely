---
description: Research a technical question using web sources. Returns verified findings with citations. Use for any technology, framework, or architectural decision that needs current information.
argument-hint: question or topic (e.g., "Is CloudKit the right choice for real-time sync between 12 iOS devices?")
---

# /research

Research a technical question and return verified, current findings with sources.

## Usage

```
/research Is CloudKit the right choice for real-time sync between 12 iOS devices?
/research What's the current SwiftData migration story? Any breaking changes since iOS 18?
/research Compare Alamofire vs URLSession for a modern iOS app
/research Is @Observable deprecated or changed in Swift 6?
```

## Delegation

Spawn the **Research Agent** (`.claude/agents/research-agent.md`):

```
subagent_type: "research"
model: "opus", mode: "bypassPermissions"
prompt: "RESEARCH: [user's question]

  Search the web for current, authoritative information.
  Follow your research methodology: identify domain → construct queries → evaluate sources → report with citations.

  For each finding:
  - Direct answer
  - Confidence level (HIGH/MEDIUM/LOW)
  - Sources with URLs and dates
  - Any caveats or version-specific notes

  If the question involves comparing options, present a comparison table.
  If the question involves verifying a claim, confirm or deny with evidence.

  Return structured findings. Keep response focused and actionable."
```

## When to Use

- Before making a technical decision you're unsure about
- When an agent's recommendation doesn't feel right
- When you want to verify something from a previous session
- When exploring a technology you haven't used before
- Anytime you think "is this still current?"

## Output

Findings are returned inline to the conversation. For persistent research that should survive across sessions, ask:

```
/research [question] — save findings to planning/research/
```
