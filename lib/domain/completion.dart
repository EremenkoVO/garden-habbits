import '../core/date_utils.dart';

class Completion {
  const Completion({
    required this.habitId,
    required this.date,
    required this.completedAt,
  });

  final int habitId;
  final DateTime date;
  final DateTime completedAt;

  Map<String, Object?> toMap() => {
    'habit_id': habitId,
    'completion_date': dateKey(date),
    'completed_at': completedAt.toIso8601String(),
  };

  factory Completion.fromMap(Map<String, Object?> map) => Completion(
    habitId: map['habit_id']! as int,
    date: dateFromKey(map['completion_date']! as String),
    completedAt: DateTime.parse(map['completed_at']! as String),
  );
}
