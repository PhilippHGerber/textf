import 'package:flutter/material.dart';

import '../core/default_styles.dart';
import '../core/textf_limits.dart';
import '../core/textf_style_utils.dart';
import '../models/textf_token.dart';
import '../widgets/internal/textf_options_resolver.dart' as resolver;
import '../widgets/textf_options.dart';

/// A class responsible for resolving the final TextStyle for formatted text segments.
///
/// It orchestrates the application of styles based on the following precedence:
/// 1. Explicit styles defined in the nearest ancestor `TextfOptions`.
/// 2. Styles inherited from higher `TextfOptions` ancestors.
/// 3. Theme-based default styles derived from the application's `ThemeData`
///    (for code, links, highlight).
/// 4. Relative default styles from `DefaultStyles`
///    (for bold, italic, strikethrough, underline).
///
/// The resolved style is always merged with the provided `baseStyle`.
class TextfStyleResolver {
  /// Creates a style resolver from the given context.
  ///
  /// Extracts [ThemeData] and the [TextfOptions] hierarchy immediately.
  /// This ensures that no [BuildContext] is retained in the instance,
  /// preventing memory leaks when the resolver is cached by controllers
  /// that outlive the widget tree.
  factory TextfStyleResolver(BuildContext context) {
    return TextfStyleResolver.withState(
      theme: Theme.of(context),
      optionsHierarchy: resolver.getAncestorOptions(context),
    );
  }

  /// Creates a style resolver directly from dependencies.
  ///
  /// Use this constructor if you have already extracted the theme and
  /// options hierarchy from the context.
  TextfStyleResolver.withState({
    required ThemeData theme,
    required List<TextfOptions> optionsHierarchy,
  })  : _theme = theme,
        _optionsHierarchy = optionsHierarchy;

  final ThemeData _theme;
  final List<TextfOptions> _optionsHierarchy;

  /// Resolves the final TextStyle for a given format marker type and base style.
  ///
  /// Use this for standard formatting types like bold, italic, code, strikethrough,
  /// underline, highlight.
  /// For links, use `resolveLinkStyle` and `resolveLinkHoverStyle`.
  ///
  /// - [type]: The type of formatting marker (e.g., `FormatMarkerType.bold`).
  /// - [baseStyle]: The style of the text segment *before* applying this format.
  ///
  /// Returns the final `TextStyle` to be applied.
  TextStyle resolveStyle(FormatMarkerType type, TextStyle baseStyle) {
    // Handle script font size adjustment first
    TextStyle effectiveBaseStyle = baseStyle;

    if (type == FormatMarkerType.superscript || type == FormatMarkerType.subscript) {
      // Resolve the scale factor (Option -> Default)
      final double scaleFactor =
          _getFirstValue((o) => o.scriptFontSizeFactor) ?? DefaultStyles.scriptFontSizeFactor;

      // Apply scaling to the base style FIRST
      // This ensures that if the user only overrides color later, the size is already correct.
      final double currentSize = baseStyle.fontSize ?? DefaultStyles.defaultFontSize;
      effectiveBaseStyle = baseStyle.copyWith(fontSize: currentSize * scaleFactor);
    }

    // Get the effective style from the TextfOptions hierarchy first.
    final TextStyle? optionsStyle = _getEffectiveStyleFromOptions(type, effectiveBaseStyle);

    if (optionsStyle != null) {
      // Precedence 1 & 2: Use the style derived from TextfOptions
      // The _getEffectiveStyleFromOptions method already merges with the base style correctly.
      return optionsStyle;
    } else {
      // Precedence 3 & 4: No TextfOptions override found, use Theme or Default fallback
      switch (type) {
        case FormatMarkerType.bold:
          return DefaultStyles.boldStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.italic:
          return DefaultStyles.italicStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.boldItalic:
          return DefaultStyles.boldItalicStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.strikethrough:
          // No full style override from options, use default effect.
          // Check if a specific thickness is provided via options.
          final double? thicknessOption = _getFirstValue((o) => o.strikethroughThickness);

          // Use the option thickness if provided, otherwise use the default thickness.
          final double finalThickness =
              thicknessOption ?? DefaultStyles.defaultStrikethroughThickness;

          // Apply the default strikethrough effect with the resolved thickness.
          return DefaultStyles.strikethroughStyle(
            effectiveBaseStyle,
            thickness: finalThickness,
          );
        case FormatMarkerType.code:
          return _getThemeBasedCodeStyle(effectiveBaseStyle); // Theme-based default
        case FormatMarkerType.underline:
          return DefaultStyles.underlineStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.highlight:
          return _getThemeBasedHighlightStyle(effectiveBaseStyle); // Theme-based default
        case FormatMarkerType.superscript:
          return effectiveBaseStyle;
        case FormatMarkerType.subscript:
          return effectiveBaseStyle;
      }
    }
  }

