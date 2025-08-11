import 'package:flutter/material.dart';

/// Merges two [TextStyle] objects with special handling for [TextDecoration].
///
/// Unlike the standard [TextStyle.merge], this function intelligently combines
/// decorations from both styles instead of letting the [optionsStyle]'s decoration
/// completely overwrite the [baseStyle]'s.
///
/// The merging logic is as follows:
/// 1.  All properties from [optionsStyle] (e.g., `color`, `fontWeight`,
///     `fontSize`) take precedence over [baseStyle], except for decoration.
/// 2.  Decoration-related properties (`decorationColor`, `decorationThickness`,
///     `decorationStyle`) from [optionsStyle] are given priority.
/// 3.  The `decoration` property itself is combined:
///     - If both styles have active, distinct decorations, they are combined
///       using [TextDecoration.combine].
///     - If [optionsStyle] specifies `TextDecoration.none`, any decoration from
///       [baseStyle] is removed.
///     - In all other cases, the standard merge logic applies (i.e., the
///       [optionsStyle]'s decoration is used).
///
/// This ensures that nested [TextfOptions] can layer decorations (e.g., add a
/// strikethrough to an existing underline) in an intuitive way.
///
/// - [baseStyle]: The base style, typically from a parent `TextfOptions` or
///   a `DefaultTextStyle`.
/// - [optionsStyle]: The style from the current `TextfOptions` widget, which
///   should take precedence.
///
/// Returns a new [TextStyle] with the properties correctly merged and
/// decorations combined.
TextStyle _mergeStyles(TextStyle baseStyle, TextStyle optionsStyle) {
  final TextDecoration? baseDecoration = baseStyle.decoration;
  final TextDecoration? optionDecoration = optionsStyle.decoration;

  TextDecoration? finalDecoration;

  final bool shouldCombine = optionDecoration != null &&
      optionDecoration != TextDecoration.none &&
      baseDecoration != null &&
      baseDecoration != TextDecoration.none &&
      !baseDecoration.contains(optionDecoration);

  finalDecoration = shouldCombine
      ? TextDecoration.combine([baseDecoration, optionDecoration])
      : optionDecoration ?? baseDecoration;

  return baseStyle.merge(optionsStyle).copyWith(
        decoration: finalDecoration,
      );
}

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget uses the `InheritedWidget` pattern to make configuration
/// available to all descendant `Textf` widgets. It allows for hierarchical
/// styling and behavior management.
///
/// ## Style Inheritance Logic
///
/// `TextStyle` properties (like `boldStyle`, `urlStyle`, etc.) are resolved
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
/// Non-style properties that cannot be merged (like `onUrlTap`, `onUrlHover`,
/// and `urlMouseCursor`) use a **"nearest ancestor wins"** strategy. The first
/// non-null value found when searching up the widget tree from the `Textf`
/// widget is the one that will be used.
class TextfOptions extends InheritedWidget {
  /// Creates a new TextfOptions instance to provide configuration down the tree.
  const TextfOptions({
    required super.child,
    super.key,
    this.onUrlTap,
    this.onUrlHover,
    this.urlMouseCursor,
    this.urlStyle,
    this.urlHoverStyle,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.strikethroughThickness,
    this.underlineStyle,
    this.highlightStyle,
  });

  /// Callback function executed when tapping or clicking on a URL.
  /// Provides the resolved `url` and the raw `displayText` including any
  /// original formatting markers (e.g., `**bold link**`).
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when the mouse pointer enters or exits a URL.
  /// Provides the resolved `url`, the raw `displayText`, and the hover state
  /// (`isHovering` is `true` on enter, `false` on exit).
  final void Function(String url, String displayText, {required bool isHovering})? onUrlHover;

  /// The [TextStyle] for link text (`[text](url)`) in its normal (non-hovered) state.
  /// Merged onto the base style if provided.
  final TextStyle? urlStyle;

  /// The [TextStyle] for link text when hovered.
  /// This style is merged on top of the link's final normal style.
  final TextStyle? urlHoverStyle;

  /// The [MouseCursor] to display when hovering over a URL link.
  final MouseCursor? urlMouseCursor;

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

  // ===== STATIC HELPERS FOR STYLE RESOLUTION LOGIC =====

  /// Gathers all [TextfOptions] widgets from the current context upwards.
  /// The returned list is ordered from the nearest ancestor to the furthest.
  static List<TextfOptions> _getAncestorOptions(BuildContext context) {
    final List<TextfOptions> optionsHierarchy = [];
    context.visitAncestorElements((element) {
      if (element.widget is TextfOptions) {
        optionsHierarchy.add(element.widget as TextfOptions);
      }
      return true; // Continue visiting all the way to the root.
    });
    return optionsHierarchy;
  }

