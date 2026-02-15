# Task: Implement Database Schema and Models

## Goal
Set up SQLite database with 3 tables (subscriber_groups, accounts, payments) and create corresponding Dart model classes with Riverpod 3 integration. This establishes the data layer foundation for the payment consolidation system.

## Scope
✓ Included:
- Add sqflite and Riverpod 3 dependencies to pubspec.yaml
- Create database schema with all constraints (unique, composite unique, foreign keys)
- Implement Dart model classes for subscriber_groups, accounts, and payments entities
- Set up database initialization and migration logic
- Create database service/repository layer with Riverpod providers

✗ Excluded:
- No UI screens for CRUD operations (deferred to next task)
- No Excel import logic
- No search/reporting logic
- No runtime verification UI

## Constraints
- **Platform:** Flutter Windows desktop, SQLite local database
- **Tech stack:** Riverpod 3 (not legacy), sqflite package
- **Schema:** Exactly 3 tables with specified columns and constraints
- **Data types:** Account numbers as INTEGER, amounts as REAL (3 decimal precision), dates as INTEGER (timestamps)
- **Deletion behavior:** CASCADE delete accounts when subscriber_group deleted; payments remain untouched
- **Payments immutability:** No foreign key from payments.reference_account_number to accounts table
- **Account uniqueness:** Account numbers globally unique (database-level UNIQUE constraint)
- **Payment uniqueness:** Composite unique constraint on (reference_account_number, payment_date, amount)

## Success Criteria
- App compiles without errors after adding dependencies
- Database initializes successfully on app startup
- All 3 tables created with correct schema and constraints
- Model classes properly represent database entities
- Database service accessible via Riverpod providers
- No runtime verification UI needed (verification deferred to future tasks)

## Open Questions
None
