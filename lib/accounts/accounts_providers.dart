import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/database_service.dart';
import '../data/models/account.dart';
import '../data/models/subscriber_group.dart';
import '../data/providers.dart';

/// Current page for accounts pagination (0-based).
final currentAccountPageProvider = StateProvider<int>((ref) => 0);

/// Search query for filtering groups by subscriber name.
final accountNameSearchQueryProvider = StateProvider<String>((ref) => '');

/// Search query for filtering groups by account number.
final accountSearchQueryProvider = StateProvider<String>((ref) => '');

/// Combined data model: a subscriber group with its accounts.
class SubscriberGroupWithAccounts {
  final SubscriberGroup group;
  final List<Account> accounts;

  SubscriberGroupWithAccounts({required this.group, required this.accounts});
}

/// Total count of subscriber groups matching current filters.
final totalAccountGroupsProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final nameQuery = ref.watch(accountNameSearchQueryProvider).trim();
  final accountQuery = ref.watch(accountSearchQueryProvider).trim();
  return await db.getTotalSubscriberGroupCount(
    nameQuery: nameQuery,
    accountQuery: accountQuery,
  );
});

/// Total number of pages for accounts pagination.
final totalAccountPagesProvider = FutureProvider<int>((ref) async {
  final total = await ref.watch(totalAccountGroupsProvider.future);
  return (total / DatabaseService.defaultPageSize).ceil().clamp(1, 999999);
});

/// Fetches paginated subscriber groups with their accounts.
/// Filtered by subscriber name and/or account number when queries are non-empty.
final subscriberGroupsProvider =
    FutureProvider<List<SubscriberGroupWithAccounts>>((ref) async {
      final db = ref.watch(databaseServiceProvider);
      final page = ref.watch(currentAccountPageProvider);
      final nameQuery = ref.watch(accountNameSearchQueryProvider).trim();
      final accountQuery = ref.watch(accountSearchQueryProvider).trim();

      final groupRows = await db.getSubscriberGroupsPaginated(
        page: page,
        pageSize: DatabaseService.defaultPageSize,
        nameQuery: nameQuery,
        accountQuery: accountQuery,
      );

      final result = <SubscriberGroupWithAccounts>[];
      for (final row in groupRows) {
        final group = SubscriberGroup.fromMap(row);
        final accountRows = await db.getAccountsByGroupId(group.id!);
        final accounts = accountRows.map((a) => Account.fromMap(a)).toList();
        result.add(
          SubscriberGroupWithAccounts(group: group, accounts: accounts),
        );
      }

      return result;
    });
