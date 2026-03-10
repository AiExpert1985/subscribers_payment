import '../data/database_service.dart';
import 'account_import_parser.dart';

/// A row that failed during account import.
class AccountImportError {
  /// Account numbers from the failed row (empty for file-level parse errors).
  final List<int> accounts;

  /// Short Arabic reason label (for display and Excel export).
  final String reason;

  AccountImportError({required this.accounts, required this.reason});
}

/// Summary returned after importing an account file.
class AccountImportResult {
  final int inserted;
  final List<AccountImportError> errors;

  AccountImportResult({required this.inserted, required this.errors});
}

/// Orchestrates the account-import pipeline: parse → validate → insert.
///
/// Per-row routing (accounts = all account numbers found in the row):
/// - All absent from DB → create new group (with name if present), insert all.
/// - Some/all exist in exactly ONE group, rest absent → add absent to that group;
///   update name if present.
/// - Accounts found across MORE THAN ONE group → skip, error "تعارض في المجموعات".
/// - All already in same group → update name if present, then silent skip.
class AccountImportService {
  final DatabaseService _db;

  AccountImportService(this._db);

  Future<AccountImportResult> importFile(
    String filePath, {
    required Map<String, List<String>> aliases,
  }) async {
    final parseResult = AccountImportParser(aliases).parseFile(filePath);
    final errors = <AccountImportError>[];

    for (final msg in parseResult.errors) {
      errors.add(AccountImportError(accounts: [], reason: msg));
    }

    if (!parseResult.hasData) {
      return AccountImportResult(inserted: 0, errors: errors);
    }

    int inserted = 0;

    for (final row in parseResult.rows) {
      final rowResult = await _processRow(row);
      inserted += rowResult.inserted;
      if (rowResult.error != null) errors.add(rowResult.error!);
    }

    return AccountImportResult(inserted: inserted, errors: errors);
  }

  Future<({int inserted, AccountImportError? error})> _processRow(
    AccountImportRow row,
  ) async {
    // Map each account number to its existing group id (null = not in DB).
    final groupByAccount = <int, int>{};
    for (final acc in row.accounts) {
      final groupId = await _db.getGroupIdByAccountNumber(acc);
      if (groupId != null) groupByAccount[acc] = groupId;
    }

    final distinctGroupIds = groupByAccount.values.toSet();

    if (distinctGroupIds.length > 1) {
      return (
        inserted: 0,
        error: AccountImportError(
          accounts: row.accounts,
          reason: 'تعارض في المجموعات',
        ),
      );
    }

    final absentAccounts =
        row.accounts.where((a) => !groupByAccount.containsKey(a)).toList();

    if (distinctGroupIds.isEmpty) {
      // None exist — create new group and insert all accounts.
      return _createGroupWithAccounts(row.accounts, row.subscriberName);
    }

    // Exactly one group found.
    final targetGroupId = distinctGroupIds.first;

    if (absentAccounts.isEmpty) {
      // All already in the same group — update name if provided, then skip.
      if (row.subscriberName != null && row.subscriberName!.isNotEmpty) {
        try {
          await _db.updateSubscriberGroup(targetGroupId, {'name': row.subscriberName});
        } catch (_) {
          // Name conflict (uniqueness) — silently skip the name update.
        }
      }
      return (inserted: 0, error: null);
    }

    // Add absent accounts to the existing group.
    return _addToExistingGroup(
      targetGroupId,
      absentAccounts,
      row.accounts,
      row.subscriberName,
    );
  }

  Future<({int inserted, AccountImportError? error})> _createGroupWithAccounts(
    List<int> accounts,
    String? name,
  ) async {
    try {
      final groupId = await _db.insertSubscriberGroup({'name': name ?? ''});
      for (final acc in accounts) {
        await _db.insertAccount({
          'account_number': acc,
          'subscriber_group_id': groupId,
        });
      }
      return (inserted: accounts.length, error: null);
    } catch (_) {
      return (
        inserted: 0,
        error: AccountImportError(accounts: accounts, reason: 'فشل الحفظ'),
      );
    }
  }

  Future<({int inserted, AccountImportError? error})> _addToExistingGroup(
    int groupId,
    List<int> toInsert,
    List<int> allAccounts,
    String? name,
  ) async {
    try {
      if (name != null && name.isNotEmpty) {
        await _db.updateSubscriberGroup(groupId, {'name': name});
      }
      for (final acc in toInsert) {
        await _db.insertAccount({
          'account_number': acc,
          'subscriber_group_id': groupId,
        });
      }
      return (inserted: toInsert.length, error: null);
    } catch (_) {
      return (
        inserted: 0,
        error: AccountImportError(accounts: allAccounts, reason: 'فشل الحفظ'),
      );
    }
  }
}
