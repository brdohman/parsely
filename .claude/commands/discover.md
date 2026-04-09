---
description: Multi-phase, multi-agent product discovery. PM validates the problem, Discovery Agent builds specs, Staff Engineer + PM + QA review for gaps. Generates complete planning documents ready for /epic.
argument-hint: app or feature description (e.g., "a macOS personal finance cash flow projection app")
---

# /discover

Multi-agent product discovery and planning document generation.

## Overview

This command runs structured discovery across multiple phases using specialized agents. Different agents bring different perspectives — PM validates the product, Discovery Agent builds specs, then Staff Engineer, PM, and QA review for technical risks, scope issues, and edge cases.

**Philosophy:** Surfaces first, plumbing last. See `.claude/docs/PLANNING-PROCESS.md`.

**Agents involved:**
- **PM Agent** — problem validation, product questions, scope prioritization
- **Discovery Agent** — UI, data, technical, and integration discovery
- **Staff Engineer** — technical risk assessment and feasibility review
- **QA perspective** — edge cases, failure modes, testability review

---

## Pre-Flight (Coordinator runs directly)

### 1. Collect User-Provided Specs

```
Scan the project root for any user-provided specs, mockups, or reference docs.
Common locations: initial-specs/, specs/, docs/, or loose files in the root (PDFs, PNGs, etc.).

If found:
  1. Create planning/specs/ if it doesn't exist
  2. Move all spec files there: mv <source>/* planning/specs/
  3. Remove the now-empty source directory
  4. Tell the user: "Moved your specs to planning/specs/ — I'll reference them during discovery."

If the files are already in planning/specs/, skip the move.
```

### 2. Check for Existing Docs

```
Scan planning/docs/ for any existing planning documents.
If found, present them and ask: "Should I use these as a starting point, or start fresh?"
```

### 3. Read Project Config

Read `CLAUDE.md` for tech stack and project standards.

### 4. Create Output Directory

```bash
mkdir -p planning/docs
```

---

## Phase 0: Problem Validation Gate (Coordinator)

Before spawning any agents, ask the user via AskUserQuestion:

```json
{
  "question": "Have you already validated the problem space for this product? (user research, competitive analysis, target audience defined)",
  "options": [
    {
      "label": "Yes — problem is validated",
      "description": "I've done research, talked to users, or have clear evidence the problem exists. Skip to product discovery."
    },
    {
      "label": "Partially — I have ideas but haven't validated",
      "description": "I have a concept but haven't done formal research. Run a quick validation pass."
    },
    {
      "label": "No — start from scratch",
      "description": "I have a rough idea. Help me validate the problem before defining the product."
    }
  ]
}
```

**If "Yes":** Skip to Phase 1.

**If "Partially" or "No":** Spawn PM Agent for problem validation:

```
subagent_type: "pm"
model: "opus", mode: "bypassPermissions"
prompt: "PROBLEM VALIDATION for [app/feature description].

  Read any user-provided specs in planning/specs/ for context.

  Ask the user these questions ONE AT A TIME using AskUserQuestion (never batch as text):

  1. What problem does this solve? Who experiences it?
  2. How do people solve this problem today? What's painful about current solutions?
  3. Who are the specific target users? (Be concrete — not 'everyone')
  4. What evidence do you have that this problem matters? (personal experience, user feedback, market data)
  5. What's the 'job to be done' — what outcome are users hiring this product to achieve?
  6. Who are the competitors? What do they get wrong?
  7. What's your unfair advantage or unique angle?

  After gathering answers, write a brief problem validation summary to planning/docs/PROBLEM_VALIDATION.md:
  - Problem statement (1-2 sentences)
  - Target user profile
  - Current alternatives and their gaps
  - Evidence supporting the problem
  - Jobs to be done
  - Competitive landscape
  - Unique angle

  Ask the user to confirm the summary via AskUserQuestion before finishing.
  Return: VALIDATED or NEEDS_WORK"
```

If NEEDS_WORK, report what's unclear and ask the user to provide more context before proceeding.

---

## Phase 1: Product Discovery (PM Agent)

The PM Agent owns the "why" and "what" — product requirements, scope, success metrics.

