import 'dart:io';
import 'package:excel/excel.dart' hide Border;

/// Builds an Excel file with one row per subscriber group.
///
/// Column layout: [#, اسم المشترك, account1, account2, ...]
/// The account columns are variable-width, expanding per group.
class SubscribersExportService {
  /// Builds an Excel workbook from [groups] and returns the raw bytes.
  ///
  /// [groups] is the result of DatabaseService.getAllGroupsWithAccounts():
  /// each entry has 'id' (int), 'name' (String), 'accounts' (`List<int>`).
  ///
  /// Returns null if encoding fails.
  List<int>? buildExcelBytes(List<Map<String, dynamic>> groups) {
    final excel = Excel.createExcel();
    final sheet = excel['المشتركين'];
    excel.delete('Sheet1');

    _writeHeaders(sheet);
    _writeRows(sheet, groups);

    return excel.save();
  }

  /// Writes the file bytes to [path].
  void writeToFile(String path, List<int> bytes) {
    File(path).writeAsBytesSync(bytes);
  }

  void _writeHeaders(Sheet sheet) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('#');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        TextCellValue('اسم المشترك');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
        TextCellValue('ارقام الحساب');
  }

  void _writeRows(Sheet sheet, List<Map<String, dynamic>> groups) {
    for (var rowIndex = 0; rowIndex < groups.length; rowIndex++) {
      final group = groups[rowIndex];
      final accounts = group['accounts'] as List<int>;
      final excelRow = rowIndex + 1; // offset for header

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: excelRow))
          .value = IntCellValue(
        group['id'] as int,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: excelRow))
          .value = TextCellValue(
        group['name'] as String,
      );

      for (var col = 0; col < accounts.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col + 2,
                rowIndex: excelRow,
              ),
            )
            .value = IntCellValue(
          accounts[col],
        );
      }
    }
  }
}
