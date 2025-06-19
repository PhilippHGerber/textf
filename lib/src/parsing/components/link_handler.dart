import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/parser_state.dart';
import '../../models/token_type.dart';
import '../../widgets/internal/hoverable_link_span.dart';
import '../textf_parser.dart';
import '../textf_tokenizer.dart';

/// Handles the processing of link tokens during parsing.
///
/// This class recognizes complete link structures `[text](url)` and creates
/// interactive `WidgetSpan`s containing `HoverableLinkSpan` widgets.
/// It utilizes the `TextfStyleResolver` from the `ParserState` to determine
/// link-specific styling (normal, hover), mouse cursor, and interaction callbacks,
/// considering `TextfOptions`, `Theme`, and defaults.
class LinkHandler {
  // Link structure constants
  static const int _linkTextOffset = 1;
  static const int _linkSeparatorOffset = 2;
  static const int _linkUrlOffset = 3;
  static const int _linkEndOffset = 4;
  static const int _linkTokenCount = 5;

  /// Processes a potential link structure starting at the given `index`.
  ///
  /// If a valid `[text](url)` structure is found:
  /// 1. Calculates the style inherited from surrounding formatting markers.
  /// 2. Uses the `styleResolver` in `state` to get the final normal style,
  ///    hover style, cursor, and callbacks for the link.
  /// 3. Parses the `text` part of the link for any nested formatting, using
  ///    the resolved normal link style as the base for this inner parsing.
  /// 4. Creates a `HoverableLinkSpan` widget within a `WidgetSpan`.
  /// 5. Adds the `WidgetSpan` to `state.spans`.
  /// 6. Marks the consumed link tokens as processed in `state.processedIndices`.
  /// 7. Returns the index immediately following the link structure.
  ///
  /// If no valid link structure is found, it treats the starting `[` as plain text,
  /// adds it to the `state.textBuffer`, marks it as processed, and returns `null`.
  ///
  /// - [context]: The BuildContext (passed down, potentially used by callbacks).
  /// - [state]: The current parser state containing tokens, stack, resolver, etc.
  /// - [index]: The index of the `TokenType.linkStart` token (`[`).
  ///
  /// Returns the new token index after processing the link structure, or `null`.
  static int? processLink(
    BuildContext context, // Keep context for potential callback needs
    ParserState state,
    int index,
  ) {
    // Flush any preceding text before potentially starting a link
    state.flushText(context);

    final tokens = state.tokens;

    // Check if the sequence starting at `index` forms a complete link structure
    if (_isCompleteLink(tokens, index)) {
      // --- Valid Link Found ---

      // Extract raw text and URL
      final linkTextToken = tokens[index + _linkTextOffset];
      final linkUrlToken = tokens[index + _linkUrlOffset];
      final rawLinkText = linkTextToken.value;
      final rawLinkUrl = linkUrlToken.value;
      final normalizedUrl = normalizeUrl(rawLinkUrl);

      // 1. Calculate the style inherited from formatting markers *outside* the link
      TextStyle inheritedStyle = state.baseStyle;
      for (final entry in state.formatStack) {
        // Use the resolver to apply styles from the current stack
        inheritedStyle = state.styleResolver.resolveStyle(entry.type, inheritedStyle);
      }

      // 2. Resolve link-specific styles, cursor, and callbacks using the resolver
      //    Pass the calculated inheritedStyle as the base for link style resolution.
      final TextStyle finalLinkStyle = state.styleResolver.resolveLinkStyle(inheritedStyle);
      final TextStyle finalLinkHoverStyle = state.styleResolver.resolveLinkHoverStyle(inheritedStyle);
      final MouseCursor effectiveCursor = state.styleResolver.resolveLinkMouseCursor();
      final void Function(String url, String displayText)? effectiveOnTap = state.styleResolver.resolveOnUrlTap();
      final void Function(String url, String displayText, {required bool isHovering})? effectiveOnHover =
          state.styleResolver.resolveOnUrlHover();

      // 3. Prepare TapGestureRecognizer if needed
      TapGestureRecognizer? recognizer;
      if (effectiveOnTap != null) {
        recognizer = TapGestureRecognizer()..onTap = () => effectiveOnTap(normalizedUrl, rawLinkText);
        // Remember to handle recognizer disposal if necessary, usually managed
        // by the widget holding the TextSpan tree (e.g., dispose in HoverableLinkSpanState).
      }

      // 4. Parse the inner link text (between []) for nested formatting
      List<InlineSpan> childrenSpans = [];
      String? spanText; // Will hold plain text if no inner formatting

      final tokenizerForLinkText = TextfTokenizer();
      final linkTextTokens = tokenizerForLinkText.tokenize(rawLinkText);
      final bool containsFormattingMarkers = linkTextTokens.any((token) => token.type != TokenType.text);

      if (containsFormattingMarkers) {
        // Parse inner content, using the *resolved normal link style* as the base
        final innerParser = TextfParser(); // Use a separate parser instance
        childrenSpans = innerParser.parse(
          rawLinkText,
          context, // Pass context for the inner parse
          finalLinkStyle, // Use the calculated link style as base
        );
        spanText = null;
      } else {
        // Plain text content, remove escape characters
        spanText = rawLinkText.replaceAllMapped(
          RegExp(r'\\([*_~`\[\]()\\])'),
          (match) => match.group(1) ?? '',
        );
        childrenSpans = [];
      }

      // 5. Create the HoverableLinkSpan widget
      final hoverableWidget = HoverableLinkSpan(
        url: normalizedUrl,
        rawDisplayText: rawLinkText,
        initialChildrenSpans: childrenSpans, // Parsed inner content
        initialPlainText: spanText, // Plain inner content
        normalStyle: finalLinkStyle, // Resolved normal style
        hoverStyle: finalLinkHoverStyle, // Resolved hover style
        tapRecognizer: recognizer,
        mouseCursor: effectiveCursor, // Resolved cursor
        onHoverCallback: effectiveOnHover, // Resolved hover callback
      );

      // 6. Add the widget as a WidgetSpan
      state.spans.add(
        WidgetSpan(
          child: hoverableWidget,
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
        ),
      );

      // 7. Mark all 5 link tokens as processed
      _markLinkTokensProcessed(state, index);

      // 8. Return the index *after* the link structure (after ')')
      return index + _linkTokenCount;
    } else {
      // --- Not a valid link structure ---
      // Treat the opening bracket '[' as plain text.
      state.textBuffer += tokens[index].value; // Add '[' character
      state.processedIndices.add(index); // Mark '[' as processed

      // Let the main parsing loop continue from the next token
      return null;
    }
  }

