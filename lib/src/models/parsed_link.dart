import 'package:flutter/foundation.dart';

/// An immutable value object representing a validated link structure.
///
/// Constructed exclusively by `LinkValidator.validate` from a 5-token link
/// sequence (`[text](url)`).
@immutable
class ParsedLink {
  /// Creates a [ParsedLink] value object.
  const new({
    required this.displayText,
    required this.url,
    required this.startPosition,
    required this.endPosition,
  });

  /// The link text between `[` and `]`.
  final String displayText;

  /// The raw, un-normalized URL string between `(` and `)`.
  final String url;

  /// Character offset of the opening `[` in the source string.
  final int startPosition;

  /// Character offset after the closing `)`.
  final int endPosition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedLink &&
          runtimeType == other.runtimeType &&
          displayText == other.displayText &&
          url == other.url &&
          startPosition == other.startPosition &&
          endPosition == other.endPosition;

  @override
  int get hashCode => Object.hash(displayText, url, startPosition, endPosition);

  @override
  String toString() =>
      'ParsedLink(displayText: "$displayText", url: "$url", '
      'startPosition: $startPosition, endPosition: $endPosition)';
}
