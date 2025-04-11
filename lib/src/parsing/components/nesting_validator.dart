import '../../models/token.dart';

/// Validates proper nesting of formatting markers.
///
/// This class ensures that formatting markers are properly nested,
/// which is important for correct rendering of formatted text.
/// It identifies and removes invalid pairs that would cause
/// improper nesting of formatting.
class NestingValidator {
  /// Maximum formatting nesting depth allowed by the parser.
  ///
  /// This limits how many layers of formatting can be nested:
  /// - Bold text = 1 level
  /// - Bold text containing italic text = 2 levels
  /// - Bold text containing italic text with strikethrough = 3 levels (exceeds max)
  ///
  /// When the nesting depth exceeds this limit, additional formatting markers
  /// are treated as plain text to maintain predictable rendering behavior.
  static const int maxDepth = 2;

  /// Validates proper nesting of formatting markers and returns valid pairs.
  ///
  /// This method:
  /// 1. Checks that opening and closing markers follow a proper nesting structure
  /// 2. Identifies improperly nested markers
  /// 3. Removes invalid pairs that would cause improper nesting
  ///
  /// @param tokens The list of tokens to validate
  /// @param candidatePairs The initial pairs identified by the pairing resolver
  /// @return A map of validated pairs with invalid ones removed
  static Map<int, int> validatePairs(
    List<Token> tokens,
    Map<int, int> candidatePairs,
  ) {
    final Map<int, int> validatedPairs = Map.from(candidatePairs);
    final List<int> openingStack = [];
    final Set<int> invalidPairs = {};

    // Check each token for proper nesting
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.text) continue;

      final matchingIndex = candidatePairs[i];
      if (matchingIndex == null) continue; // Skip unpaired markers

      if (matchingIndex > i) {
        // This is an opening marker

        // Check nesting depth limit
        if (openingStack.length >= maxDepth) {
          // Exceeds maximum nesting depth, mark as invalid
          invalidPairs.add(i);
          invalidPairs.add(matchingIndex);
          continue;
        }

        openingStack.add(i);
      } else {
        // This is a closing marker
        if (openingStack.isNotEmpty && openingStack.last == matchingIndex) {
          // Proper nesting - remove from stack
          openingStack.removeLast();
        } else {
          // Improper nesting
          _handleImproperNesting(
            openingStack,
            matchingIndex,
            invalidPairs,
            candidatePairs,
          );
        }
      }
    }

    // Remove invalid pairs
    for (final index in invalidPairs) {
      validatedPairs.remove(index);
    }

    return validatedPairs;
  }

  /// Handles improperly nested formatting markers.
  ///
  /// This method identifies and marks as invalid all pairs that are
  /// improperly nested within the current formatting context.
  ///
  /// @param openingStack The stack of opening markers
  /// @param matchingIndex The index of the matching opening marker
  /// @param invalidPairs The set of invalid pair indices
  /// @param pairs The complete map of pairs
  static void _handleImproperNesting(
    List<int> openingStack,
    int matchingIndex,
    Set<int> invalidPairs,
    Map<int, int> pairs,
  ) {
    // Find position of matching opening marker in stack
    int openingPos = -1;
    for (int j = 0; j < openingStack.length; j++) {
      if (openingStack[j] == matchingIndex) {
        openingPos = j;
        break;
      }
    }

    if (openingPos != -1) {
      // Mark all pairs from openingPos to end as invalid
      for (int j = openingPos; j < openingStack.length; j++) {
        final openIndex = openingStack[j];
        final closeIndex = pairs[openIndex]!;

        invalidPairs.add(openIndex);
        invalidPairs.add(closeIndex);
      }

      // Remove processed markers
      openingStack.removeRange(openingPos, openingStack.length);
    }
  }
}
