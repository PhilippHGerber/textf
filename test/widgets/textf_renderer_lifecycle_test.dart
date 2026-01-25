// ignore_for_file: no-magic-number, avoid-late-keyword, no-empty-block, avoid_redundant_argument_values, avoid_redundant_argument_values

import 'dart:ui' as ui;

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

    testWidgets('Cache persists when callbacks are stable references', (tester) async {
      // Define stable callback references outside the build
      void handleTap(String url, String text) {}
      void handleHover(String url, String text, {required bool isHovering}) {}

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: handleTap,
            onLinkHover: handleHover,
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

      // Rebuild with SAME callback references
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: handleTap,
            onLinkHover: handleHover,
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
        1,
        reason: 'Stable callback references should not invalidate cache',
      );
    });

    testWidgets('Cache invalidates when inline callbacks change (expected v1.1 behavior)',
        (tester) async {
      // First build with inline callback
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: (url, text) {}, // Inline closure #1
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

      // Rebuild with new inline callback (different instance)
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            onLinkTap: (url, text) {}, // Inline closure #2 - NEW instance
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

      // This documents the CURRENT behavior in v1.1:
      // Inline closures create new instances, which changes the hash and invalidates cache.
      // This is expected but suboptimal - users should use stable references for best performance.
      // See Option B in the roadmap for the v1.2 architectural fix.
      expect(
        spyParser.parseCallCount,
        2,
        reason: 'Inline callbacks create new instances, invalidating cache (v1.1 known limitation)',
      );
    });

    group('textHeightBehavior Cache Invalidation', () {
      testWidgets('Cache invalidates when textHeightBehavior changes', (tester) async {
        const behavior1 = ui.TextHeightBehavior(
            // applyHeightToFirstAscent: true,
            // applyHeightToLastDescent: true,
            );
        const behavior2 = ui.TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );

        // 1. Initial build with behavior1
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior1, // Initial behavior
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1, reason: 'Initial build should parse');

        // 2. Rebuild with behavior2 (different)
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior2, // Changed behavior
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called again when textHeightBehavior changes',
        );
      });

      testWidgets('Cache invalidates when textHeightBehavior changes from null to value',
          (tester) async {
        const behavior = ui.TextHeightBehavior(
          applyHeightToFirstAscent: false,
          // applyHeightToLastDescent: true,
        );

        // 1. Initial build with null
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: null, // Initially null
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1);

        // 2. Rebuild with a value
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior, // Now has value
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when textHeightBehavior changes from null to value',
        );
      });

      testWidgets('Cache invalidates when textHeightBehavior changes from value to null',
          (tester) async {
        const behavior = ui.TextHeightBehavior(
          // applyHeightToFirstAscent: true,
          applyHeightToLastDescent: false,
        );

        // 1. Initial build with value
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior, // Initially has value
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1);

        // 2. Rebuild with null
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: null, // Now null
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when textHeightBehavior changes from value to null',
        );
      });

      testWidgets('Cache persists when textHeightBehavior is identical', (tester) async {
        const behavior = ui.TextHeightBehavior(
            // applyHeightToFirstAscent: true,
            // applyHeightToLastDescent: true,
            );

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior,
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1);

        // 2. Rebuild with identical behavior (same const instance)
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior, // Same instance
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          1,
          reason: 'Parser should NOT be called when textHeightBehavior is unchanged',
        );
      });

      testWidgets('Cache persists when textHeightBehavior has equal values (different instance)',
          (tester) async {
        // Two different instances with same values
        const behavior1 = ui.TextHeightBehavior(
          // applyHeightToFirstAscent: true,
          applyHeightToLastDescent: false,
        );
        const behavior2 = ui.TextHeightBehavior(
          // applyHeightToFirstAscent: true,
          applyHeightToLastDescent: false,
        );

        // Sanity check: these should be equal but may be different instances
        expect(behavior1, equals(behavior2));

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior1,
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1);

        // 2. Rebuild with equal but potentially different instance
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
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
              textHeightBehavior: behavior2,
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          1,
          reason: 'Parser should NOT be called when textHeightBehavior values are equal',
        );
      });
    });

