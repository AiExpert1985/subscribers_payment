import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../import/alias_defaults.dart';
import '../data/providers.dart';
import 'alias_providers.dart';

/// Arabic display labels for each field in the payment import section.
const _paymentFieldLabels = {
  'account_number': 'رقم الحساب',
  'amount': 'المبلغ',
  'date': 'التاريخ',
  'subscriber_name': 'اسم المشترك',
  'stamp_number': 'رقم الختم',
  'type': 'النوع',
  'address': 'العنوان',
};

/// Arabic display labels for each field in the account import section.
const _accountFieldLabels = {
  'account': 'عمود الحساب',
  'subscriber_name': 'اسم المشترك',
};

/// Card for the payment import aliases section.
class PaymentAliasSectionCard extends StatelessWidget {
  final bool collapsible;

  const PaymentAliasSectionCard({super.key, this.collapsible = true});

  @override
  Widget build(BuildContext context) => AliasSectionCard(
    title: 'أعمدة استيراد المدفوعات',
    section: 'payment',
    fieldLabels: _paymentFieldLabels,
    requiredFields: kPaymentRequiredFields,
    provider: paymentAliasesProvider,
    collapsible: collapsible,
  );
}

/// Card for the account import aliases section.
class AccountAliasSectionCard extends StatelessWidget {
  final bool collapsible;

  const AccountAliasSectionCard({super.key, this.collapsible = true});

  @override
  Widget build(BuildContext context) => AliasSectionCard(
    title: 'أعمدة استيراد الحسابات',
    section: 'account',
    fieldLabels: _accountFieldLabels,
    requiredFields: kAccountRequiredFields,
    provider: accountAliasesProvider,
    collapsible: collapsible,
  );
}

/// Collapsible card for managing import column aliases for a single section.
/// Set [collapsible] to false to render content directly (for use inside dialogs).
class AliasSectionCard extends ConsumerWidget {
  final String title;
  final String section;
  final Map<String, String> fieldLabels;
  final Set<String> requiredFields;
  final FutureProvider<Map<String, List<String>>> provider;
  final bool collapsible;

  const AliasSectionCard({
    super.key,
    required this.title,
    required this.section,
    required this.fieldLabels,
    required this.requiredFields,
    required this.provider,
    this.collapsible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliasesAsync = ref.watch(provider);

    final resetButton = TextButton.icon(
      onPressed: () => _resetSection(context, ref),
      icon: const Icon(Icons.restart_alt, size: 16),
      label: const Text('إعادة تعيين'),
      style: TextButton.styleFrom(foregroundColor: Colors.orange),
    );

    final content = aliasesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('خطأ: $e'),
      ),
      data: (aliases) => Column(
        children: fieldLabels.entries.map((entry) {
          final field = entry.key;
          final label = entry.value;
          final fieldAliases = aliases[field] ?? [];
          final isRequired = requiredFields.contains(field);
          return _FieldAliasRow(
            label: label,
            aliases: fieldAliases,
            isRequired: isRequired,
            onAdd: (alias) => _addAlias(ref, field, alias),
            onDelete: (alias) => _deleteAlias(ref, field, alias),
          );
        }).toList(),
      ),
    );

    if (!collapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              resetButton,
            ],
          ),
          const Divider(height: 16),
          content,
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            resetButton,
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: content,
          ),
        ],
      ),
    );
  }

  Future<void> _addAlias(WidgetRef ref, String field, String alias) async {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) return;
    await ref.read(databaseServiceProvider).addAlias(section, field, trimmed);
    ref.invalidate(provider);
  }

  Future<void> _deleteAlias(WidgetRef ref, String field, String alias) async {
    await ref.read(databaseServiceProvider).deleteAlias(section, field, alias);
    ref.invalidate(provider);
  }

  Future<void> _resetSection(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إعادة تعيين $title'),
        content: const Text('سيتم حذف جميع الأسماء المخصصة واستعادة الافتراضية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseServiceProvider).resetSectionAliases(section);
    ref.invalidate(provider);
  }
}

/// A single field row: label + alias chips + add-alias input.
class _FieldAliasRow extends StatefulWidget {
  final String label;
  final List<String> aliases;
  final bool isRequired;
  final Future<void> Function(String alias) onAdd;
  final Future<void> Function(String alias) onDelete;

  const _FieldAliasRow({
    required this.label,
    required this.aliases,
    required this.isRequired,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_FieldAliasRow> createState() => _FieldAliasRowState();
}

class _FieldAliasRowState extends State<_FieldAliasRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Aliases + add input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.aliases.map((alias) {
                    final canDelete = !widget.isRequired || widget.aliases.length > 1;
                    return Chip(
                      label: Text(alias, style: const TextStyle(fontSize: 12)),
                      deleteIcon: canDelete
                          ? const Icon(Icons.close, size: 14)
                          : null,
                      onDeleted: canDelete
                          ? () => widget.onDelete(alias)
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(fontSize: 13),
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'اسم عمود جديد...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _submit,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _submit(_ctrl.text),
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'إضافة',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onAdd(trimmed);
    _ctrl.clear();
  }
}
