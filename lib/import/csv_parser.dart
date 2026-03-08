import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'column_aliases.dart';
import 'excel_parser.dart';

class _ColumnMapping {
  final int accountIndex;
  final int amountIndex;
  final int dateIndex;
  final int? subscriberNameIndex;
  final int? stampIndex;
  final int? typeIndex;
  final int? addressIndex;

  _ColumnMapping({
    required this.accountIndex,
    required this.amountIndex,
    required this.dateIndex,
    this.subscriberNameIndex,
    this.stampIndex,
    this.typeIndex,
    this.addressIndex,
  });
}

/// Parses CSV files into raw payment maps.
///
/// Reuses [ExcelParseResult] as the return type so the rest of the import
/// pipeline is format-agnostic. Auto-detects comma / semicolon / tab delimiters
/// and strips the UTF-8 BOM when present.
class CsvParser {
  ExcelParseResult parseFile(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;

    try {
      final sw = Stopwatch()..start();

      debugPrint('[CsvParser] [$fileName] Step 1/2: Reading file bytes...');
      final bytes = File(filePath).readAsBytesSync();

      var content = utf8.decode(bytes, allowMalformed: true);

      // Strip UTF-8 BOM (\uFEFF) that Excel sometimes writes.
      if (content.startsWith('\uFEFF')) content = content.substring(1);

      // Normalize line endings so the CSV converter sees a consistent \n.
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      debugPrint(
        '[CsvParser] [$fileName] Step 2/2: Parsing CSV... '
        '(${bytes.length} bytes read in ${sw.elapsedMilliseconds}ms)',
      );

      final delimiter = _detectDelimiter(content);
      debugPrint(
        '[CsvParser] [$fileName] Detected delimiter: '
        '"${delimiter == '\t' ? 'TAB' : delimiter}"',
      );

      final csvRows = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(content);

      debugPrint(
        '[CsvParser] [$fileName] CSV parsed: ${csvRows.length} rows '
        '(${sw.elapsedMilliseconds}ms)',
      );

      final result = _parseRows(csvRows, fileName, sw);
      debugPrint(
        '[CsvParser] [$fileName] Done: ${result.rows.length} rows accepted '
        '(${sw.elapsedMilliseconds}ms total)',
      );
      return result;
    } catch (e) {
      debugPrint('[CsvParser] Failed to parse "$fileName": $e');
      return ExcelParseResult(
        fileName: fileName,
        rows: [],
        errors: ['فشل قراءة الملف: $e'],
      );
    }
  }

  /// Picks the most frequent candidate delimiter from the header line.
  String _detectDelimiter(String content) {
    final firstLine = content.split('\n').first;
    final commas = ','.allMatches(firstLine).length;
    final semicolons = ';'.allMatches(firstLine).length;
    final tabs = '\t'.allMatches(firstLine).length;

    if (tabs >= semicolons && tabs >= commas) return '\t';
    if (semicolons >= commas) return ';';
    return ',';
  }

  ExcelParseResult _parseRows(
    List<List<dynamic>> csvRows,
    String fileName,
    Stopwatch sw,
  ) {
    if (csvRows.isEmpty) {
      return ExcelParseResult(
        fileName: fileName,
        rows: [],
        errors: ['الملف فارغ'],
      );
    }

    final headerRow = csvRows.first.map((e) => e.toString()).toList();
    final mapping = _findColumnMapping(headerRow);
    if (mapping == null) {
      return ExcelParseResult(
        fileName: fileName,
        rows: [],
        errors: ['لم يتم العثور على الأعمدة المطلوبة (الحساب، المبلغ، التاريخ)'],
      );
    }

    final rows = <Map<String, dynamic>>[];
    final total = csvRows.length - 1;

    for (int i = 1; i < csvRows.length; i++) {
      if (i % 50000 == 0) {
        debugPrint(
          '[CsvParser] Parsed $i / $total rows (${sw.elapsedMilliseconds}ms)',
        );
      }
      final parsed = _parseRow(csvRows[i], mapping);
      if (parsed != null) rows.add(parsed);
    }

    return ExcelParseResult(fileName: fileName, rows: rows, errors: []);
  }

