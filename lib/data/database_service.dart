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
  static const String _databaseName = 'subscribers_payments.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableSubscriberGroups = 'subscriber_groups';
  static const String tableAccounts = 'accounts';
  static const String tablePayments = 'payments';

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
      onUpgrade: _onUpgrade,
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
        type TEXT,
        collector_stamp TEXT,
        UNIQUE (reference_account_number, payment_date, amount)
      )
    ''');
  }

  /// Handles database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic will be added here in future versions
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // CRUD methods for subscriber_groups

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

  // CRUD methods for accounts

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

  // CRUD methods for payments

  /// Inserts a new payment
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert(tablePayments, payment);
  }

  /// Gets all payments
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await database;
    return await db.query(tablePayments);
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
}
