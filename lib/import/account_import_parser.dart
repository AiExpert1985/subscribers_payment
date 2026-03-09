import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// A valid parsed row: one or more account numbers from matched columns.
/// [subscriberName] is optional — null if the column was absent or cell blank.
typedef AccountImportRow = ({
  List<int> accounts,
  String? subscriberName,
});

/// Result of parsing an account file (Excel or CSV).
class AccountImportParseResult {
  final List<AccountImportRow> rows;

  /// Parse-level errors (bad file, no account columns found).
  final List<String> errors;

  AccountImportParseResult({required this.rows, required this.errors});

  bool get hasData => rows.isNotEmpty;
}

/// Parses an Excel or CSV file for account import.
///
/// Any column whose header contains (case-insensitive, substring) any of the
/// account keywords is treated as an account-number column. A file is valid
/// if it has at least one such column.
///
/// The optional subscriber-name column is detected by exact alias match.
/// Rows with no parseable account numbers are silently skipped.
class AccountImportParser {
  // A column is an account column if its lowercased header CONTAINS any of these.
  static const _accountKeywords = [
    'الحساب القديم',
    'الحساب الجديد',
    'account',
    'old',
    'new',
    'account_no',
  ];

  static const _nameAliases = ['اسم المشترك', 'subscriber name', 'name'];

  AccountImportParseResult parseFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final ext = fileName.split('.').last.toLowerCase();
    try {
      if (ext == 'csv') return _parseCsvFile(filePath);
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

      final accountIndices = _findAccountColumnIndices(sheetRows.first);
      if (accountIndices.isEmpty) continue; // try next sheet

      final nameIdx = _findNameColumnIndex(sheetRows.first);
      return _parseExcelSheet(sheetRows, accountIndices, nameIdx);
    }

    return AccountImportParseResult(
      rows: [],
      errors: ['لم يتم العثور على عمود حسابات في الملف'],
    );
  }

  AccountImportParseResult _parseExcelSheet(
    List<List<Data?>> sheetRows,
    List<int> accountIndices,
    int? nameIdx,
  ) {
    final rows = <AccountImportRow>[];

    for (int i = 1; i < sheetRows.length; i++) {
      final row = sheetRows[i];
      final accounts = <int>[];

      for (final idx in accountIndices) {
        final parsed = _cellInt(row, idx);
        if (parsed != null) accounts.add(parsed);
      }

      if (accounts.isEmpty) continue;

      final nameRaw = nameIdx != null ? _cellStringOrNull(row, nameIdx) : null;
      rows.add((accounts: accounts, subscriberName: nameRaw));
    }

    return AccountImportParseResult(rows: rows, errors: []);
  }

  // ─── CSV ─────────────────────────────────────────────────────────────────

  AccountImportParseResult _parseCsvFile(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    var content = utf8.decode(bytes, allowMalformed: true);

    if (content.startsWith('\uFEFF')) content = content.substring(1);
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
    final accountIndices = _findAccountColumnIndicesInStrings(headerRow);

    if (accountIndices.isEmpty) {
      return AccountImportParseResult(
        rows: [],
        errors: ['لم يتم العثور على عمود حسابات في الملف'],
      );
    }

    final nameIdx = _findNameColumnIndexInStrings(headerRow);
    return _parseCsvRows(csvRows, accountIndices, nameIdx);
  }

  AccountImportParseResult _parseCsvRows(
    List<List<dynamic>> csvRows,
    List<int> accountIndices,
    int? nameIdx,
  ) {
    final rows = <AccountImportRow>[];

    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final accounts = <int>[];

      for (final idx in accountIndices) {
        final parsed = _parseIntFromString(_csvCellString(row, idx));
        if (parsed != null) accounts.add(parsed);
      }

      if (accounts.isEmpty) continue;

      final nameRaw = nameIdx != null ? _csvCellString(row, nameIdx) : null;
      rows.add((accounts: accounts, subscriberName: nameRaw));
    }

    return AccountImportParseResult(rows: rows, errors: []);
  }

  // ─── Column detection — Excel ─────────────────────────────────────────────

  List<int> _findAccountColumnIndices(List<Data?> headerRow) {
    final result = <int>[];
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell == null) continue;
      if (_isAccountHeader(_cellText(cell).trim().toLowerCase())) result.add(i);
    }
    return result;
  }

  int? _findNameColumnIndex(List<Data?> headerRow) {
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell == null) continue;
      final text = _cellText(cell).trim().toLowerCase();
      if (_nameAliases.any((a) => a.toLowerCase() == text)) return i;
    }
    return null;
  }

  // ─── Column detection — CSV ───────────────────────────────────────────────

  List<int> _findAccountColumnIndicesInStrings(List<String> headerRow) {
    final result = <int>[];
    for (int i = 0; i < headerRow.length; i++) {
      if (_isAccountHeader(headerRow[i].trim().toLowerCase())) result.add(i);
    }
    return result;
  }

  int? _findNameColumnIndexInStrings(List<String> headerRow) {
    for (int i = 0; i < headerRow.length; i++) {
      final text = headerRow[i].trim().toLowerCase();
      if (_nameAliases.any((a) => a.toLowerCase() == text)) return i;
    }
    return null;
  }

  bool _isAccountHeader(String headerLower) =>
      _accountKeywords.any((k) => headerLower.contains(k.toLowerCase()));

  // ─── Shared helpers ───────────────────────────────────────────────────────

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

  String? _cellStringOrNull(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    final text = _cellText(cell).trim();
    return text.isEmpty ? null : text;
  }

  String _cellText(Data cell) {
    return switch (cell.value) {
      TextCellValue() => (cell.value as TextCellValue).value.toString(),
      IntCellValue() => (cell.value as IntCellValue).value.toString(),
      DoubleCellValue() => (cell.value as DoubleCellValue).value.toString(),
      _ => cell.value.toString(),
    };
  }

  // ─── CSV cell helpers ─────────────────────────────────────────────────────

  String? _csvCellString(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final text = row[index].toString().trim();
    return text.isEmpty ? null : text;
  }
}
