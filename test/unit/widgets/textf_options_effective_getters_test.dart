// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

  group('TextfStyleResolver resolves styles from TextfOptionsData', () {
    testWidgets('resolves underline style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            underlineStyle: const TextStyle(color: Colors.green),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, Colors.green);
    });

    testWidgets('resolves highlight style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            highlightStyle: const TextStyle(backgroundColor: Colors.yellow),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.backgroundColor, Colors.yellow);
    });

    testWidgets('resolves superscript style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            superscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.superscript, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    testWidgets('resolves subscript style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            subscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.subscript, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    testWidgets('reads superscriptBaselineFactor from data', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            superscriptBaselineFactor: 0.4,
            child: Builder(
              builder: (context) {
                data = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data!.superscriptBaselineFactor, 0.4);
    });

    testWidgets('reads subscriptBaselineFactor from data', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            subscriptBaselineFactor: 0.3,
            child: Builder(
              builder: (context) {
                data = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data!.subscriptBaselineFactor, 0.3);
    });

    testWidgets('reads scriptFontSizeFactor from data', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            scriptFontSizeFactor: 0.5,
            child: Builder(
              builder: (context) {
                data = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data!.scriptFontSizeFactor, 0.5);
    });

    testWidgets('resolves link hover style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            linkHoverStyle: const TextStyle(color: Colors.red),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveLinkHoverStyle(baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, Colors.red);
    });

    testWidgets('returns normal link style when hover not set', (tester) async {
      TextStyle? normal;
      TextStyle? hover;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                normal = resolver.resolveLinkStyle(baseStyle);
                hover = resolver.resolveLinkHoverStyle(baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Without a linkHoverStyle, hover falls back to normal link style
      expect(hover, normal);
    });
  });

  group('TextfOptionsData equality', () {
    test('returns true for identical options', () {
      const data = TextfOptionsData(
        boldStyle: TextStyle(fontWeight: FontWeight.bold),
      );
      expect(data, data);
    });

    test('returns false when superscriptBaselineFactor differs', () {
      const a = TextfOptionsData(superscriptBaselineFactor: 0.4);
      const b = TextfOptionsData(superscriptBaselineFactor: 0.5);
      expect(a == b, isFalse);
    });
  });
}
