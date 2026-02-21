## active-plan: Payments Screen with Excel Import

### Goal
Build the Payments screen as the main application view with paginated payment table, per-column search, inline editing, manual CRUD, and multi-file Excel import with duplicate detection.

### Initial Plan

**Approach:**
Update the data layer first (schema changes, new query methods), then build the import feature (column aliases, Excel parser, import orchestrator), then the payments screen UI (action bar, search, paginated table, inline editing), and finally wire everything together via Riverpod providers and update `main.dart`. Feature-first folder structure: `lib/import/` and `lib/payments/`.

**Affected Modules:**
- `lib/data/` — schema and model changes
- `lib/import/` — new import feature
- `lib/payments/` — new payments screen feature
- `lib/main.dart` — app shell update

**Files to modify:**
- `lib/data/database_service.dart` — add subscriber_name, rename collector_stamp, add paginated/filtered queries, batch insert, auto-create
- `lib/data/models/payment.dart` — add subscriberName, rename collectorStamp → stampNumber
- `lib/main.dart` — replace counter app with PaymentsScreen, RTL, Arabic
- `pubspec.yaml` — add excel, file_picker, intl packages

**Files to create:**
- `lib/import/column_aliases.dart` — hardcoded column name mappings
- `lib/import/excel_parser.dart` — Excel file parsing with multi-tab support
- `lib/import/import_service.dart` — import orchestration with auto-create and duplicate handling
- `lib/payments/payments_screen.dart` — main payments screen widget
- `lib/payments/add_payment_dialog.dart` — add payment dialog
- `lib/payments/payments_providers.dart` — Riverpod providers for payments state

**Key Steps:**
1. Update data layer (schema + model + new DB methods)
2. Create import feature (column aliases + parser + service)
3. Create payments screen UI with Riverpod providers
4. Update main.dart and pubspec.yaml
5. Verify compilation and manual testing

**Constraints:**
- Preserve contracts (payment immutability, duplicate prevention, auto-create)
- Respect design (RTL, Arabic-only, clean compact layout)
- Do not expand scope (no accounts/reports screens, no navigation)

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Implemented exactly as planned — data layer first (schema v2 with subscriber_name and stamp_number rename, paginated/filtered queries, batch insert), then import feature (column aliases, multi-tab Excel parser, import orchestrator with auto-create), then payments screen UI (action bar, per-column search with debounce, paginated DataTable with inline editing, delete with confirmation, add payment dialog, footer), and finally app shell (RTL, Arabic theme). Used Riverpod legacy StateProvider for simple state holders. Fixed 3 minor lint issues post-implementation.

**Deferred items:** None — all planned items completed.
