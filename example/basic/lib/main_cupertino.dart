// Run with: flutter run -t lib/main_cupertino.dart
import 'package:cupertino_ui/cupertino_ui.dart'; // SDK Cupertino: 'package:flutter/cupertino.dart'
import 'package:textf/textf.dart';

void main() => runApp(const CupertinoRecipeApp());

/// The Cupertino recipe from `example/README.md`: theme colors passed down once in `builder`.
class CupertinoRecipeApp extends StatefulWidget {
  const new({super.key});

  @override
  State<CupertinoRecipeApp> createState() => _CupertinoRecipeAppState();
}

class _CupertinoRecipeAppState extends State<CupertinoRecipeApp> {
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: _brightness,
        primaryColor: CupertinoColors.systemIndigo,
      ),
      builder: (context, child) {
        return TextfOptions(
          linkColor: CupertinoTheme.of(context).primaryColor,
          codeBackgroundColor: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          thematicBreakColor: CupertinoColors.separator.resolveFrom(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomePage(
        isDark: _brightness == Brightness.dark,
        onDarkChanged: (isDark) => setState(() {
          _brightness = isDark ? Brightness.dark : Brightness.light;
        }),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const new({required this.isDark, required this.onDarkChanged, super.key});

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Textf + cupertino_ui'),
        trailing: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
      ),
      child: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Textf(_demo),
        ),
      ),
    );
  }
}

const String _demo = '''
# Theme colors

A [link](https://example.com), some `inline code` and a ==highlight==.

---

**Bold**, *italic* and ~~strikethrough~~ keep their defaults.''';
