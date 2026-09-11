import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_controller.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await NotificationService.instance.initialize();
  await BackgroundService().initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppController()..load(),
      child: const HabitGardenApp(),
    ),
  );
}
