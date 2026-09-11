import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/home_page.dart';

class HabitGardenApp extends StatelessWidget {
  const HabitGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6C5CE7);
    return DynamicColorBuilder(
      builder: (dynamicLight, dynamicDark) {
        final lightScheme =
            dynamicLight ??
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
        final darkScheme =
            dynamicDark ??
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

        return MaterialApp(
          title: 'Сад привычек',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('en')],
          locale: const Locale('ru'),
          themeMode: ThemeMode.system,
          theme: _themeFor(lightScheme),
          darkTheme: _themeFor(darkScheme),
          home: const HomePage(),
        );
      },
    );
  }

  ThemeData _themeFor(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
    ),
  );
}
