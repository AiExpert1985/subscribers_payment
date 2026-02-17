import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/database_service.dart';
import '../data/models/payment.dart';
import '../data/providers.dart';
import '../import/import_service.dart';

/// Current page index for pagination (0-based).
final currentPageProvider = StateProvider<int>((ref) => 0);

/// Per-column search filters.
/// Keys: reference_account_number, subscriber_name, payment_date, amount, stamp_number
final paymentFiltersProvider = StateProvider<Map<String, String>>((ref) => {});

/// Paginated payments list — depends on current page and filters.
final paymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final page = ref.watch(currentPageProvider);
  final filters = ref.watch(paymentFiltersProvider);

  final rows = await db.getPaymentsPaginated(
    page: page,
    pageSize: DatabaseService.defaultPageSize,
    filters: filters,
  );

  return rows.map((row) => Payment.fromMap(row)).toList();
});

/// Total payment count for pagination (respects current filters).
final totalPaymentCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final filters = ref.watch(paymentFiltersProvider);
  return await db.getTotalPaymentCount(filters: filters);
});

/// Total number of pages based on count and page size.
final totalPagesProvider = FutureProvider<int>((ref) async {
  final total = await ref.watch(totalPaymentCountProvider.future);
  return (total / DatabaseService.defaultPageSize).ceil().clamp(1, 999999);
});

/// Last import result for displaying summary near import button.
final importResultProvider = StateProvider<ImportResult?>((ref) => null);

/// Last import timestamp for the footer.
final lastImportTimeProvider = StateProvider<DateTime?>((ref) => null);
