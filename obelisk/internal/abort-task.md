---
description: Abort & document current task
---
**CURRENT STATE: TASK ABORT**

Abort the active task, record the outcome, archive workspace, and reset to clean state.

---

## Input

Triggered when user expresses abort intent:
- `abort [reason]` → use provided reason
- `abort` → Reason defaults to "User requested"

---

## Preconditions

The following MUST exist:
- `/obelisk/workspace/active-task.md`
-  `/obelisk/history/history-summary.md`

If missing → **STOP** and report missing path


---

## Determine Abort Context

### Task Name
Extract from `active-task.md` header

### Abort Phase (Best-Effort)

Infer phase based on files present in `/obelisk/workspace/`:
- `review-notes.md` → REVIEWED
- `implementation-notes.md` → IMPLEMENTED
- `plan.md` → PLANNED
- `active-task.md` only → DEFINED

---

## Write History (Always)

Append the following block as the last entry within the section `## Unprocessed`
in `/obelisk/history/history-summary.md`:

``` markdown
## YYYY-MM-DD | [Task Name] | ABORTED

**Summary:** [One-line task goal]

---

```

---

## Archive Workspace

Destination: `/obelisk/archive/aborted/YYYYMMDD-[task-name]/`

**Steps:**
1. Create destination directory
2. Move ALL files from `/obelisk/workspace/` to destination
3. Verify `/obelisk/workspace/` is empty

---

## Output
```
🛑 TASK ABORTED

Archived: /obelisk/archive/aborted/YYYYMMDD-[task-name]/
Phase: [Detected Phase]
Reason: [Abort reason]

Workspace cleared. Ready for next task.
```

STOP.