  /// Normalizes a URL string (e.g., adds 'http://' if scheme is missing).
  @visibleForTesting
  static String normalizeUrl(String url) {
    final String normalizedUrl = url.trim();
    if (!normalizedUrl.contains(':') && //
        !normalizedUrl.startsWith('/') &&
        !normalizedUrl.startsWith('#') &&
        normalizedUrl.contains('.')) {
      return 'http://$normalizedUrl';
    }

    return normalizedUrl;
  }

  /// Checks if tokens starting at `index` form a complete `[text](url)` structure.
  static bool _isCompleteLink(List<Token> tokens, int index) {
    // Needs 5 tokens: linkStart, text, linkSeparator, urlText, linkEnd
    if (index + _linkEndOffset >= tokens.length) {
      return false;
    }

    return tokens[index].type == TokenType.linkStart &&
        tokens[index + _linkTextOffset].type == TokenType.text && // Link text (can be empty)
        tokens[index + _linkSeparatorOffset].type == TokenType.linkSeparator && // `](`
        tokens[index + _linkUrlOffset].type == TokenType.text && // URL text (can be empty)
        tokens[index + _linkEndOffset].type == TokenType.linkEnd; // `)`
  }

  /// Marks the 5 tokens forming a complete link structure as processed.
  static void _markLinkTokensProcessed(ParserState state, int startIndex) {
    // Mark '[', 'text', '](', 'url', ')' as processed
    for (int i = 0; i < _linkTokenCount; i++) {
      state.processedIndices.add(startIndex + i);
    }
  }
}
