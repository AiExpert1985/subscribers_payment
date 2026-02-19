# Implementation Notes: Auto-assign new accounts to existing subscriber groups by name match

## Execution Summary

Implemented as specified. Only `lib/data/database_service.dart` was modified.

## Changes Made

1. `_databaseVersion` incremented from `1` to `2`.
2. `openDatabase` call extended with `onUpgrade: _onUpgrade`.
3. `_onCreate` extended to call `_createSubscriberGroupNameIndex` at the end of fresh schema creation.
4. New method `_onUpgrade` — runs migration for version 1→2: calls `_createSubscriberGroupNameIndex`.
5. New method `_createSubscriberGroupNameIndex` — creates `CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriber_groups_name_nonempty ON subscriber_groups(name) WHERE name != ''`.
6. `findOrCreateAccountAndGroup` refactored: group resolution extracted into new private method `_resolveOrCreateGroup`.
7. New method `_resolveOrCreateGroup` — exact-matches non-empty subscriber name against existing groups; returns matching group ID if found, otherwise inserts new group.

## Divergences

Plan implemented as specified. No divergences.
