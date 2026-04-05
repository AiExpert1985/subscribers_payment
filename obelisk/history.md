## 2026-02-17 | Payments Screen with Excel Import | APPROVED

---

## 2026-02-17 | Fix databaseFactory Not Initialized on Windows | APPROVED

---

## 2026-02-17 | Accounts Screen | APPROVED

---

## 2026-02-17 | Implement Reports Screen With Navigation and Printing | APPROVED

---

## 2026-02-18 | Payments Screen Export to Excel | APPROVED

---

## 20260218-1038 | Improve Payments Screen Layout, Interaction, and Data Fields | APPROVED

---

## 20260219 | Auto-assign new accounts to existing subscriber groups by name match | APPROVED

---

## 20260225-0000 | Log entire file import failures to the console | APPROVED

**Intent:** To improve developer visibility into why an Excel file import fails entirely by outputting a concise failure reason to the debug console.
**Key Decisions:** Log only file-level failures. Use `debugPrint`. Output only necessary information.
**Rejected / Deferred:** Row-level logging was rejected by the user.

---

## 20260225-1200 | Optimize Excel Import Performance for Large Files | APPROVED

**Intent:** Fix two independent performance bottlenecks in the import pipeline — a UI-blocking synchronous parse and 500k individual DB round-trips — and surface a progress label to the user during the slow save phase.
**Key Decisions:**
- `Isolate.run()` preferred over `compute()` (no top-level function required; available since Dart 2.19/Flutter 3.7)
- Chunk size 500 rows per Batch commit (balances memory and progress granularity)
- Count inserted rows via before/after `COUNT(*)` queries (avoids `noResult: false` overhead on 500k batch results)
- Progress as `void Function(String)? onProgress` callback — minimal API change, no stream conversion needed

---

## 20260302-0000 | Fix Excel Import Freeze and Add Console Progress Logging | APPROVED

**Intent:** The app freezes on 500k-row imports because all rows are committed in a single `batch.commit()` on the Dart main isolate, blocking the event loop. The fix chunks commits so the event loop can process UI frames between chunks. Console `debugPrint` logs with timestamps are added at each phase boundary to give full visibility into where time is spent.
**Key Decisions:**
- Chunk size: 10,000 rows (50 chunks for 500k rows — frequent enough for feedback, not so small it adds overhead)
- Progress: `debugPrint` only, no UI changes
- Inserted-row count: single `COUNT(*)` before and after all chunks (unchanged approach, just relocated outside the chunk loop)

---

## 20260303-0000 | UI/UX Overhaul — Pagination, RTL Fixes, PDF, and Accounts Screen | APPROVED

**Intent:** Unify and improve UI/UX across all three screens with consistent pagination (20 rows, range display, first/last/prev/next), RTL-correct action bar layouts, dual filters on Accounts, a uniform X reset button pattern, and correct Arabic PDF rendering.
**Key Decisions:**
- RTL Row rule: first child = rightmost (X reset, import/export); last child = leftmost (delete, add-payment)
- X reset: `SizedBox(fixedWidth, child: condition ? button : null)` — preserves layout width while toggling visibility
- PDF RTL: `pw.MultiPage(textDirection: rtl)` + reversed `pw.Row` children (pw.Row has no textDirection param) + reversed table columns
- defaultPageSize 50 → 20 globally; both screens use server-side LIMIT/OFFSET pagination
- Flutter `Container` cannot have both `color:` and `decoration:` — color moved into `BoxDecoration`
- Account chips fixed at 130px width for layout stability

---

## 20260224-1335 | Filter Excel Import by Account Number Starting with 10 | APPROVED

**Intent:** Filter out irrelevant payment rows during Excel import based on account number prefix.
**Key Decisions:**
- Filter condition: Account number starts with "10".
- Pre-processing: Trim spaces from account number before checking.
- UX Impact: Skipped rows are handled silently without notifying the user.
**Rejected / Deferred:**
- Summarizing skipped rows to the user (rejected to keep UI simple).

---

## 20260303-0100 | Accounts Chip Width, PDF Centering, and Column Headers | TASK

