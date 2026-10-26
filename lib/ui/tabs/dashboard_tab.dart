import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_controller.dart';
import '../../core/date_utils.dart';
import '../../domain/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/heatmap.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onEdit});

  final ValueChanged<Habit> onEdit;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late DateTime _selectedDate = dateOnly(DateTime.now());

  void _selectDate(DateTime date) {
    final day = dateOnly(date);
    if (day.isBefore(DateTime(2000)) || day.isAfter(dateOnly(DateTime.now()))) {
      return;
    }
    setState(() => _selectedDate = day);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: dateOnly(DateTime.now()),
      locale: const Locale('ru'),
    );
    if (selected != null) _selectDate(selected);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final active = controller.habits
        .where((habit) => habit.isActiveOn(_selectedDate))
        .toList();
    final done = active
        .where((habit) => controller.isCompleted(habit.id!, _selectedDate))
        .length;
    final displayedHabits = [...controller.habits]
      ..sort((left, right) {
        final leftIsActive = left.isActiveOn(_selectedDate);
        final rightIsActive = right.isActiveOn(_selectedDate);
        if (leftIsActive == rightIsActive) return 0;
        return leftIsActive ? -1 : 1;
      });

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          _DaySelector(
            selectedDate: _selectedDate,
            onSelected: _selectDate,
            onOpenCalendar: _pickDate,
          ),
          const SizedBox(height: 16),
          _DayHeader(
            date: _selectedDate,
            done: done,
            total: active.length,
            hasAnyHabits: controller.habits.isNotEmpty,
          ),
          const SizedBox(height: 16),
          Heatmap(selectedDate: _selectedDate, onDateSelected: _selectDate),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                dateKey(_selectedDate) == dateKey(DateTime.now())
                    ? 'Все привычки'
                    : 'Привычки · ${DateFormat('d MMM', 'ru').format(_selectedDate)}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$done/${active.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.habits.isEmpty)
            const _EmptyHabits()
          else
            ...displayedHabits.map(
              (habit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HabitCard(
                  habit: habit,
                  date: _selectedDate,
                  onEdit: () => widget.onEdit(habit),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDate,
    required this.onSelected,
    required this.onOpenCalendar,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final nextWeekDate = selectedDate.add(const Duration(days: 7));
    final canMoveNext = !weekStart.add(const Duration(days: 7)).isAfter(today);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Предыдущая неделя',
                  onPressed: () => onSelected(
                    selectedDate.subtract(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onOpenCalendar,
                    icon: const Icon(Icons.calendar_today_rounded, size: 17),
                    label: Text(
                      DateFormat('LLLL y', 'ru').format(selectedDate),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Следующая неделя',
                  onPressed: canMoveNext
                      ? () => onSelected(
                          nextWeekDate.isAfter(today) ? today : nextWeekDate,
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Row(
              children: days.map((day) {
                final isSelected = dateKey(day) == dateKey(selectedDate);
                final isToday = dateKey(day) == dateKey(today);
                final enabled = !day.isAfter(today);
                final colors = Theme.of(context).colorScheme;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: enabled ? () => onSelected(day) : null,
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: isToday && !isSelected
                              ? Border.all(color: colors.primary)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E', 'ru').format(day).substring(0, 2),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? colors.onPrimary
                                    : enabled
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface.withValues(alpha: 0.28),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? colors.onPrimary
                                    : enabled
                                    ? colors.onSurface
                                    : colors.onSurface.withValues(alpha: 0.28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.done,
    required this.total,
    required this.hasAnyHabits,
  });

  final DateTime date;

  final int done;
  final int total;
  final bool hasAnyHabits;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final colorScheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final dayName = dateKey(date) == dateKey(today)
        ? 'Сегодня'
        : dateKey(date) == dateKey(yesterday)
        ? 'Вчера'
        : DateFormat('d MMMM', 'ru').format(date);
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
                      ? hasAnyHabits
                            ? 'На этот день нет привычек'
                            : 'Посадите первую привычку'
                      : done == total
                      ? '$dayName — всё выполнено!'
                      : '$dayName · $done из $total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? hasAnyHabits
                            ? 'Выберите другой день'
                            : 'Маленькие шаги дают большие результаты'
                      : dateKey(date) == dateKey(today)
                      ? 'Продолжайте в своём темпе'
                      : 'Можно восстановить пропущенные отметки',
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
