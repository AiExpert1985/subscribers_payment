---
description: Compact log and regenerate contracts summary
---
**CURRENT STATE: MAINTENANCE**

Compact contract log, then regenerate summary.

---

## Preflight

Required:

- `/obelisk/contracts/contracts-log.md`
- `/obelisk/contracts/contracts-summary.md`
- `/obelisk/history-log.md`

Missing → **STOP. Show error.**

---

## Stage 1: Process Unprocessed Contracts

Read `/obelisk/contracts/contracts-summary.md`.

1. Move all entries from `## Unprocessed` in `contracts-summary.md` → append to `/obelisk/contracts/contracts-log.md`
2. Clear the `## Unprocessed` section in `contracts-summary.md`

---

## Stage 2: Regenerate Contracts Summary

### Gather Inputs (Read-Only)

Read ALL of the following:

- `/obelisk/contracts/contracts-log.md` (authoritative contract history)
- `/obelisk/history-log.md` (context of evolution)
- Codebase (current system state)

---

## Reconciliation Principle

- `contracts-log.md` is the immutable record of declared contracts over time.
- `history-log.md` provides context for how contracts evolved.
- Code represents the current implementation state.
- `contracts-summary.md` is a derived projection representing the currently active contract set.

The summary must reconcile:

- Explicit supersession in contracts-log
- Evolution context in history-log
- Current enforcement state in code

`contracts-log.md` MUST NOT be modified or reinterpreted.

---

## Regenerate Contracts Summary

Analyze the full `/obelisk/contracts/contracts-log.md` and produce a reconciled projection that:

1. Includes contracts that are currently active (not explicitly superseded).
2. Consolidates duplicates or overlapping contracts without altering, expanding, or narrowing meaning.
3. Reflects enforcement state when relevant (e.g., active but unenforced).
4. Excludes contracts explicitly superseded by later entries.

---

**Write** (overwrite) `/obelisk/contracts/contracts-summary.md`:

```markdown
# Contracts Summary

Generated: YYYY-MM-DD

## System Identity
- [Consolidated current identity statements]

## Active Contracts
- [Each currently active contract]
- [Note if enforcement gaps are detected]

## Non-Goals
- [Consolidated explicit non-goals]

## Unprocessed

```

---

## Supersession

A contract is superseded if a later entry in contracts-log:

- Explicitly replaces or updates it
- Introduces a conflicting requirement in the same domain
- Eliminates the domain entirely

If uncertain, keep both and flag for review.

---

## Merging

Merge contracts that express the same constraint.

Do NOT merge:
- Orthogonal requirements (e.g., length vs symbol rules)
- Different actors or contexts (e.g., user vs admin)

When uncertain, do NOT merge.

---

## History & Code Usage

- contracts-log.md is the authoritative record of declared contracts.
- history-log.md provides context for how contracts evolved.
- Code reflects the current implementation state.

history-log and code do NOT override contracts-log.

If conflicts are detected:
- Trust contracts-log as declared intent.
- Reflect enforcement gaps or discrepancies in the summary.

---

## Rules

- contracts-log.md is authoritative.
- Remove contracts ONLY if explicitly superseded.
- Do NOT invent new contracts — only consolidate existing ones.
- Do not alter, expand, or narrow contract meaning during consolidation.
- If code does not enforce a contract, do NOT remove it — reflect the enforcement gap.
- Keep the summary concise (target <2000 tokens).
- `## Unprocessed` MUST exist (empty after regeneration).
