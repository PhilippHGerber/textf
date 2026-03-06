import '../models/textf_token.dart';
import '../parsing/components/pairing_resolver.dart';
import '../parsing/textf_tokenizer.dart';
import 'constants.dart';

/// Utility functions for text formatting operations.
class FormattingUtils {
  /// Checks if text contains any potential formatting characters.
  ///
  /// This is an optimization to quickly determine if text needs
  /// further parsing for formatting.
  ///
  /// This includes all characters that might trigger special formatting:
  /// asterisks, underscores, tildes, backticks, escapes, and the *start* characters
  /// for links ([) and placeholders ({).
  ///
  /// Closing characters (], ), }) are NOT included because they are only
  /// significant if preceded by their opening counterparts.
  static bool hasFormatting(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk ||
          char == kUnderscore ||
          char == kTilde ||
          char == kBacktick ||
          char == kEquals ||
          char == kCaret ||
          char == kPlus ||
          char == kEscape ||
          char == kOpenBracket ||
          char == kOpenBrace) {
        return true;
      }
    }

    return false;
  }

  /// Checks if text contains formatting marker characters only.
  ///
  /// This specifically checks for characters that indicate text styling
  /// (bold, italic, strikethrough, code) but not structural elements like links
  /// or placeholders.
  /// Use this when checking for formatting within link text or other contexts
  /// where link/placeholder syntax itself should be treated as literal text.
  static bool hasFormattingMarkers(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk || // *
          char == kUnderscore || // _
          char == kTilde || // ~
          char == kBacktick || // `
          char == kEquals || // =
          char == kCaret || // ^
          char == kPlus || // +
          char == kEscape) {
        // \
        return true;
      }
    }

    return false;
  }

  /// Strips all valid textf formatting markers from the string, returning plain text.
  ///
  /// This method safely removes paired markers (e.g., `**`, `~~`), extracts the
  /// display text from links (`[text](url)` -> `text`), and removes escape
  /// backslashes. Unpaired markers (e.g., `2 * 3`) and widget placeholders
  /// (e.g., `{icon}`) are left untouched.
  static String stripFormatting(String text) {
    if (!hasFormatting(text)) return text;

    final tokenizer = TextfTokenizer();
    final tokens = tokenizer.tokenize(text);
    final validPairs = PairingResolver.identifyPairs(tokens);

    final buffer = StringBuffer();
    int i = 0;

    while (i < tokens.length) {
      final token = tokens[i];

      if (token is TextToken) {
        buffer.write(token.value);
        i++;
      } else if (token is FormatMarkerToken) {
        if (validPairs.containsKey(i)) {
          // It's a valid paired marker, skip it completely
          i++;
        } else {
          // Unpaired marker, treat as literal plain text
          buffer.write(token.value);
          i++;
        }
      } else if (token is LinkStartToken) {
        if (_isCompleteLink(tokens, i)) {
          // Extract the link text and recursively strip any nested formatting
          final linkText = (tokens[i + kLinkTextOffset] as TextToken).value;
          buffer.write(stripFormatting(linkText));
          i += kLinkTokenCount; // Skip the entire link token link structure
        } else {
          // Broken link syntax, write literal bracket
          buffer.write('[');
          i++;
        }
      } else if (token is LinkSeparatorToken) {
        buffer.write('](');
        i++;
      } else if (token is LinkEndToken) {
        buffer.write(')');
        i++;
      } else if (token is PlaceholderToken) {
        buffer.write('{${token.key}}');
        i++;
      } else if (token is EscapeMarkerToken) {
        // Skip the backslash itself. The escaped character is always the
        // next token (TextToken), which will be written in the next iteration.
        i++;
      }
    }

    return buffer.toString();
  }

  /// Helper to verify a complete link structure.
  static bool _isCompleteLink(List<TextfToken> tokens, int index) {
    if (index + kLinkEndTokenOffset >= tokens.length) return false;

    return tokens[index] is LinkStartToken &&
        tokens[index + kLinkTextOffset] is TextToken &&
        (tokens[index + kLinkTextOffset] as TextToken).value.isNotEmpty &&
        tokens[index + kLinkSeparatorOffset] is LinkSeparatorToken &&
        tokens[index + kLinkUrlOffset] is TextToken &&
        tokens[index + kLinkEndTokenOffset] is LinkEndToken;
  }
}
