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

    test('leading content whitespace folds into the opening region (increment 05)', () {
      // Increment 05 trims leading spaces/tabs: the whole `#   ` run is consumed
      // and only `Title` remains as content.
      final tokens = TextfParser.getCachedTokensAndPairs('#   Title').tokens;
      final heading = tokens.whereType<HeadingToken>().single;
      expect(heading.level, 1);
      expect(heading.length, 4, reason: 'hash + three leading spaces');
      expect(heading.contentStart, 4);
      expect(tokens.whereType<TextToken>().map((t) => t.value).join(), 'Title');
    });

    test('seven hashes is not a heading', () {
      final tokens = TextfParser.getCachedTokensAndPairs('####### over').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
    });

    test('stripFormatting removes heading markers but keeps content', () {
      expect(FormattingUtils.stripFormatting('# Title'), 'Title');
      // Leading content whitespace folds into the marker (increment 05 trim).
      expect(FormattingUtils.stripFormatting('#   Title'), 'Title');
      expect(FormattingUtils.stripFormatting('## Sub\nbody'), 'Sub\nbody');
    });

    testWidgets('up to 3 leading spaces still produce a heading (increment 03)', (tester) async {
      for (final indent in <int>[0, 1, 2, 3]) {
        TextfParser.clearCache();
        final result = await parse(tester, '${' ' * indent}# Title');
        final textSpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Title'));
        expect(textSpan.style!.fontSize, 28.0, reason: 'indent $indent');
      }
    });

    test('4 leading spaces disqualify the line as a heading', () {
      final tokens = TextfParser.getCachedTokensAndPairs('    # Title').tokens;
      expect(tokens.whereType<HeadingToken>(), isEmpty);
      expect(tokens.whereType<TextToken>().map((t) => t.value).join(), '    # Title');
    });

    test('stripFormatting strips indentation along with the marker', () {
      expect(FormattingUtils.stripFormatting('   # Title'), 'Title');
      expect(FormattingUtils.stripFormatting('    # Title'), '    # Title');
    });

    // Increment 04 — empty headings.
    testWidgets('lone `#` at EOF renders no visible content (increment 04)', (tester) async {
      final result = await parse(tester, '#');

      // No content means no span is flushed at all — the heading is visually
      // empty, matching the acceptance criterion.
      expect(result, isEmpty);
    });

    test('lone `#` at EOF emits a HeadingToken with empty content', () {
      final tokens = TextfParser.getCachedTokensAndPairs('#').tokens;
      final heading = tokens.whereType<HeadingToken>().single;
      expect(heading.level, 1);
      expect(heading.contentStart, heading.contentEnd);
      expect(tokens.whereType<TextToken>(), isEmpty);
    });

    testWidgets('`## ` (trailing space only) renders no visible content (increment 04)',
        (tester) async {
      final result = await parse(tester, '## ');

      expect(result, isEmpty);
    });

    testWidgets('empty heading followed by a paragraph does not leak heading style',
        (tester) async {
      final result = await parse(tester, '#\nbody');

      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(bodySpan.style!.fontSize, 14.0);
    });

    test('stripFormatting on an empty heading yields empty text', () {
      expect(FormattingUtils.stripFormatting('#'), isEmpty);
      expect(FormattingUtils.stripFormatting('## '), isEmpty);
    });

    // Increment 05 — closing run + content trimming.
    String visibleText(List<InlineSpan> spans) =>
        spans.whereType<TextSpan>().map((s) => s.text ?? '').join();

    testWidgets('`## foo ##` renders `foo` and omits the closing run', (tester) async {
      final result = await parse(tester, '## foo ##');

      expect(visibleText(result), 'foo');
      final span = result.whereType<TextSpan>().firstWhere((s) => s.text == 'foo');
      expect(span.style!.fontSize, 21.0, reason: 'H2 sizing on the content');
    });

    testWidgets('leading and trailing whitespace is trimmed (`#   foo   `)', (tester) async {
      final result = await parse(tester, '#   foo   ');

      expect(visibleText(result), 'foo');
    });

    testWidgets('`### ###` renders no visible content', (tester) async {
      final result = await parse(tester, '### ###');

      expect(result.whereType<TextSpan>().where((s) => (s.text ?? '').isNotEmpty), isEmpty);
    });

    testWidgets('`# foo#` keeps the glued hash as content', (tester) async {
      final result = await parse(tester, '# foo#');

      expect(visibleText(result), 'foo#');
    });

    testWidgets(r'escaped closing run `### foo \###` renders `foo ###`', (tester) async {
      final result = await parse(tester, r'### foo \###');

      expect(visibleText(result), 'foo ###');
    });

    testWidgets('closing run does not leak heading style past the newline', (tester) async {
      final result = await parse(tester, '## foo ##\nbody');

      final bodySpan = result.whereType<TextSpan>().firstWhere((s) => s.text!.contains('body'));
      expect(bodySpan.style!.fontSize, 14.0);
    });

    test('stripFormatting drops the closing run and trims content', () {
      expect(FormattingUtils.stripFormatting('## foo ##'), 'foo');
      expect(FormattingUtils.stripFormatting('#   foo   '), 'foo');
      expect(FormattingUtils.stripFormatting('### ###'), isEmpty);
    });
  });
}
