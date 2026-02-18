import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../data/database_service.dart';
import '../data/models/payment.dart';
import '../data/providers.dart';
import '../import/import_service.dart';
import 'add_payment_dialog.dart';
import 'payment_export_service.dart';
import 'payments_providers.dart';

/// Main payments screen with import, search, paginated table, and inline editing.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  // Search controllers — one per text-search column
  final _accountSearchCtrl = TextEditingController();
  final _nameSearchCtrl = TextEditingController();
  final _amountSearchCtrl = TextEditingController();
  final _stampSearchCtrl = TextEditingController();
  final _typeSearchCtrl = TextEditingController();
  final _addressSearchCtrl = TextEditingController();

  // Date range filter (replaces single date text search)
  DateTime? _dateFromFilter;
  DateTime? _dateToFilter;

  // Debounce timer for search
  Timer? _debounce;

  // Tracks which cell is being edited: "rowId-columnName"
  String? _editingCell;
  final _editController = TextEditingController();

  // Hovered row id for row highlight
  int? _hoveredPaymentId;

  // Loading states
  bool _isImporting = false;
  bool _isExporting = false;

  // Fixed column widths
  static const double _kDeleteColWidth = 44.0;
  static const double _kNumberColWidth = 40.0;
  static const double _kAddBtnWidth = 148.0;

  @override
  void dispose() {
    _accountSearchCtrl.dispose();
    _nameSearchCtrl.dispose();
    _amountSearchCtrl.dispose();
    _stampSearchCtrl.dispose();
    _typeSearchCtrl.dispose();
    _addressSearchCtrl.dispose();
    _debounce?.cancel();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final totalPagesAsync = ref.watch(totalPagesProvider);
    final currentPage = ref.watch(currentPageProvider);
    final importResult = ref.watch(importResultProvider);
    final lastImport = ref.watch(lastImportTimeProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionBar(importResult),
            const SizedBox(height: 12),
            Expanded(
              child: paymentsAsync.when(
                data: (payments) =>
                    _buildPaymentsTable(payments, currentPage),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('خطأ: $error')),
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(currentPage, totalPagesAsync),
            if (lastImport != null) _buildFooter(lastImport),
          ],
        ),
      ),
    );
  }

  // ─── Action Bar ────────────────────────────────────────────────────

  Widget _buildActionBar(ImportResult? importResult) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: _isImporting ? null : _importFiles,
          icon: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: const Text('استيراد ملف التسديدات'),
        ),
        FilledButton.tonalIcon(
          onPressed: _isExporting ? null : _exportToExcel,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: const Text('تصدير إلى Excel'),
        ),
        if (importResult != null) _buildImportSummary(importResult),
      ],
    );
  }

  Widget _buildImportSummary(ImportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (result.successfulFiles > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 4),
              Text(
                '${result.successfulFiles} ملفات ناجحة'
                ' (${result.totalRowsInserted} سجل)',
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ),
        if (result.failedFiles > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              Text(
                '${result.failedFiles} ملفات فاشلة',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
      ],
    );
  }

  // ─── Payments Table ────────────────────────────────────────────────

  Widget _buildPaymentsTable(List<Payment> payments, int currentPage) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchRow(),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                _buildHeaderRow(),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                ...payments.asMap().entries.map(
                  (e) => _buildDataRowWidget(e.value, e.key, currentPage),
                ),
                if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'لا توجد تسديدات',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search Row ────────────────────────────────────────────────────

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: _kDeleteColWidth),
          SizedBox(width: _kNumberColWidth),
          Expanded(
            flex: 2,
            child: _textSearchField(
              _accountSearchCtrl,
              'reference_account_number',
              'رقم الحساب',
            ),
          ),
          Expanded(
            flex: 3,
            child: _textSearchField(
              _nameSearchCtrl,
              'subscriber_name',
              'اسم المشترك',
            ),
          ),
          Expanded(flex: 3, child: _buildDateRangeSearchField()),
          Expanded(
            flex: 2,
            child: _textSearchField(_amountSearchCtrl, 'amount', 'المبلغ'),
          ),
          Expanded(
            flex: 2,
            child: _textSearchField(
              _stampSearchCtrl,
              'stamp_number',
              'رقم الختم',
            ),
          ),
          Expanded(
            flex: 2,
            child: _textSearchField(_typeSearchCtrl, 'type', 'النوع'),
          ),
          Expanded(
            flex: 3,
            child: _textSearchField(
              _addressSearchCtrl,
              'address',
              'العنوان',
            ),
          ),
          SizedBox(width: _kAddBtnWidth),
        ],
      ),
    );
  }

  Widget _textSearchField(
    TextEditingController ctrl,
    String columnKey,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) => _onSearchChanged(columnKey, value),
        ),
      ),
    );
  }

  Widget _buildDateRangeSearchField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 130;
        final fromField = _datePickerSearchField(
          value: _dateFromFilter,
          hint: 'من',
          onChanged: _onDateFromChanged,
        );
        final toField = _datePickerSearchField(
          value: _dateToFilter,
          hint: 'إلى',
          onChanged: _onDateToChanged,
        );

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [fromField, const SizedBox(height: 2), toField],
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Expanded(child: fromField),
              const SizedBox(width: 2),
              Expanded(child: toField),
            ],
          ),
        );
      },
    );
  }

  Widget _datePickerSearchField({
    required DateTime? value,
    required String hint,
    required void Function(DateTime?) onChanged,
  }) {
    final text = value != null
        ? '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}'
        : null;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text ?? hint,
                style: TextStyle(
                  fontSize: 11,
                  color: text != null ? null : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.clear,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
              )
            else
              Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Header Row ────────────────────────────────────────────────────

  Widget _buildHeaderRow() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: _kDeleteColWidth),
          SizedBox(
            width: _kNumberColWidth,
            child: const Center(child: Text('#', style: headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: _columnHeader('رقم الحساب', headerStyle),
          ),
          Expanded(
            flex: 3,
            child: _columnHeader('اسم المشترك', headerStyle),
          ),
          Expanded(flex: 3, child: _columnHeader('التاريخ', headerStyle)),
          Expanded(flex: 2, child: _columnHeader('المبلغ', headerStyle)),
          Expanded(
            flex: 2,
            child: _columnHeader('رقم الختم', headerStyle),
          ),
          Expanded(flex: 2, child: _columnHeader('النوع', headerStyle)),
          Expanded(flex: 3, child: _columnHeader('العنوان', headerStyle)),
          SizedBox(
            width: _kAddBtnWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.icon(
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'إضافة تسديد',
                  style: TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnHeader(String label, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(label, style: style, overflow: TextOverflow.ellipsis),
    );
  }

  // ─── Data Row ──────────────────────────────────────────────────────

  Widget _buildDataRowWidget(Payment payment, int index, int currentPage) {
    final rowNumber =
        currentPage * DatabaseService.defaultPageSize + index + 1;
    final isHovered = _hoveredPaymentId == payment.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredPaymentId = payment.id),
      onExit: (_) => setState(() => _hoveredPaymentId = null),
      child: Container(
        decoration: BoxDecoration(
          color: isHovered ? Colors.grey.shade100 : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _kDeleteColWidth,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: () => _confirmDelete(payment),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            SizedBox(
              width: _kNumberColWidth,
              child: Center(
                child: Text(
                  '$rowNumber',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEditableCell(
                payment,
                'reference_account_number',
                payment.referenceAccountNumber.toString(),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildEditableCell(
                payment,
                'subscriber_name',
                payment.subscriberName ?? '',
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildEditableCell(
                payment,
                'payment_date',
                _formatDate(payment.paymentDate),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEditableCell(
                payment,
                'amount',
                payment.amount.toString(),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEditableCell(
                payment,
                'stamp_number',
                payment.stampNumber ?? '',
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEditableCell(
                payment,
                'type',
                payment.type ?? '',
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildEditableCell(
                payment,
                'address',
                payment.address ?? '',
              ),
            ),
            SizedBox(width: _kAddBtnWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableCell(
    Payment payment,
    String columnName,
    String displayValue,
  ) {
    final cellKey = '${payment.id}-$columnName';
    final isEditing = _editingCell == cellKey;

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: TextField(
          controller: _editController,
          autofocus: true,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveEdit(payment, columnName),
          onTapOutside: (_) => _saveEdit(payment, columnName),
        ),
      );
    }

    return Tooltip(
      message: 'تعديل',
      child: GestureDetector(
        onTap: () => _startEdit(cellKey, displayValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            displayValue,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ─── Search Callbacks ──────────────────────────────────────────────

  void _onSearchChanged(String columnKey, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final current = Map<String, String>.from(
        ref.read(paymentFiltersProvider),
      );
      if (value.trim().isEmpty) {
        current.remove(columnKey);
      } else {
        current[columnKey] = value.trim();
      }
      ref.read(paymentFiltersProvider.notifier).state = current;
      ref.read(currentPageProvider.notifier).state = 0;
    });
  }

  void _onDateFromChanged(DateTime? date) {
    setState(() => _dateFromFilter = date);
    final current = Map<String, String>.from(ref.read(paymentFiltersProvider));
    if (date == null) {
      current.remove('payment_date_from');
    } else {
      final ts = DateTime(
        date.year,
        date.month,
        date.day,
      ).millisecondsSinceEpoch;
      current['payment_date_from'] = ts.toString();
    }
    ref.read(paymentFiltersProvider.notifier).state = current;
    ref.read(currentPageProvider.notifier).state = 0;
  }

  void _onDateToChanged(DateTime? date) {
    setState(() => _dateToFilter = date);
    final current = Map<String, String>.from(ref.read(paymentFiltersProvider));
    if (date == null) {
      current.remove('payment_date_to');
    } else {
      final ts = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch;
      current['payment_date_to'] = ts.toString();
    }
    ref.read(paymentFiltersProvider.notifier).state = current;
    ref.read(currentPageProvider.notifier).state = 0;
  }

  // ─── Edit ──────────────────────────────────────────────────────────

  void _startEdit(String cellKey, String currentValue) {
    setState(() {
      _editingCell = cellKey;
      _editController.text = currentValue;
    });
  }

  Future<void> _saveEdit(Payment payment, String columnName) async {
    final newValue = _editController.text.trim();
    setState(() => _editingCell = null);

    final updates = <String, dynamic>{};

    switch (columnName) {
      case 'reference_account_number':
        final parsed = int.tryParse(newValue);
        if (parsed == null) return;
        updates['reference_account_number'] = parsed;
      case 'subscriber_name':
        updates['subscriber_name'] = newValue.isEmpty ? null : newValue;
      case 'payment_date':
        final parsed = _parseDateInput(newValue);
        if (parsed == null) return;
        updates['payment_date'] = parsed;
      case 'amount':
        final parsed = double.tryParse(newValue);
        if (parsed == null) return;
        updates['amount'] = parsed;
      case 'stamp_number':
        updates['stamp_number'] = newValue.isEmpty ? null : newValue;
      case 'type':
        updates['type'] = newValue.isEmpty ? null : newValue;
      case 'address':
        updates['address'] = newValue.isEmpty ? null : newValue;
    }

    if (updates.isEmpty || payment.id == null) return;

    final db = ref.read(databaseServiceProvider);
    await db.updatePayment(payment.id!, updates);
    ref.invalidate(paymentsProvider);
    ref.invalidate(totalPaymentCountProvider);
  }

  // ─── Pagination ────────────────────────────────────────────────────

  Widget _buildPagination(int currentPage, AsyncValue<int> totalPagesAsync) {
    return totalPagesAsync.when(
      data: (totalPages) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () => ref.read(currentPageProvider.notifier).state--
                : null,
            tooltip: 'الصفحة السابقة',
          ),
          const SizedBox(width: 8),
          Text(
            'صفحة ${currentPage + 1} من $totalPages',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => ref.read(currentPageProvider.notifier).state++
                : null,
            tooltip: 'الصفحة التالية',
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────

  Widget _buildFooter(DateTime lastImport) {
    final formatted = intl.DateFormat('yyyy/MM/dd HH:mm').format(lastImport);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'تم تحديث البيانات في $formatted',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _showAddPaymentDialog() async {
    final payment = await showDialog<Payment>(
      context: context,
      builder: (_) => const AddPaymentDialog(),
    );
    if (payment == null) return;

    final db = ref.read(databaseServiceProvider);

    await db.findOrCreateAccountAndGroup(
      payment.referenceAccountNumber,
      subscriberName: payment.subscriberName,
    );

    await db.insertPayment(payment.toMap());
    ref.invalidate(paymentsProvider);
    ref.invalidate(totalPaymentCountProvider);
  }

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: true,
      dialogTitle: 'اختر ملفات التسديدات',
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isImporting = true);

    final filePaths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    final db = ref.read(databaseServiceProvider);
    final importService = ImportService(db);
    final importResult = await importService.importFiles(filePaths);

    ref.read(importResultProvider.notifier).state = importResult;
    ref.read(lastImportTimeProvider.notifier).state = DateTime.now();
    ref.invalidate(paymentsProvider);
    ref.invalidate(totalPaymentCountProvider);

    setState(() => _isImporting = false);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      final filters = ref.read(paymentFiltersProvider);
      final db = ref.read(databaseServiceProvider);
      final rows = await db.getPaymentsFiltered(filters: filters);
      final payments = rows.map((r) => Payment.fromMap(r)).toList();

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف التسديدات',
        fileName: 'تسديدات.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (savePath == null) return;

      final exportService = PaymentExportService();
      final bytes = exportService.buildExcelBytes(payments);

      if (bytes == null) {
        _showExportError('فشل إنشاء ملف Excel');
        return;
      }

      exportService.writeToFile(savePath, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير ${payments.length} سجل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showExportError('خطأ أثناء التصدير: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _confirmDelete(Payment payment) async {
    if (payment.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف التسديد لحساب ${payment.referenceAccountNumber}'
          ' بمبلغ ${payment.amount}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = ref.read(databaseServiceProvider);
    await db.deletePayment(payment.id!);
    ref.invalidate(paymentsProvider);
    ref.invalidate(totalPaymentCountProvider);
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  int? _parseDateInput(String text) {
    final parts = text.split(RegExp(r'[/\-.]'));
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        try {
          return DateTime(year, month, day).millisecondsSinceEpoch;
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
}