  _ColumnMapping? _findColumnMapping(List<String> headerRow) {
    int? accountIdx;
    int? amountIdx;
    int? dateIdx;
    int? subscriberNameIdx;
    int? stampIdx;
    int? typeIdx;
    int? addressIdx;

    for (int i = 0; i < headerRow.length; i++) {
      final text = headerRow[i].trim().toLowerCase();
      if (text.isEmpty) continue;

      if (accountIdx == null && _matches(text, accountAliases)) {
        accountIdx = i;
      } else if (amountIdx == null && _matches(text, amountAliases)) {
        amountIdx = i;
      } else if (dateIdx == null && _matches(text, dateAliases)) {
        dateIdx = i;
      } else if (subscriberNameIdx == null &&
          _matches(text, subscriberNameAliases)) {
        subscriberNameIdx = i;
      } else if (stampIdx == null && _matches(text, stampAliases)) {
        stampIdx = i;
      } else if (typeIdx == null && _matches(text, typeAliases)) {
        typeIdx = i;
      } else if (addressIdx == null && _matches(text, addressAliases)) {
        addressIdx = i;
      }
    }

    if (accountIdx == null || amountIdx == null || dateIdx == null) return null;

    return _ColumnMapping(
      accountIndex: accountIdx,
      amountIndex: amountIdx,
      dateIndex: dateIdx,
      subscriberNameIndex: subscriberNameIdx,
      stampIndex: stampIdx,
      typeIndex: typeIdx,
      addressIndex: addressIdx,
    );
  }

  Map<String, dynamic>? _parseRow(List<dynamic> row, _ColumnMapping mapping) {
    final accountRaw = _cellString(row, mapping.accountIndex);
    final amountRaw = _cellString(row, mapping.amountIndex);
    final dateRaw = _cellString(row, mapping.dateIndex);

    if (accountRaw == null || amountRaw == null || dateRaw == null) return null;
    if (!accountRaw.startsWith('10')) return null;

    final accountNumber = int.tryParse(accountRaw);
    final amount = double.tryParse(amountRaw);
    final paymentDate = _parseDate(dateRaw);

    if (accountNumber == null || amount == null || paymentDate == null) {
      return null;
    }

    final result = <String, dynamic>{
      'reference_account_number': accountNumber,
      'amount': amount,
      'payment_date': paymentDate,
    };

    if (mapping.subscriberNameIndex != null) {
      final name = _cellString(row, mapping.subscriberNameIndex!);
      if (name != null) result['subscriber_name'] = name;
    }
    if (mapping.stampIndex != null) {
      final stamp = _cellString(row, mapping.stampIndex!);
      if (stamp != null) result['stamp_number'] = stamp;
    }
    if (mapping.typeIndex != null) {
      final type = _cellString(row, mapping.typeIndex!);
      if (type != null) result['type'] = type;
    }
    if (mapping.addressIndex != null) {
      final address = _cellString(row, mapping.addressIndex!);
      if (address != null) result['address'] = address;
    }

    return result;
  }

  String? _cellString(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final text = row[index].toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _parseDate(String text) {
    // ISO / standard formats (e.g. 2019-10-29, 2019-10-29T00:00:00)
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed.millisecondsSinceEpoch;

    // Excel serial date exported as a plain number
    final serial = double.tryParse(text);
    if (serial != null) {
      final ts = _tryParseExcelSerialDate(serial);
      if (ts != null) return ts;
    }

    // Compact yyyyMMdd (e.g. 20191029)
    if (text.length == 8) {
      final year = int.tryParse(text.substring(0, 4));
      final month = int.tryParse(text.substring(4, 6));
      final day = int.tryParse(text.substring(6, 8));
      if (year != null && month != null && day != null) {
        try {
          return DateTime(year, month, day).millisecondsSinceEpoch;
        } catch (_) {}
      }
    }

    // dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy
    final parts = text.split(RegExp(r'[/\-.]'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day).millisecondsSinceEpoch;
        } catch (_) {}
      }
    }

    return null;
  }

  int? _tryParseExcelSerialDate(double serial) {
    if (serial < 1 || serial > 2958465) return null;
    final excelEpoch = DateTime(1899, 12, 30);
    final date = excelEpoch.add(Duration(days: serial.toInt()));
    return date.millisecondsSinceEpoch;
  }

  bool _matches(String text, List<String> aliases) =>
      aliases.any((a) => a.toLowerCase() == text);
}
