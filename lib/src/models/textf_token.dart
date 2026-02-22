/// Sealed class hierarchy for tokens produced by the tokenizer.
///
/// Using sealed classes provides exhaustive `switch` coverage at compile time,
/// so adding a new token kind forces all consumers to handle it.
sealed class TextfToken {
  /// Base constructor shared by all token types.
  const TextfToken({required this.position, required this.length});

  /// The starting position of this token in the original string.
  final int position;

  /// The length of this token in characters.
  final int length;
}

/// Regular text content with no special formatting.
final class TextToken extends TextfToken {
  /// Creates a text token with the given [value].
  const TextToken(this.value, {required super.position, required super.length});

  /// The actual text content of this token.
  final String value;

  @override
  String toString() => 'TextToken("$value" at $position)';
}

/// The type of formatting a [FormatMarkerToken] represents.
enum FormatMarkerType {
  /// Bold formatting: `**` or `__`
  bold,

  /// Italic formatting: `*` or `_`
  italic,

  /// Bold and italic formatting: `***` or `___`
  boldItalic,

  /// Strikethrough formatting: `~~`
  strikethrough,

  /// Inline code formatting: `` ` ``
  code,

  /// Highlight formatting: `==`
  highlight,

  /// Underline formatting: `++`
  underline,

  /// Superscript formatting: `^`
  superscript,

  /// Subscript formatting: `~`
  subscript,
}

/// A formatting marker token such as `**`, `~~`, `` ` ``, etc.
final class FormatMarkerToken extends TextfToken {
  /// Creates a formatting marker token.
  const FormatMarkerToken(
    this.markerType,
    this.value, {
    required super.position,
    required super.length,
  });

  /// The specific formatting type this marker represents.
  final FormatMarkerType markerType;

  /// The raw marker characters (e.g., `**`, `~~`).
  final String value;

  @override
  String toString() => 'FormatMarkerToken($markerType, "$value" at $position)';
}

/// Opening square bracket `[` that begins a link structure.
final class LinkStartToken extends TextfToken {
  /// Creates a link start token.
  const LinkStartToken({required super.position, required super.length});

  @override
  String toString() => 'LinkStartToken(at $position)';
}

/// The separator `](` between link text and URL.
final class LinkSeparatorToken extends TextfToken {
  /// Creates a link separator token.
  const LinkSeparatorToken({required super.position, required super.length});

  @override
  String toString() => 'LinkSeparatorToken(at $position)';
}

/// Closing parenthesis `)` that ends a link structure.
final class LinkEndToken extends TextfToken {
  /// Creates a link end token.
  const LinkEndToken({required super.position, required super.length});

  @override
  String toString() => 'LinkEndToken(at $position)';
}

/// A placeholder token `{key}` for widget substitution.
final class PlaceholderToken extends TextfToken {
  /// Creates a placeholder token with the given [key].
  const PlaceholderToken(this.key, {required super.position, required super.length});

  /// The identifier between the braces (e.g., `icon` from `{icon}`).
  final String key;

  @override
  String toString() => 'PlaceholderToken("$key" at $position)';
}
