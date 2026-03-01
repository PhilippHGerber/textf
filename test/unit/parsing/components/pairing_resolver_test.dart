import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/components/pairing_resolver.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('PairingResolver', () {
    // ignore: avoid-late-keyword
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    /// Tokenizes [text], runs [PairingResolver.identifyPairs], and returns
    /// the surviving pairs as a set of `"opener -> closer"` strings (each
    /// pair represented once, from the lower index to the higher).
    Set<String> resolvedPairs(String text) {
      final tokens = tokenizer.tokenize(text);
      final pairs = PairingResolver.identifyPairs(tokens);
      final result = <String>{};
      pairs.forEach((key, value) {
        if (key < value) {
          result.add(
            '${(tokens[key] as FormatMarkerToken).value}'
            ' -> '
            '${(tokens[value] as FormatMarkerToken).value}',
          );
        }
      });
      return result;
    }

    group('no code spans', () {
      test('non-code pairs survive unaffected', () {
        expect(resolvedPairs('*text* **bold**'), {'* -> *', '** -> **'});
      });

      test('single pair survives', () {
        expect(resolvedPairs('~~strike~~'), {'~~ -> ~~'});
      });
    });

    group('code span not involved in crossing', () {
      test('non-code pair wrapping a code span both survive', () {
        // *text `code` more* — italic wraps the code span, no crossing.
        expect(resolvedPairs('*text `code` more*'), {'* -> *', '` -> `'});
      });

      test('non-code pair adjacent to code span both survive', () {
        // *italic* `code` — no crossing.
        expect(resolvedPairs('*italic* `code`'), {'* -> *', '` -> `'});
      });

      test('stray unpaired marker inside code span leaves code pair intact', () {
        // `E=m*c` — the * inside is unpaired, code pair is fine.
        expect(resolvedPairs('`E=m*c`'), {'` -> `'});
      });
    });

    group('code-span boundary crossing (M-6 regression cases)', () {
      test('opening marker before code, same-type closing marker inside code', () {
        // *text `start* end` — italic closes inside the code span → crossing.
        // Only the code pair survives.
        expect(resolvedPairs('*text `start* end`'), {'` -> `'});
      });

      test('opening marker inside code, same-type closing marker after code', () {
        // `start *end` more* — italic opens inside the code span → crossing.
        // Only the code pair survives.
        expect(resolvedPairs('`start *end` more*'), {'` -> `'});
      });

      test('TODO bug case: outer marker paired with inner marker across code span', () {
        // *text `E=m*c` more*
        // Simple pairing gives italic(0,4) and code(2,6).
        // italic(0,4) crosses the code span → remove it.
        // Only the code pair survives.
        expect(resolvedPairs('*text `E=m*c` more*'), {'` -> `'});
      });

      test('crossing pair removal does not affect unrelated pairs outside code', () {
        // **bold** *text `E=m*c` more* ~~strike~~
        // The italic crossing the code span is removed;
        // bold and strikethrough are untouched.
        expect(
          resolvedPairs('**bold** *text `E=m*c` more* ~~strike~~'),
          {'** -> **', '` -> `', '~~ -> ~~'},
        );
      });
    });

    group('non-code pairs interior to a code span', () {
      test('italic pair entirely inside code span is removed', () {
        // `text *italic* more` — italic pair is interior → removed.
        expect(resolvedPairs('`text *italic* more`'), {'` -> `'});
      });

      test('multiple interior pairs inside code span are all removed', () {
        // `*bold* and **more**` — both non-code pairs are interior → removed.
        expect(resolvedPairs('`*bold* and **more**`'), {'` -> `'});
      });
    });

    group('allowNewlineCrossing: false (editing controller path)', () {
      /// Like [resolvedPairs] but with cross-line pairing disabled.
      Set<String> resolvedPairsNoNewline(String text) {
        final tokens = tokenizer.tokenize(text);
        final pairs = PairingResolver.identifyPairs(tokens, allowNewlineCrossing: false);
        final result = <String>{};
        pairs.forEach((key, value) {
          if (key < value) {
            result.add(
              '${(tokens[key] as FormatMarkerToken).value}'
              ' -> '
              '${(tokens[value] as FormatMarkerToken).value}',
            );
          }
        });
        return result;
      }

      test('cross-line superscript pairing is prevented', () {
        // x^2\nmath x^2^ — the ^ on line 1 must not pair with the ^ on line 2.
        // Expected: line 2's ^2^ pair survives; line 1's ^ is unpaired.
        expect(resolvedPairsNoNewline('x^2\nmath x^2^'), {'^ -> ^'});
      });

      test('same-line superscript pairing still works', () {
        expect(resolvedPairsNoNewline('x^2^ is a formula'), {'^ -> ^'});
      });

      test('bold markers across lines do not pair', () {
        expect(resolvedPairsNoNewline('Hello **world\nand bold** here'), isEmpty);
      });

      test('independent same-line pairs on consecutive lines both survive', () {
        // x^2^ and y^3^\na^2^ and b^3^ — two pairs per line, all same-line.
        expect(
          resolvedPairsNoNewline('x^2^ and y^3^\na^2^ and b^3^'),
          {'^ -> ^'},
        );
      });

      test('single-line formatting unaffected — control case', () {
        expect(resolvedPairsNoNewline('E = mc^2^'), {'^ -> ^'});
      });

      test('default allowNewlineCrossing: true still allows cross-line pairs', () {
        // Confirm the display widget path is unaffected.
        expect(resolvedPairs('Hello **world\nand bold** here'), {'** -> **'});
      });
    });

    group('flanking rules', () {
      test('bullet asterisk produces no pairs', () {
        // '* Item' — * has canOpen=false (space follows) and canClose=false (SOF)
        expect(resolvedPairs('* Item'), isEmpty);
      });

      test('math expression asterisks produce no pairs', () {
        // '2 * 3 * 4' — both * are flanked by spaces on both sides
        expect(resolvedPairs('2 * 3 * 4'), isEmpty);
      });

      test('bug case: bullet does not pair with inner italic marker', () {
        // '* ==*NEW*==' — the bullet * at pos 0 has canOpen=false,
        // so only the inner *NEW* and the == markers form pairs.
        expect(resolvedPairs('* ==*NEW*=='), {'== -> ==', '* -> *'});
      });

      test('loose markers with surrounding spaces produce no pairs', () {
        // '* loose italic *' — both * are flanked by spaces
        expect(resolvedPairs('* loose italic *'), isEmpty);
      });

      test('tight italic still pairs normally', () {
        expect(resolvedPairs('*tight*'), {'* -> *'});
      });

      test('tight bold still pairs normally', () {
        expect(resolvedPairs('**bold**'), {'** -> **'});
      });

      test('subscript in non-whitespace context still pairs', () {
        // 'H~2~O' — both ~ have non-whitespace neighbors
        expect(resolvedPairs('H~2~O'), {'~ -> ~'});
      });
    });
  });
}
