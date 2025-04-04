/// Represents different types of formatting tokens in the parsing process.
///
/// Each type corresponds to a specific formatting feature supported by the Textf widget.
enum TokenType {
  /// Regular text content with no special formatting.
  text,

  /// Bold and italic formatting marker: '***' or '___'
  boldItalicMarker,

  /// Bold formatting marker: '**' or '__'
  boldMarker,

  /// Italic formatting marker: '*' or '_'
  italicMarker,

  /// Strikethrough formatting marker: '~~'
  strikeMarker,

  /// Inline code formatting marker: '`'
  codeMarker,
}

/// Represents a single token in the parsing process.
///
/// A token can be either a formatting marker or a segment of regular text.
/// Each token tracks its type, content value, and position within the original string.
class Token {
  /// The type of this token (e.g., boldMarker, text).
  final TokenType type;

  /// The actual text content of this token.
  final String value;

  /// The starting position of this token in the original string.
  final int position;

  /// The length of this token in characters.
  final int length;

  /// Creates a new token with the specified properties.
  const Token(this.type, this.value, this.position, this.length);

  @override
  String toString() => 'Token($type, "$value" at $position)';
}
