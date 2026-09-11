import '../core/date_utils.dart';
import '../core/habit_icons.dart';

class Habit {
  const Habit({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.reminderEnabled,
    required this.reminderTimes,
    this.iconKey = defaultHabitIconKey,
    required this.colorValue,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final bool reminderEnabled;

  /// Minutes since midnight for every daily reminder.
  final List<int> reminderTimes;
  final String iconKey;

  int get reminderHour =>
      (reminderTimes.isEmpty ? 20 * 60 : reminderTimes.first) ~/ 60;
  int get reminderMinute =>
      (reminderTimes.isEmpty ? 20 * 60 : reminderTimes.first) % 60;
  final int colorValue;
  final DateTime createdAt;

  bool isActiveOn(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(dateOnly(startDate)) &&
        (endDate == null || !day.isAfter(dateOnly(endDate!)));
  }

  Habit copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? reminderEnabled,
    List<int>? reminderTimes,
    String? iconKey,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'start_date': dateKey(startDate),
    'end_date': endDate == null ? null : dateKey(endDate!),
    'reminder_enabled': reminderEnabled ? 1 : 0,
    'reminder_hour': reminderHour,
    'reminder_minute': reminderMinute,
    'icon_key': iconKey,
    'color_value': colorValue,
    'created_at': createdAt.toIso8601String(),
  };

  factory Habit.fromMap(Map<String, Object?> map, {List<int>? reminderTimes}) {
    final enabled = (map['reminder_enabled']! as int) == 1;
    final legacyTime =
        (map['reminder_hour']! as int) * 60 + (map['reminder_minute']! as int);
    return Habit(
      id: map['id']! as int,
      name: map['name']! as String,
      startDate: dateFromKey(map['start_date']! as String),
      endDate: map['end_date'] == null
          ? null
          : dateFromKey(map['end_date']! as String),
      reminderEnabled: enabled,
      reminderTimes: reminderTimes == null || reminderTimes.isEmpty
          ? enabled
                ? [legacyTime]
                : []
          : List.unmodifiable(reminderTimes),
      iconKey: map['icon_key'] as String? ?? defaultHabitIconKey,
      colorValue: map['color_value']! as int,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}
