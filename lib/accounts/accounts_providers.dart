import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/database_service.dart';
import '../data/models/account.dart';
import '../data/models/subscriber_group.dart';
import '../data/providers.dart';

/// Search query for filtering groups by account number.
final accountSearchQueryProvider = StateProvider<String>((ref) => '');

/// Combined data model: a subscriber group with its accounts.
class SubscriberGroupWithAccounts {
  final SubscriberGroup group;
  final List<Account> accounts;

  SubscriberGroupWithAccounts({required this.group, required this.accounts});
}

/// Fetches all subscriber groups with their accounts.
/// When search query is non-empty, filters to groups containing matching accounts.
final subscriberGroupsProvider =
    FutureProvider<List<SubscriberGroupWithAccounts>>((ref) async {
      final db = ref.watch(databaseServiceProvider);
      final query = ref.watch(accountSearchQueryProvider).trim();

      List<Map<String, dynamic>> groupRows;

      if (query.isNotEmpty) {
        // Search: get only groups containing matching account numbers
        final matchingIds = await db.searchGroupsByAccountNumber(query);
        if (matchingIds.isEmpty) return [];

        final dbInstance = await db.database;
        groupRows = await dbInstance.query(
          DatabaseService.tableSubscriberGroups,
          where: 'id IN (${matchingIds.join(',')})',
        );
      } else {
        groupRows = await db.getAllSubscriberGroups();
      }

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
