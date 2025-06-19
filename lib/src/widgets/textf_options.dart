import 'package:flutter/material.dart';

// TODO: [Decoration Combining on Options Level]
// The current `getEffective...Style` methods (e.g., getEffectiveUnderlineStyle,
// getEffectiveStrikethroughStyle) use `baseStyle.merge(optionsStyle)`.
// If `optionsStyle` defines a `decoration`, it will override any `decoration`
// present in `baseStyle` (which might have been applied by an outer TextfOptions
// or a DefaultStyles fallback for a different format).
//
// This is standard TextStyle.merge behavior and is predictable.
// However, for scenarios where a user might want an `optionsStyle` (e.g., for strikethrough)
// to *combine* its decoration with a decoration already present in `baseStyle`
// (e.g., an underline from a parent TextfOptions or a DefaultStyles.underlineStyle call),
// the current merge logic is insufficient for automatic combination.
//
// The `DefaultStyles.underlineStyle` and `DefaultStyles.strikethroughStyle` methods
// *do* implement logic to combine decorations if called sequentially by the resolver
// when no options are overriding them.
//
// Potential Solution for Options-Level Combining:
// Each `getEffective...Style` method that deals with decorations could be made more
// intelligent. If `optionsStyle.decoration` is not null and `baseStyle.decoration` is also
// not null (and they are different and neither is TextDecoration.none),
// it could explicitly use `TextDecoration.combine([baseStyle.decoration!, optionsStyle.decoration!])`.
//
// This would involve:
// 1. Checking if both `baseStyle` and `optionsStyle` have non-null, different,
//    and non-`TextDecoration.none` decorations.
// 2. If so, creating a new `TextStyle` that includes the combined decoration.
// 3. Carefully considering which `decorationColor` and `decorationThickness`
//    should apply to the combined decoration (likely those from `optionsStyle`
//    would take precedence for the part of the decoration it's contributing).
//    This is a limitation of TextStyle, which only allows one color/thickness
//    for all combined decorations.
//
// Example for getEffectiveStrikethroughStyle:
/*
TextStyle? getEffectiveStrikethroughStyle(BuildContext context, TextStyle baseStyle) {
  final optionsSpecificStyle = _findFirstAncestorValue(context, (o) => o.strikethroughStyle);
  if (optionsSpecificStyle == null) {
    return null; // No option defined
  }

  TextStyle mergedStyle = baseStyle.merge(optionsSpecificStyle); // Initial merge

  // Intelligent decoration combination
  final baseDecoration = baseStyle.decoration;
  final optionDecoration = optionsSpecificStyle.decoration;

  if (optionDecoration != null && optionDecoration != TextDecoration.none &&
      baseDecoration != null && baseDecoration != TextDecoration.none &&
      !baseDecoration.contains(optionDecoration) // Avoid re-adding same decoration
  ) {
    // Both have distinct, active decorations, so combine them.
    // The optionsSpecificStyle's color/thickness for its part of the decoration
    // would implicitly win due to the initial merge order if not further specified.
    mergedStyle = mergedStyle.copyWith(
      decoration: TextDecoration.combine([baseDecoration, optionDecoration]),
      // decorationColor and decorationThickness from optionsSpecificStyle are preferred.
      // If baseStyle had a decorationColor and optionsSpecificStyle doesn't,
      // merge might clear it or keep base's. Explicit handling might be needed
      // if optionsSpecificStyle should only contribute its decoration type but not color/thickness.
      // For now, optionsSpecificStyle's decoration-related properties (if any) take precedence for the combined effect.
      decorationColor: optionsSpecificStyle.decorationColor ?? mergedStyle.decorationColor, // Prefer option's color
      decorationThickness: optionsSpecificStyle.decorationThickness ?? mergedStyle.decorationThickness, // Prefer option's thickness
    );
  }
  // If optionDecoration is TextDecoration.none, merge already handled clearing it.
  // If only one has a decoration, merge already handled it.

  return mergedStyle;
}
*/
// This enhanced logic would make TextfOptions more powerful for fine-grained
// control over combined decorations originating from different levels of the options tree,
// but increases the complexity of these getter methods.
// For now, the simpler override behavior is in place for options.

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget uses the `InheritedWidget` pattern to make configuration
/// available to descendant `Textf` widgets. Options include styling for different
/// formatting types (bold, italic, code, links, underline, highlight)
/// and callbacks for link interactions.
///
/// ## Implicit Inheritance and Style Resolution
///
/// When resolving a style (e.g., for bold text), the system (specifically
/// `TextfStyleResolver` interacting with these methods) follows this process:
///
/// 1. **Check Ancestor Options:** It calls the relevant `getEffective...Style`
///    method on the nearest `TextfOptions` ancestor (e.g., `getEffectiveBoldStyle`).
///    This method looks up the widget tree for the *first* ancestor `TextfOptions`
///    that defines that specific style property (e.g., `boldStyle`).
/// 2. **Apply Option Style:** If an ancestor option is found, it's merged with the
///    current segment's `baseStyle` and returned. This result is used directly.
/// 3. **Return Null:** If *no* ancestor `TextfOptions` defines the specific style
///    property, the `getEffective...Style` method returns `null`.
/// 4. **Resolver Fallback:** When `TextfStyleResolver` receives `null`, it knows
///    no explicit option was provided. It then applies its own fallback logic:
///    - For code/links/highlight: It derives a style from the current `ThemeData`.
///    - For bold/italic/strike/underline: It applies the relative default effect
///      from `DefaultStyles` to the `baseStyle`.
///
/// This ensures explicit options always win, followed by theme defaults (where applicable),
/// and finally package defaults.
///
/// Callbacks (`onUrlTap`, `onUrlHover`) and `urlMouseCursor` also search up the tree
/// for the first non-null value.
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

  /// Finds the nearest [TextfOptions] ancestor in the widget tree.
  /// Returns null if no ancestor is found. Does not establish a dependency.
  static TextfOptions? maybeOf(BuildContext context) {
    final inheritedElement = context.getElementForInheritedWidgetOfExactType<TextfOptions>();

    return inheritedElement?.widget as TextfOptions?;
  }

  /// Finds the nearest [TextfOptions] ancestor and establishes a dependency.
  /// Throws if no ancestor is found.
  static TextfOptions of(BuildContext context) {
    final TextfOptions? result = context.dependOnInheritedWidgetOfExactType<TextfOptions>();
    if (result == null) {
      throw FlutterError(
        'No TextfOptions found in context. Wrap your widget with TextfOptions '
        'or ensure one exists higher in the tree.',
      );
    }

    return result;
  }

  /// Callback function executed when tapping/clicking on a URL.
  /// Provides the resolved `url` and the raw `displayText` including formatting markers.
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when hovering over a URL.
  /// Provides the resolved `url`, raw `displayText`, and hover state `isHovering`.
  final void Function(String url, String displayText, {required bool isHovering})? onUrlHover;

  /// Styling for URLs in normal state. Merged **onto** the base text style if provided.
  final TextStyle? urlStyle;

  /// Styling for URLs in hover state. Merged **onto** the final *normal* URL style if provided.
  final TextStyle? urlHoverStyle;

  /// The mouse cursor to use when hovering over a URL link. Inherits up the tree.
  final MouseCursor? urlMouseCursor;

  /// Styling for bold formatted text. Merged **onto** the base text style if provided.
  final TextStyle? boldStyle;

  /// Styling for italic formatted text. Merged **onto** the base text style if provided.
  final TextStyle? italicStyle;

  /// Styling for bold and italic formatted text. Merged **onto** the base text style if provided.
  final TextStyle? boldItalicStyle;

  /// Styling for strikethrough text. Merged **onto** the base text style if provided.
  final TextStyle? strikethroughStyle;

  /// Styling for inline code text. Merged **onto** the base text style if provided.
  final TextStyle? codeStyle;

  /// Optional thickness for the default strikethrough decoration line.
  /// This value is only used if `strikethroughStyle` is *not* provided.
  /// If null, `DefaultStyles.defaultStrikethroughThickness` is used.
  /// Inherits up the tree.
  final double? strikethroughThickness;

  /// Styling for underlined text (`++underline++`).
  /// Merged **onto** the base text style if provided.
  final TextStyle? underlineStyle;

  /// Styling for highlighted text (`==highlight==`).
  /// Merged **onto** the base text style if provided.
  final TextStyle? highlightStyle;

  // Helper function to iteratively search ancestors for the first non-null value
  // of a specific property getter.
  T? _findFirstAncestorValue<T>(
    BuildContext context,
    T? Function(TextfOptions options) getter,
  ) {
    // Start search from the element associated with the context used to find 'this' instance
    // or the nearest ancestor if 'this' wasn't found directly via context.
    Element? currentElement = context.getElementForInheritedWidgetOfExactType<TextfOptions>();

    while (currentElement != null) {
      // Ensure the widget associated with the element is indeed TextfOptions
      if (currentElement.widget is TextfOptions) {
        final currentOptions = currentElement.widget as TextfOptions;
        final value = getter(currentOptions);
        if (value != null) {
          return value; // Found the first non-null value
        }
      }
      // Move up to the next ancestor TextfOptions
      Element? parentElement;
      currentElement.visitAncestorElements((Element ancestor) {
        if (ancestor.widget is TextfOptions) {
          parentElement = ancestor;

          return false; // Stop searching upwards for this iteration
        }

        return true; // Continue searching upwards
      });
      currentElement = parentElement; // Prepare for the next loop iteration
    }

    return null; // Not found anywhere up the tree
  }

  // --- Effective Style Getters ---
  // These methods find the first defined style in the ancestor chain
  // and merge it with the baseStyle. They return NULL if no ancestor defines the style.

  /// Finds the first defined `boldStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `boldStyle`.
  TextStyle? getEffectiveBoldStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.boldStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `italicStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `italicStyle`.
  TextStyle? getEffectiveItalicStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.italicStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `boldItalicStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `boldItalicStyle`.
  TextStyle? getEffectiveBoldItalicStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.boldItalicStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `strikethroughStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `strikethroughStyle`.
  /// Note: This does *not* handle `strikethroughThickness` directly here. The resolver
  /// uses `getEffectiveStrikethroughThickness` if this method returns null.
  TextStyle? getEffectiveStrikethroughStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.strikethroughStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `codeStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `codeStyle`.
  TextStyle? getEffectiveCodeStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.codeStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `urlStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `urlStyle`.
  TextStyle? getEffectiveUrlStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.urlStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `urlHoverStyle` up the tree and merges it onto
  /// the resolved *normal* URL style (which itself considers options and base style).
  /// Returns `null` if no ancestor defines `urlHoverStyle`.
  TextStyle? getEffectiveUrlHoverStyle(BuildContext context, TextStyle baseStyle) {
    // This logic for hover needs to merge onto the *final normal link style*.
    // The TextfStyleResolver handles this by first getting the normal link style
    // (which might be from options or theme), and then if this method returns a
    // hover-specific option, it merges that onto the already resolved normal style.
    // So, this method just needs to find the hover option and merge it with the
    // *incoming baseStyle* (which, for hover, is the resolved normal link style).

    final hoverOption = _findFirstAncestorValue(context, (o) => o.urlHoverStyle);
    if (hoverOption == null) {
      return null; // No hover option specified, resolver handles fallback.
    }
    // Merge the found hover option onto the provided baseStyle (which is the normal link style)
    return baseStyle.merge(hoverOption);
  }

  /// Finds the first defined `underlineStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `underlineStyle`.
  TextStyle? getEffectiveUnderlineStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.underlineStyle);
    // If an option style is found, merge it. Otherwise, return null.
    // The intelligent combination of decorations (if any in baseStyle)
    // would ideally happen here if the optionsStyle also has a decoration.
    // For simplicity now, we use standard merge. If DefaultStyles has already
    // combined decorations, and optionsStyle also defines one, option wins.
    // If we want Option to combine with what DefaultStyles did, this needs more logic.
    // Current approach: Option style takes precedence for decoration.
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  /// Finds the first defined `highlightStyle` up the tree and merges it with `baseStyle`.
  /// Returns `null` if no ancestor defines `highlightStyle`.
  TextStyle? getEffectiveHighlightStyle(BuildContext context, TextStyle baseStyle) {
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.highlightStyle);
    return optionsStyle == null ? null : baseStyle.merge(optionsStyle);
  }

  // --- Effective Callback & Cursor Getters ---

  /// Finds the first non-null [onUrlTap] callback defined up the tree.
  void Function(String url, String displayText)? getEffectiveOnUrlTap(BuildContext context) {
    return _findFirstAncestorValue(context, (options) => options.onUrlTap);
  }

  /// Finds the first non-null [onUrlHover] callback defined up the tree.
  /// TODO: 'bool' parameters should be named parameters.
  void Function(String url, String displayText, {required bool isHovering})? getEffectiveOnUrlHover(
    BuildContext context,
  ) {
    return _findFirstAncestorValue(context, (options) => options.onUrlHover);
  }

  /// Finds the first non-null [urlMouseCursor] defined up the tree, falling back to default.
  MouseCursor? getEffectiveUrlMouseCursor(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.urlMouseCursor);
    // Fallback to DefaultStyles.urlMouseCursor happens in the resolver if this returns null.
  }

  /// Finds the first non-null [strikethroughThickness] defined up the tree.
  /// Returns null if none is found (resolver applies final default from DefaultStyles).
  double? getEffectiveStrikethroughThickness(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.strikethroughThickness);
  }

  /// Determines if the widget tree should be rebuilt when options change.
  /// Compares only the properties of this specific instance.
  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    // Compare all properties directly held by this widget instance.
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
