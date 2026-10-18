import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

/// Wraps [child] in a design-system-neutral test host.
///
/// Uses only the widgets layer — a [WidgetsApp] plus an explicit [Directionality] and an
/// [Overlay] — so that no `MaterialApp`, `Theme` or Material `DefaultTextStyle` is in scope.
/// Widgets under test therefore see exactly what a bare `WidgetsApp` host provides.
///
/// Tests that verify interoperability with a design-system widget (for example Material's
/// `SelectionArea` or `TextField`) can pass the [localizationsDelegates] that widget needs,
/// such as `DefaultMaterialLocalizations.delegate`, instead of reaching for `MaterialApp`.
// ignore: avoid-top-level-members-in-tests
Widget neutralTestApp({
  required Widget child,
  Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates,
}) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    localizationsDelegates: localizationsDelegates,
    builder: (context, _) => Directionality(
      textDirection: TextDirection.ltr,
      // An Overlay, as a Navigator would provide, for widgets that float content (selection
      // handles, tooltips). Overlay.wrap keeps [child] up to date across re-pumps.
      child: Overlay.wrap(child: child),
    ),
  );
}

/// Pumps a [Textf] built from the given arguments inside [neutralTestApp].
///
/// [wrap] is applied last (outermost, just inside the centering widget) and lets a test add
/// its own ancestors — for example a `SelectionArea` — without this harness depending on any
/// design system.
// ignore: avoid-top-level-members-in-tests
Future<void> pumpTextfWidget(
  WidgetTester tester, {
  required String data,
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
  bool? softWrap,
  TextScaler? textScaler,
  TextDirection? textDirection,
  DefaultTextStyle? defaultTextStyle,
  Color? selectionColor,
  TextfOptions? textfOptions,
  Widget Function(Widget child)? wrap,
  Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates,
}) async {
  // Start with the core Textf widget
  Widget finalWidget = Textf(
    data,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    textScaler: textScaler,
    textDirection: textDirection,
    selectionColor: selectionColor,
  );

  // Wrap with TextfOptions *if provided*
  if (textfOptions != null) {
    finalWidget = TextfOptions(
      key: textfOptions.key, // Pass key if needed
      // Use properties from the passed instance
      onLinkTap: textfOptions.onLinkTap,
      onLinkHover: textfOptions.onLinkHover,
      linkStyle: textfOptions.linkStyle,
      linkHoverStyle: textfOptions.linkHoverStyle,
      linkMouseCursor: textfOptions.linkMouseCursor,
      boldStyle: textfOptions.boldStyle,
      italicStyle: textfOptions.italicStyle,
      boldItalicStyle: textfOptions.boldItalicStyle,
      strikethroughStyle: textfOptions.strikethroughStyle,
      codeStyle: textfOptions.codeStyle,
      linkColor: textfOptions.linkColor,
      codeBackgroundColor: textfOptions.codeBackgroundColor,
      highlightColor: textfOptions.highlightColor,
      thematicBreakColor: textfOptions.thematicBreakColor,
      child: finalWidget,
    );
  }

  // Wrap with DefaultTextStyle if provided
  if (defaultTextStyle != null) {
    finalWidget = DefaultTextStyle.merge(
      style: defaultTextStyle.style,
      child: finalWidget,
    );
  }

  // Let the test add its own ancestors (e.g. a SelectionArea)
  if (wrap != null) {
    finalWidget = wrap(finalWidget);
  }

  await tester.pumpWidget(
    neutralTestApp(
      localizationsDelegates: localizationsDelegates,
      // Center the final result
      child: Center(child: finalWidget),
    ),
  );
}

/// Returns the style of the first rendered [TextSpan] whose trimmed text is [text].
///
/// Searches every [RichText] in the tree, so spans nested in links and scripts (which render
/// their own `Text.rich`) are found too. Fails the test when no such span exists.
// ignore: avoid-top-level-members-in-tests
TextStyle renderedSpanStyle(WidgetTester tester, String text) {
  TextStyle? found;
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    richText.text.visitChildren((span) {
      if (span is TextSpan && span.text?.trim() == text) {
        found = span.style;
        return false;
      }
      return true;
    });
    if (found != null) break;
  }
  expect(found, isNotNull, reason: 'No rendered TextSpan with text "$text"');
  return found ?? const TextStyle();
}

/// Finds the default thematic-break rule: a [ColoredBox] with a visible color (host chrome may
/// contribute a separate, fully transparent one).
// ignore: avoid-top-level-members-in-tests
final Finder defaultThematicBreakRule = find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color.a > 0,
);
