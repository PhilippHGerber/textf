import 'package:flutter/material.dart';

import '../../models/format_stack_entry.dart';
import '../../models/parser_state.dart';
import '../../models/token_type.dart';

/// Handles the processing of placeholder tokens (e.g., {0}) during parsing.
///
/// This class is responsible for:
/// 1. Parsing the index from the token.
/// 2. Validating the index against the provided [InlineSpan]s list.
/// 3. If valid: Flushing pending text and inserting the span.
/// 4. If invalid: Appending the raw placeholder text to the buffer (no flush).
class PlaceholderHandler {
  /// Processes a placeholder token and updates the parser state.
  static void processPlaceholder(
    BuildContext context,
    ParserState state,
    Token token,
  ) {
    // 1. Parse the integer index from the token value (e.g., "0" -> 0).
    final int? index = int.tryParse(token.value);

    // Capture the list locally to enable type promotion and avoid non-null assertions (!).
    final List<InlineSpan>? spans = state.inlineSpans;

    // 2. Validate existence and bounds.
    if (index != null && spans != null && index >= 0 && index < spans.length) {
      // Valid placeholder found.
      // We MUST flush preceding text now to preserve order before inserting the widget.
      state.flushText(context);

      // Pass the specific span directly to avoid re-checking bounds/nullability.
      _insertStyledPlaceholder(context, state, spans[index]);
    } else {
      // Invalid placeholder or null list.
      // Do NOT flush. Just append the literal text to the buffer.
      // This ensures "Hello " + "{0}" remain a single text span.
      _handleFallback(state, token);
    }
  }

  /// Inserts the [userSpan] wrapped in the current active styles.
  static void _insertStyledPlaceholder(
    BuildContext context,
    ParserState state,
    InlineSpan userSpan,
  ) {
    // Resolve the effective style from the current stack (e.g., base + bold + italic).
    TextStyle currentStyle = state.baseStyle;
    for (final FormatStackEntry entry in state.formatStack) {
      currentStyle = state.styleResolver.resolveStyle(entry.type, currentStyle);
    }

    // We wrap the user's span in a TextSpan that carries the current calculated style.
    // Flutter's TextSpan inheritance logic ensures that if 'userSpan' is a TextSpan
    // without an explicit style, it will inherit 'currentStyle'.
    // If 'userSpan' is a WidgetSpan, the style is generally ignored by the widget,
    // which is standard Flutter behavior, but alignment is preserved.
    state.spans.add(
      TextSpan(
        style: currentStyle,
        children: [userSpan],
      ),
    );
  }

  /// Handles invalid placeholders by treating them as literal text.
  static void _handleFallback(ParserState state, Token token) {
    // Reconstruct the brace syntax. The tokenizer stripped the braces
    // to store the raw digit value.
    // e.g. token.value is "0", we append "{0}" to the buffer.
    state.textBuffer += '{${token.value}}';
  }
}
