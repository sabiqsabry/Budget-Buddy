import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'budget_buddy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE groups(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members(
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (group_id, user_id),
        FOREIGN KEY (group_id) REFERENCES groups (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        paid_by TEXT NOT NULL,
        split_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id),
        FOREIGN KEY (paid_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_splits(
        expense_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (expense_id, user_id),
        FOREIGN KEY (expense_id) REFERENCES expenses (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<void> insertGroup(Group group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Group>> getGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('groups');
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  Future<void> addUserToGroup(String userId, String groupId) async {
    final db = await database;
    await db.insert(
      'group_members',
      {
        'group_id': groupId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getGroupMembers(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN group_members gm ON u.id = gm.user_id
      WHERE gm.group_id = ?
    ''', [groupId]);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert the expense
      await txn.insert(
        'expenses',
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert the splits
      if (expense.splitType == 'equal') {
        final splitAmount = expense.amount / expense.splitBetween.length;
        for (final userId in expense.splitBetween) {
          await txn.insert(
            'expense_splits',
            {
              'expense_id': expense.id,
              'user_id': userId,
              'amount': splitAmount,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        }
      } else if (expense.customSplits != null) {
        for (final entry in expense.customSplits!.entries) {
          await txn.insert(
            'expense_splits',
            {
              'expense_id': expense.id,
              'user_id': entry.key,
              'amount': entry.value,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    });
  }

  Future<List<Expense>> getGroupExpenses(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<Map<String, double>> getUserBalances(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> paidMaps = await db.rawQuery('''
      SELECT SUM(amount) as total_paid
      FROM expenses
      WHERE paid_by = ?
    ''', [userId]);

    final List<Map<String, dynamic>> owedMaps = await db.rawQuery('''
      SELECT SUM(amount) as total_owed
      FROM expense_splits
      WHERE user_id = ?
    ''', [userId]);

    final totalPaid = paidMaps.first['total_paid'] as double? ?? 0.0;
    final totalOwed = owedMaps.first['total_owed'] as double? ?? 0.0;

    return {
      'total_paid': totalPaid,
      'total_owed': totalOwed,
      'balance': totalPaid - totalOwed,
    };
  }

  Future<List<ExpenseSplit>> getExpenseSplitsForExpense(
      String expenseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return List.generate(maps.length, (i) => ExpenseSplit.fromMap(maps[i]));
  }
}
