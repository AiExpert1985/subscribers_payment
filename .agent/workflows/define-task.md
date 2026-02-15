---
description: Creates a new Obelisk task
---
**CURRENT STATE: TASK DISCOVERY**

Define a new task through discussion.

---

## EXECUTION GUARD (CRITICAL)

Task Discovery defines intent.

You MUST NOT plan, implement, or modify code during this phase.  
If execution is triggered at any point → **STOP immediately**.

---

## Entry Point Detection

**Check if task description was provided:**

**IF user provided description:**

```
/define-task Add image picker to main screen
```

- Extract task_description = "Add image picker to main screen"
- Proceed to Preflight

**IF no description:**

```
/define-task
```

- Output: "Describe your task:"
- Call `/obelisk/internal/suggest-task.md` (outputs suggestions below)
- Wait for response
- Set task_description = [response]
- Proceed to Preflight

---

## Hotfix Assessment (If Description Provided)

Before starting discovery, assess whether the task qualifies as a hotfix.

**A task qualifies as hotfix if :**
- Scope is narrow, low-risk and clearly defined
- Change is mechanical and localized
- No design or architectural decisions required
- No contract changes required

**Common examples (non-exhaustive):**
- Typo, formatting, or whitespace fix
- Simple rename (variable, function, file)
- Add missing import or dependency
- Trivial bug fix (null check, off-by-one)
- Pure UI changes

**If criteria met:**
- Output: "Detected simple fix. Running hotfix path."
- Call `internal/hotfix.md` with description
- STOP

**If criteria NOT met or uncertain:**
- Proceed to Preflight (full task flow)

---
## Preflight

### Clean Workspace

- Delete all files in `/obelisk/workspace/`

### Load Inputs

#### Required Files
- `/obelisk/guidelines/ai-engineering.md`
- `/obelisk/contracts/contracts-summary.md`

If missing:
- STOP and report missing file
- OUTPUT: use `/init-project` to initialized project properly


---

## Code Reconnaissance (Optional, Bounded)

You MAY read code during Task Discovery, but ONLY to answer:
- **“Where does this change live?”**
- **“Which modules / files are likely affected?”**
- **“Do existing contracts already cover this area?”**

You MUST NOT:
- Design the solution
- Prototype implementation details
- Perform broad refactors

**Stop reconnaissance once:**
- The likely impacted modules / files are identified, AND
- Any contract impact is known (or confirmed as “none”), AND
- You can state the task boundary in plain language

If you find yourself reasoning about *how* to implement the change → STOP


**Output:**  
After completing reconnaissance, output only:
> "Related code reviewed."


---

## Discovery Questions

### Question Rules

These rules apply to all discovery questions in all sets.

**Ask ONLY questions affecting:**
- Task definition or intent
- Scope boundaries
- Feasibility or approach
- Required constraints

**Do NOT ask about:**
- Information already explicitly stated in contracts, the task description, or prior answers
- Implementation details (for planning phase)

**Keep questions high-impact. Skip obvious or low-value questions.**

---
### Providing Recommendations

For decision-based questions, provide a brief recommendation **only when code patterns or constraints clearly favor one option**.


**Format:**
``` markdown
[Question]

Recommendation: [Option] — [brief reason].
```

**Example:**
```
Where should password reset tokens be stored?

Recommendation: Database table — aligns with existing session storage.

```

**Skip the recommendation if options are equally valid, evidence is unclear, or user preference is required.**

---

### Set 1: Understanding (MANDATORY)

**Always ask at least one question**, even if task seems clear.

**📌 Questions:**
- What, why, for whom
- Success criteria (observable completion signals)
- Scope boundaries (what's in/out)
- Key constraints or dependencies (including required or preferred external libraries, if any)

**After Set 1:**
> "Understanding complete."

→ If no clarification gaps remain AND no contract require user input:
   - State: "No further questions are needed."
   - Proceed to Task Freeze

→ Otherwise: Continue to Set 2


---

### Set 2: Refinement (If Needed)

Resolve remaining issues in organized groups. Each group may be skipped if no issues were detected.

---

**📌 Group 1: Clarification** (if gaps remain)

- Resolve ambiguities from Set 1
- Important edge cases needing user input
- Approach selection when multiple valid options
- Flag if task should be split

*Skip if no clarification needed.*

---

**📋 Group 2: Contracts**

Check task against all loaded contracts with full context from Set 1.

**If conflict found:**
```
⚠️ **Contract Conflict**

Task: [specific step that conflicts]
Conflicts with: "[exact contract text]"

**Options:**
1. **Update task** — [what changes]
2. **Update contract** — [what exception needed]

**Recommendation:** [Option] because [reason]

Choose: [1/2]
```

**If new contract needed** (ONLY for business-critical rules):
```
📋 **Contract Addition**

Task introduces: [critical functionality]

— [Rule — why contract-worthy]

Add? [yes/no]
```

*Skip if no contract issues.*


---

## TASK FREEZE


### `active-task.md`

Write to `/obelisk/workspace/active-task.md`:

``` markdown

# Task: [One-line descriptive name]

## Goal
[What must be achieved and why]

## Scope
✓ Included: [clear list from discovery]
✗ Excluded: [clear list from discovery]

## Constraints
- [Contracts to preserve]
- [Technical/business limits]

## Success Criteria
- [Observable completion signals]

## Open Questions (if any)
- [Unresolved ambiguities]

```

---

### `contract-changes.md` (conditional)

**Only create this file if contract changes were approved during discovery.**
Write to `/obelisk/workspace/contract-changes.md`:


``` markdown

# Contract Changes — [Task Name]

**Action:** update | create
**Change:**
- [exact text]

**Action:** create | update
**Change or Move:**
- [exact text]

```

**Rules:**

- **Only include contract changes explicitly approved by the user during discovery**

---

## `discovery-decisions.md`

Write to `/obelisk/workspace/discovery-decisions.md`

**Format**:

```markdown
## [TASK_NAME] | YYYY-MM-DD

**Summary:**
- [one-line task intent]

**Decisions:**
- [decision 1]
- [decision 2]

**Deferred:**
- [item if any]
```


**Rules:** 
- Write concise, self-contained decisions only (no Q/A, no reasoning) 
- Represents model's understood and user-approved interpretation 
- Do not copy raw or verbatim user text 
- Append-only; do not revise earlier entries

---

### Display Task & Options

**Obelisk: Task Ready**

| **Task**      | [One-line name from header]                   |
| ------------- | --------------------------------------------- |
| **Goal**      | [One sentence]                                |
| **Scope**     | ✓ [2-3 key inclusions] ✗ [1-2 key exclusions] |
| **Success**   | [Primary completion signal]                   |
| **Contracts** | [brief change]                                |

**Full definition:** `/obelisk/workspace/active-task.md`

---


## TERMINAL STATE

Output EXACTLY this block. No additions.

``` markdown
**Task frozen:** `/obelisk/workspace/active-task.md`

**Next steps (user-initiated):**
- Execute: `/run-task`
- Edit: modify file, then re-run `/define-task`
```

