// Run with: flutter run -t lib/main_material.dart
import 'package:material_ui/material_ui.dart'; // SDK Material: 'package:flutter/material.dart'
import 'package:textf/textf.dart';

void main() => runApp(const MaterialRecipeApp());

/// The Material recipe
class MaterialRecipeApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MaterialRecipeApp> createState() => _MaterialRecipeAppState();
}

class _MaterialRecipeAppState extends State<MaterialRecipeApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark),
      themeMode: _themeMode,
      builder: (context, child) {
        final theme = Theme.of(context);
        return TextfOptions(
          linkColor: theme.colorScheme.primary,
          codeBackgroundColor: theme.colorScheme.surfaceContainer,
          thematicBreakColor: theme.dividerColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeScreen(
        isDark: _themeMode == ThemeMode.dark,
        onDarkChanged: (isDark) => setState(() {
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const new({required this.isDark, required this.onDarkChanged, super.key});

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textf + material_ui'),
        actions: [
          const Center(child: Text('Dark')),
          Switch(value: isDark, onChanged: onDarkChanged),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Textf(_demo),
      ),
    );
  }
}

const String _demo = '''
# Theme colors

A [link](https://example.com), some `inline code` and a ==highlight==.

---

**Bold**, *italic* and ~~strikethrough~~ keep their defaults.''';