// -----------------------------------------------------------------------------
// ISSUE #2: locale Cache Invalidation Tests
// -----------------------------------------------------------------------------

    group('locale Cache Invalidation', () {
      testWidgets('Cache invalidates when locale changes', (tester) async {
        const locale1 = Locale('en', 'US');
        const locale2 = Locale('de', 'DE');

        // 1. Initial build with locale1
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale1, // Initial locale
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

        expect(spyParser.parseCallCount, 1, reason: 'Initial build should parse');

        // 2. Rebuild with locale2 (different)
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale2, // Changed locale
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called again when locale changes',
        );
      });

      testWidgets('Cache invalidates when locale changes from null to value', (tester) async {
        const locale = Locale('fr', 'FR');

        // 1. Initial build with null
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null, // Initially null
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

        // 2. Rebuild with a value
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale, // Now has value
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when locale changes from null to value',
        );
      });

      testWidgets('Cache invalidates when locale changes from value to null', (tester) async {
        const locale = Locale('ja', 'JP');

        // 1. Initial build with value
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale, // Initially has value
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

        // 2. Rebuild with null
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: null, // Now null
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when locale changes from value to null',
        );
      });

      testWidgets('Cache invalidates when only language code changes', (tester) async {
        const locale1 = Locale('en');
        const locale2 = Locale('es');

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale1,
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

        // 2. Rebuild with different language code
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale2,
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when language code changes',
        );
      });

      testWidgets('Cache invalidates when only country code changes', (tester) async {
        const locale1 = Locale('en', 'US');
        const locale2 = Locale('en', 'GB');

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale1,
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

        // 2. Rebuild with different country code (same language)
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale2,
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when country code changes',
        );
      });

      testWidgets('Cache persists when locale is identical', (tester) async {
        const locale = Locale('zh', 'CN');

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale,
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

        // 2. Rebuild with identical locale (same const instance)
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale, // Same instance
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

        expect(
          spyParser.parseCallCount,
          1,
          reason: 'Parser should NOT be called when locale is unchanged',
        );
      });

      testWidgets('Cache persists when locale has equal values (different instance)',
          (tester) async {
        // Two different instances with same values
        const locale1 = Locale('ar', 'SA');
        const locale2 = Locale('ar', 'SA');

        // Sanity check: these should be equal
        expect(locale1, equals(locale2));

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale1,
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

        // 2. Rebuild with equal but different instance
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale2,
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

        expect(
          spyParser.parseCallCount,
          1,
          reason: 'Parser should NOT be called when locale values are equal',
        );
      });

      testWidgets('Cache invalidates for RTL locale change (regression test for i18n)',
          (tester) async {
        // This specifically tests RTL support which is advertised
        const ltrLocale = Locale('en', 'US');
        const rtlLocale = Locale('ar', 'SA'); // Arabic - RTL

        // 1. Initial build with LTR locale
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test **bold** text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: ltrLocale,
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

        // 2. Switch to RTL locale
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test **bold** text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: rtlLocale,
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

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser SHOULD be called when switching between LTR and RTL locales',
        );
      });
    });

// -----------------------------------------------------------------------------
// COMBINED TEST: Both properties change simultaneously
// -----------------------------------------------------------------------------

    group('Combined textHeightBehavior and locale Cache Invalidation', () {
      testWidgets('Cache invalidates when both textHeightBehavior and locale change',
          (tester) async {
        const behavior1 = ui.TextHeightBehavior(
            // applyHeightToFirstAscent: true
            );
        const behavior2 = ui.TextHeightBehavior(applyHeightToFirstAscent: false);
        const locale1 = Locale('en');
        const locale2 = Locale('de');

        // 1. Initial build
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale1,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: behavior1,
              selectionColor: null,
            ),
          ),
        );

        expect(spyParser.parseCallCount, 1);

        // 2. Change both properties
        await tester.pumpWidget(
          _wrap(
            TextfRenderer(
              data: 'Test text',
              style: const TextStyle(fontSize: 10),
              parser: spyParser,
              strutStyle: null,
              textAlign: null,
              textDirection: null,
              locale: locale2,
              softWrap: null,
              overflow: null,
              textScaler: null,
              maxLines: null,
              semanticsLabel: null,
              textWidthBasis: null,
              textHeightBehavior: behavior2,
              selectionColor: null,
            ),
          ),
        );

        expect(
          spyParser.parseCallCount,
          2,
          reason: 'Parser should be called when multiple properties change',
        );
      });
    });
  });
}
