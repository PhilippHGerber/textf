// ignore_for_file: avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

void main() {
  group('TextfStyleResolver Without TextfOptions', () {
    const baseStyle = TextStyle(fontSize: 16, color: Colors.black);

    /// Pumps a minimal widget tree without TextfOptions.
    Future<BuildContext> pumpWithoutOptions(WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return capturedContext;
    }

    testWidgets('resolves bold using DefaultStyles fallback', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.bold, baseStyle);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontSize, baseStyle.fontSize);
    });

    testWidgets('resolves italic using DefaultStyles fallback', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.italic, baseStyle);

      expect(result.fontStyle, FontStyle.italic);
    });

    testWidgets('resolves boldItalic using DefaultStyles fallback', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontStyle, FontStyle.italic);
    });

    testWidgets('resolves strikethrough with default thickness', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.strikethrough, baseStyle);

      expect(result.decoration, TextDecoration.lineThrough);
      expect(
        result.decorationThickness,
        DefaultStyles.defaultStrikethroughThickness,
      );
    });

    testWidgets('resolves code with theme-based styling', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.code, baseStyle);

      expect(result.fontFamily, 'monospace');
      expect(result.backgroundColor, isNotNull);
    });

    testWidgets('resolves underline using DefaultStyles fallback', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle);

      expect(result.decoration, TextDecoration.underline);
    });

    testWidgets('resolves highlight with theme-based background', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle);

      expect(result.backgroundColor, isNotNull);
    });

    testWidgets('resolves superscript with scaled font size', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.superscript, baseStyle);

      expect(
        result.fontSize,
        baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor,
      );
    });

    testWidgets('resolves subscript with scaled font size', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final result = resolver.resolveStyle(FormatMarkerType.subscript, baseStyle);

      expect(
        result.fontSize,
        baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor,
      );
    });

    testWidgets('resolves link style from theme', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);
      final theme = Theme.of(context);

      final result = resolver.resolveLinkStyle(baseStyle);

      expect(result.color, theme.colorScheme.primary);
      expect(result.decoration, TextDecoration.underline);
    });

    testWidgets('resolves link hover style from theme', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);
      Theme.of(context);

      final result = resolver.resolveLinkHoverStyle(baseStyle);

      // Hover typically uses a variant of the primary color
      expect(result.decoration, TextDecoration.underline);
      expect(result.color, isNotNull);
    });

    testWidgets('resolves link mouse cursor to default', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final cursor = resolver.resolveLinkMouseCursor();

      expect(cursor, DefaultStyles.linkMouseCursor);
    });

    testWidgets('resolves link alignment to baseline', (tester) async {
      final context = await pumpWithoutOptions(tester);
      final resolver = TextfStyleResolver(context);

      final alignment = resolver.resolveLinkAlignment();

      expect(alignment, PlaceholderAlignment.baseline);
    });
  });
}
