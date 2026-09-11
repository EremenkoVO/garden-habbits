import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/date_utils.dart';
import '../domain/habit.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // tz.local remains usable even if an OEM returns an unknown zone.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_habit'),
      ),
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> scheduleHabit(Habit habit) async {
    if (habit.id == null) return;
    await cancelHabit(habit.id!);
    if (!habit.reminderEnabled) return;

    final now = DateTime.now();
    final firstDay = dateOnly(now).isAfter(dateOnly(habit.startDate))
        ? dateOnly(now)
        : dateOnly(habit.startDate);
    final windowEnd = dateOnly(now).add(const Duration(days: 30));
    final lastDay = habit.endDate != null && habit.endDate!.isBefore(windowEnd)
        ? dateOnly(habit.endDate!)
        : windowEnd;
    if (firstDay.isAfter(lastDay)) return;

    var offset = 0;
    for (final day in daysBetween(firstDay, lastDay)) {
      for (final minutesOfDay in habit.reminderTimes) {
        final scheduled = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          minutesOfDay ~/ 60,
          minutesOfDay % 60,
        );
        if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          id: (habit.id! * 10000 + offset) & 0x7FFFFFFF,
          title: 'Время для привычки',
          body: habit.name,
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Напоминания о привычках',
              channelDescription: 'Ежедневные напоминания о привычках',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'habit:${habit.id}',
        );
        offset++;
      }
    }
  }

  Future<void> cancelHabit(int habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload == 'habit:$habitId') {
        await _plugin.cancel(id: notification.id);
      }
    }
  }
}
