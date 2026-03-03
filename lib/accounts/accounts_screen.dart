import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_service.dart';
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
  final _nameSearchCtrl = TextEditingController();
  final _accountSearchCtrl = TextEditingController();
  Timer? _nameDebounce;
  Timer? _accountDebounce;

  // Inline editing state
  String? _editingKey; // "group-{id}" or "account-{id}"
  final _editCtrl = TextEditingController();

  // New account being added to a group (groupId -> true)
  int? _addingAccountToGroup;
  final _newAccountCtrl = TextEditingController();

  // Hovered row id for highlight
  int? _hoveredGroupId;

  // Fixed column widths (match payments screen)
  static const double _kRowNumWidth = 40.0;
  static const double _kNameWidth = 160.0;
  static const double _kAccountChipWidth = 130.0;

  @override
  void dispose() {
    _nameSearchCtrl.dispose();
    _accountSearchCtrl.dispose();
    _nameDebounce?.cancel();
    _accountDebounce?.cancel();
    _editCtrl.dispose();
    _newAccountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(subscriberGroupsProvider);
    final totalPagesAsync = ref.watch(totalAccountPagesProvider);
    final totalCountAsync = ref.watch(totalAccountGroupsProvider);
    final currentPage = ref.watch(currentAccountPageProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionBar(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(
              child: groupsAsync.when(
                data: (groups) => _buildGroupsList(groups, currentPage),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('خطأ: $error')),
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(currentPage, totalPagesAsync, totalCountAsync),
          ],
        ),
      ),
    );
  }

  // ─── Action Bar ──────────────────────────────────────────────────

  Widget _buildActionBar() {
    return Center(
      child: FilledButton.icon(
        onPressed: _addGroup,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مشترك'),
      ),
    );
  }

  bool get _hasAccountFilters =>
      _nameSearchCtrl.text.isNotEmpty || _accountSearchCtrl.text.isNotEmpty;

  // ─── Search Bar ──────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Row(
      children: [
        // X reset: far right (first child = rightmost in RTL), only when active
        SizedBox(
          width: 32,
          child: _hasAccountFilters
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  onPressed: _resetFilters,
                  tooltip: 'مسح التصفية',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _nameSearchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث باسم المشترك...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: _onNameSearchChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _accountSearchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث برقم الحساب...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: _onAccountSearchChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Groups List ─────────────────────────────────────────────────

  Widget _buildGroupsList(
    List<SubscriberGroupWithAccounts> groups,
    int currentPage,
  ) {
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
      separatorBuilder: (_, _) =>
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final rowNumber =
            currentPage * DatabaseService.defaultPageSize + index + 1;
        return _buildGroupRow(groups[index], rowNumber);
      },
    );
  }

  // ─── Single Group Row ────────────────────────────────────────────

  Widget _buildGroupRow(SubscriberGroupWithAccounts data, int rowNumber) {
    final group = data.group;
    final accounts = data.accounts;
    final isHovered = _hoveredGroupId == group.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredGroupId = group.id),
      onExit: (_) => setState(() => _hoveredGroupId = null),
      child: Container(
        decoration: BoxDecoration(
          color: isHovered ? Colors.grey.shade100 : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Row number (first = rightmost in RTL)
              SizedBox(
                width: _kRowNumWidth,
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
              const SizedBox(width: 8),

              // Subscriber name (editable)
              SizedBox(width: _kNameWidth, child: _buildEditableName(group)),
              const SizedBox(width: 12),

              // Account chips + add button
              Expanded(child: _buildAccountsRow(group, accounts)),
              const SizedBox(width: 8),

              // Delete button (last = leftmost in RTL)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _confirmDeleteGroup(group),
                tooltip: 'حذف المشترك',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
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
        style: const TextStyle(fontSize: 13),
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
        child: Text(
          group.name.isEmpty ? '(بدون اسم)' : group.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: group.name.isEmpty ? Colors.grey : null,
            fontStyle:
                group.name.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          overflow: TextOverflow.ellipsis,
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
        for (final account in accounts) _buildAccountChip(account),
        if (_addingAccountToGroup == group.id) _buildNewAccountInput(group),
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
        width: _kAccountChipWidth,
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

    return SizedBox(
      width: _kAccountChipWidth,
      child: Chip(
        label: SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: () =>
                _startEdit(editKey, account.accountNumber.toString()),
            child: Text(
              account.accountNumber.toString(),
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => _confirmDeleteAccount(account),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildNewAccountInput(SubscriberGroup group) {
    return SizedBox(
      width: _kAccountChipWidth,
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
          if (_newAccountCtrl.text.trim().isEmpty) {
            setState(() => _addingAccountToGroup = null);
          } else {
            _saveNewAccount(group);
          }
        },
      ),
    );
  }

  // ─── Pagination ──────────────────────────────────────────────────

  Widget _buildPagination(
    int currentPage,
    AsyncValue<int> totalPagesAsync,
    AsyncValue<int> totalCountAsync,
  ) {
    return totalPagesAsync.when(
      data: (totalPages) => totalCountAsync.when(
        data: (totalCount) {
          final pageSize = DatabaseService.defaultPageSize;
          final startRow =
              totalCount == 0 ? 0 : currentPage * pageSize + 1;
          final endRow =
              ((currentPage + 1) * pageSize).clamp(0, totalCount);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 0
                    ? () => ref
                          .read(currentAccountPageProvider.notifier)
                          .state = 0
                    : null,
                tooltip: 'الصفحة الأولى',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () =>
                        ref.read(currentAccountPageProvider.notifier).state--
                    : null,
                tooltip: 'السابق',
              ),
              const SizedBox(width: 8),
              Text(
                'من $startRow إلى $endRow',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () =>
                        ref.read(currentAccountPageProvider.notifier).state++
                    : null,
                tooltip: 'التالي',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages - 1
                    ? () => ref
                          .read(currentAccountPageProvider.notifier)
                          .state = totalPages - 1
                    : null,
                tooltip: 'الصفحة الأخيرة',
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ─── Search Callbacks ────────────────────────────────────────────

  void _onNameSearchChanged(String value) {
    setState(() {});
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(accountNameSearchQueryProvider.notifier).state = value.trim();
      ref.read(currentAccountPageProvider.notifier).state = 0;
    });
  }

  void _onAccountSearchChanged(String value) {
    setState(() {});
    _accountDebounce?.cancel();
    _accountDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(accountSearchQueryProvider.notifier).state = value.trim();
      ref.read(currentAccountPageProvider.notifier).state = 0;
    });
  }

  void _resetFilters() {
    _nameSearchCtrl.clear();
    _accountSearchCtrl.clear();
    setState(() {});
    ref.read(accountNameSearchQueryProvider.notifier).state = '';
    ref.read(accountSearchQueryProvider.notifier).state = '';
    ref.read(currentAccountPageProvider.notifier).state = 0;
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
    ref.invalidate(totalAccountGroupsProvider);
  }

  Future<void> _saveAccountNumber(Account account) async {
    final newNumber = int.tryParse(_editCtrl.text.trim());
    setState(() => _editingKey = null);

    if (newNumber == null || account.id == null) return;
    if (newNumber == account.accountNumber) return;

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
    ref.invalidate(totalAccountGroupsProvider);
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
          'هل تريد حذف المشترك "${group.name.isEmpty ? 'بدون اسم' : group.name}"'
          ' وجميع الحسابات المرتبطة به؟',
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
    ref.invalidate(totalAccountGroupsProvider);
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
