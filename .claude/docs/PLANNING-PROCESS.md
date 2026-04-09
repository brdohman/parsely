# Planning Process: Surfaces First, Plumbing Last

## Philosophy

When building a macOS app, the order you build things determines how fast you can iterate. The wrong order creates friction that compounds across the entire project.

**The wrong order:** Security -> Database -> API -> UI -> Polish
- Every test requires password/keychain setup
- SwiftUI Previews don't work (can't access keychain in preview)
- UI iteration means: launch app -> enter password -> navigate -> change -> rebuild -> repeat
- Testing is slow, UI feedback is slow, everything is slow

**The right order:** Protocols -> UI -> Polish -> Database -> API -> Security
- Tests run against in-memory mocks (instant)
- SwiftUI Previews work for every view (instant)
- UI iteration means: change -> see in preview (~1 second)
- Security wraps the finished app without changing any views

**The rule:** If a user won't see it, build it last. If a user will see it, build it first.

---

## The Planning Workflow

```
Idea
  |
  v
/discover .............. Multi-phase discovery Q&A
  |                      Generates: PRD, UI_SPEC, DATA_SCHEMA,
  |                      TECHNICAL_SPEC, INTEGRATION_SPEC(s),
  |                      IMPLEMENTATION_GUIDE
  v
Review & Edit .......... Human reviews generated docs, makes changes
  |
  v
/external-review ....... (Optional) Multi-model review from Claude/Gemini/OpenCode
  |
  v
/epic .................. Creates structured epic from planning docs
  |
  v
/write-stories-and-tasks Breaks epic into stories and tasks
  |
  v
Human reviews plan ..... Review epic, stories, and tasks
  |
  v
/approve-epic .......... Approve the entire plan for implementation
  |
  v
/build ................. Start implementation
```

### What's New: `/discover`

The `/discover` command fills the gap between "I have an idea" and "I have planning docs ready for `/epic`". It conducts structured discovery across 6 phases, generating a complete set of planning documents.

---

## Discovery Phases

### Phase 1: Product Discovery -> PRD.md

**What we learn:** What are we building, for whom, and why?

Questions about:
- Problem statement and target user
- Core features and user stories
- What's explicitly NOT in scope
- Success metrics
- Release criteria

**Output:** `planning/docs/PRD.md`

### Phase 2: UI Discovery -> UI_SPEC.md

**What we learn:** What will users see and interact with?

Questions about:
- Screen inventory (every screen in the app)
- Navigation structure
- Component library (buttons, inputs, tables, modals)
- Interaction patterns (click, edit, keyboard shortcuts)
- Design system (colors, typography, spacing)
- Animation and transitions
- Responsive behavior
- Accessibility requirements

**Output:** `planning/docs/UI_SPEC.md`

**Key principle:** This comes BEFORE technical architecture because UI decisions drive the protocol definitions. You need to know what the views need before you define the service contracts.

### Phase 3: Data Discovery -> DATA_SCHEMA.md

**What we learn:** What data does the app need?

Questions about:
- Data models and their relationships
- Storage approach (SQLite, Core Data, UserDefaults)
- Default/seed data
- Sample data for development
- Migration strategy
- Data validation rules

**Output:** `planning/docs/DATA_SCHEMA.md`

**Key principle:** The schema includes an "In-Memory Development Mode" section. Every schema document should define how mock data is provided for previews and tests.

### Phase 4: Technical Discovery -> TECHNICAL_SPEC.md

**What we learn:** How will the architecture support the UI and data?

Questions about:
- Architecture overview (MVVM, services, protocols)
- Service protocols (the contracts views depend on)
- Mock implementations (for previews and tests)
- App environment (production/development/testing)
- Error handling strategy
- Performance considerations
- State management

**Output:** `planning/docs/TECHNICAL_SPEC.md`

**Key principle:** The tech spec defines PROTOCOLS FIRST, concrete implementations second. ViewModels depend on protocols. Mock services conform to the same protocols. This enables the entire preview-driven development workflow.

### Phase 5: Integration Discovery -> [SERVICE]_INTEGRATION.md

**What we learn:** What external services does the app connect to?

Questions about:
- API reference (endpoints, auth, data models)
- Authentication flow
- Sync strategy (initial + incremental)
- Rate limiting
- Error handling and retry
- Testing approach (mock service)

