import 'package:flutter/material.dart';

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget uses the `InheritedWidget` pattern to make configuration
/// available to descendant `Textf` widgets. Options include styling for different
/// formatting types (bold, italic, code, links) and callbacks for link interactions.
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
///    - For code/links: It derives a style from the current `ThemeData`.
///    - For bold/italic/strike: It applies the relative default effect (e.g.,
///      `FontWeight.bold`) from `DefaultStyles` to the `baseStyle`.
///
/// This ensures explicit options always win, followed by theme defaults (where applicable),
/// and finally package defaults.
///
/// Callbacks (`onUrlTap`, `onUrlHover`) and `urlMouseCursor` also search up the tree
/// for the first non-null value.
class TextfOptions extends InheritedWidget {
  /// Callback function executed when tapping/clicking on a URL.
  /// Provides the resolved `url` and the raw `displayText` including formatting markers.
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when hovering over a URL.
  /// Provides the resolved `url`, raw `displayText`, and hover state `isHovering`.
  final void Function(String url, String displayText, bool isHovering)? onUrlHover;

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

  /// Creates a new TextfOptions instance to provide configuration down the tree.
  const TextfOptions({
    super.key,
    required super.child,
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
    assert(
      result != null,
      'No TextfOptions found in context. Wrap your widget with TextfOptions '
      'or ensure one exists higher in the tree.',
    );
    return result!;
  }

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
    final optionsHoverStyle = _findFirstAncestorValue(context, (o) => o.urlHoverStyle);
    if (optionsHoverStyle == null) {
      return null; // No specific hover style defined in options hierarchy
    }

    // Revert to original corrected plan: Find option, if found, merge onto base. Resolver uses this result.
    final optionsStyle = _findFirstAncestorValue(context, (o) => o.urlHoverStyle);
    if (optionsStyle == null) {
      return null;
    }

    // --- Final Attempt at Clean Logic ---
    // 1. Find the specific hover style defined in options.
    final hoverOption = _findFirstAncestorValue(context, (o) => o.urlHoverStyle);
    if (hoverOption == null) {
      return null; // No hover option specified, resolver handles fallback.
    }

    // 2. Find the normal style *as defined by options only*.
    final normalOption = _findFirstAncestorValue(context, (o) => o.urlStyle);

    // 3. Determine the base for merging the hover option:
    //    - If a normal option exists, merge hover onto (base merged with normal option).
    //    - If no normal option exists, merge hover onto base directly.
    final TextStyle baseForHover = normalOption == null ? baseStyle : baseStyle.merge(normalOption);

    // 4. Merge the specific hover option onto the calculated base.
    return baseForHover.merge(hoverOption);
  }

  // --- Effective Callback & Cursor Getters ---

  /// Finds the first non-null [onUrlTap] callback defined up the tree.
  void Function(String url, String displayText)? getEffectiveOnUrlTap(BuildContext context) {
    return _findFirstAncestorValue(context, (options) => options.onUrlTap);
  }

  /// Finds the first non-null [onUrlHover] callback defined up the tree.
  void Function(String url, String displayText, bool isHovering)? getEffectiveOnUrlHover(BuildContext context) {
    return _findFirstAncestorValue(context, (options) => options.onUrlHover);
  }

  /// Finds the first non-null [urlMouseCursor] defined up the tree, falling back to default.
  MouseCursor? getEffectiveUrlMouseCursor(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.urlMouseCursor);
  }

  /// Finds the first non-null [strikethroughThickness] defined up the tree.
  /// Returns null if none is found (resolver applies final default).
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
        strikethroughThickness != oldWidget.strikethroughThickness;
  }
}
