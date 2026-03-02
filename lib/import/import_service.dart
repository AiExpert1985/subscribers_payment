import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/database_service.dart';
import 'excel_parser.dart';

// Top-level function required by compute() — closures are not allowed because
// they would capture non-sendable Flutter state through shared Dart contexts.
ExcelParseResult _parseFile(String path) => ExcelParser().parseFile(path);

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

  ImportService(this._db);

  /// Imports payments from multiple Excel file paths.
  /// Reports progress via [onProgress] with a human-readable Arabic label.
  Future<ImportResult> importFiles(
    List<String> filePaths, {
    void Function(String label)? onProgress,
  }) async {
    int successfulFiles = 0;
    int failedFiles = 0;
    int totalInserted = 0;
    int totalDuplicates = 0;
    final errors = <String>[];

    for (final path in filePaths) {
      final fileName = path.split(RegExp(r'[\\/]')).last;
      final fileWatch = Stopwatch()..start();

      debugPrint('[Import] [$fileName] Parsing started');
      onProgress?.call('جاري قراءة الملف...');
      final parseTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        debugPrint(
          '[Import] [$fileName] Still parsing... (${fileWatch.elapsedMilliseconds}ms)',
        );
      });
      final parseResult = await compute(_parseFile, path);
      parseTimer.cancel();

      if (!parseResult.isSuccessful) {
        failedFiles++;
        errors.add('${parseResult.fileName}: ${parseResult.errors.join(", ")}');
        debugPrint(
          '[Import] [$fileName] Parse failed (${fileWatch.elapsedMilliseconds}ms): ${parseResult.errors.join(", ")}',
        );
        continue;
      }

      debugPrint(
        '[Import] [$fileName] Parse complete: ${parseResult.rows.length} rows (${fileWatch.elapsedMilliseconds}ms)',
      );

      // Collect unique account numbers and their subscriber names
      onProgress?.call('جاري معالجة الحسابات...');
      final accountNumbers = <int>{};
      final accountNames = <int, String?>{};
      for (final row in parseResult.rows) {
        final accNum = row['reference_account_number'] as int;
        if (accountNumbers.add(accNum)) {
          accountNames[accNum] = row['subscriber_name'] as String?;
        }
      }

      debugPrint(
        '[Import] [$fileName] Processing ${accountNumbers.length} unique accounts (${fileWatch.elapsedMilliseconds}ms)',
      );

      // Load all existing accounts in one query, then create only missing ones
      final existing = await _db.getExistingAccountNumbers(accountNumbers);
      for (final accNum in accountNumbers) {
        if (!existing.contains(accNum)) {
          await _db.findOrCreateAccountAndGroup(
            accNum,
            subscriberName: accountNames[accNum],
          );
        }
      }

      debugPrint(
        '[Import] [$fileName] Accounts ready (${fileWatch.elapsedMilliseconds}ms)',
      );

      // Notify user that parsing is done and saving is starting
      onProgress?.call('تم قراءة ${parseResult.rows.length} سجل — جاري الحفظ...');
      debugPrint(
        '[Import] [$fileName] DB save started: ${parseResult.rows.length} rows (${fileWatch.elapsedMilliseconds}ms)',
      );

      final inserted = await _db.insertPaymentBatch(
        parseResult.rows,
        onProgress: (saved, total) {
          debugPrint(
            '[Import] [$fileName] Saved $saved / $total (${fileWatch.elapsedMilliseconds}ms)',
          );
        },
      );
      final duplicates = parseResult.rows.length - inserted;

      debugPrint(
        '[Import] [$fileName] Done: $inserted inserted, $duplicates duplicates (${fileWatch.elapsedMilliseconds}ms total)',
      );

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
