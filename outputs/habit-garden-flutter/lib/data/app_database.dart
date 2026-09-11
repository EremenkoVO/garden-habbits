import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      path.join(root, 'habit_garden.db'),
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            reminder_enabled INTEGER NOT NULL DEFAULT 0,
            reminder_hour INTEGER NOT NULL DEFAULT 20,
            reminder_minute INTEGER NOT NULL DEFAULT 0,
            color_value INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE completions (
            habit_id INTEGER NOT NULL,
            completion_date TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            PRIMARY KEY (habit_id, completion_date),
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX completion_date_idx ON completions(completion_date)',
        );
        await _createReminderTimesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createReminderTimesTable(db);
          await db.execute('''
            INSERT INTO reminder_times (habit_id, minutes_of_day, position)
            SELECT id, reminder_hour * 60 + reminder_minute, 0
            FROM habits
            WHERE reminder_enabled = 1
          ''');
        }
      },
    );
    return _database!;
  }

  static Future<void> _createReminderTimesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE reminder_times (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        minutes_of_day INTEGER NOT NULL CHECK(minutes_of_day BETWEEN 0 AND 1439),
        position INTEGER NOT NULL,
        UNIQUE(habit_id, minutes_of_day),
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX reminder_habit_idx ON reminder_times(habit_id, position)',
    );
  }
}
