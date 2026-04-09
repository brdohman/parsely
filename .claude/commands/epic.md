---
description: Create a comprehensive epic from planning documents. Delegates to Planning Agent.
argument-hint: phase name (e.g., "phase-1", "foundation") - optional, auto-detects if omitted
---

# /epic Command

Create a comprehensive epic from planning documents with PM and Staff Engineer review phases.

## Signature

```
/epic [phase-name]
```

**Arguments:**
- `phase-name` (optional): Specific phase to plan (e.g., "foundation", "phase-1")
- If omitted: Auto-detect next unplanned phase from `planning/progress.md`

---

## Recommended: Run External Review First

For complex epics, run multi-model review before creating the epic:

```
/external-review → /epic
```

This runs Claude, Gemini, and OpenCode reviews in parallel, synthesizes feedback. The Planning Agent reads `synthesis.md` and incorporates feedback into its Q&A and epic creation.

**Decision persistence:** The Planning Agent writes all Q&A decisions to `planning/reviews/decisions.md`. Future `/epic` runs read this file and skip already-answered questions.

---

## Coordinator Hard Rules

```
⛔ YOU ARE A LIGHTWEIGHT COORDINATOR. Your ONLY job is:
  1. Check if planning/reviews/decisions.md exists (one small Read)
  2. Spawn Planning Agent (Step 1) to read docs and return questions
  3. Fetch AskUserQuestion schema via ToolSearch, then present questions with it (NEVER as plain text)
  4. Spawn Planning Agent (Step 2) with user answers + prior decisions
  5. ⛔ MANDATORY: Spawn Designer Agent (Step 2.5) to create UX Flows (unless design_scope="no_design")
  6. Report the result

⛔ FORBIDDEN (for the coordinator):
  - NEVER read planning docs (PRD, TECHNICAL_SPEC, IMPLEMENTATION_GUIDE, etc.)
  - NEVER read templates (metadata-schema.md, epic.md, progress.md)
  - NEVER read source code or project files
  - NEVER use Grep/Glob to search the codebase

✅ ALLOWED reads:
  - planning/reviews/decisions.md (Pre-Step only, if it exists)

WHY: Planning docs are 300KB+. Reading them into coordinator context
leaves no room for the agent results and user Q&A.
```

---

## Two-Step Execution Flow

This command uses a two-phase approach for interactive UX:

### Pre-Step: Check for Prior Decisions

Check if a previous `/epic` run already captured decisions:

```
1. Check if planning/reviews/decisions.md exists
2. If exists:
   - Parse all answered questions
   - Extract decisions and their rationale
   - These will be used to skip duplicate questions in Step 1
   - Show: "Found X prior decisions. Will skip answered questions."
3. If not exists:
   - Proceed normally with all questions
```

### Step 1: Analyze and Generate Questions

```
Use Task tool with:
  subagent_type: "planning"
  prompt: "STEP 1 - ANALYZE AND RETURN QUESTIONS

  Target phase: [phase-name or 'auto-detect next phase']

  Prior decisions from previous /epic runs (if any):
  [Include contents of planning/reviews/decisions.md or 'None']

  1. Read all templates and planning documents
  2. Identify clarifying questions for PM Review and Staff Engineer Review
  3. SKIP any questions that were already answered in prior decisions
  4. Identify UX/design questions for Designer Review
  5. Return ONLY structured questions in the format below

  CRITICAL: Do NOT create the epic yet. Return questions for user input.
  CRITICAL: Do NOT ask questions already answered in decisions.md.

  Return format:
  ---QUESTIONS_START---
  {
    \"prior_decisions_used\": [
      { \"question\": \"Original question from synthesis\", \"decision\": \"What was decided\" }
    ],
    \"pm_questions\": [
      {
        \"id\": \"pm1\",
        \"question\": \"The full question text?\",
        \"header\": \"ShortName\",
        \"options\": [
          { \"label\": \"Option A (Recommended)\", \"description\": \"Why this is recommended...\" },
          { \"label\": \"Option B\", \"description\": \"Alternative approach...\" },
          { \"label\": \"Option C\", \"description\": \"Another option...\" }
        ]
      }
    ],
    \"tech_questions\": [
      {
        \"id\": \"tech1\",
        \"question\": \"Technical question text?\",
        \"header\": \"ShortName\",
        \"options\": [
          { \"label\": \"Option A (Recommended)\", \"description\": \"Why this is recommended...\" },
          { \"label\": \"Option B\", \"description\": \"Alternative approach...\" }
        ]
      }
    ],
    \"design_questions\": [
      {
        \"id\": \"design1\",
        \"question\": \"What are the critical user journeys for this epic?\",
        \"header\": \"Journeys\",
        \"options\": [
          { \"label\": \"Derive from PRD (Recommended)\", \"description\": \"Map PRD stories to flows\" },
          { \"label\": \"Custom journeys\", \"description\": \"Describe paths in your own words\" }
        ]
      }
    ],
    \"context\": {
      \"project_name\": \"...\",
      \"phase_name\": \"...\",
      \"phase_description\": \"...\"
    }
  }
  ---QUESTIONS_END---"
```

### After Step 1: Use AskUserQuestion

⛔ **MANDATORY: You MUST use the `AskUserQuestion` tool — do NOT present questions as plain text.**

Before presenting questions, fetch the tool schema:
```
ToolSearch({ query: "select:AskUserQuestion" })
```

Then parse the structured questions and use AskUserQuestion tool for each batch.

The AskUserQuestion tool provides:
- Interactive option selection with chips/tags
- Descriptions for each option
- Recommendations shown first with "(Recommended)" suffix
- "Other" option automatically added for custom input

