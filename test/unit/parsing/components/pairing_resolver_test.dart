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
  });
}
