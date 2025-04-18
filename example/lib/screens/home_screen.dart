// example/lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import 'basic_formatting_screen.dart';
import 'chat_example_screen.dart';
import 'complex_formatting_screen.dart';
import 'nested_formatting_screen.dart';
import 'notification_example_screen.dart';
import 'screenshot_screen.dart';
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
              'Theme Examples',
              'Show default link/code styling adapting to themes',
              ThemeExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Basic Formatting',
              'Simple examples of bold, italic, strikethrough, and code formatting',
              BasicFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Nested Formatting',
              'Examples of nested formatting styles',
              NestedFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Complex Formatting',
              'More advanced text formatting combinations',
              ComplexFormattingScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'URL Examples',
              'Examples of URL formatting and interaction',
              UrlExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Chat Bubble Example',
              'Example of formatting in a chat bubble',
              ChatExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Notification Example',
              'Example of formatting in a notification',
              NotificationExampleScreen(
                // Pass down theme info
                currentThemeMode: currentThemeMode,
                toggleThemeMode: toggleThemeMode,
              ),
            ),
            _buildExampleTile(
              context,
              'Screenshot Generator',
              'Create custom formatted text and take screenshots',
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
    String title,
    String subtitle,
    Widget destination, // Destination now already has theme info
  ) {
    return Card(
      // Use theme card settings
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical margin
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
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
