import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_controller.dart';
import '../../core/habit_icons.dart';
import '../../domain/habit.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({super.key, required this.habit, required this.onEdit});

  final Habit habit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final today = DateTime.now();
    final activeToday = habit.isActiveOn(today);
    final completed = controller.isCompleted(habit.id!, today);
    final stats = controller.statsFor(habit.id!);
    final color = Color(habit.colorValue);
    final habitIcon = habitIconByKey(habit.iconKey);

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(habitIcon.icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Meta(
                          icon: Icons.local_fire_department_rounded,
                          text: '${stats.currentStreak} дн.',
                        ),
                        if (habit.reminderEnabled)
                          _Meta(
                            icon: Icons.notifications_active_outlined,
                            text: _reminderLabel(habit),
                          ),
                        if (habit.endDate != null)
                          _Meta(
                            icon: Icons.flag_outlined,
                            text: DateFormat(
                              'd MMM',
                              'ru',
                            ).format(habit.endDate!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: completed ? 'Отменить выполнение' : 'Выполнить сегодня',
                child: InkResponse(
                  onTap: activeToday
                      ? () => controller.toggle(habit, today)
                      : null,
                  radius: 28,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: completed ? color : color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completed ? Icons.check_rounded : Icons.circle_outlined,
                      color: completed ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reminderLabel(Habit habit) {
    String format(int minutes) =>
        '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';

    if (habit.reminderTimes.isEmpty) return 'включены';
    if (habit.reminderTimes.length <= 2) {
      return habit.reminderTimes.map(format).join(' · ');
    }
    final count = habit.reminderTimes.length;
    if (count >= 2 && count <= 4) {
      return '$count раза в день';
    }
    return '$count раз в день';
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
