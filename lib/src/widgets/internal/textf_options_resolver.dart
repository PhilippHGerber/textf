import 'package:flutter/material.dart';

import '../../core/textf_style_utils.dart';
import '../textf_options.dart';

/// Gathers all [TextfOptions] widgets from the given context upwards.
///
/// The returned list is ordered from the nearest ancestor to the furthest.
List<TextfOptions> getAncestorOptions(BuildContext context) {
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
/// Reverses the ancestor list (to start from the top-most parent) and
/// iteratively merges styles downwards.
TextStyle? getMergedStyleFromHierarchy(
  BuildContext context,
  TextStyle? Function(TextfOptions) getter,
) {
  final List<TextfOptions> hierarchy = getAncestorOptions(context);
  if (hierarchy.isEmpty) {
    return null;
  }

  // Reverse the list to start from the top-most ancestor and merge down.
  final Iterable<TextfOptions> reversedHierarchy = hierarchy.reversed;
  TextStyle? finalStyle;

  for (final options in reversedHierarchy) {
    final TextStyle? localStyle = getter(options);
    if (localStyle != null) {
      finalStyle = finalStyle == null ? localStyle : mergeTextStyles(finalStyle, localStyle);
    }
  }
  return finalStyle;
}

/// Finds the first non-null value for a given property by searching up
/// the widget tree (from nearest to furthest).
///
/// Used for non-mergeable properties like callbacks and enums where
/// a "nearest wins" strategy is appropriate.
T? findFirstAncestorValue<T>(
  BuildContext context,
  T? Function(TextfOptions) getter,
) {
  final List<TextfOptions> hierarchy = getAncestorOptions(context);
  for (final options in hierarchy) {
    final T? value = getter(options);
    if (value != null) {
      return value; // Found the nearest value, stop searching.
    }
  }
  return null; // Reached the top with no value found.
}

/// Computes a hash of all resolved TextfOptions values with a single tree walk.
///
/// Performance: O(Depth) tree walk + O(Depth) property iteration.
/// This is much faster than calling getEffective... for each property,
/// which would be O(Properties x Depth).
int computeOptionsResolvedHash(BuildContext context, TextStyle baseStyle) {
  final List<TextfOptions> hierarchy = getAncestorOptions(context);

  if (hierarchy.isEmpty) return 0;

  // === MERGEABLE STYLES ===
  // Accumulated from root -> nearest (hierarchy.reversed)
  TextStyle? boldStyle;
  TextStyle? italicStyle;
  TextStyle? boldItalicStyle;
  TextStyle? strikethroughStyle;
  TextStyle? codeStyle;
  TextStyle? underlineStyle;
  TextStyle? highlightStyle;
  TextStyle? superscriptStyle;
  TextStyle? subscriptStyle;
  TextStyle? linkStyle;
  TextStyle? linkHoverStyle;

  // === NON-MERGEABLE (NEAREST WINS) ===
  // Overwritten from root -> nearest, so final value = nearest
  MouseCursor? linkMouseCursor;
  PlaceholderAlignment? linkAlignment;
  double? strikethroughThickness;
  double? superscriptBaselineFactor;
  double? subscriptBaselineFactor;
  double? scriptFontSizeFactor;
  void Function(String, String)? onLinkTap;
  void Function(String, String, {required bool isHovering})? onLinkHover;

  // Single pass: root -> nearest
  for (final opt in hierarchy.reversed) {
    // Mergeable: accumulate
    final optBold = opt.boldStyle;
    if (optBold != null) {
      boldStyle = boldStyle == null ? optBold : mergeTextStyles(boldStyle, optBold);
    }

    final optItalic = opt.italicStyle;
    if (optItalic != null) {
      italicStyle = italicStyle == null ? optItalic : mergeTextStyles(italicStyle, optItalic);
    }

    final optBoldItalic = opt.boldItalicStyle;
    if (optBoldItalic != null) {
      boldItalicStyle =
          boldItalicStyle == null ? optBoldItalic : mergeTextStyles(boldItalicStyle, optBoldItalic);
    }

    final optStrike = opt.strikethroughStyle;
    if (optStrike != null) {
      strikethroughStyle =
          strikethroughStyle == null ? optStrike : mergeTextStyles(strikethroughStyle, optStrike);
    }

    final optCode = opt.codeStyle;
    if (optCode != null) {
      codeStyle = codeStyle == null ? optCode : mergeTextStyles(codeStyle, optCode);
    }

    final optUnderline = opt.underlineStyle;
    if (optUnderline != null) {
      underlineStyle =
          underlineStyle == null ? optUnderline : mergeTextStyles(underlineStyle, optUnderline);
    }

    final optHighlight = opt.highlightStyle;
    if (optHighlight != null) {
      highlightStyle =
          highlightStyle == null ? optHighlight : mergeTextStyles(highlightStyle, optHighlight);
    }

    final optSuper = opt.superscriptStyle;
    if (optSuper != null) {
      superscriptStyle =
          superscriptStyle == null ? optSuper : mergeTextStyles(superscriptStyle, optSuper);
    }

    final optSub = opt.subscriptStyle;
    if (optSub != null) {
      subscriptStyle = subscriptStyle == null ? optSub : mergeTextStyles(subscriptStyle, optSub);
    }

    final optLink = opt.linkStyle;
    if (optLink != null) {
      linkStyle = linkStyle == null ? optLink : mergeTextStyles(linkStyle, optLink);
    }

    final optLinkHover = opt.linkHoverStyle;
    if (optLinkHover != null) {
      linkHoverStyle =
          linkHoverStyle == null ? optLinkHover : mergeTextStyles(linkHoverStyle, optLinkHover);
    }

    // Non-mergeable: overwrite (last value = nearest)
    if (opt.linkMouseCursor != null) linkMouseCursor = opt.linkMouseCursor;
    if (opt.linkAlignment != null) linkAlignment = opt.linkAlignment;
    if (opt.strikethroughThickness != null) strikethroughThickness = opt.strikethroughThickness;
    if (opt.superscriptBaselineFactor != null) {
      superscriptBaselineFactor = opt.superscriptBaselineFactor;
    }
    if (opt.subscriptBaselineFactor != null) {
      subscriptBaselineFactor = opt.subscriptBaselineFactor;
    }
    if (opt.scriptFontSizeFactor != null) scriptFontSizeFactor = opt.scriptFontSizeFactor;
    if (opt.onLinkTap != null) onLinkTap = opt.onLinkTap;
    if (opt.onLinkHover != null) onLinkHover = opt.onLinkHover;
  }

  // Merge accumulated styles onto baseStyle for final comparison
  final effectiveBold = boldStyle != null ? mergeTextStyles(baseStyle, boldStyle) : null;
  final effectiveItalic = italicStyle != null ? mergeTextStyles(baseStyle, italicStyle) : null;
  final effectiveBoldItalic =
      boldItalicStyle != null ? mergeTextStyles(baseStyle, boldItalicStyle) : null;
  final effectiveStrike =
      strikethroughStyle != null ? mergeTextStyles(baseStyle, strikethroughStyle) : null;
  final effectiveCode = codeStyle != null ? mergeTextStyles(baseStyle, codeStyle) : null;
  final effectiveUnderline =
      underlineStyle != null ? mergeTextStyles(baseStyle, underlineStyle) : null;
  final effectiveHighlight =
      highlightStyle != null ? mergeTextStyles(baseStyle, highlightStyle) : null;
  final effectiveSuperscript =
      superscriptStyle != null ? mergeTextStyles(baseStyle, superscriptStyle) : null;
  final effectiveSubscript =
      subscriptStyle != null ? mergeTextStyles(baseStyle, subscriptStyle) : null;
  final effectiveLink = linkStyle != null ? mergeTextStyles(baseStyle, linkStyle) : null;
  final effectiveLinkHover =
      linkHoverStyle != null ? mergeTextStyles(baseStyle, linkHoverStyle) : null;

  return Object.hash(
    effectiveBold,
    effectiveItalic,
    effectiveBoldItalic,
    effectiveStrike,
    effectiveCode,
    effectiveUnderline,
    effectiveHighlight,
    effectiveSuperscript,
    effectiveSubscript,
    effectiveLink,
    effectiveLinkHover,
    linkMouseCursor,
    linkAlignment,
    strikethroughThickness,
    superscriptBaselineFactor,
    subscriptBaselineFactor,
    scriptFontSizeFactor,
    onLinkTap,
    onLinkHover,
  );
}
