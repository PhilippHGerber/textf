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
  /// Returns the index immediately following the link structure if successful.
  /// Returns `null` if the tokens do not form a valid link.
  static int? processLink(
    BuildContext context,
    ParserState state,
    int index,
  ) {
    final tokens = state.tokens;

    // 1. Fast Check: Do we have a valid link structure?
    // We check this BEFORE flushing text. If it's not a link, we want the
    // '[' character to remain part of the previous text buffer to preserve ligatures.
    if (!_isCompleteLink(tokens, index)) {
      return null;
    }

    // 2. It IS a link. Now we must flush previous text to start a new span.
    state.flushText(context);

    // --- Valid Link Processing ---

    // Extract raw text and URL
    final linkTextToken = tokens[index + _linkTextOffset];
    final linkUrlToken = tokens[index + _linkUrlOffset];
    final rawLinkText = linkTextToken.value;
    final rawLinkUrl = linkUrlToken.value;
    final normalizedUrl = normalizeUrl(rawLinkUrl);

    // Calculate the style inherited from formatting markers *outside* the link
    TextStyle inheritedStyle = state.baseStyle;
    for (final entry in state.formatStack) {
      inheritedStyle = state.styleResolver.resolveStyle(entry.type, inheritedStyle);
    }

    // Resolve link-specific styles and callbacks
    final TextStyle finalLinkStyle = state.styleResolver.resolveLinkStyle(inheritedStyle);
    final TextStyle finalLinkHoverStyle = state.styleResolver.resolveLinkHoverStyle(inheritedStyle);
    final MouseCursor effectiveCursor = state.styleResolver.resolveLinkMouseCursor();
    final void Function(String url, String displayText)? effectiveOnTap =
        state.styleResolver.resolveOnLinkTap();
    final void Function(String url, String displayText, {required bool isHovering})?
        effectiveOnHover = state.styleResolver.resolveOnLinkHover();

    // Prepare TapGestureRecognizer
    TapGestureRecognizer? recognizer;
    if (effectiveOnTap != null) {
      recognizer = TapGestureRecognizer()..onTap = () => effectiveOnTap(normalizedUrl, rawLinkText);
    }

    // Parse the inner link text (between []) for nested formatting
    List<InlineSpan> childrenSpans = [];
    String? spanText;

    final tokenizerForLinkText = TextfTokenizer();
    final linkTextTokens = tokenizerForLinkText.tokenize(rawLinkText);

    // Check if the link text contains any non-text tokens (markers or placeholders)
    final bool containsFormattingMarkers =
        linkTextTokens.any((token) => token.type != TokenType.text);

    if (containsFormattingMarkers) {
      final innerParser = TextfParser();
      // Pass the placeholders down to allow substitution inside links
      childrenSpans = innerParser.parse(
        rawLinkText,
        context,
        finalLinkStyle,
        placeholders: state.placeholders,
      );
      spanText = null;
    } else {
      // Plain text content, remove escape characters
      spanText = rawLinkText.replaceAllMapped(
        RegExp(r'\\([*_~`\[\](){}\\])'),
        (match) => match.group(1) ?? '',
      );
      childrenSpans = [];
    }

    // Create the HoverableLinkSpan widget
    final hoverableWidget = HoverableLinkSpan(
      url: normalizedUrl,
      rawDisplayText: rawLinkText,
      initialChildrenSpans: childrenSpans,
      initialPlainText: spanText,
      normalStyle: finalLinkStyle,
      hoverStyle: finalLinkHoverStyle,
      tapRecognizer: recognizer,
      mouseCursor: effectiveCursor,
      onHoverCallback: effectiveOnHover,
    );

    // Add the widget as a WidgetSpan
    state.spans.add(
      WidgetSpan(
        child: hoverableWidget,
        alignment: state.styleResolver.resolveLinkAlignment(),
        baseline: TextBaseline.alphabetic,
      ),
    );

    // Return the index *after* the link structure (after ')')
    return index + _linkTokenCount;
  }

  /// Normalizes a URL string to ensure it is launchable.
  ///
  /// This method ensures that URLs without a scheme (like "google.com")
  /// are treated as web links by prepending "https://", while preserving
  /// existing schemes (like "https://", "mailto:", "tel:", "file:").
  @visibleForTesting
  static String normalizeUrl(String url) {
    final String normalizedUrl = url.trim();

    if (normalizedUrl.isEmpty) return normalizedUrl;

    // Check if the URL already has a scheme.
    if (_hasScheme(normalizedUrl)) {
      return normalizedUrl;
    }

    // Special handling for anchors (e.g. "#section") and relative paths
    if (normalizedUrl.startsWith('#') || normalizedUrl.startsWith('/')) {
      return normalizedUrl;
    }

    // Fallback: Assume it's a web domain and prepend https://
    return 'https://$normalizedUrl';
  }

  /// Helper to determine if a string starts with a URI scheme.
  ///
  /// Returns true if a colon matches the pattern `scheme:...`
  /// (before any '/', '?', or '#').
  static bool _hasScheme(String url) {
    final int colonIndex = url.indexOf(':');

    // No colon means no scheme.
    if (colonIndex == -1) return false;

    // Find indices of delimiters that would end the authority/path part.
    final int slashIndex = url.indexOf('/');
    final int questionIndex = url.indexOf('?');
    final int hashIndex = url.indexOf('#');

    // If a colon exists, it must appear BEFORE any slash, question mark, or hash
    // to be considered a scheme delimiter.
    // e.g. "google.com/foo:bar" -> colon is after slash -> NO scheme.
    // e.g. "mailto:user" -> colon is before everything -> YES scheme.
    if (slashIndex != -1 && colonIndex > slashIndex) return false;
    if (questionIndex != -1 && colonIndex > questionIndex) return false;
    if (hashIndex != -1 && colonIndex > hashIndex) return false;

    return true;
  }

  /// Checks if tokens starting at `index` form a complete `[text](url)` structure.
  static bool _isCompleteLink(List<Token> tokens, int index) {
    // Needs 5 tokens: linkStart, text, linkSeparator, urlText, linkEnd
    if (index + _linkEndOffset >= tokens.length) {
      return false;
    }

    return tokens[index].type == TokenType.linkStart &&
        (tokens[index + _linkTextOffset].type == TokenType.text ||
            tokens[index + _linkTextOffset].type ==
                TokenType.placeholder) && // Allow placeholders in position check?
        // The outer tokenizer emits link text as a single TokenType.text token,
        // even if it contains placeholders like "{icon}". LinkHandler re-tokenizes
        // the link text internally to support nested formatting and placeholders.
        tokens[index + _linkTextOffset].type == TokenType.text &&
        tokens[index + _linkSeparatorOffset].type == TokenType.linkSeparator &&
        tokens[index + _linkUrlOffset].type == TokenType.text &&
        tokens[index + _linkEndOffset].type == TokenType.linkEnd;
  }
}
