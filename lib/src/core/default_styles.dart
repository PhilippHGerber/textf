import 'package:flutter/widgets.dart';

/// Provides default styling behaviours used as fallbacks by TextfStyleResolver.
///
/// This class centralizes the design-system-neutral constants and relative
/// fallback styles for the formatting types. Nothing here reads a
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
  static const double scriptFontSizeFactor = 0.6;

  /// Default baseline offset factor for superscript (relative to font size).
  static const double superscriptBaselineFactor = 0.4; // Move up

  /// Default baseline offset factor for subscript (relative to font size).
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

  /// Default heading style for ATX headings (`# H1` .. `###### H6`).
  ///
  /// Scales the base font size by [headingFontSizeFactors] and applies bold
  /// weight. Used as a fallback when no
  /// `h{n}Style` is provided via TextfOptions.
  static TextStyle headingStyle(int level, TextStyle baseStyle) {
    final int index = (level - 1).clamp(0, headingFontSizeFactors.length - 1);
    final double factor = headingFontSizeFactors[index];
    final double baseSize = baseStyle.fontSize ?? defaultFontSize;
    return baseStyle.copyWith(
      fontSize: baseSize * factor,
      fontWeight: baseStyle.fontWeight ?? FontWeight.bold,
      height: headingLineHeight,
    );
  }

  /// Applies default bold formatting (`**bold**` or `__bold__`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldStyle` is found via TextfOptions.
  static TextStyle boldStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  /// Applies default italic formatting (`*italic*` or `_italic_`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `italicStyle` is found via TextfOptions.
  static TextStyle italicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }

  /// Applies default bold and italic formatting (`***both***` or `___both___`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldItalicStyle` is found via TextfOptions.
  static TextStyle boldItalicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    );
  }

  /// Applies default strikethrough formatting (`~~strikethrough~~`) to a base style,
  /// using the specified line thickness.
  /// Used as a fallback by TextfStyleResolver if no `strikethroughStyle` is found
  /// via TextfOptions. The thickness resolved by the resolver (considering TextfOptions
  /// or the default) is passed in here.
  static TextStyle strikethroughStyle(
    TextStyle baseStyle, {
    double thickness = defaultStrikethroughThickness,
  }) {
    TextDecoration newDecoration = TextDecoration.lineThrough;
    // Combine with existing decoration if present
    if (baseStyle.decoration != null) {
      // Prevent combining with itself if somehow applied twice (defensive)
      final decoration = baseStyle.decoration;
      if (decoration != null && decoration.contains(TextDecoration.lineThrough)) {
        newDecoration = decoration;
      } else if (decoration != null) {
        newDecoration = TextDecoration.combine([decoration, TextDecoration.lineThrough]);
      }
    }

    // Use the base color for the line if available, otherwise let Flutter decide.
    // If combining decorations, the original decorationColor might be for a different part.
    // It's safer to let Flutter pick or for the user to specify a combined decorationColor
    // via TextfOptions.
    // For simplicity here, we might just use baseStyle.color if no decorationColor is set.
    final Color? decorationColorToApply = baseStyle.decorationColor ?? baseStyle.color;

    return baseStyle.copyWith(
      decoration: newDecoration,
      decorationColor: decorationColorToApply,
      decorationThickness: thickness,
    );
  }

  /// Applies default underline formatting (`++underline++`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `underlineStyle` is found via TextfOptions.
  static TextStyle underlineStyle(TextStyle baseStyle) {
    TextDecoration newDecoration = TextDecoration.underline;
    // Combine with existing decoration if present
    final TextDecoration? decoration = baseStyle.decoration;
    if (decoration != null) {
      // Prevent combining with itself (defensive)
      newDecoration = decoration.contains(TextDecoration.underline)
          ? decoration
          : TextDecoration.combine([decoration, TextDecoration.underline]);
    }

    final Color? decorationColorToApply = baseStyle.decorationColor ?? baseStyle.color;

    return baseStyle.copyWith(
      decoration: newDecoration,
      decorationColor: decorationColorToApply,
      // Use baseStyle.decorationThickness if available, otherwise a sensible default or null.
      // This thickness applies to the new underline part.
      decorationThickness: baseStyle.decorationThickness ?? 1.0,
    );
  }

  /// Applies the default highlight formatting (`==highlight==`) to a base
  /// style: the [highlightBackgroundColor] for [surface] as the background,
  /// keeping the base text color.
  static TextStyle highlightStyle(TextStyle baseStyle, Brightness surface) {
    return baseStyle.copyWith(backgroundColor: highlightBackgroundColor(surface));
  }

  /// Applies default superscript formatting (`^superscript^`) to a base style.
  static TextStyle superscriptStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? defaultFontSize) * scriptFontSizeFactor,
    );
  }

  /// Applies default subscript formatting (`~subscript~`) to a base style.
  static TextStyle subscriptStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? defaultFontSize) * scriptFontSizeFactor,
    );
  }
}