**Output:** `planning/docs/[SERVICE]_INTEGRATION.md` (one per external service)

**Key principle:** Integration docs describe both the real service AND the mock implementation. The mock is used for all development until the integration phase.

### Phase 6: Implementation Planning -> IMPLEMENTATION_GUIDE.md

**What we learn:** In what order do we build everything?

This phase reads ALL previously generated documents and produces the implementation guide. The guide follows the surfaces-first ordering:

```
Phase 1: Architecture Skeleton + Protocols + Models
Phase 2: Main Layout + Navigation (with mock data)
Phase 3-N: UI Screens (each with mock data, previews)
Phase N+1: Polish + Keyboard Shortcuts
Phase N+2: Real Database (unencrypted)
Phase N+3: External Service Integration
Phase N+4: Security Layer (encryption, keychain, login)
Phase N+5: Backup & Export
```

**Output:** `planning/docs/IMPLEMENTATION_GUIDE.md`

---

## Surfaces-First Phase Ordering

When generating the implementation guide, phases MUST follow this ordering principle:

### Build First (User-Facing)

1. **Protocol skeleton** - Define all service contracts, create mock implementations, sample data factories
2. **Navigation shell** - App structure, sidebar, tabs, empty states
3. **Core UI screens** - The main screens users interact with, built against mock data
4. **Secondary UI screens** - Settings, management views, modals
5. **Polish** - Keyboard shortcuts, animations, confirmations, accessibility

### Build Last (Infrastructure)

6. **Real database** - Concrete persistence replacing mocks (unencrypted first)
7. **External integrations** - Real API clients replacing mock services
8. **Security** - Encryption, keychain, login flow wrapping the working app
9. **Backup & export** - Data safety and portability

### Why This Order Works

| Concern | When Built | Why |
|---------|-----------|-----|
| Protocols | Phase 1 | Everything depends on contracts |
| UI screens | Phases 2-5 | Users see these; iterate fast with previews |
| Polish | After UI | Need all screens to exist first |
| Database | After polish | Views don't change when swapping mock -> real |
| API integration | After database | Need real persistence for real data |
| Security | After integration | Wraps the finished app; doesn't change views |
| Backup | Last | Needs encryption to exist first |

---

## Development Modes

Every project planned with this process includes three environments:

| Mode | Database | Keychain | Login | Use For |
|------|----------|----------|-------|---------|
| **Production** | Real (encrypted) | Real | Required | Release builds |
| **Development** | In-memory (mock) | Mock | Skipped | Day-to-day coding, previews |
| **Testing** | In-memory (mock) | Mock | Skipped | Automated test runs |

The development scheme launches straight into the main UI with sample data. No password, no database setup, no keychain access. This is what makes iteration fast.

---

## Template Reference

| Template | Location | Used By Phase |
|----------|----------|---------------|
| PRD | `planning/templates/PRD-TEMPLATE.md` | Phase 1 |
| UI Spec | `planning/templates/UI_SPEC-TEMPLATE.md` | Phase 2 |
| Data Schema | `planning/templates/DATA_SCHEMA-TEMPLATE.md` | Phase 3 |
| Technical Spec | `planning/templates/TECHNICAL_SPEC-TEMPLATE.md` | Phase 4 |
| Integration Spec | `planning/templates/INTEGRATION_SPEC-TEMPLATE.md` | Phase 5 |
| Implementation Guide | `planning/templates/IMPLEMENTATION_GUIDE-TEMPLATE.md` | Phase 6 |

---

## Commands Reference

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/discover` | Multi-phase discovery -> generates all planning docs | Starting a new app or major feature |
| `/external-review` | Multi-model review of planning docs | Before creating epic (optional) |
| `/epic` | Creates structured epic from planning docs | After docs are reviewed |
| `/write-stories-and-tasks` | Breaks epic into stories and tasks | After epic created |
| `/feature` | Quick discovery -> epic (skips doc generation) | Small, well-understood features |

### When to Use `/discover` vs `/feature`

**Use `/discover` when:**
- Starting a new app from scratch
- Building a major feature that needs multiple screens
- You want comprehensive planning docs for reference
- You want to iterate on the plan before committing to tasks
- The feature involves security, APIs, or complex data

**Use `/feature` when:**
- Adding a small, well-understood feature
- The scope is clear and doesn't need extensive documentation
- You want to go from idea to tasks quickly
