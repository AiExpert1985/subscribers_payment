import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../accounts/accounts_providers.dart';
import '../payments/payments_providers.dart';

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
              title: 'إعادة ضبط المشتركين',
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
              title: 'إعادة ضبط التسديدات',
              description:
                  'يحذف جميع سجلات التسديدات.\n'
                  'لا يؤثر على بيانات المشتركين والحسابات.',
              warningColor: Colors.red,
              onConfirmed: () => _resetPayments(context, ref),
            ),
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
