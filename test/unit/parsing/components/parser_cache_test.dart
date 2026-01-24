// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

// Manual Mock to track calls
class MockTokenizer extends TextfTokenizer {
  int callCount = 0;

  @override
  List<Token> tokenize(String text) {
    callCount++;
    return super.tokenize(text);
  }
}

void main() {
  group('TextfParser Static Cache Tests', () {
    late MockTokenizer mockTokenizer;
    late TextfParser parser;
    // ignore: avoid-late-keyword
    late BuildContext mockContext;

    setUp(() {
      // Reset static cache before every test to ensure isolation
      TextfParser.clearCache();

      mockTokenizer = MockTokenizer();
      parser = TextfParser(tokenizer: mockTokenizer);
    });

    tearDown(TextfParser.clearCache);

    // Helper to get a dummy context
    Widget createTestWidget(void Function(BuildContext) onContext) {
      return Builder(
        builder: (context) {
          onContext(context);
          return const SizedBox();
        },
      );
    }

    testWidgets('Uses cache on second call for same text', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Cached Text**';

      // 1. First Parse (Cache Miss)
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1, reason: 'Tokenizer should be called on first parse');

      // 2. Second Parse (Cache Hit)
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1, reason: 'Tokenizer should NOT be called on second parse');
    });

    testWidgets('clearCache() forces re-tokenization', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Text**';

      // 1. Parse & Cache
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1);

      // 2. Clear
      TextfParser.clearCache();

      // 3. Parse again (Should be Cache Miss)
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 2, reason: 'Should re-tokenize after cache clear');
    });

    testWidgets('Does NOT cache strings longer than 1000 chars', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // Create a string slightly longer than 1000 chars
      final longText = '**${'A' * 999}**';
      expect(longText.length, greaterThan(1000)); // Sanity check

      // First Parse
      parser.parse(longText, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1);

      // Second Parse - should NOT use cache (too long)
      parser.parse(longText, mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        2,
        reason: 'Should re-tokenize long strings (bypass cache)',
      );
    });

    testWidgets('LRU Eviction works (Max 200 entries)', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // 1. Fill the cache with 200 items
      for (int i = 0; i < 200; i++) {
        parser.parse('**Item $i**', mockContext, const TextStyle());
      }
      expect(mockTokenizer.callCount, 200);

      // Add 201st item to trigger eviction
      parser.parse('**Item 200**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 201);

      // "Item 0" should have been evicted (LRU = oldest)
      parser.parse('**Item 0**', mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        202,
        reason: 'Item 0 should have been evicted and thus re-tokenized',
      );
    });
  });
}
