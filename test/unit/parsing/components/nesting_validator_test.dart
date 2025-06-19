import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/parsing/components/nesting_validator.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('NestingValidator Tests', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // Helper function to run a validation test.
    // It tokenizes text, finds initial pairs, validates them, and checks the result.
    void testValidation(
      String description,
      String text,
      List<String> expectedValidPairs,
    ) {
      test(description, () {
        // ARRANGE: Tokenize and find all potential pairs (before validation).
        final tokens = tokenizer.tokenize(text);
        final candidatePairs = <int, int>{};
        // This is a simplified version of PairingResolver._identifySimplePairs
        // to get the initial candidates for validation.
        final stacks = <TokenType, List<int>>{};
        for (int i = 0; i < tokens.length; i++) {
          final token = tokens[i];
          if (!token.type.isFormattingMarker) continue;
          final stack = stacks.putIfAbsent(token.type, () => []);
          if (stack.isEmpty) {
            stack.add(i);
          } else {
            final openIndex = stack.removeLast();
            candidatePairs[openIndex] = i;
            candidatePairs[i] = openIndex;
          }
        }

        // ACT: Validate the pairs using the NestingValidator.
        final validatedPairs = NestingValidator.validatePairs(tokens, candidatePairs);

        // ASSERT: Format the result for easy comparison.
        final actualValidPairs = <String>{};
        validatedPairs.forEach((key, value) {
          // Add each pair only once to the set for comparison (from opener to closer).
          if (key < value) {
            actualValidPairs.add('${tokens[key].value} -> ${tokens[value].value}');
          }
        });

        expect(actualValidPairs, unorderedEquals(expectedValidPairs), reason: description);
      });
    }

    group('Valid Nesting Scenarios', () {
      testValidation(
        'should validate correctly nested different markers',
        '**bold with _italic_**',
        ['** -> **', '_ -> _'],
      );

      testValidation(
        'should validate adjacent markers',
        '**bold**_italic_`code`',
        ['** -> **', '_ -> _', '` -> `'],
      );

      testValidation(
        'should validate correctly nested same markers (using different chars)',
        '__bold with _italic_ __',
        ['__ -> __', '_ -> _'],
      );
    });

    group('Invalid Nesting Scenarios', () {
      testValidation(
        'should invalidate overlapping markers',
        // Here, bold opens, then italic opens. But bold closes before italic.
        // This is invalid nesting, so both pairs should be discarded.
        '**bold *and italic** is wrong*',
        [], // Expect no valid pairs.
      );

      testValidation(
        'should invalidate overlapping markers of different types',
        '~~strike with **bold~~ inner**',
        [], // Expect no valid pairs.
      );
    });

    group('Nesting Depth Limit', () {
      // NestingValidator.maxDepth is 2. This test uses 3 levels.
      testValidation(
        'should invalidate pairs exceeding the maximum nesting depth',
        // Level 1: **
        // Level 2: _
        // Level 3: ~~ (This should be invalidated)
        '**level1 _level2 ~~level3~~_**',
        // The outer two pairs are valid and should be kept.
        ['** -> **', '_ -> _'],
      );

      testValidation(
        'should handle multiple pairs at the same depth correctly',
        '**bold _italic_ and `code`**',
        // Italic and code are both at depth 2, which is valid.
        ['** -> **', '_ -> _', '` -> `'],
      );

      testValidation(
        'should invalidate only the deepest pair in a multi-level violation',
        // Level 1: **
        // Level 2: _
        // Level 3: ~~
        // Level 4: `` (Invalid)
        '**_~~`code`~~_**',
        // Only the code pair ` -> ` should be invalidated.
        ['** -> **', '_ -> _'],
      );
    });
  });
}
