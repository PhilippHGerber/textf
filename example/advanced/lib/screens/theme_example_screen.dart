// example/lib/screens/theme_example_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ThemeExampleScreen extends StatelessWidget {
  const new({
    required this.currentThemeMode,
    required this.toggleThemeMode,
    super.key,
  });
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  @override
  Widget build(BuildContext context) {
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon = currentBrightness == Brightness.dark
        ? Icons.light_mode_outlined
        : Icons.dark_mode_outlined;
    final String themeName = currentBrightness == Brightness.dark ? 'Dark' : 'Light';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Light & Dark Defaults'),
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
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "Textf's default colors follow the text, not the theme ($themeName Theme). Links keep a fixed blue (#1A73E8); inline code gets a faint tint of the text color, stronger in dark mode. Use the toggle button in the AppBar to see the changes, and TextfOptions color options to use theme colors instead.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 20),
          ExampleCard(
            title: 'Default Link Styling',
            description: 'Links ([text](url)) use a fixed blue (#1A73E8) by default. Set TextfOptions.linkColor to use a brand color.',
            code: '''
Textf(
  '==Visit== the [Flutter website](https://flutter.dev) '
  'or the [Dart website](https://dart.dev).'
)
            ''',
            child: Textf(
              '==Visit== the [Flutter website](https://flutter.dev) or the [Dart website](https://dart.dev).',
              // Use a slightly larger font size for better visibility
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          ExampleCard(
            title: 'Default Code Styling',
            description: 'Inline code (`code`) keeps the text color on a faint tint of it (5% in light mode, 15% in dark mode).',
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
