// ignore_for_file: no-magic-number, avoid-late-keyword, prefer-match-file-name, avoid-top-level-members-in-tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

/// Mock tokenizer that tracks call count for verifying cache behavior.
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
    late BuildContext mockContext;

    setUp(() {
      // Reset static cache before every test to ensure isolation
      TextfParser.clearCache();

      mockTokenizer = MockTokenizer();
      parser = TextfParser(tokenizer: mockTokenizer);
    });

    tearDown(TextfParser.clearCache);

    /// Helper to get a BuildContext for testing.
    Widget createTestWidget(void Function(BuildContext) onContext) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            onContext(context);
            return const SizedBox();
          },
        ),
      );
    }

    // =========================================================================
    // BASIC CACHE BEHAVIOR
    // =========================================================================

    testWidgets('Uses cache on second call for same text', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Cached Text**';

      // 1. First Parse (Cache Miss)
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1, reason: 'Tokenizer should be called on first parse');

      // 2. Second Parse (Cache Hit)
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1, reason: 'Tokenizer should NOT be called on cache hit');
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

    // =========================================================================
    // CACHE KEY BEHAVIOR (TEXT-ONLY KEYING)
    // =========================================================================

    testWidgets('Same text with different styles shares token cache', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Styled Text**';
      const style1 = TextStyle(fontSize: 16, color: Colors.red);
      const style2 = TextStyle(fontSize: 24, color: Colors.blue);

      // 1. First parse with style1
      parser.parse(text, mockContext, style1);
      expect(mockTokenizer.callCount, 1, reason: 'First parse should tokenize');

      // 2. Second parse with different style - should reuse cached tokens
      parser.parse(text, mockContext, style2);
      expect(
        mockTokenizer.callCount,
        1,
        reason: 'Cache is keyed by text only; different styles share token cache',
      );
    });

    testWidgets('Same text with different contexts shares token cache', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Context Test**';

      // 1. Parse with first context
      parser.parse(text, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1);

      // 2. Get a new context (simulating widget rebuild)
      late BuildContext newContext;
      await tester.pumpWidget(createTestWidget((ctx) => newContext = ctx));

      // 3. Parse with new context - should still use cached tokens
      parser.parse(text, newContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        1,
        reason: 'Cache is keyed by text only; different contexts share token cache',
      );
    });

    testWidgets('Different text creates separate cache entries', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // 1. Parse first text
      parser.parse('**First**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1);

      // 2. Parse different text - cache miss
      parser.parse('**Second**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 2, reason: 'Different text requires new tokenization');

      // 3. Parse first text again - cache hit
      parser.parse('**First**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 2, reason: 'First text should still be cached');

      // 4. Parse second text again - cache hit
      parser.parse('**Second**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 2, reason: 'Second text should still be cached');
    });

    // =========================================================================
    // CACHE SIZE LIMITS
    // =========================================================================

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
        reason: 'Strings > 1000 chars bypass cache to prevent memory bloat',
      );
    });

    testWidgets('Caches strings at exactly 1000 chars', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // Create a string exactly 1000 chars WITH formatting markers
      // 4 chars for markers (**...**) + 996 chars content = 1000
      final exactText = '**${'A' * 996}**';
      expect(exactText.length, 1000); // Sanity check

      // First Parse
      parser.parse(exactText, mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 1);

      // Second Parse - SHOULD use cache (exactly at limit)
      parser.parse(exactText, mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        1,
        reason: 'Strings at exactly 1000 chars should be cached',
      );
    });

    // =========================================================================
    // LRU EVICTION
    // =========================================================================

    testWidgets('LRU eviction removes oldest entry when exceeding 200 items', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // 1. Fill the cache with 200 items
      for (int i = 0; i < 200; i++) {
        parser.parse('**Item $i**', mockContext, const TextStyle());
      }
      expect(mockTokenizer.callCount, 200);

      // 2. Add 201st item to trigger eviction
      parser.parse('**Item 200**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 201);

      // 3. "Item 0" should have been evicted (oldest entry)
      parser.parse('**Item 0**', mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        202,
        reason: 'Item 0 (oldest) should have been evicted and require re-tokenization',
      );

      // 4. "Item 1" should still be cached (it was second oldest, but Item 0 was evicted)
      // Wait - after evicting Item 0 and adding Item 200, then re-adding Item 0,
      // the cache now has 200 items again. Item 1 is now the oldest.
      // Let's verify Item 199 is still cached (it was added before Item 200)
      parser.parse('**Item 199**', mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        202,
        reason: 'Item 199 should still be cached',
      );
    });

    testWidgets('LRU access refreshes entry position (true LRU behavior)', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));

      // 1. Fill the cache with 200 items (Item 0 is oldest, Item 199 is newest)
      for (int i = 0; i < 200; i++) {
        parser.parse('**Item $i**', mockContext, const TextStyle());
      }
      expect(mockTokenizer.callCount, 200);

      // 2. Access Item 0 - this should refresh its position to "most recent"
      parser.parse('**Item 0**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 200, reason: 'Item 0 should be a cache hit');

      // 3. Add new item - Item 1 should now be evicted (it's now the oldest)
      parser.parse('**Item 200**', mockContext, const TextStyle());
      expect(mockTokenizer.callCount, 201);

      // 4. Item 0 should still be cached (was refreshed in step 2)
      parser.parse('**Item 0**', mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        201,
        reason: 'Item 0 was refreshed and should still be cached',
      );

      // 5. Item 1 should have been evicted (was oldest after Item 0 was refreshed)
      parser.parse('**Item 1**', mockContext, const TextStyle());
      expect(
        mockTokenizer.callCount,
        202,
        reason: 'Item 1 should have been evicted as the oldest entry',
      );
    });

    // =========================================================================
    // OUTPUT VERIFICATION
    // =========================================================================

    testWidgets('Cached and non-cached parses produce equivalent output', (tester) async {
      await tester.pumpWidget(createTestWidget((ctx) => mockContext = ctx));
      const text = '**Bold** and *italic*';
      const style = TextStyle(fontSize: 16);

      // 1. First parse (cache miss)
      final firstResult = parser.parse(text, mockContext, style);
      expect(mockTokenizer.callCount, 1);

      // 2. Second parse (cache hit)
      final secondResult = parser.parse(text, mockContext, style);
      expect(mockTokenizer.callCount, 1);

      // 3. Verify structural equivalence
      expect(firstResult.length, secondResult.length, reason: 'Same number of spans');

      for (int i = 0; i < firstResult.length; i++) {
        final first = firstResult[i] as TextSpan;
        final second = secondResult[i] as TextSpan;
        expect(first.text, second.text, reason: 'Span $i text should match');
        expect(first.style, second.style, reason: 'Span $i style should match');
      }

      // 4. Verify they are different List instances (not the same reference)
      expect(
        identical(firstResult, secondResult),
        isFalse,
        reason: 'Each parse returns a new List instance (spans are rebuilt with styles)',
      );
    });
  });
}
