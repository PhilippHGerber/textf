import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/default_styles.dart';

/// The design-system-neutral colors Textf derives its built-in defaults from.
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
/// The surface is a guess — nothing in the widgets layer publishes the real
/// one — so it only drives cosmetic defaults (the code-chip background alpha
/// and the highlight tint), where a wrong guess costs nothing in legibility.
/// The default link color deliberately does not depend on it.
///
/// Two palettes are equal when their [foreground] colors are equal.
@immutable
class TextfPalette {
  /// Creates the palette for the given effective root [style].
  ///
  /// A `null` style, or one without a color, yields
  /// [DefaultStyles.defaultForegroundColor].
  factory(TextStyle? style) {
    final Color foreground = style?.color ?? DefaultStyles.defaultForegroundColor;
    return TextfPalette._(foreground: foreground, surface: _inferSurface(foreground));
  }

  const new _({required this.foreground, required this.surface});

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
