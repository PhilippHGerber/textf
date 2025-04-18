// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TextfExampleApp());
}

class TextfExampleApp extends StatefulWidget {
  const TextfExampleApp({super.key});

  @override
  State<TextfExampleApp> createState() => _TextfExampleAppState();
}

class _TextfExampleAppState extends State<TextfExampleApp> {
  // Use ValueNotifier for simple state management
  // Initialize with system preference or default to dark
  late final ValueNotifier<ThemeMode> _themeModeNotifier;

  @override
  void initState() {
    super.initState();
    // Read initial system theme preference
    final Brightness platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    _themeModeNotifier = ValueNotifier(platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
    // You could also default to ThemeMode.dark or ThemeMode.system
  }

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    super.dispose();
  }

  void _toggleThemeMode() {
    _themeModeNotifier.value = _themeModeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the notifier to rebuild MaterialApp when the theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Textf Example',
          // Define explicit light and dark themes
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            // Optional: Customize specific component themes for light mode
            cardTheme: const CardTheme(
              elevation: 1,
              margin: EdgeInsets.zero, // Adjusted for consistency
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            // Optional: Customize specific component themes for dark mode
            cardTheme: const CardTheme(
              elevation: 1,
              margin: EdgeInsets.zero, // Adjusted for consistency
            ),
          ),
          themeMode: currentMode, // Set the current theme mode
          // Pass down the toggle function and current mode to HomeScreen
          home: HomeScreen(
            currentThemeMode: currentMode,
            toggleThemeMode: _toggleThemeMode,
          ),
        );
      },
    );
  }
}
