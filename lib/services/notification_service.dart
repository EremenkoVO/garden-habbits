import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/date_utils.dart';
import '../core/habit_icons.dart';
import '../core/notification_payload.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';

const notificationCheckInActionId = 'check_in';

@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse response) async {
  if (response.actionId != notificationCheckInActionId) return;
  final habitId = habitIdFromNotificationPayload(response.payload);
  if (habitId == null) return;

  final date = dateFromNotificationPayload(response.payload) ?? DateTime.now();
  await HabitRepository().setCompleted(habitId, date, true);
  await NotificationService.instance.cancelHabitForDate(habitId, date);
}

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
      onDidReceiveNotificationResponse: notificationActionBackground,
      onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> scheduleHabit(
    Habit habit, {
    Set<String> completedDates = const {},
  }) async {
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
      if (completedDates.contains(dateKey(day))) continue;
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
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Напоминания о привычках',
              channelDescription: 'Ежедневные напоминания о привычках',
              importance: Importance.high,
              priority: Priority.high,
              icon: habitIconByKey(habit.iconKey).notificationIcon,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  notificationCheckInActionId,
                  'Отметиться',
                  semanticAction: SemanticAction.markAsRead,
                ),
              ],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: habitNotificationPayload(habit.id!, day),
        );
        offset++;
      }
    }
  }

  Future<void> cancelHabit(int habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (habitIdFromNotificationPayload(notification.payload) == habitId) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }

  Future<void> cancelHabitForDate(int habitId, DateTime date) async {
    final targetPayload = habitNotificationPayload(habitId, date);
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload == targetPayload) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }
}
