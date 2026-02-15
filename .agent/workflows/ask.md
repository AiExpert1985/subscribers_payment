---
description: Query project knowledge (read-only)
---
**CURRENT STATE: ASK**

Purpose: Answer user questions about the project using canonical records.

## Scope (Read-Only)

You may read:

- `/obelisk/contracts/contracts-log.md`
- `/obelisk/history/history-log.md`
- `/obelisk/archive/` (if needed for context)
- Code (only if question requires current implementation state)

You MUST NOT modify any files or trigger workflows.

## Rules

- Base answers on canonical logs.
- Prefer logs over summaries.
- Cite relevant source (file + entry or task).
- If information is not found, state so explicitly.

## Output

1. Direct answer  
2. Brief source references
