// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

void main() {
  group('TextfParser coverage', () {
    late TextfParser parser;
    final resolver = TextfStyleResolver.withState(options: null);

    setUp(() {
      TextfParser.clearCache();
      parser = TextfParser();
    });

    test('long text bypasses cache', () {
      // Text longer than maxCacheKeyLength (1000) should be parsed without caching
      final longText = '**bold** ${'a' * 1001}';

      final result = parser.parse(longText, const TextStyle(), resolver);

      expect(result, isNotEmpty);
    });

    test('PlaceholderToken renders as plain text when no placeholders provided', () {
      final result = parser.parse('{icon}', const TextStyle(), resolver);

      expect(result, isNotEmpty);
      // Without placeholders map, {icon} should be rendered as plain text
      final span = result.first as TextSpan;
      expect(span.text, contains('icon'));
    });

    test('broken link separator renders as plain text', () {
      // A standalone [ without matching ](url) should render as plain text
      final result = parser.parse('[broken', const TextStyle(), resolver);

      expect(result, isNotEmpty);
      final text = (result.first as TextSpan).text;
      expect(text, contains('['));
    });
  });
}
