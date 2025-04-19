/// Represents different types of formatting tokens in the parsing process.
///
/// Each type corresponds to a specific formatting feature supported by the Textf widget.
enum TokenType {
  /// Regular text content with no special formatting.
  text,

  /// Bold and italic formatting marker: '***' or '___'
  boldItalicMarker(isFormattingMarker:true),

  /// Bold formatting marker: '**' or '__'
  boldMarker(isFormattingMarker:true),

  /// Italic formatting marker: '*' or '_'
  italicMarker(isFormattingMarker:true),

  /// Strikethrough formatting marker: '~~'
  strikeMarker(isFormattingMarker: true),

  /// Inline code formatting marker: '`'
  codeMarker(isFormattingMarker:true),

  /// Opening square bracket for link: '['
  linkStart(isLinkToken:true),

  /// Text content to be displayed for a link
  linkText(isLinkToken:true),

  /// Closing square bracket followed by opening parenthesis: ']('
  linkSeparator(isLinkToken:true),

  /// URL content of a link
  linkUrl(isLinkToken:true),

  /// Closing parenthesis for link: ')'
  linkEnd(isLinkToken:true),
  ;

  const TokenType( {this.isFormattingMarker=false, this.isLinkToken=false} );

  /// Indicates whether this token type is standard formatting marker.
  final bool isFormattingMarker;

  /// Indicates whether this token type is part of a link.
  final bool isLinkToken;
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
