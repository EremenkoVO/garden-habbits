import 'package:flutter_test/flutter_test.dart';
import 'package:habit_garden/core/habit_icons.dart';
import 'package:habit_garden/domain/habit.dart';

Habit habit({DateTime? end}) => Habit(
  id: 1,
  name: 'Тест',
  startDate: DateTime(2026, 8, 10),
  endDate: end,
  reminderEnabled: false,
  reminderTimes: const [],
  colorValue: 0xFF6C5CE7,
  createdAt: DateTime(2026, 8, 1),
);

void main() {
  test('habit respects start date', () {
    expect(habit().isActiveOn(DateTime(2026, 8, 9)), isFalse);
    expect(habit().isActiveOn(DateTime(2026, 8, 10)), isTrue);
  });

  test('habit respects inclusive end date', () {
    final value = habit(end: DateTime(2026, 8, 12));
    expect(value.isActiveOn(DateTime(2026, 8, 12)), isTrue);
    expect(value.isActiveOn(DateTime(2026, 8, 13)), isFalse);
  });

  test('legacy columns use the first reminder time', () {
    final value = Habit(
      id: 1,
      name: 'Таблетки',
      startDate: DateTime(2026, 8, 10),
      reminderEnabled: true,
      reminderTimes: const [8 * 60 + 30, 14 * 60, 21 * 60],
      colorValue: 0xFF6C5CE7,
      createdAt: DateTime(2026, 8, 1),
    );

    expect(value.toMap()['reminder_hour'], 8);
    expect(value.toMap()['reminder_minute'], 30);
  });

  test('legacy database rows use the default icon', () {
    final value = Habit.fromMap({
      'id': 1,
      'name': 'Тест',
      'start_date': '2026-08-10',
      'end_date': null,
      'reminder_enabled': 0,
      'reminder_hour': 20,
      'reminder_minute': 0,
      'color_value': 0xFF6C5CE7,
      'created_at': '2026-08-01T10:00:00.000',
    });

    expect(value.iconKey, defaultHabitIconKey);
  });
}
