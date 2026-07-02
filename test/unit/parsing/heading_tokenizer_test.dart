// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

/// Test specification for ATX heading tokenization — **increment 01**
/// (walking skeleton). Scope is intentionally narrow:
///
///  * Column 0 only (line start = string start or immediately after `\n`).
///  * A single `U+0020` space separator only.
///
/// Deferred to later increments (each has its own conformance cases):
///  * tab separator + lone-`\r`/`\r\n` line starts  → increment 02 (done)
///  * 0–3 leading spaces of indentation             → increment 03 (done)
///  * empty heading from a separator-less `#`        → increment 04 (done)
///  * closing `#` run + leading/trailing trimming    → increment 05
///
/// Recognition rules exercised here:
///  * Emitted at a line start: at SOF or immediately after `\n`.
///  * 1..6 `#` characters. 7+ `#` is NOT a heading and stays verbatim.
///  * The `#` run must be followed by a single space. `#` directly followed by
///    a non-space (or end of line) is NOT a heading in this increment.
///  * An escaped `\#` at line start is NOT a heading.
///
/// Enriched-token invariants (FR Option A):
///  * [HeadingToken.length] covers the consumed opening region
///    `[position, contentStart)` = the `#` run + the single separator space.
///  * [HeadingToken.contentStart] is the first content character.
///  * [HeadingToken.contentEnd] / [HeadingToken.lineEndPosition] are
///    back-patched to the line terminator (or `text.length`) in the same pass.
///  * The sum of every token's `length` always equals `text.length` (UTF-16
///    code units) — the 1:1 character invariant.
///  * Detection is independent of `allowNewlineCrossing`.
void main() {
  group('TextfTokenizer — headings (increment 01)', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // -- Helpers ------------------------------------------------------------

    int slotSum(List<TextfToken> tokens) => tokens.fold(0, (sum, t) => sum + t.length);

    List<HeadingToken> headings(List<TextfToken> tokens) =>
        tokens.whereType<HeadingToken>().toList();

    String plainTextOf(List<TextfToken> tokens) =>
        tokens.whereType<TextToken>().map((t) => t.value).join();

    /// Tokenizes [input] under BOTH newline-crossing modes and asserts the set
    /// of detected headings (level + position) is identical. Returns the tokens
    /// from the read-only (`allowNewlineCrossing: true`) pass.
    List<TextfToken> tokenizeBothModes(String input) {
      final readOnly = tokenizer.tokenize(input);
      final editor = tokenizer.tokenize(input, allowNewlineCrossing: false);

      final readOnlyHeads = headings(readOnly).map((h) => '${h.level}@${h.position}').toList();
      final editorHeads = headings(editor).map((h) => '${h.level}@${h.position}').toList();
      expect(
        editorHeads,
        readOnlyHeads,
        reason: 'Heading detection must be allowNewlineCrossing-independent',
      );

      expect(slotSum(readOnly), input.length);
      expect(slotSum(editor), input.length);

      return readOnly;
    }

    // ========================================================================
    // Recognition — levels and boundaries
    // ========================================================================

    group('Recognition', () {
      test('Simple H1 through H6 with a single-space separator', () {
        for (var level = 1; level <= 6; level++) {
          final marker = '#' * level;
          final input = '$marker H$level';
          final tokens = tokenizeBothModes(input);

          final heads = headings(tokens);
          expect(heads, hasLength(1), reason: 'level $level should yield one heading');

          final heading = heads.single;
          expect(heading.level, level);
          expect(heading.position, 0);
          // Opening region = '#'*level + one space.
          expect(heading.length, level + 1);
          expect(heading.contentStart, level + 1);
          // No newline: content runs to EOF, back-patched to text.length.
          expect(heading.contentEnd, input.length);
          expect(heading.lineEndPosition, input.length);
          expect(plainTextOf(tokens), 'H$level');
        }
      });

      test('Seven hashes are not a heading and stay verbatim', () {
        const input = '####### Title';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty, reason: '7+ hashes is not an ATX heading');
        expect(plainTextOf(tokens), input);
      });

      test('Six hashes is the upper boundary (still a heading)', () {
        const input = '###### H6';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).single.level, 6);
        expect(plainTextOf(tokens), 'H6');
      });

      test('Hash with no following space is not a heading', () {
        const input = '#no-space';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('Six hashes with no following space is not a heading', () {
        const input = '######no-space';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('Lone hash at end of string is an empty heading (increment 04)', () {
        const input = '#';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 1);
        expect(heading.contentStart, 1);
        expect(heading.contentEnd, 1);
        expect(plainTextOf(tokens), isEmpty);
      });

      test('Hash + trailing space with empty content is a heading (region only)', () {
        const input = '# ';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 2);
        expect(heading.contentStart, 2);
        expect(heading.contentEnd, 2);
        expect(plainTextOf(tokens), isEmpty);
      });

      test('Leading content whitespace folds into the opening region (increment 05)', () {
        // Increment 05 trims leading spaces/tabs; the whole `#   ` run is the
        // consumed opening region and only `Title` remains as content.
        const input = '#   Title';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 4, reason: 'one hash + three leading spaces');
        expect(heading.contentStart, 4);
        expect(plainTextOf(tokens), 'Title');
      });

      test('Hash not at line start is plain text', () {
        const input = 'Text # in the middle of the line';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('Escaped hash at line start is not a heading', () {
        const input = r'\# not a heading';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty, reason: r'\# must not start a heading');
        expect(tokens.first, isA<EscapeMarkerToken>());
        expect((tokens[1] as TextToken).value, '#');
      });

      test('Pure plain text without any hash stays a single text token', () {
        const input = 'Just plain text without any special characters.';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(tokens, hasLength(1));
        expect((tokens.single as TextToken).value, input);
      });
    });

    // ========================================================================
    // Enriched token — line-end back-patch
    // ========================================================================

    group('lineEndPosition back-patch', () {
      test('Heading followed by a newline: line end is the terminator index', () {
        const input = '# Heading\nbody';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentStart, 2);
        // '\n' is at index 9.
        expect(heading.contentEnd, 9);
        expect(heading.lineEndPosition, 9);
      });

      test('Heading at EOF: line end is text.length', () {
        const input = '# Heading';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.lineEndPosition, input.length);
        expect(heading.contentEnd, input.length);
      });

      test('CRLF before a hash still starts a heading (line break ends with LF)', () {
        const input = 'Line1\r\n# Title';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads.single.level, 1);
        // The heading begins right after the \r\n (index 7).
        expect(heads.single.position, 7);
      });
    });

    // ========================================================================
    // Multi-line interaction
    // ========================================================================

    group('Multi-line', () {
      test('Heading followed by a normal paragraph: only line 1 is a heading', () {
        const input = '# Heading\nNormal text afterwards.';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).map((h) => h.level), [1]);
      });

      test('Two consecutive headings each detected with the right level', () {
        const input = '# One\n## Two';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads.map((h) => h.level), [1, 2]);
        // First heading's line ends at the '\n' (index 5); second runs to EOF.
        expect(heads.first.lineEndPosition, 5);
        expect(heads[1].lineEndPosition, input.length);
      });

      test('Alternating headings and paragraphs', () {
        const input = '# First\nParagraph one.\n## Second\nParagraph two.';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).map((h) => h.level), [1, 2]);
      });

      test('Open inline marker in a heading line does not affect detection', () {
        const input = '# One **still open\n## Two';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).map((h) => h.level), [1, 2]);
      });

      test('Heading with inline formatting keeps both heading and markers', () {
        const input = '# Title with **bold** and *italic*';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), hasLength(1));
        expect(
          tokens.whereType<FormatMarkerToken>().map((m) => m.markerType),
          containsAll(<FormatMarkerType>[FormatMarkerType.bold, FormatMarkerType.italic]),
        );
      });

      test('Heading on the second line (after a leading newline)', () {
        const input = '\n# Title';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).single.level, 1);
        expect(headings(tokens).single.position, 1);
      });
    });

    // ========================================================================
    // Degenerate inputs
    // ========================================================================

    group('Degenerate inputs', () {
      test('Empty input yields no tokens and no heading', () {
        final tokens = tokenizer.tokenize('');
        expect(tokens, isEmpty);
      });

      test('Only a newline yields no heading', () {
        const input = '\n';
        final tokens = tokenizeBothModes(input);
        expect(headings(tokens), isEmpty);
      });

      test('Bare CR (no LF) before hash preserves the 1:1 invariant', () {
        const input = 'a\r# b';
        final tokens = tokenizeBothModes(input);
        expect(slotSum(tokens), input.length);
      });
    });

    // ========================================================================
    // Increment 02 — tab separator + CRLF / lone-CR line starts
    // ========================================================================

    group('Increment 02 — tab separator', () {
      test('A tab after the # run is a valid separator', () {
        const input = '#\tTitle';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 2, reason: 'one hash + one separator tab');
        expect(heading.contentStart, 2);
        expect(plainTextOf(tokens), 'Title');
      });

      test('Tab separator works at every level', () {
        for (var level = 1; level <= 6; level++) {
          final input = '${'#' * level}\tH$level';
          final tokens = tokenizeBothModes(input);
          expect(headings(tokens).single.level, level, reason: 'level $level');
        }
      });
    });

    group('Increment 02 — lone CR line start', () {
      test('A lone CR (not followed by LF) starts a new line', () {
        const input = 'Line1\r# Title';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.position, 6);
      });

      test('A heading can begin the string itself (SOF), unaffected by CR support', () {
        const input = '# Title';
        final tokens = tokenizeBothModes(input);
        expect(headings(tokens).single.position, 0);
      });
    });

    group('Increment 02 — line-terminator back-patch excludes the terminator', () {
      test('LF-terminated heading: lineEndPosition is the LF index (unchanged behavior)', () {
        const input = '# Title\nBody';
        final tokens = tokenizeBothModes(input);
        final heading = headings(tokens).single;
        // '\n' is at index 7.
        expect(heading.contentEnd, 7);
        expect(heading.lineEndPosition, 7);
      });

      test('CRLF-terminated heading: lineEndPosition is the CR index, not the LF index', () {
        const input = '# Title\r\nBody';
        final tokens = tokenizeBothModes(input);
        final heading = headings(tokens).single;
        // '\r' is at index 7, '\n' at index 8. The CR starts the terminator.
        expect(heading.contentEnd, 7);
        expect(heading.lineEndPosition, 7);
      });

      test('Lone-CR-terminated heading: lineEndPosition is the CR index', () {
        const input = '# Title\rBody';
        final tokens = tokenizeBothModes(input);
        final heading = headings(tokens).single;
        expect(heading.contentEnd, 7);
        expect(heading.lineEndPosition, 7);
      });

      test('Two headings separated by CRLF: both back-patched correctly', () {
        const input = '# One\r\n## Two';
        final tokens = tokenizeBothModes(input);
        final heads = headings(tokens);
        expect(heads.map((h) => h.level), [1, 2]);
        // '# One' ends at the '\r' (index 5); '## Two' starts right after the
        // '\r\n' (index 7) and runs to EOF.
        expect(heads.first.lineEndPosition, 5);
        expect(heads[1].position, 7);
        expect(heads[1].lineEndPosition, input.length);
      });
    });

    // ========================================================================
    // Increment 03 — up to three-space indentation
    // ========================================================================

    group('Increment 03 — up to three-space indentation', () {
      test('0/1/2/3 leading spaces are recognized at the correct level', () {
        for (var indent = 0; indent <= 3; indent++) {
          final input = '${' ' * indent}### foo';
          final tokens = tokenizeBothModes(input);

          final heads = headings(tokens);
          expect(heads, hasLength(1), reason: 'indent $indent should yield one heading');
          expect(heads.single.level, 3);
          // The heading's consumed region starts at the FIRST leading space (or
          // the `#` itself when indent is 0), so the indentation folds into it.
          expect(heads.single.position, 0);
          expect(heads.single.length, indent + 4, reason: '$indent spaces + "### "');
          expect(heads.single.contentStart, indent + 4);
          expect(plainTextOf(tokens), 'foo');
        }
      });

      test('4 leading spaces disqualify the line as a heading', () {
        const input = '    # foo';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty, reason: '4+ leading spaces is not a heading');
        expect(plainTextOf(tokens), input);
      });

      test('5 leading spaces also disqualify the line as a heading', () {
        const input = '     # foo';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('Indentation folds into the consumed opening region (1:1 invariant)', () {
        const input = '   # Indented';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.position, 0);
        expect(heading.length, 5, reason: '3 spaces + "# "');
        expect(heading.contentStart, 5);
        expect(plainTextOf(tokens), 'Indented');
        expect(slotSum(tokens), input.length);
      });

      test('Indentation after a newline is recognized on the second line', () {
        const input = 'Para\n   ## Sub';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.level, 2);
        // Heading region starts right after the '\n' (index 5), not at the '#'.
        expect(heads.single.position, 5);
      });

      test('Indentation with a tab separator', () {
        const input = '  #\tTabbed';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 4, reason: '2 spaces + "#" + tab');
        expect(plainTextOf(tokens), 'Tabbed');
      });

      test('4-space indent still allows a heading later on the SAME line to matter only per-line',
          () {
        // The disqualified line is plain text; a following well-formed heading
        // line is unaffected.
        const input = '    # not a heading\n# real heading';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.level, 1);
        expect(heads.single.position, 20);
      });
    });

    // ========================================================================
    // Increment 04 — empty headings
    // ========================================================================

    group('Increment 04 — empty headings', () {
      test('Lone `#` at EOF is an empty H1 (end of line is a valid separator)', () {
        const input = '#';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.length, 1, reason: 'just the hash — no separator character to consume');
        expect(heading.contentStart, 1);
        expect(heading.contentEnd, 1);
        expect(plainTextOf(tokens), isEmpty);
      });

      test('Lone `#` followed by a newline is an empty H1', () {
        const input = '#\nbody';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.contentStart, 1);
        expect(heading.contentEnd, 1, reason: 'content ends right before the newline');
        expect(heading.lineEndPosition, 1);
        expect(plainTextOf(tokens), '\nbody');
      });

      test('Lone `#` followed by a lone CR is an empty H1', () {
        const input = '#\rbody';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentStart, 1);
        expect(heading.contentEnd, 1);
        expect(heading.lineEndPosition, 1);
      });

      test('Lone `#` followed by CRLF is an empty H1', () {
        const input = '#\r\nbody';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentStart, 1);
        expect(heading.contentEnd, 1);
        expect(heading.lineEndPosition, 1);
      });

      test('Every level alone at EOF is an empty heading of that level', () {
        for (var level = 1; level <= 6; level++) {
          final input = '#' * level;
          final tokens = tokenizeBothModes(input);

          final heading = headings(tokens).single;
          expect(heading.level, level, reason: 'level $level');
          expect(heading.contentStart, level);
          expect(heading.contentEnd, level);
        }
      });

      test('7+ hashes alone at EOF is still not a heading', () {
        const input = '#######';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
      });

      test('`## ` (trailing space only) is an empty H2', () {
        const input = '## ';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 2);
        expect(heading.length, 3, reason: '2 hashes + 1 separator space');
        expect(heading.contentStart, 3);
        expect(heading.contentEnd, 3);
        expect(plainTextOf(tokens), isEmpty);
      });

      test('Indented lone `#` at EOF is still an empty heading (increment 03 interaction)', () {
        const input = '  #';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 1);
        expect(heading.position, 0);
        expect(heading.length, 3, reason: '2 spaces + the hash');
        expect(heading.contentStart, 3);
        expect(heading.contentEnd, 3);
        expect(plainTextOf(tokens), isEmpty);
      });

      test('Two consecutive empty headings, both back-patched correctly', () {
        const input = '#\n##';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads.map((h) => h.level), [1, 2]);
        expect(heads.first.contentEnd, 1);
        expect(heads.first.lineEndPosition, 1);
        expect(heads[1].position, 2);
        expect(heads[1].contentStart, 4);
        expect(heads[1].contentEnd, 4);
        expect(heads[1].lineEndPosition, input.length);
      });
    });

    // ========================================================================
    // Increment 05 — closing '#' run and content trimming
    // ========================================================================

    group('Increment 05 — closing run and content trimming', () {
      List<HeadingSuffixToken> suffixes(List<TextfToken> tokens) =>
          tokens.whereType<HeadingSuffixToken>().toList();

      test('`## foo ##` trims the closing run into a suffix token', () {
        const input = '## foo ##';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 2);
        expect(heading.contentStart, 3);
        expect(heading.contentEnd, 6, reason: 'content is `foo`');
        expect(plainTextOf(tokens), 'foo');

        final suffix = suffixes(tokens).single;
        expect(suffix.position, 6);
        expect(suffix.length, 3, reason: 'the ` ##` trailing region');
        expect(suffix.headingStart, 0);
        expect(suffix.lineEndPosition, input.length);
      });

      test('Closing run is length-independent (`# foo ##########`)', () {
        const input = '# foo ##########';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentEnd, 5, reason: 'content is still `foo`');
        expect(plainTextOf(tokens), 'foo');
        // Space + ten hashes are one suffix region.
        expect(suffixes(tokens).single.length, 11);
      });

      test('`# foo#` keeps `foo#` — closing run must be blank-preceded', () {
        const input = '# foo#';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentEnd, input.length);
        expect(plainTextOf(tokens), 'foo#');
        expect(suffixes(tokens), isEmpty);
      });

      test(r'`### foo \###` keeps `foo ###` — escaped `#` does not close', () {
        const input = r'### foo \###';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentEnd, input.length, reason: 'no closing run stripped');
        // Escape strips the backslash; the three hashes remain content.
        expect(plainTextOf(tokens), 'foo ###');
        expect(suffixes(tokens), isEmpty);
      });

      test('`### foo ### b` keeps `foo ### b` — non-blank after the run', () {
        const input = '### foo ### b';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).single.contentEnd, input.length);
        expect(plainTextOf(tokens), 'foo ### b');
        expect(suffixes(tokens), isEmpty);
      });

      test('Leading and trailing spaces are trimmed (`#   foo   `)', () {
        const input = '#   foo   ';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        // Leading `#   ` folds into the opening region.
        expect(heading.length, 4);
        expect(heading.contentStart, 4);
        expect(heading.contentEnd, 7, reason: 'content is `foo`');
        expect(plainTextOf(tokens), 'foo');
        // Trailing spaces (no closing run) are their own suffix region.
        expect(suffixes(tokens).single.length, 3);
      });

      test('`### ###` is an empty heading with the closing run as suffix', () {
        const input = '### ###';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.level, 3);
        expect(heading.contentStart, 4);
        expect(heading.contentEnd, 4, reason: 'empty content');
        expect(plainTextOf(tokens), isEmpty);

        final suffix = suffixes(tokens).single;
        expect(suffix.position, 4);
        expect(suffix.length, 3, reason: 'the closing `###`');
      });

      test('Closing run followed by trailing spaces (`# foo ##  `)', () {
        const input = '# foo ##  ';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentEnd, 5, reason: 'content is `foo`');
        expect(plainTextOf(tokens), 'foo');
        // ` ##  ` — the space, run, and trailing spaces are one suffix region.
        expect(suffixes(tokens).single.length, 5);
      });

      test('Suffix region is excluded before a newline, terminator preserved', () {
        const input = '# foo ##\nbody';
        final tokens = tokenizeBothModes(input);

        final heading = headings(tokens).single;
        expect(heading.contentEnd, 5);
        expect(heading.lineEndPosition, 8, reason: r'the `\n` index');
        expect(suffixes(tokens).single.length, 3);
        // The newline and body resume as ordinary text.
        expect(plainTextOf(tokens), 'foo\nbody');
      });

      test('Tab-preceded closing run and tab trimming', () {
        const input = '#\tfoo\t##';
        final tokens = tokenizeBothModes(input);

        expect(plainTextOf(tokens), 'foo');
        expect(suffixes(tokens).single.length, 3, reason: 'tab + `##`');
      });
    });
  });
}
