import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';
import 'package:textf_flex/home_screen.dart';
import 'package:textf_flex/main.dart';

/// textf's own neutral link default. The recipe must replace it with the brand color.
const Color _neutralLinkBlue = Color(0xFF1A73E8);

/// These tests also cover the `material_ui` host of T-ENV-01, which the root package cannot test
/// because `material_ui` must not become one of its dependencies (ADR 0004).
void main() {
  group('T-MIG-01: TextfOptions adapter recipe in MaterialApp.builder', () {
    testWidgets('brand colors render and follow light -> dark -> light theme-mode switches', (
      tester,
    ) async {
      await tester.pumpWidget(const FlexTextfExampleApp());
      await tester.pumpAndSettle();

      final light = _activeTheme(tester);
      expect(light.brightness, Brightness.light);
      _expectBrandColors(tester, light);
      expect(_spanStyle(tester, 'brand link').color, isNot(_neutralLinkBlue));

      await tester.tap(find.byTooltip('Switch to Dark Mode'));
      await tester.pumpAndSettle();

      final dark = _activeTheme(tester);
      expect(dark.brightness, Brightness.dark);
      // The switch only proves something if the brand colors actually differ per mode.
      expect(dark.colorScheme.primary, isNot(light.colorScheme.primary));
      expect(dark.colorScheme.surfaceContainer, isNot(light.colorScheme.surfaceContainer));
      expect(dark.colorScheme.tertiaryContainer, isNot(light.colorScheme.tertiaryContainer));
      expect(dark.dividerColor, isNot(light.dividerColor));
      _expectBrandColors(tester, dark);

      // dark -> system (the test platform is light) -> light.
      await tester.tap(find.byTooltip('Switch to System Mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to Light Mode'));
      await tester.pumpAndSettle();

      _expectBrandColors(tester, _activeTheme(tester));
      expect(_spanStyle(tester, 'brand link').color, light.colorScheme.primary);
    });

    testWidgets('color options keep the built-in typography and decorations', (tester) async {
      await tester.pumpWidget(const FlexTextfExampleApp());
      await tester.pumpAndSettle();

      final link = _spanStyle(tester, 'brand link');
      expect(link.decoration, TextDecoration.underline);
      expect(link.decorationColor, _activeTheme(tester).colorScheme.primary);

      final code = _spanStyle(tester, 'brand code');
      expect(code.fontFamily, 'monospace');
      expect(code.fontFamilyFallback, isNotEmpty);
    });
  });
}

/// The `material_ui` theme that `MaterialApp` currently exposes to the app's content.
ThemeData _activeTheme(WidgetTester tester) => Theme.of(tester.element(find.byType(HomeScreen)));

void _expectBrandColors(WidgetTester tester, ThemeData theme) {
  final scheme = theme.colorScheme;
  expect(_spanStyle(tester, 'brand link').color, scheme.primary, reason: 'linkColor');
  expect(
    _spanStyle(tester, 'brand code').backgroundColor,
    scheme.surfaceContainer,
    reason: 'codeBackgroundColor',
  );
  expect(
    _spanStyle(tester, 'brand highlight').backgroundColor,
    scheme.tertiaryContainer,
    reason: 'highlightColor',
  );
  final rule = find.descendant(
    of: find.byKey(brandColorsTextfKey),
    matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == theme.dividerColor),
  );
  expect(rule, findsOneWidget, reason: 'thematicBreakColor');
}

/// The style of the rendered [TextSpan] whose trimmed text is [text], searched below the
/// brand-colors [Textf].
TextStyle _spanStyle(WidgetTester tester, String text) {
  TextStyle? found;
  final richTexts = find.descendant(
    of: find.byKey(brandColorsTextfKey),
    matching: find.byType(RichText),
  );
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
