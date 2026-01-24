import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

/// A diagnostic screen to test theme change cache invalidation.
///
/// This screen helps verify that Textf widgets properly update
/// when the theme changes (light <-> dark).
class ThemeCacheTestScreen extends StatefulWidget {
  const ThemeCacheTestScreen({super.key});

  @override
  State<ThemeCacheTestScreen> createState() => _ThemeCacheTestScreenState();
}

class _ThemeCacheTestScreenState extends State<ThemeCacheTestScreen> {
  ThemeMode _themeMode = ThemeMode.light;
  int _rebuildCount = 0;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      _rebuildCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We wrap in our own MaterialApp to control theme independently
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Theme Cache Test',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.light, // or Brightness.dark
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark, // or Brightness.light
        ),
      ),
      home: _ThemeCacheTestBody(
        themeMode: _themeMode,
        rebuildCount: _rebuildCount,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class _ThemeCacheTestBody extends StatelessWidget {
  const _ThemeCacheTestBody({
    required this.themeMode,
    required this.rebuildCount,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final int rebuildCount;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Cache Test'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current State',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Theme: ${isDark ? "DARK" : "LIGHT"}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                    Text(
                      'Toggle count: $rebuildCount',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                    const Divider(),
                    Text(
                      'Expected Colors:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ColorRow(
                      label: 'Link (primary)',
                      color: colorScheme.primary,
                    ),
                    _ColorRow(
                      label: 'Code bg (surfaceContainer)',
                      color: colorScheme.surfaceContainer,
                    ),
                    _ColorRow(
                      label: 'Code text (onSurfaceVariant)',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Section: Links
            _TestSection(
              title: '1. Link Color Test',
              description: 'Link should use colorScheme.primary',
              expectedColor: colorScheme.primary,
              child: const Textf(
                'Click this [example link](https://example.com) to test.',
              ),
            ),

            const SizedBox(height: 16),

            // Test Section: Code
            _TestSection(
              title: '2. Inline Code Test',
              description: 'Code background should use surfaceContainer',
              expectedColor: colorScheme.surfaceContainer,
              child: const Textf(
                'Here is some `inline code` in the text.',
              ),
            ),

            const SizedBox(height: 16),

            // Test Section: Multiple formats
            _TestSection(
              title: '3. Combined Formatting',
              description: 'All theme-dependent styles should update together',
              child: const Textf(
                '==**Bold**, *italic*, `code`==, and [link](https://example.com).',
              ),
            ),

            const SizedBox(height: 16),

            // Test Section: Link inside formatting
            _TestSection(
              title: '4. Nested: Link in Bold',
              description: 'Link color should still follow theme',
              expectedColor: colorScheme.primary,
              child: const Textf(
                '**Bold text with [bold link](https://example.com) inside.**',
              ),
            ),

            const SizedBox(height: 16),

            // Test Section: Code inside link
            _TestSection(
              title: '5. Nested: Code in Link',
              description: 'Complex nesting should handle theme change',
              child: const Textf(
                'Visit [`code link`](https://example.com) for more.',
              ),
            ),

            const SizedBox(height: 16),

            // Test Section: With TextfOptions override
            _TestSection(
              title: '6. TextfOptions Override',
              description: 'Custom linkStyle should NOT change with theme',
              child: const TextfOptions(
                linkStyle: TextStyle(color: Colors.orange),
                child: Textf(
                  'This [orange link](https://example.com) stays orange.',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diagnostic: Actual widget inspection
            _DiagnosticSection(theme: theme),

            const SizedBox(height: 32),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Note the current link/code colors\n'
                      '2. Tap the theme toggle button in the app bar\n'
                      '3. Verify ALL Textf widgets update their colors\n'
                      '4. Toggle back and forth multiple times\n'
                      '5. If colors don\'t change → cache invalidation bug',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onToggleTheme,
        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        label: Text('Switch to ${isDark ? "Light" : "Dark"}'),
      ),
    );
  }
}

class _TestSection extends StatelessWidget {
  const _TestSection({
    required this.title,
    required this.description,
    required this.child,
    this.expectedColor,
  });

  final String title;
  final String description;
  final Widget child;
  final Color? expectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (expectedColor != null)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: expectedColor,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${_colorToHex(color)}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticSection extends StatelessWidget {
  const _DiagnosticSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Diagnostic',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            // This Builder ensures we get fresh context each rebuild
            Builder(
              builder: (innerContext) {
                final innerTheme = Theme.of(innerContext);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme.of(context).brightness: ${innerTheme.brightness}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      'colorScheme.primary: ${_colorToHex(innerTheme.colorScheme.primary)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      'hashCode: ${innerTheme.hashCode}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
