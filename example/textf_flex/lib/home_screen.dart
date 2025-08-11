import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:textf/textf.dart'; // Import your textf package

class HomeScreen extends StatelessWidget {
  final FlexScheme selectedScheme;
  final ThemeMode themeMode;
  final ValueChanged<FlexScheme?> onSchemeChanged;
  final VoidCallback onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.selectedScheme,
    required this.themeMode,
    required this.onSchemeChanged,
    required this.onThemeModeChanged,
  });

  // --- Helper Methods ---

  // Helper to build the example cards
  Widget _buildExampleCard({
    required BuildContext context,
    required String title,
    Widget? description,
    String? code,
    Widget? cardContent,
    Widget? textf,
  }) {
    final theme = Theme.of(context);
    Widget displayContent;
    if (cardContent != null) {
      displayContent = cardContent;
    } else if (textf != null) {
      displayContent = DefaultTextStyle.merge(
        style: theme.textTheme.bodyMedium ?? const TextStyle(),
        child: textf,
      );
    } else {
      displayContent = const Text('No content provided.');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8.0),
            if (description != null) ...[
              description,
              const SizedBox(height: 8.0),
            ],
            if (code != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Use theme color for code background
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextfOptions(
                  italicStyle: TextStyle(
                    fontFamily: 'RobotoMono',
                    color: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  child: Textf(
                    "`$code`",
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: displayContent,
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to capitalize the first letter of a string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _formatSchemeName(FlexScheme scheme) {
    final rawName = scheme.name;

    // Handle specific cases first
    if (rawName == 'blackWhite') return 'Black white';

    // Handle M3 suffix
    if (rawName.endsWith('M3')) {
      // Get the part before M3, replace underscores, capitalize first letter
      final prefix = rawName.substring(0, rawName.length - 2);
      final spacedPrefix = prefix.replaceAll('_', ' ');
      return '${_capitalize(spacedPrefix)} M3';
    } else {
      // General case: replace underscores, capitalize first letter
      final spacedName = rawName.replaceAll('_', ' ');
      return _capitalize(spacedName);
    }
  }
  // --- End Helper Methods ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the icon and tooltip for the ThemeMode toggle button
    final IconData modeIcon;
    final String modeTooltip;
    switch (themeMode) {
      case ThemeMode.light:
        modeIcon = Icons.dark_mode_outlined;
        modeTooltip = 'Switch to Dark Mode';
        break;
      case ThemeMode.dark:
        modeIcon = Icons.light_mode_outlined;
        modeTooltip = 'Switch to System Mode';
        break;
      case ThemeMode.system:
        modeIcon = Icons.brightness_auto_outlined;
        modeTooltip = 'Switch to Light Mode';
        break;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextfOptions(
          boldStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          italicStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          child: Textf(
            '_Textf_ with FlexColorScheme **${_formatSchemeName(selectedScheme)}**',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(modeIcon),
            tooltip: modeTooltip,
            onPressed: onThemeModeChanged,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<FlexScheme>(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              value: selectedScheme,
              underline: const SizedBox.shrink(),
              style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleMedium,
              iconEnabledColor: theme.appBarTheme.iconTheme?.color,
              items: FlexScheme.values
                  .map(
                    (scheme) => DropdownMenuItem<FlexScheme>(
                      value: scheme,
                      child: Text(
                        _formatSchemeName(scheme),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onSchemeChanged,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        children: [
          // --- Example Cards ---
          _buildExampleCard(
            context: context,
            title: 'Basic Formatting',
            description: Textf(
              '**No boilerplate. No TextSpan pain. Just** `Textf`.\n'
              'Easily apply bold, italic, strikethrough, and inline code styles using a clean, Markdown-like syntax.',
            ),
            code:
                'Textf(\'This is \\*\\*bold**, \\*italic*, \\~~strikethrough~~, \\`inline code\\`\')',
            textf: Textf('This is **bold**, *italic*, ~~strikethrough~~, `inline code`'),
          ),
          _buildExampleCard(
            context: context,
            title: 'Links',
            description: Textf(
              '**Themed links out of the box.**\n'
              'Textf automatically styles links to match your app’s theme — no extra setup needed.',
            ),
            code: "Textf(\n"
                "  'Visit the \\[Flutter Website](https://flutter.dev) '\n"
                "  'or \\[DartPad](https://dartpad.dev)',\n"
                ")",
            textf: Textf(
              'Visit the [Flutter Website](https://flutter.dev) '
              'or [DartPad](https://dartpad.dev)',
            ),
          ),
          _buildExampleCard(
            context: context,
            title: 'Override Link Style',
            description: Textf(
              '**Customize everything.**\n'
              'Freely override link styles, hover effects, and tap behavior using `TextfOptions`.',
            ),
            code: "TextfOptions(\n"
                "  _urlStyle_: TextStyle(\n"
                "    _color: colorScheme.secondary_,\n"
                "    fontWeight: FontWeight.bold,\n"
                "  ),\n"
                "  _urlHoverStyle_: TextStyle(\n"
                "    _decoration: TextDecoration.underline_,\n"
                "    decorationColor: colorScheme.secondary,\n"
                "  ),\n"
                "  child: _Textf_(\n"
                "    'This [link looks different]'\n"
                "    '(https://docs.flexcolorscheme.com/).',\n"
                "  ),\n"
                ")",
            textf: TextfOptions(
              urlStyle: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
              urlHoverStyle: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.secondary,
              ),
              child: Textf(
                'This [link looks different]'
                '(https://docs.flexcolorscheme.com/).',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
