import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/default_styles.dart';
import '../../core/formatting_utils.dart';
import '../../models/parser_state.dart';
import '../../models/token.dart';
import '../../models/url_link_span.dart';
import 'format_handler.dart';
import 'style_applicator.dart';

/// Handles the processing of link tokens during parsing.
///
/// This class contains methods for recognizing and building URL links
/// in the text, including support for formatted text within links.
class LinkHandler {
  /// Processes a link token and updates the parser state.
  ///
  /// This method handles complete link structures ([text](url)) and creates
  /// appropriate UrlLinkSpan objects, with support for formatting within the link text.
  ///
  /// @param state The current parser state
  /// @param index The index of the token being processed
  /// @return The new token index after processing, or null if no index change
  static int? processLink(ParserState state, int index) {
    // Flush any existing text
    state.flushText();

    final tokens = state.tokens;

    // Check if we have a complete link structure
    if (_isCompleteLink(tokens, index)) {
      final linkText = tokens[index + 1].value;
      final linkUrl = tokens[index + 3].value;
      final normalizedUrl = _normalizeUrl(linkUrl);

      // Build and add the appropriate span
      state.spans.add(_buildLinkSpan(state, normalizedUrl, linkText));

      // Mark tokens as processed
      _markProcessed(state, index);

      return index + 4; // Skip to after the link
    } else {
      // Malformed link, treat as text
      state.textBuffer += tokens[index].value;
      return null;
    }
  }

  /// Checks if tokens form a complete link structure.
  ///
  /// A complete link structure consists of:
  /// 1. A linkStart token ([)
  /// 2. A text token for the link text
  /// 3. A linkSeparator token (](
  /// 4. A text token for the URL
  /// 5. A linkEnd token ())
  ///
  /// @param tokens The list of tokens to check
  /// @param index The index of the potential linkStart token
  /// @return True if the tokens form a complete link, false otherwise
  static bool _isCompleteLink(List<Token> tokens, int index) {
    return index + 4 < tokens.length &&
        tokens[index].type == TokenType.linkStart &&
        tokens[index + 1].type == TokenType.text &&
        tokens[index + 2].type == TokenType.linkSeparator &&
        tokens[index + 3].type == TokenType.text &&
        tokens[index + 4].type == TokenType.linkEnd;
  }

  /// Normalizes a URL for consistent handling.
  ///
  /// This method:
  /// 1. Trims whitespace from the URL
  /// 2. Adds http:// prefix to domain-like URLs without a protocol
  ///
  /// @param url The URL to normalize
  /// @return The normalized URL
  static String _normalizeUrl(String url) {
    // Trim whitespace
    url = url.trim();

    // Handle common URL patterns
    if (!url.contains(':') &&
        !url.startsWith('/') &&
        !url.startsWith('#') &&
        !url.startsWith('mailto:')) {
      // Look for domain-like patterns
      if (url.contains('.') || url.contains('localhost')) {
        return 'http://$url';
      }
    }

    return url;
  }

