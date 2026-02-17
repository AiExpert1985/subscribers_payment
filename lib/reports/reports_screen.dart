import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/payment.dart';
import '../data/providers.dart';

/// Reports screen: generate subscriber-level payment reports by account number.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _accountCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _errorMessage;
  _GeneratedReport? _report;

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputsCard(context),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorBanner(_errorMessage!),
            ],
            if (_report != null) ...[
              const SizedBox(height: 12),
              _buildReportCard(_report!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'رقم الحساب',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'من تاريخ',
                    value: _fromDate,
                    onPick: () => _pickDate(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      onSelected: (date) => setState(() => _fromDate = date),
                    ),
                    onClear: _fromDate == null
                        ? null
                        : () => setState(() => _fromDate = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'إلى تاريخ',
                    value: _toDate,
                    onPick: () => _pickDate(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      onSelected: (date) => setState(() => _toDate = date),
                    ),
                    onClear: _toDate == null
                        ? null
                        : () => setState(() => _toDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Generate Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(_GeneratedReport report) {
    final numberFormat = intl.NumberFormat('#,##0.###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'تقرير المشترك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _printReport,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _reportLine(
              'رقم الحساب المدخل',
              report.searchedAccountNumber.toString(),
            ),
            _reportLine('اسم المشترك', report.subscriberName),
            _reportLine('الحسابات', report.accountNumbers.join(' - ')),
            _reportLine('الفترة', report.periodLabel),
            _reportLine(
              'إجمالي المبلغ',
              numberFormat.format(report.totalAmount),
            ),
            _reportLine(
              'تاريخ الإنشاء',
              intl.DateFormat('yyyy/MM/dd HH:mm').format(report.generatedAt),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('رقم الحساب')),
                  DataColumn(label: Text('اسم المشترك')),
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('المبلغ')),
                  DataColumn(label: Text('رقم الختم')),
                ],
                rows: report.payments
                    .map(
                      (payment) => DataRow(
                        cells: [
                          DataCell(
                            Text(payment.referenceAccountNumber.toString()),
                          ),
                          DataCell(Text(report.subscriberName)),
                          DataCell(
                            Text(_formatDateFromTimestamp(payment.paymentDate)),
                          ),
                          DataCell(Text(numberFormat.format(payment.amount))),
                          DataCell(Text(payment.stampNumber ?? '')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            if (report.payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'لا توجد تسديدات ضمن الفترة المحددة',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    final accountNumber = int.tryParse(_accountCtrl.text.trim());
    if (accountNumber == null) {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم حساب صحيح';
        _report = null;
      });
      return;
    }

    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      setState(() {
        _errorMessage = 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية';
        _report = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = ref.read(databaseServiceProvider);
    final accountRow = await db.getAccountByNumber(accountNumber);

    if (!mounted) return;

    if (accountRow == null) {
      setState(() {
        _isLoading = false;
        _report = null;
        _errorMessage = 'المستخدم غير موجود';
      });
      return;
    }

    final groupId = accountRow['subscriber_group_id'] as int;
    final groupRow = await db.getSubscriberGroupById(groupId);
    final accountRows = await db.getAccountsByGroupId(groupId);
    final accountNumbers = accountRows
        .map((row) => row['account_number'] as int)
        .toList();

    final fromTimestamp = _fromDate == null ? null : _startOfDay(_fromDate!);
    final toTimestamp = _toDate == null ? null : _endOfDay(_toDate!);

    final paymentRows = await db.getPaymentsByAccountNumbers(
      accountNumbers: accountNumbers,
      fromDate: fromTimestamp,
      toDate: toTimestamp,
    );
    final payments = paymentRows.map(Payment.fromMap).toList();

    final report = _GeneratedReport(
      searchedAccountNumber: accountNumber,
      subscriberName: (groupRow?['name'] as String?)?.trim().isNotEmpty == true
          ? (groupRow!['name'] as String)
          : '(بدون اسم)',
      accountNumbers: accountNumbers,
      fromDate: _fromDate,
      toDate: _toDate,
      payments: payments,
      generatedAt: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _report = report;
      _errorMessage = null;
    });
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _printReport() async {
    final report = _report;
    if (report == null) return;

    final numberFormat = intl.NumberFormat('#,##0.###');
    final pdfFont = await PdfGoogleFonts.notoNaskhArabicRegular();

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(24),
            theme: pw.ThemeData.withFont(base: pdfFont, bold: pdfFont),
            build: (_) => [
              pw.Text(
                'تقرير المشترك',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 12),
              _pdfLine('اسم المشترك', report.subscriberName),
              _pdfLine(
                'رقم الحساب المدخل',
                report.searchedAccountNumber.toString(),
              ),
              _pdfLine('الحسابات', report.accountNumbers.join(' - ')),
              _pdfLine('الفترة', report.periodLabel),
              _pdfLine(
                'إجمالي المبلغ',
                numberFormat.format(report.totalAmount),
              ),
              _pdfLine(
                'تاريخ الإنشاء',
                intl.DateFormat('yyyy/MM/dd HH:mm').format(report.generatedAt),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'رقم الحساب',
                  'اسم المشترك',
                  'التاريخ',
                  'المبلغ',
                  'رقم الختم',
                ],
                data: report.payments
                    .map(
                      (payment) => [
                        payment.referenceAccountNumber.toString(),
                        report.subscriberName,
                        _formatDateFromTimestamp(payment.paymentDate),
                        numberFormat.format(payment.amount),
                        payment.stampNumber ?? '',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.centerRight,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignments: const {
                  0: pw.Alignment.centerRight,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
            ],
          ),
        );

        return doc.save();
      },
    );
  }

  pw.Widget _pdfLine(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              '$title:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatDateFromTimestamp(int timestamp) {
    return _formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  int _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  int _endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : intl.DateFormat('yyyy/MM/dd').format(value!);

    return InkWell(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value == null
              ? const Icon(Icons.date_range_outlined)
              : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        ),
        child: Text(text),
      ),
    );
  }
}

class _GeneratedReport {
  final int searchedAccountNumber;
  final String subscriberName;
  final List<int> accountNumbers;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Payment> payments;
  final DateTime generatedAt;

  _GeneratedReport({
    required this.searchedAccountNumber,
    required this.subscriberName,
    required this.accountNumbers,
    required this.fromDate,
    required this.toDate,
    required this.payments,
    required this.generatedAt,
  });

  String get periodLabel {
    if (fromDate == null && toDate == null) return 'كل الفترات';

    final formatter = intl.DateFormat('yyyy/MM/dd');
    final start = fromDate == null ? 'البداية' : formatter.format(fromDate!);
    final end = toDate == null ? 'النهاية' : formatter.format(toDate!);
    return '$start - $end';
  }

  double get totalAmount =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
}
