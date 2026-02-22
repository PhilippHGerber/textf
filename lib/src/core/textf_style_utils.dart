import 'package:flutter/painting.dart';

/// Merges two [TextStyle] objects with intelligent [TextDecoration] handling.
///
/// Unlike the standard [TextStyle.merge], this function prevents:
/// 1. Accidental removal of decorations: If the base has `underline | lineThrough`
///    and options adds `underline`, the result remains `underline | lineThrough`
///    (instead of being downgraded to just `underline`).
/// 2. Duplicate decorations: It checks if the decoration is already present
///    before combining.
///
/// - [baseStyle]: The style inherited from the parent/theme.
/// - [optionsStyle]: The style defined in the current options.
TextStyle mergeTextStyles(TextStyle baseStyle, TextStyle optionsStyle) {
  // Use standard merge for properties like color, fontSize, fontWeight, etc.
  // This lets Flutter handle the heavy lifting for most attributes.
  final TextStyle merged = baseStyle.merge(optionsStyle);

  final TextDecoration? baseDeco = baseStyle.decoration;
  final TextDecoration? optionDeco = optionsStyle.decoration;

  // Case 1: Options explicitly set decoration to 'none'.
  // We want to remove all decorations. 'merged' already has this from the standard merge.
  if (optionDeco == TextDecoration.none) {
    return merged;
  }

  // Case 2: Options don't specify any decoration (null).
  // We want to keep the base decoration. 'merged' already inherited baseDeco.
  if (optionDeco == null) {
    return merged;
  }

  // Case 3: Both styles have active decorations. We need custom logic.
  if (baseDeco != null && baseDeco != TextDecoration.none) {
    // Check if the base decoration already "contains" the option's decoration.
    // TextDecoration treats combinations as a bitmask.
    // If true:
    //    The option is adding a decoration that already exists (e.g., adding
    //    'underline' to text that is already 'underline' or 'underline + lineThrough').
    //
    //    Standard merge would overwrite 'baseDeco' with 'optionDeco', potentially
    //    losing other flags (like 'lineThrough').
    //    We must restore 'baseDeco' to preserve those other flags.
    // If false:
    //    The option adds a completely new decoration (e.g., adding 'lineThrough'
    //    to text that is only 'underlined').
    //    Combine them so both appear.
    return baseDeco.contains(optionDeco)
        ? merged.copyWith(decoration: baseDeco)
        : merged.copyWith(
            decoration: TextDecoration.combine([baseDeco, optionDeco]),
          );
  }

  // Case 4: Base has no decoration, but Option does.
  // 'merged' already has 'optionDeco'.
  return merged;
}

/// Applies a link appearance style onto an inner span's style, with intelligent
/// [TextDecoration] merging.
///
/// This preserves existing decorations on the [spanStyle] (e.g., strikethrough
/// from formatted text inside a link) while adding the link's own decoration
/// (e.g., underline).
TextStyle applyLinkStyleToSpan(TextStyle spanStyle, TextStyle linkAppearance) {
  // 1. Determine Decoration (Merge logic)
  TextDecoration? finalDecoration;
  final TextDecoration? linkBaseDecoration = linkAppearance.decoration;
  final TextDecoration? innerExistingDecoration = spanStyle.decoration;

  if (linkBaseDecoration != null && linkBaseDecoration != TextDecoration.none) {
    // ignore: prefer-conditional-expressions
    if (innerExistingDecoration != null && innerExistingDecoration != TextDecoration.none) {
      finalDecoration = !innerExistingDecoration.contains(linkBaseDecoration)
          ? TextDecoration.combine([innerExistingDecoration, linkBaseDecoration])
          : innerExistingDecoration;
    } else {
      finalDecoration = linkBaseDecoration;
    }
  } else {
    finalDecoration = innerExistingDecoration;
  }

  // 2. Determine Decoration Color and Thickness
  final Color? finalDecorationColor =
      linkAppearance.decorationColor ?? spanStyle.decorationColor;
  final double? finalDecorationThickness =
      linkAppearance.decorationThickness ?? spanStyle.decorationThickness;

  // 3. Construct the merged style
  return spanStyle.copyWith(
    color: linkAppearance.color ?? spanStyle.color,
    decoration: finalDecoration,
    decorationColor: finalDecorationColor,
    decorationThickness: finalDecorationThickness,
  );
}
