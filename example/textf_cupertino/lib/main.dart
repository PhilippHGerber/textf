import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:textf/textf.dart';

import 'demo_content.dart';

void main() {
  runApp(const TextfCupertinoApp());
}

/// A Cupertino app on `package:cupertino_ui` that hands its theme colors to `textf`.
class TextfCupertinoApp extends StatefulWidget {
  const new({super.key});

  @override
  State<TextfCupertinoApp> createState() => _TextfCupertinoAppState();
}

class _TextfCupertinoAppState extends State<TextfCupertinoApp> {
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf + cupertino_ui',
      theme: CupertinoThemeData(
        brightness: _brightness,
        primaryColor: CupertinoColors.systemIndigo,
      ),
      // The adapter recipe: textf never reads `CupertinoTheme`, so the app passes its colors to
      // every descendant `Textf` once. `builder` runs below the theme, so `resolveFrom` picks the
      // light or dark variant and the colors follow brightness changes.
      builder: (context, child) {
        return TextfOptions(
          linkColor: CupertinoTheme.of(context).primaryColor,
          codeBackgroundColor: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          highlightColor: CupertinoColors.systemYellow
              .resolveFrom(context)
              .withValues(alpha: highlightAlpha),
          thematicBreakColor: CupertinoColors.separator.resolveFrom(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _DemoPage(
        isDark: _brightness == Brightness.dark,
        onDarkChanged: (isDark) => setState(() {
          _brightness = isDark ? Brightness.dark : Brightness.light;
        }),
      ),
    );
  }
}

class _DemoPage extends StatefulWidget {
  const new({required this.isDark, required this.onDarkChanged});

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final TextfEditingController _controller = TextfEditingController(
    text: 'Type **bold**, *italic* or `code` here',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Textf + Cupertino'),
        trailing: Semantics(
          label: 'Dark mode',
          child: CupertinoSwitch(value: widget.isDark, onChanged: widget.onDarkChanged),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Textf(demoMarkdown, key: demoTextfKey),
            const SizedBox(height: 24),
            // TextfEditingController is a plain TextEditingController, so it works in any
            // EditableText-based field, CupertinoTextField included.
            CupertinoTextField(controller: _controller, maxLines: null),
          ],
        ),
      ),
    );
  }
}
