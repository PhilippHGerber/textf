/// Centralized numeric limits and tuning constants for the textf package.
///
/// Keeping these values in one place makes them discoverable
/// and avoids scattering magic numbers across the codebase.
final class TextfLimits {
  TextfLimits._();

  /// Maximum number of entries in the parser LRU cache.
  static const int maxCacheEntries = 200;

  /// Maximum length of a string eligible for caching.
  /// Strings longer than this are parsed on-demand to prevent memory bloating.
  static const int maxCacheKeyLength = 1000;

  /// Maximum formatting nesting depth (e.g., bold inside italic = 2 levels).
  static const int maxNestingDepth = 2;

  /// Padding multiplier for script (superscript/subscript) alignment.
  ///
  /// Doubled because `PlaceholderAlignment.middle` centers on the baseline;
  /// shifting the visual center by `offsetY` requires `2 * offsetY` padding.
  static const double scriptAlignmentPaddingFactor = 2;
}
