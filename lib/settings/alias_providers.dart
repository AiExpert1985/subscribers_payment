import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

/// All aliases for the payment import section, grouped by field name.
final paymentAliasesProvider = FutureProvider<Map<String, List<String>>>((ref) {
  return ref.watch(databaseServiceProvider).getAliasesForSection('payment');
});

/// All aliases for the account import section, grouped by field name.
final accountAliasesProvider = FutureProvider<Map<String, List<String>>>((ref) {
  return ref.watch(databaseServiceProvider).getAliasesForSection('account');
});
