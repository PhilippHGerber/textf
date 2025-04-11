import 'package:flutter/material.dart';

import '../core/default_styles.dart';

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget uses the `InheritedWidget` pattern to make configuration
/// available to descendant `Textf` widgets. Options include styling for different
/// formatting types (bold, italic, code, links) and callbacks for link interactions.
///
/// ## Implicit Inheritance
///
/// When multiple `TextfOptions` are nested in the widget tree, a `Textf` widget
/// will use the configuration from the nearest ancestor `TextfOptions`. However,
/// if a specific property (e.g., `boldStyle`) is `null` on the nearest ancestor,
/// `TextfOptions` will automatically look up the widget tree for the *next*
/// ancestor `TextfOptions` that *does* define that property. If no ancestor
/// defines the property, the package's built-in default (from `DefaultStyles`)
/// will be used.
///
/// This allows you to set global defaults high up in the tree and override only
/// specific properties in nested `TextfOptions` widgets without needing to
/// manually copy all other properties.
///
/// ```dart
/// TextfOptions( // Root options
///   boldStyle: TextStyle(fontWeight: FontWeight.w900),
///   urlStyle: TextStyle(color: Colors.blue),
///   onUrlTap: (url, text) => print('Root tap: $url'),
///   child: ...,
///     TextfOptions( // Nested options
///       urlStyle: TextStyle(color: Colors.green), // Only override URL style
///       // boldStyle will implicitly be inherited from the root options
///       // onUrlTap will implicitly be inherited from the root options
///       child: Textf("This uses green [links](...) and w900 **bold** text."),
///     )
///   ...,
/// )
/// ```
class TextfOptions extends InheritedWidget {
  /// Callback function executed when tapping/clicking on a URL.
  /// Provides the resolved [url] and the raw [displayText] including formatting markers.
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when hovering over a URL.
  /// Provides the resolved [url], raw [displayText], and hover state [isHovering].
  final void Function(String url, String displayText, bool isHovering)?
      onUrlHover;

  /// Styling for URLs in normal state. Merged with the base text style.
  final TextStyle? urlStyle;

  /// Styling for URLs in hover state. Merged with the effective normal URL style.
  final TextStyle? urlHoverStyle;

  /// The mouse cursor to use when hovering over a URL link.
  final MouseCursor? urlMouseCursor;

  /// Styling for bold formatted text. Merged with the base text style.
  final TextStyle? boldStyle;

  /// Styling for italic formatted text. Merged with the base text style.
  final TextStyle? italicStyle;

  /// Styling for bold and italic formatted text. Merged with the base text style.
  final TextStyle? boldItalicStyle;

  /// Styling for strikethrough text. Merged with the base text style.
  final TextStyle? strikethroughStyle;

