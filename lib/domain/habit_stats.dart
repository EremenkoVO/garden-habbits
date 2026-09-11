import '../core/date_utils.dart';
import 'completion.dart';

class HabitStats {
  const HabitStats({
    required this.totalCompletions,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int totalCompletions;
  final int currentStreak;
  final int bestStreak;

  factory HabitStats.fromCompletions(
    Iterable<Completion> completions, {
    DateTime? today,
  }) {
    final keys = completions.map((item) => dateKey(item.date)).toSet();
    if (keys.isEmpty) {
      return const HabitStats(
        totalCompletions: 0,
        currentStreak: 0,
        bestStreak: 0,
      );
    }

    final dates = keys.map(dateFromKey).toList()..sort();
    var best = 1;
    var running = 1;
    for (var index = 1; index < dates.length; index++) {
      if (dates[index].difference(dates[index - 1]).inDays == 1) {
        running++;
        if (running > best) best = running;
      } else {
        running = 1;
      }
    }

    var cursor = dateOnly(today ?? DateTime.now());
    if (!keys.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var current = 0;
    while (keys.contains(dateKey(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return HabitStats(
      totalCompletions: keys.length,
      currentStreak: current,
      bestStreak: best,
    );
  }
}
