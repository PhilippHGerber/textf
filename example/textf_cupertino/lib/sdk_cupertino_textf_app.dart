// The same recipe as `main.dart`, on the SDK's `package:flutter/cupertino.dart` instead of
// `package:cupertino_ui`. Run it with `flutter run -t lib/sdk_cupertino_textf_app.dart`.
import 'package:flutter/cupertino.dart';
import 'package:textf/textf.dart';

import 'demo_content.dart';

void main() {
  runApp(const SdkCupertinoTextfApp());
}

/// A minimal SDK Cupertino app using the same `TextfOptions` recipe as `TextfCupertinoApp`.
class SdkCupertinoTextfApp extends StatelessWidget {
  const new({this.brightness = Brightness.light, super.key});

  /// The theme brightness.
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf + SDK Cupertino',
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: CupertinoColors.systemIndigo,
      ),
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
      home: const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Textf + SDK Cupertino')),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Textf(demoMarkdown, key: demoTextfKey),
          ),
        ),
      ),
    );
  }
}
