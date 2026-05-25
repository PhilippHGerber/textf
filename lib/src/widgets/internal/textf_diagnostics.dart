import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Type alias for the diagnostics builder used by addTextfDebugProperties.
typedef TextfDiagnosticPropertiesBuilder = DiagnosticPropertiesBuilder;

/// Adds the debug diagnostics entries for a Textf widget instance.
///
/// Callers pass through the same values stored on Textf so diagnostics output
/// stays centralised and consistent while keeping widget files smaller.
void addTextfDebugProperties({
  required TextfDiagnosticPropertiesBuilder properties,
  required String data,
  required TextStyle? style,
  required TextAlign? textAlign,
  required TextDirection? textDirection,
  required int? maxLines,
  required TextOverflow? overflow,
  required bool? softWrap,
  required TextScaler? textScaler,
  required String? semanticsLabel,
  required Locale? locale,
  required StrutStyle? strutStyle,
  required TextWidthBasis? textWidthBasis,
  required ui.TextHeightBehavior? textHeightBehavior,
  required Color? selectionColor,
  required Map<String, InlineSpan>? placeholders,
}) {
  properties
    ..add(StringProperty('data', data))
    ..add(DiagnosticsProperty<TextStyle?>('style', style, defaultValue: null))
    ..add(EnumProperty<TextAlign?>('textAlign', textAlign, defaultValue: null))
    ..add(
      EnumProperty<TextDirection?>(
        'textDirection',
        textDirection,
        defaultValue: null,
      ),
    )
    ..add(IntProperty('maxLines', maxLines, defaultValue: null))
    ..add(EnumProperty<TextOverflow?>('overflow', overflow, defaultValue: null))
    ..add(
      FlagProperty(
        'softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
      ),
    )
    ..add(
      DiagnosticsProperty<TextScaler?>(
        'textScaler',
        textScaler,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<String?>(
        'semanticsLabel',
        semanticsLabel,
        defaultValue: null,
      ),
    )
    ..add(DiagnosticsProperty<Locale?>('locale', locale, defaultValue: null))
    ..add(
      DiagnosticsProperty<StrutStyle?>(
        'strutStyle',
        strutStyle,
        defaultValue: null,
      ),
    )
    ..add(
      EnumProperty<TextWidthBasis?>(
        'textWidthBasis',
        textWidthBasis,
        defaultValue: null,
      ),
    )
    ..add(
      DiagnosticsProperty<ui.TextHeightBehavior?>(
        'textHeightBehavior',
        textHeightBehavior,
        defaultValue: null,
      ),
    )
    ..add(ColorProperty('selectionColor', selectionColor, defaultValue: null))
    ..add(
      ObjectFlagProperty<Map<String, InlineSpan>?>.has(
        'placeholders',
        placeholders,
      ),
    );
}
