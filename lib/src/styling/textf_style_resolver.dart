import 'package:flutter/widgets.dart';

import '../core/default_styles.dart';
import '../core/textf_limits.dart';
import '../core/textf_style_utils.dart';
import '../models/textf_token.dart';
import '../widgets/textf_options.dart';
import '../widgets/textf_options_data.dart';
import 'link_style_configuration.dart';
import 'textf_palette.dart';
import 'thematic_break.dart';

/// A class responsible for resolving the final TextStyle for formatted text segments.
///
/// It is design-system-neutral: its only state is the pre-merged
/// [TextfOptionsData], and the colors of the built-in defaults come from the
/// [TextfPalette] passed in per call. Styles resolve in four tiers:
/// 1. An explicit style option (`codeStyle`, `linkStyle`, …) from the
///    `TextfOptionsData`. It replaces the built-in default and is merged onto
///    the base style.
/// 2. An explicit color option (`linkColor`, `codeBackgroundColor`,
///    `highlightColor`, `thematicBreakColor`). It tints the built-in default and
///    leaves its typography and decoration intact.
/// 3. Neutral defaults derived from the [TextfPalette] (code background,
///    highlight tint, thematic-break rule) or fixed in `DefaultStyles` (link
///    blue).
/// 4. Relative defaults from `DefaultStyles` (bold, italic, strikethrough,
///    underline, script and heading sizes).
///
/// The resolved style is always merged with the provided `baseStyle`.
class TextfStyleResolver {
  /// Creates a style resolver from the [TextfOptionsData] in scope at [context].
  ///
  /// Only the pre-merged options are read; no [BuildContext] is retained in
  /// the instance, preventing memory leaks when the resolver is cached by
  /// controllers that outlive the widget tree.
  factory(BuildContext context) {
    return TextfStyleResolver.withState(options: TextfOptions.maybeOf(context));
  }

  /// Creates a style resolver directly from already-extracted options.
  new withState({required this._options});

  final TextfOptionsData? _options;