```
subagent_type: "pm"
model: "opus", mode: "bypassPermissions"
prompt: "PRODUCT DISCOVERY for [app/feature description].

  Read these files for context:
  - All files in planning/specs/ (user-provided specs — PRIMARY INPUT)
  - planning/docs/PROBLEM_VALIDATION.md (if exists)
  - CLAUDE.md (tech stack)
  - planning/templates/PRD-TEMPLATE.md (output template)

  Where specs clearly answer a question, state the answer and ask the user to confirm
  rather than asking from scratch. Reduce redundant questions.

  Ask questions ONE AT A TIME using AskUserQuestion:

  Product & Users:
  - What are the 3-5 core things a user should be able to do?
  - Walk me through a typical session (open app → ... → close app)
  - What's the 'aha moment' — when does the app first deliver value?

  Scope:
  - What is explicitly NOT in scope for v1?
  - Features you want eventually but not now?
  - Hard constraints? (platform, distribution, pricing, timeline)

  Success:
  - How will you know the app is working well?
  - What does 'done' look like for v1?

  Prioritization — for each feature mentioned, classify as:
  - P0 Must Have: App is unusable without this
  - P1 Should Have: Important but has workaround
  - P2 Nice to Have: Enhances experience
  - Deferred: Explicitly not v1

  Present the prioritization table and ask user to confirm via AskUserQuestion.

  Generate planning/docs/PRD.md from the PRD-TEMPLATE.
  Ask user to review via AskUserQuestion: 'Does this PRD capture your vision? Any changes?'

  Return: PRD_COMPLETE or PRD_NEEDS_REVISION"
```

---

## Phase 2: UI & UX Discovery (Discovery Agent)

The Discovery Agent handles visual design, screens, interactions, and UX flows.

```
subagent_type: "discovery"
model: "opus", mode: "bypassPermissions"
prompt: "UI & UX DISCOVERY for [app/feature description].

  Read these files:
  - All files in planning/specs/ (mockups, wireframes — PRIMARY INPUT for UI)
  - planning/docs/PRD.md (just generated)
  - CLAUDE.md (tech stack)
  - planning/templates/UI_SPEC-TEMPLATE.md

  Ask questions ONE AT A TIME using AskUserQuestion. Where mockups/specs answer
  a question, state what you see and ask user to confirm.

  Cover: screens, navigation, primary screen, design preferences, creative brief
  (personality, accent color, visual signature), interactions, keyboard shortcuts,
  macOS platform features, accessibility.

  Generate:
  1. planning/docs/UI_SPEC.md (from template)
  2. Populate creative brief in .claude/skills/design-system/frontend-design.md
  3. planning/[app-name]/UX_FLOWS.md (Level 0 skeleton: nav map, journey outlines,
     section headers only for 3-9)

  Ask user to review UI_SPEC via AskUserQuestion before finishing.
  Return: UI_COMPLETE"
```

---

## Phase 3: Data & Technical Discovery (Discovery Agent)

```
subagent_type: "discovery"
model: "opus", mode: "bypassPermissions"
prompt: "DATA & TECHNICAL DISCOVERY for [app/feature description].

  Read these files:
  - planning/docs/PRD.md
  - planning/docs/UI_SPEC.md
  - planning/specs/* (any data-related specs)
  - CLAUDE.md (tech stack)
  - planning/templates/DATA_SCHEMA-TEMPLATE.md
  - planning/templates/TECHNICAL_SPEC-TEMPLATE.md

  Ask questions ONE AT A TIME using AskUserQuestion.

  DATA (Phase 3):
  - Data models and relationships (derived from screens)
  - Storage approach, encryption needs
  - Default/seed data, sample data for development
  - Validation rules

  Generate planning/docs/DATA_SCHEMA.md. Ask user to review.

  TECHNICAL (Phase 4):
  - Confirm MVVM + @Observable from CLAUDE.md
  - Service protocol definitions
  - Mock implementation strategy
  - Error handling types, performance targets

  Generate planning/docs/TECHNICAL_SPEC.md. Ask user to review.

  INTEGRATION (Phase 5, conditional):
  - Only if PRD mentions external APIs/services
  - API reference, sync strategy, rate limiting, mock service
  - Generate planning/docs/[SERVICE]_INTEGRATION.md per service

  Return: SPECS_COMPLETE"
```

---

## Phase 4: Multi-Agent Expert Review (Parallel)

⛔ **This is what single-agent discovery misses.** Three perspectives review the draft specs for gaps, risks, and edge cases.

Spawn all three agents in the SAME message (parallel):

**Agent 1: Staff Engineer — Technical Risk Assessment**