  /// Resolves the final NORMAL TextStyle for a link.
  ///
  /// Checks TextfOptions hierarchy first, then falls back to a theme-based style.
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting
  ///                (might already include bold, italic etc. if the link is nested).
  ///
  /// Returns the final normal `TextStyle` for the link.
  TextStyle resolveLinkStyle(TextStyle baseStyle) {
    final TextStyle? optionsStyle = _getMergedStyle((o) => o.linkStyle);
    final TextStyle? mergedOption =
        optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);

    return mergedOption ?? _getThemeBasedLinkStyle(baseStyle);
  }

  /// Resolves the final HOVER TextStyle for a link.
  ///
  /// Checks TextfOptions hierarchy first, then falls back to a theme-based style
  /// (which, by default, might be the same as the normal style unless overridden).
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting.
  ///
  /// Returns the final hover `TextStyle` for the link.
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) {
    // 1. Resolve the normal link style first
    final TextStyle normalLinkStyle = resolveLinkStyle(baseStyle);

    // 2. Try to get a hover-specific style from options, merging it onto the normalLinkStyle
    final TextStyle? optionsStyle = _getMergedStyle((o) => o.linkHoverStyle);

    if (optionsStyle == null) return normalLinkStyle;
    return mergeTextStyles(normalLinkStyle, optionsStyle);
  }

  /// Resolves the effective MouseCursor for a link.
  ///
  /// Checks TextfOptions hierarchy first, then falls back to `DefaultStyles.linkMouseCursor`.
  MouseCursor resolveLinkMouseCursor() {
    return _getFirstValue((o) => o.linkMouseCursor) ?? DefaultStyles.linkMouseCursor;
  }

  /// Resolves the effective onLinkTap callback for a link.
  ///
  /// Checks TextfOptions hierarchy for the callback. Returns null if none found.
  void Function(String url, String displayText)? resolveOnLinkTap() {
    return _getFirstValue((o) => o.onLinkTap);
  }

  /// Resolves the effective onLinkHover callback for a link.
  ///
  /// Checks TextfOptions hierarchy for the callback. Returns null if none found.
  void Function(String url, String displayText, {required bool isHovering})? resolveOnLinkHover() {
    return _getFirstValue((o) => o.onLinkHover);
  }

  /// Resolves the effective placeholder alignment for a link widget.
  ///
  /// Checks TextfOptions hierarchy. Defaults to[PlaceholderAlignment.baseline] if not found.
  PlaceholderAlignment resolveLinkAlignment() {
    return _getFirstValue((o) => o.linkAlignment) ?? PlaceholderAlignment.baseline;
  }

  /// Calculates the vertical padding required to achieve the script's visual
  /// displacement, respecting any overrides in the [TextfOptions] hierarchy.
  ///
  /// Superscript uses bottom padding (pushes text up when aligned to middle).
  /// Subscript uses top padding (pushes text down).
  ///
  /// The padding magnitude is `fontSize × offsetFactor × 2`, where the `× 2`
  /// comes from[TextfLimits.scriptAlignmentPaddingFactor] (because
  /// [PlaceholderAlignment.middle] centers the widget, so shifting the visual
  /// center by `offset` requires `2 × offset` padding).
  EdgeInsetsGeometry resolveScriptPadding({
    required TextStyle style,
    required bool isSuperscript,
  }) {
    final double fontSize = style.fontSize ?? DefaultStyles.defaultFontSize;

    final double? optionFactor = isSuperscript
        ? _getFirstValue((o) => o.superscriptBaselineFactor)
        : _getFirstValue((o) => o.subscriptBaselineFactor);

    final double offsetFactor = optionFactor ??
        (isSuperscript
            ? DefaultStyles.superscriptBaselineFactor
            : DefaultStyles.subscriptBaselineFactor);

    final double offsetY = fontSize * offsetFactor;

    return isSuperscript
        ? EdgeInsets.only(bottom: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor)
        : EdgeInsets.only(top: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor);
  }

  /// Creates an[InlineSpan] representing a single script fragment.
  ///
  /// The returned span uses [WidgetSpan] with[PlaceholderAlignment.middle]
  /// and directional [Padding] (resolved via [resolveScriptPadding]) to
  /// vertically displace the text. The child [Text.rich] uses
  /// [TextScaler.noScaling] to prevent double-scaling.
  InlineSpan createScriptSpan({
    required String text,
    required TextStyle style,
    required bool isSuperscript,
  }) {
    final EdgeInsetsGeometry padding = resolveScriptPadding(
      style: style,
      isSuperscript: isSuperscript,
    );

    return WidgetSpan(
      // Aligning to middle keeps the widget anchored to the line center,
      // ensuring SelectionArea sorts it correctly (e.g. "E = mc2")
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: padding,
        child: Text.rich(
          TextSpan(text: text, style: style),
          // Disable scaling here to prevent double-scaling.
          // The parent RichText already applies the scaler
          // to WidgetSpan dimensions.
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }

  // --- Private Helper Methods ---

  /// Internal helper to retrieve and merge a specific style from the pre-computed hierarchy.
  /// Reverses the ancestor list (to start from the top-most parent) and iteratively merges styles downwards.
  TextStyle? _getMergedStyle(TextStyle? Function(TextfOptions) getter) {
    if (_optionsHierarchy.isEmpty) return null;

    TextStyle? finalStyle;
    // Iterate from root-most ancestor to nearest
    for (final options in _optionsHierarchy.reversed) {
      final TextStyle? localStyle = getter(options);
      if (localStyle != null) {
        finalStyle = finalStyle == null ? localStyle : mergeTextStyles(finalStyle, localStyle);
      }
    }
    return finalStyle;
  }

  /// Internal helper to find the first non-null property from the pre-computed hierarchy.
  /// Uses a "nearest wins" strategy, iterating from nearest ancestor to furthest.
  T? _getFirstValue<T>(T? Function(TextfOptions) getter) {
    for (final options in _optionsHierarchy) {
      final T? value = getter(options);
      if (value != null) return value;
    }
    return null;
  }

  /// Internal helper to retrieve the effective style from the TextfOptions hierarchy.
  /// Returns null if no option is defined for the given type.
  TextStyle? _getEffectiveStyleFromOptions(FormatMarkerType type, TextStyle baseStyle) {
    if (_optionsHierarchy.isEmpty) return null;

    TextStyle? optionsStyle;
    switch (type) {
      case FormatMarkerType.bold:
        optionsStyle = _getMergedStyle((o) => o.boldStyle);
      case FormatMarkerType.italic:
        optionsStyle = _getMergedStyle((o) => o.italicStyle);
      case FormatMarkerType.boldItalic:
        optionsStyle = _getMergedStyle((o) => o.boldItalicStyle);
      case FormatMarkerType.strikethrough:
        optionsStyle = _getMergedStyle((o) => o.strikethroughStyle);
      case FormatMarkerType.code:
        optionsStyle = _getMergedStyle((o) => o.codeStyle);
      case FormatMarkerType.underline:
        optionsStyle = _getMergedStyle((o) => o.underlineStyle);
      case FormatMarkerType.highlight:
        optionsStyle = _getMergedStyle((o) => o.highlightStyle);
      case FormatMarkerType.superscript:
        optionsStyle = _getMergedStyle((o) => o.superscriptStyle);
      case FormatMarkerType.subscript:
        optionsStyle = _getMergedStyle((o) => o.subscriptStyle);
    }

    return optionsStyle == null ? null : mergeTextStyles(baseStyle, optionsStyle);
  }

  /// Internal helper to create the default code style based on the current theme.
  TextStyle _getThemeBasedCodeStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;

    final Color codeBackgroundColor = colorScheme.surfaceContainer; // Example theme color
    final Color codeForegroundColor = colorScheme.onSurfaceVariant; // Example theme color

    // Use monospace font family
    const String codeFontFamily = 'monospace';
    // Use the constant list directly from DefaultStyles
    const List<String> codeFontFamilyFallback = DefaultStyles.defaultCodeFontFamilyFallback;

    // Merge theme defaults with the base style
    return baseStyle.copyWith(
      fontFamily: codeFontFamily,
      fontFamilyFallback: codeFontFamilyFallback,
      backgroundColor: codeBackgroundColor,
      color: codeForegroundColor,
      letterSpacing: baseStyle.letterSpacing ?? 0,
    );
  }

  /// Internal helper to create the default link style based on the current theme.
  TextStyle _getThemeBasedLinkStyle(TextStyle baseStyle) {
    final Color themeLinkColor = _theme.colorScheme.primary; // Use primary color

    // Merge theme link appearance (color, decoration) ON TOP of the base style.
    return baseStyle.merge(
      TextStyle(
        color: themeLinkColor,
        decoration: TextDecoration.underline, // Default underline for links
        decorationColor: themeLinkColor,
      ),
    );
  }

  /// Internal helper to create the default highlight style based on the current theme.
  TextStyle _getThemeBasedHighlightStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;

    // A common "highlighter yellow":
    final Color highlightBgColor = colorScheme.brightness == Brightness.light
        ? Colors.yellow.withValues(alpha: DefaultStyles.highlightAlphaLight)
        : Colors.yellow.shade700.withValues(alpha: DefaultStyles.highlightAlphaDark);
    final Color highlightTextColor = baseStyle.color ??
        (colorScheme.brightness == Brightness.light ? Colors.black87 : Colors.white);

    return baseStyle.copyWith(
      backgroundColor: highlightBgColor,
      color: highlightTextColor,
    );
  }
}
