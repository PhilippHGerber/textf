// Tests for HoverableLinkSpan edge cases.

// ignore_for_file: no-empty-block, no-magic-number

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

void main() {
  group('HoverableLinkSpan Edge Cases', () {
    testWidgets('handles null onTap callback gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TextfOptions(
            child: Textf('[Click me](https://example.com)'),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(Textf), findsOneWidget);
      // Link text should be visible
      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('handles rapid hover state changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: (url, displayText) {},
            onLinkHover: (url, displayText, {required isHovering}) {},
            child: const Textf('[Link](https://example.com)'),
          ),
        ),
      );

      // Verify widget renders
      expect(find.byType(Textf), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);

      // Simulate multiple hover enter/exit cycles
      for (int i = 0; i < 5; i++) {
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.text('Link')));
        await tester.pump();
        await gesture.moveTo(Offset.zero);
        await tester.pump();

        await gesture.removePointer();
      }

      // Should not crash
      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('link with empty URL is handled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Textf('[Empty link]()'),
        ),
      );

      // Should render the link text even with empty URL
      expect(find.byType(Textf), findsOneWidget);
      expect(find.text('Empty link'), findsOneWidget);
    });

    testWidgets('multiple links render independently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: (url, displayText) {},
            child: const Textf('[First](https://first.com) and [Second](https://second.com)'),
          ),
        ),
      );

      // Both link texts should be rendered
      expect(find.byType(Textf), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });
}
