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
        tokens.add(Token(
            TokenType.text, text.substring(start, end), start, end - start));
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
        // Check if next char is a formatting character or link-related character
        if (nextChar == kAsterisk ||
            nextChar == kUnderscore ||
            nextChar == kTilde ||
            nextChar == kEscape ||
            nextChar == kBacktick ||
            nextChar == kOpenBracket ||
            nextChar == kCloseBracket ||
            nextChar == kOpenParen ||
            nextChar == kCloseParen) {
          addTextToken(textStart, pos);
          // Just add the escaped character as normal text
          tokens.add(
              Token(TokenType.text, String.fromCharCode(nextChar), pos + 1, 1));
          pos += 2;
          textStart = pos;
          continue;
        }
      }

      // Identify token patterns without semantic interpretation
      if (currentChar == kAsterisk) {
        // Check for bold+italic (***)
        if (pos + 2 < length &&
            codeUnits[pos + 1] == kAsterisk &&
            codeUnits[pos + 2] == kAsterisk) {
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
        if (pos + 2 < length &&
            codeUnits[pos + 1] == kUnderscore &&
            codeUnits[pos + 2] == kUnderscore) {
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
      } else if (currentChar == kOpenBracket) {
        // Opening square bracket for link
        addTextToken(textStart, pos);

        // Start link parsing
        final int linkStartPos = pos;
        pos++; // Move past '['

        // Find the end of link text
        int linkTextStart = pos;
        int nestLevel = 0;
        int linkTextEnd = -1;

        while (pos < length) {
          final int c = codeUnits[pos];

          // Handle escape sequences
          if (c == kEscape && pos + 1 < length) {
            pos += 2; // Skip escape and next character
            continue;
          }

          // Track nested brackets if we find them
          if (c == kOpenBracket) {
            nestLevel++;
          } else if (c == kCloseBracket) {
            if (nestLevel > 0) {
              nestLevel--;
            } else {
              // This is the closing bracket for our link
              linkTextEnd = pos;

              // Check if followed by opening parenthesis for URL
              if (pos + 1 < length && codeUnits[pos + 1] == kOpenParen) {
                break;
              } else {
                // Not a link, just bracket notation
                linkTextEnd = -1;
                pos++;
                continue;
              }
            }
          }

          pos++;
        }

        // If we found a proper link structure "[text]("
        if (linkTextEnd != -1 && pos + 1 < length) {
          // Add the opening bracket
          tokens.add(Token(TokenType.linkStart, '[', linkStartPos, 1));

          // Add the link text
          if (linkTextEnd > linkTextStart) {
            tokens.add(
              Token(
                TokenType.text,
                text.substring(linkTextStart, linkTextEnd),
                linkTextStart,
                linkTextEnd - linkTextStart,
              ),
            );
          } else {
            // Empty link text
            tokens.add(Token(TokenType.text, '', linkTextStart, 0));
          }

          // Add the link separator ")("
          pos = linkTextEnd; // Position at closing bracket
          tokens.add(Token(TokenType.linkSeparator, '](', pos, 2));
          pos += 2; // Move past "]("

          // Now collect the URL
          int urlStart = pos;
          int urlEnd = -1;
          nestLevel = 0;

          while (pos < length) {
            final int c = codeUnits[pos];

            // Handle escape sequences
            if (c == kEscape && pos + 1 < length) {
              pos += 2;
              continue;
            }

            // Track nested parentheses
            if (c == kOpenParen) {
              nestLevel++;
            } else if (c == kCloseParen) {
              if (nestLevel > 0) {
                nestLevel--;
              } else {
                // This is the closing parenthesis for our URL
                urlEnd = pos;
                break;
              }
            }

            pos++;
          }

          // If we found a proper URL end
          if (urlEnd != -1) {
            // Add the URL
            if (urlEnd > urlStart) {
              tokens.add(Token(TokenType.text, text.substring(urlStart, urlEnd),
                  urlStart, urlEnd - urlStart));
            } else {
              // Empty URL
              tokens.add(Token(TokenType.text, '', urlStart, 0));
            }

            // Add the closing parenthesis
            tokens.add(Token(TokenType.linkEnd, ')', urlEnd, 1));
            pos = urlEnd + 1; // Move past ')'

            // Update text start position
            textStart = pos;
          } else {
            // Malformed URL, revert to treating the whole thing as text
            pos = linkStartPos + 1;
            textStart = linkStartPos;
          }
        } else {
          // Not a link, just an opening bracket
          tokens.add(Token(TokenType.text, '[', linkStartPos, 1));
          pos = linkStartPos + 1;
          textStart = pos;
        }
      } else if (currentChar == kCloseBracket ||
          currentChar == kOpenParen ||
          currentChar == kCloseParen) {
        // We handle these characters in the link processing block above
        // Here we just treat them as regular text when encountered outside of link context
        pos++;
      } else {
        // Regular text character, just move forward
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
