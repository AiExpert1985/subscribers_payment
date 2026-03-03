import '../data/database_service.dart';
import 'account_import_parser.dart';

/// A row that failed during account import.
class AccountImportError {
  final int? oldAccount;
  final int? newAccount;

  /// Short Arabic reason label (for display and Excel export).
  final String reason;

  AccountImportError({
    required this.oldAccount,
    required this.newAccount,
    required this.reason,
  });
}

/// Summary returned after importing an account-mapping Excel file.
class AccountImportResult {
  final int inserted;
  final List<AccountImportError> errors;

  AccountImportResult({required this.inserted, required this.errors});
}

/// Orchestrates the account-import pipeline: parse → validate → insert accounts.
///
/// Rules:
/// - Old account must already exist in DB; otherwise skipped with error.
/// - New account must not already exist anywhere; otherwise skipped with error.
/// - On success: new account is inserted into the same group as old account.
class AccountImportService {
  final DatabaseService _db;

  AccountImportService(this._db);

  Future<AccountImportResult> importFile(String filePath) async {
    final parseResult = AccountImportParser().parseFile(filePath);

    final errors = <AccountImportError>[];

    // Carry over parse-level errors as entries with no account numbers.
    for (final msg in parseResult.errors) {
      errors.add(
        AccountImportError(oldAccount: null, newAccount: null, reason: msg),
      );
    }

    if (!parseResult.hasData) {
      return AccountImportResult(inserted: 0, errors: errors);
    }

    int inserted = 0;

    for (final row in parseResult.rows) {
      final groupId = await _db.getGroupIdByAccountNumber(row.oldAccount);

      if (groupId == null) {
        errors.add(
          AccountImportError(
            oldAccount: row.oldAccount,
            newAccount: row.newAccount,
            reason: 'الحساب القديم غير موجود',
          ),
        );
        continue;
      }

      final newExists = await _db.getGroupIdByAccountNumber(row.newAccount);
      if (newExists != null) {
        errors.add(
          AccountImportError(
            oldAccount: row.oldAccount,
            newAccount: row.newAccount,
            reason: 'الحساب الجديد موجود مسبقاً',
          ),
        );
        continue;
      }

      try {
        await _db.insertAccount({
          'account_number': row.newAccount,
          'subscriber_group_id': groupId,
        });
        inserted++;
      } catch (_) {
        errors.add(
          AccountImportError(
            oldAccount: row.oldAccount,
            newAccount: row.newAccount,
            reason: 'فشل الحفظ',
          ),
        );
      }
    }

    return AccountImportResult(inserted: inserted, errors: errors);
  }
}
