import 'package:flutter/painting.dart';

import 'textf_token.dart';

/// Helper class for tracking format stack entries during parsing.
///
/// Each entry represents a formatting marker that has been opened
/// but not yet closed during the parsing process. This class helps
/// in tracking the nesting of formatting styles and ensures that
/// they are properly applied and removed in the correct order.
///
/// The [resolvedStyle] field caches the cumulative resolved style at this
/// stack depth, making style lookups O(1) instead of O(depth) per flush.
class FormatStackEntry {
  /// Creates a new format stack entry.
  const FormatStackEntry({
    required this.index,
    required this.matchingIndex,
    required this.type,
    this.resolvedStyle,
  });

  /// Index of the opening formatting marker in the token list.
  final int index;

  /// Index of the matching closing marker in the token list.
  final int matchingIndex;

  /// Type of the formatting marker.
  final FormatMarkerType type;

  /// The cumulative resolved style at this stack depth.
  ///
  /// When set, this represents the fully resolved style from baseStyle
  /// through all format stack entries up to and including this one.
  /// This avoids re-walking the stack on every [flushText] call.
  final TextStyle? resolvedStyle;

  @override
  String toString() => 'FormatStackEntry($type, $index -> $matchingIndex)';
}
