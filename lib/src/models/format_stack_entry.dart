import 'token_type.dart';

/// Helper class for tracking format stack entries during parsing.
///
/// Each entry represents a formatting marker that has been opened
/// but not yet closed during the parsing process. This class helps
/// in tracking the nesting of formatting styles and ensures that
/// they are properly applied and removed in the correct order.
class FormatStackEntry {
  /// Creates a new format stack entry.
  const FormatStackEntry({
    required this.index,
    required this.matchingIndex,
    required this.type,
  });

  /// Index of the opening formatting marker in the token list.
  final int index;

  /// Index of the matching closing marker in the token list.
  final int matchingIndex;

  /// Type of the formatting marker.
  final TokenType type;

  @override
  String toString() => 'FormatStackEntry($type, $index -> $matchingIndex)';
}