Three targeted UI fixes: account chips widened 130→160px for longer numbers; PDF report header centered and info lines converted to single centered RTL text lines; Accounts screen gained static column headers (#, اسم المشترك, ارقام الحساب) aligned to row layout.

---

## 20260303-1226 | Payment / Subscriber Full Separation | TASK

Fully decoupled payments from subscribers. Removed auto-creation of accounts/groups from payment import (eliminating N×3 per-account DB round-trips). Added "Import Accounts" to the Accounts screen: Excel with old→new account columns maps new accounts onto existing groups, with a result dialog showing success count + error table exportable to Excel. Contract 5 replaced with "Payment Isolation"; Contract 8 added for Account Import.

---

## 20260304-1133 | UI Fixes — Payment Inline Editing, Button Color, Report Filter Height | TASK

Empty/null cells in the payments table were unresponsive to click on Flutter desktop because `GestureDetector` only hit-tests visible pixels and `Text('')` renders none; fixed with `HitTestBehavior.opaque` + `minHeight: 36`. Import Accounts button color normalized to app theme primary (removed teal override). Report screen date filter fields aligned in height to the account number field via `isDense: true` + matching `contentPadding`.

---

## 20260304-1358 | Settings Tab, Subscribers Export, Payment Import Aliases | TASK

Added a Settings tab (4th nav item) with two protected data-reset actions (Reset Accounts, Reset Payments), each requiring the user to type "reset" before activating. Added a subscribers Excel export to the Accounts screen (one row per group: ID, name, accounts horizontally). Extended payment import alias map with o_accountno, o_date, o_amount, o_txtusern for legacy source compatibility.

---

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

## 20260303-0100 | Accounts Chip Width, PDF Centering, and Column Headers

- Account chips: 130px → 160px (line 57 row-description still says "uniform 130px" — reconcile on next maintain-project run)
- Accounts screen: static column header row added above ListView; headers: #, اسم المشترك, ارقام الحساب
- PDF `_pdfLine`: replaced 2-column Row layout with `pw.Center(pw.Text('$title: $value', textAlign: center, textDirection: rtl))`
- PDF table: columns in natural order (رقم الحساب → رقم الختم); `cellAlignment` and `headerAlignment` → `pw.Alignment.center`
- PDF header: wrapped in `pw.Center`

---

## 20260303-1226 | Payment / Subscriber Full Separation

- `ImportService` strip: removed account-collection loop and `findOrCreateAccountAndGroup` calls; payment import is now parse → batch-insert only
- New `AccountImportParser`: same alias-matching pattern as `ExcelParser`; 2-column Excel (old/new account numbers)
- New `AccountImportService`: plain class injected with `DatabaseService`; error model carries `oldAccount?`, `newAccount?`, `reason` (Arabic string) used for both dialog display and Excel export
- Excel error export uses existing `excel` package + `FilePicker.saveFile`; `excel.Border` conflict resolved with `hide Border` on import
- `_TableCell` defined as a private file-level widget (not inside state class) to support `const` in table children

---

## 20260304-1358 | Settings Tab, Subscribers Export, Payment Import Aliases

- New `lib/settings/` feature folder with `SettingsScreen` (ConsumerWidget; no local state)
- Reset protection: `_ConfirmResetDialog` (private StatefulWidget) — delete button disabled until `TextEditingController` matches "reset" (case-insensitive); no secondary confirmation click needed
- `BottomNavigationBarType.fixed` required when nav bar has 4+ items
- `SubscribersExportService` in `lib/accounts/` — same pattern as `PaymentExportService`; variable-width rows (account columns expand horizontally per group)
- `getAllGroupsWithAccounts()` uses sequential per-group queries (N+1), consistent with existing `subscriberGroupsProvider` approach
- Hot-reload from 3→4 `IndexedStack` children causes `_AssertionError`; requires full app restart

---

Generated: 2026-03-03

## System Identity

Payment consolidation system for 11+ years of Excel-based historical payment records. Arabic-only, single-user, Windows desktop application.

## Active Contracts

**1. Payment Immutability**
Payment records are never auto-modified or auto-deleted. Only explicit manual user action (edit/delete) can change a payment record. No system process, import, or mapping change may alter existing payment data.

**2. Duplicate Prevention**
A payment is duplicate when the combination of `reference_account_number` + `payment_date` + `amount` already exists. Duplicates must be rejected during import and manual entry. Enforced via composite unique index at database level.

**3. Global Account Uniqueness**
Each `account_number` exists exactly once across all subscriber groups. Enforced via unique constraint at database level.

**4. Dynamic Mapping Resolution**
Account-to-subscriber-group mapping changes immediately affect all searches, reports, and display. Mapping changes never modify stored payment records.

**5. Payment Isolation**
Payment import and manual payment entry store `reference_account_number` as a raw fact only. No account or subscriber group is ever created, modified, or looked up during any payment operation. Payments and subscribers are fully decoupled in both directions.

**6. Subscriber Group Name Uniqueness**
Non-empty subscriber group names must be unique across all groups. Enforced at database level via partial unique index (`WHERE name != ''`). Prevents ambiguous group resolution during auto-assign.

**7. Delete Confirmation**
All destructive delete actions (group, account, payment) must present a confirmation dialog before executing. No silent deletes.

**8. Account Import (Accounts screen only)**
An Excel or CSV file with columns `الحساب القديم` / `الحساب الجديد` and an optional `اسم المشترك` can be imported from the Accounts screen. For each row:
- Old exists, new doesn't → new account added to old's group.
- Old exists, new already exists → skipped with error "الحساب الجديد موجود مسبقاً".
- Old doesn't exist, new doesn't exist → new subscriber group created; both accounts inserted into it.
- Old doesn't exist, new already exists → old account added to new's group; new is not re-inserted.
If `اسم المشترك` is present and non-empty, the target group's name is overwritten. A blank/missing name cell leaves the group name unchanged. Rows with invalid/missing required cell values are skipped. All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الحساب القديم, الحساب الجديد, السبب).

**Deletion Rules:**
- Delete subscriber group: Cascade deletes all accounts in the group. Never touches payments table.
- Delete account: Removes from group. Payments referencing it remain unchanged (become "unmapped").
- Delete payment: Manual user action only.

## Non-Goals

- Multi-language support (Arabic only)
- Audit trail or change history
- Multi-user or concurrent access
- Cloud sync, backup, or replication
- Automatic data backup mechanisms


Generated: 2026-03-03

## System Identity

Payment consolidation system for 11+ years of Excel-based historical payment records. Arabic-only, single-user, Windows desktop application.

## Active Contracts

**1. Payment Immutability**
Payment records are never auto-modified or auto-deleted. Only explicit manual user action (edit/delete) can change a payment record. No system process, import, or mapping change may alter existing payment data.

**2. Duplicate Prevention**
A payment is duplicate when the combination of `reference_account_number` + `payment_date` + `amount` already exists. Duplicates must be rejected during import and manual entry. Enforced via composite unique index at database level.

**3. Global Account Uniqueness**
Each `account_number` exists exactly once across all subscriber groups. Enforced via unique constraint at database level.

**4. Dynamic Mapping Resolution**
Account-to-subscriber-group mapping changes immediately affect all searches, reports, and display. Mapping changes never modify stored payment records.

**5. Payment Isolation**
Payment import and manual payment entry store `reference_account_number` as a raw fact only. No account or subscriber group is ever created, modified, or looked up during any payment operation. Payments and subscribers are fully decoupled in both directions.

**6. Subscriber Group Name Uniqueness**
Non-empty subscriber group names must be unique across all groups. Enforced at database level via partial unique index (`WHERE name != ''`). Prevents ambiguous group resolution during auto-assign.

**7. Delete Confirmation**
All destructive delete actions (group, account, payment) must present a confirmation dialog before executing. No silent deletes.

**8. Account Import (Accounts screen only)**
An Excel or CSV file with columns `الحساب القديم` / `الحساب الجديد` and an optional `اسم المشترك` can be imported from the Accounts screen. For each row:
- Old exists, new doesn't → new account added to old's group.
- Old exists, new already exists → skipped with error "الحساب الجديد موجود مسبقاً".
- Old doesn't exist, new doesn't exist → new subscriber group created; both accounts inserted into it.
- Old doesn't exist, new already exists → old account added to new's group; new is not re-inserted.
If `اسم المشترك` is present and non-empty, the target group's name is overwritten. A blank/missing name cell leaves the group name unchanged. Rows with invalid/missing required cell values are skipped. All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الحساب القديم, الحساب الجديد, السبب).

**Deletion Rules:**
- Delete subscriber group: Cascade deletes all accounts in the group. Never touches payments table.
- Delete account: Removes from group. Payments referencing it remain unchanged (become "unmapped").
- Delete payment: Manual user action only.

## Non-Goals

- Multi-language support (Arabic only)
- Audit trail or change history
- Multi-user or concurrent access
- Cloud sync, backup, or replication
- Automatic data backup mechanisms


## 20260308-0100 | Unmatched Accounts in Settings | TASK

**Task:** Add a Settings action that surfaces all payment account numbers not registered under any subscriber, shows a count in a result dialog, and allows exporting them to Excel.

**Design:** DB query uses `NOT IN (SELECT account_number FROM accounts)` — no application-side set diff. Export follows the existing single-column Excel pattern via a dedicated `UnmatchedAccountsExportService` in `lib/settings/`. Zero-unmatched case shows a success message with no export button.

---

## 20260308-0000 | CSV Import Support | TASK

**Task:** Add CSV as an accepted import format for payments to resolve severe performance issues with the `excel` package on 500k-row files.

**Design:** `CsvParser` returns the existing `ExcelParseResult` type so the import pipeline requires no structural changes. Delimiter is auto-detected from the header line (comma / semicolon / tab). Routing is handled inside the existing top-level `_parseFile` function via an extension check. The `csv` package (already a dependency) is used with `shouldParseNumbers: false` for uniform string-based value parsing.

**Rejected:** `syncfusion_flutter_xlsio` — write-only in Flutter (no read/parse support), requires commercial license registration, no performance advantage over the existing `excel` package.

---

## 20260309-0000 | Fix Account Import — Decimal Parsing, CSV Support, Error Messages, Dialog Overflow | TASK

**Task:** Account import silently skipped every row because Excel serialises integers as decimal text (e.g. "1001.0") and the parser only tried `int.tryParse`. Fixed alongside: CSV file support added to account import, error messages improved to show the failing column and raw value, and the result dialog restructured to eliminate overflow caused by an unbounded list of parse-error text items.

**Rejected:** None.

---

## 20260309-0100 | Account Import — Create Group When Old Account Missing | TASK

**Task:** Account import was erroring "الحساب القديم غير موجود" and skipping rows when the old account didn't exist in the DB. Changed to a four-case routing: old+new both absent → create new group with both; old absent but new exists → add old to new's group. Existing cases (old exists) are unchanged.

**Rejected:** None.

---

## 20260309-0200 | Account Import — Flexible N-Column Account Detection | TASK

**Task:** Replace the fixed two-column (old/new) import model with a flexible N-column model. Any column whose header contains a known account keyword (partial, case-insensitive) is treated as an account column, enabling single-column file imports. Per-row routing uses four cases keyed by the number of distinct existing DB groups: conflict (>1), create new (0), add to existing (1 with absent accounts), or silent skip (all already in same group). Error display and export updated to show account numbers as a joined list with a single reason column.

**Rejected:** None.

---

## 20260309-0300 | Account Import — Expanded Column Header Keywords | TASK

**Task:** Expanded the account-number and subscriber-name keyword lists in the account import parser to match a broader set of real-world column headers. Added "حساب", "قديم", "جديد", "account no" to account keywords and "اسم" to name aliases. No routing or pipeline logic changed.

**Rejected:** None.

---

## 20260309-0400 | Account Import — Name Update on Silent Skip & Settings About Section | TASK

**Task:** Two improvements: (1) the account import "all already in same group" silent-skip case now applies a name update if a non-empty subscriber name is present (uniqueness conflicts silently ignored); (2) a static Arabic About section was added to the bottom of the Settings screen displaying program title and authorship credit.

**Rejected:** None.

---

## 20260310-0000 | User-Editable Import Column Aliases via Settings | TASK

**Task:** Replace hardcoded column header aliases in both import pipelines with a user-managed SQLite table so users can add, remove, and reset aliases per field from the Settings screen without rebuilding the app. Account import detection changed from substring to exact match as part of the same change.

---

## 20260310-1200 | Settings Screen — Unify Content into Dialog Buttons | TASK

**Task:** Replace inline alias sections and About block in the Settings screen with buttons that open dialogs, and give the alias buttons section a title and description consistent with the other action sections.

**Rejected:** Single combined alias button (rejected in favour of two separate buttons, one per import type).

---

## 20260310-1400 | Top Bar UI Refresh — Action Bars, Button Layout, Tab Bar Color | TASK

**Task:** Wrapped action buttons on both Payments and Accounts screens in a styled full-width top bar container to visually separate controls from data. Accounts screen button order was corrected to match Payments (import/export right, add-new far left). Bottom navigation bar updated to a light teal palette.

**Rejected:** Moving filter/search fields into the top bar — kept column-aligned inside the table to preserve the visual column-to-filter relationship.

---
