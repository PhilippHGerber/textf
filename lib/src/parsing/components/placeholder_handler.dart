import 'package:flutter/material.dart';

import '../../models/format_stack_entry.dart';
import '../../models/parser_state.dart';
import '../../models/token_type.dart';

/// Handles the processing of placeholder tokens (e.g., {icon}) during parsing.
///
/// This class is responsible for:
/// 1. Extracting the key from the token.
/// 2. Looking up the key in the provided placeholders map.
/// 3. If found: Flushing pending text and inserting the span.
/// 4. If not found: Appending the raw placeholder text to the buffer (no flush).
class PlaceholderHandler {
  /// Processes a placeholder token and updates the parser state.
  static void processPlaceholder(
    BuildContext context,
    ParserState state,
    Token token,
  ) {
    // 1. The token value is the key (e.g., "icon" from "{icon}").
    final String key = token.value;

    // Capture the map locally.
    final Map<String, InlineSpan>? placeholders = state.placeholders;

    // 2. Lookup the span.
    if (placeholders != null && placeholders.containsKey(key)) {
      final InlineSpan? span = placeholders[key];
      if (span != null) {
        // Valid placeholder found.
        // We MUST flush preceding text now to preserve order before inserting the widget.
        state.flushText(context);

        _insertStyledPlaceholder(context, state, span);
        return;
      }
    }

    // Invalid placeholder (key not found or map is null).
    // Do NOT flush. Just append the literal text to the buffer.
    // This ensures "Hello " + "{icon}" remain a single text span.
    _handleFallback(state, token);
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
    // to store the key value.
    // e.g. token.value is "icon", we append "{icon}" to the buffer.
    state.textBuffer.write('{${token.value}}');
  }
}
