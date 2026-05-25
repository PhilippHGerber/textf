import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const _ManualDebugFillPropertiesApp());
}

class _ManualDebugFillPropertiesApp extends StatelessWidget {
  const _ManualDebugFillPropertiesApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textf Diagnostics Manual Check',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _ManualDebugFillPropertiesScreen(),
    );
  }
}

class _ManualDebugFillPropertiesScreen extends StatelessWidget {
  const _ManualDebugFillPropertiesScreen();

  static void _onLinkTap(String url, String displayText) {
    debugPrint('Tapped: $url ($displayText)');
  }

  static void _onLinkHover(
    String url,
    String displayText, {
    required bool isHovering,
  }) {
    debugPrint('Hover: $url ($displayText), isHovering: $isHovering');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Inspector Check'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Inspect the widgets below in Flutter Widget Inspector.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            '1) Select TextfOptions and verify callback presence + style options.\n'
            '2) Select Textf and verify text/render properties and placeholders.',
          ),
          const SizedBox(height: 24),
          const TextfOptions(
            onLinkTap: _onLinkTap,
            onLinkHover: _onLinkHover,
            linkMouseCursor: SystemMouseCursors.click,
            linkAlignment: PlaceholderAlignment.middle,
            boldStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            italicStyle: TextStyle(fontStyle: FontStyle.italic),
            boldItalicStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
            strikethroughStyle: TextStyle(
              decoration: TextDecoration.lineThrough,
            ),
            codeStyle: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Color(0xFFEDEDED),
            ),
            underlineStyle: TextStyle(decoration: TextDecoration.underline),
            highlightStyle: TextStyle(backgroundColor: Color(0xFFFFFF99)),
            superscriptStyle: TextStyle(fontSize: 10),
            subscriptStyle: TextStyle(fontSize: 10),
            linkStyle: TextStyle(color: Colors.blue),
            linkHoverStyle: TextStyle(
              color: Colors.lightBlue,
              decoration: TextDecoration.underline,
            ),
            scriptFontSizeFactor: 0.7,
            superscriptBaselineFactor: 0.35,
            subscriptBaselineFactor: 0.25,
            strikethroughThickness: 1.5,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Textf(
                  'Inspect **Textf** with [link](flutter.dev), H~2~O, and x^2^ {dot}',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  textScaler: TextScaler.linear(1.1),
                  semanticsLabel: 'Manual diagnostics sample',
                  locale: Locale('en', 'US'),
                  strutStyle: StrutStyle(fontSize: 16),
                  textWidthBasis: TextWidthBasis.parent,
                  textHeightBehavior: TextHeightBehavior(),
                  selectionColor: Colors.amber,
                  placeholders: {
                    'dot': WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.teal,
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
