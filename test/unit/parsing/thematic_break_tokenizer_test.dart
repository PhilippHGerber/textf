// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

/// Test specification for thematic-break tokenization — full CommonMark
/// conformance for the construct (ticket 2). Building on the walking skeleton
/// (ticket 1), this covers:
///
///  * all three markers with whitespace permitted between them (`* * *`);
///  * up to 3 leading spaces of indentation (4+ → plain text);
///  * rejection of mixed-character lines (`- * -`), trailing content
///    (`--- foo`), and sub-3 runs (`--`);
///  * `***` (rule) vs `***bold***` (emphasis) vs `***Hello` (text) precedence;
///  * `\---` / `\***` escaping to literal text.
///
/// Invariants asserted here:
///  * A recognized break is one [ThematicBreakToken] spanning the whole
///    consumed line — leading indentation, the markers, and any inner/trailing
///    whitespace — stopping before the line terminator.
///  * The sum of every token's `length` equals `text.length` — the 1:1
///    character invariant.
///  * Detection is independent of `allowNewlineCrossing` (read vs edit path).
///  * Emphasis is not regressed: `***bold***` and `***Hello` are NOT breaks.
void main() {
  group('TextfTokenizer — thematic breaks (CommonMark conformance)', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // -- Helpers ------------------------------------------------------------

    int slotSum(List<TextfToken> tokens) => tokens.fold(0, (sum, t) => sum + t.length);

    List<ThematicBreakToken> breaks(List<TextfToken> tokens) =>
        tokens.whereType<ThematicBreakToken>().toList();

    String plainTextOf(List<TextfToken> tokens) =>
        tokens.whereType<TextToken>().map((t) => t.value).join();

    /// Tokenizes [input] under BOTH newline-crossing modes and asserts the set
    /// of detected breaks (position + length) is identical. Returns the tokens
    /// from the read-only (`allowNewlineCrossing: true`) pass.
    List<TextfToken> tokenizeBothModes(String input) {
      final readOnly = tokenizer.tokenize(input);
      final editor = tokenizer.tokenize(input, allowNewlineCrossing: false);

      String sig(List<TextfToken> t) => breaks(t).map((b) => '${b.position}+${b.length}').join(',');
      expect(
        sig(editor),
        sig(readOnly),
        reason: 'Thematic-break detection must be allowNewlineCrossing-independent',
      );

      expect(slotSum(readOnly), input.length);
      expect(slotSum(editor), input.length);

      return readOnly;
    }

    // ========================================================================
    // Recognition — the three markers, bare case
    // ========================================================================

    group('Recognition', () {
      test('`---`, `***`, `___` each yield a single break at column 0', () {
        for (final marker in const ['---', '***', '___']) {
          final tokens = tokenizeBothModes(marker);

          final rule = breaks(tokens).single;
          expect(rule.position, 0, reason: '"$marker" starts at column 0');
          expect(rule.length, 3, reason: '"$marker" spans all three markers');
          // The whole line is consumed; no text token remains.
          expect(tokens.whereType<TextToken>(), isEmpty);
        }
      });

      test('Runs longer than three are still a single break', () {
        const input = '-----';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        expect(rule.position, 0);
        expect(rule.length, 5);
      });

      test('Fewer than three markers is NOT a break', () {
        for (final marker in const ['--', '**', '__']) {
          final tokens = tokenizeBothModes(marker);
          expect(breaks(tokens), isEmpty, reason: '"$marker" is too short');
        }
      });
    });

    // ========================================================================
    // Whitespace between markers
    // ========================================================================

    group('Whitespace between markers', () {
      test('`* * *` and `- - -` are breaks spanning first-through-last marker', () {
        for (final input in const ['* * *', '- - -', '_ _ _']) {
          final tokens = tokenizeBothModes(input);

          final rule = breaks(tokens).single;
          expect(rule.position, 0, reason: '"$input" starts at column 0');
          expect(rule.length, 5, reason: '"$input" spans through the last marker');
          expect(tokens.whereType<TextToken>(), isEmpty);
        }
      });

      test('Extra spaces and tabs between markers are permitted', () {
        const input = '*   *\t*';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        expect(rule.position, 0);
        expect(rule.length, input.length, reason: 'the whole run is one break');
      });

      test('Trailing whitespace is consumed into the whole-line break', () {
        const input = '***   ';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        expect(rule.position, 0);
        expect(rule.length, input.length, reason: 'the whole line, including trailing ws');
        expect(tokens.whereType<TextToken>(), isEmpty, reason: 'nothing left over as text');
      });

      test('More markers with spaces (`*** ***`) is a single break', () {
        const input = '*** ***';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens).single.length, input.length);
      });
    });

    // ========================================================================
    // Indentation — up to 3 spaces
    // ========================================================================

    group('Indentation', () {
      test('1–3 leading spaces are recognized and consumed into the break', () {
        for (final indent in const [' ', '  ', '   ']) {
          final input = '$indent---';
          final tokens = tokenizeBothModes(input);

          final rule = breaks(tokens).single;
          expect(rule.position, 0, reason: 'the whole-line break begins at the line start');
          expect(rule.length, input.length, reason: 'indentation is part of the consumed line');
          expect(tokens.whereType<TextToken>(), isEmpty, reason: 'no stray indentation text');
        }
      });

      test('4 leading spaces disqualify the line', () {
        const input = '    ---';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens), isEmpty, reason: '4+ spaces is plain text');
        expect(plainTextOf(tokens), input, reason: 'the whole line stays literal');
      });

      test('Indentation is measured from the current line, not the whole string', () {
        const input = 'para\n  ***';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        // 'para\n' (5 chars) precedes; the rule owns '  ***' (indices 5..10).
        expect(rule.position, 5, reason: r'the break starts at the indentation after "para\n"');
        expect(rule.length, 5);
        expect(plainTextOf(tokens), 'para\n', reason: 'only the preceding line is text');
      });
    });

    // ========================================================================
    // Surrounding text — line membership and the 1:1 invariant
    // ========================================================================

    group('Surrounding lines', () {
      test('A break between two text lines flushes text on both sides', () {
        const input = 'a\n---\nb';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        // 'a\n' precedes; the rule spans indices 2..5; '\nb' follows.
        expect(rule.position, 2);
        expect(rule.length, 3);
        expect(plainTextOf(tokens), 'a\n\nb', reason: 'the terminator stays as text on both sides');
      });

      test('A break recognized after a CRLF line', () {
        const input = 'a\r\n---';
        final tokens = tokenizeBothModes(input);

        final rule = breaks(tokens).single;
        expect(rule.position, 3, reason: r'immediately after the \r\n');
        expect(rule.length, 3);
      });

      test('A break followed by a heading line stays independent', () {
        const input = '---\n# H';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens).single.position, 0);
        expect(tokens.whereType<HeadingToken>().single.level, 1);
      });
    });

    // ========================================================================
    // Rejection — column, mixed chars, trailing content
    // ========================================================================

    group('Rejection', () {
      test('Markers not at line start are not a break', () {
        const input = 'x ---';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens), isEmpty, reason: 'not at line start');
      });

      test('Hyphenated prose (`well-known`) is never a break', () {
        const input = 'well-known';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('Trailing content after the run is not a break', () {
        const input = '--- foo';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens), isEmpty);
      });

      test('Mixed marker characters (`- * -`) are not a break', () {
        for (final input in const ['- * -', '-*-', '_ - _', '**-']) {
          final tokens = tokenizeBothModes(input);
          expect(breaks(tokens), isEmpty, reason: '"$input" mixes marker chars');
        }
      });
    });

    // ========================================================================
    // Emphasis precedence — rule wins only for a pure marker run
    // ========================================================================

    group('Emphasis precedence', () {
      test('`***bold***` stays emphasis, not a break', () {
        const input = '***bold***';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens), isEmpty);
        expect(
          tokens.whereType<FormatMarkerToken>().map((m) => m.markerType),
          everyElement(FormatMarkerType.boldItalic),
        );
      });

      test('`***Hello` (markers then text) is not a break', () {
        const input = '***Hello';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens), isEmpty);
      });

      test('`___x___`-style triple underscore run with content is not a break', () {
        const input = '___x___';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens), isEmpty);
      });

      test('A pure `***` line still wins over emphasis', () {
        const input = '***';
        final tokens = tokenizeBothModes(input);
        expect(breaks(tokens).single.length, 3);
        expect(tokens.whereType<FormatMarkerToken>(), isEmpty);
      });
    });

    // ========================================================================
    // Escapes — `\---` / `\***` render as literal text
    // ========================================================================

    group('Escapes', () {
      test(r'`\---` escapes to the literal text `---`, no break', () {
        const input = r'\---';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens), isEmpty);
        // The escape marker consumes the backslash; the three dashes remain as
        // text, so the rendered plain text is exactly `---`.
        expect(tokens.whereType<EscapeMarkerToken>().length, 1);
        expect(plainTextOf(tokens), '---');
      });

      test(r'`\***` escapes to literal text, no break', () {
        const input = r'\***';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens), isEmpty);
        expect(tokens.whereType<EscapeMarkerToken>().length, 1);
      });

      test(r'`\-` renders as a literal hyphen mid-line', () {
        const input = r'a\-b';
        final tokens = tokenizeBothModes(input);

        expect(breaks(tokens), isEmpty);
        expect(plainTextOf(tokens), 'a-b', reason: 'the backslash is consumed');
      });
    });

    // ========================================================================
    // O(N) regression guard — fail-fast fallback stays linear
    // ========================================================================
    //
    // The whole-line thematic-break check wins over emphasis at line start but
    // bails at the first disqualifying character; a line like `***…*x` scans the
    // marker run, hits the `x`, abandons the candidate, and re-tokenizes the run
    // as emphasis/text. That is ≤2× work per line — linear overall — but a
    // careless refactor could turn the per-line rescan quadratic. This large
    // input of many long fail-fast lines locks the linear-time guarantee in:
    // O(N) finishes in milliseconds, whereas an O(N²) regression on ~200k chars
    // would blow far past the generous wall-clock bound. (Prior art: the
    // heading perf guard in `issues/pre2.0.md` and
    // `test/unit/editing/heading_span_builder_test.dart`.)
    group('O(N) fail-fast regression', () {
      test('many long `***…*x` fail-fast lines tokenize in linear time', () {
        // The regression this guards is a *per-line* rescan going quadratic, so
        // the fail-fast runs are deliberately LONG (not merely numerous): the
        // per-line cost must scale with the run length L, not L². With
        // runLength = 10_000 a per-line O(L²) blowup is ≈10¹⁰ char ops across
        // the failing lines — seconds of work, far past the bound — while the
        // linear path is a few million ops (milliseconds). A handful of genuine
        // `---` rules are interleaved to exercise the success path in the same
        // pass. (Prior art: the heading perf guard in `issues/pre2.0.md`.)
        const lineCount = 100;
        const runLength = 10000;
        final buffer = StringBuffer();
        var expectedRules = 0;
        for (var i = 0; i < lineCount; i++) {
          if (i % 10 == 0) {
            buffer.write('---'); // a real rule every tenth line
            expectedRules++;
          } else {
            buffer
              ..write('*' * runLength)
              ..write('x'); // long marker run that fails fast at the trailing `x`
          }
          buffer.write('\n');
        }
        final input = buffer.toString();

        final stopwatch = Stopwatch()..start();
        final tokens = tokenizer.tokenize(input);
        stopwatch.stop();

        // Correctness: only the interleaved `---` lines are breaks, and every
        // source character is still accounted for (1:1 slot invariant).
        expect(breaks(tokens).length, expectedRules);
        expect(slotSum(tokens), input.length);
        // A per-line (or global) O(N²) regression would run for seconds; the
        // generous bound only guards against that, not micro-timing.
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
