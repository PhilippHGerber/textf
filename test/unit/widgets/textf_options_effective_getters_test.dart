// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/link_style_configuration.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

import '../../widgets/pump_textf_widget.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Color(0xFF000000));
  final palette = TextfPalette(baseStyle);

  group('TextfStyleResolver resolves styles from TextfOptionsData', () {
    testWidgets('resolves underline style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            underlineStyle: const TextStyle(color: Color(0xFF4CAF50)),
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

    testWidgets('resolves highlight style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            highlightStyle: const TextStyle(backgroundColor: Color(0xFFFFEB3B)),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.backgroundColor, const Color(0xFFFFEB3B));
    });

    testWidgets('resolves superscript style', (tester) async {
      TextStyle? result;

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

    testWidgets('resolves subscript style', (tester) async {
      TextStyle? result;

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

    testWidgets('resolves link configuration with hover style', (tester) async {
      TextStyle? result;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            linkHoverStyle: const TextStyle(color: Color(0xFFF44336)),
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                result = resolver.resolveLinkConfiguration(baseStyle).hoverStyle;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      expect(result!.color, const Color(0xFFF44336));
    });

    testWidgets('returns normal link style for hoverStyle when hover not set', (tester) async {
      LinkStyleConfiguration? config;

      await tester.pumpWidget(
        neutralTestApp(
          child: TextfOptions(
            child: Builder(
              builder: (context) {
                final resolver = TextfStyleResolver(context);
                config = resolver.resolveLinkConfiguration(baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Without a linkHoverStyle, hover falls back to normal link style
      expect(config, isNotNull);
      expect(config!.hoverStyle, config!.style);
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
