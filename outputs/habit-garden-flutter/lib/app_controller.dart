import 'package:flutter/foundation.dart';

import 'core/date_utils.dart';
import 'data/habit_repository.dart';
import 'domain/completion.dart';
import 'domain/habit.dart';
import 'domain/habit_stats.dart';
import 'services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    HabitRepository? repository,
    NotificationService? notifications,
  })  : _repository = repository ?? HabitRepository(),
        _notifications = notifications ?? NotificationService.instance;

  final HabitRepository _repository;
  final NotificationService _notifications;
  List<Habit> habits = [];
  List<Completion> completions = [];
  bool loading = true;
  Object? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      habits = await _repository.getHabits();
      completions = await _repository.getCompletions();
    } on Object catch (caught) {
      error = caught;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool isCompleted(int habitId, DateTime date) => completions.any(
        (item) =>
            item.habitId == habitId && dateKey(item.date) == dateKey(date),
      );

  int completionCount(DateTime date) => completions
      .where((item) => dateKey(item.date) == dateKey(date))
      .length;

  HabitStats statsFor(int habitId) => HabitStats.fromCompletions(
        completions.where((item) => item.habitId == habitId),
      );

  HabitStats get totalStats {
    final streaks = HabitStats.fromCompletions(completions);
    return HabitStats(
      totalCompletions: completions.length,
      currentStreak: streaks.currentStreak,
      bestStreak: streaks.bestStreak,
    );
  }

  Future<void> toggle(Habit habit, DateTime date) async {
    final id = habit.id!;
    final completed = !isCompleted(id, date);
    await _repository.setCompleted(id, date, completed);
    if (completed) {
      completions.add(
        Completion(habitId: id, date: date, completedAt: DateTime.now()),
      );
    } else {
      completions.removeWhere(
        (item) => item.habitId == id && dateKey(item.date) == dateKey(date),
      );
    }
    notifyListeners();
  }

  Future<void> save(Habit habit) async {
    if (habit.reminderEnabled) await _notifications.requestPermission();
    final saved = await _repository.saveHabit(habit);
    await _notifications.scheduleHabit(saved);
    await load();
  }

  Future<void> delete(Habit habit) async {
    await _notifications.cancelHabit(habit.id!);
    await _repository.deleteHabit(habit.id!);
    await load();
  }
}
