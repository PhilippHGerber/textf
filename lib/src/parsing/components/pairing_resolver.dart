import '../../models/textf_token.dart';
import 'nesting_validator.dart';

/// Identifies matching pairs of formatting markers in a token list.
///
/// This class handles the process of matching opening and closing
/// formatting markers, which is a critical step in the parsing process.
/// It includes optimizations for handling different marker types and
/// robust error handling for malformed input.
class PairingResolver {
  /// Identifies matching pairs of formatting markers.
  ///
  /// This method:
  /// 1. Identifies simple pairs based on token type
  /// 2. Applies context-aware pairing for ambiguous cases (not currently implemented, but structure allows)
  /// 3. Validates proper nesting of the identified pairs using NestingValidator.
  ///
  /// @param tokens The list of tokens to analyze
  /// @return A map where keys are token indices and values are their matching pair indices
  static Map<int, int> identifyPairs(List<TextfToken> tokens) {
    final Map<int, int> pairs = {};

    // First pass: identify simple pairs by type
    _identifySimplePairs(tokens, pairs);

    // Second pass: remove pairs that cross code-span boundaries or are
    // entirely inside a code span, so they cannot corrupt code pair validity.
    _removeCodeBoundaryCrossingPairs(tokens, pairs);

    // Validate nesting and remove invalid pairs
    return NestingValidator.validatePairs(tokens, pairs);
  }

  /// Removes non-code pairs that cross a code-span boundary or lie entirely
  /// inside a code span.
  ///
  /// [_identifySimplePairs] uses independent per-type stacks, so a marker of
  /// another format type that sits inside a code span can be paired with a
  /// marker outside the span. When [NestingValidator] later detects the
  /// crossing, it invalidates *both* pairs — including the code pair itself,
  /// which causes the code span to disappear from the rendered output.
  ///
  /// This pass removes the offending non-code pairs *before* they reach
  /// [NestingValidator], so the code pair is never threatened.
  ///
  /// Two cases are handled for each non-code pair `(open, close)`:
  /// - **Crossing:** exactly one end falls strictly inside a code range →
  ///   the pair straddles the code boundary and is removed.
  /// - **Interior:** both ends fall strictly inside the same code range →
  ///   formatting markers inside code are intentionally suppressed and the
  ///   pair is removed.
  static void _removeCodeBoundaryCrossingPairs(
    List<TextfToken> tokens,
    Map<int, int> pairs,
  ) {
    // Collect all code-span ranges (token-index intervals) from the candidate pairs.
    final List<(int, int)> codeRanges = [];
    for (final MapEntry<int, int> entry in pairs.entries) {
      final int open = entry.key;
      final int close = entry.value;
      if (open >= close) continue; // process open→close direction only
      final token = tokens[open];
      if (token is FormatMarkerToken && token.markerType == FormatMarkerType.code) {
        codeRanges.add((open, close));
      }
    }

    if (codeRanges.isEmpty) return;

    // Find all non-code pairs that are affected by at least one code range.
    final List<int> toRemove = [];
    for (final MapEntry<int, int> entry in pairs.entries) {
      final int open = entry.key;
      final int close = entry.value;
      if (open >= close) continue;
      final token = tokens[open];
      if (token is! FormatMarkerToken || token.markerType == FormatMarkerType.code) continue;

      for (final (int codeOpen, int codeClose) in codeRanges) {
        final bool openInside = open > codeOpen && open < codeClose;
        final bool closeInside = close > codeOpen && close < codeClose;
        if (openInside || closeInside) {
          // Crossing pair (only one end inside) or interior pair (both inside).
          toRemove
            ..add(open)
            ..add(close);
          break;
        }
      }
    }

    toRemove.forEach(pairs.remove);
  }

  /// Identifies simple pairs of matching markers based on token type.
  ///
  /// This method uses a stack-based approach to pair opening and closing
  /// markers of the same type in a left-to-right pass.
  ///
  /// @param tokens The list of tokens to analyze
  /// @param pairs The map to populate with identified pairs
  static void _identifySimplePairs(List<TextfToken> tokens, Map<int, int> pairs) {
    // Stack of opening markers for each format type
    final Map<FormatMarkerType, List<int>> openingStacks = {
      FormatMarkerType.bold: [],
      FormatMarkerType.italic: [],
      FormatMarkerType.boldItalic: [],
      FormatMarkerType.strikethrough: [],
      FormatMarkerType.code: [],
      FormatMarkerType.underline: [],
      FormatMarkerType.highlight: [],
      FormatMarkerType.superscript: [],
      FormatMarkerType.subscript: [],
    };

    // First pass - pair markers based on type
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Only consider formatting markers for pairing.
      // Text tokens and link-specific tokens are ignored here.
      if (token is! FormatMarkerToken) {
        continue;
      }

      // Get the stack for the current token's marker type.
      final stack = openingStacks[token.markerType];
      if (stack == null) continue; // Should not happen for known formatting markers

      if (stack.isEmpty) {
        // No opening marker of this type on the stack yet - treat this as an opening marker.
        stack.add(i);
      } else {
        // An opening marker of this type exists on the stack - pair it with this closing marker.
        final int openingIndex = stack.removeLast();

        // Record the pair (bidirectionally)
        pairs[openingIndex] = i;
        pairs[i] = openingIndex;
      }
    }
    // At this point, any markers remaining on the stacks in `openingStacks`
    // are unpaired opening markers. They will not be included in the `pairs` map.
  }
}
