import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// A valid parsed row: both account numbers are present and positive integers.
/// [subscriberName] is optional — null if the column was absent or cell blank.
typedef AccountImportRow = ({
  int oldAccount,
  int newAccount,
  String? subscriberName,
});

/// Result of parsing an account-mapping file (Excel or CSV).
class AccountImportParseResult {
  final List<AccountImportRow> rows;

  /// Parse-level errors (bad file, missing columns, invalid cell values).
  final List<String> errors;

  AccountImportParseResult({required this.rows, required this.errors});

  bool get hasData => rows.isNotEmpty;
}

/// Parses an Excel or CSV file with two required columns:
/// "الحساب القديم" (old account) and "الحساب الجديد" (new account),
/// and one optional column: "اسم المشترك" (subscriber name).
///
/// Header matching is case-insensitive and whitespace-trimmed.
/// Rows with invalid or missing required values are skipped (collected as errors).
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
  static const _nameAliases = ['اسم المشترك', 'subscriber name', 'name'];

  AccountImportParseResult parseFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final ext = fileName.split('.').last.toLowerCase();
    try {
      if (ext == 'csv') return _parseCsvFile(filePath, fileName);
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

  // ─── Excel ───────────────────────────────────────────────────────────────

  AccountImportParseResult _parseExcel(Excel excel) {
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      final sheetRows = sheet.rows;
      if (sheetRows.isEmpty) continue;

      final oldIdx = _findColumnIndex(sheetRows.first, _oldAliases);
      final newIdx = _findColumnIndex(sheetRows.first, _newAliases);

      if (oldIdx == null || newIdx == null) continue; // try next sheet

      // Name column is optional — null if not present.
      final nameIdx = _findColumnIndex(sheetRows.first, _nameAliases);

      return _parseExcelSheet(sheetRows, oldIdx, newIdx, nameIdx);
    }

    return AccountImportParseResult(
      rows: [],
      errors: [
        'لم يتم العثور على الأعمدة المطلوبة: "الحساب القديم" و "الحساب الجديد"',
      ],
    );
  }

  AccountImportParseResult _parseExcelSheet(
    List<List<Data?>> sheetRows,
    int oldIdx,
    int newIdx,
    int? nameIdx,
  ) {
    final rows = <AccountImportRow>[];
    final errors = <String>[];

    for (int i = 1; i < sheetRows.length; i++) {
      final row = sheetRows[i];
      final oldParsed = _cellInt(row, oldIdx);
      final newParsed = _cellInt(row, newIdx);

      if (oldParsed == null || newParsed == null) {
        final which = oldParsed == null ? 'الحساب القديم' : 'الحساب الجديد';
        final rawIdx = oldParsed == null ? oldIdx : newIdx;
        final rawVal = _cellRawString(row, rawIdx);
        errors.add('السطر ${i + 1}: $which غير صالح (القيمة: ${rawVal ?? "فارغ"})');
        continue;
      }

      // Name is optional; blank/missing → null (no-op on group name).
      final nameRaw = nameIdx != null ? _cellStringOrNull(row, nameIdx) : null;

      rows.add((
        oldAccount: oldParsed,
        newAccount: newParsed,
        subscriberName: nameRaw,
      ));
    }

    return AccountImportParseResult(rows: rows, errors: errors);
  }

  // ─── CSV ─────────────────────────────────────────────────────────────────

  AccountImportParseResult _parseCsvFile(String filePath, String fileName) {
    final bytes = File(filePath).readAsBytesSync();
    var content = utf8.decode(bytes, allowMalformed: true);

    // Strip UTF-8 BOM that Excel sometimes writes.
    if (content.startsWith('\uFEFF')) content = content.substring(1);

    // Normalize line endings.
    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final delimiter = _detectDelimiter(content);
    final csvRows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (csvRows.isEmpty) {
      return AccountImportParseResult(rows: [], errors: ['الملف فارغ']);
    }

    final headerRow = csvRows.first.map((e) => e.toString()).toList();
    final oldIdx = _findColumnIndexInStrings(headerRow, _oldAliases);
    final newIdx = _findColumnIndexInStrings(headerRow, _newAliases);

    if (oldIdx == null || newIdx == null) {
      return AccountImportParseResult(
        rows: [],
        errors: [
          'لم يتم العثور على الأعمدة المطلوبة: "الحساب القديم" و "الحساب الجديد"',
        ],
      );
    }

    final nameIdx = _findColumnIndexInStrings(headerRow, _nameAliases);
    return _parseCsvRows(csvRows, oldIdx, newIdx, nameIdx);
  }

  AccountImportParseResult _parseCsvRows(
    List<List<dynamic>> csvRows,
    int oldIdx,
    int newIdx,
    int? nameIdx,
  ) {
    final rows = <AccountImportRow>[];
    final errors = <String>[];

    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final oldRaw = _csvCellString(row, oldIdx);
      final newRaw = _csvCellString(row, newIdx);

      final oldParsed = _parseIntFromString(oldRaw);
      final newParsed = _parseIntFromString(newRaw);

      if (oldParsed == null || newParsed == null) {
        final which = oldParsed == null ? 'الحساب القديم' : 'الحساب الجديد';
        final val = (oldParsed == null ? oldRaw : newRaw) ?? 'فارغ';
        errors.add('السطر ${i + 1}: $which غير صالح (القيمة: $val)');
        continue;
      }

      final nameRaw =
          nameIdx != null ? _csvCellString(row, nameIdx) : null;

      rows.add((
        oldAccount: oldParsed,
        newAccount: newParsed,
        subscriberName: nameRaw,
      ));
    }

    return AccountImportParseResult(rows: rows, errors: errors);
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  /// Parses an integer from a string, accepting "1001.0"-style decimal text.
  int? _parseIntFromString(String? text) {
    if (text == null) return null;
    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.toInt();
    return null;
  }

  String _detectDelimiter(String content) {
    final firstLine = content.split('\n').first;
    final commas = ','.allMatches(firstLine).length;
    final semicolons = ';'.allMatches(firstLine).length;
    final tabs = '\t'.allMatches(firstLine).length;
    if (tabs >= semicolons && tabs >= commas) return '\t';
    if (semicolons >= commas) return ';';
    return ',';
  }

  // ─── Excel cell helpers ───────────────────────────────────────────────────

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
  /// Also accepts "1001.0"-style text values via double.tryParse fallback.
  int? _cellInt(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    return switch (cell.value) {
      IntCellValue() => (cell.value as IntCellValue).value,
      DoubleCellValue() => (cell.value as DoubleCellValue).value.toInt(),
      TextCellValue() => _parseIntFromString(
        (cell.value as TextCellValue).value.toString().trim(),
      ),
      _ => _parseIntFromString(cell.value.toString().trim()),
    };
  }

  /// Returns the raw string representation of a cell value for error messages.
  String? _cellRawString(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    final text = _cellText(cell).trim();
    return text.isEmpty ? null : text;
  }

  /// Extracts a non-empty trimmed string from a cell, or null if blank/absent.
  String? _cellStringOrNull(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    final text = _cellText(cell).trim();
    return text.isEmpty ? null : text;
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

  // ─── CSV cell helpers ─────────────────────────────────────────────────────

  int? _findColumnIndexInStrings(List<String> headerRow, List<String> aliases) {
    for (int i = 0; i < headerRow.length; i++) {
      final text = headerRow[i].trim().toLowerCase();
      if (aliases.any((a) => a.toLowerCase() == text)) return i;
    }
    return null;
  }

  String? _csvCellString(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final text = row[index].toString().trim();
    return text.isEmpty ? null : text;
  }
}
