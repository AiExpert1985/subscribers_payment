---
description: run small mechanical fix without full task flow
---
**CURRENT STATE: HOTFIX**

Execute a pre-approved hotfix: a safe, atomic, low-risk change.

---

## Preconditions

### Required Inputs

The following MUST exist:
- Hotfix description (passed from `/define-task`)
- `/obelisk/guidelines/ai-engineering.md`
- `/obelisk/contracts/contracts-summary.md`
- `/obelisk/history/history-summary.md`

If any are missing → **STOP** and report


---

## Execution Rules (Strict)

**MUST:**
- Perform exactly one localized change
- Preserve all existing behavior and contracts
- Modify minimum number of files
- Keep change fully reversible

**MUST NOT:**
- Introduce new concepts, abstractions, or features
- Expand scope beyond original description
- Perform refactors or multi-step changes

**If scope grows or uncertainty appears → STOP**

---

## Apply Change

**Mental planning (required):**
- Identify exact file(s) and line(s) to change
- Verify change aligns with existing code patterns
- Confirm no side effects or contract violations

**Then execute:**
- Apply the minimal change directly
- No formal plan.md artifact
- No user questions
- Stop if anything unexpected appears

**If the change requires:**
- Multiple steps
- Coordination across files
- Design decisions
→ **STOP** (should have been full task)

---

## Write History

Append the following block as the last entry within the section `## Unprocessed`
in `/obelisk/history/history-summary.md`:

``` markdown
## YYYY-MM-DD | [Hotfix Name] | HOTFIX

**Summary:** [One-line description]

---

```
---

## Output
```
✅ HOTFIX APPLIED
Recorded in history-log.md
```

STOP.