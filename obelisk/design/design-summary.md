# Design Summary

Generated: 2026-02-16

## System Architecture
_(empty — populated after maintenance)_

## Data Model
_(empty — populated after maintenance)_

## Core Design Principles
_(empty — populated after maintenance)_

## Modules
_(empty — populated after maintenance)_

## Open Design Questions
_(empty — populated after maintenance)_

## Unprocessed

### 2026-02-17 | Accounts Screen

**Architecture / Design:**
- Bottom navigation bar introduced as app-level shell (Payments, Accounts, future Reports)
- Accounts screen follows feature-first structure under `lib/accounts/`
- Inline editing for both subscriber names and account numbers (tap to edit)

**Business Logic:**
- Delete confirmation required for all destructive actions (new contract)
- Search by account number resolves to containing subscriber group

---

### Architectural Decisions

- **Platform**: Flutter desktop application, Windows primary target
- **Database**: SQLite (local file-based, single-user)
- **State Management**: Riverpod 3 (latest generation, not legacy)
- **Routing**: go_router
- **Language/Layout**: Arabic-only, full RTL layout

### Core Design Principles

1. Payments are immutable historical facts
2. Account-to-subscriber relationships are dynamic and editable
3. Mapping changes immediately reflect in searches and reports
4. Data integrity enforced at database level wherever possible
5. System must remain simple, maintainable, and deterministic
6. No hidden data transformations

### Data Model

**subscriber_groups** — represents one logical subscriber entity
- `id` (PK, auto-generated)
- `subscriber_name` (String, optional, editable)

**accounts** — represents account numbers and their grouping
- `id` (PK, auto-generated)
- `account_number` (String, UNIQUE, required)
- `subscriber_group_id` (FK → subscriber_groups.id, required)

**payments** — represents historical payment records
- `id` (PK, auto-generated)
- `reference_account_number` (String, required, no FK)
- `amount` (Decimal, required)
- `payment_date` (Date, required)
- `stamp_number` (String, optional)
- `subscriber_name` (String, optional — preserved from import source)
- `type` (String, optional)

**Key design**: `reference_account_number` stored exactly as found in source. Mapping to subscriber groups resolved dynamically at query time.

### Modules

**Import Screen**
- Import payments from structured Excel files
- Column matching via predefined alias mapping (account, amount, date, stamp, subscriber name)
- Auto-create subscriber group + account for unknown account numbers
- Duplicate detection during import

**Payments Screen**
- Table view: reference account, resolved subscriber name, amount, date, stamp number
- Live multi-column search (AND logic, ignore empty fields)
- Account number search includes all accounts in same group
- Manual CRUD operations (add, edit, delete)
- Date range filter
- Print and export filtered view to Excel

**Accounts Screen**
- Table-like list: each row = one subscriber group
- Shows subscriber name + inline account numbers (tags/pills)
- Group-level: add group (subscriber name only, auto-assigns ID), delete group (cascades to accounts)
- Account-level: add account to group, edit account number, delete account
- Search by account number → shows containing group
- Hover controls for edit/delete on account elements

**Reports Screen**
- Input: account number + date range (default: all time)
- Resolves group → fetches all accounts in group → fetches all matching payments
- Header: subscriber name, all account numbers, period, total amount
- Body: detailed payments table
- Footer: generated date/time
- Print capability
- Error "account not found" if account doesn't exist

### UX Philosophy

- Arabic-only RTL interface
- Clean, compact layout
- Inline editing where appropriate
- Live filtering for instant feedback
- Minimal clutter — hover-reveal controls

### Open Design Questions

_(none)_

## 2026-02-17 | Payments Screen with Excel Import

**Architecture / Design:**
- Import is integrated into Payments screen (button), not a separate module
- subscriber_name in payments table is standalone, not resolved from subscriber_groups — payments are self-contained historical records
- Pagination with server-side queries for 100k+ record performance

**Business Logic:**
- Excel file is "successful" if it contains the 3 key columns (account_number, amount, date) via alias matching; other columns (subscriber_name, stamp_number) are optional
- Multi-file and multi-tab (worksheet) import supported
- File success is per-file: one successful tab makes the file successful

---
## 2026-02-17 | Implement Reports Screen With Navigation and Printing

**Architecture / Design (if applicable):**
- Reports is introduced as a first-class app module/screen and wired into app-level navigation.
- Report input UX is fixed: one account number field, then from/to date fields, then generate action.
- Printed output must mirror the on-screen report data.

**Business Logic (if applicable):**
- Report lookup starts from account number; missing account returns a clear "user not found" failure state.
- If account exists, resolve its subscriber group and include payments for all accounts in that group.
- Empty from/to dates mean all-time period.
- Subscriber display name in reports is sourced from current subscriber group mapping (`subscriber_groups.name`).

---
