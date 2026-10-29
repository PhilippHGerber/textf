import 'package:flutter/widgets.dart';

/// Plain default values read by TextfStyleResolver.
///
/// This class centralizes the design-system-neutral constants behind the
/// neutral and relative defaults of the formatting types; the resolver
/// applies them. Nothing here reads a design-system theme. The only color
/// here is the fixed link color; the neutral default colors come from the
/// palette (see `TextfPalette`).
class DefaultStyles {
  /// Default mouse cursor for links.
  /// The neutral default TextfStyleResolver applies when no TextfOptions in
  /// the widget tree specifies a cursor.
  static const MouseCursor linkMouseCursor = SystemMouseCursors.click;

  /// Default link color: `#1A73E8`, a single fixed blue for every surface.
  ///
  /// It is deliberately *not* derived from the inferred surface brightness:
  /// that guess can be wrong, and for links a wrong guess is an accessibility
  /// failure rather than a cosmetic one. This blue reaches about 4.51:1
  /// against white and 4.16:1 against a `#121212` dark surface, so it stays
  /// legible whichever surface the text actually sits on.
  static const Color defaultLinkColor = Color(0xFF1A73E8);

  /// Font family of the default inline-code style.
  static const String defaultCodeFontFamily = 'monospace';

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
