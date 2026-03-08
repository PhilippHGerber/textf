import '../models/textf_token.dart';
import '../parsing/components/pairing_resolver.dart';
import '../parsing/textf_tokenizer.dart';
import 'textf_cache.dart';
import 'textf_limits.dart';

/// Shared static cache for tokenization and pair resolution results.
///
/// Used by both `TextfParser` (read-only widgets) and `TextfSpanBuilder`
/// (editing controllers) to avoid duplicate caching of identical data.
class TextfTokenCache {
  TextfTokenCache._();

  static final TextfTokenizer _tokenizer = TextfTokenizer();

  /// Single shared LRU cache keyed by (text, allowNewlineCrossing).
  static final TextfCache<({String text, bool allowNewlineCrossing}), TokenCacheEntry> _cache =
      TextfCache<({String text, bool allowNewlineCrossing}), TokenCacheEntry>(
    maxEntries: TextfLimits.maxCacheEntries,
    maxTotalChars: TextfLimits.maxCacheTotalCharacters,
    getCharCount: (key) => key.text.length,
  );

  /// Retrieves tokenized text and valid pairs, utilizing the shared LRU cache.
  ///
  /// Strings longer than [TextfLimits.maxCacheKeyLength] are parsed on-demand
  /// without caching to prevent memory bloat.
  static TokenCacheEntry getTokensAndPairs(
    String text, {
    bool allowNewlineCrossing = true,
  }) {
    if (text.length > TextfLimits.maxCacheKeyLength) {
      final tokens = _tokenizer.tokenize(text, allowNewlineCrossing: allowNewlineCrossing);
      final validPairs =
          PairingResolver.identifyPairs(tokens, allowNewlineCrossing: allowNewlineCrossing);
      return TokenCacheEntry(tokens, validPairs);
    }

    final key = (text: text, allowNewlineCrossing: allowNewlineCrossing);
    final cached = _cache.get(key);
    if (cached != null) {
      return cached;
    }

    final tokens = _tokenizer.tokenize(text, allowNewlineCrossing: allowNewlineCrossing);
    final validPairs =
        PairingResolver.identifyPairs(tokens, allowNewlineCrossing: allowNewlineCrossing);
    final entry = TokenCacheEntry(tokens, validPairs);
    _cache.set(key, entry);

    return entry;
  }

  /// Clears the shared token cache.
  static void clearCache() {
    _cache.clear();
  }

  /// Number of entries currently in the cache (useful for testing).
  static int get cacheLength => _cache.length;
}

/// Cached result of tokenization and pair resolution.
class TokenCacheEntry {
  /// Creates a new cache entry.
  const TokenCacheEntry(this.tokens, this.validPairs);

  /// The tokenized text.
  final List<TextfToken> tokens;

  /// Map of matching format marker pairs (open index → close index and vice versa).
  final Map<int, int> validPairs;
}
