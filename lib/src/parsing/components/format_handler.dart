import 'package:flutter/material.dart';

import '../../models/format_stack_entry.dart';
import '../../models/parser_state.dart';
import '../../models/token.dart';

/// Handles the processing of formatting tokens during parsing.
///
/// This class contains methods for handling formatting markers like
/// bold, italic, strikethrough, and code. It manages the format stack
/// and ensures that formatting is correctly applied and removed.
class FormatHandler {
  /// Processes a formatting token and updates the parser state.
  ///
  /// This method handles both opening and closing formatting markers.
  /// It updates the format stack, flushes text when necessary, and
  /// keeps track of processed tokens.
  ///
  /// @param context The BuildContext
  /// @param state The current parser state
  /// @param index The index of the token being processed
  /// @param token The token to process
  /// @return The new token index after processing, or null if no index change
  static int? processFormat(
    BuildContext context,
    ParserState state,
    int index,
    Token token,
  ) {
    final matchingIndex = state.matchingPairs[index];
    if (matchingIndex != null) {
      // This is a formatting marker with a matching pair
      if (matchingIndex > index) {
        // This is an opening marker
        return _handleOpeningMarker(context, state, index, token);
      } else {
        // This is a closing marker
        return _handleClosingMarker(context, state, index, matchingIndex);
      }
    } else {
      // Unpaired marker, treat as text
      state.textBuffer += token.value;
      return null;
    }
  }

  /// Handles an opening formatting marker.
  ///
  /// This method adds the marker to the format stack and flushes
  /// any accumulated text with the previous formatting.
  ///
  /// @param context The BuildContext
  /// @param state The current parser state
  /// @param index The index of the token being processed
  /// @param token The opening marker token
  /// @return The new token index after processing, or null if no index change
  static int? _handleOpeningMarker(
    BuildContext context,
    ParserState state,
    int index,
    Token token,
  ) {
    // Add any accumulated text before we start this formatting
    state.flushText(context);

    // Push onto the format stack
    state.formatStack.add(
      FormatStackEntry(
        index: index,
        matchingIndex: state.matchingPairs[index]!,
        type: token.type,
      ),
    );

    // Mark as processed
    state.processedIndices.add(index);

    return null;
  }

  /// Handles a closing formatting marker.
  ///
  /// This method removes the corresponding marker from the format stack
  /// and flushes accumulated text with the current formatting.
  ///
  /// @param context The BuildContext
  /// @param state The current parser state
  /// @param index The index of the token being processed
  /// @param matchingIndex The index of the matching opening marker
  /// @return The new token index after processing, or null if no index change
  static int? _handleClosingMarker(
    BuildContext context,
    ParserState state,
    int index,
    int matchingIndex,
  ) {
    // Mark as processed
    state.processedIndices.add(index);

    // Find and remove the matching entry from the format stack
    int stackIndex = -1;
    for (int j = state.formatStack.length - 1; j >= 0; j--) {
      if (state.formatStack[j].index == matchingIndex) {
        stackIndex = j;
        break;
      }
    }

    if (stackIndex != -1) {
      // First flush the text with formatting still applied
      state.flushText(context);

      // Then remove the entry from the stack
      state.formatStack.removeAt(stackIndex);
    } else {
      // No matching format found, just flush text
      state.flushText(context);
    }

    return null;
  }
}
