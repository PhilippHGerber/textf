import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '/shell/playground_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TextfPlaygroundApp());
}

class TextfPlaygroundApp extends StatefulWidget {
  const TextfPlaygroundApp({super.key});

  @override
  State<TextfPlaygroundApp> createState() => _TextfPlaygroundAppState();
}

class _TextfPlaygroundAppState extends State<TextfPlaygroundApp> {
  // ignore: avoid-late-keyword
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
    _themeModeNotifier.value =
        _themeModeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Textf Playground',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
          home: PlaygroundShell(
            currentThemeMode: currentMode,
            toggleThemeMode: _toggleThemeMode,
          ),
        );
      },
    );
  }
}
