import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/components/pair_validator.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('PairValidator', () {
    // ignore: avoid-late-keyword
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    /// Tokenizes [text], runs [PairValidator.identifyPairs], and returns
    /// the surviving pairs as a set of `"opener -> closer"` strings (each
    /// pair represented once, from the lower index to the higher).
    Set<String> resolvedPairs(String text) {
      final tokens = tokenizer.tokenize(text);
      final pairs = PairValidator.identifyPairs(tokens);
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

    // -------------------------------------------------------------------------
    // Code-boundary crossing removal
    // -------------------------------------------------------------------------

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
        expect(resolvedPairs('*text `code` more*'), {'* -> *', '` -> `'});
      });

      test('non-code pair adjacent to code span both survive', () {
        expect(resolvedPairs('*italic* `code`'), {'* -> *', '` -> `'});
      });

      test('stray unpaired marker inside code span leaves code pair intact', () {
        expect(resolvedPairs('`E=m*c`'), {'` -> `'});
      });
    });

    group('code-span boundary crossing (M-6 regression cases)', () {
      test('opening marker before code, same-type closing marker inside code', () {
        expect(resolvedPairs('*text `start* end`'), {'` -> `'});
      });

      test('opening marker inside code, same-type closing marker after code', () {
        expect(resolvedPairs('`start *end` more*'), {'` -> `'});
      });

      test('outer marker paired with inner marker across code span', () {
        expect(resolvedPairs('*text `E=m*c` more*'), {'` -> `'});
      });

      test('crossing pair removal does not affect unrelated pairs outside code', () {
        expect(
          resolvedPairs('**bold** *text `E=m*c` more* ~~strike~~'),
          {'** -> **', '` -> `', '~~ -> ~~'},
        );
      });
    });

    group('non-code pairs interior to a code span', () {
      test('italic pair entirely inside code span is removed', () {
        expect(resolvedPairs('`text *italic* more`'), {'` -> `'});
      });

      test('multiple interior pairs inside code span are all removed', () {
        expect(resolvedPairs('`*bold* and **more**`'), {'` -> `'});
      });
    });

    // -------------------------------------------------------------------------
    // Newline-crossing rejection
    // -------------------------------------------------------------------------

    group('allowNewlineCrossing: false (editing controller path)', () {
      Set<String> noNewline(String text) {
        final tokens = tokenizer.tokenize(text);
        final pairs = PairValidator.identifyPairs(tokens, allowNewlineCrossing: false);
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
        expect(noNewline('x^2\nmath x^2^'), {'^ -> ^'});
      });

      test('same-line superscript pairing still works', () {
        expect(noNewline('x^2^ is a formula'), {'^ -> ^'});
      });

      test('bold markers across lines do not pair', () {
        expect(noNewline('Hello **world\nand bold** here'), isEmpty);
      });

      test('independent same-line pairs on consecutive lines both survive', () {
        expect(noNewline('x^2^ and y^3^\na^2^ and b^3^'), {'^ -> ^'});
      });

      test('single-line formatting unaffected — control case', () {
        expect(noNewline('E = mc^2^'), {'^ -> ^'});
      });

      test('default allowNewlineCrossing: true still allows cross-line pairs', () {
        expect(resolvedPairs('Hello **world\nand bold** here'), {'** -> **'});
      });
    });

    // -------------------------------------------------------------------------
    // Improper nesting rejection
    // -------------------------------------------------------------------------

    group('improper nesting', () {
      test('overlapping markers are both rejected', () {
        // **bold *and italic** is wrong*
        expect(resolvedPairs('**bold *and italic** is wrong*'), isEmpty);
      });

      test('overlapping markers of different types are both rejected', () {
        expect(resolvedPairs('~~strike with **bold~~ inner**'), isEmpty);
      });

      test('correctly nested different markers both survive', () {
        expect(resolvedPairs('**bold with _italic_**'), {'** -> **', '_ -> _'});
      });

      test('adjacent markers all survive', () {
        expect(resolvedPairs('**bold**_italic_`code`'), {'** -> **', '_ -> _', '` -> `'});
      });

      test('correctly nested same-character markers both survive', () {
        // closing __ must not have a space immediately before it
        expect(resolvedPairs('__bold with _italic_ end__'), {'__ -> __', '_ -> _'});
      });
    });

    // -------------------------------------------------------------------------
    // Maximum depth enforcement
    // -------------------------------------------------------------------------

    group('nesting depth limit', () {
      test('third-level pair is rejected, outer two survive', () {
        // Level 1: **, Level 2: _, Level 3: ~~ (rejected)
        expect(
          resolvedPairs('**level1 _level2 ~~level3~~_**'),
          {'** -> **', '_ -> _'},
        );
      });

      test('two siblings at depth 2 both survive', () {
        expect(
          resolvedPairs('**bold _italic_ and `code`**'),
          {'** -> **', '_ -> _', '` -> `'},
        );
      });

      test('only the deepest pair is invalidated in a four-level chain', () {
        // Level 1: **, Level 2: _, Level 3: ~~, Level 4: ` (rejected)
        expect(resolvedPairs('**_~~`code`~~_**'), {'** -> **', '_ -> _'});
      });
    });

    // -------------------------------------------------------------------------
    // Flanking rules
    // -------------------------------------------------------------------------

    group('flanking rules', () {
      test('bullet asterisk produces no pairs', () {
        expect(resolvedPairs('* Item'), isEmpty);
      });

      test('math expression asterisks produce no pairs', () {
        expect(resolvedPairs('2 * 3 * 4'), isEmpty);
      });

      test('bullet does not pair with inner italic marker', () {
        expect(resolvedPairs('* ==*NEW*=='), {'== -> ==', '* -> *'});
      });

      test('loose markers with surrounding spaces produce no pairs', () {
        expect(resolvedPairs('* loose italic *'), isEmpty);
      });

      test('tight italic still pairs normally', () {
        expect(resolvedPairs('*tight*'), {'* -> *'});
      });

      test('tight bold still pairs normally', () {
        expect(resolvedPairs('**bold**'), {'** -> **'});
      });

      test('subscript in non-whitespace context still pairs', () {
        expect(resolvedPairs('H~2~O'), {'~ -> ~'});
      });
    });
  });
}
