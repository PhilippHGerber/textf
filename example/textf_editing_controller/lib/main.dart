import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '/screens/web_demo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TextfWebDemo());
}

class TextfWebDemo extends StatefulWidget {
  const TextfWebDemo({super.key});

  @override
  State<TextfWebDemo> createState() => _TextfWebDemoState();
}

class _TextfWebDemoState extends State<TextfWebDemo> {
  late final ValueNotifier<ThemeMode> _themeModeNotifier;

  @override
  void initState() {
    super.initState();
    final platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    _themeModeNotifier = ValueNotifier(
      platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    super.dispose();
  }

  void _toggleThemeMode() {
    _themeModeNotifier.value = _themeModeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Textf — Live Formatting Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: WebDemoScreen(
            currentThemeMode: currentMode,
            toggleThemeMode: _toggleThemeMode,
          ),
        );
      },
    );
  }
}
