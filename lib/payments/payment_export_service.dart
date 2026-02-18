import 'dart:io';
import 'package:excel/excel.dart';
import '../data/models/payment.dart';

/// Builds and writes an Excel file from a list of payments.
///
/// Column order matches the on-screen payments table:
/// account number, subscriber name, date, amount, stamp number, type, address.
class PaymentExportService {
  static const _headers = [
    'رقم الحساب',
    'اسم المشترك',
    'التاريخ',
    'المبلغ',
    'رقم الختم',
    'النوع',
    'العنوان',
  ];

  /// Builds an Excel workbook from [payments] and returns the raw bytes.
  /// Returns null if the excel package fails to encode.
  List<int>? buildExcelBytes(List<Payment> payments) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    _writeHeaders(sheet);
    _writeRows(sheet, payments);

    return excel.save();
  }

  /// Writes the Excel bytes to the file at [path].
  void writeToFile(String path, List<int> bytes) {
    File(path).writeAsBytesSync(bytes);
  }

  void _writeHeaders(Sheet sheet) {
    for (var col = 0; col < _headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(_headers[col]);
    }
  }

  void _writeRows(Sheet sheet, List<Payment> payments) {
    for (var row = 0; row < payments.length; row++) {
      final p = payments[row];
      final cells = [
        p.referenceAccountNumber.toString(),
        p.subscriberName ?? '',
        _formatDate(p.paymentDate),
        p.amount.toString(),
        p.stampNumber ?? '',
        p.type ?? '',
        p.address ?? '',
      ];

      for (var col = 0; col < cells.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
            )
            .value = TextCellValue(cells[col]);
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }
}
