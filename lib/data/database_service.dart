import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Service for managing SQLite database operations.
///
/// Handles database initialization, schema creation, and version management.
/// The schema consists of 3 tables with specific constraints:
/// - subscriber_groups: Basic subscriber information
/// - accounts: Account numbers linked to subscriber groups (CASCADE delete)
/// - payments: Immutable payment records (no FK to accounts)
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'subscribers_payments_v2.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableSubscriberGroups = 'subscriber_groups';
  static const String tableAccounts = 'accounts';
  static const String tablePayments = 'payments';

  // Pagination defaults
  static const int defaultPageSize = 50;

  /// Gets the database instance, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Creates the database schema on first initialization
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSubscriberGroups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAccounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_number INTEGER NOT NULL UNIQUE,
        subscriber_group_id INTEGER NOT NULL,
        FOREIGN KEY (subscriber_group_id) 
          REFERENCES $tableSubscriberGroups(id) 
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference_account_number INTEGER NOT NULL,
        payment_date INTEGER NOT NULL,
        amount REAL NOT NULL,
        subscriber_name TEXT,
        type TEXT,
        stamp_number TEXT,
        address TEXT,
        UNIQUE (reference_account_number, payment_date, amount)
      )
    ''');
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ─── Subscriber Groups ───────────────────────────────────────────

  /// Inserts a new subscriber group
  Future<int> insertSubscriberGroup(Map<String, dynamic> group) async {
    final db = await database;
    return await db.insert(tableSubscriberGroups, group);
  }

  /// Gets all subscriber groups
  Future<List<Map<String, dynamic>>> getAllSubscriberGroups() async {
    final db = await database;
    return await db.query(tableSubscriberGroups);
  }

  /// Gets a subscriber group by ID
  Future<Map<String, dynamic>?> getSubscriberGroupById(int id) async {
    final db = await database;
    final results = await db.query(
      tableSubscriberGroups,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Updates a subscriber group
  Future<int> updateSubscriberGroup(int id, Map<String, dynamic> group) async {
    final db = await database;
    return await db.update(
      tableSubscriberGroups,
      group,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a subscriber group (CASCADE deletes related accounts)
  Future<int> deleteSubscriberGroup(int id) async {
    final db = await database;
    return await db.delete(
      tableSubscriberGroups,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Accounts ────────────────────────────────────────────────────

  /// Inserts a new account
  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await database;
    return await db.insert(tableAccounts, account);
  }

  /// Gets all accounts
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await database;
    return await db.query(tableAccounts);
  }

  /// Gets an account by ID
  Future<Map<String, dynamic>?> getAccountById(int id) async {
    final db = await database;
    final results = await db.query(
      tableAccounts,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Gets accounts by subscriber group ID
  Future<List<Map<String, dynamic>>> getAccountsByGroupId(
    int subscriberGroupId,
  ) async {
    final db = await database;
    return await db.query(
      tableAccounts,
      where: 'subscriber_group_id = ?',
      whereArgs: [subscriberGroupId],
    );
  }

  /// Finds an account by account number
  Future<Map<String, dynamic>?> getAccountByNumber(int accountNumber) async {
    final db = await database;
    final results = await db.query(
      tableAccounts,
      where: 'account_number = ?',
      whereArgs: [accountNumber],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Updates an account
  Future<int> updateAccount(int id, Map<String, dynamic> account) async {
    final db = await database;
    return await db.update(
      tableAccounts,
      account,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes an account
  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(tableAccounts, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Payments ────────────────────────────────────────────────────

  /// Inserts a new payment
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert(tablePayments, payment);
  }

  /// Inserts payments in batch, skipping duplicates via INSERT OR IGNORE.
  /// Returns the number of successfully inserted rows.
  Future<int> insertPaymentBatch(List<Map<String, dynamic>> payments) async {
    final db = await database;
    int inserted = 0;

    await db.transaction((txn) async {
      for (final payment in payments) {
        final result = await txn.insert(
          tablePayments,
          payment,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (result != 0) inserted++;
      }
    });

    return inserted;
  }

  /// Gets paginated payments with optional per-column filters.
  ///
  /// [filters] keys match column names: reference_account_number,
  /// subscriber_name, payment_date, amount, stamp_number.
  /// Non-empty filter values are applied as LIKE '%value%' (AND logic).
  Future<List<Map<String, dynamic>>> getPaymentsPaginated({
    int page = 0,
    int pageSize = defaultPageSize,
    Map<String, String> filters = const {},
  }) async {
    final db = await database;
    final whereClause = _buildWhereClause(filters);

    return await db.query(
      tablePayments,
      where: whereClause.clause,
      whereArgs: whereClause.args,
      orderBy: 'id DESC',
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  /// Gets total payment count with optional filters (for pagination).
  Future<int> getTotalPaymentCount({
    Map<String, String> filters = const {},
  }) async {
    final db = await database;
    final whereClause = _buildWhereClause(filters);

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tablePayments'
      '${whereClause.clause != null ? " WHERE ${whereClause.clause}" : ""}',
      whereClause.args,
    );

    return result.first['count'] as int;
  }

  /// Gets all payments matching the given filters, with no pagination limit.
  ///
  /// Uses the same filter logic as [getPaymentsPaginated]. Intended for export.
  Future<List<Map<String, dynamic>>> getPaymentsFiltered({
    Map<String, String> filters = const {},
  }) async {
    final db = await database;
    final whereClause = _buildWhereClause(filters);

    return await db.query(
      tablePayments,
      where: whereClause.clause,
      whereArgs: whereClause.args,
      orderBy: 'id DESC',
    );
  }

  /// Gets a payment by ID
  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    final db = await database;
    final results = await db.query(
      tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Gets payments by reference account number
  Future<List<Map<String, dynamic>>> getPaymentsByAccountNumber(
    int accountNumber,
  ) async {
    final db = await database;
    return await db.query(
      tablePayments,
      where: 'reference_account_number = ?',
      whereArgs: [accountNumber],
    );
  }

  /// Gets payments for a set of account numbers with optional date bounds.
  ///
  /// [fromDate] and [toDate] are Unix timestamps in milliseconds, inclusive.
  Future<List<Map<String, dynamic>>> getPaymentsByAccountNumbers({
    required List<int> accountNumbers,
    int? fromDate,
    int? toDate,
  }) async {
    if (accountNumbers.isEmpty) return [];

    final db = await database;
    final conditions = <String>[];
    final args = <Object?>[];

    final accountPlaceholders = List.filled(
      accountNumbers.length,
      '?',
    ).join(',');
    conditions.add('reference_account_number IN ($accountPlaceholders)');
    args.addAll(accountNumbers);

    if (fromDate != null) {
      conditions.add('payment_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      conditions.add('payment_date <= ?');
      args.add(toDate);
    }

    final whereClause = conditions.join(' AND ');
    return await db.query(
      tablePayments,
      where: whereClause,
      whereArgs: args,
      orderBy: 'payment_date ASC, id ASC',
    );
  }

  /// Updates a payment
  Future<int> updatePayment(int id, Map<String, dynamic> payment) async {
    final db = await database;
    return await db.update(
      tablePayments,
      payment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a payment
  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete(tablePayments, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Import Helpers ──────────────────────────────────────────────

  /// Finds or creates an account and its subscriber group for import.
  ///
  /// If the account number already exists, returns the existing account ID.
  /// Otherwise, creates a new subscriber group (using subscriberName if
  /// provided) and a new account linked to it.
  Future<int> findOrCreateAccountAndGroup(
    int accountNumber, {
    String? subscriberName,
  }) async {
    final existing = await getAccountByNumber(accountNumber);
    if (existing != null) return existing['id'] as int;

    final db = await database;
    final groupId = await db.insert(tableSubscriberGroups, {
      'name': subscriberName ?? '',
    });

    return await db.insert(tableAccounts, {
      'account_number': accountNumber,
      'subscriber_group_id': groupId,
    });
  }

  /// Searches for subscriber group IDs that contain an account
  /// whose number matches the query (LIKE '%query%').
  Future<List<int>> searchGroupsByAccountNumber(String query) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT sg.id
      FROM $tableSubscriberGroups sg
      INNER JOIN $tableAccounts a ON a.subscriber_group_id = sg.id
      WHERE CAST(a.account_number AS TEXT) LIKE ?
    ''',
      ['%$query%'],
    );
    return results.map((r) => r['id'] as int).toList();
  }

  // ─── Private Helpers ─────────────────────────────────────────────

  /// Builds a WHERE clause from column filters.
  ///
  /// Special keys:
  /// - `payment_date_from` → `payment_date >= value` (timestamp string)
  /// - `payment_date_to`   → `payment_date <= value` (timestamp string)
  /// All other keys use CAST(column AS TEXT) LIKE '%value%'.
  _WhereClause _buildWhereClause(Map<String, String> filters) {
    final conditions = <String>[];
    final args = <String>[];

    for (final entry in filters.entries) {
      if (entry.value.trim().isEmpty) continue;

      if (entry.key == 'payment_date_from') {
        conditions.add('payment_date >= ?');
        args.add(entry.value);
      } else if (entry.key == 'payment_date_to') {
        conditions.add('payment_date <= ?');
        args.add(entry.value);
      } else {
        conditions.add('CAST(${entry.key} AS TEXT) LIKE ?');
        args.add('%${entry.value.trim()}%');
      }
    }

    if (conditions.isEmpty) return _WhereClause(null, []);
    return _WhereClause(conditions.join(' AND '), args);
  }
}

/// Helper class for WHERE clause construction.
class _WhereClause {
  final String? clause;
  final List<String> args;

  _WhereClause(this.clause, this.args);
}
