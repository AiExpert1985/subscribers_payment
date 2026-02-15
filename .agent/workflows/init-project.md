---
description: Initialize new Obelisk project
---
**CURRENT STATE: PROJECT START**

Two-phase process: Discovery (discussion) → Initialization (file creation).

---

## Forbidden Pre-Existing State

The following MUST NOT exist:

**State files:**
- `/obelisk/contracts/contracts-summary.md`
-  `/obelisk/contracts/contracts-log.md`
- `/obelisk/history/history-summary.md`
- `/obelisk/history/history-log.md`

If any exist → **STOP**.

**Output to user:**
> ⛔ PROJECT INIT ABORTED  
> This project appears to be already initialized.  
> Re-initialization is blocked to prevent accidental data loss.  
> If you intended to start fresh, ensure no existing project state remains.

---

# PHASE 1: DISCOVERY

Understand the project through discussion. **No files created yet.**

---

## Discovery Rules

**Purpose**
- Understand the system
- Identify contract candidates

**Questioning Rules**
- Ask only what materially affects contracts or long-lived understanding
- Do NOT propose solutions, designs, or code
- Do NOT assume missing information — surface it explicitly
- Prefer fewer, high-impact questions
- Skip obvious or deferrable details
- Group related clarifications into a single question

**Allowed Topics**
- System identity and boundaries
- Core invariants
- Global or technical constraints
- Safety or irreversible risks
- Long-lived design or UX intent

**Forbidden Topics**
- Implementation details
- Edge cases or speculative future features
- Preferences likely to change
- Anything deferrable to task-level work or clearly inferable

---

## Discovery Flow

### 1. Open

Output exactly:
```
PHASE 1: DISCOVERY

Describe your system to help initialize contracts.
Type `skip` to use minimal defaults (not recommended).
```

**STOP. Wait for user response.**

- If `skip` → proceed to PHASE 2
- Otherwise → treat response as project description, proceed to Clarification

---

### 2. Clarification

#### Step 1 — Core Questions

Based on the project description provided by the user, ask questions that materially affect:
- System identity and boundaries
- Contracts and invariants
- Global constraints or risks
- Long-lived architectural or UX intent

Ask only what would change contracts or durable understanding.

---

#### Step 2 — Follow-up Questions

Ask follow-up questions **only if needed** to resolve ambiguity
introduced by earlier answers.

---

### 3. Summary

Present confirmed understanding for review.

If ambiguity remains:
- Record unresolved items under **Open Questions**
- Treat them as task-level concerns, not blockers
- Proceed with initialization

**Summary Format**
```markdown
**System Identity:**
- What it is:
- What it is NOT:
- Users:

**Contract Candidates:**
- Core:
- [Feature]:

**Safety Concerns:**  
**Explicit Non-Goals:**  
**Open Questions:**
```

---

## Discovery Exit

Output exactly:
```
Review the summary above.
- Type `initialize` to create project files
- Or reply with corrections to update the summary

Awaiting input.
```

**STOP. Do not proceed until user responds.**

- If `initialize` → proceed to PHASE 2
- Otherwise → treat as corrections, update summary, confirm again

---

# PHASE 2: INITIALIZATION

Extract and persist confirmed project truth. **Non-interactive, non-creative.**

---

## Rules

- Use ONLY information explicitly established
- Do NOT invent, infer, or strengthen intent
- Be minimal — over-specification is failure
- List unresolved items explicitly

---

## Initialization (Skipped Discovery)

If discovery was skipped:

- Populate only what is explicitly stated
- Leave all other sections empty
- Do NOT infer or normalize missing information
- Do NOT create feature contract files

---

## Required Outputs

### Contracts (`/obelisk/contracts/`)

create: 
- `contracts-summary.md`
- `contracts-log.md`

Append initial invariants to the `## Unprocessed` section of `contracts-summary.md`:
- System identity and boundaries
- Global business rules
- Explicit non-goals
- Safety-critical rules
- Open questions


---

### History (`/obelisk/history`)

Create 
- `history-summary.md`:
- `history-log.md`

Append the following block as the last entry within the section `## Unprocessed`
in `/obelisk/history/history-summary.md`:

``` markdown
## YYYY-MM-DD | [Project Name] | INITIALIZED

**Summary:** [One-line project description]

**Decisions:**
[Copy from discovery-decisions.md created during init]

---

```

---

## Output

> ✅ PROJECT INITIALIZED
> 

STOP.