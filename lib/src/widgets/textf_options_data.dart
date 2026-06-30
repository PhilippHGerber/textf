import 'package:flutter/material.dart';

/// Holds the pre-merged, effective configuration for Textf widgets.
///
/// This data class represents the fully resolved styling and behavior
/// configuration at a specific point in the widget tree.
@immutable
class TextfOptionsData {
  /// Creates a new TextfOptionsData instance with the given properties.
  const TextfOptionsData({
    this.onLinkTap,
    this.onLinkHover,
    this.linkMouseCursor,
    this.linkStyle,
    this.linkHoverStyle,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.strikethroughThickness,
    this.underlineStyle,
    this.highlightStyle,
    this.superscriptStyle,
    this.subscriptStyle,
    this.superscriptBaselineFactor,
    this.subscriptBaselineFactor,
    this.scriptFontSizeFactor,
    this.linkAlignment,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
  });

  /// Callback function executed when tapping or clicking on a link.
  final void Function(String url, String displayText)? onLinkTap;

  /// Callback function executed when hovering over a link (web/desktop).
  final void Function(String url, String displayText, {required bool isHovering})? onLinkHover;

  /// Mouse cursor to show when hovering over a link.
  final MouseCursor? linkMouseCursor;

  /// Alignment for link widgets.
  final PlaceholderAlignment? linkAlignment;

  // Script factors (Nearest wins)
  /// A specific thickness for the strikethrough line decoration.
  /// This property is **only used if `strikethroughStyle` is `null`**.
  final double? strikethroughThickness;

  /// Custom baseline offset factor for superscript text.
  ///
  /// Determines the vertical offset magnitude relative to the font size.
  /// The value is treated as an absolute offset; superscript is always raised.
  ///
  /// If null, defaults to `DefaultStyles.superscriptBaselineFactor`.
  final double? superscriptBaselineFactor;

  /// Custom baseline offset factor for subscript text.
  ///
  /// Determines the vertical offset magnitude relative to the font size.
  /// The value is treated as an absolute offset; subscript is always lowered.
  ///
  /// If null, defaults to `DefaultStyles.subscriptBaselineFactor`.
  final double? subscriptBaselineFactor;

  /// Custom font size scaling factor for both superscript and subscript text.
  ///
  /// Multiplies the base font size by this factor.
  /// For example, `0.6` means the script text will be 60% the size of the body text.
  ///
  /// If null, defaults to `DefaultStyles.scriptFontSizeFactor` (0.6).
  final double? scriptFontSizeFactor;

  // Styles (Merged down the tree)
  /// The [TextStyle] for link text (`[text](url)`) in its normal (non-hovered) state.
  /// Merged onto the base style if provided.
  final TextStyle? linkStyle;

  /// The [TextStyle] for link text when hovered.
  /// This style is merged on top of the link's final normal style.
  final TextStyle? linkHoverStyle;

  /// The [TextStyle] for bold text (`**bold**` or `__bold__`).
  /// Merged onto the base style if provided.
  final TextStyle? boldStyle;

  /// The [TextStyle] for italic text (`*italic*` or `_italic_`).
  /// Merged onto the base style if provided.
  final TextStyle? italicStyle;

  /// The [TextStyle] for bold and italic text (`***both***` or `___both___`).
  /// Merged onto the base style if provided.
  final TextStyle? boldItalicStyle;

  /// The [TextStyle] for strikethrough text (`~~strike~~`).
  /// Merged onto the base style if provided.
  final TextStyle? strikethroughStyle;

  /// The [TextStyle] for inline code text (`` `code` ``).
  /// Merged onto the base style if provided.
  final TextStyle? codeStyle;

  /// The [TextStyle] for underlined text (`++underline++`).
  /// Merged onto the base style if provided.
  final TextStyle? underlineStyle;

  /// The [TextStyle] for highlighted text (`==highlight==`).
  /// Merged onto the base style if provided.
  final TextStyle? highlightStyle;

  /// The [TextStyle] for superscript text (`^superscript^`).
  /// Merged onto the base style if provided.
  final TextStyle? superscriptStyle;

  /// The [TextStyle] for subscript text (`~subscript~`).
  /// Merged onto the base style if provided.
  final TextStyle? subscriptStyle;

<<<<<<< HEAD
=======
  /// The [TextStyle] for level-1 headings (`# H1`). Merged onto the base style.
  final TextStyle? h1Style;

  /// The [TextStyle] for level-2 headings (`## H2`). Merged onto the base style.
  final TextStyle? h2Style;

  /// The [TextStyle] for level-3 headings (`### H3`). Merged onto the base style.
  final TextStyle? h3Style;

  /// The [TextStyle] for level-4 headings (`#### H4`). Merged onto the base style.
  final TextStyle? h4Style;

  /// The [TextStyle] for level-5 headings (`##### H5`). Merged onto the base style.
  final TextStyle? h5Style;

  /// The [TextStyle] for level-6 headings (`###### H6`). Merged onto the base style.
  final TextStyle? h6Style;

>>>>>>> pr-10
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextfOptionsData &&
        other.onLinkTap == onLinkTap &&
        other.onLinkHover == onLinkHover &&
        other.linkMouseCursor == linkMouseCursor &&
        other.linkAlignment == linkAlignment &&
        other.strikethroughThickness == strikethroughThickness &&
        other.superscriptBaselineFactor == superscriptBaselineFactor &&
        other.subscriptBaselineFactor == subscriptBaselineFactor &&
        other.scriptFontSizeFactor == scriptFontSizeFactor &&
        other.linkStyle == linkStyle &&
        other.linkHoverStyle == linkHoverStyle &&
        other.boldStyle == boldStyle &&
        other.italicStyle == italicStyle &&
        other.boldItalicStyle == boldItalicStyle &&
        other.strikethroughStyle == strikethroughStyle &&
        other.codeStyle == codeStyle &&
        other.underlineStyle == underlineStyle &&
        other.highlightStyle == highlightStyle &&
        other.superscriptStyle == superscriptStyle &&
<<<<<<< HEAD
        other.subscriptStyle == subscriptStyle;
=======
        other.subscriptStyle == subscriptStyle &&
        other.h1Style == h1Style &&
        other.h2Style == h2Style &&
        other.h3Style == h3Style &&
        other.h4Style == h4Style &&
        other.h5Style == h5Style &&
        other.h6Style == h6Style;
>>>>>>> pr-10
  }

  @override
  int get hashCode => Object.hashAll([
        onLinkTap,
        onLinkHover,
        linkMouseCursor,
        linkAlignment,
        strikethroughThickness,
        superscriptBaselineFactor,
        subscriptBaselineFactor,
        scriptFontSizeFactor,
        linkStyle,
        linkHoverStyle,
        boldStyle,
        italicStyle,
        boldItalicStyle,
        strikethroughStyle,
        codeStyle,
        underlineStyle,
        highlightStyle,
        superscriptStyle,
        subscriptStyle,
<<<<<<< HEAD
=======
        h1Style,
        h2Style,
        h3Style,
        h4Style,
        h5Style,
        h6Style,
>>>>>>> pr-10
      ]);
}
