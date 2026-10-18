import 'package:flutter/widgets.dart';

/// An immutable value object bundling all resolved link render properties.
///
/// Bundles the base and hover [TextStyle]s, [MouseCursor], interaction callbacks,
/// and [PlaceholderAlignment] needed to render interactive links. Produced by
/// `TextfStyleResolver.resolveLinkConfiguration`.
@immutable
class LinkStyleConfiguration {
  /// Creates a [LinkStyleConfiguration] value object.
  const new({
    required this.style,
    required this.hoverStyle,
    required this.cursor,
    required this.alignment,
    this.onTap,
    this.onHover,
  });

  /// The resolved base [TextStyle] for the link.
  final TextStyle style;

  /// The resolved hover [TextStyle] for the link.
  final TextStyle hoverStyle;

  /// The resolved [MouseCursor] to display when hovering over the link.
  final MouseCursor cursor;

  /// The resolved callback invoked when the link is tapped.
  final void Function(String url, String displayText)? onTap;

  /// The resolved callback invoked when hovering over or away from the link.
  final void Function(String url, String displayText, {required bool isHovering})? onHover;

  /// The resolved [PlaceholderAlignment] for the link widget span.
  final PlaceholderAlignment alignment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkStyleConfiguration &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          hoverStyle == other.hoverStyle &&
          cursor == other.cursor &&
          onTap == other.onTap &&
          onHover == other.onHover &&
          alignment == other.alignment;

  @override
  int get hashCode => Object.hash(style, hoverStyle, cursor, onTap, onHover, alignment);

  @override
  String toString() =>
      'LinkStyleConfiguration(style: $style, hoverStyle: $hoverStyle, '
      'cursor: $cursor, onTap: $onTap, onHover: $onHover, alignment: $alignment)';
}
