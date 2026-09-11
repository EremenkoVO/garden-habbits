import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../domain/habit.dart';
import 'habit_form_page.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/dashboard_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _index = 0;

  Future<void> _openForm([Habit? habit]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => HabitFormPage(habit: habit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Сад привычек' : 'Достижения'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: controller.loading ? null : controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: controller.loading
            ? const Center(child: CircularProgressIndicator())
            : controller.error != null
                ? _ErrorState(onRetry: controller.load)
                : IndexedStack(
                    index: _index,
                    children: [
                      DashboardTab(onEdit: _openForm),
                      const AchievementsTab(),
                    ],
                  ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Привычка'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Награды',
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52),
              const SizedBox(height: 12),
              const Text('Не удалось открыть локальную базу'),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ),
        ),
      );
}
