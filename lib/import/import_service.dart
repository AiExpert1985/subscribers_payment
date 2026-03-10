import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import '../data/database_service.dart';
import 'csv_parser.dart';
import 'excel_parser.dart';

/// Result of importing one or more Excel/CSV files.
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

/// Orchestrates the full import pipeline: parse → validate → insert.
///
/// Uses the database's composite unique constraint for duplicate prevention
/// (INSERT OR IGNORE).
class ImportService {
  final DatabaseService _db;

  ImportService(this._db);

  /// Imports payments from multiple file paths.
  ///
  /// [aliases] is the payment section alias map fetched from the DB before
  /// calling this method — it must be passed in so the parser can run inside
  /// a background isolate without accessing the database.
  ///
  /// Reports progress via [onProgress] with a human-readable Arabic label.
  Future<ImportResult> importFiles(
    List<String> filePaths, {
    required Map<String, List<String>> aliases,
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

      // Aliases are plain Map<String,List<String>> — safe to send across isolate boundary.
      final aliasesSnapshot = Map<String, List<String>>.from(aliases);
      final parseResult = await Isolate.run(() {
        final ext = path.split('.').last.toLowerCase();
        if (ext == 'csv') return CsvParser(aliasesSnapshot).parseFile(path);
        return ExcelParser(aliasesSnapshot).parseFile(path);
      });

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

      onProgress?.call(
        'تم قراءة ${parseResult.rows.length} سجل — جاري الحفظ...',
      );
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
