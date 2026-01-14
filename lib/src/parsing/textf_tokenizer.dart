// ignore_for_file: no-magic-number

import '../core/constants.dart';
import '../models/token_type.dart';

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
/// ```dart
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
  /// - Underline markers: ++
  /// - Highlight markers: ==
  /// - Escaped characters: \* \_ \~ \` \\ \+ \= \[ \] \( \)
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
        tokens.add(
          Token(
            TokenType.text,
            // The `avoid_substring` lint is ignored here for specific, performance-critical reasons.
            // This tokenizer works by iterating through the string's UTF-16 code units and
            // tracking positions (`start`, `end`) as code unit indices, not as grapheme clusters
            // (user-perceived characters).
            //
            // 1. **Consistency**: The entire tokenizer's logic, including its loop counters and
            //    marker detection, is based on UTF-16 code unit indices. Using `substring`, which
            //    also operates on these indices, ensures perfect alignment and correctness within
            //    this specific algorithm.
            //
            // 2. **Safety**: Since `start` and `end` are guaranteed by the tokenizer's logic to
            //    never fall within the middle of a multi-byte character sequence (they always
            //    point to the boundaries between characters or markers), using `substring` is
            //    safe in this context and will not slice characters apart.
            //
            // For these reasons, `substring` is the correct and necessary choice for this low-level
            // parsing task, despite the general validity of the linting rule for UI-level text manipulation.
            // ignore: avoid-substring
            text.substring(start, end),
            start,
            end - start,
          ),
        );
      }
    }

    // Performance optimization: pre-process code units
    final List<int> codeUnits = text.codeUnits;

    while (pos < length) {
      final int startPosInLoop = pos;
      final int currentChar = codeUnits[pos];

      // Handle escape character
      if (currentChar == kEscape && pos + 1 < length) {
        final int nextChar = codeUnits[pos + 1];
        // Check if next char is a formatting character or link-related character
        if (nextChar == kAsterisk ||
            nextChar == kUnderscore ||
            nextChar == kTilde ||
            nextChar == kBacktick ||
            nextChar == kPlus ||
            nextChar == kEquals ||
            nextChar == kCaret ||
            nextChar == kEscape ||
            nextChar == kOpenBracket ||
            nextChar == kCloseBracket ||
            nextChar == kOpenParen ||
            nextChar == kCloseParen ||
            nextChar == kOpenBrace ||
            nextChar == kCloseBrace) {
          addTextToken(textStart, pos);
          // Just add the escaped character as normal text
          tokens.add(
            Token(
              TokenType.text,
              String.fromCharCode(nextChar),
              pos + 1, // Position of the character itself
              1, // Length of the character itself
            ),
          );
          pos += 2; // Skip escape character and the escaped character
          textStart = pos;
          continue;
        }
      }

      // Identify token patterns without semantic interpretation
      if (currentChar == kAsterisk) {
        // Check for bold+italic (***)
        if (pos + 2 < length && //
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
        if (pos + 2 < length && //
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
          // Single tilde for subscript
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.subscriptMarker, '~', pos, 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kCaret) {
        // Caret for superscript
        addTextToken(textStart, pos);
        tokens.add(Token(TokenType.superscriptMarker, '^', pos, 1));
        pos++;
        textStart = pos;
      } else if (currentChar == kBacktick) {
        // Inline code (`)
        addTextToken(textStart, pos);
        tokens.add(Token(TokenType.codeMarker, '`', pos, 1));
        pos++;
        textStart = pos;
      } else if (currentChar == kPlus) {
        // Check for underline (++)
        if (pos + 1 < length && codeUnits[pos + 1] == kPlus) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.underlineMarker, '++', pos, 2));
          pos += 2;
          textStart = pos;
        } else {
          // Single plus treated as plain text, will be handled by final pos increment
          pos++;
        }
      } else if (currentChar == kEquals) {
        // Check for highlight (==)
        if (pos + 1 < length && codeUnits[pos + 1] == kEquals) {
          addTextToken(textStart, pos);
          tokens.add(Token(TokenType.highlightMarker, '==', pos, 2));
          pos += 2;
          textStart = pos;
        } else {
          // Single equals treated as plain text, will be handled by final pos increment
          pos++;
        }
      } else if (currentChar == kOpenBracket) {
        addTextToken(textStart, pos);
        final int? nextPos = _tryParseLink(text, codeUnits, length, pos, tokens);
        if (nextPos != null) {
          pos = nextPos;
          textStart = pos;
        } else {
          tokens.add(Token(TokenType.text, '[', pos, 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kOpenBrace) {
        addTextToken(textStart, pos);
        final int? nextPos = _tryParsePlaceholder(text, codeUnits, length, pos, tokens);
        if (nextPos != null) {
          pos = nextPos;
          textStart = pos;
        } else {
          tokens.add(Token(TokenType.text, '{', pos, 1));
          pos++;
          textStart = pos;
        }
      } else {
        pos++;
      }

      if (pos == startPosInLoop && pos < length) {
        pos++;
      }
    }

    addTextToken(textStart, pos);
    return tokens;
  }

  /// Attempts to parse a Markdown-style link `[text](url)`.
  ///
  /// Returns the position after the closing parenthesis if successful,
  /// otherwise returns null.
  int? _tryParseLink(
    String text,
    List<int> codeUnits,
    int length,
    int startPos,
    List<Token> tokens,
  ) {
    int pos = startPos + 1; // Move past '['

    // 1. Find the end of link text ']'
    final int linkTextStart = pos;
    int nestLevel = 0;
    int linkTextEnd = -1;

    while (pos < length) {
      // Inner loop for link text
      final int c = codeUnits[pos];
      // Handle escape sequences
      if (c == kEscape && pos + 1 < length) {
        pos += 2;
        continue;
      }
      // Track nested brackets
      if (c == kOpenBracket) {
        nestLevel++;
      } else if (c == kCloseBracket) {
        if (nestLevel > 0) {
          nestLevel--;
        } else {
          // This is the closing bracket for our link text
          linkTextEnd = pos;
          // Check if followed by opening parenthesis for URL
          if (pos + 1 < length && codeUnits[pos + 1] == kOpenParen) {
            break; // Found '](', proceed
          } else {
            return null; // Not part of a complete [text](link)
          }
        }
      }
      pos++;
    }

    if (linkTextEnd == -1 || pos + 1 >= length || codeUnits[pos + 1] != kOpenParen) {
      return null;
    }

    // 2. Find the end of URL ')'
    final int urlStart = linkTextEnd + 2;
    pos = urlStart;
    int urlEnd = -1;
    nestLevel = 0;

    while (pos < length) {
      final int c = codeUnits[pos];
      if (c == kEscape && pos + 1 < length) {
        pos += 2;
        continue;
      }
      if (c == kOpenParen) {
        nestLevel++;
      } else if (c == kCloseParen) {
        if (nestLevel > 0) {
          nestLevel--;
        } else {
          urlEnd = pos;
          break;
        }
      }
      pos++;
    }

    if (urlEnd == -1) {
      return null;
    }

    // Successfully parsed a full link structure. Add tokens.
    tokens
      ..add(Token(TokenType.linkStart, '[', startPos, 1))
      ..add(
        Token(
          TokenType.text,
          // ignore: avoid-substring
          text.substring(linkTextStart, linkTextEnd),
          linkTextStart,
          linkTextEnd - linkTextStart,
        ),
      )
      ..add(Token(TokenType.linkSeparator, '](', linkTextEnd, 2))
      ..add(
        Token(
          TokenType.text,
          // ignore: avoid-substring
          text.substring(urlStart, urlEnd),
          urlStart,
          urlEnd - urlStart,
        ),
      )
      ..add(Token(TokenType.linkEnd, ')', urlEnd, 1));

    return urlEnd + 1;
  }

  /// Attempts to parse a placeholder `{{N}}`.
  ///
  /// Returns the position after the closing braces if successful,
  /// otherwise returns null.
  int? _tryParsePlaceholder(
    String text,
    List<int> codeUnits,
    int length,
    int startPos,
    List<Token> tokens,
  ) {
    if (startPos + 1 >= length || codeUnits[startPos + 1] != kOpenBrace) {
      return null;
    }

    int pos = startPos + 2; // Move past '{{'
    final int digitsStart = pos;

    while (pos < length) {
      final int c = codeUnits[pos];
      if (c >= 0x30 && c <= 0x39) {
        // Digit 0-9
        pos++;
      } else if (c == kCloseBrace) {
        if (pos + 1 < length && codeUnits[pos + 1] == kCloseBrace) {
          // Found '}}'
          if (pos > digitsStart) {
            // We have at least one digit
            tokens.add(
              Token(
                TokenType.placeholder,
                // ignore: avoid-substring
                text.substring(startPos, pos + 2),
                startPos,
                pos + 2 - startPos,
              ),
            );
            return pos + 2;
          } else {
            // Empty placeholder '{{}}' - treat as text
            return null;
          }
        } else {
          // Single '}' - invalid for placeholder, treat as text
          return null;
        }
      } else {
        // Non-digit char inside - treat as text
        return null;
      }
    }

    return null;
  }
}
