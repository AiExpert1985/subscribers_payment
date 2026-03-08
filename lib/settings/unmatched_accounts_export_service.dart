import 'dart:io';
import 'package:excel/excel.dart';

/// Builds and writes an Excel file from a list of unmatched account numbers.
///
/// Single column: رقم الحساب — one account number per row.
class UnmatchedAccountsExportService {
  /// Builds an Excel workbook from [accountNumbers] and returns the raw bytes.
  /// Returns null if the excel package fails to encode.
  List<int>? buildExcelBytes(List<int> accountNumbers) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('رقم الحساب');

    for (var row = 0; row < accountNumbers.length; row++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1))
          .value = TextCellValue(accountNumbers[row].toString());
    }

    return excel.save();
  }

  /// Writes the Excel bytes to the file at [path].
  void writeToFile(String path, List<int> bytes) {
    File(path).writeAsBytesSync(bytes);
  }
}
