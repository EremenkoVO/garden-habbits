import 'package:flutter_test/flutter_test.dart';
import 'package:habit_garden/domain/completion.dart';
import 'package:habit_garden/domain/habit_stats.dart';

Completion completion(int day) => Completion(
  habitId: 1,
  date: DateTime(2026, 8, day),
  completedAt: DateTime(2026, 8, day, 12),
);

void main() {
  test('calculates current and best streaks', () {
    final stats = HabitStats.fromCompletions([
      completion(1),
      completion(2),
      completion(5),
      completion(6),
    ], today: DateTime(2026, 8, 7));

    expect(stats.totalCompletions, 4);
    expect(stats.currentStreak, 2);
    expect(stats.bestStreak, 2);
  });

  test('today extends current streak', () {
    final stats = HabitStats.fromCompletions([
      completion(6),
      completion(7),
    ], today: DateTime(2026, 8, 7));

    expect(stats.currentStreak, 2);
  });

  test('duplicate dates do not inflate statistics', () {
    final stats = HabitStats.fromCompletions([
      completion(7),
      completion(7),
    ], today: DateTime(2026, 8, 7));

    expect(stats.totalCompletions, 1);
    expect(stats.bestStreak, 1);
  });
}
