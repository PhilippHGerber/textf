import 'package:flutter/widgets.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const TextfBareApp());
}

/// Key of the demo [Textf].
const Key demoTextfKey = ValueKey<String>('demo-textf');

/// Key of the light/dark toggle.
const Key darkModeToggleKey = ValueKey<String>('dark-mode-toggle');

/// The app's brand color, handed to textf as `linkColor`.
const Color brandColor = Color(0xFF00796B);

/// Text color on the light background.
const Color lightInk = Color(0xFF1B1B1F);

/// Text color on the dark background.
const Color darkInk = Color(0xFFE4E1E6);

/// The app's body font size.
const double bareFontSize = 17;

const double _lineHeight = 1.5;

const Color _lightPaper = Color(0xFFFFFBFE);
const Color _darkPaper = Color(0xFF1B1B1F);

const String _demoMarkdown = '''
# Textf without a design system
This app is a bare `WidgetsApp`: no Material, no Cupertino, no `Theme`.
**bold**, *italic*, ~~strike~~, ++underline++, ==highlight==, H~2~O and x^2^ all work.
Here is [a link](https://pub.dev/packages/textf) in the brand color and some `inline code`.
---
Code chips and the rule above take their color from the ambient text color, so they adapt when you switch to dark mode.''';

/// A textf demo on the widgets layer only.
class TextfBareApp extends StatefulWidget {
  const new({super.key});

  @override
  State<TextfBareApp> createState() => _TextfBareAppState();
}

class _TextfBareAppState extends State<TextfBareApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    final Color ink = _isDark ? darkInk : lightInk;
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf bare',
      color: brandColor,
      // Without a design system, the app's typography is just a DefaultTextStyle. Every Textf
      // below derives its defaults (code chip, highlight, rule) from this style.
      textStyle: TextStyle(fontSize: bareFontSize, height: _lineHeight, color: ink),
      builder: (context, _) {
        // Only the brand link color is set. Everything else uses textf's neutral defaults.
        return TextfOptions(
          linkColor: brandColor,
          child: ColoredBox(
            color: _isDark ? _darkPaper : _lightPaper,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Textf(_demoMarkdown, key: demoTextfKey),
                  const SizedBox(height: 24),
                  _Toggle(
                    isDark: _isDark,
                    onTap: () => setState(() => _isDark = !_isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const new({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        key: darkModeToggleKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Textf(
          '**Dark mode:** ${isDark ? 'on' : 'off'} (tap to switch)',
        ),
      ),
    );
  }
}
