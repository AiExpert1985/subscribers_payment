import '../data/database_service.dart';
import 'excel_parser.dart';

/// Result of importing one or more Excel files.
class ImportResult {
  final int successfulFiles;
  final int failedFiles;
  final int totalRowsInserted;
  final int totalDuplicatesSkipped;
  final List<String> fileErrors;

  ImportResult({
    required this.successfulFiles,
    required this.failedFiles,
    required this.totalRowsInserted,
    required this.totalDuplicatesSkipped,
    required this.fileErrors,
  });
}

/// Orchestrates the full import pipeline: parse → validate → auto-create → insert.
///
/// Uses the database's composite unique constraint for duplicate prevention
/// (INSERT OR IGNORE).
class ImportService {
  final DatabaseService _db;
  final ExcelParser _parser = ExcelParser();

  ImportService(this._db);

  /// Imports payments from multiple Excel file paths.
  Future<ImportResult> importFiles(List<String> filePaths) async {
    int successfulFiles = 0;
    int failedFiles = 0;
    int totalInserted = 0;
    int totalDuplicates = 0;
    final errors = <String>[];

    for (final path in filePaths) {
      final parseResult = _parser.parseFile(path);

      if (!parseResult.isSuccessful) {
        failedFiles++;
        errors.add('${parseResult.fileName}: ${parseResult.errors.join(", ")}');
        continue;
      }

      // Auto-create accounts/groups for unknown account numbers
      final accountNumbers = <int>{};
      for (final row in parseResult.rows) {
        final accNum = row['reference_account_number'] as int;
        if (accountNumbers.add(accNum)) {
          await _db.findOrCreateAccountAndGroup(
            accNum,
            subscriberName: row['subscriber_name'] as String?,
          );
        }
      }

      // Batch insert with duplicate skipping
      final inserted = await _db.insertPaymentBatch(parseResult.rows);
      final duplicates = parseResult.rows.length - inserted;

      totalInserted += inserted;
      totalDuplicates += duplicates;
      successfulFiles++;

      if (parseResult.errors.isNotEmpty) {
        errors.add(
          '${parseResult.fileName}: ${parseResult.errors.join(", ")} '
          '(تم استيراد $inserted سجل)',
        );
      }
    }

    return ImportResult(
      successfulFiles: successfulFiles,
      failedFiles: failedFiles,
      totalRowsInserted: totalInserted,
      totalDuplicatesSkipped: totalDuplicates,
      fileErrors: errors,
    );
  }
}
