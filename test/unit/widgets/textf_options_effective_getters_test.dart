// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

import '../../widgets/pump_textf_widget.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Color(0xFF000000));
  final palette = TextfPalette(baseStyle);

  group('TextfStyleResolver resolves styles from TextfOptionsData', () {
    test('resolves underline style', () {
      final resolver = TextfStyleResolver(
        options: const TextfOptionsData(underlineStyle: TextStyle(color: Color(0xFF4CAF50))),
      );

      final result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);

      expect(result.color, const Color(0xFF4CAF50));
    });

    test('resolves highlight style', () {
      final resolver = TextfStyleResolver(
        options: const TextfOptionsData(
          highlightStyle: TextStyle(backgroundColor: Color(0xFFFFEB3B)),
        ),
      );

      final result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);

      expect(result.backgroundColor, const Color(0xFFFFEB3B));
    });

    test('resolves superscript style', () {
      final resolver = TextfStyleResolver(
        options: const TextfOptionsData(superscriptStyle: TextStyle(fontSize: 10)),
      );

      final result = resolver.resolveStyle(FormatMarkerType.superscript, baseStyle, palette);

      expect(result.fontSize, 10);
    });

    test('resolves subscript style', () {
      final resolver = TextfStyleResolver(
        options: const TextfOptionsData(subscriptStyle: TextStyle(fontSize: 10)),
      );

      final result = resolver.resolveStyle(FormatMarkerType.subscript, baseStyle, palette);

      expect(result.fontSize, 10);
    });

    testWidgets('reads superscriptBaselineFactor from data', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
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
        neutralTestApp(
          child: TextfOptions(
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
        neutralTestApp(
          child: TextfOptions(
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

    test('resolves link configuration with hover style', () {
      final resolver = TextfStyleResolver(
        options: const TextfOptionsData(linkHoverStyle: TextStyle(color: Color(0xFFF44336))),
      );

      final result = resolver.resolveLinkConfiguration(baseStyle).hoverStyle;

      expect(result.color, const Color(0xFFF44336));
    });

    test('returns normal link style for hoverStyle when hover not set', () {
      final config = TextfStyleResolver(
        options: const TextfOptionsData(),
      ).resolveLinkConfiguration(baseStyle);

      // Without a linkHoverStyle, hover falls back to normal link style
      expect(config.hoverStyle, config.style);
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
