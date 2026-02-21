---
description: Auto-execute task until the end
---
## Required Files

- `/workspace/task.md`
- `/workspace/plan.md`
- `/guidelines/ai-engineering.md`

If any are missing → STOP and report path.

---

## IMPLEMENTATION PHASE

### Execution Rules

MUST:

- Implement strictly according to `plan.md`.
- Modify ONLY files listed in the plan.
- Preserve all contracts listed in the plan.
- Log any divergence in implementation-notes.md.

MUST NOT:

- Reinterpret, redesign, or expand the plan.
- Silently correct or redesign plan errors.
- Modify contracts.
- Modify files not listed in the plan.
- Ask questions (use STOP instead).

---

### STOP Conditions

STOP immediately if:

- A plan requirement cannot be achieved without new decisions.
- A change would violate a contract listed in the plan.
- Completing a step requires architectural or scope decisions not in the plan.
- Continuing would risk irreversible or unsafe changes.
- You are uncertain whether a change is mechanical.

STOP is terminal. No further execution is allowed.

---

### Allowed Mechanical Adaptations (No STOP)

Proceed only if intent and observable behavior remain unchanged:

- Minor renames
- Import adjustments
- Formatting / whitespace
- Syntax or API alignment to actual code state
- Defensive checks consistent with existing patterns

Log any such divergence.

---

### Implementation Notes

Create `/workspace/implementation-notes.md`:

```markdown
# Implementation Notes: [Task Name]

## Execution Summary
[What was done. If exact match, state so.]

## Divergences
- Plan specified: [X]
- Actual: [Y]
- Reason: [mechanically necessary because...]

(If none: "Plan implemented as specified. No divergences.")
```


---

## Review Phase

For every ✔, provide evidence: file path + function/class, code snippet, 
or precise observed logic. Vague statements are not evidence.

 **Write to `/workspace/review-notes.md`:**

```
# Review: [Task Name]

**Status:** APPROVED | REJECTED

1. Goal Achieved: ✔ | ✗ — [evidence]
2. Contracts Preserved: ✔ | ✗ — [evidence]
3. Scope Preserved: ✔ | ✗ — [evidence]

**Files Verified:** [list]

**Notes:** [optional — mechanical divergences or observations only]
```

---


### Status Gate

**If REJECTED**

1. Append to `/history/history-log.md`:

``` markdown
## YYYYMMDD-HHMM | [Task Name] | REJECTED

---

```

2. Archive workspace to  
   `/archive/rejected/YYYYMMDD-HHMM-[task-name]/`
   
3. Clear `/workspace/`

**Output:**

``` markdown
⚠️ TASK CLOSED — REJECTED
Archived: /archive/rejected/YYYYMMDD-HHMM-[task-name]/

```

STOP.

---

**If APPROVED**

#### **1 — Write History**

Append to `/history/history-log.md`:

``` markdown
## YYYYMMDD-HHMM | [Task Name] | APPROVED

---

```

---

#### **2 — Apply Contract Changes**

If `task.md` has `## Contract-Changes` section:

Append its content exactly as written to  
`/contracts/contracts-summary.md → ## Unprocessed`

**Format:**

``` markdown
## YYYYMMDD-HHMM | [Task Name]

[Contract change content]

---
```

**Rules:**
- Do NOT modify wording
- Do NOT reinterpret
- Preserve exact contract text

**If contracts-summary `## Unprocessed` contains ≥ 10 entries 
→ Run `/internal/maintain-contracts.md`**

---

#### **3 — Promote Design Changes**

If `task.md` has `## Design-Changes` section:

Append its content (excluding Summary and Deferred) to:

`/design/design-summary.md` → `## Unprocessed`

**Format:**

``` markdown
## YYYYMMDD-HHMM | [Task Name]

[Architecture / Design and Business Logic sections exactly as written]

---
```


**If design-summary `## Unprocessed` contains ≥ 10 entries 
→ Run `/internal/maintain-desgin.md`** 

---

#### **4 — Archive Workspace**

Archive all files to:
`/archive/completed/YYYYMMDD-HHMM-[task-name]/`

Clear `/workspace/`

---

## Output

```
✅ TASK CLOSED — APPROVED
Archived: /archive/completed/YYYYMMDD-HHMM-task-name/
```


STOP.
