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

    // Validate nesting and remove invalid pairs
    return NestingValidator.validatePairs(tokens, pairs);
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
