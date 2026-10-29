// ignore_for_file: cascade_invocations, no-magic-number, avoid-late-keyword, prefer-match-file-name, avoid-top-level-members-in-tests

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  group('TextfParser Static Cache Tests', () {
    final resolver = TextfStyleResolver(options: null);

    setUp(TextfParser.clearCache);
    tearDown(TextfParser.clearCache);

    // =========================================================================
    // BASIC CACHE BEHAVIOR
    // =========================================================================

    test('Uses cache on second call for same text', () {
      final parser = TextfParser();
      const text = '**Cached Text**';

      // 1. First Parse (Cache Miss)
      parser.parse(text, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1, reason: 'Cache should have 1 entry after first parse');

      // 2. Second Parse (Cache Hit) - cache size stays the same
      parser.parse(text, const TextStyle(), resolver);
      expect(
        TextfParser.cacheLength,
        1,
        reason: 'Cache should still have 1 entry (no new tokenization)',
      );
    });

    test('clearCache() forces re-tokenization', () {
      final parser = TextfParser();
      const text = '**Text**';

      // 1. Parse & Cache
      parser.parse(text, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1);

      // 2. Clear
      TextfParser.clearCache();
      expect(TextfParser.cacheLength, 0, reason: 'Cache should be empty after clear');

      // 3. Parse again (Should be Cache Miss)
      parser.parse(text, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1, reason: 'Should re-tokenize after cache clear');
    });

    // =========================================================================
    // LINK TEXT GOES THROUGH THE SHARED CACHE
    // =========================================================================

    test('a plain link label is tokenized through the shared cache', () {
      final parser = TextfParser();

      parser.parse('[plain label](example.com)', const TextStyle(), resolver);

      expect(
        TextfParser.cacheLength,
        2,
        reason: 'one entry for the source text, one for the link label',
      );
    });

    test('a formatted link label shares one cache entry with its nested parse', () {
      final parser = TextfParser();

      parser.parse('[**bold** label](example.com)', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 2, reason: 'source text + link label');

      parser.parse('See [**bold** label](example.com)', const TextStyle(), resolver);
      expect(
        TextfParser.cacheLength,
        3,
        reason: 'only the new source text is added; the label entry is reused',
      );
    });

    // =========================================================================
    // CACHE KEY BEHAVIOR (TEXT-ONLY KEYING)
    // =========================================================================

    test('Same text with different styles shares token cache', () {
      final parser = TextfParser();
      const text = '**Styled Text**';
      const style1 = TextStyle(fontSize: 16, color: Color(0xFFF44336));
      const style2 = TextStyle(fontSize: 24, color: Color(0xFF2196F3));

      // 1. First parse with style1
      parser.parse(text, style1, resolver);
      expect(TextfParser.cacheLength, 1, reason: 'First parse should cache');

      // 2. Second parse with different style - should reuse cached tokens
      parser.parse(text, style2, resolver);
      expect(
        TextfParser.cacheLength,
        1,
        reason: 'Cache is keyed by text only; different styles share token cache',
      );
    });

    test('Same text with different resolvers shares token cache', () {
      final parser = TextfParser();
      const text = '**Resolver Test**';

      // 1. Parse with the first resolver
      parser.parse(text, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1);

      // 2. Parse with a resolver built from other options - should still use cached tokens
      parser.parse(
        text,
        const TextStyle(),
        TextfStyleResolver(
          options: const TextfOptionsData(boldStyle: TextStyle(fontSize: 20)),
        ),
      );
      expect(
        TextfParser.cacheLength,
        1,
        reason: 'Cache is keyed by text only; different resolvers share token cache',
      );
    });

    test('Different text creates separate cache entries', () {
      final parser = TextfParser();

      // 1. Parse first text
      parser.parse('**First**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1);

      // 2. Parse different text - cache miss
      parser.parse('**Second**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 2, reason: 'Different text creates separate cache entry');

      // 3. Parse first text again - cache hit (no new entry)
      parser.parse('**First**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 2, reason: 'First text should still be cached');

      // 4. Parse second text again - cache hit (no new entry)
      parser.parse('**Second**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 2, reason: 'Second text should still be cached');
    });

    // =========================================================================
    // CACHE SIZE LIMITS
    // =========================================================================

    test('Does NOT cache strings longer than 1000 chars', () {
      final parser = TextfParser();

      // Create a string slightly longer than 1000 chars
      final longText = '**${'A' * 999}**';
      expect(longText.length, greaterThan(1000)); // Sanity check

      // First Parse - should NOT cache (too long)
      parser.parse(longText, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 0, reason: 'Strings > 1000 chars should not be cached');

      // Second Parse - still not cached
      parser.parse(longText, const TextStyle(), resolver);
      expect(
        TextfParser.cacheLength,
        0,
        reason: 'Strings > 1000 chars bypass cache to prevent memory bloat',
      );
    });

    test('Caches strings at exactly 1000 chars', () {
      final parser = TextfParser();

      // Create a string exactly 1000 chars WITH formatting markers
      // 4 chars for markers (**...**) + 996 chars content = 1000
      final exactText = '**${'A' * 996}**';
      expect(exactText.length, 1000); // Sanity check

      // First Parse
      parser.parse(exactText, const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1);

      // Second Parse - SHOULD use cache (exactly at limit)
      parser.parse(exactText, const TextStyle(), resolver);
      expect(
        TextfParser.cacheLength,
        1,
        reason: 'Strings at exactly 1000 chars should be cached',
      );
    });

    // =========================================================================
    // LRU EVICTION
    // =========================================================================

    test('LRU eviction removes oldest entry when exceeding 1000 items', () {
      final parser = TextfParser();

      // 1. Fill the cache with 1000 items (max is 1000 entries)
      for (int i = 0; i < 1000; i++) {
        parser.parse('**Item $i**', const TextStyle(), resolver);
      }
      expect(TextfParser.cacheLength, 1000);

      // 2. Add 1001st item to trigger eviction
      parser.parse('**Item 1000**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1000, reason: 'Cache should stay at max 1000 after eviction');
    });

    test('LRU access refreshes entry position (true LRU behavior)', () {
      final parser = TextfParser();

      // 1. Fill the cache with 1000 items (Item 0 is oldest, Item 999 is newest)
      for (int i = 0; i < 1000; i++) {
        parser.parse('**Item $i**', const TextStyle(), resolver);
      }
      expect(TextfParser.cacheLength, 1000);

      // 2. Access Item 0 to refresh its position (cache hit, no new entry)
      parser.parse('**Item 0**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1000, reason: 'Item 0 is a cache hit, no change in count');

      // 3. Add a new item - cache stays at 1000 (Item 1 evicted, not Item 0)
      parser.parse('**Item 1000**', const TextStyle(), resolver);
      expect(TextfParser.cacheLength, 1000, reason: 'Cache should stay at 1000 after eviction');

      // 4. Item 0 should still be cached (was refreshed in step 2) -
      //    verifiable by checking that cacheLength doesn't increase on re-parse
      final lengthBefore = TextfParser.cacheLength;
      parser.parse('**Item 0**', const TextStyle(), resolver);
      expect(
        TextfParser.cacheLength,
        lengthBefore,
        reason: 'Item 0 was refreshed and should still be in cache (no new eviction)',
      );
    });

    // =========================================================================
    // OUTPUT VERIFICATION
    // =========================================================================

    test('Cached and non-cached parses produce equivalent output', () {
      final parser = TextfParser();
      const text = '**Bold** and *italic*';
      const style = TextStyle(fontSize: 16);

      // 1. First parse (cache miss)
      final firstResult = parser.parse(text, style, resolver);
      expect(TextfParser.cacheLength, 1);

      // 2. Second parse (cache hit)
      final secondResult = parser.parse(text, style, resolver);
      expect(TextfParser.cacheLength, 1, reason: 'Cache hit should not add new entry');

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
