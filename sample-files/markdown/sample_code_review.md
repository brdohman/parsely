# Code Review Findings — PR #42

**Review effort:** 3 (Moderate) | ~20 minutes

**Actionable comments posted:** 4 (inline, Critical severity)

---

## Summary

### Walkthrough

This PR adds comprehensive documentation and configuration, including a guide defining workflow terminology and lifecycle management, seventeen agent specifications with operational protocols, and forty-six command specifications detailing CLI workflows for task creation, building, code review, QA, and release processes. All files establish schema version 2.0 metadata standards, review-stage pipelines, and agent delegation patterns.

### Changes by Cohort

| Cohort / File(s) | Summary |
|---|---|
| **Core Documentation & Framework** `docs/HOW-TO.md` | Comprehensive guide defining workflow terminology, command-level build/review/QA cycles, metadata schema v2.0, structured comment templates, troubleshooting, and repository structure expectations. |
| **Agent Specifications - Implementation** `agents/developer.md`, `agents/build-engineer.md` | Agent configurations for developers and build engineers defining task lifecycle protocols, design-system loading requirements, screenshot validation, build verification gates, and code pattern standards. |
| **Agent Specifications - Quality & Review** `agents/qa.md`, `agents/staff-engineer.md`, `agents/docs.md` | Agents performing test-based QA validation against acceptance criteria, visual UX testing via state machine walkthroughs, code review orchestration, and documentation capture/audit. |
| **Agent Specifications - Security & Analysis** `agents/security-audit.md`, `agents/security-static.md` | Multi-agent security audit framework with static analysis, reasoning-based review, platform checks, root cause analysis for bugs, and technical research verification with source grounding. |
| **Command Specifications - Building** `commands/build.md`, `commands/build-story.md`, `commands/commit.md` | Commands orchestrating story implementation workflows with task claiming, code verification, multi-stage review pipelines (code review -> QA -> product review), and git committing. |
| **Command Specifications - Quality Gates** `commands/code-review.md`, `commands/qa.md`, `commands/product-review.md` | Commands for code review with static scanning, test-based QA validation, and product review with mandatory evidence. |

---

## Critical Findings

### Critical 1: Invalid lifecycle state value

- **File:** `agents/rca-agent.md`
- **Line:** 147
- **Severity:** Critical

**Finding:** `status: "investigating"` is not in the declared lifecycle. This state value conflicts with the documented progression used elsewhere (`pending`, `investigated`, `needs-more-info`, `reviewed`, `approved`) and can break workflow validation.

**Proposed fix:** Replace `"investigating"` with one of the declared lifecycle values (e.g., `"pending"` for initial state or `"investigated"` if this represents a completed investigation).

---

### Critical 2: Agent missing required capabilities

- **File:** `agents/ui-audit-agent.md`
- **Lines:** 1-9, also 157-174
- **Severity:** Critical

**Finding:** Pass 5 of the audit workflow is not executable with current configuration. The workflow requires screenshot tools and app launch/build, but the agent has no screenshot server configured and no shell access. As written, required visual verification cannot run.

**Proposed fix:** Either add the screenshot server and shell access to the agent configuration, or remove the visual verification actions from this agent.

---

### Critical 3: Read-only command writes to files

- **File:** `commands/evolve.md`
- **Lines:** 12, also 434-449
- **Severity:** Critical

**Finding:** The command is declared read-only and does not allow file writes, but Step 7 requires appending to `update-log.md`. In current form, this step is not executable and contradicts the command contract.

**Proposed fix:** Either:
1. Keep true read-only and remove Step 7 write, or
2. Explicitly allow writes and update the read-only statements to "analysis + log append only."

---

### Critical 4: Completion skips required review stage

- **File:** `commands/product-review.md`
- **Line:** 265
- **Severity:** Critical

**Finding:** Marking an item completed at product-review skips the required User Acceptance Testing stage. Product review should advance to the UAT stage, not final completion. Per the project's own learnings: "UAT is required before final merge."

