import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_controller.dart';
import '../../domain/achievement.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final stats = controller.totalStats;
    final achievements = buildAchievements(stats);
    final unlocked = achievements.where((item) => item.unlocked).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 42)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked из ${achievements.length} открыто',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${stats.totalCompletions} выполнений · рекорд ${stats.bestStreak} дн.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AchievementCard(achievement: achievement),
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: achievement.unlocked ? 1 : 0.56,
      duration: const Duration(milliseconds: 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: achievement.unlocked
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  achievement.unlocked ? achievement.emoji : '🔒',
                  style: const TextStyle(fontSize: 27),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    if (!achievement.unlocked) ...[
                      const SizedBox(height: 9),
                      LinearProgressIndicator(
                        value: achievement.progress,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ],
                ),
              ),
              if (achievement.unlocked)
                const Icon(Icons.check_circle_rounded, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
