import 'package:flutter/material.dart';

import '../../models/format_stack_entry.dart';
import '../../models/parser_state.dart';
import '../../models/token.dart';

/// Handles the processing of formatting tokens (bold, italic, etc.) during parsing.
///
/// This class is responsible for managing the `formatStack` within the `ParserState`
/// based on opening and closing formatting markers identified by the `PairingResolver`.
/// It ensures that `state.flushText()` is called before format changes occur,
/// allowing the `ParserState` (using the `TextfStyleResolver`) to apply the correct
/// style to the text segments.
class FormatHandler {
  /// Processes a formatting token (bold, italic, strike, code) and updates the parser state.
  ///
  /// This method handles both opening and closing formatting markers:
  /// - For opening markers: It flushes any preceding text, adds the marker to the format stack,
  ///   and marks the token as processed.
  /// - For closing markers: It flushes the text *within* the format, removes the corresponding
  ///   marker from the stack, and marks the token as processed.
  /// - Unpaired markers are treated as plain text (handled by the caller loop in TextfParser).
  ///
  /// - [context]: The BuildContext, needed by `state.flushText`.
  /// - [state]: The current parser state holding the tokens, stack, buffer, etc.
  /// - [index]: The index of the token being processed in `state.tokens`.
  /// - [token]: The formatting token to process.
  static void processFormat(
    BuildContext context,
    ParserState state,
    int index,
    Token token,
  ) {
    // Find the index of the matching counterpart for this token.
    // This relies on the pre-calculated `matchingPairs` map in the state,
    // which only contains valid, nested pairs.
    final int? matchingIndex = state.matchingPairs[index];

    if (matchingIndex != null) {
      // This is a valid formatting marker with a matching pair.
      if (matchingIndex > index) {
        // This is an OPENING marker (its match is further down the list).
        _handleOpeningMarker(context, state, index, token, matchingIndex);
      } else {
        // This is a CLOSING marker (its match is earlier in the list).
        _handleClosingMarker(context, state, index, matchingIndex);
      }
    }
    // If matchingIndex is null, it's an unpaired marker.
    // The main loop in TextfParser should handle adding unpaired markers
    // to the text buffer as plain text before calling this function.
    // No action needed here for unpaired markers.
  }

  /// Handles an opening formatting marker.
  ///
  /// Flushes any preceding text, pushes the new format onto the stack,
  /// and marks the token as processed.
  static void _handleOpeningMarker(
    BuildContext context,
    ParserState state,
    int index,
    Token token,
    int matchingIndex, // Index of the corresponding closing marker
  ) {
    // Flush any accumulated text *before* this new formatting starts.
    // The flushed text will have the style active *before* this marker.
    state.flushText(context);

    // Push the new format onto the stack.
    state.formatStack.add(
      FormatStackEntry(
        index: index, // Store index of this opening marker
        matchingIndex: matchingIndex, // Store index of its closing counterpart
        type: token.type, // Store the type of format being applied
      ),
    );

    // Mark this opening marker token as processed so the main loop skips it.
    state.processedIndices.add(index);
  }

  /// Handles a closing formatting marker.
  ///
  /// Flushes the text segment that was *inside* the format being closed,
  /// removes the corresponding format entry from the stack, and marks
  /// the token as processed.
  static void _handleClosingMarker(
    BuildContext context,
    ParserState state,
    int index, // The index of this closing marker token
    int matchingIndex, // The index of the corresponding opening marker
  ) {
    // First, flush the text that was formatted with the style we are about to remove.
    // `flushText` uses the current `formatStack` (which still includes the style
    // being closed) to calculate the style.
    state.flushText(context);

    // Mark this closing marker token as processed.
    state.processedIndices.add(index);

    // Find and remove the corresponding opening entry from the format stack.
    // We search from the end of the stack for the entry whose `index` matches
    // the `matchingIndex` of the closing marker we are handling.
    int stackIndexToRemove = -1;
    for (int j = state.formatStack.length - 1; j >= 0; j--) {
      if (state.formatStack[j].index == matchingIndex) {
        stackIndexToRemove = j;
        break;
      }
    }

    // If found (which it should be, as we only process valid pairs), remove it.
    if (stackIndexToRemove != -1) {
      state.formatStack.removeAt(stackIndexToRemove);
    }
    // If not found (unexpected, indicates an issue in pairing/nesting logic),
    // we've already flushed the text, so the visual result might be reasonable,
    // but it indicates a potential internal inconsistency. No error is thrown here.
  }
}
