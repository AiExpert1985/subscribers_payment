# Design Summary

Generated: 2026-03-03

## System Architecture

- **Platform**: Flutter desktop, Windows primary target
- **Database**: SQLite, local file-based, single-user (sqflite)
- **State Management**: Riverpod 3 (FutureProvider, StateProvider)
- **Routing**: go_router
- **Language/Layout**: Arabic-only, full RTL layout
- **Structure**: Feature-first (`lib/payments/`, `lib/accounts/`, `lib/reports/`, `lib/data/`)
- **Navigation**: Bottom navigation bar as app-level shell (Payments, Accounts, Reports)

## Data Model

| Table | Key Columns |
|---|---|
| `subscriber_groups` | `id` PK, `name` (optional, editable, non-empty values unique) |
| `accounts` | `id` PK, `account_number` (UNIQUE), `subscriber_group_id` FK |
| `payments` | `id` PK, `reference_account_number` (no FK), `amount`, `payment_date`, `stamp_number`, `subscriber_name`, `type`, `address` |

`reference_account_number` stored exactly as found in source. Mapping to subscriber groups resolved dynamically at query time — never stored.

## Core Design Principles

1. Payments are immutable historical facts
2. Account-to-subscriber relationships are dynamic and editable
3. Mapping changes immediately reflect in searches and reports
4. Data integrity enforced at database level wherever possible
5. System must remain simple, maintainable, and deterministic
6. No hidden data transformations

## Modules

**Import** (integrated into Payments screen)
- Excel file import: multi-file, multi-tab, column alias matching
- Required columns: account_number, amount, date; optional: subscriber_name, stamp_number, type, address
- Filter: only account numbers starting with '10' (after trim) are processed; others silently skipped
- Auto-assign unknown accounts to groups by exact subscriber name match; create new group if no match
- Duplicate detection on (reference_account_number, payment_date, amount)
- Parse runs in background isolate; DB inserts in 10,000-row chunks to avoid event-loop blocking
- Progress via `debugPrint` only; file-level failures logged with `debugPrint`

**Payments Screen**
- Server-side paginated table: 20 rows/page; pagination shows "من X إلى Y" with first/prev/next/last
- Multi-column search (AND logic, positionally coupled to columns): account, subscriber name, amount, date range, stamp, type, address
- X reset button: `SizedBox(36px, child: condition ? Icons.close red : null)` — first child (visual right)
- Action bar: import/export (first = far right), add-payment (last = far left)
- Inline tap-to-edit for all fields; delete with confirmation (last child = visual left)
- Export: full filtered dataset (not page-only) via file_picker save dialog

**Accounts Screen**
- Server-side paginated list: 20 rows/page; "من X إلى Y" display
- Dual filter: subscriber name + account number (both server-side LIKE queries)
- X reset button as first child (visual right); appears only when a filter is active
- Each row: # number, subscriber name (inline editable), account chips (uniform 130px), delete (last child = visual left)
- No hover pen/edit icon — inline tap-to-edit only
- Account chips 130px wide for stable layout across pages
- Delete group cascades to accounts; delete confirmation always required
- New DB methods: `getSubscriberGroupsPaginated`, `getTotalSubscriberGroupCount`
- New providers: `currentAccountPageProvider`, `accountNameSearchQueryProvider`, `accountSearchQueryProvider`, `totalAccountGroupsProvider`, `totalAccountPagesProvider`

**Reports Screen**
- Input: account number + optional date range; all in one row with X reset (first child = visual right)
- Lookup: account → subscriber group → all accounts in group → all matching payments
- Display: subscriber name, all account numbers, period, total amount, payments table
- PDF print: `pw.MultiPage(textDirection: pw.TextDirection.rtl)`; `pw.Row` has no textDirection param — RTL achieved by reversing children manually; table columns reversed for RTL reading order

## UX Patterns

- **RTL Row Rule**: First child = rightmost on screen; last child = leftmost. Consistently applied: delete = last child; X reset and import/export = first children.
- **X Reset Button**: `SizedBox(width: fixedWidth, child: condition ? button : null)` — always reserves width, preventing layout shift on toggle.
- **Inline editing**: Tap-to-edit on all editable fields; no separate edit icons anywhere.
- **Pagination**: 20 rows/page, "من X إلى Y" range label, first/prev/next/last buttons.
- **Container color rule**: Flutter `Container` cannot combine `color:` and `decoration:` — color must be inside `BoxDecoration`.

## Open Design Questions

_(none)_

## Unprocessed