  /// Styling for inline code text. Merged with the base text style.
  final TextStyle? codeStyle;

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
  });

  /// Finds the nearest [TextfOptions] ancestor in the widget tree.
  /// Returns null if no ancestor is found.
  static TextfOptions? maybeOf(BuildContext context) {
    // Use getElementForInheritedWidgetOfExactType for potentially better performance
    // as it doesn't establish a dependency.
    final inheritedElement =
        context.getElementForInheritedWidgetOfExactType<TextfOptions>();
    return inheritedElement?.widget as TextfOptions?;
  }

  /// Finds the nearest [TextfOptions] ancestor and establishes a dependency.
  static TextfOptions of(BuildContext context) {
    final TextfOptions? result =
        context.dependOnInheritedWidgetOfExactType<TextfOptions>();
    assert(result != null,
        'No TextfOptions found in context. Wrap your widget with TextfOptions or ensure one exists higher in the tree.');
    return result!;
  }

  // Helper function to iteratively search ancestors for a non-null value
  T? _findFirstAncestorValue<T>(
    BuildContext context,
    T? Function(TextfOptions options) getter,
  ) {
    // Start search from the element associated with the context used to find 'this'
    Element? currentElement =
        context.getElementForInheritedWidgetOfExactType<TextfOptions>();

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

  /// Calculates the effective style by applying defaults, base, and overrides.
  /// Priority: Specified Override > Default Style Effect > Base Style
  TextStyle _getEffectiveStyle(
    BuildContext context,
    TextStyle baseStyle,
    TextStyle? Function(TextfOptions options)
        getter, // Function to get the specified override style
    TextStyle Function(TextStyle base)
        defaultApplier, // Function to apply the default effect (e.g., add bold)
  ) {
    // 1. Apply the default styling effect to the base style.
    //    e.g., for bold, this adds fontWeight: FontWeight.bold to baseStyle
    final styleWithDefaultApplied = defaultApplier(baseStyle);

    // 2. Find the first specified override style up the ancestor chain.
    final specifiedStyle = _findFirstAncestorValue(context, getter);

    // 3. Merge the specified override onto the style that already has the default effect.
    //    This ensures the override takes precedence over both base and default effects.
    //    If specifiedStyle is null, merge(null) does nothing.
    return styleWithDefaultApplied.merge(specifiedStyle);
  }

  /// Calculates the effective URL style.
  /// Precedence: Specified Override > Default Link Style (color/deco) > Base Style
  TextStyle getEffectiveUrlStyle(BuildContext context, TextStyle baseStyle) {
    // 1. Start with the base style properties (fontSize, fontFamily, etc.)
    TextStyle effectiveStyle = baseStyle;

    // 2. Apply the default URL look (color, decoration) ON TOP of the base.
    //    This ensures we get the default blue/underline unless overridden later.
    effectiveStyle = effectiveStyle.merge(DefaultStyles.urlStyle);
    // Now effectiveStyle has base props + default url color/decoration.
    // e.g., if base={color:black, size:16}, style is now {color:blue, deco:underline, size:16}

    // 3. Find the specific override from TextfOptions ancestors.
    final specifiedStyle = _findFirstAncestorValue(context, (o) => o.urlStyle);

    // 4. Merge the override ON TOP of the current style.
    //    If specifiedStyle has color or decoration, it will overwrite the defaults.
    //    If it has other properties (like fontSize), it will overwrite the base.
    if (specifiedStyle != null) {
      effectiveStyle = effectiveStyle.merge(specifiedStyle);
      // e.g., if specified={color:green, deco:none}, style becomes {color:green, deco:none, size:16}
    }

    return effectiveStyle;
  }

  /// Calculates the effective URL hover style.
  /// Precedence: Specified Hover Override > Default Hover Effect > Effective Normal URL Style
  TextStyle getEffectiveUrlHoverStyle(
      BuildContext context, TextStyle baseStyle) {
    // 1. Get the fully resolved normal URL style using the corrected logic above.
    final effectiveNormalStyle = getEffectiveUrlStyle(context, baseStyle);

    // 2. Start with the effective NORMAL style as the base for hover.
    TextStyle effectiveHoverStyle = effectiveNormalStyle;

    // 3. Apply the default HOVER effect (changes color/etc.) ON TOP of the normal style.
    //    This merges the default hover changes (e.g., darker blue) onto the calculated normal style.
    effectiveHoverStyle =
        effectiveHoverStyle.merge(DefaultStyles.urlHoverStyle);
    // e.g., if normal style was {color:green, deco:none, size:16},
    // and default hover is {color:darkerBlue}, style is now {color:darkerBlue, deco:none, size:16}

    // 4. Find the specific hover override style up the ancestor chain.
    final specifiedHoverStyle =
        _findFirstAncestorValue(context, (o) => o.urlHoverStyle);

    // 5. Merge the specified hover override ON TOP. Override takes final precedence for hover state.
    if (specifiedHoverStyle != null) {
      effectiveHoverStyle = effectiveHoverStyle.merge(specifiedHoverStyle);
      // e.g., if specified hover is {background:yellow}, style becomes
      // {color:darkerBlue, deco:none, size:16, background:yellow}
    }

    return effectiveHoverStyle;
  }

  // --- Effective Callback Getters with Ancestor Lookup ---

  /// Finds the first non-null [onUrlTap] callback defined up the tree.
  void Function(String url, String displayText)? getEffectiveOnUrlTap(
      BuildContext context) {
    // Pass the getter for onUrlTap to the helper function
    return _findFirstAncestorValue(context, (options) => options.onUrlTap);
  }

  /// Finds the first non-null [onUrlHover] callback defined up the tree.
  void Function(String url, String displayText, bool isHovering)?
      getEffectiveOnUrlHover(BuildContext context) {
    // Pass the getter for onUrlHover to the helper function
    return _findFirstAncestorValue(context, (options) => options.onUrlHover);
  }

  // --- Property Getters using the corrected _getEffectiveStyle ---

  /// Finds the first non-null [urlMouseCursor] defined up the tree, falling back to default.
  MouseCursor getEffectiveUrlMouseCursor(BuildContext context) {
    return _findFirstAncestorValue(context, (o) => o.urlMouseCursor) ??
        DefaultStyles.urlMouseCursor;
  }

  TextStyle getEffectiveBoldStyle(BuildContext context, TextStyle baseStyle) {
    return _getEffectiveStyle(
        context, baseStyle, (o) => o.boldStyle, DefaultStyles.boldStyle);
  }

  TextStyle getEffectiveItalicStyle(BuildContext context, TextStyle baseStyle) {
    return _getEffectiveStyle(
        context, baseStyle, (o) => o.italicStyle, DefaultStyles.italicStyle);
  }

  TextStyle getEffectiveBoldItalicStyle(
      BuildContext context, TextStyle baseStyle) {
    return _getEffectiveStyle(context, baseStyle, (o) => o.boldItalicStyle,
        DefaultStyles.boldItalicStyle);
  }

  TextStyle getEffectiveStrikethroughStyle(
      BuildContext context, TextStyle baseStyle) {
    return _getEffectiveStyle(context, baseStyle, (o) => o.strikethroughStyle,
        DefaultStyles.strikethroughStyle);
  }

  TextStyle getEffectiveCodeStyle(BuildContext context, TextStyle baseStyle) {
    return _getEffectiveStyle(
        context, baseStyle, (o) => o.codeStyle, DefaultStyles.codeStyle);
  }

  /// Determines if the widget tree should be rebuilt when options change.
  /// Compares only the properties of this specific instance.
  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    return onUrlTap != oldWidget.onUrlTap ||
        onUrlHover != oldWidget.onUrlHover ||
        urlStyle != oldWidget.urlStyle ||
        urlHoverStyle != oldWidget.urlHoverStyle ||
        urlMouseCursor != oldWidget.urlMouseCursor ||
        boldStyle != oldWidget.boldStyle ||
        italicStyle != oldWidget.italicStyle ||
        boldItalicStyle != oldWidget.boldItalicStyle ||
        strikethroughStyle != oldWidget.strikethroughStyle ||
        codeStyle != oldWidget.codeStyle;
  }
}
