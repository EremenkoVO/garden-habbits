import 'package:flutter/material.dart';

const defaultHabitIconKey = 'leaf';

class HabitIconOption {
  const HabitIconOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.notificationIcon,
    this.isAbstinence = false,
  });

  final String key;
  final String label;
  final IconData icon;
  final String notificationIcon;
  final bool isAbstinence;
}

const habitIconOptions = <HabitIconOption>[
  HabitIconOption(
    key: defaultHabitIconKey,
    label: 'Рост',
    icon: Icons.eco_rounded,
    notificationIcon: 'ic_stat_leaf',
  ),
  HabitIconOption(
    key: 'fitness',
    label: 'Спорт',
    icon: Icons.fitness_center_rounded,
    notificationIcon: 'ic_stat_fitness',
  ),
  HabitIconOption(
    key: 'water',
    label: 'Вода',
    icon: Icons.water_drop_rounded,
    notificationIcon: 'ic_stat_water',
  ),
  HabitIconOption(
    key: 'book',
    label: 'Чтение',
    icon: Icons.menu_book_rounded,
    notificationIcon: 'ic_stat_book',
  ),
  HabitIconOption(
    key: 'meditation',
    label: 'Практика',
    icon: Icons.self_improvement_rounded,
    notificationIcon: 'ic_stat_meditation',
  ),
  HabitIconOption(
    key: 'walk',
    label: 'Прогулка',
    icon: Icons.directions_walk_rounded,
    notificationIcon: 'ic_stat_walk',
  ),
  HabitIconOption(
    key: 'sleep',
    label: 'Сон',
    icon: Icons.bedtime_rounded,
    notificationIcon: 'ic_stat_sleep',
  ),
  HabitIconOption(
    key: 'health',
    label: 'Здоровье',
    icon: Icons.medication_rounded,
    notificationIcon: 'ic_stat_health',
  ),
  HabitIconOption(
    key: 'no_smoking',
    label: 'Без сигарет',
    icon: Icons.smoke_free_rounded,
    notificationIcon: 'ic_stat_no_smoking',
    isAbstinence: true,
  ),
  HabitIconOption(
    key: 'no_drink',
    label: 'Без алкоголя',
    icon: Icons.no_drinks_rounded,
    notificationIcon: 'ic_stat_no_alcohol',
    isAbstinence: true,
  ),
  HabitIconOption(
    key: 'no_junk_food',
    label: 'Без вредной еды',
    icon: Icons.no_food_rounded,
    notificationIcon: 'ic_stat_no_food',
    isAbstinence: true,
  ),
  HabitIconOption(
    key: 'digital_detox',
    label: 'Без скроллинга',
    icon: Icons.mobile_off_rounded,
    notificationIcon: 'ic_stat_phone_off',
    isAbstinence: true,
  ),
  HabitIconOption(
    key: 'stop',
    label: 'Стоп',
    icon: Icons.block_rounded,
    notificationIcon: 'ic_stat_stop',
    isAbstinence: true,
  ),
];

HabitIconOption habitIconByKey(String key) => habitIconOptions.firstWhere(
  (option) => option.key == key,
  orElse: () => habitIconOptions.first,
);
