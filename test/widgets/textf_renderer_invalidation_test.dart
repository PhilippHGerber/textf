// ignore_for_file: no-magic-number, no-empty-block

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/textf.dart';

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
        const MaterialApp(
          home: TextfOptions(
            boldStyle: TextStyle(color: Colors.red),
            child: Textf('**BoldText**'),
          ),
        ),
      );

      final style1 = _getStyleForText(tester, 'BoldText');
      expect(style1?.color, Colors.red, reason: 'Initial bold color should be red');

      // 2. Update State: Bold is BLUE
      // This forces the TextfRenderer to compare the new Options with the cached ones.
      // If hasSameStyle() works correctly, this will trigger a re-parse.
      await tester.pumpWidget(
        const MaterialApp(
          home: TextfOptions(
            boldStyle: TextStyle(color: Colors.blue),
            child: Textf('**BoldText**'),
          ),
        ),
      );

      final style2 = _getStyleForText(tester, 'BoldText');
      expect(style2?.color, Colors.blue, reason: 'Bold color should update to blue');
    });

    testWidgets('Updates visual style when Theme changes (Light -> Dark)', (tester) async {
      Color? getLinkColor() {
        final hoverableFinder = find.byType(HoverableLinkSpan);
        if (hoverableFinder.evaluate().isEmpty) return null;
        final widget = tester.widget<HoverableLinkSpan>(hoverableFinder);
        return widget.normalStyle.color;
      }

      // 1. Initial State: Light Theme
      final lightTheme = ThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: const Textf('[Link](https://example.com)'),
        ),
      );

      // waits until all animations and rebuilds complete.
      await tester.pumpAndSettle();

      final lightLinkColor = getLinkColor();

      // 2. Update State: Dark Theme
      final darkTheme = ThemeData.dark();
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: const Textf('[Link](https://example.com)'),
        ),
      );
      await tester.pumpAndSettle(); // <-- Add this

      final darkLinkColor = getLinkColor();

      // Verify
      expect(lightLinkColor, isNotNull);
      expect(darkLinkColor, isNotNull);
      expect(
        lightLinkColor,
        lightTheme.colorScheme.primary,
        reason: 'Light theme link should use primary color',
      );
      expect(
        darkLinkColor,
        darkTheme.colorScheme.primary,
        reason: 'Dark theme link should use primary color',
      );
      expect(
        lightLinkColor,
        isNot(darkLinkColor),
        reason: 'Link color should change when theme changes',
      );
    });

    testWidgets('Updates when Placeholders content changes', (tester) async {
      // 1. Initial State: {icon} is Star
      await tester.pumpWidget(
        const MaterialApp(
          home: Textf(
            'Hello {icon}',
            placeholders: {
              'icon': WidgetSpan(child: Icon(Icons.star)),
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);

      // 2. Update State: {icon} is Heart
      // Renderer uses mapEquals. Since content changed, it must re-parse.
      await tester.pumpWidget(
        const MaterialApp(
          home: Textf(
            'Hello {icon}',
            placeholders: {
              'icon': WidgetSpan(child: Icon(Icons.favorite)),
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
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
        MaterialApp(
          home: TextfOptions(
            linkAlignment: PlaceholderAlignment.baseline,
            onLinkTap: (_, __) {}, // Enable link rendering
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
        MaterialApp(
          home: TextfOptions(
            linkAlignment: PlaceholderAlignment.middle,
            onLinkTap: (_, __) {},
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
