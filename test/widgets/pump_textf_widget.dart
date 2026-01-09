import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

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
  SelectionRegistrar? selectionRegistrar,
  bool wrapInSelectionArea = false,
  Color? selectionColor,
  TextfOptions? textfOptions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
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

            // Wrap with SelectionArea if requested
            if (wrapInSelectionArea) {
              finalWidget = SelectionArea(
                child: finalWidget,
              );
            }

            // Center the final result
            return Center(child: finalWidget);
          },
        ),
      ),
    ),
  );
}
