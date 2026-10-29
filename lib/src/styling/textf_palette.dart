import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The design-system-neutral colors Textf derives its neutral defaults from.
///
/// A palette is built from the *effective root style* alone — no
/// `BuildContext`, no design-system theme — so the style resolver stays
/// context-free. It carries:
///
/// - [foreground]: the effective text color, or opaque black when the style
///   sets none.
/// - [surface]: the brightness of the surface the text is *assumed* to sit
///   on, inferred from the luminance of [foreground]. Light text implies a
///   dark surface and vice versa.
///
/// Every color the palette produces is derived from those two, computed on
/// read: [codeBackground], [highlightBackground], [highlightText],
/// [thematicBreak] and [editingMarker].
///
/// The surface is a guess — nothing in the widgets layer publishes the real
/// one — so it only drives cosmetic defaults (the code-chip background alpha
/// and the highlight tint), where a wrong guess costs nothing in legibility.
/// The default link color deliberately does not depend on it and stays a
/// fixed constant outside the palette.
///
/// Two palettes are equal when their [foreground] colors are equal.
@immutable
class TextfPalette {
  /// Creates the palette for the given effective root [style].
  ///
  /// A `null` style, or one without a color, yields an opaque black
  /// [foreground], matching what Flutter paints for a color-less [TextStyle].
  factory(TextStyle? style) {
    final Color foreground = style?.color ?? _defaultForeground;
    return TextfPalette._(foreground: foreground, surface: _inferSurface(foreground));
  }

  const new _({required this.foreground, required this.surface});

  /// Foreground assumed when the effective root style sets no color.
  static const Color _defaultForeground = Color(0xFF000000);

  /// Offset added to relative luminance in the WCAG contrast formula.
  static const double _luminanceOffset = 0.05;

  /// Threshold on `(L + 0.05)²` above which the foreground counts as light.
  ///
  /// The same rule Flutter uses to pick text for a background, applied in
  /// reverse: `(L + 0.05)² > 0.15` is equivalent to `L > ~0.337`.
  static const double _lightForegroundThreshold = 0.15;

  /// The effective text color the defaults are derived from.
  final Color foreground;

  /// The inferred surface brightness: [Brightness.dark] behind light text,
  /// [Brightness.light] behind dark text.
  final Brightness surface;

  /// Alpha of the code-chip background tint on a light surface.
  static const double _codeBackgroundAlphaLight = 0.05;

  /// Alpha of the code-chip background tint on a dark surface.
  static const double _codeBackgroundAlphaDark = 0.15;

  /// The neutral default inline-code background: [foreground] at
  /// [_codeBackgroundAlphaLight] on a light [surface], or at
  /// [_codeBackgroundAlphaDark] on a dark one.
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  Color get codeBackground => foreground.withValues(
    alpha: surface == Brightness.light ? _codeBackgroundAlphaLight : _codeBackgroundAlphaDark,
  );

  /// Base color of the highlight background on a light surface.
  static const Color _highlightColorLight = Color(0xFFFFEB3B);

  /// Base color of the highlight background on a dark surface.
  static const Color _highlightColorDark = Color(0xFFFBC02D);

  /// Alpha applied to [_highlightColorLight].
  static const double _highlightAlphaLight = 0.5;

  /// Alpha applied to [_highlightColorDark].
  static const double _highlightAlphaDark = 0.4;

  /// Highlight text color on a light surface.
  static const Color _highlightTextLight = Color(0xDD000000);

  /// Highlight text color on a dark surface.
  static const Color _highlightTextDark = Color(0xFFFFFFFF);

  /// The neutral default highlight (`==text==`) background:
  /// [_highlightColorLight] at [_highlightAlphaLight] on a light [surface], or
  /// [_highlightColorDark] at [_highlightAlphaDark] on a dark one.
  Color get highlightBackground => surface == Brightness.light
      ? _highlightColorLight.withValues(alpha: _highlightAlphaLight)
      : _highlightColorDark.withValues(alpha: _highlightAlphaDark);

  /// The neutral default highlight (`==text==`) text color:
  /// [_highlightTextLight] on a light [surface], or [_highlightTextDark] on a
  /// dark one.
  ///
  /// The style resolver uses it only when the segment sets no color of its
  /// own.
  Color get highlightText => surface == Brightness.light ? _highlightTextLight : _highlightTextDark;

  /// Alpha of the neutral default thematic-break rule.
  static const double _thematicBreakAlpha = 0.20;

  /// Alpha of the dimmed formatting markers in `TextfEditingController`.
  static const double _editingMarkerAlpha = 0.4;

  /// The neutral default thematic-break rule color: [foreground] at
  /// [_thematicBreakAlpha].
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  Color get thematicBreak => foreground.withValues(alpha: _thematicBreakAlpha);

  /// The dimmed formatting-marker color in `TextfEditingController`:
  /// [foreground] at [_editingMarkerAlpha].
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  Color get editingMarker => foreground.withValues(alpha: _editingMarkerAlpha);

  static Brightness _inferSurface(Color foreground) {
    final double offsetLuminance = foreground.computeLuminance() + _luminanceOffset;
    return offsetLuminance * offsetLuminance > _lightForegroundThreshold
        ? Brightness.dark
        : Brightness.light;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextfPalette && other.foreground == foreground;

  @override
  int get hashCode => foreground.hashCode;

  @override
  String toString() => 'TextfPalette(foreground: $foreground, surface: $surface)';
}
