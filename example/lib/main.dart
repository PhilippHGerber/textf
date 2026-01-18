// Textf Feature Showcase - A comprehensive code reference
// This file demonstrates all Textf features with concise comments.
// This file is a code reference, not UI showcase.

// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
// import 'package:url_launcher/url_launcher.dart'; // Uncomment for real URL handling

void main() => runApp(const TextfShowcaseApp());

class TextfShowcaseApp extends StatelessWidget {
  const TextfShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textf Feature Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.light,
      home: const ShowcaseScreen(),
    );
  }
}

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Textf Features')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────────────────────
            // SECTION 1: Basic Formatting
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('1. Basic Formatting'),

            // Bold: Use ** or __
            const Textf('This is **bold** text.'),
            const Textf('This is also __bold__ text.'),

            // Italic: Use * or _
            const Textf('This is *italic* text.'),
            const Textf('This is also _italic_ text.'),

            // Bold + Italic: Use *** or ___
            const Textf('This is ***bold and italic*** text.'),
            const Textf('This is also ___bold and italic___ text.'),

            // Strikethrough: Use ~~
            const Textf('This is ~~strikethrough~~ text.'),

            // Underline: Use ++
            const Textf('This is ++underlined++ text.'),

            // Highlight: Use ==
            const Textf('This is ==highlighted== text.'),

            // Inline code: Use `
            const Textf('Run `flutter pub get` to install.'),

            // Combined in one line
            const Textf(
              '**Bold**, *italic*, ~~strike~~, ++underline++, ==highlight==, `code`.',
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 2: Superscript & Subscript
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('2. Superscript & Subscript'),

            // Superscript: Use ^
            const Textf('Einstein: E = mc^2^'),
            const Textf('Footnote reference^1^'),
            const Textf('x^2^ + y^2^ = z^2^'),

            // Subscript: Use ~
            const Textf('Water: H~2~O'),
            const Textf('Carbon dioxide: CO~2~'),
            const Textf('Glucose: C~6~H~12~O~6~'),

            // Combined with other formatting
            const Textf('The **first** derivative: f^*prime*^(x)'),
            const Textf('*Important*: H~2~O is **essential**'),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 3: Links
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('3. Links'),

            // Basic link syntax: [display text](url)
            const Textf('Visit [Flutter](https://flutter.dev) for docs.'),

            // URL auto-normalization (adds https:// if missing)
            const Textf('Check out [example.com](example.com).'),

            // Formatting inside links
            const Textf(
              'Read the [**official** docs](https://docs.flutter.dev).',
            ),
            const Textf(
              'See the [*getting started* guide](https://flutter.dev/start).',
            ),
            const Textf('View [~~old~~ **new** API](https://api.flutter.dev).'),

            // Multiple links in one text
            const Textf(
              'Learn [Dart](https://dart.dev) and [Flutter](https://flutter.dev).',
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 4: Interactive Links with Callbacks
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('4. Interactive Links'),

            // Wrap with TextfOptions to handle taps
            TextfOptions(
              onLinkTap: (url, displayText) {
                // url: The resolved URL (e.g., 'https://flutter.dev')
                // displayText: The raw text between [] (e.g., 'Flutter')
                debugPrint('Tapped: $url (text: $displayText)');
                // launchUrl(Uri.parse(url)); // Uncomment with url_launcher
              },
              onLinkHover: (url, displayText, {required isHovering}) {
                // isHovering: true on mouse enter, false on mouse exit
                debugPrint('Hover $url: $isHovering');
              },
              child: const Textf(
                'Click [this link](https://flutter.dev) to test.',
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 5: Placeholders for InlineSpans
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('5. Placeholders for InlineSpans'),

            const Textf(
              'Press the {0} button to add a {1}.',
              inlineSpans: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.add_circle, color: Colors.blue),
                ),
                // Icon of a user
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.person, color: Colors.green),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 6: Escaped Characters
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('6. Escaped Characters'),

            // Use backslash to escape formatting characters
            // Note: Use raw strings (r'...') for cleaner escape syntax
            const Textf(r'Literal asterisks: \*not bold\*'),
            const Textf(r'Literal underscores: \_not italic\_'),
            const Textf(r'Literal tildes: \~\~not strikethrough\~\~'),
            const Textf(r'Literal backtick: \`not code\`'),
            const Textf(r'Literal backslash: \\'),
            const Textf(r'Star rating: \*\*\*\*\* (5 stars)'),

            // Escaping in links
            const Textf(r'Link with \[brackets\] in text'),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 7: Nested Formatting
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('7. Nested Formatting'),

            // Use different marker types for nesting (** with _ works best)
            const Textf('**Bold with _nested italic_ inside.**'),
            const Textf('_Italic with **nested bold** inside._'),
            const Textf('**Bold with `code` inside.**'),
            const Textf('==Highlighted with **bold** inside.=='),

            // Maximum nesting depth is 2 levels
            // Third level becomes plain text (by design)
            const Textf('**Level 1 _Level 2_ back to 1.**'),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 8: Custom Styling with TextfOptions
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('8. Custom Styling'),

            // Override individual format styles
            TextfOptions(
              boldStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.deepOrange,
              ),
              italicStyle: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.purple,
              ),
              strikethroughStyle: const TextStyle(
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.red,
                decorationThickness: 2,
                color: Colors.grey,
              ),
              underlineStyle: const TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
                decorationStyle: TextDecorationStyle.wavy,
              ),
              highlightStyle: TextStyle(
                backgroundColor: Colors.yellow.shade200,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              codeStyle: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade200,
                color: Colors.pink.shade700,
              ),
              child: const Textf(
                '**Bold** *italic* ~~strike~~ ++underline++ ==highlight== `code`',
              ),
            ),

            const SizedBox(height: 16),

            // Custom link styling
            TextfOptions(
              linkStyle: const TextStyle(
                color: Colors.teal,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w600,
              ),
              linkHoverStyle: const TextStyle(
                color: Colors.teal,
                decoration: TextDecoration.underline,
              ),
              linkMouseCursor: SystemMouseCursors.click,
              onLinkTap: (url, _) => debugPrint('Link tapped: $url'),
              child: const Textf('Custom styled [link](https://example.com).'),
            ),

            const SizedBox(height: 16),

            // Custom superscript/subscript styling
            const TextfOptions(
              superscriptStyle: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              subscriptStyle: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              // Adjust size factor (default: 0.6)
              scriptFontSizeFactor: 0.7,
              // Adjust baseline offset (default: 0.4)
              superscriptBaselineFactor: 0.5,
              subscriptBaselineFactor: 0.3,
              child: Textf('Custom: E = mc^2^ and H~2~O'),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 9: Style Inheritance & Nesting
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('9. Style Inheritance'),

            // Parent TextfOptions
            TextfOptions(
              boldStyle: const TextStyle(color: Colors.red),
              italicStyle: const TextStyle(color: Colors.blue),
              onLinkTap: (url, _) => debugPrint('Parent handler: $url'),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inherits red bold and blue italic from parent
                  Textf('**Red bold** and *blue italic* from parent.'),

                  SizedBox(height: 8),

                  // Child overrides only bold, inherits italic from parent
                  TextfOptions(
                    boldStyle: TextStyle(color: Colors.green),
                    child: Textf(
                      '**Green bold** (override) and *blue italic* (inherited).',
                    ),
                  ),

                  SizedBox(height: 8),

                  // Styles MERGE: parent color + child weight
                  TextfOptions(
                    boldStyle: TextStyle(fontWeight: FontWeight.w900),
                    // Color inherited from parent, weight from child
                    child: Textf('**Red + extra bold** (merged styles).'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 10: Theme Integration
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('10. Theme Integration'),

            // Textf automatically uses theme colors
            // Links: colorScheme.primary
            // Code background: colorScheme.surfaceContainer
            // Code text: colorScheme.onSurfaceVariant
            const Textf(
              'Links use [theme primary](https://example.com) automatically.',
            ),
            const Textf('Code uses `theme surface` colors automatically.'),

            const SizedBox(height: 16),

            // Theme-aware custom styling
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return TextfOptions(
                  highlightStyle: TextStyle(
                    backgroundColor: isDark //
                        ? Colors.yellow.shade700.withAlpha(30)
                        : Colors.yellow.shade200,
                  ),
                  child: const Textf(
                    '==Theme-aware== highlight adapts to dark mode.',
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 11: Text Widget Properties
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('11. Text Widget Properties'),

            // All standard Text properties work
            const Textf(
              'All **standard** Text properties work: style, textAlign, '
              'maxLines, overflow, softWrap, textScaler, locale, '
              'textDirection, semanticsLabel, strutStyle, and more.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 8),

            // Example with multiple properties
            const Textf(
              'This **long text** demonstrates *maxLines* and overflow. '
              'It will be truncated with an ellipsis because maxLines is set to 2. '
              'Additional content is cut off gracefully.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // TextScaler for accessibility
            const Textf(
              '**Scaled** text for accessibility.',
              textScaler: TextScaler.linear(1.5),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 12: Error Handling
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('12. Error Handling'),

            // Unclosed markers become plain text
            const Textf('**Unclosed bold marker'),
            const Textf('Unclosed italic marker*'),
            const Textf('*Mismatched **markers*'),

            // Empty content is handled
            const Textf('[](https://example.com)'), // Empty link text
            const Textf('****'), // Empty bold
            const Textf(''), // Empty string
            // Malformed links become plain text
            const Textf('[No closing paren](https://example.com'),
            const Textf('[Missing URL]()'),

            // App never crashes from malformed input
            const Textf('Malformed input renders **safely**, no crashes.'),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────────
            // SECTION: Highlight Comparison (add after Section 6 or wherever fits)
            // ─────────────────────────────────────────────────────────────────
            const Textf('**Highlight Styling Comparison**'),
            const SizedBox(height: 8),

            // Default highlight: Uses theme-aware yellow background
            const Textf('This is ==highlighted== with default styling.'),

            const SizedBox(height: 8),

            // Custom highlight:  Soft blue
            TextfOptions(
              highlightStyle: TextStyle(
                backgroundColor: Colors.blue.shade50,
                color: Colors.blue.shade900,
              ),
              child: const Textf('==Soft blue== highlight.'),
            ),

            // Warm orange
            TextfOptions(
              highlightStyle: TextStyle(
                backgroundColor: Colors.orange.shade100,
                color: Colors.orange.shade900,
              ),
              child: const Textf('==Warm orange== highlight.'),
            ),

            // Bold highlight with extra styling
            TextfOptions(
              highlightStyle: TextStyle(
                backgroundColor: Colors.lightGreen.shade100,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
              ),
              child: const Textf('==Bold green== highlight with extra weight.'),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────
            // SECTION 13: Real-World Examples
            // ─────────────────────────────────────────────────────────────
            _sectionHeader('13. Real-World Examples'),

            // Chat message
            _exampleCard(
              'Chat Message',
              const Textf(
                'I **really** enjoyed the movie! 🎬 '
                'Check out the [trailer](https://example.com/trailer).',
              ),
            ),

            // Help tooltip
            _exampleCard(
              'Help Tooltip',
              const Textf(
                'Press **Ctrl+S** to save. '
                'Files are stored in `~/Documents`. '
                'See [shortcuts](https://example.com/help).',
              ),
            ),

            // Product description
            _exampleCard(
              'Product Card',
              const Textf(
                '**Wireless Headphones**\n'
                '==50% OFF== — Now *only* \$49^99^\n'
                '[View details](https://example.com/product)',
              ),
            ),

            // Scientific content
            _exampleCard(
              'Scientific Text',
              const Textf(
                'The equation E = mc^2^ shows mass-energy equivalence. '
                'Water (H~2~O) and carbon dioxide (CO~2~) are essential molecules.',
              ),
            ),

            // i18n example
            _exampleCard(
              'Internationalization',
              const Textf(
                // Imagine this comes from an .arb translation file
                'Bienvenue sur **Flutter**, la façon *élégante* de créer des apps!',
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Helper Widgets
  // ───────────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _exampleCard(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextfOptions(
              onLinkTap: (url, _) => debugPrint('Example link: $url'),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
