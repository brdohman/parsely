---
name: spawn-subagents
description: "Guidelines for spawning subagents to maintain clean context. Use for research tasks, parallel coding, verification, or any work benefiting from isolated context. Patterns by agent type."
allowed-tools: [Task]
---

# Subagent Delegation Rules

## Core Principle

**Use subagents liberally.** They provide:
- Clean context windows (no accumulated noise)
- Parallel execution (multiple tasks simultaneously)
- Specialization (focused expertise per task)
- Failure isolation (one failure doesn't lose other work)

---

## When to Spawn Subagents

### Always Spawn Subagents For:

| Task Type | Why |
|-----------|-----|
| **Research/Exploration** | Keeps main context clean for decisions |
| **Code Generation** (ViewModel, View, Service) | Each component gets focused context |
| **Test Writing** | Separate concern from implementation |
| **Documentation** | Don't pollute impl context with docs |
| **Verification/Validation** | Clean run of tests, linting |
| **File Searches** | Grep/Glob across codebase |
| **External Reviews** | Claude review alongside Gemini/OpenCode |

### Keep in Main Context:

| Task Type | Why |
|-----------|-----|
| **Coordination** | Need full picture to orchestrate |
| **Integration Decisions** | Must see how pieces fit together |
| **User Communication** | Context of conversation |
| **Final Assembly** | Combining subagent outputs |

---

## Subagent Invocation Patterns

### Pattern 1: "Use Subagents" Suffix

Append to any prompt for automatic delegation:

```
Refactor the authentication module. Use subagents.
```

Claude will spawn child agents for subtasks automatically.

### Pattern 2: Explicit Task Agent

Use the Task tool with specific agent types:

```
Task tool:
  subagent_type: "macos-developer"
  prompt: "Implement the LoginViewModel with these requirements..."
```

### Pattern 3: Parallel Background Tasks

For independent work, run multiple subagents simultaneously:

```
# All three run in parallel
Task 1: subagent_type: "macos-developer", run_in_background: true
  → Implement ViewModel

Task 2: subagent_type: "macos-developer", run_in_background: true
  → Implement View

Task 3: subagent_type: "qa", run_in_background: true
  → Write test plan
```

---

## Agent-Specific Subagent Usage

### macOS Developer Agent

When implementing a feature, spawn subagents for:

```
Main Agent (Coordinator)
├── Subagent 1: Research existing patterns in codebase
├── Subagent 2: Implement ViewModel
├── Subagent 3: Implement View (after ViewModel)
├── Subagent 4: Implement Service (if needed)
└── Subagent 5: Write unit tests
```

**Coordination responsibilities:**
- Decide component boundaries
- Review subagent outputs
- Integrate components
- Handle cross-cutting concerns

### Staff Engineer Agent

When reviewing code, spawn subagents for:

```
Main Agent (Reviewer)
├── Subagent 1: Check architecture compliance
├── Subagent 2: Check Swift best practices
├── Subagent 3: Check test coverage
└── Subagent 4: Check security concerns
```

### QA Agent

When testing, spawn subagents for:

```
Main Agent (Test Coordinator)
├── Subagent 1: Verify acceptance criteria 1-3
├── Subagent 2: Verify acceptance criteria 4-6
├── Subagent 3: Run edge case tests
└── Subagent 4: Run regression tests
```

### Planning Agent

When creating epics, spawn subagents for:

```
Main Agent (Planner)
├── Subagent 1: Analyze PRD.md
├── Subagent 2: Analyze TECHNICAL_SPEC.md
├── Subagent 3: Analyze IMPLEMENTATION_GUIDE.md
└── Main: Synthesize into epic
```

---

## Context Window Hygiene

### Problem
Long conversations accumulate context. By turn 50+, the context window is full of:
- Old file reads (now stale)
- Previous attempts (superseded)
- Research tangents (no longer relevant)

### Solution
Spawn subagents for discrete tasks. Each subagent:
- Starts with clean context
- Returns only the relevant output
- Doesn't pollute main context with internals

### Example

**Without subagents (bad):**
```
Turn 1: Read 10 files to understand codebase
Turn 2: Research patterns
Turn 3-10: Try implementation approach A (failed)
Turn 11-20: Try implementation approach B (failed)
Turn 21-30: Try implementation approach C (succeeded)
→ Context now full of failed attempts, stale file reads
```

**With subagents (good):**
```
Main Turn 1: Spawn research subagent
  Subagent: Read files, return summary
  → Main receives: 500 token summary (not 10 files)

Main Turn 2: Spawn impl subagent with approach A
  Subagent: Try approach A, fails
  → Main receives: "Approach A failed because X"

Main Turn 3: Spawn impl subagent with approach B
  Subagent: Try approach B, succeeds
  → Main receives: Files created, test results

→ Main context stays clean, only has summaries
```

---

## Subagent Output Handling

### Successful Subagent

```
1. Read the output
2. Verify it meets requirements
3. Integrate into main work
4. Continue to next step
```

### Failed Subagent

```
1. Read the error/failure reason
2. Decide: retry with different approach, or escalate
3. If retry: spawn new subagent with adjusted prompt
4. If escalate: report to user
```

### Timeout/Hung Subagent

```
1. Check if output file has partial results
2. Use what's available
3. Spawn replacement for remaining work
4. Note the issue in task comments
```

---

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Do everything in main context | Spawn subagents for discrete tasks |
| Spawn one giant subagent | Break into multiple focused subagents |
| Ignore subagent failures | Handle failures, retry or escalate |
| Duplicate work across subagents | Define clear boundaries |
| Wait sequentially for parallel tasks | Use `run_in_background: true` |

---

## Performance Tips

1. **Batch independent subagents** - Spawn all at once, wait for all
2. **Use background mode** - `run_in_background: true` for slow tasks
3. **Right-size the task** - Not too big (slow), not too small (overhead)
4. **Specify model when appropriate** - Use `model: "haiku"` for simple tasks
5. **Include output format** - Tell subagent exactly what to return

---

## Integration with Existing Agents

All agents defined in `.claude/agents/` can be used as subagent types:

| Agent | subagent_type |
|-------|---------------|
| macOS Developer | `macos-developer` |
| Staff Engineer | `techlead` |
| QA | `qa` |
| PM | `pm` |
| Build Engineer | `build-engineer` |
| Security | `security` |
| Designer | `designer-agent` |
| Data Architect | `data-architect-agent` |
| Planning | `planning` |

**Example:**
```
Task tool:
  subagent_type: "macos-developer"
  prompt: "Implement the ProfileView according to the design spec..."
```
