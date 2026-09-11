import 'package:sqflite/sqflite.dart';

import '../core/date_utils.dart';
import '../domain/completion.dart';
import '../domain/habit.dart';
import 'app_database.dart';

class HabitRepository {
  HabitRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Habit>> getHabits() async {
    final db = await _database.database;
    final rows = await db.query('habits', orderBy: 'created_at DESC');
    final reminderRows = await db.query(
      'reminder_times',
      orderBy: 'habit_id ASC, position ASC',
    );
    final remindersByHabit = <int, List<int>>{};
    for (final row in reminderRows) {
      remindersByHabit
          .putIfAbsent(row['habit_id']! as int, () => [])
          .add(row['minutes_of_day']! as int);
    }
    return rows
        .map(
          (row) => Habit.fromMap(
            row,
            reminderTimes: remindersByHabit[row['id']! as int],
          ),
        )
        .toList();
  }

  Future<List<Completion>> getCompletions() async {
    final db = await _database.database;
    final rows = await db.query('completions', orderBy: 'completion_date ASC');
    return rows.map(Completion.fromMap).toList();
  }

  Future<Habit> saveHabit(Habit habit) async {
    final db = await _database.database;
    final values = habit.toMap()..remove('id');
    return db.transaction((transaction) async {
      final int id;
      if (habit.id == null) {
        id = await transaction.insert('habits', values);
      } else {
        id = habit.id!;
        await transaction.update(
          'habits',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await transaction.delete(
        'reminder_times',
        where: 'habit_id = ?',
        whereArgs: [id],
      );
      final batch = transaction.batch();
      for (var index = 0; index < habit.reminderTimes.length; index++) {
        batch.insert('reminder_times', {
          'habit_id': id,
          'minutes_of_day': habit.reminderTimes[index],
          'position': index,
        });
      }
      await batch.commit(noResult: true);
      return habit.copyWith(id: id);
    });
  }

  Future<void> deleteHabit(int id) async {
    final db = await _database.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setCompleted(int habitId, DateTime date, bool completed) async {
    final db = await _database.database;
    if (completed) {
      await db.insert(
        'completions',
        Completion(habitId: habitId, date: date, completedAt: DateTime.now())
            .toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'completions',
        where: 'habit_id = ? AND completion_date = ?',
        whereArgs: [habitId, dateKey(date)],
      );
    }
  }
}
