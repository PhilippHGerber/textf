// Tests for TextfRenderer edge cases and lifecycle scenarios.

// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

void main() {
  group('TextfRenderer Edge Cases', () {
    testWidgets('handles rapid text changes without errors', (tester) async {
      // Simulates rapid updates that might stress cache invalidation
      String currentText = 'Initial **text**';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Textf(currentText),
                  ElevatedButton(
                    onPressed: () {
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
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      // Should complete without errors
      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('handles theme changes gracefully', (tester) async {
      ThemeMode themeMode = ThemeMode.light;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              themeMode: themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: Column(
                children: [
                  const Textf('Some **bold** and `code` text'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                      });
                    },
                    child: const Text('Toggle'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Toggle theme multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('disposes correctly when removed from tree', (tester) async {
      bool showTextf = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Column(
                children: [
                  if (showTextf) const Textf('**Bold** with [link](url)'),
                  ElevatedButton(
                    onPressed: () => setState(() => showTextf = !showTextf),
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
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(Textf), findsNothing);

      // Add it back
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(Textf), findsOneWidget);
    });

    testWidgets('handles very long text without overflow errors', (tester) async {
      final longText = 'Word ' * 1000 + '**bold**';

      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Textf(longText),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles text with only formatting markers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Textf('********'),
        ),
      );

      // Should render without crashing
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles deeply nested formatting', (tester) async {
      // Tests nesting limit behavior
      await tester.pumpWidget(
        const MaterialApp(
          home: Textf('**bold _italic `code` end_ end**'),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText, isNotNull);
    });
  });
}
