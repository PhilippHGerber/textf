// example/lib/screens/theme_example_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ThemeExampleScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const ThemeExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final String themeName = currentBrightness == Brightness.dark ? "Dark" : "Light";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Awareness'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Textf automatically adapts the default styling for links and inline code to the current application theme ($themeName Theme). Use the toggle button in the AppBar to see the changes.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 20),
          ExampleCard(
            title: 'Default Link Styling',
            description: 'Links ([text](url)) use the theme\'s primary color by default.',
            code: '''
Textf(
  'Visit the [Flutter website](https://flutter.dev) '
  'or the [Dart website](https://dart.dev).'
)
            ''',
            child: Textf(
              'Visit the [Flutter website](https://flutter.dev) or the [Dart website](https://dart.dev).',
              // Use a slightly larger font size for better visibility
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          ExampleCard(
            title: 'Default Code Styling',
            description: 'Inline code (`code`) uses theme-appropriate background and text colors.',
            code: '''
Textf(
  'Check the `pubspec.yaml` and the `main.dart` files.'
)
            ''',
            child: Textf(
              'Check the `pubspec.yaml` and the `main.dart` files.',
              // Use a slightly larger font size for better visibility
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          ExampleCard(
            title: 'Mixed Default Styles',
            description: 'Combine default link and code styles within regular text.',
            code: '''
Textf(
  'Refer to `TextfStyleResolver` in the [source code](https://github.com/PhilippHGerber/textf).'
)
            ''',
            child: Textf(
              'Refer to `TextfStyleResolver` in the [source code](https://github.com/PhilippHGerber/textf).',
              // Use a slightly larger font size for better visibility
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
