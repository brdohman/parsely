# Feature Request Template

## Epic
```
TaskCreate {
  subject: "Feature: [name]",
  description: "...",
  metadata: { type: "epic", priority: "P1", approval: "approved", blocked: false, review_stage: null, review_result: null, labels: [] }
}
```

## Problem Statement
[2-3 sentences describing the problem this solves]

## User Story
As a [user type], I want to [action] so that [benefit].

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

## Scope

### In Scope
- [Feature aspect 1]
- [Feature aspect 2]

### Out of Scope
- [Explicitly excluded 1]
- [Explicitly excluded 2]

## Technical Considerations

### Database Changes
- [ ] New tables needed
- [ ] Schema modifications
- [ ] RLS policies required
- [ ] No database changes

### API Changes
- [ ] New endpoints
- [ ] Modified endpoints
- [ ] No API changes

### UI Changes
- [ ] New screens
- [ ] Modified screens
- [ ] No UI changes

## Business Rules Affected
- [ ] BR-XXX-NNN: [How it affects]
- [ ] New business rules needed
- [ ] No business rules affected

## Acceptance Criteria
```gherkin
Given [precondition]
When [action]
Then [expected result]
```

## Open Questions
- [ ] [Question 1]
- [ ] [Question 2]

## Priority
- [ ] P1 - Critical
- [ ] P2 - Important
- [ ] P3 - Nice to have

---

Next: Run `/plan` to break into phases and tasks.
