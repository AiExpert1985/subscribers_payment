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
/// - Old exists, new doesn't → add new to old's group.
/// - Old exists, new already exists → skip with error.
/// - Old doesn't exist, new doesn't exist → create new group, insert both.
/// - Old doesn't exist, new already exists → add old to new's group; skip new.
/// - If اسم المشترك is non-empty: the target group's name is overwritten.
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
      final oldGroupId = await _db.getGroupIdByAccountNumber(row.oldAccount);

      if (oldGroupId != null) {
        // Old account exists — add new to old's group.
        if (row.subscriberName != null && row.subscriberName!.isNotEmpty) {
          await _db.updateSubscriberGroup(oldGroupId, {'name': row.subscriberName});
        }

        final newExists = await _db.getGroupIdByAccountNumber(row.newAccount);
        if (newExists != null) {
          errors.add(AccountImportError(
            oldAccount: row.oldAccount,
            newAccount: row.newAccount,
            reason: 'الحساب الجديد موجود مسبقاً',
          ));
          continue;
        }

        try {
          await _db.insertAccount({
            'account_number': row.newAccount,
            'subscriber_group_id': oldGroupId,
          });
          inserted++;
        } catch (_) {
          errors.add(AccountImportError(
            oldAccount: row.oldAccount,
            newAccount: row.newAccount,
            reason: 'فشل الحفظ',
          ));
        }
      } else {
        // Old account doesn't exist — check new account.
        final newGroupId = await _db.getGroupIdByAccountNumber(row.newAccount);

        if (newGroupId != null) {
          // New exists — add old to new's group.
          if (row.subscriberName != null && row.subscriberName!.isNotEmpty) {
            await _db.updateSubscriberGroup(newGroupId, {'name': row.subscriberName});
          }
          try {
            await _db.insertAccount({
              'account_number': row.oldAccount,
              'subscriber_group_id': newGroupId,
            });
            inserted++;
          } catch (_) {
            errors.add(AccountImportError(
              oldAccount: row.oldAccount,
              newAccount: row.newAccount,
              reason: 'فشل الحفظ',
            ));
          }
        } else {
          // Neither exists — create new group, insert both.
          try {
            final groupId = await _db.insertSubscriberGroup({
              'name': row.subscriberName ?? '',
            });
            await _db.insertAccount({
              'account_number': row.oldAccount,
              'subscriber_group_id': groupId,
            });
            await _db.insertAccount({
              'account_number': row.newAccount,
              'subscriber_group_id': groupId,
            });
            inserted += 2;
          } catch (_) {
            errors.add(AccountImportError(
              oldAccount: row.oldAccount,
              newAccount: row.newAccount,
              reason: 'فشل الحفظ',
            ));
          }
        }
      }
    }

    return AccountImportResult(inserted: inserted, errors: errors);
  }
}
