---
description: Suggest next tasks
---
**CURRENT STATE: TASK SUGGESTION**

Help the user choose the next task to work on.

> **Scope:** Advisory only. Does NOT create tasks or modify files.

---

## Required Context (Read-Only)

- `/obelisk/history/history-log.md`
- `/obelisk/contracts/contracts-log.md`

If either is missing → STOP.

---

## Analysis

From **history-log.md**:
- Last 10 approved tasks
- Explicit deferred items not marked resolved
- Rejected/aborted tasks and their reasons
- Repeated instability or friction patterns

From **contracts-log.md**:
- Active invariants
- Recently added or changed contracts
- Areas lacking enforcement or clarity

Optional (light check only if needed):
- Briefly scan relevant files mentioned in recent history
- Check whether declared contracts appear enforced
- Do NOT design solutions

---

## Prioritization

Order of importance:

1. Risk Containment  
   (Contract gaps, repeated instability, invariant risks)

2. Deferred Debt  
   (Explicitly deferred follow-ups)

3. Continuation  
   (Logical next step of recent work)

4. Optimization  
   (Grounded cleanup tasks)

Rules:
- Skip completed work
- Skip rejected tasks unless reason is now resolved
- Avoid speculative or future features
- Tasks must be concrete and executable as a single scoped task

Select the **top 3 highest-impact tasks**.

---

## Output

``` markdown
Here are suggested next tasks based on project history and contracts:

1. **[Task Name]**  
   Category: [Risk Containment | Deferred Debt | Continuation | Optimization]  
   Why: [Concrete reason grounded in logs]

2. **[Task Name]**  
   Category: [Risk Containment | Deferred Debt | Continuation | Optimization]  
   Why: [Concrete reason grounded in logs]

3. **[Task Name]**  
   Category: [Risk Containment | Deferred Debt | Continuation | Optimization]  
   Why: [Concrete reason grounded in logs]
```