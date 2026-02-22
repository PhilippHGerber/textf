// ignore_for_file: no-magic-number

import '../core/constants.dart';
import '../models/textf_token.dart';

/// Tokenizes text into formatting markers, placeholders, and content segments.
///
/// The TextfTokenizer breaks down input text into a sequence of [TextfToken] objects that
/// represent either formatting markers (like bold, italic), placeholders (like {icon}),
/// or regular text content.
///
/// This class is optimized for performance with a character-by-character approach
/// and special handling for escape sequences.
class TextfTokenizer {
  /// Tokenizes the input text into a list of [TextfToken] objects.
  ///
  /// This method processes the text character by character, identifying:
  /// - Formatting markers: **, __, *, _, ~~, `, ++, ==, ^, ~
  /// - Placeholders: {key} (alphanumeric and underscores)
  /// - Links: [text](url)
  /// - Regular text
  ///
  /// Escaped characters (preceded by \) are treated as literal text.
  List<TextfToken> tokenize(String text) {
    final tokens = <TextfToken>[];
    int pos = 0;
    int textStart = 0;
    final int length = text.length;

    // Helper to add accumulated text as a token
    void addTextToken(int start, int end) {
      if (end > start) {
        tokens.add(
          TextToken(
            // Since `start` and `end` are guaranteed by the tokenizer's logic to
            //    never fall within the middle of a multi-byte character sequence (they always
            //    point to the boundaries between characters or markers), using `substring` is
            //    safe in this context and will not slice characters apart.
            // ignore: avoid-substring
            text.substring(start, end),
            position: start,
            length: end - start,
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
        // Check if next char is a formatting character, link char, or placeholder brace
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
            TextToken(
              String.fromCharCode(nextChar),
              position: pos + 1, // Position of the character itself
              length: 1, // Length of the character itself
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
        if (pos + 2 < length &&
            codeUnits[pos + 1] == kAsterisk &&
            codeUnits[pos + 2] == kAsterisk) {
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.boldItalic, '***', position: pos, length: 3),
          );
          pos += 3;
          textStart = pos;
        }
        // Check for bold (**)
        else if (pos + 1 < length && codeUnits[pos + 1] == kAsterisk) {
          addTextToken(textStart, pos);
          tokens.add(FormatMarkerToken(FormatMarkerType.bold, '**', position: pos, length: 2));
          pos += 2;
          textStart = pos;
        }
        // Italic (*)
        else {
          addTextToken(textStart, pos);
          tokens.add(FormatMarkerToken(FormatMarkerType.italic, '*', position: pos, length: 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kUnderscore) {
        // Check for bold+italic (___)
        if (pos + 2 < length &&
            codeUnits[pos + 1] == kUnderscore &&
            codeUnits[pos + 2] == kUnderscore) {
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.boldItalic, '___', position: pos, length: 3),
          );
          pos += 3;
          textStart = pos;
        }
        // Check for bold (__)
        else if (pos + 1 < length && codeUnits[pos + 1] == kUnderscore) {
          addTextToken(textStart, pos);
          tokens.add(FormatMarkerToken(FormatMarkerType.bold, '__', position: pos, length: 2));
          pos += 2;
          textStart = pos;
        }
        // Italic (_)
        else {
          addTextToken(textStart, pos);
          tokens.add(FormatMarkerToken(FormatMarkerType.italic, '_', position: pos, length: 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kTilde) {
        // Check for strikethrough (~~)
        if (pos + 1 < length && codeUnits[pos + 1] == kTilde) {
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.strikethrough, '~~', position: pos, length: 2),
          );
          pos += 2;
          textStart = pos;
        } else {
          // Single tilde for subscript
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.subscript, '~', position: pos, length: 1),
          );
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kCaret) {
        // Caret for superscript
        addTextToken(textStart, pos);
        tokens.add(
          FormatMarkerToken(FormatMarkerType.superscript, '^', position: pos, length: 1),
        );
        pos++;
        textStart = pos;
      } else if (currentChar == kBacktick) {
        // Inline code (`)
        addTextToken(textStart, pos);
        tokens.add(FormatMarkerToken(FormatMarkerType.code, '`', position: pos, length: 1));
        pos++;
        textStart = pos;
      } else if (currentChar == kPlus) {
        // Check for underline (++)
        if (pos + 1 < length && codeUnits[pos + 1] == kPlus) {
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.underline, '++', position: pos, length: 2),
          );
          pos += 2;
          textStart = pos;
        } else {
          // Single plus treated as plain text
          pos++;
        }
      } else if (currentChar == kEquals) {
        // Check for highlight (==)
        if (pos + 1 < length && codeUnits[pos + 1] == kEquals) {
          addTextToken(textStart, pos);
          tokens.add(
            FormatMarkerToken(FormatMarkerType.highlight, '==', position: pos, length: 2),
          );
          pos += 2;
          textStart = pos;
        } else {
          pos++;
        }
      } else if (currentChar == kOpenBracket) {
        // Check for link start [text](url)
        addTextToken(textStart, pos);
        final int? nextPos = _tryParseLink(text, codeUnits, length, pos, tokens);
        if (nextPos != null) {
          pos = nextPos;
          textStart = pos;
        } else {
          tokens.add(TextToken('[', position: pos, length: 1));
          pos++;
          textStart = pos;
        }
      } else if (currentChar == kOpenBrace) {
        // Check for placeholder {key}
        addTextToken(textStart, pos);
        final int? nextPos = _tryParsePlaceholder(text, codeUnits, length, pos, tokens);
        if (nextPos != null) {
          pos = nextPos;
          textStart = pos;
        } else {
          // Not a valid placeholder (e.g. {a b} or {}), treat as plain text '{'
          tokens.add(TextToken('{', position: pos, length: 1));
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
    List<TextfToken> tokens,
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
      ..add(LinkStartToken(position: startPos, length: 1))
      ..add(
        TextToken(
          // ignore: avoid-substring
          text.substring(linkTextStart, linkTextEnd),
          position: linkTextStart,
          length: linkTextEnd - linkTextStart,
        ),
      )
      ..add(LinkSeparatorToken(position: linkTextEnd, length: 2))
      ..add(
        TextToken(
          // ignore: avoid-substring
          text.substring(urlStart, urlEnd),
          position: urlStart,
          length: urlEnd - urlStart,
        ),
      )
      ..add(LinkEndToken(position: urlEnd, length: 1));

    return urlEnd + 1;
  }

  /// Attempts to parse a widget placeholder `{key}`.
  ///
  /// Returns the position after the closing brace if successful,
  /// otherwise returns null.
  ///
  /// Valid format: `{` followed by alphanumeric characters or underscores,
  /// followed immediately by `}`. Spaces are NOT allowed.
  ///
  /// Examples: `{0}`, `{icon}`, `{my_icon}`, `{Icon1}`.
  /// Invalid examples: `{}`, `{ icon}`, `{a b}`, `{key.name}`.
  int? _tryParsePlaceholder(
    String text,
    List<int> codeUnits,
    int length,
    int startPos,
    List<TextfToken> tokens,
  ) {
    int pos = startPos + 1; // Move past '{'
    final int keyStart = pos;

    while (pos < length) {
      final int char = codeUnits[pos];

      // Check for allowed characters: 0-9, A-Z, _, a-z
      // 0x30-0x39: 0-9
      // 0x41-0x5A: A-Z
      // 0x5F: _
      // 0x61-0x7A: a-z
      if ((char >= 0x30 && char <= 0x39) ||
          (char >= 0x41 && char <= 0x5A) ||
          char == 0x5F ||
          (char >= 0x61 && char <= 0x7A)) {
        pos++;
        continue;
      }

      // Check for closing brace
      if (char == kCloseBrace) {
        // Must have at least one character between braces
        if (pos == keyStart) {
          return null; // Empty {} is treated as text
        }

        // Successfully parsed a placeholder
        // ignore: avoid-substring
        final String key = text.substring(keyStart, pos);
        tokens.add(
          PlaceholderToken(
            key,
            position: startPos,
            length: (pos + 1) - startPos,
          ),
        );
        return pos + 1;
      }

      // Any other character (space, period, hyphen, emoji) invalidates the placeholder
      return null;
    }

    // End of string reached without closing brace
    return null;
  }
}