**Proposed fix:** Change the transition so that when product review passes it advances to the UAT stage instead of marking as completed. Update the success message accordingly.

---

## Major Findings (8)

### Major 1: Tool permissions contradict read-only contract

- **File:** `agents/rca-agent.md`
- **Lines:** 4, also 220-221

Line 4 grants write access, while Lines 220-221 explicitly prohibit writing/editing source files. Remove write capability to enforce agent boundary safety.

---

### Major 2: Referenced dependency missing from configuration

- **File:** `agents/designer-agent.md`
- **Lines:** 5, also 18

Line 18 references `review-cycle`, but it is not declared in the dependencies list. Add it or remove the reference to avoid unresolved runtime errors.

---

### Major 3: Review fields applied to wrong item type

- **File:** `commands/ticket-update.md`
- **Lines:** 37, also 55-64

Line 37 defines a universal `completed` behavior that clears review fields, but certain item types should not carry review fields at all. This can introduce invalid metadata.

**Proposed fix:** Detect the item type and omit review field writes for items that don't support them.

---

### Major 4: Inconsistent project location assumptions

- **File:** `commands/setup.md`
- **Lines:** 24, also 73

Line 24 says the project is in the current directory, but Line 73 detects it under a subdirectory. This inconsistency can produce false negatives in setup detection.

---

### Major 5: Invalid shell syntax in code snippet

- **File:** `commands/setup.md`
- **Lines:** 122-129

Inside a `bash` block, Lines 127-128 use `//` comments, which are not valid in shell and will fail if copied literally.

**Proposed fix:**
```diff
-// Add linter configuration
-// Add ignore entries
+# Add linter configuration
+# Add ignore entries
```

---

### Major 6: Metadata not aligned to v2.0 schema

- **File:** `commands/design-review.md`
- **Lines:** 80-88

This template omits required workflow fields. Using this snippet can create items that fail later validation checks.

**Proposed fix:**
```diff
 metadata: {
-    type: "task",
-    labels: ["design"]
+    schema_version: "2.0",
+    type: "task",
+    approval: "pending",
+    blocked: false,
+    labels: ["design"]
 }
```

---

### Major 7: Dual writers for state updates (race condition)

- **File:** `commands/code-review.md`
- **Lines:** 154-158, also 206-254

Both the spawned agent and the coordinator are instructed to mutate the same state fields. Pick one owner (prefer coordinator) to avoid races and duplicate entries.

---

### Major 8: Loop termination condition can stall indefinitely

- **File:** `commands/build-workflow.md`
- **Lines:** 256-271, also 326-332

The loop waits for `status == "completed"`, but the review pass sets `result -> "passed"` (status is completed only later). This can keep the loop running after items have effectively passed.

**Proposed fix:**
```diff
-WHILE any item has status != "completed":
+WHILE any item has result != "passed":
```

---

## Minor/Suggestions (3)

### Minor 1: Nested fenced-code blocks break parsing

- **File:** `commands/context-prompt.md`
- **Lines:** 49-106

Triple-backtick markdown examples contain inner triple-backtick blocks, which breaks fence parsing.

**Proposed fix:** Use four-backtick fences for the outer blocks so inner triple-backtick fences remain valid.

---

### Minor 2: Inconsistent source path examples

- **File:** `commands/ui-polish.md`
- **Lines:** 229-230, also 249-250

Line 229 defines sources under `app/Views/`, but Lines 249-250 show `app/AppName/...`. Use one canonical path shape.

---

### Minor 3: Missing language identifiers on fenced code blocks

- **File:** `commands/workflow.md`
- **Lines:** 12-13, also 26-27, 38-39

Several code fences are missing language tags. Add language identifiers (e.g., `text`, `bash`) to satisfy linter rules.

---

## Finding Counts Summary

| Severity | Count |
|---|---|
| Critical (inline) | 4 |
| Major | 8 |
| Minor/Suggestions | 3 |
| **Total** | **15** |
