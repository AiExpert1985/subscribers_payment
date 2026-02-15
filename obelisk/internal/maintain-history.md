---
description: Compact logs and regenerate history summary
---
**CURRENT STATE: MAINTENANCE**

Compact history log, then regenerate summary.

---

## Preflight

Required:

- `/obelisk/history-log.md`
- `/obelisk/history-summary.md`

Missing → **STOP. Show error.**


---

## Stage 1: Process Unprocessed History

Read `/obelisk/history-summary.md`.

1. Move all entries from `## Unprocessed` in `history-summary.md` → append to end of `/obelisk/history-log.md`
2. Clear the `## Unprocessed` section in `history-summary.md`


---

## Stage 2: Regenerate History Summary


Analyze the full `/obelisk/history-log.md` and generate a fresh summary.

**Write** (overwrite) `/obelisk/history-summary.md`:

```markdown
# History Summary

Generated: YYYY-MM-DD

## Project Timeline
- [Key milestones and major decisions, chronologically]

## Recent Activity
- [Last 3–5 significant tasks with outcomes]

## Active Patterns
- [Recurring themes, deferred items still pending, ongoing concerns]

## Unprocessed
```

**Rules:**

- Active Patterns must be directly observable from recurring entries in history-log.
- Merge only if later entry explicitly supersedes earlier entry.
- Drop deferred items only if explicitly marked as resolved in a later history-log entry.
- Preserve all unresolved deferred items
- Keep it concise — target under 2000 tokens
- `## Unprocessed` section MUST exist (empty after regeneration)