  /// Merges a specific [TextStyle] property from the entire options hierarchy.
  ///
  /// It achieves this by reversing the ancestor list (to start from the
  /// top-most parent) and iteratively merging styles downwards.
  static TextStyle? _getMergedStyleFromHierarchy(
    BuildContext context,
    TextStyle? Function(TextfOptions) getter,
  ) {
    final List<TextfOptions> hierarchy = _getAncestorOptions(context);
    if (hierarchy.isEmpty) {
      return null;
    }

    // Reverse the list to start from the top-most ancestor and merge down.
    final Iterable<TextfOptions> reversedHierarchy = hierarchy.reversed;
    TextStyle? finalStyle;

    for (final options in reversedHierarchy) {
      final TextStyle? localStyle = getter(options);
      if (localStyle != null) {
        finalStyle = finalStyle == null ? localStyle : _mergeStyles(finalStyle, localStyle);
      }
    }
    return finalStyle;
  }

  /// Finds the first non-null value for a given property by searching up
  /// the widget tree (from nearest to furthest).
  ///
  /// This is used for non-mergeable properties like callbacks and enums where
  /// a "nearest wins" strategy is appropriate.
  static T? _findFirstAncestorValue<T>(
    BuildContext context,
    T? Function(TextfOptions) getter,
  ) {
    final List<TextfOptions> hierarchy = _getAncestorOptions(context);
    for (final options in hierarchy) {
      final T? value = getter(options);
      if (value != null) {
        return value; // Found the nearest value, stop searching.
      }
    }
    return null; // Reached the top with no value found.
  }

  // ===== EFFECTIVE GETTERS (Used by TextfStyleResolver) =====

  /// Resolves the final merged `boldStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveBoldStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.boldStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `italicStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveItalicStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.italicStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `boldItalicStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveBoldItalicStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.boldItalicStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `strikethroughStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveStrikethroughStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle =
        _getMergedStyleFromHierarchy(context, (o) => o.strikethroughStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `codeStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveCodeStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.codeStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `urlStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveUrlStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.urlStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `urlHoverStyle` and merges it onto the final `normalLinkStyle`.
  TextStyle? getEffectiveUrlHoverStyle(BuildContext context, TextStyle normalLinkStyle) {
    final TextStyle? hoverOptionsStyle =
        _getMergedStyleFromHierarchy(context, (o) => o.urlHoverStyle);
    if (hoverOptionsStyle == null) return null;
    return _mergeStyles(normalLinkStyle, hoverOptionsStyle);
  }

  /// Resolves the final merged `underlineStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveUnderlineStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.underlineStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the final merged `highlightStyle` from the hierarchy and merges it onto `baseStyle`.
  TextStyle? getEffectiveHighlightStyle(BuildContext context, TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyleFromHierarchy(context, (o) => o.highlightStyle);
    return optionsStyle == null ? null : _mergeStyles(baseStyle, optionsStyle);
  }

  /// Resolves the nearest `onUrlTap` callback from the hierarchy.
  void Function(String url, String displayText)? getEffectiveOnUrlTap(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.onUrlTap);
  }

  /// Resolves the nearest `onUrlHover` callback from the hierarchy.
  void Function(String url, String displayText, {required bool isHovering})? getEffectiveOnUrlHover(
    BuildContext context,
  ) {
    return _findFirstAncestorValue(context, (o) => o.onUrlHover);
  }

  /// Resolves the nearest `urlMouseCursor` from the hierarchy.
  MouseCursor? getEffectiveUrlMouseCursor(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.urlMouseCursor);
  }

  /// Resolves the nearest `strikethroughThickness` from the hierarchy.
  double? getEffectiveStrikethroughThickness(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.strikethroughThickness);
  }

  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    // Comparing only the properties of this specific instance.
    return onUrlTap != oldWidget.onUrlTap ||
        onUrlHover != oldWidget.onUrlHover ||
        urlStyle != oldWidget.urlStyle ||
        urlHoverStyle != oldWidget.urlHoverStyle ||
        urlMouseCursor != oldWidget.urlMouseCursor ||
        boldStyle != oldWidget.boldStyle ||
        italicStyle != oldWidget.italicStyle ||
        boldItalicStyle != oldWidget.boldItalicStyle ||
        strikethroughStyle != oldWidget.strikethroughStyle ||
        codeStyle != oldWidget.codeStyle ||
        strikethroughThickness != oldWidget.strikethroughThickness ||
        underlineStyle != oldWidget.underlineStyle ||
        highlightStyle != oldWidget.highlightStyle;
  }
}
