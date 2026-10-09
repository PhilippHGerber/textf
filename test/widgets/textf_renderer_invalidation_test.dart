// ignore_for_file: no-magic-number, no-empty-block

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

// Helper to extract the TextStyle of a specific text span
TextStyle? _getStyleForText(WidgetTester tester, String textToFind) {
  final richTextFinder = find.byType(RichText);
  final richText = tester.widget<RichText>(richTextFinder.first);
  final rootSpan = richText.text as TextSpan;

  TextStyle? foundStyle;
  rootSpan.visitChildren((span) {
    if (span is TextSpan && span.text == textToFind) {
      foundStyle = span.style;
      return false; // Stop visiting
    }
    return true;
  });
  return foundStyle;
}

void main() {
  group('TextfRenderer Cache Invalidation Tests', () {
    testWidgets('Updates visual style when TextfOptions boldStyle changes', (tester) async {
      // 1. Initial State: Bold is RED
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            boldStyle: TextStyle(color: Color(0xFFF44336)),
            child: Textf('**BoldText**'),
          ),
        ),
      );

      final style1 = _getStyleForText(tester, 'BoldText');
      expect(style1?.color, const Color(0xFFF44336), reason: 'Initial bold color should be red');

      // 2. Update State: Bold is BLUE
      // This forces the TextfRenderer to compare the new Options with the cached ones.
      // If hasSameStyle() works correctly, this will trigger a re-parse.
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            boldStyle: TextStyle(color: Color(0xFF2196F3)),
            child: Textf('**BoldText**'),
          ),
        ),
      );

      final style2 = _getStyleForText(tester, 'BoldText');
      expect(style2?.color, const Color(0xFF2196F3), reason: 'Bold color should update to blue');
    });

    // T-COLOPT-01 × cache: an app switching light -> dark passes a new `linkColor` through
    // TextfOptions (the adapter recipe); the changed option must invalidate the cached spans.
    testWidgets('Updates link color when the linkColor option changes (light -> dark)', (
      tester,
    ) async {
      Color? getLinkColor() {
        final hoverableFinder = find.byType(HoverableLinkSpan);
        if (hoverableFinder.evaluate().isEmpty) return null;
        final widget = tester.widget<HoverableLinkSpan>(hoverableFinder);
        return widget.normalStyle.color;
      }

      const lightBrand = Color(0xFF6750A4);
      const darkBrand = Color(0xFFD0BCFF);

      // 1. Initial State: the light-mode brand color
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            linkColor: lightBrand,
            child: Textf('[Link](https://example.com)'),
          ),
        ),
      );
      final lightLinkColor = getLinkColor();

      // 2. Update State: the dark-mode brand color
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            linkColor: darkBrand,
            child: Textf('[Link](https://example.com)'),
          ),
        ),
      );
      final darkLinkColor = getLinkColor();

      expect(lightLinkColor, lightBrand, reason: 'Light link should use the light brand color');
      expect(darkLinkColor, darkBrand, reason: 'Link color should follow the changed option');
    });

    testWidgets('Re-resolves heading spans when the base style changes (no stale cache)', (
      tester,
    ) async {
      // 1. Initial base font size 10 -> H1 is 20.
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf('# Title', style: TextStyle(fontSize: 10)),
        ),
      );

      final size1 = _getStyleForText(tester, 'Title')?.fontSize;
      expect(size1, 20.0, reason: 'H1 scales 2x off the base size (10)');

      // 2. Change base font size to 40 -> H1 must re-resolve to 80.
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf('# Title', style: TextStyle(fontSize: 40)),
        ),
      );

      final size2 = _getStyleForText(tester, 'Title')?.fontSize;
      expect(
        size2,
        80.0,
        reason: 'H1 must re-resolve against the new base, not serve a stale span',
      );
    });

    testWidgets('Updates heading style when TextfOptions h1Style changes', (tester) async {
      // 1. Initial: h1Style color RED.
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            h1Style: TextStyle(color: Color(0xFFF44336)),
            child: Textf('# Title'),
          ),
        ),
      );

      final style1 = _getStyleForText(tester, 'Title');
      expect(style1?.color, const Color(0xFFF44336), reason: 'Initial heading color should be red');
      // Color-only override still inherits the default (bold-ish) heading weight.
      expect(style1?.fontWeight?.value ?? 0, greaterThanOrEqualTo(FontWeight.bold.value));

      // 2. Update: h1Style color BLUE -> must re-parse.
      await tester.pumpWidget(
        neutralTestApp(
          child: const TextfOptions(
            h1Style: TextStyle(color: Color(0xFF2196F3)),
            child: Textf('# Title'),
          ),
        ),
      );

      final style2 = _getStyleForText(tester, 'Title');
      expect(style2?.color, const Color(0xFF2196F3), reason: 'Heading color should update to blue');
    });

    testWidgets('Updates when Placeholders content changes', (tester) async {
      // 1. Initial State: {icon} is Star
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf(
            'Hello {icon}',
            placeholders: {
              'icon': WidgetSpan(child: SizedBox(key: Key('star'), width: 8, height: 8)),
            },
          ),
        ),
      );

      expect(find.byKey(const Key('star')), findsOneWidget);

      // 2. Update State: {icon} is Heart
      // Renderer uses mapEquals. Since content changed, it must re-parse.
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf(
            'Hello {icon}',
            placeholders: {
              'icon': WidgetSpan(child: SizedBox(key: Key('heart'), width: 8, height: 8)),
            },
          ),
        ),
      );

      expect(find.byKey(const Key('heart')), findsOneWidget);
    });

    testWidgets('Invalidates cache when TextfOptions.linkAlignment changes', (tester) async {
      // Helper to find the WidgetSpan and extract its alignment
      PlaceholderAlignment? getLinkAlignment() {
        final richTextFinder = find.byType(RichText);
        if (richTextFinder.evaluate().isEmpty) return null;

        final richText = tester.widget<RichText>(richTextFinder.first);
        final rootSpan = richText.text as TextSpan;

        PlaceholderAlignment? foundAlignment;
        rootSpan.visitChildren((span) {
          if (span is WidgetSpan) {
            foundAlignment = span.alignment;
            return false; // Stop visiting
          }
          return true;
        });
        return foundAlignment;
      }

      // 1. Initial State: linkAlignment is baseline (default)
      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            linkAlignment: PlaceholderAlignment.baseline,
            onLinkTap: (_, _) {}, // Enable link rendering
            child: const Textf('[Link](https://example.com)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignment1 = getLinkAlignment();
      expect(
        alignment1,
        PlaceholderAlignment.baseline,
        reason: 'Initial alignment should be baseline',
      );

      // 2. Update State: linkAlignment changes to middle
      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            linkAlignment: PlaceholderAlignment.middle,
            onLinkTap: (_, _) {},
            child: const Textf('[Link](https://example.com)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignment2 = getLinkAlignment();
      expect(alignment2, PlaceholderAlignment.middle, reason: 'Alignment should update to middle');
      expect(alignment1, isNot(alignment2), reason: 'Alignment should have changed');
    });
  });
}
