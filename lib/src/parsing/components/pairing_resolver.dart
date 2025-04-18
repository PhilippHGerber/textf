import '../../models/token.dart';
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
  /// 2. Applies context-aware pairing for ambiguous cases
  /// 3. Validates proper nesting of the identified pairs
  ///
  /// @param tokens The list of tokens to analyze
  /// @return A map where keys are token indices and values are their matching pair indices
  static Map<int, int> identifyPairs(List<Token> tokens) {
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
  static void _identifySimplePairs(List<Token> tokens, Map<int, int> pairs) {
    // Stack of opening markers for each type
    final Map<TokenType, List<int>> openingStacks = {
      TokenType.boldMarker: [],
      TokenType.italicMarker: [],
      TokenType.boldItalicMarker: [],
      TokenType.strikeMarker: [],
      TokenType.codeMarker: [],
    };

    // First pass - pair markers based on type
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.text) continue;

      // Skip link-related tokens as they're handled separately
      if (token.type.isLinkToken) {
        continue;
      }

      // Check if we already have an opening marker of this type
      final stack = openingStacks[token.type];
      if (stack == null) continue; // Unsupported token type

      if (stack.isEmpty) {
        // No opening marker yet - treat this as opening
        stack.add(i);
      } else {
        // We have an opening marker - pair it
        final openingIndex = stack.removeLast();

        // Record the pair
        pairs[openingIndex] = i;
        pairs[i] = openingIndex;
      }
    }
  }

}