Example AskUserQuestion call:
```
AskUserQuestion({
  questions: [
    {
      header: "Password",
      question: "What happens if the user forgets their password?",
      options: [
        { label: "Show warning during setup (Recommended)", description: "Inform users upfront that password cannot be recovered" },
        { label: "Allow data loss", description: "Accept that forgotten password means data is inaccessible" },
        { label: "Email recovery", description: "Implement email-based recovery (requires account system)" }
      ],
      multiSelect: false
    }
  ]
})
```

**Present PM questions first, then Staff Engineer questions, then Designer questions.** You can batch up to 4 questions per AskUserQuestion call.

### Step 2: Create Epic with Answers

```
Use Task tool with:
  subagent_type: "planning"
  prompt: "STEP 2 - CREATE EPIC WITH ANSWERS

  Target phase: [phase-name]

  Prior decisions from previous runs:
  [Include all prior_decisions_used from Step 1 response]

  User answers to new clarifying questions:
  [Include all question IDs and selected answers]

  pm1: [selected option or custom answer]
  pm2: [selected option or custom answer]
  tech1: [selected option or custom answer]
  ...

  Now complete the epic creation:
  1. Read UX Flows doc if referenced in planning docs (planning/[app-name]/UX_FLOWS.md)
  2. Fill complete epic skeleton with ALL 25+ fields
  3. Incorporate BOTH prior decisions AND new user answers
  4. Write/update planning/reviews/decisions.md with ALL decisions (prior + new)
     - Append new phase decisions, preserve existing ones
     - Format: phase header, then each Q with decision, rationale, source
  5. Add UX Flows metadata fields to epic:
     - ux_flows_ref: 'planning/[app]/UX_FLOWS.md' (path to UX Flows doc)
     - journeys: ['J1', 'J3'] (journey IDs from UX Flows that this epic touches)
     - screens: ['SCR-01', 'SCR-04'] (screen IDs from UX Flows that this epic touches)
     - design_scope: 'full_design|design_update|no_design' (classification for /build-epic Phase A)
     - design_phase_complete: false (auto-set to true for no_design)
  5. Stories array should be LIGHTWEIGHT OUTLINES only (title, description, rough points)
  6. Run validation checkpoint
  7. Create ONE epic via TaskCreate - this is the ONLY TaskCreate call
  8. Update progress.md
  9. Output summary and STOP - wait for user to review

  ⛔ DO NOT create Story or Task Claude Tasks. Only the epic.
  ⛔ DO NOT proceed to /write-stories-and-tasks. User will run that after reviewing.
  ⛔ DO NOT review the epic yourself. User reviews it."
```

### ⛔ MANDATORY: After Step 2 Returns, Execute Step 2.5

**Do NOT present results to the user yet.** The planning agent's Step 2 summary is an intermediate result. You MUST execute Step 2.5 before showing the final output. The only exception is `design_scope: "no_design"` — skip Step 2.5 and go directly to the summary.

### Step 2.5: Create Per-Epic UX Flows

After the planning agent creates the epic (Step 2), create the per-epic UX Flows doc:

1. **Read project-level UX Flows** if it exists:
   `planning/[app-name]/UX_FLOWS.md` (Level 0 skeleton from /discover)

2. **Create per-epic directory:**
   `mkdir -p planning/notes/[epic-name]/`

3. **Spawn Designer agent:**
   ```
   Use Agent tool with:
     subagent_type: "designer-agent"
     prompt: "CREATE PER-EPIC UX FLOWS

     Epic: [epic-id] — [epic title]
     Epic screens: [screens from epic metadata]
     Epic journeys: [journeys from epic metadata]
     Design scope: [design_scope from epic metadata]

     User's answers to design questions:
     [design1]: [answer]
     [design2]: [answer]
     ...

     Project-level UX Flows baseline (if exists):
     [path to planning/[app-name]/UX_FLOWS.md or 'none']

     Instructions:
     1. Read the UX Flows template at planning/templates/UX_FLOWS.md
     2. Read the project-level UX Flows as baseline context (if it exists)
     3. Create planning/notes/[epic-name]/ux-flows.md with Level 1 depth:
        - Section 1: Navigation map scoped to this epic's screens
        - Section 2: Journeys from user's answers + project baseline
        - Section 3: State machines for screens this epic builds
        - Section 4: Interaction specs for this epic's interactions
        - Section 5: Modal flows for this epic's modals
        - Section 6: Error states this epic must handle
        - Section 7: macOS conventions — mark applicable items
        - Section 8: Accessibility for this epic's screens
        - Section 9: Traceability — PRD refs only (story/task/test filled later)
     4. Sections for screens NOT in this epic: headers with 'Not in scope for this epic'

     Final response under 200 characters: path to created file."
   ```

4. **Update epic metadata with UX Flows path:**
   ```
   TaskGet [epic-id]
   TaskUpdate [epic-id]:
     metadata.ux_flows_ref: "planning/notes/[epic-name]/ux-flows.md"
   ```

5. **Skip Step 2.5 if:** `design_scope` is `"no_design"` (backend/refactoring/infra epics). Note: "UX Flows skipped — no_design scope."

---

## Cross-References

- **Planning Agent:** `.claude/agents/planning-agent.md` (full epic creation logic, metadata fields, validation)
- **Metadata Schema:** `.claude/templates/tasks/metadata-schema.md` (v2.0 field definitions)
- **Epic Template:** `.claude/templates/tasks/epic.md`
- **Workflow State:** `.claude/docs/WORKFLOW-STATE.md` (review stages, workflow fields)
