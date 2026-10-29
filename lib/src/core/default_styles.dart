import 'package:flutter/widgets.dart';

/// Plain default values read by TextfStyleResolver.
///
/// This class centralizes the design-system-neutral constants behind the
/// neutral and relative defaults of the formatting types; the resolver
/// applies them. Nothing here reads a
/// design-system theme: colors are fixed constants or derived from a text
/// foreground and its inferred surface brightness (see `TextfPalette`).
class DefaultStyles {
  /// Default mouse cursor for links.
  /// Used as a fallback by TextfStyleResolver when no cursor is specified
  /// via TextfOptions in the widget tree.
  static const MouseCursor linkMouseCursor = SystemMouseCursors.click;

  /// Foreground color assumed when the effective text style sets no color.
  ///
  /// Opaque black, matching what Flutter paints for a color-less [TextStyle].
  static const Color defaultForegroundColor = Color(0xFF000000);

  /// Default link color: `#1A73E8`, a single fixed blue for every surface.
  ///
  /// It is deliberately *not* derived from the inferred surface brightness:
  /// that guess can be wrong, and for links a wrong guess is an accessibility
  /// failure rather than a cosmetic one. This blue reaches about 4.51:1
  /// against white and 4.16:1 against a `#121212` dark surface, so it stays
  /// legible whichever surface the text actually sits on.
  static const Color defaultLinkColor = Color(0xFF1A73E8);

  /// Alpha applied to the foreground color for the inline-code background on
  /// a light surface.
  static const double codeBackgroundAlphaLight = 0.05;

  /// Alpha applied to the foreground color for the inline-code background on
  /// a dark surface.
  static const double codeBackgroundAlphaDark = 0.15;

  /// Base color of the highlight (`==text==`) background on a light surface.
  static const Color highlightColorLight = Color(0xFFFFEB3B);

  /// Base color of the highlight (`==text==`) background on a dark surface.
  static const Color highlightColorDark = Color(0xFFFBC02D);

  /// Alpha applied to [highlightColorLight] for the highlight background.
  static const double highlightAlphaLight = 0.5;

  /// Alpha applied to [highlightColorDark] for the highlight background.
  static const double highlightAlphaDark = 0.4;

  /// Highlight (`==text==`) text color on a light surface, used only when the
  /// segment itself sets no color: black at 87% opacity.
  static const Color highlightTextColorLight = Color(0xDD000000);

  /// Highlight (`==text==`) text color on a dark surface, used only when the
  /// segment itself sets no color: opaque white.
  static const Color highlightTextColorDark = Color(0xFFFFFFFF);

  /// Alpha applied to the ambient text color for the default thematic-break
  /// rule.
  static const double thematicBreakAlpha = 0.20;

  /// Alpha applied to the text color for dimmed formatting markers in
  /// `TextfEditingController`.
  static const double editingMarkerAlpha = 0.4;

  /// Font family of the default inline-code style.
  static const String defaultCodeFontFamily = 'monospace';

  /// The default inline-code background: [foreground] tinted at
  /// [codeBackgroundAlphaLight] on a light [surface], or
  /// [codeBackgroundAlphaDark] on a dark one.
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  static Color codeBackgroundColor(Color foreground, Brightness surface) {
    return foreground.withValues(
      alpha: surface == Brightness.light ? codeBackgroundAlphaLight : codeBackgroundAlphaDark,
    );
  }

  /// The default highlight background for the given [surface]:
  /// [highlightColorLight] at [highlightAlphaLight], or [highlightColorDark]
  /// at [highlightAlphaDark].
  static Color highlightBackgroundColor(Brightness surface) {
    return surface == Brightness.light
        ? highlightColorLight.withValues(alpha: highlightAlphaLight)
        : highlightColorDark.withValues(alpha: highlightAlphaDark);
  }

  /// The highlight text color for the given [surface], used when the segment
  /// sets no color of its own: [highlightTextColorLight] on a light surface,
  /// [highlightTextColorDark] on a dark one.
  static Color highlightTextColor(Brightness surface) {
    return surface == Brightness.light ? highlightTextColorLight : highlightTextColorDark;
  }

  /// The default thematic-break rule color: [foreground] at
  /// [thematicBreakAlpha].
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  static Color thematicBreakColor(Color foreground) {
    return foreground.withValues(alpha: thematicBreakAlpha);
  }

  /// The dimmed formatting-marker color in `TextfEditingController`:
  /// [foreground] at [editingMarkerAlpha].
  ///
  /// The alpha replaces any alpha [foreground] already carries.
  static Color editingMarkerColor(Color foreground) {
    return foreground.withValues(alpha: editingMarkerAlpha);
  }

  /// Default font family fallback list for inline code (`code`).
  /// Used by TextfStyleResolver when applying the default code styling
  /// if no specific `codeStyle` (with font information) is provided via TextfOptions.
  /// Includes 'monospace' as a final generic fallback.
  static const List<String> defaultCodeFontFamilyFallback = [
    'RobotoMono', // Commonly included via assets in Flutter projects using this package
    'Menlo', // Common monospace font on macOS
    'Courier New', // Common monospace font on Windows
    'monospace', // Generic CSS/platform fallback
  ];

  /// Default thickness for the strikethrough line decoration (`~~strikethrough~~`).
  /// Used by TextfStyleResolver when applying the default strikethrough effect
  /// if no specific `strikethroughThickness` is provided via TextfOptions.
  static const double defaultStrikethroughThickness = 1.5;

  /// Default font size used for relative calculations when base style has no font size.
  static const double defaultFontSize = 14;

  /// Default font size factor for superscript and subscript.
  // Repeated in the `scriptFontSizeFactor` docs of TextfOptions and TextfOptionsData.
  static const double scriptFontSizeFactor = 0.6;

  /// Default baseline offset factor for superscript (relative to font size).
  // Repeated in the `superscriptBaselineFactor` docs of TextfOptions and TextfOptionsData.
  static const double superscriptBaselineFactor = 0.4; // Move up

  /// Default baseline offset factor for subscript (relative to font size).
  // Repeated in the `subscriptBaselineFactor` docs of TextfOptions and TextfOptionsData.
  static const double subscriptBaselineFactor = 0.4; // Move down

  /// Default line-height multiplier applied to ATX headings.
  static const double headingLineHeight = 1.2;

  /// Relative font-size multipliers for H1–H6.
  static const List<double> headingFontSizeFactors = [
    2.00, // h1
    1.50, // h2
    1.33, // h3
    1.14, // h4
    1.07, // h5
    1.00, // h6
  ];
}
