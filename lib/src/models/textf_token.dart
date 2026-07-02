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
    this.canOpen = true,
    this.canClose = true,
  });

  /// The specific formatting type this marker represents.
  final FormatMarkerType markerType;

  /// The raw marker characters (e.g., `**`, `~~`).
  final String value;

  /// Whether this marker can act as an opening delimiter.
  ///
  /// True when the character immediately after the marker run is not whitespace
  /// and the marker is not at end-of-string.
  final bool canOpen;

  /// Whether this marker can act as a closing delimiter.
  ///
  /// True when the character immediately before the marker run is not whitespace
  /// and the marker is not at start-of-string.
  final bool canClose;

  @override
  String toString() => 'FormatMarkerToken($markerType, "$value" at $position, '
      'canOpen: $canOpen, canClose: $canClose)';
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

/// A marker token representing an escape character `\`.
final class EscapeMarkerToken extends TextfToken {
  /// Creates an escape marker token.
  const EscapeMarkerToken({required super.position, required super.length});

  @override
  String toString() => 'EscapeMarkerToken(at $position)';
}

/// An ATX-style heading prefix: a run of 1–6 `#` characters at the start of a
/// line.
///
/// Unlike [FormatMarkerToken], a heading is a single-sided (line-prefix)
/// marker: its style scopes from the end of this token to the line terminator
/// (or end of string). The heading level (1–6) is derived from the run length.
///
/// The token is **enriched** so neither renderer re-derives line boundaries
/// (FR Option A). [position]..[contentStart] is the consumed opening region
/// (the `#` run plus its separator); [contentStart]..[contentEnd] is the
/// inline content; [lineEndPosition] is the index of the line terminator (or
/// `text.length`).
///
/// [contentEnd] and [lineEndPosition] are **back-patched** by the tokenizer
/// when the line terminator is reached later in the same single pass — there is
/// no second pass and no per-heading forward scan. They are therefore the only
/// mutable token fields.
final class HeadingToken extends TextfToken {
  /// Creates a heading token.
  ///
  /// [length] is derived as the width of the consumed opening region
  /// ([contentStart] − [position]) so the per-token slot sum still equals the
  /// input length (the 1:1 invariant). The inline content follows as separate
  /// [TextToken]s.
  HeadingToken({
    required this.level,
    required super.position,
    required this.contentStart,
    required this.contentEnd,
    required this.lineEndPosition,
  }) : super(length: contentStart - position);

  /// The heading level, from 1 (`#`) to 6 (`######`).
  final int level;

  /// Index of the first content character (== [contentEnd] when empty).
  final int contentStart;

  /// One past the last content character. Back-patched at the line terminator.
  int contentEnd;

  /// Index of the line terminator, or `text.length` at end of input.
  /// Back-patched at the line terminator; enables an O(1) cursor-inside-line
  /// test in the editor.
  int lineEndPosition;

  @override
  String toString() => 'HeadingToken(h$level at $position, '
      'content $contentStart..$contentEnd, lineEnd $lineEndPosition)';
}

/// The trailing region of an ATX heading line: optional trailing spaces/tabs
/// plus an optional closing `#` run (`spec.txt:1215`).
///
/// Emitted by the tokenizer immediately after the heading's content tokens,
/// and only when that region `[position, position + length)` is non-empty. Like
/// the opening region of a [HeadingToken] it is a **consumed** marker: the
/// read-only pipeline renders nothing for it, while the editor renders it as a
/// visible, dimmed span so every source character keeps exactly one cursor slot
/// (the 1:1 invariant).
final class HeadingSuffixToken extends TextfToken {
  /// Creates a heading-suffix marker token spanning `[position, position +
  /// length)`.
  const HeadingSuffixToken({
    required super.position,
    required super.length,
    required this.headingStart,
    required this.lineEndPosition,
  });

  /// Start index of the owning heading's line construct (== the owning
  /// [HeadingToken.position]). Together with [lineEndPosition] this reproduces
  /// the same O(1) cursor-inside-line test the opening run uses.
  final int headingStart;

  /// Index of the line terminator, or `text.length` at end of input — the same
  /// value carried on the owning [HeadingToken.lineEndPosition].
  final int lineEndPosition;

  @override
  String toString() => 'HeadingSuffixToken(at $position, len $length, '
      'line $headingStart..$lineEndPosition)';
}
