## System Baseline | Architectural Decisions

- **Platform**: Flutter desktop application, Windows primary target
- **Database**: SQLite (local file-based, single-user)
- **State Management**: Riverpod 3 (latest generation, not legacy)
- **Routing**: go_router
- **Language/Layout**: Arabic-only, full RTL layout
- **Structure**: Feature-first folder structure (`lib/payments/`, `lib/accounts/`, `lib/reports/`, `lib/data/`)

**Core Design Principles:**
1. Payments are immutable historical facts
2. Account-to-subscriber relationships are dynamic and editable
3. Mapping changes immediately reflect in searches and reports
4. Data integrity enforced at database level wherever possible
5. System must remain simple, maintainable, and deterministic
6. No hidden data transformations

**Data Model:**
- `subscriber_groups`: id, name (optional, editable)
- `accounts`: id, account_number (UNIQUE), subscriber_group_id (FK)
- `payments`: id, reference_account_number (no FK), amount, payment_date, stamp_number, subscriber_name, type, address
- `reference_account_number` stored exactly as in source; group mapping resolved dynamically at query time.

**UX Philosophy:**
- Arabic-only RTL interface
- Clean, compact layout
- Inline editing where appropriate
- Live filtering for instant feedback
- Minimal clutter — hover-reveal controls

---

## 2026-02-17 | Accounts Screen

- Bottom navigation bar introduced as app-level shell (Payments, Accounts, Reports)
- Accounts screen follows feature-first structure under `lib/accounts/`
- Inline editing for subscriber names and account numbers (tap to edit)
- Delete confirmation required for all destructive actions

---

## 2026-02-17 | Payments Screen with Excel Import

- Import is integrated into Payments screen (button), not a separate module
- `subscriber_name` in payments table is standalone (self-contained historical record), not resolved from subscriber_groups
- Pagination with server-side queries for 100k+ record performance
- Excel file is "successful" if it contains the 3 key columns (account_number, amount, date) via alias matching; other columns optional
- Multi-file and multi-tab (worksheet) import supported

---

## 2026-02-17 | Implement Reports Screen With Navigation and Printing

- Reports is a first-class app module/screen wired into app-level navigation
- Report input: one account number field, from/to date fields, generate action
- Printed output mirrors on-screen report data
- Report lookup starts from account number; missing account returns "user not found"
- If account exists, resolve subscriber group and include payments for all accounts in that group
- Empty from/to dates mean all-time period
- Subscriber display name in reports sourced from current `subscriber_groups.name`

---

## 2026-02-18 | Payments Screen Export to Excel

- Export scope is all filtered records (full dataset, not current page only)
- Save path determined by user via `file_picker.saveFile()` dialog
- Uses existing `excel` package; no new dependencies
- Export action lives in the payments feature module

---

## 20260218-1038 | Improve Payments Screen Layout, Interaction, and Data Fields

- Inline edit-on-click is the unified UX pattern for all app screens — no separate edit icon; clicking a field activates inline editing
- Search fields are positionally coupled to their columns (rendered above column header, matching column width)
- Date filter: two date-picker fields (from / to) side-by-side
- Row numbers are global sequence (page offset + local index), not per-page restart
- `payments` table: `address TEXT` column added; DB version incremented to 3
- `type` and `address` are optional (nullable) — not part of duplicate detection
- Import alias mapping extended to recognise `type` and `address` column headers

---

## 20260219 | Auto-assign new accounts to existing subscriber groups by name match

- Lookup order for unknown account: (1) exact-match existing group by non-empty name → assign; (2) no match or empty name → create new group
- Non-empty subscriber group names are unique at DB level (partial unique index where name != '')
- DB schema version incremented; migration adds the partial unique index

---

## 20260224-1335 | Filter Excel Import by Account Number Starting with 10

- Import filtering rule: account numbers must start with '10' (after trimming) to be imported; others silently skipped

---

## 20260225-0000 | Log Entire File Import Failures to Console

- Use `debugPrint` for debugging import failures; no file persistence or UI display

---

## 20260225-0937 | Update Import Headers, Add yyyyMMDD Date Format, Fix Filter Heights

- Import date parsing extended to support compact yyyyMMDD format (e.g., 20191029)
- Payment filter fields use uniform visual height via consistent padding/density settings

---

## 20260225-1200 | Optimize Excel Import Performance for Large Files

- Import pipeline runs Excel parsing in a background isolate (`Isolate.run()`)
- DB inserts use sqflite Batch in 500-row chunks with optional progress callback
- Inserted-row count: `COUNT(*)` before and after all chunks

---

## 20260302-0000 | Fix Excel Import Freeze and Add Console Progress Logging

- DB batch inserts chunked at 10,000 rows per commit (prevents event-loop blocking on large imports)
- `debugPrint` logs at each phase boundary for visibility

---

## 20260303-0000 | UI/UX Overhaul — Pagination, RTL Fixes, PDF, and Accounts Screen

- **defaultPageSize**: Changed from 50 → 20 (global, affects all paginated screens)
- **Pagination display**: "من X إلى Y" range (not page number); first/prev/next/last navigation; server-side LIMIT/OFFSET
- **RTL Row Layout Rule**: First child of a `Row` = rightmost on screen; last child = leftmost. Applied consistently: delete = last child (visual left); X reset and import/export = first children (visual right)
- **X Reset Button Pattern**: `SizedBox(width: fixedWidth, child: condition ? IconButton : null)` — fixed-width SizedBox always reserves space; button appears/disappears without layout shift. Icon: `Icons.close`, red, size 16
- **PDF RTL**: `pw.MultiPage` requires `textDirection: pw.TextDirection.rtl`. `pw.Row` has no `textDirection` param — achieve RTL visually by reversing children (value Expanded first = left, label SizedBox last = right). Table columns reversed for RTL reading order
- **Account chips**: Uniform `SizedBox(width: 130)` wrapper for layout stability on paging
- **Flutter Container rule**: Cannot combine `color:` property with `decoration:`. Color must go inside `BoxDecoration`
- **Accounts screen**: No hover pen/edit icon; inline tap-to-edit is the sole edit mechanism. Dual filters (name + account number). # row numbering (global offset + local index)
- **New DB methods**: `getSubscriberGroupsPaginated`, `getTotalSubscriberGroupCount`
- **New providers**: `currentAccountPageProvider`, `accountNameSearchQueryProvider`, `accountSearchQueryProvider`, `totalAccountGroupsProvider`, `totalAccountPagesProvider`

---
