import 'dart:io';
import 'package:excel/excel.dart';
import 'column_aliases.dart';

/// Result of parsing a single Excel file.
class ExcelParseResult {
  final String fileName;
  final List<Map<String, dynamic>> rows;
  final List<String> errors;

  ExcelParseResult({
    required this.fileName,
    required this.rows,
    required this.errors,
  });

  bool get isSuccessful => rows.isNotEmpty;
}

/// Column index mapping for a single worksheet.
class _ColumnMapping {
  final int accountIndex;
  final int amountIndex;
  final int dateIndex;
  final int? subscriberNameIndex;
  final int? stampIndex;

  _ColumnMapping({
    required this.accountIndex,
    required this.amountIndex,
    required this.dateIndex,
    this.subscriberNameIndex,
    this.stampIndex,
  });
}

/// Parses Excel files into raw payment maps.
///
/// Supports multi-tab (worksheet) parsing. Each tab is checked independently
/// for the 3 required columns. A file is "successful" if at least one tab
/// has valid data.
class ExcelParser {
  /// Parses a single Excel file from [filePath].
  ExcelParseResult parseFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      return _parseExcel(excel, fileName);
    } catch (e) {
      return ExcelParseResult(
        fileName: fileName,
        rows: [],
        errors: ['فشل قراءة الملف: $e'],
      );
    }
  }

  /// Parses an Excel object across all its worksheets.
  ExcelParseResult _parseExcel(Excel excel, String fileName) {
    final allRows = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.isEmpty) continue;

      final mapping = _findColumnMapping(sheet.rows.first);
      if (mapping == null) {
        errors.add('التبويب "$sheetName": لم يتم العثور على الأعمدة المطلوبة');
        continue;
      }

      final sheetRows = _parseSheet(sheet, mapping);
      allRows.addAll(sheetRows);
    }

    return ExcelParseResult(fileName: fileName, rows: allRows, errors: errors);
  }

  /// Tries to find column indices from the header row.
  /// Returns null if required columns (account, amount, date) are missing.
  _ColumnMapping? _findColumnMapping(List<Data?> headerRow) {
    int? accountIdx;
    int? amountIdx;
    int? dateIdx;
    int? subscriberNameIdx;
    int? stampIdx;

    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell == null) continue;

      final headerText = _extractCellText(cell).trim().toLowerCase();
      if (headerText.isEmpty) continue;

      if (accountIdx == null && _matchesAlias(headerText, accountAliases)) {
        accountIdx = i;
      } else if (amountIdx == null &&
          _matchesAlias(headerText, amountAliases)) {
        amountIdx = i;
      } else if (dateIdx == null && _matchesAlias(headerText, dateAliases)) {
        dateIdx = i;
      } else if (subscriberNameIdx == null &&
          _matchesAlias(headerText, subscriberNameAliases)) {
        subscriberNameIdx = i;
      } else if (stampIdx == null && _matchesAlias(headerText, stampAliases)) {
        stampIdx = i;
      }
    }

    if (accountIdx == null || amountIdx == null || dateIdx == null) {
      return null;
    }

    return _ColumnMapping(
      accountIndex: accountIdx,
      amountIndex: amountIdx,
      dateIndex: dateIdx,
      subscriberNameIndex: subscriberNameIdx,
      stampIndex: stampIdx,
    );
  }

  /// Parses data rows from a worksheet using the column mapping.
  List<Map<String, dynamic>> _parseSheet(Sheet sheet, _ColumnMapping mapping) {
    final rows = <Map<String, dynamic>>[];

    // Skip header row (index 0), parse data rows
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final parsed = _parseRow(row, mapping);
      if (parsed != null) rows.add(parsed);
    }

    return rows;
  }

  /// Parses a single row into a payment map.
  /// Returns null if required fields are missing or invalid.
  Map<String, dynamic>? _parseRow(List<Data?> row, _ColumnMapping mapping) {
    final accountValue = _extractCellValue(row, mapping.accountIndex);
    final amountValue = _extractCellValue(row, mapping.amountIndex);
    final dateValue = _extractCellValue(row, mapping.dateIndex);

    // All 3 required fields must be present
    if (accountValue == null || amountValue == null || dateValue == null) {
      return null;
    }

    final accountNumber = _parseAccountNumber(accountValue);
    final amount = _parseAmount(amountValue);
    final paymentDate = _parseDate(dateValue, row, mapping.dateIndex);

    if (accountNumber == null || amount == null || paymentDate == null) {
      return null;
    }

    final result = <String, dynamic>{
      'reference_account_number': accountNumber,
      'amount': amount,
      'payment_date': paymentDate,
    };

    // Optional fields
    if (mapping.subscriberNameIndex != null) {
      final name = _extractCellValue(row, mapping.subscriberNameIndex!);
      if (name != null) {
        final nameStr = name.toString().trim();
        if (nameStr.isNotEmpty) result['subscriber_name'] = nameStr;
      }
    }

    if (mapping.stampIndex != null) {
      final stamp = _extractCellValue(row, mapping.stampIndex!);
      if (stamp != null) {
        final stampStr = stamp.toString().trim();
        if (stampStr.isNotEmpty) result['stamp_number'] = stampStr;
      }
    }

    return result;
  }

  // ─── Cell Value Extraction ───────────────────────────────────────

  /// Extracts the raw value from a cell at the given index.
  dynamic _extractCellValue(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null) return null;
    return cell.value;
  }

  /// Extracts text representation from a cell for header matching.
  String _extractCellText(Data cell) {
    final value = cell.value;
    if (value == null) return '';

    return switch (value) {
      TextCellValue() => value.value.toString(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      _ => value.toString(),
    };
  }

  // ─── Value Parsing ───────────────────────────────────────────────

  /// Parses an account number from various cell value types.
  int? _parseAccountNumber(dynamic value) {
    return switch (value) {
      IntCellValue() => value.value,
      DoubleCellValue() => value.value.toInt(),
      TextCellValue() => int.tryParse(value.value.toString().trim()),
      _ => int.tryParse(value.toString().trim()),
    };
  }

  /// Parses an amount from various cell value types.
  double? _parseAmount(dynamic value) {
    return switch (value) {
      DoubleCellValue() => value.value,
      IntCellValue() => value.value.toDouble(),
      TextCellValue() => double.tryParse(value.value.toString().trim()),
      _ => double.tryParse(value.toString().trim()),
    };
  }

  /// Parses a date into a Unix timestamp from various cell value types.
  int? _parseDate(dynamic value, List<Data?> row, int index) {
    return switch (value) {
      DateCellValue() => DateTime(
        value.year,
        value.month,
        value.day,
      ).millisecondsSinceEpoch,
      DateTimeCellValue() => DateTime(
        value.year,
        value.month,
        value.day,
      ).millisecondsSinceEpoch,
      IntCellValue() => _tryParseExcelSerialDate(value.value.toDouble()),
      DoubleCellValue() => _tryParseExcelSerialDate(value.value),
      TextCellValue() => _tryParseDateString(value.value.toString().trim()),
      _ => _tryParseDateString(value.toString().trim()),
    };
  }

  /// Tries to parse a date string in common formats.
  int? _tryParseDateString(String text) {
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed.millisecondsSinceEpoch;

    // Try common date formats: dd/MM/yyyy, dd-MM-yyyy
    final parts = text.split(RegExp(r'[/\-.]'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day).millisecondsSinceEpoch;
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  /// Converts Excel serial date number to Unix timestamp.
  /// Excel dates start from 1900-01-01 (serial 1).
  int? _tryParseExcelSerialDate(double serial) {
    if (serial < 1 || serial > 2958465) return null; // Reasonable range

    // Excel epoch: 1899-12-30 (accounting for the 1900 leap year bug)
    final excelEpoch = DateTime(1899, 12, 30);
    final date = excelEpoch.add(Duration(days: serial.toInt()));
    return date.millisecondsSinceEpoch;
  }

  /// Checks if header text matches any alias in the list.
  bool _matchesAlias(String headerText, List<String> aliases) {
    return aliases.any((alias) => alias.toLowerCase() == headerText);
  }
}
