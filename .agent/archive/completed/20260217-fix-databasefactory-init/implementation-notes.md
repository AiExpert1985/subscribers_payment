## active-plan: Fix databaseFactory Not Initialized on Windows

### Goal
Fix the `Bad state: databaseFactory not initialized` error by adding the `sqflite_common_ffi` package and initializing the database factory before app startup.

### Initial Plan

**Approach:**
The `sqflite` package doesn't auto-initialize on desktop platforms. Add `sqflite_common_ffi` as a dependency and call `databaseFactory = databaseFactoryFfi` in `main()` before `runApp()`. This is the standard pattern for sqflite on Windows/macOS/Linux.

**Affected Modules:**
- App entry point (`main.dart`)
- Dependencies (`pubspec.yaml`)

**Files to modify:**
- `pubspec.yaml` — add `sqflite_common_ffi` dependency
- `lib/main.dart` — initialize databaseFactory before runApp

**Files to create:**
- None

**Key Steps:**
1. Add `sqflite_common_ffi` to `pubspec.yaml`
2. Import `sqflite_common_ffi` in `main.dart`
3. Set `databaseFactory = databaseFactoryFfi` before `runApp()`
4. Run `flutter pub get`
5. Verify app launches without error

**Constraints:**
- Preserve contracts
- Respect design
- Do not expand scope

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Added `sqflite_common_ffi: ^2.3.4+4` to `pubspec.yaml` and set `databaseFactory = databaseFactoryFfi` in `main()` before `runApp()`. Build verified successfully.

**Deferred items:** None
