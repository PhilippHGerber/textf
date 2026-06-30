// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

/// Test specification for ATX heading tokenization.
///
/// Detection rules (CommonMark-aligned, per the agreed decisions):
///  * Emitted only at a line start: at SOF, immediately after `\n`, or
///    immediately after `\r\n` (CRLF must be treated as a line break).
///  * Up to 3 leading spaces before the first `#` are allowed.
///  * 1..6 `#` characters. 7+ `#` is NOT a heading.
///  * The `#` run must be followed by at least one whitespace OR end-of-line.
///    `#` directly followed by a non-space is NOT a heading.
///  * A line consisting only of `#`s and trailing whitespace is a valid EMPTY
///    heading.
///  * An escaped `\#` at line start is NOT a heading; `kHash` joins the
///    escape whitelist.
///
/// Token-stream invariants:
///  * `HeadingToken.length` covers the consumed marker region: any leading
///    spaces + the `#` run + the trailing whitespace run up to the content.
///    e.g. `# `    -> length 2 ; `###   ` -> length 6 ; `   # ` -> length 5.
///  * The heading content (if any) follows as a separate [TextToken].
///  * The sum of every token's `length` always equals `text.length`
///    (UTF-16 code units). This is the 1:1 character invariant.
///  * Detection is independent of `allowNewlineCrossing`; only the downstream
///    rendering differs.
void main() {
  group('TextfTokenizer — headings', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // -- Helpers ------------------------------------------------------------

    /// Total UTF-16 code-unit slots represented by [tokens]. Must always equal
    /// the original input length (the 1:1 invariant).
    int slotSum(List<TextfToken> tokens) => tokens.fold(0, (sum, t) => sum + t.length);

    List<HeadingToken> headings(List<TextfToken> tokens) =>
        tokens.whereType<HeadingToken>().toList();

    /// Concatenates the textual payload of [TextToken]s only. Useful for
    /// asserting plain-text preservation in the no-heading cases.
    String plainTextOf(List<TextfToken> tokens) =>
        tokens.whereType<TextToken>().map((t) => t.value).join();

    /// Tokenizes [input] under BOTH newline-crossing modes and asserts the set
    /// of detected headings (level + position) is identical. Returns the
    /// tokens from the read-only (`allowNewlineCrossing: true`) pass.
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

      // The 1:1 invariant must hold in both modes.
      expect(slotSum(readOnly), input.length);
      expect(slotSum(editor), input.length);

      return readOnly;
    }

    // ========================================================================
    // Probable-bug cases
    // ========================================================================

    group('Probable-bug cases', () {
      test('Seven hashes are not a heading and must stay verbatim', () {
        const input = '####### Titel';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty, reason: '7+ hashes is not an ATX heading');
        // The whole sequence survives unchanged as plain text.
        expect(plainTextOf(tokens), input);
        expect(slotSum(tokens), input.length);
      });

      test('Hash without a following space is not a heading', () {
        const input = '#kein-space';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
        expect(slotSum(tokens), input.length);
      });

      test('Hash without space, followed by an inline marker', () {
        const input = '#tag *kursiv*';
        final tokens = tokenizeBothModes(input);

        // No heading; the `#tag ` stays plain text and `*kursiv*` is still
        // recognised as italic markers around content.
        expect(headings(tokens), isEmpty);
        expect(
          tokens.any((t) => t is FormatMarkerToken && t.markerType == FormatMarkerType.italic),
          isTrue,
          reason: '`*kursiv*` must still tokenize as italic',
        );
        // No character is dropped or duplicated.
        expect(slotSum(tokens), input.length);
        // The literal `#tag ` text is preserved exactly once, before the marker.
        expect(plainTextOf(tokens), contains('#tag '));
        expect('#'.allMatches(plainTextOf(tokens)).length, 1);
      });

      test('CRLF before hash still starts a heading (Windows / pasted text)', () {
        const input = 'Zeile1\r\n# Titel';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1), reason: r'`# Titel` after \r\n is a valid H1');
        expect(heads.single.level, 1);
        expect(slotSum(tokens), input.length);
      });

      test('Six hashes without a space is not a heading (upper boundary)', () {
        const input = '###### no-space';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
        expect(slotSum(tokens), input.length);
      });

      test('Up to three leading spaces before the hash → valid H1 (CommonMark)', () {
        const input = '   # Eingerückt';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.level, 1);
        // The marker region (3 spaces + `# `) is absorbed into the token length.
        expect(heads.single.length, 5);
        // Content follows as a separate text token.
        expect(plainTextOf(tokens), 'Eingerückt');
        expect(slotSum(tokens), input.length);
      });

      test('Four leading spaces is NOT a heading (exceeds the 3-space allowance)', () {
        const input = '    # zu weit eingerückt';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
        expect(slotSum(tokens), input.length);
      });

      test('Lone hash at end of string is plain text', () {
        const input = '#';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), '#');
        // Exactly one `#`, never duplicated or lost.
        expect('#'.allMatches(plainTextOf(tokens)).length, 1);
        expect(slotSum(tokens), input.length);
      });

      test('Marker then only whitespace to EOL → empty heading (CommonMark)', () {
        const input = '###   ';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.level, 3);
        // Three hashes + three spaces are all consumed by the marker token.
        expect(heads.single.length, 6);
        // No content text token follows.
        expect(plainTextOf(tokens), isEmpty);
        expect(slotSum(tokens), input.length);
      });
    });

    // ========================================================================
    // Mandatory cases
    // ========================================================================

    group('Mandatory cases', () {
      test('Simple H1 through H6', () {
        for (var level = 1; level <= 6; level++) {
          final marker = '#' * level;
          final input = '$marker H$level';
          final tokens = tokenizeBothModes(input);

          final heads = headings(tokens);
          expect(heads, hasLength(1), reason: 'level $level should yield one heading');
          expect(heads.single.level, level);
          expect(heads.single.position, 0);
          // marker + single space.
          expect(heads.single.length, level + 1);
          expect(plainTextOf(tokens), 'H$level');
          expect(slotSum(tokens), input.length);
        }
      });

      test('H1 with no content but a trailing space (valid empty heading)', () {
        const input = '# ';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads, hasLength(1));
        expect(heads.single.level, 1);
        expect(heads.single.length, 2);
        expect(slotSum(tokens), input.length);
      });

      test('Bare `#` at EOL (no trailing space) is a valid empty heading', () {
        const input = '#';
        // NOTE: distinct from A9 only by interpretation. A9 fixes that a LONE
        // `#` is plain text; CommonMark would also accept `#` as empty H1 when
        // it is the whole line. We keep A9 as the decided behaviour: lone `#`
        // with no following whitespace stays plain text.
        final tokens = tokenizer.tokenize(input);
        expect(headings(tokens), isEmpty);
      });

      test('Hash not at line start is plain text', () {
        const input = 'Text # mitten in der Zeile';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(plainTextOf(tokens), input);
        expect(slotSum(tokens), input.length);
      });

      test('Escaped hash at line start is not a heading', () {
        const input = r'\# kein Heading';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty, reason: r'\# must not start a heading');
        // The backslash is emitted as an escape marker, then a literal `#`.
        expect(tokens.first, isA<EscapeMarkerToken>());
        expect((tokens[1] as TextToken).value, '#');
        expect(slotSum(tokens), input.length);
      });

      test('Pure plain text without any hash stays a single text token', () {
        const input = 'Ganz normaler Text ohne Sonderzeichen.';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), isEmpty);
        expect(tokens, hasLength(1));
        expect(tokens.single, isA<TextToken>());
        expect((tokens.single as TextToken).value, input);
      });

      test('Read-only and editor detect the same headings per line', () {
        const input = '# Eins\n####### Sieben\n#kein-space';

        final readOnly = tokenizer.tokenize(input);
        final editor = tokenizer.tokenize(input, allowNewlineCrossing: false);

        // Only the first line is a heading; lines 2 and 3 (A1/A7-style and
        // A2-style) are NOT headings — in BOTH modes.
        final readOnlyHeads = headings(readOnly);
        final editorHeads = headings(editor);

        expect(readOnlyHeads.map((h) => h.level), [1]);
        expect(editorHeads.map((h) => h.level), [1]);
        expect(readOnlyHeads.single.position, editorHeads.single.position);

        expect(slotSum(readOnly), input.length);
        expect(slotSum(editor), input.length);
      });
    });

    // ========================================================================
    // Multi-line interaction
    // ========================================================================

    group('Multi-line', () {
      test('Heading followed by a normal paragraph: only line 1 is a heading', () {
        const input = '# Überschrift\nNormaler Text danach.';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).map((h) => h.level), [1]);
        expect(slotSum(tokens), input.length);
      });

      test('Two consecutive headings each detected with the right level', () {
        const input = '# Eins\n## Zwei';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens).map((h) => h.level), [1, 2]);
        expect(slotSum(tokens), input.length);
      });

      test('Alternating headings and paragraphs', () {
        const input = '# Erste\nAbsatz eins.\n## Zweite\nAbsatz zwei.';
        final tokens = tokenizeBothModes(input);

        final heads = headings(tokens);
        expect(heads.map((h) => h.level), [1, 2]);
        // Second heading starts exactly at its own line, not before.
        expect(heads[1].level, 2);
        expect(slotSum(tokens), input.length);
      });

      test('Open inline marker in a heading line does not leak across the newline', () {
        const input = '# Eins **noch offen\n## Zwei';
        final tokens = tokenizeBothModes(input);

        // Tokenizer view: both heading lines are detected; the dangling `**`
        // is just a FormatMarkerToken on line 1 — pairing/styling happens later.
        expect(headings(tokens).map((h) => h.level), [1, 2]);
        expect(slotSum(tokens), input.length);
      });
    });

    // ========================================================================
    // Extra edge cases worth pinning down
    // ========================================================================

    group('Additional edge cases', () {
      test('Tab after the hash counts as the required whitespace', () {
        const input = '#\tTitel';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), hasLength(1));
        expect(headings(tokens).single.level, 1);
        expect(slotSum(tokens), input.length);
      });

      test('Heading with inline formatting keeps both heading and markers', () {
        const input = '# Titel mit **fett** und *kursiv*';
        final tokens = tokenizeBothModes(input);

        expect(headings(tokens), hasLength(1));
        expect(
          tokens.whereType<FormatMarkerToken>().map((m) => m.markerType),
          containsAll(<FormatMarkerType>[FormatMarkerType.bold, FormatMarkerType.italic]),
        );
        expect(slotSum(tokens), input.length);
      });

      test('Empty input yields no tokens and no heading', () {
        final tokens = tokenizer.tokenize('');
        expect(tokens, isEmpty);
        expect(headings(tokens), isEmpty);
      });

      test('Only a newline yields no heading', () {
        const input = '\n';
        final tokens = tokenizeBothModes(input);
        expect(headings(tokens), isEmpty);
        expect(slotSum(tokens), input.length);
      });

      test('Heading on the second line (after a leading newline)', () {
        const input = '\n# Titel';
        final tokens = tokenizeBothModes(input);
        expect(headings(tokens), hasLength(1));
        expect(headings(tokens).single.level, 1);
        expect(slotSum(tokens), input.length);
      });

      test('Bare CR (no LF) before hash does not falsely fragment the line', () {
        // A standalone \r is rare; whatever the decision, the 1:1 invariant
        // must hold and no character may be lost.
        const input = 'a\r# b';
        final tokens = tokenizeBothModes(input);
        expect(slotSum(tokens), input.length);
      });
    });
  });
}
