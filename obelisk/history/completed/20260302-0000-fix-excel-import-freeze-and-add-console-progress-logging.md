# Task: Fix Excel Import Freeze and Add Console Progress Logging

## Goal
Prevent the app from freezing during large Excel imports (500k rows) by chunking the database batch commits, and add `debugPrint` timestamps at each pipeline phase so progress is visible in the console.

## Scope
✓ Included:
- Chunked batch DB inserts in `insertPaymentBatch` (break 500k rows into chunks, await each chunk separately so the event loop can breathe between them)
- `debugPrint` logs with wall-clock timestamps at: parse start, parse complete (with row count), account processing start/end, DB save start, per-chunk progress, and save complete
- Consolidate the two `COUNT(*)` queries: one before all chunks + one after all chunks

✗ Excluded:
- UI progress changes (no on-screen counter or new widgets)
- Parsing logic changes
- New dependencies
- Any changes outside `import_service.dart` and `database_service.dart`

## Constraints
- **Design: Background isolate** — parsing via `compute()` stays unchanged
- **Design: Simple over clever** — no new abstractions; minimal changes to existing signatures
- **Technical** — sqflite `batch.commit()` is async; chunking + awaiting each chunk yields the Dart event loop between chunks, which prevents UI freeze and allows progress labels to update

## Execution Strategy
In `database_service.dart`: split the payments list into chunks of 10,000 rows; create and commit one `Batch` per chunk, awaiting each. Keep a single `COUNT(*)` before + after all chunks to compute inserted count. Accept an optional `onProgress` callback `void Function(int saved, int total)?` called after each chunk.

In `import_service.dart`: add `debugPrint` with `DateTime.now()` at every significant phase transition — before `compute()`, after parse returns (log row count and duration), before account processing, after account processing, before DB save, after each chunk via the callback, and after save completes (log final inserted count and total duration).

## Affected Area
- **Module / Feature:** Import pipeline
- **Entry points:** `import_service.dart`, `database_service.dart`
- **Notes:** None — no contract-sensitive spots touched

## Open Questions
- None

---

## Contract-Changes
None.

## Design-Changes
**Date:** 2026-03-02
- DB batch inserts are chunked at 10,000 rows per commit (previously one commit for the entire file) to prevent event-loop blocking on large imports.

## Discovery-Summary
**Intent:** The app freezes on 500k-row imports because all rows are committed in a single `batch.commit()` on the Dart main isolate, blocking the event loop. The fix chunks commits so the event loop can process UI frames between chunks. Console `debugPrint` logs with timestamps are added at each phase boundary to give full visibility into where time is spent.
**Key Decisions:**
- Chunk size: 10,000 rows (50 chunks for 500k rows — frequent enough for feedback, not so small it adds overhead)
- Progress: `debugPrint` only, no UI changes
- Inserted-row count: single `COUNT(*)` before and after all chunks (unchanged approach, just relocated outside the chunk loop)

---

## Implementation Notes

### Execution Summary
Implemented as specified. No scope changes.

**`database_service.dart` — `insertPaymentBatch`:**
- Added optional `onProgress` callback parameter: `void Function(int saved, int total)?`
- Replaced single `batch.commit()` with a `for` loop over 10,000-row chunks; each chunk creates its own `Batch`, commits, then calls `onProgress`
- `COUNT(*)` before/after queries remain in place, now wrapping the entire chunk loop

**`import_service.dart` — `importFiles`:**
- Added `Stopwatch` per file, started before `compute()` call
- Added `debugPrint` at 6 phase boundaries: parse started, parse complete (row count + ms), account processing (unique account count + ms), accounts ready (ms), DB save started (row count + ms), per-chunk saved progress (saved/total + ms), and final done (inserted, duplicates, total ms)
- Wired `onProgress` callback from `insertPaymentBatch` to emit per-chunk `debugPrint`
- Extracted `fileName` from path using `split(RegExp(r'[\\/]'))` for clean log prefixes

### Divergences
Implemented as specified. No divergences.

---

## Review

**Status:** APPROVED

1. Goal Achieved: ✔ — `insertPaymentBatch` in `database_service.dart:231-263` chunks commits at 10,000 rows; each `await batch.commit()` yields the event loop. `debugPrint` logs at 6 phase boundaries with elapsed ms in `import_service.dart:51-115`.
2. Constraints Preserved: ✔ — `compute()` call unchanged; `Stopwatch` is dart:core (no new deps); no new abstractions introduced; only the two specified files modified.
3. Scope Preserved: ✔ — Only `import_service.dart` and `database_service.dart` touched; no UI files, no parsing logic, no pubspec changes.

**Files Modified:**
- `lib/import/import_service.dart`
- `lib/data/database_service.dart`

**Notes:** None.
