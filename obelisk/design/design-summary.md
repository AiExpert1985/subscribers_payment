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
