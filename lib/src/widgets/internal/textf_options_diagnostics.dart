import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Type alias for the diagnostics builder used by addTextfOptionsDebugProperties.
typedef TextfOptionsDiagnosticPropertiesBuilder = DiagnosticPropertiesBuilder;

/// Adds debug diagnostics entries for TextfOptions configuration inputs.
///
/// The `child` field is intentionally omitted to keep diagnostics focused on
/// options configured by the developer.
void addTextfOptionsDebugProperties({
  required TextfOptionsDiagnosticPropertiesBuilder properties,
  required void Function(String url, String displayText)? onLinkTap,
  required void Function(String url, String displayText, {required bool isHovering})? onLinkHover,
  required MouseCursor? linkMouseCursor,
  required PlaceholderAlignment? linkAlignment,
  required TextStyle? boldStyle,
  required TextStyle? italicStyle,
  required TextStyle? boldItalicStyle,
  required TextStyle? strikethroughStyle,
  required TextStyle? codeStyle,
  required TextStyle? underlineStyle,
  required TextStyle? highlightStyle,
  required TextStyle? superscriptStyle,
  required TextStyle? subscriptStyle,
  required TextStyle? linkStyle,
  required TextStyle? linkHoverStyle,
  required double? scriptFontSizeFactor,
  required double? superscriptBaselineFactor,
  required double? subscriptBaselineFactor,
  required double? strikethroughThickness,
}) {
  properties
    ..add(
      ObjectFlagProperty<void Function(String, String)?>.has(
        'onLinkTap',
        onLinkTap,
      ),
    )
    ..add(
      ObjectFlagProperty<void Function(String, String, {required bool isHovering})?>.has(
        'onLinkHover',
        onLinkHover,
      ),
    )
    ..add(
      DiagnosticsProperty<MouseCursor?>(
        'linkMouseCursor',
        linkMouseCursor,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<PlaceholderAlignment?>(
        'linkAlignment',
        linkAlignment,
        defaultValue: null,
      ),
    )
    ..add(DiagnosticsProperty<TextStyle?>('boldStyle', boldStyle, defaultValue: null))
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'italicStyle',
        italicStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'boldItalicStyle',
        boldItalicStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'strikethroughStyle',
        strikethroughStyle,
        defaultValue: null,
      ),
    )
    ..add(DiagnosticsProperty<TextStyle?>('codeStyle', codeStyle, defaultValue: null))
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'underlineStyle',
        underlineStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'highlightStyle',
        highlightStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'superscriptStyle',
        superscriptStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'subscriptStyle',
        subscriptStyle,
        defaultValue: null,
      ),
    )
    ..add(DiagnosticsProperty<TextStyle?>('linkStyle', linkStyle, defaultValue: null))
    ..add(
      DiagnosticsProperty<TextStyle?>(
        'linkHoverStyle',
        linkHoverStyle,
        defaultValue: null,
      ),
    )
    ..add(
      DoubleProperty(
        'scriptFontSizeFactor',
        scriptFontSizeFactor,
        defaultValue: null,
      ),
    )
    ..add(
      DoubleProperty(
        'superscriptBaselineFactor',
        superscriptBaselineFactor,
        defaultValue: null,
      ),
    )
    ..add(
      DoubleProperty(
        'subscriptBaselineFactor',
        subscriptBaselineFactor,
        defaultValue: null,
      ),
    )
    ..add(
      DoubleProperty(
        'strikethroughThickness',
        strikethroughThickness,
        defaultValue: null,
      ),
    );
}
