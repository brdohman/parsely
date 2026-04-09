---
name: Pre-existing test failures must always get a tracking item
description: Never dismiss pre-existing test failures as "not our problem" — always create a Bug or TechDebt task immediately
type: feedback
---

Pre-existing test failures must ALWAYS result in a Bug or TechDebt task being created immediately. Never say "these failures are pre-existing, not caused by this epic" and move on without filing a tracking item.

**Why:** The user explicitly dislikes the behavior where agents dismiss pre-existing failures. Untracked failures accumulate silently and become normalized. Every failure needs accountability, even if it won't be fixed in the current epic.

**How to apply:** Any agent that encounters a test failure not caused by the current work must use TaskCreate to file a Bug or TechDebt task before continuing. This applies at every level — story QA, epic QA, /checkpoint, /complete-epic. The filed task doesn't need to block the current work, but it must exist.