```
subagent_type: "staff-engineer"
model: "sonnet", mode: "bypassPermissions"
prompt: "TECHNICAL RISK REVIEW of discovery specs.

  Read ALL docs in planning/docs/ (PRD, UI_SPEC, DATA_SCHEMA, TECHNICAL_SPEC, any integrations).
  Read CLAUDE.md for tech stack constraints.

  Review from a senior engineer's perspective. Write findings to
  planning/docs/REVIEW_TECHNICAL_RISKS.md:

  1. ARCHITECTURE RISKS — Are there structural decisions that will be hard to change later?
     (e.g., 'real-time sync for 12 users needs conflict resolution strategy not addressed')
  2. FEASIBILITY FLAGS — Anything that's harder than it sounds?
     (e.g., 'CloudKit has 5MB record limit — will that constrain attachments?')
  3. MISSING TECHNICAL DECISIONS — What needs to be decided before build?
     (e.g., 'No offline strategy defined — what happens without network?')
  4. COMPLEXITY ESTIMATE — Rough size (S/M/L/XL) with reasoning
  5. RECOMMENDED SPIKES — What should be prototyped before committing?

  Be adversarial. Find problems, don't confirm the plan.
  Return: [N] risks, [N] flags, [N] missing decisions"
```

**Agent 2: PM — Scope & Value Review**

```
subagent_type: "pm"
model: "sonnet", mode: "bypassPermissions"
prompt: "SCOPE & VALUE REVIEW of discovery specs.

  Read ALL docs in planning/docs/.

  Review from a PM's perspective. Write findings to
  planning/docs/REVIEW_SCOPE_VALUE.md:

  1. SCOPE CREEP CHECK — Is the v1 scope realistic? What should be cut?
  2. MVP VALIDATION — Can we ship something useful with just P0 features?
  3. SUCCESS METRICS GAP — Are the success criteria measurable and specific?
  4. USER JOURNEY GAPS — Any missing flows? (first-time experience, error recovery, onboarding)
  5. PRIORITIZATION CHALLENGE — Should any P1 be P0, or P0 be P1?
  6. COMPETITIVE BLIND SPOTS — Anything competitors do that we're ignoring?

  Be critical. Challenge assumptions, don't validate them.
  Return: [N] scope issues, [N] gaps, [N] reprioritizations"
```

**Agent 3: QA Perspective — Edge Cases & Testability**

```
subagent_type: "qa"
model: "sonnet", mode: "bypassPermissions"
prompt: "EDGE CASE & TESTABILITY REVIEW of discovery specs.

  Read ALL docs in planning/docs/.

  Review from a QA engineer's perspective. Write findings to
  planning/docs/REVIEW_EDGE_CASES.md:

  1. FAILURE MODES — For each feature in the PRD, what can go wrong?
     (network failure, concurrent access, invalid input, data corruption, full disk)
  2. MISSING ACCEPTANCE CRITERIA — What's underspecified?
     (e.g., 'What happens when user sends signal but recipient's app is closed?')
  3. TESTABILITY CONCERNS — What will be hard to test?
     (e.g., 'Real-time sync between devices — how do we test in CI?')
  4. EDGE CASES BY SCREEN — For each screen in UI_SPEC:
     - Empty state (no data)
     - Boundary values (max items, long text, special characters)
     - Rapid input / double-tap
     - Interrupted operations
  5. DATA EDGE CASES — Migration, corruption recovery, concurrent writes
  6. PLATFORM EDGE CASES — Permissions denied, low storage, background/foreground transitions

  Be thorough. Every 'what if?' you catch now saves a bug later.
  Return: [N] failure modes, [N] missing criteria, [N] testability concerns"
```

**After all three return:** Present a summary to the user:

```
"Expert review complete:

  Staff Engineer: [N] risks, [N] feasibility flags, [N] missing decisions
  PM:             [N] scope issues, [N] gaps, [N] reprioritizations
  QA:             [N] failure modes, [N] missing criteria, [N] testability concerns

  Review files saved to planning/docs/REVIEW_*.md

  Would you like to:
  (a) Review the findings and incorporate them into the specs
  (b) Proceed to implementation planning — I'll incorporate the findings automatically
  (c) Address specific findings first"
```

---

## Phase 5: Finalize & Generate Implementation Guide (Discovery Agent)

