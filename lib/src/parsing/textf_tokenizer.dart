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
            nextChar == kEscape ||
            nextChar == kOpenBracket ||
            nextChar == kCloseBracket ||
            nextChar == kOpenParen ||
            nextChar == kCloseParen) {
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
          // Single tilde treated as plain text, handled by falling through
          pos++;
        }
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
      } //
      else if (currentChar == kOpenBracket) {
        // Opening square bracket for link
        addTextToken(textStart, pos);

        // Start link parsing
        final int linkStartPos = pos;
        pos++; // Move past '['

        // Find the end of link text
        final int linkTextStart = pos;
        int nestLevel = 0;
        int linkTextEnd = -1;

        while (pos < length) {
          // Inner loop for link text
          final int c = codeUnits[pos];

          // Handle escape sequences (original simple version)
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
                break; // Found '](', proceed to URL parsing
              } else {
                // Not a valid link separator ']( )'.
                // The ']' found was not part of a valid link structure here.
                linkTextEnd = -1; // Mark that we didn't find a valid end for a link text segment
                // that leads to a URL.
                // The original code from llms.txt effectively did:
                // pos++; continue;
                // This means it continues scanning the inner loop.
                // If the loop finishes and linkTextEnd is still -1,
                // the outer 'if (linkTextEnd != -1 && ...)' will fail,
                // and the 'else' branch (treating '[' as text) will be taken.
                // We need to ensure this loop continues or breaks correctly.
                // To match original llms.txt behavior if `](` is not found after `]`:
                // it means the `[` was not a start of a link that completes with `](...)`.
                // The code would try to find another `]` if `pos++` happens here,
                // or if `break` happens, the outer `if(linkTextEnd != -1 ...)` fails.
                // Let's ensure the `break` happens so outer `if` fails.
                break; // Exit this inner loop. `linkTextEnd` is set, but `(` check failed.
                // The outer `if` will then determine if it's a full link.
              }
            }
          }
          pos++;
        }

        // Check if we found a proper link structure "[text]("
        // `pos` is currently at `linkTextEnd` (']') or at `length` if `]` wasn't found.
        // If `break` happened from `if (pos + 1 < length && codeUnits[pos + 1] == kOpenParen)`,
        // then `pos` points to `]`.
        if (linkTextEnd != -1 &&
            (linkTextEnd + 1) < length &&
            codeUnits[linkTextEnd + 1] == kOpenParen) {
          // Valid '[text](' structure found.
          tokens.add(Token(TokenType.linkStart, '[', linkStartPos, 1));

          if (linkTextEnd > linkTextStart) {
            // If there's actual text between [ and ]
            tokens.add(
              Token(
                TokenType.text, // It's just text at this stage
                text.substring(linkTextStart, linkTextEnd),
                linkTextStart,
                linkTextEnd - linkTextStart,
              ),
            );
          } else {
            // Empty link text, e.g. [](url)
            tokens.add(Token(TokenType.text, '', linkTextStart, 0));
          }

          tokens.add(Token(TokenType.linkSeparator, '](', linkTextEnd, 2));
          pos = linkTextEnd + 2; // Move main `pos` past ']('

          // Now collect the URL
          final int urlStart = pos;
          int urlEnd = -1;
          nestLevel = 0; // For nested parentheses within URL

          while (pos < length) {
            // Inner loop for URL
            final int c = codeUnits[pos];
            if (c == kEscape && pos + 1 < length) {
              pos += 2; // Original simple escape skipping
              continue;
            }
            if (c == kOpenParen) {
              nestLevel++;
            } else if (c == kCloseParen) {
              if (nestLevel > 0) {
                nestLevel--;
              } else {
                urlEnd = pos; // Position of ')'
                break; // Found ')'
              }
            }
            pos++;
          } // End of inner loop for URL

          if (urlEnd != -1) {
            // Valid URL found
            if (urlEnd > urlStart) {
              // If there's actual text for URL
              tokens.add(
                Token(
                  TokenType.text, // URL is also just text at this stage
                  text.substring(urlStart, urlEnd),
                  urlStart,
                  urlEnd - urlStart,
                ),
              );
            } else {
              // Empty URL, e.g. [text]()
              tokens.add(Token(TokenType.text, '', urlStart, 0));
            }
            tokens.add(Token(TokenType.linkEnd, ')', urlEnd, 1));
            pos = urlEnd + 1; // Move main `pos` past ')'
            textStart = pos; // Reset textStart for the next segment of plain text.
          } else {
            // Malformed URL (e.g., [text](url without closing paren).
            // The original fallback: treat the initial `[` at `linkStartPos` as plain text
            // and let subsequent characters be re-evaluated by the main loop.
            // To achieve this, we must discard any link tokens already added for this attempt
            // and reset `pos` and `textStart` correctly.
            tokens
              ..removeLast() // Remove linkSeparator
              ..removeLast() // Remove linkText (or empty linkText token)
              ..removeLast() // Remove linkStart
              // Now, treat the original '[' as text.
              ..add(Token(TokenType.text, '[', linkStartPos, 1)); // Add '[' as text
            pos = linkStartPos + 1; // Set main `pos` to parse after the '['
            textStart = pos; // Reset textStart.
          }
        } else {
          // Not a complete link structure (e.g. "[text" or "[text]no_paren").
          // Treat the initial '[' as plain text.
          // `addTextToken(textStart, linkStartPos)` was already called.
          tokens.add(Token(TokenType.text, '[', linkStartPos, 1));
          pos = linkStartPos + 1; // Continue parsing after the '['
          textStart = pos; // Reset textStart for the next segment of plain text.
        }
      }
      // Fallback for other characters that are not part of other rules
      // (e.g. single `]`, `(`, `)` not consumed by link logic, or any other char)
      else {
        pos++;
      }

      // Safety check to ensure forward progress if no specific token was matched
      // and pos wasn't advanced by one of the specific rules.
      if (pos == startPosInLoop && pos < length) {
        // This means the character at `startPosInLoop` was not handled by any
        // of the if/else if blocks that would advance `pos`.
        // This typically means it's a plain text character.
        // The `pos++` in the final `else` block above should handle most plain chars.
        // This is an ultimate fallback.
        pos++;
      }
    }

    // Add any remaining text
    addTextToken(textStart, pos);

    return tokens;
  }
}
