import 'habit_stats.dart';

class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlocked,
    required this.progress,
  });

  final String title;
  final String description;
  final String emoji;
  final bool unlocked;
  final double progress;
}

List<Achievement> buildAchievements(HabitStats stats) => [
  Achievement(
    title: 'Первый росток',
    description: 'Выполнить привычку 1 раз',
    emoji: '🌱',
    unlocked: stats.totalCompletions >= 1,
    progress: (stats.totalCompletions / 1).clamp(0.0, 1.0).toDouble(),
  ),
  Achievement(
    title: 'Неделя силы',
    description: 'Серия из 7 дней',
    emoji: '🔥',
    unlocked: stats.bestStreak >= 7,
    progress: (stats.bestStreak / 7).clamp(0.0, 1.0).toDouble(),
  ),
  Achievement(
    title: 'Неудержимый',
    description: 'Серия из 30 дней',
    emoji: '⚡',
    unlocked: stats.bestStreak >= 30,
    progress: (stats.bestStreak / 30).clamp(0.0, 1.0).toDouble(),
  ),
  Achievement(
    title: 'Сотня',
    description: '100 выполнений суммарно',
    emoji: '🏆',
    unlocked: stats.totalCompletions >= 100,
    progress: (stats.totalCompletions / 100).clamp(0.0, 1.0).toDouble(),
  ),
];
