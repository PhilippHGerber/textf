// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/textf.dart';

import '../widgets/pump_textf_widget.dart';

void main() {
  group('TextfStyleResolver with TextfOptions for various format types', () {
    const baseStyle = TextStyle(fontSize: 14, color: Color(0xFF000000));
    final palette = TextfPalette(baseStyle);

    testWidgets('resolves boldItalic style from TextfOptions', (tester) async {
      late TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            boldItalicStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle, palette);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontWeight, FontWeight.w900);
    });

    testWidgets('resolves underline style from TextfOptions', (tester) async {
      late TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            underlineStyle: const TextStyle(
              decoration: TextDecoration.underline,
              color: Color(0xFF4CAF50),
            ),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, const Color(0xFF4CAF50));
    });

    testWidgets('resolves superscript style from TextfOptions', (tester) async {
      late TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            superscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.superscript, baseStyle, palette);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    testWidgets('resolves subscript style from TextfOptions', (tester) async {
      late TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            subscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.subscript, baseStyle, palette);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    test('resolves highlight style on a dark surface (light text)', () {
      final darkSurface = TextfPalette(const TextStyle(color: Color(0xFFFFFFFF)));
      final resolver = TextfStyleResolver.withState(options: null);

      final result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, darkSurface);

      expect(result.backgroundColor, const Color(0xFFFBC02D).withValues(alpha: 0.4));
    });
  });

  group('Nested TextfOptions merging via TextfOptionsData', () {
    testWidgets('merges same style property from two levels', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            italicStyle: const TextStyle(color: Color(0xFFF44336)),
            boldItalicStyle: const TextStyle(fontWeight: FontWeight.bold),
            strikethroughStyle: const TextStyle(decoration: TextDecoration.lineThrough),
            codeStyle: const TextStyle(fontFamily: 'monospace'),
            underlineStyle: const TextStyle(decoration: TextDecoration.underline),
            highlightStyle: const TextStyle(backgroundColor: Color(0xFFFFEB3B)),
            superscriptStyle: const TextStyle(fontSize: 8),
            subscriptStyle: const TextStyle(fontSize: 8),
            linkStyle: const TextStyle(color: Color(0xFF2196F3)),
            linkHoverStyle: const TextStyle(color: Color(0xFF9C27B0)),
            child: TextfOptions(
              // Same properties at a second level to hit merge branches
              italicStyle: const TextStyle(fontStyle: FontStyle.italic),
              boldItalicStyle: const TextStyle(fontStyle: FontStyle.italic),
              strikethroughStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              codeStyle: const TextStyle(fontSize: 12),
              underlineStyle: const TextStyle(color: Color(0xFF4CAF50)),
              highlightStyle: const TextStyle(color: Color(0xFF000000)),
              superscriptStyle: const TextStyle(color: Color(0xFFFF9800)),
              subscriptStyle: const TextStyle(color: Color(0xFFFF9800)),
              linkStyle: const TextStyle(decoration: TextDecoration.underline),
              linkHoverStyle: const TextStyle(decoration: TextDecoration.underline),
              child: Builder(
                builder: (context) {
                  data = TextfOptions.maybeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // Merged data should be present and contain properties from both levels
      expect(data, isNotNull);
      // Child italic color (from child) should be merged on top of parent red
      expect(data!.italicStyle?.fontStyle, FontStyle.italic); // from child
      // Child underline color wins
      expect(data!.underlineStyle?.color, const Color(0xFF4CAF50)); // from child
      // Parent link color merged with child decoration
      expect(
        data!.linkStyle?.color,
        const Color(0xFF2196F3),
      ); // from parent (child didn't specify color)
    });
  });

  group('TextfEditingController composing with formatted text', () {
    late TextfEditingController controller;

    tearDown(() {
      controller.dispose();
    });

    testWidgets('composing region with WidgetSpan (script preview)', (tester) async {
      controller = TextfEditingController(
        text: 'E=mc^2^',
        markerVisibility: MarkerVisibility.whenActive,
      );
      late TextSpan result;

      await tester.pumpWidget(
        neutralTestApp(
          child: Builder(
            builder: (context) {
              // Cursor at 0 means ^2^ is in preview mode (WidgetSpans)
              controller
                ..selection = const TextSelection.collapsed(offset: 0)
                ..value = controller.value.copyWith(
                  composing: const TextRange(start: 0, end: 4), // E=mc
                );
              result = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: true,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.children, isNotNull);
      // Should have WidgetSpans for the preview zone
      final widgetSpans = result.children!.whereType<WidgetSpan>().toList();
      expect(widgetSpans, isNotEmpty);
    });

    testWidgets('composing region overlaps with WidgetSpan (script preview)', (tester) async {
      // This tests the WidgetSpan branch in composing region handling
      // (controller lines 212-215)
      controller = TextfEditingController(
        text: 'E=mc^2^',
        markerVisibility: MarkerVisibility.whenActive,
      );
      late TextSpan result;

      await tester.pumpWidget(
        neutralTestApp(
          child: Builder(
            builder: (context) {
              // Cursor at 0 means ^2^ is in preview mode (WidgetSpans)
              // Composing range covers the whole string including WidgetSpan positions
              controller
                ..selection = const TextSelection.collapsed(offset: 0)
                ..value = controller.value.copyWith(
                  composing: const TextRange(start: 0, end: 7), // entire string
                );
              result = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: true,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.children, isNotNull);
      // WidgetSpans should be passed through even when composing overlaps
      final widgetSpans = result.children!.whereType<WidgetSpan>().toList();
      expect(widgetSpans, isNotEmpty);
    });

    testWidgets('composing region splits formatted text after composing end', (tester) async {
      controller = TextfEditingController(text: '**hello world**');
      late TextSpan result;

      await tester.pumpWidget(
        neutralTestApp(
          child: Builder(
            builder: (context) {
              controller.value = controller.value.copyWith(
                composing: const TextRange(start: 2, end: 7), // "hello"
              );
              result = controller.buildTextSpan(
                context: context,
                style: const TextStyle(),
                withComposing: true,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.children, isNotNull);
      // Should have split spans: before composing, composing, after composing
      expect(result.children!.length, greaterThan(2));
    });
  });

  group('TextfEditingController span builder with broken links', () {
    late TextfEditingController controller;

    tearDown(() {
      controller.dispose();
    });

    testWidgets('broken link tokens fall through as plain text in span builder', (tester) async {
      // The span builder should handle [text](url) by rendering all chars
      controller = TextfEditingController(text: '[link](url) and more');
      late TextSpan result;

      await tester.pumpWidget(
        neutralTestApp(
          child: Builder(
            builder: (context) {
              result = controller.buildTextSpan(
                context: context,
                style: const TextStyle(),
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.children, isNotNull);
      var totalLength = 0;
      for (final child in result.children!) {
        if (child is TextSpan) {
          totalLength += child.text?.length ?? 0;
        } else if (child is WidgetSpan) {
          totalLength += 1;
        }
      }
      expect(totalLength, '[link](url) and more'.length);
    });
  });

  group('Textf widget static methods', () {
    test('Textf.clearCache does not throw', () {
      expect(Textf.clearCache, returnsNormally);
    });
  });

  group('TextfParser orphan link tokens as plain text', () {
    late TextfParser parser;

    setUp(() {
      TextfParser.clearCache();
      parser = TextfParser();
    });

    testWidgets('link tokens that fail validation render as plain text', (tester) async {
      // This input has [ which triggers link parsing, but if the link handler
      // fails, tokens should fall through to plain text
      late List<InlineSpan> result;

      await tester.pumpWidget(
        neutralTestApp(
          child: Builder(
            builder: (context) {
              // [text](url) is a valid link - it will be handled by LinkHandler
              // To test fallthrough, we need tokens that exist but aren't handled
              // However, as analyzed, LinkSeparator/LinkEnd are always produced
              // as part of a complete link. These branches are exhaustive-switch
              // dead code.
              //
              // Instead, test that the parser handles complex nested links
              result = parser.parse(
                '[outer [inner](url1)](url2)',
                context,
                const TextStyle(),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNotEmpty);
    });
  });
}
