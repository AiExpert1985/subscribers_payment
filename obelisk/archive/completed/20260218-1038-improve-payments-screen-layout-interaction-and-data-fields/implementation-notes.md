## active-plan: Improve Payments Screen Layout, Interaction, and Data Fields

### Goal
Overhaul the payments screen UX and surface `type` (already in DB) and new `address` field across table, search, add/edit form, import, and export.

### Initial Plan

**Approach:**
Replace the DataTable with a custom Row-based table layout that gives full control over column widths, hover effects, and button placement. Each row (search, header, data) uses the same `Expanded(flex: N)` + fixed-width `SizedBox` children so columns align perfectly. `MouseRegion` on each data row drives the hover highlight and allows per-cell `Tooltip` for "تعديل". Date search splits into two `DatePicker` fields using a `LayoutBuilder` to stack them when narrow. The `address` field requires a DB migration (version 2→3). The `type` field is already in the DB schema and model; it only needs to be surfaced in the UI, import, and export.

**Affected Modules:**
- `lib/data/database_service.dart` — DB migration + where-clause date-range handling
- `lib/data/models/payment.dart` — add `address` field
- `lib/payments/payments_screen.dart` — full layout/interaction rewrite
- `lib/payments/add_payment_dialog.dart` — add type and address fields
- `lib/payments/payment_export_service.dart` — add type and address columns
- `lib/import/column_aliases.dart` — add type and address aliases
- `lib/import/excel_parser.dart` — detect and parse type and address columns

**Files to modify:**
- `lib/data/database_service.dart` — bump version to 3, add address migration, update `_buildWhereClause` for `payment_date_from`/`payment_date_to`
- `lib/data/models/payment.dart` — add `address` field throughout
- `lib/payments/payments_screen.dart` — complete rewrite of table and interaction
- `lib/payments/add_payment_dialog.dart` — add type and address TextFormFields
- `lib/payments/payment_export_service.dart` — add النوع and العنوان to headers/rows
- `lib/import/column_aliases.dart` — add `typeAliases` and `addressAliases`
- `lib/import/excel_parser.dart` — extend `_ColumnMapping`, `_findColumnMapping`, `_parseRow`

**Files to create:**
- None

**Key Steps:**
1. DB migration: bump to v3, add `address TEXT` column via ALTER TABLE
2. Update `_buildWhereClause` to handle date-range keys with `>=`/`<=` instead of LIKE
3. Add `address` to Payment model (constructor, fromMap, toMap, copyWith, ==, hashCode)
4. Rewrite `payments_screen.dart`: custom table layout with search row above headers, delete button first (rightmost in RTL), row numbers, hover effect, inline edit-on-click, date-picker search, Add button in header row, reduced row padding, reversed pagination icons
5. Add type and address fields to `add_payment_dialog.dart`
6. Add type and address columns to export service
7. Add type and address column alias lists and wire into excel_parser

**Constraints:**
- Preserve contracts
- Respect design
- Do not expand scope

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Custom Row-based table replacing DataTable — each row (search, header, data) uses identical `Expanded(flex)` + fixed `SizedBox` children so columns align perfectly. `LayoutBuilder` + `SingleChildScrollView(horizontal)` + `ConstrainedBox(minWidth)` handles both responsive fill and horizontal overflow. `MouseRegion` per data row drives hover highlight; `Tooltip(message: 'تعديل')` on each cell handles per-field edit hint. Date range search uses two `InkWell` date-picker fields with a `LayoutBuilder` narrow-stack fallback. DB migrated to v3 with `address TEXT` column; `_buildWhereClause` extended with `>=`/`<=` for `payment_date_from`/`payment_date_to` keys. `type` and `address` wired through model, screen, dialog, export, import aliases, and parser.

**Deferred items:** None
