import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/cupertino.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';
import 'package:textf_cupertino/demo_content.dart';
import 'package:textf_cupertino/main.dart';
import 'package:textf_cupertino/sdk_cupertino_textf_app.dart';

void main() {
  group('T-ENV-01 (cupertino_ui host, lib/main.dart)', () {
    testWidgets('renders every construct and the editing field without errors', (tester) async {
      await tester.pumpWidget(const TextfCupertinoApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(demoTextfKey), findsOneWidget);
      final field = tester.widget<CupertinoTextField>(find.byType(CupertinoTextField));
      expect(field.controller, isA<TextfEditingController>());
    });

    testWidgets('the recipe applies CupertinoTheme colors and follows a brightness switch', (
      tester,
    ) async {
      await tester.pumpWidget(const TextfCupertinoApp());
      await tester.pumpAndSettle();

      final light = _expectedColors(Brightness.light);
      final dark = _expectedColors(Brightness.dark);
      // The switch only proves something if the colors actually differ per brightness.
      expect(dark.primary, isNot(isSameColorAs(light.primary)));
      expect(dark.codeBackground, isNot(isSameColorAs(light.codeBackground)));
      expect(dark.highlight, isNot(isSameColorAs(light.highlight)));
      expect(dark.separator, isNot(isSameColorAs(light.separator)));

      _expectRecipeColors(tester, light);

      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      _expectRecipeColors(tester, dark);
    });
  });

  group('T-ENV-01 (SDK Cupertino host, lib/sdk_cupertino_textf_app.dart)', () {
    for (final brightness in Brightness.values) {
      testWidgets('the same recipe gives the same colors ($brightness)', (tester) async {
        await tester.pumpWidget(SdkCupertinoTextfApp(brightness: brightness));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Colors resolved by package:cupertino_ui ...
        final expected = _expectedColors(brightness);
        _expectRecipeColors(tester, expected);
        // ... equal the ones SDK Cupertino resolves, so the recipe is portable between them.
        expect(
          expected.primary,
          isSameColorAs(_sdkResolved(sdk.CupertinoColors.systemIndigo, brightness)),
        );
        expect(
          expected.codeBackground,
          isSameColorAs(_sdkResolved(sdk.CupertinoColors.tertiarySystemFill, brightness)),
        );
        expect(
          expected.separator,
          isSameColorAs(_sdkResolved(sdk.CupertinoColors.separator, brightness)),
        );
      });
    }
  });
}

/// The colors the recipe should produce.
typedef _RecipeColors = ({Color primary, Color codeBackground, Color highlight, Color separator});

/// The colors the recipe should produce for [brightness], resolved with `package:cupertino_ui`.
_RecipeColors _expectedColors(Brightness brightness) {
  Color resolve(CupertinoDynamicColor color) =>
      brightness == Brightness.light ? color.color : color.darkColor;
  return (
    primary: resolve(CupertinoColors.systemIndigo),
    codeBackground: resolve(CupertinoColors.tertiarySystemFill),
    highlight: resolve(CupertinoColors.systemYellow).withValues(alpha: highlightAlpha),
    separator: resolve(CupertinoColors.separator),
  );
}

Color _sdkResolved(sdk.CupertinoDynamicColor color, Brightness brightness) =>
    brightness == Brightness.light ? color.color : color.darkColor;

void _expectRecipeColors(WidgetTester tester, _RecipeColors expected) {
  final link = _spanStyle(tester, 'a link');
  expect(link.color, isSameColorAs(expected.primary), reason: 'linkColor');
  expect(link.decoration, TextDecoration.underline, reason: 'link keeps its underline');
  final code = _spanStyle(tester, 'inline code');
  expect(
    code.backgroundColor,
    isSameColorAs(expected.codeBackground),
    reason: 'codeBackgroundColor',
  );
  expect(code.fontFamily, 'monospace', reason: 'code keeps its monospace font');
  expect(
    _spanStyle(tester, 'a highlight').backgroundColor,
    isSameColorAs(expected.highlight),
    reason: 'highlightColor',
  );
  final rule = find.descendant(
    of: find.byKey(demoTextfKey),
    matching: find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color.toARGB32() == expected.separator.toARGB32(),
    ),
  );
  expect(rule, findsOneWidget, reason: 'thematicBreakColor');
}

/// The style of the rendered [TextSpan] whose trimmed text is [text], searched below the demo
/// [Textf].
TextStyle _spanStyle(WidgetTester tester, String text) {
  TextStyle? found;
  final richTexts = find.descendant(of: find.byKey(demoTextfKey), matching: find.byType(RichText));
  for (final richText in tester.widgetList<RichText>(richTexts)) {
    richText.text.visitChildren((span) {
      if (span is TextSpan && span.text?.trim() == text) {
        found = span.style;
        return false;
      }
      return true;
    });
    if (found != null) break;
  }
  expect(found, isNotNull, reason: 'No rendered TextSpan with text "$text"');
  return found ?? const TextStyle();
}
