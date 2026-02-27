// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  group('TextfParser coverage', () {
    late TextfParser parser;

    setUp(() {
      TextfParser.clearCache();
      parser = TextfParser();
    });

    testWidgets('long text bypasses cache', (tester) async {
      // Text longer than maxCacheKeyLength (1000) should be parsed without caching
      final longText = '**bold** ${'a' * 1001}';
      late List<InlineSpan> result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = parser.parse(longText, context, const TextStyle());
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNotEmpty);
    });

    testWidgets('PlaceholderToken renders as plain text when no placeholders provided',
        (tester) async {
      late List<InlineSpan> result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = parser.parse('{icon}', context, const TextStyle());
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNotEmpty);
      // Without placeholders map, {icon} should be rendered as plain text
      final span = result.first as TextSpan;
      expect(span.text, contains('icon'));
    });

    testWidgets('broken link separator renders as plain text', (tester) async {
      late List<InlineSpan> result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // A standalone [ without matching ](url) should render as plain text
              result = parser.parse('[broken', context, const TextStyle());
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNotEmpty);
      final text = (result.first as TextSpan).text;
      expect(text, contains('['));
    });
  });
}
