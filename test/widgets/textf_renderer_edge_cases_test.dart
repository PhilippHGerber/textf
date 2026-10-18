// Tests for TextfRenderer edge cases and lifecycle scenarios.

// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

void main() {
  group('TextfRenderer Edge Cases', () {
    testWidgets('handles rapid text changes without errors', (tester) async {
      // Simulates rapid updates that might stress cache invalidation
      String currentText = 'Initial **text**';

      await tester.pumpWidget(
        neutralTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Textf(currentText),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentText = 'Updated *text* ${DateTime.now().millisecond}';
                      });
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Rapidly update the text multiple times
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Update'));
        await tester.pump();
      }

      // Should complete without errors
      expect(find.byType(Textf), findsOneWidget);
    });

    // Material interop: an explicit `Theme` (not `MaterialApp`) is toggled between light and
    // dark. Textf reads no design-system theme, so this guards that ancestor Theme churn does
    // not break rendering.
    testWidgets('handles theme changes gracefully', (tester) async {
      bool isDark = false;

      await tester.pumpWidget(
        neutralTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Theme(
                data: isDark ? ThemeData.dark() : ThemeData.light(),
                child: Column(
                  children: [
                    const Textf('Some **bold** and `code` text'),
                    GestureDetector(
                      onTap: () => setState(() => isDark = !isDark),
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Toggle theme multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Toggle'));
        await tester.pumpAndSettle();
      }

      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('disposes correctly when removed from tree', (tester) async {
      bool showTextf = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return neutralTestApp(
              child: Column(
                children: [
                  if (showTextf) const Textf('**Bold** with [link](url)'),
                  GestureDetector(
                    onTap: () => setState(() => showTextf = !showTextf),
                    child: const Text('Toggle'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.byType(Textf), findsOneWidget);

      // Remove Textf from tree
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(find.byType(Textf), findsNothing);

      // Add it back
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('handles very long text without overflow errors', (tester) async {
      final longText = 'Word ' * 1000 + '**bold**';

      await tester.pumpWidget(
        neutralTestApp(
          child: SingleChildScrollView(
            child: Textf(longText),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles text with only formatting markers', (tester) async {
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf('********'),
        ),
      );

      // Should render without crashing
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles deeply nested formatting', (tester) async {
      // Tests nesting limit behavior
      await tester.pumpWidget(
        neutralTestApp(
          child: const Textf('**bold _italic `code` end_ end**'),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText, isNotNull);
    });
  });
}
