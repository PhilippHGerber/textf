// File: lib/src/parsing/components/link_handler.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/default_styles.dart';
import '../../core/formatting_utils.dart';
import '../../models/parser_state.dart';
import '../../models/token.dart';
import '../../widgets/internal/hoverable_link_span.dart';
import '../parser.dart';
import 'style_applicator.dart';

/// Handles the processing of link tokens during parsing.
///
/// This class contains methods for recognizing and building URL links
/// in the text, including support for formatted text within links.
/// It now generates WidgetSpans containing _HoverableLinkSpan widgets
/// to handle hover effects internally.
class LinkHandler {
  /// Processes a link token sequence and updates the parser state.
  ///
  /// This method handles complete link structures ([text](url)) and creates
  /// WidgetSpans containing interactive _HoverableLinkSpan widgets.
  /// It supports formatting within the link text.
  ///
  /// Returns the new token index after processing the link structure,
  /// or null if the current token doesn't start a valid link.
  static int? processLink(
    BuildContext context,
    ParserState state,
    int index,
  ) {
    // Flush any existing text before processing the potential link
    state.flushText(context);

    final tokens = state.tokens;

    // Check if we have a complete link structure: [ text ]( url )
    if (_isCompleteLink(tokens, index)) {
      // Extract relevant tokens
      final linkTextToken = tokens[index + 1];
      final linkUrlToken = tokens[index + 3];
      final rawLinkText = linkTextToken.value;
      final rawLinkUrl = linkUrlToken.value;
      final normalizedUrl = _normalizeUrl(rawLinkUrl);

      // Build the WidgetSpan containing the interactive link widget
      final widgetSpan = _buildLinkWidgetSpan(
        context,
        state,
        normalizedUrl,
        rawLinkText,
      );

      // Add the generated WidgetSpan to the list of spans
      state.spans.add(widgetSpan);

      // Mark all tokens belonging to this link structure as processed
      _markLinkTokensProcessed(state, index);

      // Return the index *after* the closing parenthesis ')' of the link
      // (index + 4 is the closing paren, so next index is index + 5)
      return index + 4;
    } else {
      // Malformed link or just an opening bracket, treat '[' as plain text
      state.textBuffer += tokens[index].value; // Add '[' to buffer
      state.processedIndices.add(index); // Mark bracket as processed
      return null; // Continue processing next token normally
    }
  }

  /// Checks if tokens form a complete link structure: `[` `text` `](` `text` `)`
  static bool _isCompleteLink(List<Token> tokens, int index) {
    // Needs 5 tokens: linkStart, text, linkSeparator, urlText, linkEnd
    if (index + 4 >= tokens.length) {
      return false;
    }
    return tokens[index].type == TokenType.linkStart &&
        // Link text can be empty, so its token might have empty value
        tokens[index + 1].type == TokenType.text &&
        tokens[index + 2].type == TokenType.linkSeparator &&
        // URL can be empty
        tokens[index + 3].type == TokenType.text &&
        tokens[index + 4].type == TokenType.linkEnd;
  }

  /// Normalizes a URL string (e.g., adds scheme if missing).
  static String _normalizeUrl(String url) {
    url = url.trim();
    // Add http:// scheme if missing for common web URLs
    if (!url.contains(':') && //
        !url.startsWith('/') &&
        !url.startsWith('#') &&
        url.contains('.')) {
      // Basic check: contains a dot and no scheme/protocol/path/fragment start
      return 'http://$url';
    }
    return url;
  }

  /// Marks the 5 tokens of a complete link structure as processed.
  static void _markLinkTokensProcessed(ParserState state, int startIndex) {
    for (int i = 0; i < 5; i++) {
      state.processedIndices.add(startIndex + i);
    }
  }

  /// Builds a WidgetSpan containing an interactive [_HoverableLinkSpan] widget.
  ///
  /// This method gathers all necessary styles, callbacks, and text content
  /// required by the [_HoverableLinkSpan].
  static WidgetSpan _buildLinkWidgetSpan(
    BuildContext context,
    ParserState state,
    String url,
    String rawLinkText,
  ) {
    // 1. Calculate inherited style (remains the same)
    TextStyle inheritedStyle = state.baseStyle;
    for (final entry in state.formatStack) {
      inheritedStyle = StyleApplicator.applyStyle(
        context,
        inheritedStyle,
        entry.type,
        state.options,
      );
    }

    // 2. Get effective normal and hover styles (remains the same)
    final TextStyle finalLinkStyle =
        state.options?.getEffectiveUrlStyle(context, inheritedStyle) ?? DefaultStyles.urlStyle.merge(inheritedStyle);
    final TextStyle finalLinkHoverStyle = state.options?.getEffectiveUrlHoverStyle(context, inheritedStyle) ??
        DefaultStyles.urlHoverStyle.merge(finalLinkStyle);

    // 3. Get effective interaction callbacks and cursor (remains the same)
    final effectiveOnTap = state.options?.getEffectiveOnUrlTap(context);
    final effectiveOnHover = state.options?.getEffectiveOnUrlHover(context);
    final MouseCursor effectiveCursor =
        state.options?.getEffectiveUrlMouseCursor(context) ?? DefaultStyles.urlMouseCursor;

    // 4. Prepare tap recognizer (remains the same)
    TapGestureRecognizer? recognizer;
    if (effectiveOnTap != null) {
      recognizer = TapGestureRecognizer()..onTap = () => effectiveOnTap(url, rawLinkText);
    }

    // 5. PARSE childrenSpans or get plainText HERE again!
    List<InlineSpan> childrenSpans = [];
    String? spanText;

    if (FormattingUtils.hasFormattingMarkers(rawLinkText)) {
      // Parse the inner content using finalLinkStyle as the base
      final innerParser = TextfParser(maxCacheSize: 10);
      childrenSpans = innerParser.parse(
        rawLinkText,
        context,
        finalLinkStyle, // Apply the final NORMAL link style as base for parsing
      );
      spanText = null;
    } else {
      // Link text is plain
      spanText = rawLinkText;
      childrenSpans = [];
    }
    // Now childrenSpans contains spans with combined styles (e.g., bold+linkStyle)
    // or spanText contains the plain text.

    // 6. Create the _HoverableLinkSpan widget instance
    final hoverableWidget = HoverableLinkSpan(
      url: url,
      rawDisplayText: rawLinkText,
      // Pass the PARSED children or plain text
      initialChildrenSpans: childrenSpans,
      initialPlainText: spanText,
      // Pass the SEPARATE styles
      normalStyle: finalLinkStyle,
      hoverStyle: finalLinkHoverStyle,
      // Pass interaction handlers/cursor
      tapRecognizer: recognizer,
      mouseCursor: effectiveCursor,
      onHoverCallback: effectiveOnHover,
    );

    // 7. Create and return the WidgetSpan (remains the same)
    return WidgetSpan(
      child: hoverableWidget,
      // Use baseline alignment to match surrounding text.
      alignment: PlaceholderAlignment.baseline,
      // Specify the alphabetic baseline, which is standard for text.
      baseline: TextBaseline.alphabetic,
    );
  }
}
