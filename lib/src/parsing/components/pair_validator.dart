import '../../core/textf_limits.dart';
import '../../models/textf_token.dart';

/// Identifies and validates matching pairs of formatting markers in a token list.
///
/// Runs two passes internally: code-boundary crossing removal, then LIFO
/// nesting validation. Callers only see the final validated map.
class PairValidator {
  static const int _maxDepth = TextfLimits.maxNestingDepth;

  /// Identifies matching, valid pairs of formatting markers.
  ///
  /// [allowNewlineCrossing] — when false, pairs whose span contains a newline
  /// are rejected. Set to false for the editing controller path where
  /// cross-line pairing is always accidental; leave true (default) for the
  /// display widget where developer-authored cross-line formatting is
  /// intentional.
  ///
  /// Returns a map where each key is a token index and each value is the
  /// index of its matching partner (bidirectional).
  static Map<int, int> identifyPairs(
    List<TextfToken> tokens, {
    bool allowNewlineCrossing = true,
  }) {
    final Map<int, int> pairs = {};

    _identifySimplePairs(tokens, pairs, allowNewlineCrossing: allowNewlineCrossing);
    _removeCodeBoundaryCrossingPairs(tokens, pairs);

    return _validateNesting(tokens, pairs);
  }

  // -------------------------------------------------------------------------
  // Pass 1: simple per-type stack pairing
  // -------------------------------------------------------------------------

  static void _identifySimplePairs(
    List<TextfToken> tokens,
    Map<int, int> pairs, {
    bool allowNewlineCrossing = true,
  }) {
    final List<int>? nlPrefix = allowNewlineCrossing ? null : _buildNewlinePrefixSum(tokens);

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

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token is! FormatMarkerToken) continue;

      final stack = openingStacks[token.markerType];
      if (stack == null) continue;

      if (stack.isNotEmpty && token.canClose) {
        final int openingIndex = stack.last;

        if (nlPrefix != null && nlPrefix[i - 1] > nlPrefix[openingIndex]) {
          if (token.canOpen) stack.add(i);
          continue;
        }

        stack.removeLast();
        pairs[openingIndex] = i;
        pairs[i] = openingIndex;
      } else if (token.canOpen) {
        stack.add(i);
      }
    }
  }

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

  // -------------------------------------------------------------------------
  // Pass 2: remove non-code pairs that cross or sit inside a code span
  // -------------------------------------------------------------------------

  static void _removeCodeBoundaryCrossingPairs(
    List<TextfToken> tokens,
    Map<int, int> pairs,
  ) {
    final List<(int, int)> codeRanges = [];
    for (final MapEntry<int, int> entry in pairs.entries) {
      final int open = entry.key;
      final int close = entry.value;
      if (open >= close) continue;
      final token = tokens[open];
      if (token is FormatMarkerToken && token.markerType == FormatMarkerType.code) {
        codeRanges.add((open, close));
      }
    }

    if (codeRanges.isEmpty) return;

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
          toRemove
            ..add(open)
            ..add(close);
          break;
        }
      }
    }

    toRemove.forEach(pairs.remove);
  }

  // -------------------------------------------------------------------------
  // Pass 3: LIFO nesting validation and depth enforcement
  // -------------------------------------------------------------------------

  static Map<int, int> _validateNesting(
    List<TextfToken> tokens,
    Map<int, int> candidatePairs,
  ) {
    final Map<int, int> validatedPairs = Map.of(candidatePairs);
    final List<int> openingStack = [];
    final Set<int> invalidPairs = {};

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token is TextToken) continue;

      final matchingIndex = candidatePairs[i];
      if (matchingIndex == null) continue;

      if (matchingIndex > i) {
        if (openingStack.length >= _maxDepth) {
          invalidPairs
            ..add(i)
            ..add(matchingIndex);
          continue;
        }
        openingStack.add(i);
      } else {
        if (openingStack.isNotEmpty && openingStack.last == matchingIndex) {
          openingStack.removeLast();
        } else {
          _markImproperNesting(openingStack, matchingIndex, invalidPairs, candidatePairs);
        }
      }
    }

    invalidPairs.forEach(validatedPairs.remove);
    return validatedPairs;
  }

  static void _markImproperNesting(
    List<int> openingStack,
    int matchingIndex,
    Set<int> invalidPairs,
    Map<int, int> pairs,
  ) {
    int openingPos = -1;
    for (int j = 0; j < openingStack.length; j++) {
      if (openingStack[j] == matchingIndex) {
        openingPos = j;
        break;
      }
    }

    if (openingPos != -1) {
      for (int j = openingPos; j < openingStack.length; j++) {
        final openIndex = openingStack[j];
        final closeIndex = pairs[openIndex]!;
        invalidPairs
          ..add(openIndex)
          ..add(closeIndex);
      }
      openingStack.removeRange(openingPos, openingStack.length);
    }
  }
}