  /// Resolves the final TextStyle for a given format marker type and base style.
  ///
  /// Use this for standard formatting types like bold, italic, code, strikethrough,
  /// underline, highlight.
  /// For links, use [resolveLinkConfiguration].
  ///
  /// - [type]: The type of formatting marker (e.g., `FormatMarkerType.bold`).
  /// - [baseStyle]: The style of the text segment *before* applying this format.
  /// - [palette]: The render pass's palette, derived from the *effective root
  ///   style* (not from [baseStyle]); it colors the code and highlight defaults.
  ///
  /// Returns the final `TextStyle` to be applied.
  TextStyle resolveStyle(FormatMarkerType type, TextStyle baseStyle, TextfPalette palette) {
    // Handle script font size adjustment first
    TextStyle effectiveBaseStyle = baseStyle;

    if (type == FormatMarkerType.superscript || type == FormatMarkerType.subscript) {
      // Resolve the scale factor (Option -> Default)
      final double scaleFactor =
          _options?.scriptFontSizeFactor ?? DefaultStyles.scriptFontSizeFactor;

      // Apply scaling to the base style FIRST
      // This ensures that if the user only overrides color later, the size is already correct.
      final double currentSize = baseStyle.fontSize ?? DefaultStyles.defaultFontSize;
      effectiveBaseStyle = baseStyle.copyWith(fontSize: currentSize * scaleFactor);
    }

    // Get the effective style from the pre-merged TextfOptionsData first.
    final TextStyle? optionsStyle = _getStyleFromOptions(type);

    if (optionsStyle != null) {
      // Precedence 1: Use the style derived from TextfOptions
      return mergeTextStyles(effectiveBaseStyle, optionsStyle);
    } else {
      // Precedence 2–4: no style option; color option, neutral or relative default
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
          final double finalThickness =
              _options?.strikethroughThickness ?? DefaultStyles.defaultStrikethroughThickness;

          // Apply the default strikethrough effect with the resolved thickness.
          return DefaultStyles.strikethroughStyle(
            effectiveBaseStyle,
            thickness: finalThickness,
          );
        case FormatMarkerType.code:
          return _defaultCodeStyle(effectiveBaseStyle, palette); // Color option or neutral
        case FormatMarkerType.underline:
          return DefaultStyles.underlineStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.highlight:
          return _defaultHighlightStyle(effectiveBaseStyle, palette); // Color option or neutral
        case FormatMarkerType.superscript:
          return effectiveBaseStyle;
        case FormatMarkerType.subscript:
          return effectiveBaseStyle;
      }
    }
  }

  /// Resolves all link-related styling, interaction callbacks, and geometry into
  /// a [LinkStyleConfiguration].
  ///
  /// Combines normal and hover [TextStyle]s, [MouseCursor], tap and hover
  /// callbacks, and [PlaceholderAlignment].
  ///
  /// - [inheritedStyle]: The style of the link text before applying link formatting.
  LinkStyleConfiguration resolveLinkConfiguration(TextStyle inheritedStyle) {
    final TextStyle baseLinkStyle = _resolveLinkStyle(inheritedStyle);
    final TextStyle hoverLinkStyle = _resolveLinkHoverStyle(baseLinkStyle);
    final MouseCursor cursor = _options?.linkMouseCursor ?? DefaultStyles.linkMouseCursor;
    final PlaceholderAlignment alignment = _options?.linkAlignment ?? PlaceholderAlignment.baseline;

    return LinkStyleConfiguration(
      style: baseLinkStyle,
      hoverStyle: hoverLinkStyle,
      cursor: cursor,
      onTap: _options?.onLinkTap,
      onHover: _options?.onLinkHover,
      alignment: alignment,
    );
  }

  TextStyle _resolveLinkStyle(TextStyle baseStyle) {
    final TextStyle? optionsStyle = _options?.linkStyle;

    if (optionsStyle != null) {
      return mergeTextStyles(baseStyle, optionsStyle);
    }
    return _defaultLinkStyle(baseStyle);
  }

  TextStyle _resolveLinkHoverStyle(TextStyle normalLinkStyle) {
    final TextStyle? optionsStyle = _options?.linkHoverStyle;

    if (optionsStyle == null) return normalLinkStyle;
    return mergeTextStyles(normalLinkStyle, optionsStyle);
  }

  /// Calculates the vertical padding required to achieve the script's visual
  /// displacement, respecting any overrides in the [TextfOptions].
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
        ? _options?.superscriptBaselineFactor
        : _options?.subscriptBaselineFactor;

    final double offsetFactor =
        optionFactor ??
        (isSuperscript
            ? DefaultStyles.superscriptBaselineFactor
            : DefaultStyles.subscriptBaselineFactor);

    final double offsetY = fontSize * offsetFactor;

    return isSuperscript
        ? EdgeInsets.only(bottom: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor)
        : EdgeInsets.only(top: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor);
  }

  /// Creates an [InlineSpan] representing a single script fragment.
  ///
  /// The returned span uses [WidgetSpan] with [PlaceholderAlignment.middle]
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

  /// Resolves the final TextStyle for an ATX heading of [level] (1–6).
  ///
  /// The default heading style ([DefaultStyles.headingStyle]) — the scaled size,
  /// bold weight and line height for [level] — is computed first. A matching
  /// `h{n}Style` override from the [TextfOptionsData] hierarchy is then merged
  /// on top of it, so a delta-only override (e.g. color alone) still inherits
  /// the default size and weight. The whole result sits on [baseStyle].
  TextStyle resolveHeadingStyle(int level, TextStyle baseStyle) {
    final TextStyle headingBase = DefaultStyles.headingStyle(level, baseStyle);
    final TextStyle? optionsStyle = _headingStyleFromOptions(level);
    if (optionsStyle != null) {
      return mergeTextStyles(headingBase, optionsStyle);
    }
    return headingBase;
  }

  /// Internal helper returning the per-level `h{n}Style` override, or null.
  ///
  /// Uses a `switch` (no per-call list allocation) and inherits through the
  /// [TextfOptions] hierarchy via the pre-merged [_options].
  TextStyle? _headingStyleFromOptions(int level) {
    final opts = _options;
    if (opts == null) return null;
    switch (level) {
      case 1:
        return opts.h1Style;
      case 2:
        return opts.h2Style;
      case 3:
        return opts.h3Style;
      case 4:
        return opts.h4Style;
      case 5:
        return opts.h5Style;
      case 6:
        return opts.h6Style;
      default:
        return null;
    }
  }

  /// Resolves the [InlineSpan] rendered for a thematic break (`---`/`***`/`___`).
  ///
  /// A `thematicBreakBuilder` supplied anywhere in the [TextfOptions] hierarchy
  /// (nearest ancestor wins, via the pre-merged [_options]) overrides the
  /// default; its widget is placed in a middle-aligned [WidgetSpan]. Absent a
  /// builder, the guarded full-width 1px default rule renders, colored by the
  /// `thematicBreakColor` option or, failing that, by the [palette]'s
  /// foreground at [DefaultStyles.thematicBreakAlpha].
  InlineSpan resolveThematicBreak(TextfPalette palette) {
    final Widget Function(BuildContext context)? builder = _options?.thematicBreakBuilder;
    if (builder != null) {
      return customThematicBreakSpan(builder);
    }
    return defaultThematicBreakSpan(
      _options?.thematicBreakColor ?? DefaultStyles.thematicBreakColor(palette.foreground),
    );
  }

  // --- Private Helper Methods ---

  /// Internal helper to retrieve the pre-merged style from the TextfOptionsData.
  /// Returns null if no option is defined for the given type.
  TextStyle? _getStyleFromOptions(FormatMarkerType type) {
    switch (type) {
      case FormatMarkerType.bold:
        return _options?.boldStyle;
      case FormatMarkerType.italic:
        return _options?.italicStyle;
      case FormatMarkerType.boldItalic:
        return _options?.boldItalicStyle;
      case FormatMarkerType.strikethrough:
        return _options?.strikethroughStyle;
      case FormatMarkerType.code:
        return _options?.codeStyle;
      case FormatMarkerType.underline:
        return _options?.underlineStyle;
      case FormatMarkerType.highlight:
        return _options?.highlightStyle;
      case FormatMarkerType.superscript:
        return _options?.superscriptStyle;
      case FormatMarkerType.subscript:
        return _options?.subscriptStyle;
    }
  }

  /// The default code style: monospace family and fallbacks on the base style,
  /// on the `codeBackgroundColor` option or the palette-derived tint. The code
  /// text keeps the segment's color.
  TextStyle _defaultCodeStyle(TextStyle baseStyle, TextfPalette palette) {
    return baseStyle.copyWith(
      fontFamily: DefaultStyles.defaultCodeFontFamily,
      fontFamilyFallback: DefaultStyles.defaultCodeFontFamilyFallback,
      backgroundColor:
          _options?.codeBackgroundColor ??
          DefaultStyles.codeBackgroundColor(palette.foreground, palette.surface),
      letterSpacing: baseStyle.letterSpacing ?? 0,
    );
  }

  /// The default link style: underline, with text and underline colored by the
  /// `linkColor` option or the fixed default link blue.
  TextStyle _defaultLinkStyle(TextStyle baseStyle) {
    final Color linkColor = _options?.linkColor ?? DefaultStyles.defaultLinkColor;

    return baseStyle.merge(
      TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
      ),
    );
  }

  /// The default highlight style: the `highlightColor` option or the
  /// palette-derived tint as the background. The text keeps the segment's
  /// color, or takes a surface-appropriate one when the segment has none.
  TextStyle _defaultHighlightStyle(TextStyle baseStyle, TextfPalette palette) {
    return baseStyle.copyWith(
      backgroundColor:
          _options?.highlightColor ?? DefaultStyles.highlightBackgroundColor(palette.surface),
      color: baseStyle.color ?? DefaultStyles.highlightTextColor(palette.surface),
    );
  }
}