```
subagent_type: "discovery"
model: "opus", mode: "bypassPermissions"
prompt: "FINALIZE SPECS AND GENERATE IMPLEMENTATION GUIDE.

  Read ALL docs in planning/docs/ including the three REVIEW_*.md files.

  1. INCORPORATE REVIEW FINDINGS:
     - Update PRD.md with any scope/priority changes from PM review
     - Update TECHNICAL_SPEC.md with risk mitigations from Staff Engineer review
     - Update DATA_SCHEMA.md with edge cases from QA review
     - Add an 'Edge Cases & Failure Modes' section to PRD.md from QA findings
     - Add a 'Technical Risks' section to TECHNICAL_SPEC.md from Staff Engineer findings

  2. GENERATE IMPLEMENTATION GUIDE:
     Read planning/templates/IMPLEMENTATION_GUIDE-TEMPLATE.md.
     Ordering principle — surfaces first:
     1. Architecture skeleton + protocols + models
     2. Main layout + navigation (mock data)
     3. Core UI screens (mock data, with previews)
     4. Secondary UI screens (mock data)
     5. Polish + keyboard shortcuts
     6. Real database (unencrypted first)
     7. External integrations
     8. Security layer (encryption, keychain, login)
     9. Backup & export

     Include: phase dependency map, test tier architecture, critical path to MVP,
     recommended spikes from Staff Engineer review.

     Write to planning/docs/IMPLEMENTATION_GUIDE.md.

  Do NOT ask questions. This is a synthesis phase.
  Return: DISCOVERY_COMPLETE"
```

---

## After All Phases Complete

### Summary Output

```
Discovery complete! Generated planning documents:

  planning/docs/PROBLEM_VALIDATION.md     - Problem validation (if run)
  planning/docs/PRD.md                     - Product requirements
  planning/docs/UI_SPEC.md                - UI specification
  planning/[app-name]/UX_FLOWS.md         - UX Flows skeleton
  planning/docs/DATA_SCHEMA.md            - Data schema
  planning/docs/TECHNICAL_SPEC.md         - Technical architecture
  planning/docs/[SERVICE]_INTEGRATION.md  - Integration guide (if applicable)
  planning/docs/IMPLEMENTATION_GUIDE.md   - Implementation phases

  Expert reviews:
  planning/docs/REVIEW_TECHNICAL_RISKS.md - Staff Engineer risk assessment
  planning/docs/REVIEW_SCOPE_VALUE.md     - PM scope & value review
  planning/docs/REVIEW_EDGE_CASES.md      - QA edge case analysis

Next steps:
  1. Review the documents - edit anything that doesn't look right
  2. (Optional) Run /external-review for multi-model feedback
  3. Run /epic to create the first epic from these docs
  4. Run /approve-epic to approve the epic + stories + tasks
  5. Run /build-epic to start implementation
```

---

## Resuming Discovery

If context is cleared mid-discovery:

1. Check which docs already exist in `planning/docs/`
2. Read the existing docs to understand where we left off
3. Resume from the next phase that doesn't have a document yet

```
I see we've already completed:
  ✓ Phase 1: PRD.md exists
  ✓ Phase 2: UI_SPEC.md exists
  ✗ Phase 3: DATA_SCHEMA.md missing

Resuming from Phase 3: Data & Technical Discovery.
```

If REVIEW_*.md files don't exist but all specs do, resume from Phase 4 (Expert Review).

---

## Error Handling

### User Wants to Skip a Phase

Allow it, but warn about downstream impact:
```
"Skipping UI Discovery. Note: the Technical Spec and Implementation Guide
will be less specific about UI-related protocols and preview states."
```

### User Wants to Change a Previous Document

Allow it. Re-read the updated document before generating subsequent docs. If expert reviews already ran, note they may be stale.

### User Has Existing Planning Docs (Not Generated by /discover)

Read them and treat them as completed phases. Only run discovery for missing documents. Still run expert review (Phase 4) on all docs.

---

## Anti-Patterns

| DO NOT | DO INSTEAD |
|--------|-----------|
| Ask all questions from all phases at once | One phase at a time, focused questions |
| Dump questions as a text block | Use AskUserQuestion tool for EVERY question |
| Generate all docs without user review | Generate one doc, review, then next |
| Skip the expert review phase | It catches risks that single-agent discovery misses |
| Skip the preview strategy in UI spec | Every view needs defined preview states |
| Skip the mock service in tech spec | Protocols + mocks are the foundation |
| Put security in early implementation phases | Security wraps the finished app |
| Generate implementation guide before other docs | It synthesizes from all other docs |
| Use more than 8-10 questions per phase | Keep it focused; follow up if needed |
| Run expert review before specs are drafted | Review needs complete docs to be useful |
