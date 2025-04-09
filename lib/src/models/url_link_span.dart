import 'package:flutter/material.dart';

/// A specialized TextSpan that carries URL information for interactive links.
///
/// This class extends TextSpan to store the URL and display text data needed
/// for link interactivity, while remaining fully compatible with Flutter's
/// text rendering system.
class UrlLinkSpan extends TextSpan {
  /// The URL that should be opened when the link is activated.
  final String url;

  /// Creates a UrlLinkSpan with URL data.
  const UrlLinkSpan({
    required this.url,
    required String super.text,
    super.style,
    super.recognizer,
    super.children,
    String? semanticsLabel,
    super.locale,
    super.spellOut,
  }) : super(
          semanticsLabel: semanticsLabel ?? 'Link to: $url',
        );
}
