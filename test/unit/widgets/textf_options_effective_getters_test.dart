// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

  group('TextfOptions effective getters', () {
    testWidgets('getEffectiveUnderlineStyle returns merged style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            underlineStyle: const TextStyle(color: Colors.green),
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveUnderlineStyle(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, Colors.green);
    });

    testWidgets('getEffectiveHighlightStyle returns merged style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            highlightStyle: const TextStyle(backgroundColor: Colors.yellow),
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveHighlightStyle(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.backgroundColor, Colors.yellow);
    });

    testWidgets('getEffectiveSuperscriptStyle returns merged style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            superscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveSuperscriptStyle(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    testWidgets('getEffectiveSubscriptStyle returns merged style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            subscriptStyle: const TextStyle(fontSize: 10),
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveSubscriptStyle(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.fontSize, 10);
    });

    testWidgets('getEffectiveSuperscriptBaselineFactor returns value', (tester) async {
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            superscriptBaselineFactor: 0.4,
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveSuperscriptBaselineFactor(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, 0.4);
    });

    testWidgets('getEffectiveSubscriptBaselineFactor returns value', (tester) async {
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            subscriptBaselineFactor: 0.3,
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveSubscriptBaselineFactor(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, 0.3);
    });

    testWidgets('getEffectiveScriptFontSizeFactor returns value', (tester) async {
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            scriptFontSizeFactor: 0.5,
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveScriptFontSizeFactor(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, 0.5);
    });

    testWidgets('getEffectiveLinkHoverStyle returns merged style', (tester) async {
      TextStyle? result;
      const normalLinkStyle = TextStyle(color: Colors.blue);

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            linkHoverStyle: const TextStyle(color: Colors.red),
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveLinkHoverStyle(context, normalLinkStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, Colors.red);
    });

    testWidgets('getEffectiveLinkHoverStyle returns null when not set', (tester) async {
      TextStyle? result;
      const normalLinkStyle = TextStyle(color: Colors.blue);

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            child: Builder(
              builder: (context) {
                final options = TextfOptions.maybeOf(context)!;
                result = options.getEffectiveLinkHoverStyle(context, normalLinkStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNull);
    });
  });

  group('TextfOptions.hasSameStyle', () {
    test('returns true for identical options', () {
      const options = TextfOptions(
        boldStyle: TextStyle(fontWeight: FontWeight.bold),
        child: SizedBox(),
      );
      expect(options.hasSameStyle(options), isTrue);
    });

    test('returns false when superscriptBaselineFactor differs', () {
      const a = TextfOptions(
        superscriptBaselineFactor: 0.4,
        child: SizedBox(),
      );
      const b = TextfOptions(
        superscriptBaselineFactor: 0.5,
        child: SizedBox(),
      );
      expect(a.hasSameStyle(b), isFalse);
    });
  });
}
