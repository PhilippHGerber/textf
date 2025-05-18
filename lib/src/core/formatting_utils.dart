import 'constants.dart';

/// Utility functions for text formatting operations.
class FormattingUtils {
  /// Checks if text contains any potential formatting characters.
  ///
  ///
  /// This is an optimization to quickly determine if text needs
  /// further parsing for formatting.
  ///
  /// This includes all characters that might trigger special formatting:
  /// asterisks, underscores, tildes, backticks, brackets, parentheses, and escapes.
  /// Use this for initial fast-path detection of potential formatting.
  static bool hasFormatting(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk ||
          char == kUnderscore ||
          char == kTilde ||
          char == kBacktick ||
          char == kEquals ||
          char == kPlus ||
          char == kEscape ||
          char == kOpenBracket ||
          char == kCloseBracket ||
          char == kOpenParen ||
          char == kCloseParen) {
        return true;
      }
    }
    return false;
  }

  /// Checks if text contains formatting marker characters only.
  ///
  /// This specifically checks for characters that indicate text styling
  /// (bold, italic, strikethrough, code) but not structural elements like links.
  /// Use this when checking for formatting within link text or other contexts
  /// where link syntax itself should be ignored.
  static bool hasFormattingMarkers(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk || // *
          char == kUnderscore || // _
          char == kTilde || // ~
          char == kBacktick || // `
          char == kEquals || // =
          char == kPlus || // +
          char == kEscape) {
        // \
        return true;
      }
    }
    return false;
  }
}
