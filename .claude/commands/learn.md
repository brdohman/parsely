---
disable-model-invocation: true
description: Capture a learning and add it to CLAUDE.md or a rules file to prevent future mistakes
argument-hint: "description of what was learned or what mistake to avoid"
---

# /learn Command

Capture learnings, mistakes, and best practices to improve future Claude behavior.

## Signature

```
/learn <description>
```

**Arguments:**
- `description` (required): What was learned, what mistake was made, or what pattern to follow

**Examples:**
```
/learn Always check if a Core Data entity has a default value before assuming nil
/learn SwiftUI @Observable requires macOS 14+, don't suggest @StateObject
/learn When using Alamofire, always use .validate() before .responseDecodable()
```

---
disable-model-invocation: true

## What This Command Does

1. **Analyzes the learning** - Determines the category and scope
2. **Suggests placement** - CLAUDE.md, a specific rule file, or new rule
3. **Drafts the rule** - Formats it appropriately for the target file
4. **Asks for confirmation** - Shows where it will be added
5. **Updates the file** - Adds the learning with timestamp

---
disable-model-invocation: true

## Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Analyze Learning                                    │
│ Categorize as:                                              │
│   • Swift/SwiftUI pattern → .claude/rules/path/             │
│   • Workflow/process → .claude/rules/workflow/              │
│   • Global behavior → .claude/rules/global/                 │
│   • Project-specific → CLAUDE.md                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Check Existing Rules                                │
│ Search for related rules that could be updated vs new       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Draft Rule                                          │
│ Format appropriately for target file                        │
│ Include: What, Why, Example (if applicable)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: Present Options                                     │
│ Show proposed changes and ask for confirmation              │
│ Options: Add to suggested file, different file, or cancel   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: Update File                                         │
│ Add learning with timestamp and context                     │
└─────────────────────────────────────────────────────────────┘
```

---
disable-model-invocation: true

## Category Mapping

| Learning Type | Target File |
|---------------|-------------|
| SwiftUI views, components | `.claude/rules/path/swiftui-views.md` |
| Core Data, migrations | `.claude/rules/path/core-data-migrations.md` |
| API clients, networking | `.claude/rules/path/api-clients.md` |
| Testing patterns | `.claude/rules/global/testing-requirements.md` |
| Swift language features | `.claude/rules/global/swift-strict.md` |
| Task/workflow process | `.claude/rules/workflow/task-*.md` |
| Commit/PR process | `.claude/rules/workflow/pre-commit.md` |
| Project-specific | `CLAUDE.md` |
| New category | Create new `.claude/rules/` file |

---
disable-model-invocation: true

## Rule Format

When adding to a rule file:

```markdown
## [Category]

### [Specific Pattern] (Added: YYYY-MM-DD)

**Do:**
- [Correct approach]

**Don't:**
- [Incorrect approach to avoid]

**Example:**
```swift
// Good
[code example]

// Bad
[counter example]
```

**Why:** [Brief explanation of the reasoning]
```

When adding to CLAUDE.md:

```markdown
## Learnings

### [Date] - [Brief Title]
- [Learning description]
- Context: [When this applies]
```

---
disable-model-invocation: true

## Implementation

```
1. Parse the learning description

2. Use Grep to search existing rules for related content:
   - Search .claude/rules/**/*.md
   - Search CLAUDE.md

3. Categorize the learning:
   - If matches existing rule file → suggest adding to that file
   - If new category → suggest creating new rule file or adding to CLAUDE.md

4. Use AskUserQuestion to confirm:
   {
     "question": "Where should this learning be added?",
     "header": "Location",
     "options": [
       { "label": "[suggested file] (Recommended)", "description": "Related rules already exist here" },
       { "label": "CLAUDE.md", "description": "Project-specific learning" },
       { "label": "New rule file", "description": "Create .claude/rules/[category]/[name].md" }
     ]
   }

5. Draft the rule in appropriate format

6. Show preview and ask for confirmation

7. Use Edit tool to add the rule to the file
```

---
disable-model-invocation: true

## Examples

### Example 1: Swift Pattern Learning

**Input:**
```
/learn When using @Observable, properties must not be private or the view won't update
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                      LEARNING CAPTURED                         ║
╠═══════════════════════════════════════════════════════════════╣
║ Category: SwiftUI / Observable                                 ║
║ Target: .claude/rules/path/swiftui-views.md                    ║
╠═══════════════════════════════════════════════════════════════╣
║ PROPOSED ADDITION                                              ║
╠═══════════════════════════════════════════════════════════════╣
║ ### @Observable Property Visibility (Added: 2026-02-01)        ║
║                                                                ║
║ **Do:**                                                        ║
║ - Use internal or public for @Observable properties            ║
║                                                                ║
║ **Don't:**                                                     ║
║ - Mark @Observable properties as private                       ║
║                                                                ║
║ **Why:** Private properties in @Observable classes don't       ║
║ trigger view updates because SwiftUI can't observe them.       ║
╠═══════════════════════════════════════════════════════════════╣
║ Add to .claude/rules/path/swiftui-views.md? [Y/n]              ║
╚═══════════════════════════════════════════════════════════════╝
```

### Example 2: Workflow Learning

**Input:**
```
/learn Always run tests before marking a task as ready for code review
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                      LEARNING CAPTURED                         ║
╠═══════════════════════════════════════════════════════════════╣
║ Category: Workflow / Task Completion                           ║
║ Target: .claude/rules/workflow/task-completion.md              ║
╠═══════════════════════════════════════════════════════════════╣
║ PROPOSED ADDITION                                              ║
╠═══════════════════════════════════════════════════════════════╣
║ ### Pre-Code-Review Checklist (Added: 2026-02-01)              ║
║                                                                ║
║ Before setting review_stage: "code-review",                    ║
║ review_result: "awaiting":                                     ║
║ - [ ] All unit tests pass locally                              ║
║ - [ ] New code has test coverage                               ║
║ - [ ] SwiftLint passes with no errors                          ║
╠═══════════════════════════════════════════════════════════════╣
║ Add to .claude/rules/workflow/task-completion.md? [Y/n]        ║
╚═══════════════════════════════════════════════════════════════╝
```

---
disable-model-invocation: true

## Cross-References

- **Rules Directory:** `.claude/rules/`
- **CLAUDE.md:** Project root
- **Swift Standards:** `.claude/rules/global/swift-strict.md`
- **SwiftUI Views:** `.claude/rules/path/swiftui-views.md`
- **Task Completion:** `.claude/rules/workflow/task-completion.md`
