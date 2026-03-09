import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../data/providers.dart';
import '../accounts/accounts_providers.dart';
import '../payments/payments_providers.dart';
import 'unmatched_accounts_export_service.dart';

/// Settings screen with protected data-reset actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإعدادات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _ResetSection(
              title: 'تصفير بيانات المشتركين',
              description:
                  'يحذف جميع المشتركين وأرقام الحسابات المرتبطة بهم.\n'
                  'لا يؤثر على سجلات التسديدات.',
              warningColor: Colors.orange,
              onConfirmed: () => _resetAccounts(context, ref),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _ResetSection(
              title: 'تصفير بيانات التسديدات',
              description:
                  'يحذف جميع سجلات التسديدات.\n'
                  'لا يؤثر على بيانات المشتركين والحسابات.',
              warningColor: Colors.red,
              onConfirmed: () => _resetPayments(context, ref),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _UnmatchedAccountsSection(
              onPressed: () => _findUnmatchedAccounts(context, ref),
            ),
            const Spacer(),
            const _AboutSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAccounts(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseServiceProvider);
    await db.resetAllAccounts();
    ref.invalidate(subscriberGroupsProvider);
    ref.invalidate(totalAccountGroupsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح جميع بيانات المشتركين')),
      );
    }
  }

  Future<void> _resetPayments(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseServiceProvider);
    await db.resetAllPayments();
    ref.invalidate(paymentsProvider);
    ref.invalidate(totalPaymentCountProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح جميع سجلات التسديدات')),
      );
    }
  }

  Future<void> _findUnmatchedAccounts(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final db = ref.read(databaseServiceProvider);
    final unmatched = await db.getUnmatchedPaymentAccountNumbers();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) =>
          _UnmatchedAccountsResultDialog(accountNumbers: unmatched),
    );
  }
}

/// Section that triggers the unmatched-accounts lookup.
class _UnmatchedAccountsSection extends StatelessWidget {
  final VoidCallback onPressed;

  const _UnmatchedAccountsSection({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الحسابات الغير مسجلة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'يعرض أرقام الحسابات الموجودة في التسديدات والتي لم تُضف لأي مشترك.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.manage_search),
          label: const Text('الحسابات الغير مسجلة'),
        ),
      ],
    );
  }
}

/// Result dialog shown after the unmatched-accounts lookup completes.
class _UnmatchedAccountsResultDialog extends StatelessWidget {
  final List<int> accountNumbers;

  const _UnmatchedAccountsResultDialog({required this.accountNumbers});

  @override
  Widget build(BuildContext context) {
    final hasUnmatched = accountNumbers.isNotEmpty;
    return AlertDialog(
      title: const Text('الحسابات الغير مسجلة'),
      content: Text(
        hasUnmatched
            ? 'تم الانتهاء، هناك ${accountNumbers.length} حساب غير مضاف لأي مشترك'
            : 'تم الانتهاء، جميع الحسابات مسجلة',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        if (hasUnmatched)
          FilledButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.download),
            label: const Text('تصدير Excel'),
          ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final service = UnmatchedAccountsExportService();
    final bytes = service.buildExcelBytes(accountNumbers);
    if (bytes == null) return;

    final defaultName =
        'unmatched_accounts_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final tempFile = File('${Directory.systemTemp.path}/$defaultName');
    await tempFile.writeAsBytes(bytes);

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ الحسابات الغير مسجلة',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savePath == null) return;
    await tempFile.copy(savePath);
  }
}

/// Static "About" section displayed at the bottom of the Settings screen.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const Column(
        children: [
          Text(
            'حول البرنامج',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'هذا البرنامج هو قاعدة بيانات لجميع تسديدات المشتركين',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          SizedBox(height: 4),
          Text(
            'تم تصميم هذا البرنامج من قبل قسم الاتصالات في فرع توزيع كهرباء مركز نينوى 2026',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// A single reset section with title, description, and a protected delete button.
class _ResetSection extends StatelessWidget {
  final String title;
  final String description;
  final Color warningColor;
  final VoidCallback onConfirmed;

  const _ResetSection({
    required this.title,
    required this.description,
    required this.warningColor,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: warningColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showConfirmDialog(context),
          icon: const Icon(Icons.delete_forever),
          label: Text(title),
          style: FilledButton.styleFrom(backgroundColor: warningColor),
        ),
      ],
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _ConfirmResetDialog(title: title, warningColor: warningColor),
    );
    if (confirmed == true) onConfirmed();
  }
}

/// Dialog that requires the user to type "reset" before the delete button activates.
class _ConfirmResetDialog extends StatefulWidget {
  final String title;
  final Color warningColor;

  const _ConfirmResetDialog({required this.title, required this.warningColor});

  @override
  State<_ConfirmResetDialog> createState() => _ConfirmResetDialogState();
}

class _ConfirmResetDialogState extends State<_ConfirmResetDialog> {
  final _ctrl = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _isValid = value.trim().toLowerCase() == 'reset');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'هذه العملية لا يمكن التراجع عنها.',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 12),
          const Text(
            'اكتب كلمة reset في الحقل أدناه للتأكيد:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'reset',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            onChanged: _onChanged,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: widget.warningColor),
          child: const Text('حذف'),
        ),
      ],
    );
  }
}
