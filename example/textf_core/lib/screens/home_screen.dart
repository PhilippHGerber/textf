// example/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import 'basic_formatting_screen.dart';
import 'complex_formatting_screen.dart';
import 'nested_formatting_screen.dart';
import 'placeholder_example_screen.dart';
import 'screenshot_screen.dart';
import 'theme_cache_test_screen.dart';
import 'theme_example_screen.dart';
import 'url_example_screen.dart';

class HomeScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const HomeScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the icon based on the current theme mode
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon = currentBrightness == Brightness.dark
        ? Icons.light_mode_outlined // Icon to show when it's dark (will switch to light)
        : Icons.dark_mode_outlined; // Icon to show when it's light (will switch to dark)

    const WidgetSpan badgeNew = WidgetSpan(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 6, right: 6, top: 3, bottom: 2),
          child: Text(
            'NEW',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textf Examples'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: toggleThemeMode, // Use the callback passed down
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          children: [
            // Add tile for the new Theme Example Screen
            _buildExampleTile(
              context,
              const Text('Theme Examples'),
              const Text('Show default link/code styling adapting to themes'),
              ThemeExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              const Text('Basic Formatting'),
              const Text('Simple examples of bold, italic, strikethrough, and code formatting'),
              BasicFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              const Text('Nested Formatting'),
              const Text('Examples of nested formatting styles'),
              NestedFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              const Text('Complex Formatting'),
              const Text('More advanced text formatting combinations'),
              ComplexFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              const Text('URL Examples'),
              const Text('Examples of URL formatting and interaction'),
              UrlExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),

            _buildExampleTile(
              context,
              Textf(
                '{new} Placeholder Example',
                placeholders: {
                  'new': badgeNew,
                },
              ),
              const Text('Inject widgets like Icons and Images inline'),
              PlaceholderExampleScreen(
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              const Textf(
                '{new} Theme Cache Examples',
                placeholders: {
                  'new': badgeNew,
                },
              ),
              const Text('Show Caching'),
              ThemeCacheTestScreen(),
            ),
            _buildExampleTile(
              context,
              const Text('Screenshot Generator'),
              const Text('Create custom formatted text and take screenshots'),
              ScreenshotScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleTile(
    BuildContext context,
    Widget title,
    Widget subtitle,
    Widget destination, // Destination now already has theme info
  ) {
    return Card(
      // Use theme card settings
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical margin
      child: ListTile(
        title: title,
        subtitle: subtitle,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}
