import 'dart:collection';

/// A memory-aware Least Recently Used (LRU) cache.
///
/// Evicts the oldest entries when either the [maxEntries] limit
/// OR the[maxTotalChars] budget is exceeded. This dual-bound approach
/// prevents memory bloat when caching many long strings.
class TextfCache<K, V> {
  /// Creates a new dual-bounded LRU cache.
  TextfCache({
    required this.maxEntries,
    required this.maxTotalChars,
    required this.getCharCount,
  });

  /// The maximum number of distinct entries the cache can hold.
  final int maxEntries;

  /// The maximum sum of characters allowed across all cached keys.
  final int maxTotalChars;

  /// A function that extracts the character length (weight) from a given key.
  final int Function(K key) getCharCount;

  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();
  int _currentCharCount = 0;

  /// Explicitly tracks the Most Recently Used key to achieve O(1) cache hits.
  K? _mruKey;

  /// Retrieves a value from the cache and marks it as recently used.
  ///
  /// Returns `null` if the key is not present.
  V? get(K key) {
    final V? value = _map[key];

    if (value != null) {
      // Optimization: Only mutate the LinkedHashMap if the item isn't ALREADY
      // the most recently used. Tracking _mruKey explicitly provides O(1) checking,
      // avoiding the O(N) penalty of calling `_map.keys.last`.
      if (key != _mruKey) {
        _map.remove(key);
        _map[key] = value;
        _mruKey = key;
      }
    }
    return value;
  }

  /// Inserts or updates a value in the cache, enforcing eviction policies.
  void set(K key, V value) {
    final int charCount = getCharCount(key);

    // If the key already exists, remove it first to accurately track the budget
    if (_map.containsKey(key)) {
      _currentCharCount -= charCount;
      _map.remove(key);
    }

    _map[key] = value;
    _currentCharCount += charCount;
    _mruKey = key;

    _evictIfNeeded();
  }

  /// Removes the oldest entries until both limits are satisfied.
  void _evictIfNeeded() {
    while (_map.isNotEmpty && (_map.length > maxEntries || _currentCharCount > maxTotalChars)) {
      final K oldestKey = _map.keys.first;
      _currentCharCount -= getCharCount(oldestKey);
      _map.remove(oldestKey);
    }
    // If we evicted the MRU key (unlikely unless maxEntries=1), reset it.
    if (!_map.containsKey(_mruKey)) {
      _mruKey = _map.isNotEmpty ? _map.keys.last : null;
    }
  }

  /// Clears all entries and resets the character budget.
  void clear() {
    _map.clear();
    _currentCharCount = 0;
    _mruKey = null;
  }

  /// Number of items currently in the cache (useful for testing).
  int get length => _map.length;

  /// Total character budget currently consumed (useful for testing).
  int get currentTotalChars => _currentCharCount;
}
