import '../core/constants.dart';
import '../models/token.dart';

/// Tokenizes text into formatting markers and content segments.
///
/// The TextfTokenizer breaks down input text into a sequence of [Token] objects that
/// represent either formatting markers (like bold, italic) or regular text content.
/// It focuses solely on identifying tokens without validating their pairing or nesting.
///
/// This class is optimized for performance with a character-by-character approach
/// and special handling for escape sequences.
///
/// Example:
/// ```
/// final tokenizer = TextfTokenizer();
/// final tokens = tokenizer.tokenize('Hello **world**');
/// // Results in 3 tokens: "Hello ", "**" (bold marker), "world", "**" (bold marker)
/// ```
class TextfTokenizer {
  /// Tokenizes the input text into a list of [Token] objects.
  ///
  /// This method processes the text character by character, identifying formatting
  /// markers and regular text segments. It recognizes:
  /// - Bold markers: ** or __
  /// - Italic markers: * or _
  /// - Bold+Italic markers: *** or ___
  /// - Strikethrough markers: ~~
  /// - Code markers: `
  /// - Escaped characters: \* \_ \~ \` \\
  ///
  /// The method is optimized for performance by:
  /// - Pre-processing text into code units
  /// - Using direct character code comparisons
  /// - Minimizing string operations
  ///
  /// @param text The input text to tokenize
  /// @return A list of [Token] objects representing the text components
  List<Token> tokenize(String text) {
    final tokens = <Token>[];
    int pos = 0;
    int textStart = 0;
    final int length = text.length;

    // Helper to add accumulated text as a token
    void addTextToken(int start, int end) {
      if (end > start) {
        tokens.add(Token(TokenType.text, text.substring(start, end), start, end - start));
      }
    }

    // Performance optimization: pre-process code units
    final List<int> codeUnits = text.codeUnits;

    while (pos < length) {
      final int startPos = pos;
      final int currentChar = codeUnits[pos];

      // Handle escape character
      if (currentChar == kEscape && pos + 1 < length) {
        final int nextChar = codeUnits[pos + 1];
        // Check if next char is a formatting character
        if (nextChar == kAsterisk ||
            nextChar == kUnderscore ||
            nextChar == kTilde ||
            nextChar == kEscape ||
            nextChar == kBacktick) {
          addTextToken(textStart, pos);
          // Just add the escaped character as normal text
          tokens.add(Token(TokenType.text, String.fromCharCode(nextChar), pos + 1, 1));
          pos += 2;
          textStart = pos;
          continue;
        }
      }

      // Identify token patterns without semantic interpretation
      if (currentChar == kAsterisk) {
        // Check for bold+italic (***)
        if (pos + 2 < length && codeUnits[pos + 1] == kAsterisk && codeUnits[pos + 2] == kAsterisk) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.boldItalicMarker, '***', pos, 3));
          pos += 3;
          textStart = pos;
        }
        // Check for bold (**)
        else if (pos + 1 < length && codeUnits[pos + 1] == kAsterisk) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.boldMarker, '**', pos, 2));
          pos += 2;
          textStart = pos;
        }
        // Italic (*)
        else {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.italicMarker, '*', pos, 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kUnderscore) {
        // Check for bold+italic (___)
        if (pos + 2 < length && codeUnits[pos + 1] == kUnderscore && codeUnits[pos + 2] == kUnderscore) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.boldItalicMarker, '___', pos, 3));
          pos += 3;
          textStart = pos;
        }
        // Check for bold (__)
        else if (pos + 1 < length && codeUnits[pos + 1] == kUnderscore) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.boldMarker, '__', pos, 2));
          pos += 2;
          textStart = pos;
        }
        // Italic (_)
        else {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.italicMarker, '_', pos, 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kTilde) {
        // Check for strikethrough (~~)
        if (pos + 1 < length && codeUnits[pos + 1] == kTilde) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.strikeMarker, '~~', pos, 2));
          pos += 2;
          textStart = pos;
        } else {
          pos++;
        }
      } else if (currentChar == kBacktick) {
        // Inline code (`)
        addTextToken(textStart, pos);
        tokens.add(Token(TokenType.codeMarker, '`', pos, 1));
        pos++;
        textStart = pos;
      } else {
        pos++;
      }

      // Safety check to ensure forward progress
      if (pos == startPos) {
        // TODO - add warning: no progress made in tokenization, could be an infinite loop
        pos++; // Ensure we always advance
      }
    }

    // Add any remaining text
    addTextToken(textStart, pos);

    return tokens;
  }
}
