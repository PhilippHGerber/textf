// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/formatting_utils.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  group('ATX headings', () {
    late TextfParser parser;

    setUp(() {
      TextfParser.clearCache();
      parser = TextfParser();
    });

    Future<List<InlineSpan>> parse(WidgetTester tester, String text) async {
      late List<InlineSpan> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = parser.parse(text, context, const TextStyle(fontSize: 14));
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('H1 applies enlarged bold style to the line', (tester) async {
      final result = await parse(tester, '# Title');

      final textSpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Title'));
      expect(textSpan.style!.fontSize, 28.0);
      expect(textSpan.style!.fontWeight, FontWeight.bold);
    });

    testWidgets('heading terminates at newline', (tester) async {
      final result = await parse(tester, '# Heading\nbody');

      final headingSpan =
          result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Heading'));
      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(headingSpan.style!.fontSize, 28.0);
      expect(bodySpan.style!.fontSize, 14.0);
    });

    testWidgets('heading terminates at CRLF (increment 02)', (tester) async {
      final result = await parse(tester, '# Heading\r\nbody');

      final headingSpan =
          result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Heading'));
      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(headingSpan.style!.fontSize, 28.0);
      expect(bodySpan.style!.fontSize, 14.0);
    });

    testWidgets('heading terminates at a lone CR (increment 02)', (tester) async {
      final result = await parse(tester, '# Heading\rbody');

      final headingSpan =
          result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Heading'));
      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(headingSpan.style!.fontSize, 28.0);
      expect(bodySpan.style!.fontSize, 14.0);
    });

    testWidgets('tab separator produces a heading with H1 styling (increment 02)', (tester) async {
      final result = await parse(tester, '#\tTitle');

      final textSpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Title'));
      expect(textSpan.style!.fontSize, 28.0);
      expect(textSpan.style!.fontWeight, FontWeight.bold);
    });

    testWidgets('heading terminates inside cross-line formatting', (tester) async {
      final result = await parse(tester, '# **Heading\nbody**');

      final headingSpan =
          result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Heading'));
      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(headingSpan.style!.fontSize, 28.0);
      expect(bodySpan.style!.fontSize, 14.0);
      expect(bodySpan.style!.fontWeight, FontWeight.bold);
    });

    test('mid-line hash is not a heading', () {
      final tokens = TextfParser.getCachedTokensAndPairs('use C# often').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
    });

    test('line-start hash without following space is not a heading', () {
      final tokens = TextfParser.getCachedTokensAndPairs('#Title').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
    });

    test('escaped hash is literal text', () {
      final tokens = TextfParser.getCachedTokensAndPairs(r'\# Heading').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
      expect(tokens.whereType<TextToken>().map((t) => t.value).join(), '# Heading');
    });

    test('line-start hash emits a HeadingToken with correct level', () {
      for (var level = 1; level <= 6; level++) {
        TextfParser.clearCache();
        final tokens = TextfParser.getCachedTokensAndPairs('${'#' * level} hi').tokens;
        final heading = tokens.whereType<HeadingToken>().single;
        expect(heading.level, level);
        expect(heading.length, level + 1);
      }
    });

    test('a single space is the separator; extra spaces remain (untrimmed) content', () {
      // Increment 01 consumes exactly one separator space; trimming of leading
      // content whitespace arrives in increment 05.
      final tokens = TextfParser.getCachedTokensAndPairs('#   Title').tokens;
      final heading = tokens.whereType<HeadingToken>().single;
      expect(heading.level, 1);
      expect(heading.length, 2);
      expect(tokens.whereType<TextToken>().map((t) => t.value).join(), '  Title');
    });

    test('seven hashes is not a heading', () {
      final tokens = TextfParser.getCachedTokensAndPairs('####### over').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
    });

    test('stripFormatting removes heading markers but keeps content', () {
      expect(FormattingUtils.stripFormatting('# Title'), 'Title');
      // Only the single separator space is part of the marker (increment 01).
      expect(FormattingUtils.stripFormatting('#   Title'), '  Title');
      expect(FormattingUtils.stripFormatting('## Sub\nbody'), 'Sub\nbody');
    });
  });
}
