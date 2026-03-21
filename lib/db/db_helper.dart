import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/character.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'budget.db');
    return await openDatabase(
      path,
      version: 2, // Bump version to 2 for character table
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            title TEXT,
            amount INTEGER,
            category TEXT,
            memo TEXT,
            type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE character (
            id INTEGER PRIMARY KEY DEFAULT 0,
            level INTEGER,
            xp INTEGER,
            maxXP INTEGER,
            status TEXT
          )
        ''');
        await db.insert('character', {'id': 0, 'level': 1, 'xp': 0, 'maxXP': 100, 'status': 'happy'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE character (
              id INTEGER PRIMARY KEY DEFAULT 0,
              level INTEGER,
              xp INTEGER,
              maxXP INTEGER,
              status TEXT
            )
          ''');
          await db.insert('character', {'id': 0, 'level': 1, 'xp': 0, 'maxXP': 100, 'status': 'happy'});
        }
      },
    );
  }

  Future<int> insert(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<Map<String, int>> getTotals() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT type, SUM(amount) as total FROM expenses GROUP BY type'
    );
    
    int income = 0;
    int expense = 0;
    
    for (var row in result) {
      if (row['type'] == 'income') {
        income = row['total'] as int;
      } else if (row['type'] == 'expense') {
        expense = row['total'] as int;
      }
    }
    
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.update('character', {'level': 1, 'xp': 0, 'maxXP': 100, 'status': 'happy'}, where: 'id = 0');
  }

  // --- Character Methods ---
  Future<Character> getCharacter() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('character', where: 'id = 0');
    if (maps.isEmpty) {
      await db.insert('character', {'id': 0, 'level': 1, 'xp': 0, 'maxXP': 100, 'status': 'happy'});
      return Character(level: 1, xp: 0, maxXP: 100, status: 'happy');
    }
    return Character.fromMap(maps[0]);
  }

  Future<int> updateCharacter(Character char) async {
    final db = await database;
    return await db.update('character', char.toMap(), where: 'id = 0');
  }
}
