import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';
import 'package:textf_bare/main.dart';

void main() {
  group('bare WidgetsApp host', () {
    testWidgets('renders every construct without a Theme and without errors', (tester) async {
      await tester.pumpWidget(const TextfBareApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(demoTextfKey), findsOneWidget);
      // The app's own typography reaches textf through DefaultTextStyle.
      final bold = _spanStyle(tester, 'bold');
      expect(bold.fontSize, bareFontSize);
      expect(bold.color, lightInk);
    });

    testWidgets('color options apply and neutral defaults follow the ambient text color', (
      tester,
    ) async {
      await tester.pumpWidget(const TextfBareApp());
      await tester.pumpAndSettle();

      final link = _spanStyle(tester, 'a link');
      expect(link.color, brandColor);
      expect(link.decoration, TextDecoration.underline);
      // No codeBackgroundColor is set: the chip is the text color at the light-surface alpha.
      expect(_spanStyle(tester, 'inline code').backgroundColor, lightInk.withValues(alpha: 0.05));

      await tester.tap(find.byKey(darkModeToggleKey));
      await tester.pumpAndSettle();

      expect(_spanStyle(tester, 'a link').color, brandColor);
      // Light text means a dark surface: textf infers it from DefaultTextStyle alone.
      expect(_spanStyle(tester, 'inline code').backgroundColor, darkInk.withValues(alpha: 0.15));
    });
  });

  test('lib/ imports no design system', () {
    final imports = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand((file) => file.readAsLinesSync())
        .where((line) => line.startsWith('import ') || line.startsWith('export '));
    for (final line in imports) {
      expect(
        line,
        anyOf(
          contains("'dart:"),
          contains('package:flutter/widgets.dart'),
          contains('package:textf/'),
        ),
        reason: 'textf_bare must stay on the widgets layer',
      );
    }
  });
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
