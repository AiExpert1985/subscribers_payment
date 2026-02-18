import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
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
  // Search controllers — one per column
  final _accountSearchCtrl = TextEditingController();
  final _nameSearchCtrl = TextEditingController();
  final _dateSearchCtrl = TextEditingController();
  final _amountSearchCtrl = TextEditingController();
  final _stampSearchCtrl = TextEditingController();

  // Debounce timer for search
  Timer? _debounce;

  // Tracks which cell is being edited: "rowId-columnName"
  String? _editingCell;
  final _editController = TextEditingController();

  // Import loading state
  bool _isImporting = false;

  // Export loading state
  bool _isExporting = false;

  @override
  void dispose() {
    _accountSearchCtrl.dispose();
    _nameSearchCtrl.dispose();
    _dateSearchCtrl.dispose();
    _amountSearchCtrl.dispose();
    _stampSearchCtrl.dispose();
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
            // ── Action Bar ──
            _buildActionBar(importResult),
            const SizedBox(height: 16),

            // ── Table with search ──
            Expanded(
              child: paymentsAsync.when(
                data: (payments) => _buildPaymentsTable(payments),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('خطأ: $error')),
              ),
            ),

            // ── Pagination ──
            const SizedBox(height: 8),
            _buildPagination(currentPage, totalPagesAsync),

            // ── Footer ──
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
        FilledButton.icon(
          onPressed: _showAddPaymentDialog,
          icon: const Icon(Icons.add),
          label: const Text('إضافة تسديد'),
        ),
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

  Widget _buildPaymentsTable(List<Payment> payments) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search row
          _buildSearchRow(),
          const SizedBox(height: 4),

          // Data table
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(label: Text('رقم الحساب')),
                DataColumn(label: Text('اسم المشترك')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('المبلغ')),
                DataColumn(label: Text('رقم الختم')),
                DataColumn(label: Text('')), // Delete column
              ],
              rows: payments.map((p) => _buildDataRow(p)).toList(),
            ),
          ),

          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'لا توجد تسديدات',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: _searchField(
            _accountSearchCtrl,
            'reference_account_number',
            'بحث...',
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _searchField(_nameSearchCtrl, 'subscriber_name', 'بحث...'),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _searchField(_dateSearchCtrl, 'payment_date', 'بحث...'),
        ),
        const SizedBox(width: 4),
        Expanded(child: _searchField(_amountSearchCtrl, 'amount', 'بحث...')),
        const SizedBox(width: 4),
        Expanded(
          child: _searchField(_stampSearchCtrl, 'stamp_number', 'بحث...'),
        ),
        const SizedBox(width: 48), // Space for delete column
      ],
    );
  }

  Widget _searchField(
    TextEditingController controller,
    String columnKey,
    String hint,
  ) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (value) => _onSearchChanged(columnKey, value),
      ),
    );
  }

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
      ref.read(currentPageProvider.notifier).state = 0; // Reset to first page
    });
  }

  DataRow _buildDataRow(Payment payment) {
    final dateFormatted = _formatDate(payment.paymentDate);

    return DataRow(
      cells: [
        _buildEditableCell(
          payment,
          'reference_account_number',
          payment.referenceAccountNumber.toString(),
        ),
        _buildEditableCell(
          payment,
          'subscriber_name',
          payment.subscriberName ?? '',
        ),
        _buildEditableCell(payment, 'payment_date', dateFormatted),
        _buildEditableCell(payment, 'amount', payment.amount.toString()),
        _buildEditableCell(payment, 'stamp_number', payment.stampNumber ?? ''),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(payment),
            tooltip: 'حذف',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
    );
  }

  DataCell _buildEditableCell(
    Payment payment,
    String columnName,
    String displayValue,
  ) {
    final cellKey = '${payment.id}-$columnName';
    final isEditing = _editingCell == cellKey;

    if (isEditing) {
      return DataCell(
        SizedBox(
          width: double.infinity,
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
        ),
      );
    }

    return DataCell(
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(displayValue, style: const TextStyle(fontSize: 13)),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: InkWell(
              onTap: () => _startEdit(cellKey, displayValue),
              child: const Icon(Icons.edit, size: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.chevron_right),
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
            icon: const Icon(Icons.chevron_left),
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

    // Auto-create account/group on manual add too
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
    // Try yyyy/MM/dd format
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
