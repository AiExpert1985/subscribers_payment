import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';

/// Provider for the DatabaseService singleton.
///
/// This provider creates and maintains a single instance of DatabaseService
/// throughout the app lifecycle. The database is initialized lazily on first access.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for database initialization.
///
/// This FutureProvider ensures the database is initialized before use.
/// It can be used in widgets that need to wait for database readiness.
final databaseInitializationProvider = FutureProvider<void>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  await dbService.database; // Triggers initialization
});
