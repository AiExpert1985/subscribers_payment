## active-plan: Accounts Screen

### Goal
Implement the Accounts management screen with full CRUD for subscriber groups and their account numbers, accessible via a new bottom navigation bar.

### Initial Plan

**Approach:**
Create a new `accounts` feature module following the existing feature-first pattern. Add a `searchGroupsByAccountNumber` method to `DatabaseService` for the search feature. Build the Accounts screen with a reactive list of subscriber groups, each displaying inline-editable name and account numbers with "+" buttons. Wrap the app in a bottom navigation shell (`Scaffold` with `BottomNavigationBar`) in `main.dart` to switch between Payments and Accounts tabs. Use Riverpod `StateProvider` for search state and `FutureProvider` for the groups list, matching the Payments screen pattern.

**Affected Modules:**
- `lib/data/` — database_service.dart (add search method)
- `lib/accounts/` — new feature module (screen + providers)
- `lib/main.dart` — add bottom navigation shell

**Files to modify:**
- `lib/data/database_service.dart` — add `searchGroupsByAccountNumber` method that joins accounts and subscriber_groups
- `lib/main.dart` — replace `PaymentsScreen` as home with a navigation shell widget

**Files to create:**
- `lib/accounts/accounts_providers.dart` — Riverpod providers for groups list, search filter, refresh trigger
- `lib/accounts/accounts_screen.dart` — accounts UI: search bar, scrollable list of groups with inline editing, add/delete

**Key Steps:**
1. Add `searchGroupsByAccountNumber(String query)` to `DatabaseService` — returns group IDs where any account_number matches LIKE query
2. Create `accounts_providers.dart` with search filter, subscriber groups list provider (fetches groups + their accounts), and a refresh trigger
3. Create `accounts_screen.dart` — Scaffold body with search field at top, add-group button, scrollable list of group rows. Each row: editable subscriber name, list of account number chips with inline edit, "+" button to add account, delete group button
4. Create navigation shell in `main.dart` — `BottomNavigationBar` with Payments and Accounts tabs, `IndexedStack` to preserve state

**Constraints:**
- Preserve contracts (payment immutability, global account uniqueness, cascade deletes)
- New contract: all delete actions show confirmation dialog
- Respect design (RTL, compact layout, hover-reveal controls)
- Do not expand scope (no Reports screen, no bulk operations)

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Added `searchGroupsByAccountNumber` to `DatabaseService`, created `accounts_providers.dart` (search state + combined groups-with-accounts provider), created `accounts_screen.dart` (full CRUD with inline editing, search, delete confirmations), and replaced `PaymentsScreen` home with `AppShell` bottom navigation in `main.dart`. No plan revisions needed.

**Deferred items:** None
