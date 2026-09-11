import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../core/date_utils.dart';
import '../core/habit_icons.dart';
import '../domain/habit.dart';

class HabitFormPage extends StatefulWidget {
  const HabitFormPage({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  static const _colors = [
    0xFF6C5CE7,
    0xFF00A884,
    0xFFFF8A4C,
    0xFFE84393,
    0xFF2D9CDB,
    0xFFE2B93B,
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _reminderEnabled;
  late List<TimeOfDay> _reminderTimes;
  late String _iconKey;
  late int _colorValue;
  var _saving = false;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _startDate = dateOnly(habit?.startDate ?? DateTime.now());
    _endDate = habit?.endDate;
    _reminderEnabled = habit?.reminderEnabled ?? false;
    _reminderTimes = habit == null || habit.reminderTimes.isEmpty
        ? [const TimeOfDay(hour: 20, minute: 0)]
        : habit.reminderTimes
              .map(
                (minutes) =>
                    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
              )
              .toList();
    _iconKey = habit?.iconKey ?? defaultHabitIconKey;
    _colorValue = habit?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ru'),
    );
    if (selected == null) return;
    setState(() {
      _startDate = dateOnly(selected);
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
      locale: const Locale('ru'),
    );
    if (selected != null) setState(() => _endDate = dateOnly(selected));
  }

  Future<void> _pickTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (selected == null) return;
    setState(() {
      _reminderTimes[index] = selected;
      _reminderTimes.sort(
        (left, right) => _minutes(left).compareTo(_minutes(right)),
      );
    });
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  void _addReminder() {
    if (_reminderTimes.length >= 8) return;
    final last = _minutes(_reminderTimes.last);
    var candidate = (last + 6 * 60) % (24 * 60);
    final occupied = _reminderTimes.map(_minutes).toSet();
    while (occupied.contains(candidate)) {
      candidate = (candidate + 60) % (24 * 60);
    }
    setState(() {
      _reminderTimes.add(
        TimeOfDay(hour: candidate ~/ 60, minute: candidate % 60),
      );
      _reminderTimes.sort(
        (left, right) => _minutes(left).compareTo(_minutes(right)),
      );
    });
  }

  void _removeReminder(int index) {
    if (_reminderTimes.length == 1) return;
    setState(() => _reminderTimes.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final original = widget.habit;
    final habit = Habit(
      id: original?.id,
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      reminderEnabled: _reminderEnabled,
      reminderTimes: _reminderTimes.map(_minutes).toSet().toList()..sort(),
      iconKey: _iconKey,
      colorValue: _colorValue,
      createdAt: original?.createdAt ?? DateTime.now(),
    );
    try {
      await context.read<AppController>().save(habit);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $error')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: const Text('История выполнений также будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AppController>().delete(widget.habit!);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось удалить: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM y', 'ru');
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Редактирование' : 'Новая привычка'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Удалить',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_editing,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                hintText: 'Например, читать 20 минут',
                prefixIcon: Icon(habitIconByKey(_iconKey).icon),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Введите название привычки'
                  : null,
            ),
            const SizedBox(height: 18),
            Text('Период', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline_rounded),
                    title: const Text('Дата начала'),
                    trailing: Text(dateFormat.format(_startDate)),
                    onTap: _pickStartDate,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Дата окончания'),
                    subtitle: _endDate == null
                        ? const Text('Без ограничения')
                        : null,
                    trailing: _endDate == null
                        ? const Icon(Icons.chevron_right_rounded)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(dateFormat.format(_endDate!)),
                              IconButton(
                                tooltip: 'Убрать дату',
                                onPressed: () =>
                                    setState(() => _endDate = null),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ],
                          ),
                    onTap: _pickEndDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Оформление', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Иконка', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _IconChoices(
              options: habitIconOptions
                  .where((option) => !option.isAbstinence)
                  .toList(),
              selectedKey: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: 14),
            Text(
              'Отказ от вредного',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _IconChoices(
              options: habitIconOptions
                  .where((option) => option.isAbstinence)
                  .toList(),
              selectedKey: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: 18),
            Text('Цвет', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((value) {
                final selected = _colorValue == value;
                return InkResponse(
                  onTap: () => setState(() => _colorValue = value),
                  radius: 28,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Напоминать'),
                    subtitle: Text(
                      _reminderEnabled
                          ? '${_reminderTimes.length} ${_timesWord(_reminderTimes.length)} в день'
                          : 'Уведомления выключены',
                    ),
                    value: _reminderEnabled,
                    onChanged: (value) =>
                        setState(() => _reminderEnabled = value),
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 1, indent: 56),
                    ...List.generate(_reminderTimes.length, (index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 15,
                              child: Text('${index + 1}'),
                            ),
                            title: Text('Напоминание ${index + 1}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatTimeOfDay(
                                    _reminderTimes[index],
                                    alwaysUse24HourFormat: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_reminderTimes.length > 1)
                                  IconButton(
                                    tooltip: 'Удалить время',
                                    onPressed: () => _removeReminder(index),
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _pickTime(index),
                          ),
                          if (index < _reminderTimes.length - 1)
                            const Divider(height: 1, indent: 56),
                        ],
                      );
                    }),
                    if (_reminderTimes.length < 8)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addReminder,
                            icon: const Icon(Icons.add_alarm_rounded),
                            label: const Text('Добавить время'),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_editing ? 'Сохранить изменения' : 'Создать привычку'),
        ),
      ),
    );
  }

  String _timesWord(int count) {
    if (count == 1) return 'раз';
    if (count >= 2 && count <= 4) return 'раза';
    return 'раз';
  }
}

class _IconChoices extends StatelessWidget {
  const _IconChoices({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<HabitIconOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options.map((option) {
      return ChoiceChip(
        avatar: Icon(option.icon, size: 19),
        label: Text(option.label),
        selected: selectedKey == option.key,
        showCheckmark: false,
        onSelected: (_) => onSelected(option.key),
      );
    }).toList(),
  );
}
