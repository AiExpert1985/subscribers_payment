---
description: Plan and implement the active task in one workflow
---
**CURRENT STATE: TASK EXECUTION**

Plan and implement the active task in one workflow.

---

## Preconditions

Required:
- `/obelisk/workspace/active-task.md`
- `/obelisk/contracts/contracts-summary.md`
- `/obelisk/guidelines/ai-engineering.md`

Optional:
- `/obelisk/workspace/contract-changes.md`

If any required file is missing → STOP and report path.

---

# Authority

- Frozen task defines scope and intent.
- Contracts define invariants.
- Plan is a working blueprint (informational, not authority).

---

# Step 1 — Task Analysis (Required)

Read relevant code before planning.

You MUST:
- Understand actual code structure and dependencies
- Identify risks and edge cases
- Determine correct order of operations
- Confirm task is feasible in current codebase

You MUST NOT:
- Expand frozen task scope
- Introduce new requirements
- Modify contracts

If task is internally contradictory or infeasible → STOP.

---

# Step 2 — Create Initial Plan (Before Code Changes)

Create `/obelisk/workspace/implementation-notes.md`:

```markdown
# active-plan: [Task Name]

## Goal
[From active-task.md]

## Success Criteria
[From active-task.md]

## Initial Plan

**Approach:**
[3–5 sentences describing strategy and key decisions]

**Files to modify:**
- `/path/file.ext` — [what will change]

**Files to create:**
- `/path/new-file.ext` — [purpose]

**Key steps:**
1. [Step]
2. [Step]
3. [Step]

**Constraints:**
- Preserve all contracts in contracts-summary.md
- Do not expand scope beyond frozen task
  
---

## Plan Revisions

*Leave empty initially. Append here if approach changes during implementation.*

---

## Execution Summary

*Leave empty. Complete after implementation.*

```

The `## Initial Plan` section MUST NOT be modified after creation.

All sections required. Use "None" if applicable.

---

# Step 3 — Implementation

Execute the initial plan.

You MAY adapt the approach if required by actual code state, provided ALL are true:

1. Frozen Task Goal remains unchanged.
2. Success Criteria remain achievable as written.
3. No contract is violated or modified (unless approved).
4. Scope boundaries are preserved.
5. No new feature or requirement is introduced.

When adapting:

Append under `## Plan Revisions`:

``` markdown
**Revision [N]:**
- **Original plan:** [what initial plan said]
- **Actual approach:** [what you did instead]
- **Reason:** [why revision was necessary]

```

Do NOT modify the `## Initial Plan` section.

---

# STOP Conditions

STOP immediately if ANY true:

- Task Goal requires reinterpretation.
- Success Criteria must change.
- A contract would be violated.
- Scope must expand beyond frozen task.
- A fundamentally new architectural direction or critical new decision is required.
- Task is infeasible in current codebase.
- Continuing risks irreversible damage (data loss, security issue).

If uncertain whether scope or contracts are affected → STOP.

STOP is terminal.

---

# Completion

After implementation, append under `## Execution Summary`:

``` markdown
## Execution Summary

**Final approach:** [Brief description]

**Deferred items:** [If any]

```

---

OUTPUT:

> "✓ EXECUTION COMPLETE — implementation-notes.md created"