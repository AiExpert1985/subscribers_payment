
# CURRENT STATE: REVIEW + ARCHIVE

Validate implementation against frozen task and finalize the task.

---

## Preconditions

The following MUST exist:

- `/obelisk/workspace/active-task.md`
- `/obelisk/workspace/implementation-notes.md`
- `/obelisk/contracts/contracts-summary.md`
- `/obelisk/history/history-summary.md`

If any are missing → STOP and report path.

---

# Authority

- Frozen task defines scope and intent.
- Contracts define invariants.
- Plan (inside implementation-notes.md) is informational only.

Review validates against:
- Frozen task
- Success Criteria
- Contracts
- Scope boundaries

---

# Review Phase

## Required Validation

You MUST:

1. Inspect actual source code changes (not summaries).
2. Confirm the frozen Task Goal is fully achieved.
3. Confirm all Success Criteria are satisfied as written.
4. Confirm no contract is violated or implicitly weakened.
5. Confirm scope was not expanded beyond the frozen task.
6. Confirm implementation does not reinterpret or alter task intent.
7. Confirm no unrelated, speculative, or hallucinated changes were introduced.

If any validation fails → Status = REJECTED.

---

## Anti-Hallucination Rule (Mandatory)

For every ✓ involving code validation, reviewer MUST reference:

- File path + function/class name  
OR  
- Short code snippet  
OR  
- Precise logic description observed

If code evidence cannot be provided → mark as ✗.

---

# Review Output

Write to `/obelisk/workspace/review-notes.md`:


```markdown
# Review Outcome

**Status:** APPROVED | REJECTED

## Summary
[2–3 sentence factual summary]

## Validation Results
1. Goal Achieved: ✓ | ✗
2. Success Criteria Met: ✓ | ✗
3. Contracts Preserved: ✓ | ✗
4. Scope Preserved: ✓ | ✗
5. Intent Preserved: ✓ | ✗
6. No Hallucinated Changes: ✓ | ✗

## Files Verified
- [list of actual source files reviewed]

## Notes
- Factual observations only
```

# Status Gate

If **Status = REJECTED**:

1. Append the following block as the last entry within the section `## Unprocessed` in `/obelisk/history/history-summary.md`:

``` markdown
## YYYY-MM-DD | [Task Name] | REJECTED

**Summary:** [One-line task goal]

---

```

2. Archive workspace to: 
   `/obelisk/archive/rejected/YYYYMMDD-[task-name]/`
3. Clear `/obelisk/workspace/`

Output:

``` markdown
⚠️ TASK CLOSED — REJECTED
Archived: /obelisk/archive/rejected/YYYYMMDD-[task-name]/

```

STOP.

---

# Approved Path

If **Status = APPROVED**:

## 1 — Write History

Append the following block as the last entry within the section `## Unprocessed`
in `/obelisk/history/history-summary.md`:

``` markdown
## YYYY-MM-DD | [Task Name] | APPROVED

**Summary:** [One-line task goal]

**Decisions:**
[Copy content from discovery-decisions.md if present]

**Deferred:**
[Deferred items from Execution Summary, if any]

---

```

---

## 2 — Apply Contract Changes (If Present)

If `/obelisk/workspace/contract-changes.md` exists:

- Append approved entries verbatim to contracts log under `## Unprocessed`
- Do NOT reinterpret or rewrite content

---

## 3 — Archive Workspace

Archive all files to:

`/obelisk/archive/completed/YYYYMMDD-[task-name]/`

Clear `/obelisk/workspace/`

---

## Maintenance Check

If `/obelisk/history/history-log.md` exceeds 4000 tokens:
→ Run History Compaction

If `/obelisk/contracts/contracts-summary.md` exceeds 4000 tokens:
→ Run Contract Compaction


---

# Output

```
✅ TASK CLOSED — APPROVED
Archived: /obelisk/archive/completed/YYYYMMDD-[task-name]/
```


STOP.