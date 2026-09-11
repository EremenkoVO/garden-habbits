import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_controller.dart';
import '../../domain/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/heatmap.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.onEdit});

  final ValueChanged<Habit> onEdit;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final today = DateTime.now();
    final active = controller.habits
        .where((habit) => habit.isActiveOn(today))
        .toList();
    final done = active
        .where((habit) => controller.isCompleted(habit.id!, today))
        .length;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          _TodayHeader(done: done, total: active.length),
          const SizedBox(height: 16),
          const Heatmap(),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                'Все привычки',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${controller.habits.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.habits.isEmpty)
            const _EmptyHabits()
          else
            ...controller.habits.map(
              (habit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HabitCard(habit: habit, onEdit: () => onEdit(habit)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'Посадите первую привычку'
                      : done == total
                      ? 'Идеальный день!'
                      : 'Сегодня $done из $total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Маленькие шаги дают большие результаты'
                      : 'Продолжайте в своём темпе',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox.square(
            dimension: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: colorScheme.onPrimary.withValues(
                    alpha: 0.22,
                  ),
                  color: colorScheme.onPrimary,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.spa_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Здесь появятся ваши привычки',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Нажмите «Привычка», чтобы начать',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
