import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/material.dart';

import '../parsing/textf_parser.dart';
import 'internal/textf_renderer.dart';

/// A lightweight text widget for simple inline formatting.
///
/// [Textf] provides basic text formatting capabilities similar to a subset of Markdown,
/// focusing only on inline styles like bold, italic, strikethrough, and code.
/// It's designed for simple use cases where you need basic text formatting without
/// the overhead of a full Markdown rendering solution.
///
/// ## Supported formatting
/// * `**bold**` or `__bold__` for **bold** text
/// * `*italic*` or `_italic_` for *italic* text
/// * `***bold and italic***` or `___bold and italic___` for ***bold and italic*** text
/// * `~~strikethrough~~` for ~~strikethrough~~ text
/// * `^superscript^` for superscript text
/// * `~subscript~` for subscript text
/// * `` `code` `` for `code` text
/// * `[link text](url)` for [links](https://example.com)
/// * `{key}` placeholders for inserting [InlineSpan]s (e.g., WidgetSpan) via [placeholders].
///
/// Links support nested formatting such as `[**bold** link](url)`.
///
/// ## Usage example
/// ```dart
/// Textf(
///   'Hello **bold** *italic* ~~strikethrough~~ `code`',
///   style: TextStyle(fontSize: 16),
/// )
/// ```
///
/// ## Widget Interpolation
/// You can insert arbitrary widgets or spans into the text using named placeholders.
/// Keys must be alphanumeric (A-Z, a-z, 0-9) or underscores (_).
///
/// ```dart
/// Textf(
///   'Built with {flutter} and {dart}.',
///   placeholders: {
///     'flutter': WidgetSpan(child: Icon(Icons.flutter_dash)),
///     'dart': WidgetSpan(child: Icon(Icons.code)),
///   },
/// )
/// ```
///
/// ## Limitations
/// - Maximum nesting depth of 2 formatting levels
/// - When nesting, use different marker types (e.g., **bold with _italic_**)
/// - No support for block elements (headings, lists, quotes, etc.)
/// - No support for images (unless inserted via {key} placeholder)
/// - Designed for inline formatting only, not full Markdown rendering
///
/// To escape formatting characters use a backslash: `\*not italic\*`
///
/// The widget supports standard text styling properties like [style], [textAlign],
/// and [overflow], similar to the standard Text widget.
class Textf extends StatelessWidget {
  /// Creates a text widget with inline formatting capabilities.
  ///
  /// The [data] parameter is the text string that contains formatting markers.
  /// All other parameters function identically to Flutter's standard [Text] widget.
  ///
  /// Example:
  /// ```dart
  /// Textf(
  ///   'Hello **world** with *formatting*',
  ///   style: TextStyle(fontSize: 16),
  ///   textAlign: TextAlign.center,
  /// )
  /// ```
  ///
  /// The base [style] will be applied to all text, with formatting markers
  /// modifying it where specified. For example, bold markers will apply
  /// FontWeight.bold to the specified text segments.
  const Textf(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.placeholders,
  });

  /// The text to display with formatting
  final String data;

  /// The base text style to apply to the text
  final TextStyle? style;

  /// The strut style to use for vertical layout
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally
  final TextAlign? textAlign;

  /// The directionality of the text
  final TextDirection? textDirection;

  /// The locale to use for the text
  final Locale? locale;

  /// Whether the text should break at soft line breaks
  final bool? softWrap;

  /// How visual overflow should be handled
  final TextOverflow? overflow;

  /// The text scaling factor to apply
  final TextScaler? textScaler;

  /// The maximum number of lines for the text to span
  final int? maxLines;

  /// An alternative semantics label for the text
  final String? semanticsLabel;

  /// Defines how the paragraph width is determined
  final TextWidthBasis? textWidthBasis;

  /// Defines how the paragraph will position lines vertically
  final ui.TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection
  final Color? selectionColor;

  /// A map of [InlineSpan] objects to insert into the text at placeholder positions.
  ///
  /// Placeholders are denoted by `{key}` in the [data] string, where `key` corresponds
  /// to a key in this map. Keys must consist of alphanumeric characters or underscores.
  ///
  /// Example:
  /// ```dart
  /// Textf(
  ///   'Status: {status_icon}',
  ///   placeholders: {
  ///     'status_icon': WidgetSpan(child: Icon(Icons.check)),
  ///   },
  /// )
  /// ```
  final Map<String, InlineSpan>? placeholders;

  /// Clears the internal parser cache to free memory.
  ///
  /// Call this in low-memory situations or when navigating
  /// away from text-heavy screens. The cache rebuilds automatically.
  static void clearCache() => TextfParser.clearCache();

  // Private static instance for default usage
  static final TextfParser _defaultParser = TextfParser();

  /// Builds the widget by parsing the formatted text into spans and
  /// rendering it using a Text.rich widget.
  ///
  /// The parsing process converts formatting markers into appropriate TextSpan
  /// objects with the correct styling applied. The resulting spans are then
  /// combined and passed to a Text.rich widget along with the other parameters.
  @override
  Widget build(BuildContext context) {
    return TextfRenderer(
      data: data,
      style: style,
      parser: _defaultParser,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      placeholders: placeholders,
    );
  }
}
