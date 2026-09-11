import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_controller.dart';
import '../../core/date_utils.dart';

class Heatmap extends StatelessWidget {
  const Heatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final today = dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 83));
    final alignedStart = start.subtract(Duration(days: start.weekday - 1));
    final days = List.generate(
      13 * 7,
      (index) => alignedStart.add(Duration(days: index)),
    );
    final primary = Theme.of(context).colorScheme.primary;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Последние 12 недель',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(13, (week) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      children: List.generate(7, (weekday) {
                        final date = days[week * 7 + weekday];
                        final activeCount = controller.habits
                            .where((habit) => habit.isActiveOn(date))
                            .length;
                        final done = controller.completionCount(date);
                        final intensity = activeCount == 0
                            ? 0.0
                            : math.min(done / activeCount, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Tooltip(
                            message:
                                '${DateFormat('d MMMM', 'ru').format(date)}: $done',
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: intensity == 0
                                    ? colorScheme.surfaceContainerHighest
                                    : Color.lerp(
                                        primary.withValues(alpha: 0.22),
                                        primary,
                                        intensity,
                                      ),
                                borderRadius: BorderRadius.circular(5),
                                border: dateKey(date) == dateKey(today)
                                    ? Border.all(color: primary, width: 1.5)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Чем ярче клетка, тем больше привычек выполнено',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
