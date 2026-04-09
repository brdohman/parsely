---
disable-model-invocation: true
description: Run multi-model external review of planning documents using Claude, Gemini, and OpenCode
argument-hint: "product" | "technical" | "both" (default: both)
---

# /external-review Command

Run parallel reviews of planning documents using multiple AI models to find gaps and issues before epic creation.

## Signature

```
/external-review [scope]
```

**Arguments:**
- `scope` (optional): What type of review to run
  - `product` - Product/UX focused review only
  - `technical` - Technical/architecture review only
  - `both` (default) - Run both product and technical reviews

---
disable-model-invocation: true

## Prerequisites

This command uses external CLI tools for multi-model review. Install before use:

| Tool | Install | Required? |
|-|-|-|
| Gemini CLI | `npm install -g @anthropic-ai/gemini-cli` or see Google docs | Optional |
| OpenCode CLI | `npm install -g opencode` or see project docs | Optional |

**Fallback:** If external CLIs are not available, the command runs Claude-only reviews (2 subagents instead of 6). You still get product + technical perspectives, just from one model.

## What This Command Does

1. **Runs up to 6 parallel reviews** (3 models x 2 perspectives):
   - Claude (subagent) - Product Review (always available)
   - Claude (subagent) - Technical Review (always available)
   - Gemini CLI - Product Review (if `gemini` CLI is installed)
   - Gemini CLI - Technical Review (if `gemini` CLI is installed)
   - OpenCode CLI (glm-4.7) - Product Review (if `opencode` CLI is installed)
   - OpenCode CLI (glm-4.7) - Technical Review (if `opencode` CLI is installed)

2. **Outputs to `planning/reviews/`**:
   ```
   planning/reviews/
   ├── claude-product-review.md
   ├── claude-technical-review.md
   ├── gemini-product-review.md
   ├── gemini-technical-review.md
   ├── opencode-product-review.md
   ├── opencode-technical-review.md
   └── synthesis.md          # Combined analysis
   ```

3. **Synthesizes all feedback** into prioritized recommendations

---
disable-model-invocation: true

## Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Verify Prerequisites                                │
│ - Check planning docs exist (PRD, TECHNICAL_SPEC, etc.)     │
│ - Check gemini CLI available                                │
│ - Check opencode CLI available                              │
│ - Create planning/reviews/ directory                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Launch Parallel Reviews                             │
│                                                             │
│ Run in parallel (background):                               │
│                                                             │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│ │   Claude    │  │   Gemini    │  │  OpenCode   │          │
│ │  (subagent) │  │    (CLI)    │  │   (CLI)     │          │
│ ├─────────────┤  ├─────────────┤  ├─────────────┤          │
│ │ Product     │  │ Product     │  │ Product     │          │
│ │ Technical   │  │ Technical   │  │ Technical   │          │
│ └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                             │
│ Timeout: 8 minutes for OpenCode, 2 minutes for others      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Wait for Completion                                 │
│ - Poll for file existence                                   │
│ - Max wait: 10 minutes total                                │
│ - Continue if any model times out (partial results OK)      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: Synthesize Reviews                                  │
│ - Read all review files                                     │
│ - Identify common concerns (HIGH priority)                  │
│ - Identify unique concerns (evaluate individually)          │
│ - Categorize by: Must Fix, Should Fix, Consider             │
│ - Output to planning/reviews/synthesis.md                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: Output Summary                                      │
│ - Show count of issues by priority                          │
│ - List top 5 concerns                                       │
│ - Recommend next steps                                      │
└─────────────────────────────────────────────────────────────┘
```

---
disable-model-invocation: true

## Implementation

### Step 1: Prerequisites Check

```bash
# Verify planning docs directory exists and has files
ls planning/docs/*.md planning/docs/*.jsx 2>/dev/null || ls planning/docs/*

# Verify CLIs available
which gemini
which opencode

# Create reviews directory
mkdir -p planning/reviews
```

**Note:** All planning documents should be in `planning/docs/`. This includes:
- PRD.md, TECHNICAL_SPEC.md, IMPLEMENTATION_GUIDE.md (standard)
- DATA_SCHEMA.md, UI_SPEC.md (optional)
- Integration specs, prototypes, etc.

### Step 2: Run Reviews in Parallel

**Gemini Reviews (fast, ~30 seconds each):**

```bash
# Product Review
gemini -p "$(cat .claude/templates/external-review-prompts.md | sed -n '/## Product Review Prompt/,/## Technical Review Prompt/p' | head -n -1)

PLANNING DOCUMENTS:
$(cat planning/docs/*.md planning/docs/*.jsx 2>/dev/null)" \
> planning/reviews/gemini-product-review.md &

# Technical Review
gemini -p "$(cat .claude/templates/external-review-prompts.md | sed -n '/## Technical Review Prompt/,/## Synthesis Prompt/p' | head -n -1)

PLANNING DOCUMENTS:
$(cat planning/docs/*.md planning/docs/*.jsx 2>/dev/null)" \
> planning/reviews/gemini-technical-review.md &
```

**OpenCode Reviews (slow, ~2-5 minutes each):**

```bash
# Product Review
cat planning/docs/*.md planning/docs/*.jsx 2>/dev/null \
| opencode run --model zai-coding-plan/glm-4.7 \
"You are a Head of Product reviewing planning documents for a macOS app.

Review for:
1. Missing user scenarios or edge cases
2. Unclear acceptance criteria
3. UX gaps or friction points
4. Requirements that conflict with each other
5. Features that need more definition
6. Success metrics that are missing or unmeasurable

Be the users advocate. Find gaps. Be critical.

Output as markdown with these sections:
## Critical Issues (Must Fix)
## Major Concerns (Should Fix)
## Minor Suggestions (Consider)
## Questions for Clarification" \
> planning/reviews/opencode-product-review.md &

# Technical Review
cat planning/docs/*.md planning/docs/*.jsx 2>/dev/null \
| opencode run --model zai-coding-plan/glm-4.7 \
"You are a Principal Engineer reviewing planning documents for a macOS app.

Review for:
1. Architectural gaps or risks
2. Missing technical requirements
3. Unclear implementation details
4. Security concerns
5. Scalability issues
6. Dependencies that could cause problems

Be skeptical. Find problems. Be critical.

Output as markdown with these sections:
## Critical Issues (Must Fix)
## Major Concerns (Should Fix)
## Minor Suggestions (Consider)
## Questions for Clarification" \
> planning/reviews/opencode-technical-review.md &
```

**Claude Reviews (via subagent):**

```
Use Task tool with:
  subagent_type: "general-purpose"
  run_in_background: true
  prompt: "PRODUCT REVIEW - Head of Product Perspective

  Read ALL planning documents in planning/docs/:
  - Use Glob to find: planning/docs/*.md and planning/docs/*.jsx
  - Read each file found

  Review for:
  1. Missing user scenarios or edge cases
  2. Unclear acceptance criteria
  3. UX gaps or friction points
  4. Requirements that conflict
  5. Features needing more definition
  6. Missing/unmeasurable success metrics

  Be critical. Find gaps.

  Write output to: planning/reviews/claude-product-review.md

  Use this format:
  ## Critical Issues (Must Fix)
  ## Major Concerns (Should Fix)
  ## Minor Suggestions (Consider)
  ## Questions for Clarification"
```

```
Use Task tool with:
  subagent_type: "general-purpose"
  run_in_background: true
  prompt: "TECHNICAL REVIEW - Principal Engineer Perspective

  Read ALL planning documents in planning/docs/:
  - Use Glob to find: planning/docs/*.md and planning/docs/*.jsx
  - Read each file found

  Review for:
  1. Architectural gaps or risks
  2. Missing technical requirements
  3. Unclear implementation details
  4. Security concerns
  5. Scalability issues
  6. Problematic dependencies

  Be skeptical. Find problems.

  Write output to: planning/reviews/claude-technical-review.md

  Use this format:
  ## Critical Issues (Must Fix)
  ## Major Concerns (Should Fix)
  ## Minor Suggestions (Consider)
  ## Questions for Clarification"
```

### Step 3: Wait for Completion

```bash
# Wait for all background jobs
wait

# Or poll for files (if using Task agents)
# Check every 30 seconds for up to 10 minutes
```

### Step 4: Synthesize Reviews

```
Use Task tool with:
  subagent_type: "techlead"
  prompt: "SYNTHESIZE EXTERNAL REVIEWS

  Read ALL review files in planning/reviews/:
  - claude-product-review.md
  - claude-technical-review.md
  - gemini-product-review.md
  - gemini-technical-review.md
  - opencode-product-review.md
  - opencode-technical-review.md

  Synthesize into planning/reviews/synthesis.md with:

  ## Summary
  - Total issues found across all reviews
  - Consensus level (how many models agreed)

  ## Critical Issues (Must Fix Before Epic)
  Issues identified by 2+ models, or security/data-loss risks
  For each: Issue, Models that found it, Recommendation

  ## Major Concerns (Should Address)
  Issues identified by 1+ models, significant impact
  For each: Issue, Source, Recommendation

  ## Minor Suggestions (Consider)
  Nice-to-haves, optimizations

  ## Conflicting Opinions
  Where models disagreed, with analysis of which is right

  ## Questions Raised
  Combined list of clarifying questions from all reviews

  ## Recommended Actions
  Numbered list of what to do before running /epic"
```

---
disable-model-invocation: true

## Expected Output

```
╔═══════════════════════════════════════════════════════════════╗
║                   EXTERNAL REVIEW COMPLETE                     ║
╠═══════════════════════════════════════════════════════════════╣
║ Reviews Completed: 6/6                                         ║
║                                                                ║
║ Models:                                                        ║
║   ✓ Claude    - Product & Technical                            ║
║   ✓ Gemini    - Product & Technical                            ║
║   ✓ OpenCode  - Product & Technical                            ║
╠═══════════════════════════════════════════════════════════════╣
║ ISSUES FOUND                                                   ║
╠═══════════════════════════════════════════════════════════════╣
║ Critical (Must Fix):    3                                      ║
║ Major (Should Fix):     7                                      ║
║ Minor (Consider):      12                                      ║
║ Questions Raised:       5                                      ║
╠═══════════════════════════════════════════════════════════════╣
║ TOP 5 CRITICAL ISSUES                                          ║
╠═══════════════════════════════════════════════════════════════╣
║ 1. [Issue] - Found by: Claude, Gemini, OpenCode                ║
║ 2. [Issue] - Found by: Claude, Gemini                          ║
║ 3. [Issue] - Found by: OpenCode (security)                     ║
║ 4. [Issue] - Found by: Gemini, OpenCode                        ║
║ 5. [Issue] - Found by: Claude                                  ║
╠═══════════════════════════════════════════════════════════════╣
║ FILES CREATED                                                  ║
╠═══════════════════════════════════════════════════════════════╣
║ planning/reviews/claude-product-review.md                      ║
║ planning/reviews/claude-technical-review.md                    ║
║ planning/reviews/gemini-product-review.md                      ║
║ planning/reviews/gemini-technical-review.md                    ║
║ planning/reviews/opencode-product-review.md                    ║
║ planning/reviews/opencode-technical-review.md                  ║
║ planning/reviews/synthesis.md                                  ║
╠═══════════════════════════════════════════════════════════════╣
║ NEXT STEPS                                                     ║
╠═══════════════════════════════════════════════════════════════╣
║ 1. Review planning/reviews/synthesis.md                        ║
║ 2. Address critical issues in planning docs                    ║
║ 3. Run /epic to create epic (will incorporate review feedback) ║
╚═══════════════════════════════════════════════════════════════╝
```

---
disable-model-invocation: true

## Integration with /epic

After running `/external-review`, the `/epic` command will:
1. Check for `planning/reviews/synthesis.md`
2. If found, incorporate critical issues into epic risks
3. Add unresolved questions to clarifying questions phase
4. Reference review findings in epic metadata

---
disable-model-invocation: true

## Error Handling

| Error | Response |
|-------|----------|
| Missing planning docs | List missing files, abort |
| gemini CLI not found | Skip Gemini reviews, continue with others |
| opencode CLI not found | Skip OpenCode reviews, continue with others |
| Timeout on OpenCode | Use partial results, note in synthesis |
| All external CLIs fail | Fall back to Claude-only review |

---
disable-model-invocation: true

## Cross-References

- **Review Prompts:** `.claude/templates/external-review-prompts.md`
- **Planning Agent:** `.claude/agents/planning-agent.md`
- **Epic Command:** `.claude/commands/epic.md`
