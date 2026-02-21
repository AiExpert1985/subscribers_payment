## Accounts Screen | 2026-02-17

**Summary:**
- Implement Accounts screen with subscriber group/account CRUD, accessible via bottom navigation bar.

**Architecture / Design:**
- Bottom navigation bar introduced as app-level shell (Payments, Accounts, future Reports)
- Accounts screen follows feature-first structure under `lib/accounts/`
- Inline editing for both subscriber names and account numbers (tap to edit)

**Business Logic:**
- Delete confirmation required for all destructive actions (new contract)
- Search by account number resolves to containing subscriber group
