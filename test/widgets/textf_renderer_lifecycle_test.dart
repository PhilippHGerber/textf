// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/widgets/internal/textf_renderer.dart';
import 'package:textf/textf.dart';

// --- Spy ---

// ignore: prefer-match-file-name, avoid-top-level-members-in-tests
class SpyTextfParser implements TextfParser {
  int parseCallCount = 0;

  @override
  List<InlineSpan> parse(
    String data,
    BuildContext context,
    TextStyle? baseStyle, {
    TextScaler? textScaler,
    Map<String, InlineSpan>? placeholders,
  }) {
    parseCallCount++;
    // Return a dummy span to allow the widget to build without errors
    return [TextSpan(text: data, style: baseStyle)];
  }
}

// --- Helper Wrapper ---

/// Helper to wrap TextfRenderer in the necessary ancestors
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('TextfRenderer Lifecycle & Cache Tests', () {
    late SpyTextfParser spyParser;

    setUp(() {
      spyParser = SpyTextfParser();
    });

    testWidgets('Initial build parses data', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Initial',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      // Verify parse was called once
      expect(spyParser.parseCallCount, 1, reason: 'Parser should be called on initial build');
    });

    testWidgets('Rebuild with identical props uses cache (no re-parse)', (tester) async {
      // 1. Initial Build
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      expect(spyParser.parseCallCount, 1);

      // 2. Rebuild with identical props
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10), // Equality via const or data class
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      // Verify parse was NOT called again
      expect(
        spyParser.parseCallCount,
        1,
        reason: 'Parser should NOT be called again for identical props',
      );
    });

    testWidgets('Layout properties invalidate cache (Regression Fix: Alignment Issue)',
        (tester) async {
      // 1. Initial Build
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.center, // Starts Center
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );
      expect(spyParser.parseCallCount, 1);

      // 2. Change TextAlign -> Should Re-parse (Invalidate Cache)
      // This is crucial for verifying the fix where alignment changes require new WidgetSpans.
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.right, // Changed to Right
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      // Verify called effectively again (total 2)
      expect(
        spyParser.parseCallCount,
        2,
        reason: 'Parser SHOULD be called again when TextAlign changes',
      );
    });

    testWidgets('Changing other layout props (maxLines, overflow) also invalidates cache',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );
      expect(spyParser.parseCallCount, 1);

      // Change maxLines
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            maxLines: 2, // Changed
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );
      expect(spyParser.parseCallCount, 2, reason: 'Parser SHOULD be called when maxLines changes');
    });

    testWidgets('Changing non-layout props (selectionColor) DOES NOT invalidate cache',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: Colors.red,
          ),
        ),
      );
      expect(spyParser.parseCallCount, 1);

      // Change selectionColor
      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Text',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: Colors.blue, // Changed
          ),
        ),
      );

      // Should NOT call parse again
      expect(
        spyParser.parseCallCount,
        1,
        reason: 'Parser should NOT be called for non-layout prop changes',
      );
    });

    testWidgets('Alignment Propagation: Wraps output in DefaultTextStyle', (tester) async {
      // This test verifies that the rendered widget tree actually contains the DefaultTextStyle.merge
      // which propagates the alignment to children.

      await tester.pumpWidget(
        _wrap(
          TextfRenderer(
            data: 'Check Alignment',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: TextAlign.justify, // Specific alignment
            textDirection: TextDirection.ltr,
            locale: null,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: TextScaler.noScaling,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: TextWidthBasis.parent,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      // Find the DefaultTextStyle widget immediately below the TextfRenderer
      // TextfRenderer builds: DefaultTextStyle.merge( child: Text.rich(...) )

      final defaultTextStyleFinder = find.descendant(
        of: find.byType(TextfRenderer),
        matching: find.byType(DefaultTextStyle),
      );

      expect(defaultTextStyleFinder, findsOneWidget);

      final DefaultTextStyle dts = tester.widget<DefaultTextStyle>(defaultTextStyleFinder);
      expect(
        dts.textAlign,
        TextAlign.justify,
        reason: 'TextAlign should be propagated via DefaultTextStyle',
      );
    });

    testWidgets('Cache persists when Parent rebuilds with identical TextfOptions values',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: TextfRenderer(
              data: 'Text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: null,
              selectionColor: null,
            ),
          ),
        ),
      );

      expect(spyParser.parseCallCount, 1);

      // Rebuild the tree. This creates a NEW TextfOptions instance,
      // but with the SAME boldStyle value.
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: TextfRenderer(
              data: 'Text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: null,
              selectionColor: null,
            ),
          ),
        ),
      );

      expect(
        spyParser.parseCallCount,
        1,
        reason: 'Should not re-parse if Options value is identical',
      );
    });

    testWidgets('linkAlignment change triggers re-parse', (tester) async {
      // 1. Initial Build with baseline alignment
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            linkAlignment: PlaceholderAlignment.baseline,
            onLinkTap: (_, __) {},
            child: TextfRenderer(
              data: '[Link](https://example.com)',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: null,
              selectionColor: null,
            ),
          ),
        ),
      );
      expect(spyParser.parseCallCount, 1);

      // 2. Change linkAlignment -> Should trigger re-parse
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            linkAlignment: PlaceholderAlignment.middle, // Changed
            onLinkTap: (_, __) {},
            child: TextfRenderer(
              data: '[Link](https://example.com)',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: null,
              selectionColor: null,
            ),
          ),
        ),
      );

      expect(
        spyParser.parseCallCount,
        2,
        reason: 'Parser SHOULD be called again when linkAlignment changes',
      );
    });

    testWidgets('Cache persists when Theme instance changes but relevant colors are identical',
        (tester) async {
      // Two different ThemeData instances with SAME relevant colors
      final theme1 = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          onSurfaceVariant: Colors.grey,
          surfaceContainer: Colors.white,
        ),
      );

      final theme2 = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue, // Same
          onSurfaceVariant: Colors.grey, // Same
          surfaceContainer: Colors.white, // Same
          // But different tertiary (irrelevant to Textf)
          tertiary: Colors.purple,
        ),
      );

      // Sanity check: these are different instances
      expect(identical(theme1, theme2), isFalse);

      // 1. Initial build with theme1
      await tester.pumpWidget(
        MaterialApp(
          theme: theme1,
          home: TextfRenderer(
            data: '**Bold** and `code` and [link](https://example.com)',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: null,
            textDirection: null,
            locale: null,
            softWrap: null,
            overflow: null,
            textScaler: null,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: null,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );
      expect(spyParser.parseCallCount, 1);

      // 2. Rebuild with theme2 (different instance, same relevant colors)
      await tester.pumpWidget(
        MaterialApp(
          theme: theme2,
          home: TextfRenderer(
            data: '**Bold** and `code` and [link](https://example.com)',
            style: const TextStyle(fontSize: 10),
            parser: spyParser,
            strutStyle: null,
            textAlign: null,
            textDirection: null,
            locale: null,
            softWrap: null,
            overflow: null,
            textScaler: null,
            maxLines: null,
            semanticsLabel: null,
            textWidthBasis: null,
            textHeightBehavior: null,
            selectionColor: null,
          ),
        ),
      );

      // Should NOT re-parse because relevant colors are identical
      expect(
        spyParser.parseCallCount,
        1,
        reason: 'Should not re-parse when only irrelevant theme properties change',
      );
    });

    testWidgets('Cache invalidates when Theme relevant colors change', (tester) async {
      final theme1 = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          onSurfaceVariant: Colors.grey,
          surfaceContainer: Colors.white,
        ),
      );

      final theme2 = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.red, // Different!
          onSurfaceVariant: Colors.grey,
          surfaceContainer: Colors.white,
        ),
      );

      // Simple wrapper without MaterialApp's theme animation
      Widget buildWithTheme(ThemeData theme) {
        return Theme(
          data: theme,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: TextfRenderer(
                data: '[link](https://example.com)',
                style: const TextStyle(fontSize: 10),
                parser: spyParser,
                strutStyle: null,
                textAlign: null,
                textDirection: null,
                locale: null,
                softWrap: null,
                overflow: null,
                textScaler: null,
                maxLines: null,
                semanticsLabel: null,
                textWidthBasis: null,
                textHeightBehavior: null,
                selectionColor: null,
              ),
            ),
          ),
        );
      }

      // 1. Initial build with theme1
      await tester.pumpWidget(buildWithTheme(theme1));
      expect(spyParser.parseCallCount, 1);

      // 2. Switch to theme2 (different primary color)
      await tester.pumpWidget(buildWithTheme(theme2));

      expect(
        spyParser.parseCallCount,
        2,
        reason: 'Should re-parse when theme primary color changes',
      );
    });

    testWidgets('Cache invalidates when ancestor (non-nearest) TextfOptions changes',
        (tester) async {
      Widget buildTree({required Color grandparentBoldColor}) {
        return Theme(
          data: ThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: TextfOptions(
                // Grandparent - provides boldStyle
                boldStyle: TextStyle(color: grandparentBoldColor),
                child: TextfOptions(
                  // Parent (nearest) - provides italicStyle only
                  italicStyle: const TextStyle(fontStyle: FontStyle.italic),
                  child: TextfRenderer(
                    data: '**bold**',
                    style: const TextStyle(fontSize: 10),
                    parser: spyParser,
                    strutStyle: null,
                    textAlign: null,
                    textDirection: null,
                    locale: null,
                    softWrap: null,
                    overflow: null,
                    textScaler: null,
                    maxLines: null,
                    semanticsLabel: null,
                    textWidthBasis: null,
                    textHeightBehavior: null,
                    selectionColor: null,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // 1. Initial: grandparent boldStyle is blue
      await tester.pumpWidget(buildTree(grandparentBoldColor: Colors.blue));
      expect(spyParser.parseCallCount, 1);

      // 2. Change grandparent boldStyle to red (nearest TextfOptions unchanged)
      await tester.pumpWidget(buildTree(grandparentBoldColor: Colors.red));

      // Should re-parse because effective boldStyle changed
      expect(
        spyParser.parseCallCount,
        2,
        reason: 'Should re-parse when ancestor TextfOptions changes',
      );
    });
  });
}
