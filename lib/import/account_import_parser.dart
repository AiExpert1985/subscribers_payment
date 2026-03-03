import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// A valid parsed row: both account numbers are present and positive integers.
typedef AccountImportRow = ({int oldAccount, int newAccount});

/// Result of parsing an account-mapping Excel file.
class AccountImportParseResult {
  final List<AccountImportRow> rows;

  /// Parse-level errors (bad file, missing columns, invalid cell values).
  final List<String> errors;

  AccountImportParseResult({required this.rows, required this.errors});

  bool get hasData => rows.isNotEmpty;
}

/// Parses an Excel file with two required columns:
/// "الحساب القديم" (old account) and "الحساب الجديد" (new account).
///
/// Header matching is case-insensitive and whitespace-trimmed.
/// Rows with invalid or missing values are skipped (collected as errors).
class AccountImportParser {
  // Recognised header aliases — extend as needed.
  static const _oldAliases = [
    'الحساب القديم',
    'حساب قديم',
    'old account',
    'old',
  ];
  static const _newAliases = [
    'الحساب الجديد',
    'حساب جديد',
    'new account',
    'new',
  ];

  AccountImportParseResult parseFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      return _parseExcel(excel);
    } catch (e) {
      debugPrint('[AccountImportParser] Failed to read "$fileName": $e');
      return AccountImportParseResult(
        rows: [],
        errors: ['فشل قراءة الملف: $e'],
      );
    }
  }

  AccountImportParseResult _parseExcel(Excel excel) {
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      final sheetRows = sheet.rows;
      if (sheetRows.isEmpty) continue;

      final oldIdx = _findColumnIndex(sheetRows.first, _oldAliases);
      final newIdx = _findColumnIndex(sheetRows.first, _newAliases);

      if (oldIdx == null || newIdx == null) continue; // try next sheet

      return _parseSheet(sheetRows, oldIdx, newIdx);
    }

    return AccountImportParseResult(
      rows: [],
      errors: [
        'لم يتم العثور على الأعمدة المطلوبة: "الحساب القديم" و "الحساب الجديد"',
      ],
    );
  }

  AccountImportParseResult _parseSheet(
    List<List<Data?>> sheetRows,
    int oldIdx,
    int newIdx,
  ) {
    final rows = <AccountImportRow>[];
    final errors = <String>[];

    for (int i = 1; i < sheetRows.length; i++) {
      final row = sheetRows[i];
      final oldRaw = _cellInt(row, oldIdx);
      final newRaw = _cellInt(row, newIdx);

      if (oldRaw == null || newRaw == null) {
        errors.add('السطر ${i + 1}: بيانات غير صالحة — تم التخطي');
        continue;
      }

      rows.add((oldAccount: oldRaw, newAccount: newRaw));
    }

    return AccountImportParseResult(rows: rows, errors: errors);
  }

  /// Finds the index of the first header that matches any alias.
  int? _findColumnIndex(List<Data?> headerRow, List<String> aliases) {
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell == null) continue;
      final text = _cellText(cell).trim().toLowerCase();
      if (aliases.any((a) => a.toLowerCase() == text)) return i;
    }
    return null;
  }

  /// Extracts an integer from a cell (handles int, double, and text types).
  int? _cellInt(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    return switch (cell.value) {
      IntCellValue() => (cell.value as IntCellValue).value,
      DoubleCellValue() => (cell.value as DoubleCellValue).value.toInt(),
      TextCellValue() => int.tryParse(
        (cell.value as TextCellValue).value.toString().trim(),
      ),
      _ => int.tryParse(cell.value.toString().trim()),
    };
  }

  /// Extracts text from a header cell for alias matching.
  String _cellText(Data cell) {
    return switch (cell.value) {
      TextCellValue() => (cell.value as TextCellValue).value.toString(),
      IntCellValue() => (cell.value as IntCellValue).value.toString(),
      DoubleCellValue() => (cell.value as DoubleCellValue).value.toString(),
      _ => cell.value.toString(),
    };
  }
}
