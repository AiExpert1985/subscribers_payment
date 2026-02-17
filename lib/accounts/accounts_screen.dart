import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/account.dart';
import '../data/models/subscriber_group.dart';
import '../data/providers.dart';
import 'accounts_providers.dart';

/// Accounts screen: manage subscriber groups and their account numbers.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Inline editing state
  String? _editingKey; // "group-{id}" or "account-{id}"
  final _editCtrl = TextEditingController();

  // New account being added to a group (groupId -> true)
  int? _addingAccountToGroup;
  final _newAccountCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _editCtrl.dispose();
    _newAccountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(subscriberGroupsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionBar(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: groupsAsync.when(
                data: (groups) => _buildGroupsList(groups),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('خطأ: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action Bar ──────────────────────────────────────────────────

  Widget _buildActionBar() {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: _addGroup,
          icon: const Icon(Icons.group_add),
          label: const Text('إضافة مجموعة'),
        ),
      ],
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'بحث برقم الحساب...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(accountSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: _onSearchChanged,
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {}); // Rebuild to show/hide clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(accountSearchQueryProvider.notifier).state = value.trim();
    });
  }

  // ─── Groups List ─────────────────────────────────────────────────

  Widget _buildGroupsList(List<SubscriberGroupWithAccounts> groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مجموعات مشتركين',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildGroupRow(groups[index]),
    );
  }

  // ─── Single Group Row ────────────────────────────────────────────

  Widget _buildGroupRow(SubscriberGroupWithAccounts data) {
    final group = data.group;
    final accounts = data.accounts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delete group button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDeleteGroup(group),
            tooltip: 'حذف المجموعة',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),

          // Subscriber name (editable)
          SizedBox(width: 180, child: _buildEditableName(group)),
          const SizedBox(width: 12),

          // Account numbers + add button
          Expanded(child: _buildAccountsRow(group, accounts)),
        ],
      ),
    );
  }

  // ─── Editable Subscriber Name ────────────────────────────────────

  Widget _buildEditableName(SubscriberGroup group) {
    final editKey = 'group-${group.id}';
    final isEditing = _editingKey == editKey;

    if (isEditing) {
      return TextField(
        controller: _editCtrl,
        autofocus: true,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _saveGroupName(group),
        onTapOutside: (_) => _saveGroupName(group),
      );
    }

    return InkWell(
      onTap: () => _startEdit(editKey, group.name),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                group.name.isEmpty ? '(بدون اسم)' : group.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: group.name.isEmpty ? Colors.grey : null,
                  fontStyle: group.name.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.edit, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ─── Accounts Row ────────────────────────────────────────────────

  Widget _buildAccountsRow(SubscriberGroup group, List<Account> accounts) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Existing accounts
        for (final account in accounts) _buildAccountChip(account),

        // New account input (if adding)
        if (_addingAccountToGroup == group.id) _buildNewAccountInput(group),

        // Add account button (always last)
        if (_addingAccountToGroup != group.id)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 22,
              color: Colors.teal,
            ),
            onPressed: () => _startAddAccount(group.id!),
            tooltip: 'إضافة حساب',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
      ],
    );
  }

  Widget _buildAccountChip(Account account) {
    final editKey = 'account-${account.id}';
    final isEditing = _editingKey == editKey;

    if (isEditing) {
      return SizedBox(
        width: 120,
        child: TextField(
          controller: _editCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveAccountNumber(account),
          onTapOutside: (_) => _saveAccountNumber(account),
        ),
      );
    }

    return Chip(
      label: InkWell(
        onTap: () => _startEdit(editKey, account.accountNumber.toString()),
        child: Text(
          account.accountNumber.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _confirmDeleteAccount(account),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildNewAccountInput(SubscriberGroup group) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: _newAccountCtrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'رقم الحساب',
          hintStyle: const TextStyle(fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check, size: 16, color: Colors.teal),
            onPressed: () => _saveNewAccount(group),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ),
        onSubmitted: (_) => _saveNewAccount(group),
        onTapOutside: (_) {
          // Cancel if empty
          if (_newAccountCtrl.text.trim().isEmpty) {
            setState(() => _addingAccountToGroup = null);
          } else {
            _saveNewAccount(group);
          }
        },
      ),
    );
  }

  // ─── Editing Helpers ─────────────────────────────────────────────

  void _startEdit(String key, String currentValue) {
    setState(() {
      _editingKey = key;
      _editCtrl.text = currentValue;
    });
  }

  Future<void> _saveGroupName(SubscriberGroup group) async {
    final newName = _editCtrl.text.trim();
    setState(() => _editingKey = null);

    if (group.id == null) return;

    final db = ref.read(databaseServiceProvider);
    await db.updateSubscriberGroup(group.id!, {'name': newName});
    ref.invalidate(subscriberGroupsProvider);
  }

  Future<void> _saveAccountNumber(Account account) async {
    final newNumber = int.tryParse(_editCtrl.text.trim());
    setState(() => _editingKey = null);

    if (newNumber == null || account.id == null) return;
    if (newNumber == account.accountNumber) return; // No change

    final db = ref.read(databaseServiceProvider);
    try {
      await db.updateAccount(account.id!, {'account_number': newNumber});
      ref.invalidate(subscriberGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رقم الحساب $newNumber موجود مسبقاً'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Add / Delete Actions ────────────────────────────────────────

  Future<void> _addGroup() async {
    final db = ref.read(databaseServiceProvider);
    await db.insertSubscriberGroup({'name': ''});
    ref.invalidate(subscriberGroupsProvider);
  }

  void _startAddAccount(int groupId) {
    setState(() {
      _addingAccountToGroup = groupId;
      _newAccountCtrl.clear();
    });
  }

  Future<void> _saveNewAccount(SubscriberGroup group) async {
    final number = int.tryParse(_newAccountCtrl.text.trim());
    setState(() => _addingAccountToGroup = null);

    if (number == null || group.id == null) return;

    final db = ref.read(databaseServiceProvider);
    try {
      await db.insertAccount({
        'account_number': number,
        'subscriber_group_id': group.id,
      });
      ref.invalidate(subscriberGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رقم الحساب $number موجود مسبقاً'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteGroup(SubscriberGroup group) async {
    if (group.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف المجموعة "${group.name.isEmpty ? 'بدون اسم' : group.name}"'
          ' وجميع الحسابات المرتبطة بها؟',
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
    await db.deleteSubscriberGroup(group.id!);
    ref.invalidate(subscriberGroupsProvider);
  }

  Future<void> _confirmDeleteAccount(Account account) async {
    if (account.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الحساب رقم ${account.accountNumber}؟'),
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
    await db.deleteAccount(account.id!);
    ref.invalidate(subscriberGroupsProvider);
  }
}
