import 'package:flutter/material.dart';

import '../core/textf_style_utils.dart';
import 'internal/textf_options_resolver.dart' as resolver;

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget uses the `InheritedWidget` pattern to make configuration
/// available to all descendant `Textf` widgets. It allows for hierarchical
/// styling and behavior management.
///
/// ## Style Inheritance Logic
///
/// `TextStyle` properties (like `boldStyle`, `linkStyle`, etc.) are resolved
/// using a **recursive merge strategy**. The system collects all `TextfOptions`
/// widgets up the tree and merges their styles starting from the top-most
/// (root) ancestor down to the nearest one.
///
/// This allows for powerful and intuitive style composition. For example, a
/// parent `TextfOptions` can define a `boldStyle` with a red color, and a
/// child `TextfOptions` can define its own `boldStyle` with only a bold font
/// weight. The final resolved style for bold text in that subtree will be
/// **both red and bold**.
///
/// The final, fully-merged style from the `TextfOptions` hierarchy is then
/// applied on top of the `Textf` widget's base style (from `DefaultTextStyle`
/// or the `style` parameter).
///
/// ## Callback and Value Inheritance Logic
///
/// Non-style properties that cannot be merged (like `onLinkTap`, `onLinkHover`,
/// and `linkMouseCursor`) use a **"nearest ancestor wins"** strategy. The first
/// non-null value found when searching up the widget tree from the `Textf`
/// widget is the one that will be used.
class TextfOptions extends InheritedWidget {
  /// Creates a new TextfOptions instance to provide configuration down the tree.
  const TextfOptions({
    required super.child,
    super.key,
    this.onLinkTap,
    this.onLinkHover,
    this.linkMouseCursor,
    this.linkStyle,
    this.linkAlignment,
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
  });

  /// Callback function executed when tapping or clicking on a link.
  /// Provides the resolved `url` and the raw `displayText` including any
  /// original formatting markers (e.g., `**bold link**`).
  final void Function(String url, String displayText)? onLinkTap;

  /// Callback function executed when the mouse pointer enters or exits a link.
  /// Provides the resolved `url`, the raw `displayText`, and the hover state
  /// (`isHovering` is `true` on enter, `false` on exit).
  final void Function(String url, String displayText, {required bool isHovering})? onLinkHover;

  /// The [TextStyle] for link text (`[text](url)`) in its normal (non-hovered) state.
  /// Merged onto the base style if provided.
  final TextStyle? linkStyle;

  /// The [TextStyle] for link text when hovered.
  /// This style is merged on top of the link's final normal style.
  final TextStyle? linkHoverStyle;

  /// The [MouseCursor] to display when hovering over a link.
  final MouseCursor? linkMouseCursor;

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

  /// A specific thickness for the strikethrough line decoration.
  /// This property is **only used if `strikethroughStyle` is `null`**.
  final double? strikethroughThickness;

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

  /// Custom alignment for link widgets.
  ///
  /// Defaults to [PlaceholderAlignment.baseline] if not specified.
  final PlaceholderAlignment? linkAlignment;

