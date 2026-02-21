# Task: Fix databaseFactory Not Initialized on Windows

## Goal
Fix the `Bad state: databaseFactory not initialized` error when running the app on Windows desktop. The `sqflite` package requires `sqflite_common_ffi` on desktop platforms, and the database factory must be set before any database calls.

## Scope
✓ Included:
- Add `sqflite_common_ffi` dependency to `pubspec.yaml`
- Initialize `databaseFactory = databaseFactoryFfi` in `main.dart` before `runApp`

✗ Excluded:
- No changes to database schema or service logic
- No changes to any other features

## Constraints
- Minimal change — only add the missing initialization
- No contract changes needed
- Must preserve all existing behavior