  /// Builds a UrlLinkSpan for the link.
  ///
  /// This method creates a UrlLinkSpan with the appropriate styling and behavior,
  /// including support for formatted text within the link text.
  ///
  /// @param state The current parser state
  /// @param url The normalized URL for the link
  /// @param linkText The display text for the link
  /// @return A UrlLinkSpan for the link
  static UrlLinkSpan _buildLinkSpan(
    ParserState state,
    String url,
    String rawLinkText,
  ) {
    // 1. Calculate the style inherited from the current formatting stack
    TextStyle inheritedStyle = state.baseStyle;
    for (final entry in state.formatStack) {
      inheritedStyle = StyleApplicator.applyStyle(
        inheritedStyle,
        entry.type,
        state.options,
      );
    }

    // 2. Get the specific link style configuration from TextfOptions
    //    Note: We merge onto the *original* baseStyle here to get the
    //    intended link color/decoration, avoiding double-merging fontWeight etc.
    //    Alternatively, define linkOptionsStyle independently.
    final TextStyle linkOptionsStyle =
        state.options?.getEffectiveUrlStyle(state.baseStyle) ??
            DefaultStyles.urlStyle.merge(state.baseStyle);

    // 3. Merge the inherited style with the link-specific style.
    //    Properties from linkOptionsStyle (like color, decoration)
    //    will override inherited ones if specified. Inherited properties
    //    (like fontWeight from bold) will be preserved if not in linkOptionsStyle.
    final TextStyle finalLinkStyle = inheritedStyle.merge(linkOptionsStyle);

    // Get the link-specific cursor and hover handlers ONCE
    final MouseCursor cursor = state.options?.getEffectiveUrlMouseCursor() ??
        DefaultStyles.urlMouseCursor;
    PointerEnterEventListener? onEnter;
    PointerExitEventListener? onExit;
    if (state.options?.onUrlHover != null) {
      // Use rawLinkText for the hover callback as decided
      onEnter = (_) => state.options!.onUrlHover!(url, rawLinkText, true);
      onExit = (_) => state.options!.onUrlHover!(url, rawLinkText, false);
    }

    // Prepare child spans and determine final structure
    List<InlineSpan>? finalChildrenSpans;
    String spanText;

    if (FormattingUtils.hasFormattingMarkers(rawLinkText)) {
      final List<Token> linkTextTokens = state.tokenizer.tokenize(rawLinkText);
      // Parse the inner content using the final combined link style as base
      final List<InlineSpan> intermediateChildrenSpans =
          _parseFormattedLinkText(state, linkTextTokens, finalLinkStyle);

      finalChildrenSpans = intermediateChildrenSpans.map((span) {
        if (span is TextSpan) {
          // Create a new TextSpan copying original properties BUT adding hover handlers
          return TextSpan(
            text: span.text,
            // Keep potential nested children
            children: span.children,
            style: span.style,
            // Propagate hover effects, but NOT the recognizer
            mouseCursor: cursor,
            onEnter: onEnter,
            onExit: onExit,
            // Recognizer should stay on the parent UrlLinkSpan
            recognizer: null, // Explicitly null on children
            locale: span.locale,
            semanticsLabel: span.semanticsLabel,
            spellOut: span.spellOut,
          );
        }
        // If other InlineSpan types could appear (unlikely for basic textf), handle them
        return span;
      }).toList();

      // Parent UrlLinkSpan has no direct text when it has children
      spanText = '';
    } else {
      // No formatting, raw text is plain text
      spanText = rawLinkText;
      finalChildrenSpans = null; // No children needed
    }

    // Create gesture recognizer for tap using rawLinkText
    TapGestureRecognizer? recognizer;
    if (state.options?.onUrlTap != null) {
      recognizer = TapGestureRecognizer()
        ..onTap =
            () => state.options!.onUrlTap!(url, rawLinkText); // Use raw text
    }

    // Create the final UrlLinkSpan
    return UrlLinkSpan(
      url: url,
      // Either empty (has children) or rawLinkText (no children)
      text: spanText,
      // Apply the final combined style to the parent span as well
      // This ensures consistent style application if the parent itself had text
      style: finalLinkStyle,
      // Recognizer ONLY on the parent
      recognizer: recognizer,
      // Set hover properties on the PARENT *as well* (for safety/consistency)
      mouseCursor: cursor,
      onEnter: onEnter,
      onExit: onExit,
      // Assign the potentially modified children
      children: finalChildrenSpans,
    );
  }

  /// Parses formatted text within a link.
  ///
  /// This method creates a simplified parser for handling
  /// formatting within link text.
  ///
  /// @param state The current parser state
  /// @param tokens The tokens for the link text
  /// @param urlStyle The base style for the link
  /// @return A list of spans for the formatted link text
  static List<InlineSpan> _parseFormattedLinkText(
      ParserState state, List<Token> tokens, TextStyle linkBaseStyle) {
    // Create a simplified parser state just for the link text
    final linkTextState = ParserState(
      tokens: tokens,
      baseStyle: linkBaseStyle,
      options: state.options,
      tokenizer: state.tokenizer,
      matchingPairs: {}, // Start with empty pairs
    );

    // Identify matching pairs within the link text
    // This is a simplified version that doesn't handle nesting
    for (int i = 0; i < tokens.length - 1; i++) {
      final token = tokens[i];
      if (token.type == TokenType.text) continue;

      // Look for a matching closing marker
      for (int j = i + 1; j < tokens.length; j++) {
        if (tokens[j].type == token.type) {
          linkTextState.matchingPairs[i] = j;
          linkTextState.matchingPairs[j] = i;
          break;
        }
      }
    }

    // Process the tokens
    for (int i = 0; i < tokens.length; i++) {
      if (linkTextState.processedIndices.contains(i)) continue;

      final token = tokens[i];
      if (token.type == TokenType.text) {
        linkTextState.textBuffer += token.value;
      } else {
        FormatHandler.processFormat(linkTextState, i, token);
      }
    }

    // Flush any remaining text
    linkTextState.flushText();

    return linkTextState.spans;
  }

  /// Marks link tokens as processed.
  ///
  /// This method marks all tokens in a complete link structure as processed
  /// so they won't be processed again.
  ///
  /// @param state The current parser state
  /// @param index The index of the linkStart token
  static void _markProcessed(ParserState state, int index) {
    for (int i = 0; i < 5; i++) {
      state.processedIndices.add(index + i);
    }
  }
}
