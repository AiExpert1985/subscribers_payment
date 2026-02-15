## Database Schema Implementation | 2026-02-15

**Summary:**
- Implement SQLite database with 3 tables, Dart models, and Riverpod 3 integration

**Decisions:**
- Account numbers stored as INTEGER (not TEXT)
- Amounts stored as REAL with 3 decimal precision
- Dates stored as INTEGER timestamps
- Payments table has two additional fields: `type` and `collector_stamp` (both separate text fields)
- ON DELETE CASCADE: when subscriber_group deleted, cascade to accounts but leave payments untouched
- No runtime UI verification needed (app compilation sufficient for now)

**Deferred:**
- CRUD UI screens
- Excel import logic
- Search/reporting functionality