  /// Finds the nearest [TextfOptions] ancestor in the widget tree.
  ///
  /// Returns null if no ancestor is found. This establishes a dependency on the
  /// nearest `TextfOptions`, so the calling widget will rebuild if it changes.
  static TextfOptions? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextfOptions>();
  }

  /// Finds the nearest [TextfOptions] ancestor and establishes a dependency.
  ///
  /// Throws a [FlutterError] if no ancestor is found.
  static TextfOptions of(BuildContext context) {
    final TextfOptions? result = context.dependOnInheritedWidgetOfExactType<TextfOptions>();
    if (result == null) {
      throw FlutterError(
        'No TextfOptions found in context. To use TextfOptions.of, a TextfOptions widget must be an ancestor of the calling widget.',
      );
    }
    return result;
  }

  // ===== EFFECTIVE GETTERS (Used by TextfStyleResolver) =====

  /// Resolves the final merged `boldStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveBoldStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.boldStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `italicStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveItalicStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.italicStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `boldItalicStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveBoldItalicStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.boldItalicStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `strikethroughStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveStrikethroughStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.strikethroughStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `codeStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveCodeStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.codeStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `linkStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveLinkStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.linkStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `linkHoverStyle` and merges it onto the final `normalLinkStyle`.
  TextStyle? getEffectiveLinkHoverStyle(BuildContext context, TextStyle normalLinkStyle) {
    final TextStyle? hoverOptionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.linkHoverStyle);
    if (hoverOptionsStyle == null) return null;
    return mergeTextStyles(normalLinkStyle, hoverOptionsStyle);
  }

  /// Resolves the final merged `underlineStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveUnderlineStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.underlineStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `highlightStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveHighlightStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.highlightStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `superscriptStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveSuperscriptStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.superscriptStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `subscriptStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveSubscriptStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        resolver.getMergedStyleFromHierarchy(context, (o) => o.subscriptStyle);
    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Resolves the nearest `superscriptBaselineFactor` from the hierarchy.
  double? getEffectiveSuperscriptBaselineFactor(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.superscriptBaselineFactor);
  }

  /// Resolves the nearest `subscriptBaselineFactor` from the hierarchy.
  double? getEffectiveSubscriptBaselineFactor(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.subscriptBaselineFactor);
  }

  /// Resolves the nearest `scriptFontSizeFactor` from the hierarchy.
  double? getEffectiveScriptFontSizeFactor(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.scriptFontSizeFactor);
  }

  /// Resolves the nearest `onLinkTap` callback from the hierarchy.
  void Function(String url, String displayText)? getEffectiveOnLinkTap(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.onLinkTap);
  }

  /// Resolves the nearest `onLinkHover` callback from the hierarchy.
  void Function(String url, String displayText, {required bool isHovering})?
      getEffectiveOnLinkHover(
    BuildContext context,
  ) {
    return resolver.findFirstAncestorValue(context, (o) => o.onLinkHover);
  }

  /// Resolves the nearest `linkMouseCursor` from the hierarchy.
  MouseCursor? getEffectiveLinkMouseCursor(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.linkMouseCursor);
  }

  /// Resolves the nearest `strikethroughThickness` from the hierarchy.
  double? getEffectiveStrikethroughThickness(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.strikethroughThickness);
  }

  /// Resolves the nearest `linkAlignment` from the hierarchy.
  PlaceholderAlignment? getEffectiveLinkAlignment(BuildContext context) {
    return resolver.findFirstAncestorValue(context, (o) => o.linkAlignment);
  }

  /// Checks if this instance has the same style-related properties as [other].
  bool hasSameStyle(TextfOptions other) {
    if (identical(this, other)) return true;

    return other.onLinkTap == onLinkTap &&
        other.onLinkHover == onLinkHover &&
        other.linkMouseCursor == linkMouseCursor &&
        other.linkStyle == linkStyle &&
        other.linkAlignment == linkAlignment &&
        other.linkHoverStyle == linkHoverStyle &&
        other.boldStyle == boldStyle &&
        other.italicStyle == italicStyle &&
        other.boldItalicStyle == boldItalicStyle &&
        other.strikethroughStyle == strikethroughStyle &&
        other.codeStyle == codeStyle &&
        other.strikethroughThickness == strikethroughThickness &&
        other.underlineStyle == underlineStyle &&
        other.highlightStyle == highlightStyle &&
        other.superscriptStyle == superscriptStyle &&
        other.subscriptStyle == subscriptStyle &&
        other.superscriptBaselineFactor == superscriptBaselineFactor &&
        other.subscriptBaselineFactor == subscriptBaselineFactor &&
        other.scriptFontSizeFactor == scriptFontSizeFactor;
  }

  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    return !hasSameStyle(oldWidget);
  }

  /// Computes a hash of all resolved TextfOptions values with a single tree walk.
  ///
  /// Performance: O(Depth) tree walk + O(Depth) property iteration.
  /// This is much faster than calling getEffective... for each property,
  /// which would be O(Properties x Depth).
  static int computeResolvedHash(BuildContext context, TextStyle baseStyle) {
    return resolver.computeOptionsResolvedHash(context, baseStyle);
  }
}
