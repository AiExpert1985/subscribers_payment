# Task: Optimize Excel Import Performance for Large Files

## Goal
Eliminate UI freeze and significantly reduce total import time when processing Excel files with ~500,000 rows. The app currently freezes during import because parsing runs on the main thread, and saving is slow due to 500k individual database round-trips.

## Scope
✓ Included:
- Move Excel parsing to a background isolate (fix UI freeze)
- Replace row-by-row DB inserts with sqflite Batch committed in chunks (fix insert speed)
- Batch-load existing account numbers before the resolution loop (reduce N DB lookups to 1)
- Add live progress label visible in the import button area ("جاري الحفظ... X / Y")

✗ Excluded:
- Switching Excel parsing library
- Streaming row-by-row parsing (requires library change)
- Parallelising multi-file imports
- Progress during the parse phase (isolate returns all-at-once; label shows "جاري القراءة...")

## Constraints
- **Contract: Payment Immutability** — batch inserts use INSERT OR IGNORE; no existing payments are modified
- **Contract: Duplicate Prevention** — composite unique constraint still enforced at DB level; ConflictAlgorithm.ignore preserved
- **Design: SQLite / sqflite** — no new DB dependencies; use existing sqflite Batch API
- Isolate must receive only sendable data (file path as String — already the case)
- Progress callback must be optional (null-safe) to avoid breaking existing callers

## Execution Strategy
Move `ExcelParser.parseFile()` into a background isolate via `Isolate.run()` — this immediately unblocks the UI with zero parsing-logic changes. Replace the 500k-loop in `insertPaymentBatch` with sqflite `Batch` committed in chunks of 500 rows, reporting progress between chunks via an optional callback. Before the account-resolution loop, issue one query to load all existing account numbers and skip `findOrCreateAccountAndGroup` for those already known. Wire the progress callback through `ImportService.importFiles()` to the screen, where `setState` updates a single status string shown near the import button.

## Affected Area
- **Module / Feature:** Import pipeline
- **Entry points:** `ImportService.importFiles()`, `DatabaseService.insertPaymentBatch()`, `PaymentsScreen._importFiles()`
- **Notes:** `insertPaymentBatch` is called only from `ImportService` — safe to add optional parameter without touching other callers

## Open Questions
- None

---

## Contract-Changes
None.

## Design-Changes
**Date:** 2026-02-25
- Import pipeline runs Excel parsing in a background isolate; DB inserts use sqflite Batch in 500-row chunks with optional progress callback.

## Discovery-Summary
**Intent:** Fix two independent performance bottlenecks in the import pipeline — a UI-blocking synchronous parse and 500k individual DB round-trips — and surface a progress label to the user during the slow save phase.
**Key Decisions:**
- `Isolate.run()` preferred over `compute()` (no top-level function required; available since Dart 2.19/Flutter 3.7)
- Chunk size 500 rows per Batch commit (balances memory and progress granularity)
- Count inserted rows via before/after `COUNT(*)` queries (avoids `noResult: false` overhead on 500k batch results)
- Progress as `void Function(String)? onProgress` callback — minimal API change, no stream conversion needed

---

## Implementation Notes

### Execution Summary
Implemented as specified. All four scope items delivered across three files.

### Divergences
- Specified: keep `ExcelParser _parser` field
- Actual: removed `_parser` field from `ImportService` — field became unused after switching to `Isolate.run(() => ExcelParser().parseFile(path))`. Mechanical removal to eliminate compiler warning.

---

## Review

**Status:** APPROVED

1. Goal Achieved: ✔ — UI freeze eliminated: `import_service.dart:47` calls `await Isolate.run(() => ExcelParser().parseFile(path))`, moving all file I/O and CPU work off the main thread. DB insert speed fixed: `database_service.dart:244–258` uses sqflite `Batch` in 500-row chunks with `noResult: true`. Total import time further reduced by `getExistingAccountNumbers` skipping DB lookups for accounts already present.

2. Constraints Preserved: ✔ — `ConflictAlgorithm.ignore` retained on every `batch.insert()` call (`database_service.dart:250–254`), preserving both Payment Immutability and Duplicate Prevention contracts. No new dependencies added.

3. Scope Preserved: ✔ — Live progress label wired: `payments_screen.dart` shows `_importStatus` text beside the import button when `_isImporting && _importStatus != null`. Progress phases: "جاري قراءة الملف..." → "جاري معالجة الحسابات..." → "جاري الحفظ... X / Y". Switching Excel library, streaming parsing, and multi-file parallelism correctly excluded.

**Files Modified:**
- `lib/import/import_service.dart`
- `lib/data/database_service.dart`
- `lib/payments/payments_screen.dart`

**Notes:** Removed unused `_parser` field from `ImportService` — mechanical, no behavioral change.
