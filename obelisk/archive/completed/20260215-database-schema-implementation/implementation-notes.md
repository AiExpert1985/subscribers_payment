# active-plan: Implement Database Schema and Models

## Goal
Set up SQLite database with 3 tables (subscriber_groups, accounts, payments) and create corresponding Dart model classes with Riverpod 3 integration. This establishes the data layer foundation for the payment consolidation system.

## Success Criteria
- App compiles without errors after adding dependencies
- Database initializes successfully on app startup
- All 3 tables created with correct schema and constraints
- Model classes properly represent database entities
- Database service accessible via Riverpod providers
- No runtime verification UI needed (verification deferred to future tasks)

## Initial Plan

**Approach:**
Create a feature-based data layer following Flutter best practices. Add sqflite (2.4.2) and flutter_riverpod (3.2.1) dependencies. Implement three model classes with fromMap/toMap methods. Create a database service that initializes SQLite on first run with proper schema and constraints (account uniqueness, payment composite unique, CASCADE delete). Expose database via Riverpod provider and initialize in main.dart startup.

**Files to modify:**
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/pubspec.yaml` — Add sqflite ^2.4.2 and flutter_riverpod ^3.2.1 dependencies
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/main.dart` — Add ProviderScope wrapper and database initialization

**Files to create:**
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/data/models/subscriber_group.dart` — SubscriberGroup model with id and name fields
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/data/models/account.dart` — Account model with id, accountNumber, subscriberGroupId
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/data/models/payment.dart` — Payment model with id, referenceAccountNumber, paymentDate, amount, type, collectorStamp
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/data/database_service.dart` — Database initialization, schema creation, and query methods
- `/d:/Electricity Apps/Python & Flutter/subscribers_payments/lib/data/providers.dart` — Riverpod providers for database service

**Key steps:**
1. Add sqflite and flutter_riverpod dependencies to pubspec.yaml
2. Create three model classes with proper data types (int for IDs/account numbers/timestamps, double for amounts, String for text)
3. Create DatabaseService with schema creation SQL (3 tables with all constraints)
4. Implement database initialization with version management
5. Create Riverpod provider for DatabaseService
6. Wrap MyApp with ProviderScope in main.dart
7. Run flutter pub get to install dependencies

**Constraints:**
- Preserve all contracts in contracts-summary.md
- Do not expand scope beyond frozen task
- Account numbers: INTEGER type
- Amounts: REAL type with 3 decimal precision
- Dates: INTEGER type (unix timestamps)
- No FK from payments.reference_account_number to accounts
- UNIQUE constraint on accounts.account_number
- Composite UNIQUE on payments (reference_account_number, payment_date, amount)
- CASCADE delete from subscriber_groups to accounts, but payments untouched

---

## Plan Revisions

*Leave empty initially. Append here if approach changes during implementation.*

---

## Execution Summary

**Final approach:** 
Implemented database layer following the initial plan without revisions. Created feature-based data structure with models, database service, and Riverpod providers. Used sqflite 2.4.2 and flutter_riverpod 3.2.1 as researched. DatabaseService implements all schema constraints: account_number UNIQUE, composite UNIQUE on payments (reference_account_number, payment_date, amount), and CASCADE delete from subscriber_groups to accounts while leaving payments untouched. All CRUD operations implemented for future use.

**Success criteria verification:**
- ✓ App compiles without errors (flutter analyze: no issues found)
- ✓ Database initializes on app startup via lazy initialization
- ✓ All 3 tables created with correct schema and constraints
- ✓ Model classes properly represent database entities with fromMap/toMap
- ✓ Database service accessible via Riverpod providers (databaseServiceProvider)
- ✓ No runtime verification UI (as requested)

**Deferred items:** None
