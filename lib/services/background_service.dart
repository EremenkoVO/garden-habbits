import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/date_utils.dart';
import '../data/habit_repository.dart';
import 'notification_service.dart';

const refreshRemindersTask = 'refresh_habit_reminders';

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != refreshRemindersTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.instance.initialize();
    final repository = HabitRepository();
    final habits = await repository.getHabits();
    final completions = await repository.getCompletions();
    for (final habit in habits.where((item) => item.reminderEnabled)) {
      final completedDates = completions
          .where((item) => item.habitId == habit.id)
          .map((item) => dateKey(item.date))
          .toSet();
      await NotificationService.instance.scheduleHabit(
        habit,
        completedDates: completedDates,
      );
    }
    return true;
  });
}

class BackgroundService {
  Future<void> initialize() async {
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      'habit-reminder-window-refresh',
      refreshRemindersTask,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
