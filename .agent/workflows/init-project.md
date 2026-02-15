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

### Canonical Log Rule (CRITICAL)

During initialization:
- **DO NOT write any entries** to `contracts-log.md` or `history-log.md`
- All initial content **MUST** be written **ONLY** under `## Unprocessed` in summaries
- Canonical logs remain **empty** until first maintenance compaction

---

### File Templates (Use Exactly)

#### 1. Create Empty Logs

**`/obelisk/contracts/contracts-log.md`:**

# Contracts Log

*(Leave file empty - no additional content)*

---

**`/obelisk/history/history-log.md`:**

# History Log

*(Leave file empty - no additional content)*

---

#### 2. Create Summaries with Structure

**`/obelisk/contracts/contracts-summary.md`:**

``` markdown
# Contracts Summary

Generated: [Insert actual date YYYY-MM-DD]

## System Identity
_(empty — populated after first maintenance)_

## Active Contracts
_(empty — populated after first maintenance)_

## Non-Goals
_(empty — populated after first maintenance)_

## Unprocessed

[Append all initialization contracts here]
```

**Rules:**
- Append initialization contracts under `## Unprocessed` only
- Do NOT add `## Processed` or any other sections
- Keep structured sections empty with placeholder text

---

**`/obelisk/history/history-summary.md`:**

``` markdown
# History Summary

Generated: [Insert actual date YYYY-MM-DD]

## Project Timeline
_(empty — populated after first maintenance)_

## Recent Activity
_(empty — populated after first maintenance)_

## Active Patterns
_(empty — populated after first maintenance)_

## Unprocessed

## YYYY-MM-DD | [Project Name] | INITIALIZED

**Summary:** [One-line project description]

**Decisions:**
[List key decisions from discovery]
```

**Rules:**
- Append initialization entry under `## Unprocessed` only
- Do NOT add `## Processed` or any other sections
- Keep structured sections empty with placeholder text
- Replace YYYY-MM-DD with actual date in the entry header

---

### Content Placement Rules

**Contracts Summary (`## Unprocessed`):**
- System identity and boundaries
- Global business rules
- Explicit non-goals
- Safety-critical rules
- Open questions

**History Summary (`## Unprocessed`):**
- Single INITIALIZED entry block
- Include summary + decisions from discovery

**Both Logs:**
- Must remain completely empty
- No placeholder text
- No section headers beyond file title

---

## Output

> ✅ PROJECT INITIALIZED
> 

STOP.