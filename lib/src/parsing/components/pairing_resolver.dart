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
  /// @param allowNewlineCrossing When false, pairs whose span contains a newline are
  ///   rejected during the pairing pass. Set to false for the editing controller path
  ///   where cross-line pairing is always accidental; leave true (default) for the
  ///   display widget where developer-authored cross-line formatting is intentional.
  /// @return A map where keys are token indices and values are their matching pair indices
  static Map<int, int> identifyPairs(
    List<TextfToken> tokens, {
    bool allowNewlineCrossing = true,
  }) {
    final Map<int, int> pairs = {};

    // First pass: identify simple pairs by type
    _identifySimplePairs(tokens, pairs, allowNewlineCrossing: allowNewlineCrossing);

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
  /// When [allowNewlineCrossing] is false, a candidate pair is rejected if any
  /// token between the opener and the current closer contains a newline. In that
  /// case the opener is left on the stack and the current token is pushed as a
  /// new opener (if [FormatMarkerToken.canOpen]), allowing it to pair with a
  /// subsequent same-line closer.
  ///
  /// Newline detection uses a prefix-sum array for O(1) per-query lookups
  /// instead of scanning tokens between each candidate pair.
  ///
  /// @param tokens The list of tokens to analyze
  /// @param pairs The map to populate with identified pairs
  static void _identifySimplePairs(
    List<TextfToken> tokens,
    Map<int, int> pairs, {
    bool allowNewlineCrossing = true,
  }) {
    // Pre-compute newline positions for O(1) range queries when needed.
    final List<int>? nlPrefix = allowNewlineCrossing ? null : _buildNewlinePrefixSum(tokens);

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

      if (stack.isNotEmpty && token.canClose) {
        final int openingIndex = stack.last; // peek before deciding

        // When newline crossing is disabled, reject any pair whose span
        // contains a newline. Leave the opener on the stack so a later
        // same-line closer can still match it, and push the current token
        // as a new opener if it qualifies.
        // O(1) check: compare prefix sums at range boundaries.
        if (nlPrefix != null && nlPrefix[i - 1] > nlPrefix[openingIndex]) {
          if (token.canOpen) {
            stack.add(i);
          }
          continue;
        }

        // An opener exists and this token can close — pair them.
        stack.removeLast();

        // Record the pair (bidirectionally)
        pairs[openingIndex] = i;
        pairs[i] = openingIndex;
      } else if (token.canOpen) {
        // No opener to close, or this token cannot close — treat as an opener.
        stack.add(i);
      }
      // If neither canOpen nor canClose (e.g. a bullet-point `*` or a math
      // operator), leave the token unpaired so it renders as literal text.
    }
    // At this point, any markers remaining on the stacks in `openingStacks`
    // are unpaired opening markers. They will not be included in the `pairs` map.
  }

  /// Builds a cumulative count of newline-containing [TextToken]s.
  ///
  /// `result[i]` equals the number of newline-containing tokens at indices
  /// 0 through i (inclusive). A range `(open, close)` contains a newline iff
  /// `result[close - 1] > result[open]`.
  static List<int> _buildNewlinePrefixSum(List<TextfToken> tokens) {
    final result = List<int>.filled(tokens.length, 0);
    var count = 0;
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token is TextToken && token.value.contains('\n')) count++;
      result[i] = count;
    }
    return result;
  }
}
