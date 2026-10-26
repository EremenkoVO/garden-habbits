import 'dart:async';

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
  }) : _repository = repository ?? HabitRepository(),
       _notifications = notifications ?? NotificationService.instance;

  final HabitRepository _repository;
  final NotificationService _notifications;
  List<Habit> habits = [];
  List<Completion> completions = [];
  bool loading = true;
  Object? error;
  bool _didRefreshReminders = false;
  Future<void>? _reminderRefresh;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      habits = await _repository.getHabits();
      completions = await _repository.getCompletions();
      if (!_didRefreshReminders) {
        _didRefreshReminders = true;
        _reminderRefresh = _refreshReminders();
        unawaited(_reminderRefresh);
      }
    } on Object catch (caught) {
      error = caught;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshReminders() async {
    try {
      for (final habit in habits.where((item) => item.reminderEnabled)) {
        await _notifications.scheduleHabit(
          habit,
          completedDates: _completionDatesFor(habit.id!),
        );
      }
    } on Object {
      _didRefreshReminders = false;
    }
  }

  Future<void> refreshCompletions() async {
    try {
      completions = await _repository.getCompletions();
      error = null;
    } on Object catch (caught) {
      error = caught;
    }
    notifyListeners();
  }

  bool isCompleted(int habitId, DateTime date) => completions.any(
    (item) => item.habitId == habitId && dateKey(item.date) == dateKey(date),
  );

  int completionCount(DateTime date) =>
      completions.where((item) => dateKey(item.date) == dateKey(date)).length;

  Set<String> _completionDatesFor(int habitId) => completions
      .where((item) => item.habitId == habitId)
      .map((item) => dateKey(item.date))
      .toSet();

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
    final day = dateOnly(date);
    if (day.isAfter(dateOnly(DateTime.now())) || !habit.isActiveOn(day)) return;
    final id = habit.id!;
    final completed = !isCompleted(id, day);
    await _repository.setCompleted(id, day, completed);
    if (completed) {
      completions.add(
        Completion(habitId: id, date: day, completedAt: DateTime.now()),
      );
    } else {
      completions.removeWhere(
        (item) => item.habitId == id && dateKey(item.date) == dateKey(day),
      );
    }
    notifyListeners();

    if (habit.reminderEnabled && dateKey(day) == dateKey(DateTime.now())) {
      try {
        await _reminderRefresh;
        if (completed) {
          await _notifications.cancelHabitForDate(id, day);
        } else {
          await _notifications.scheduleHabit(
            habit,
            completedDates: _completionDatesFor(id),
          );
        }
      } on Object {
        // Completion is already saved; a later refresh will repair reminders.
      }
    }
  }

  Future<void> save(Habit habit) async {
    if (habit.reminderEnabled) await _notifications.requestPermission();
    final saved = await _repository.saveHabit(habit);
    await _notifications.scheduleHabit(
      saved,
      completedDates: _completionDatesFor(saved.id!),
    );
    await load();
  }

  Future<void> delete(Habit habit) async {
    await _notifications.cancelHabit(habit.id!);
    await _repository.deleteHabit(habit.id!);
    await load();
  }
}
