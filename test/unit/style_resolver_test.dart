// File: test/unit/styling/textf_style_resolver_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/token.dart';
import 'package:textf/src/styling/style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';

// --- Helper Callbacks & Styles for Testing (Remain the same) ---
void _stubTap1(String u, String d) {}
void _stubTap2(String u, String d) {}
void _stubHover1(String u, String d, bool h) {}

const _baseStyle = TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Roboto');

const _rootBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
const _rootItalicStyle = TextStyle(fontStyle: FontStyle.italic, decoration: TextDecoration.underline);
const _rootUrlStyle = TextStyle(color: Colors.purple, fontSize: 18);
const _rootUrlHoverStyle = TextStyle(backgroundColor: Colors.yellow);
const _rootCursor = SystemMouseCursors.text;
final _rootOnTap = _stubTap1;
final _rootOnHover = _stubHover1;

const _childItalicStyle = TextStyle(fontStyle: FontStyle.normal, backgroundColor: Colors.blue);
const _childCodeStyle = TextStyle(fontFamily: 'Courier', color: Colors.green);
const _childUrlStyle = TextStyle(decoration: TextDecoration.none);
final _childOnTap = _stubTap2;

// --- Helper function to pump a widget tree (Remains the same) ---
Future<BuildContext> pumpWithOptions(
  WidgetTester tester, {
  required ThemeData theme,
  TextfOptions? rootOptions,
  TextfOptions? childOptions,
}) async {
  late BuildContext capturedContext;
  Widget child = Builder(
    builder: (context) {
      capturedContext = context;
      return const SizedBox.shrink();
    },
  );

  if (childOptions != null) {
    child = TextfOptions(
      key: childOptions.key,
      onUrlTap: childOptions.onUrlTap,
      onUrlHover: childOptions.onUrlHover,
      urlStyle: childOptions.urlStyle,
      urlHoverStyle: childOptions.urlHoverStyle,
      urlMouseCursor: childOptions.urlMouseCursor,
      boldStyle: childOptions.boldStyle,
      italicStyle: childOptions.italicStyle,
      boldItalicStyle: childOptions.boldItalicStyle,
      strikethroughStyle: childOptions.strikethroughStyle,
      codeStyle: childOptions.codeStyle,
      child: child,
    );
  }
  if (rootOptions != null) {
    child = TextfOptions(
      key: rootOptions.key,
      onUrlTap: rootOptions.onUrlTap,
      onUrlHover: rootOptions.onUrlHover,
      urlStyle: rootOptions.urlStyle,
      urlHoverStyle: rootOptions.urlHoverStyle,
      urlMouseCursor: rootOptions.urlMouseCursor,
      boldStyle: rootOptions.boldStyle,
      italicStyle: rootOptions.italicStyle,
      boldItalicStyle: rootOptions.boldItalicStyle,
      strikethroughStyle: rootOptions.strikethroughStyle,
      codeStyle: rootOptions.codeStyle,
      child: child,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: DefaultTextStyle(
        style: _baseStyle,
        child: child,
      ),
    ),
  );
  return capturedContext;
}

void main() {
  group('TextfStyleResolver Tests', () {
    // --- Scenario 1: No TextfOptions Ancestor (No change needed here) ---
    group('No TextfOptions Ancestor', () {
      late ThemeData lightTheme;
      late ThemeData darkTheme;

      // Use setUpAll for things that don't depend on tester
      setUpAll(() {
        lightTheme = ThemeData.light();
        darkTheme = ThemeData.dark();
      });

      testWidgets('resolveStyle uses DefaultStyles for relative types (Light Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);

        final boldStyle = resolver.resolveStyle(TokenType.boldMarker, _baseStyle);
        expect(boldStyle.fontWeight, FontWeight.bold);
        expect(boldStyle.color, _baseStyle.color);

        final italicStyle = resolver.resolveStyle(TokenType.italicMarker, _baseStyle);
        expect(italicStyle.fontStyle, FontStyle.italic);

        final strikeStyle = resolver.resolveStyle(TokenType.strikeMarker, _baseStyle);
        expect(strikeStyle.decoration, TextDecoration.lineThrough);
      });

      testWidgets('resolveStyle uses Theme-based defaults for Code (Light Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);
        final codeStyle = resolver.resolveStyle(TokenType.codeMarker, _baseStyle);

        expect(codeStyle.fontFamily, 'monospace');
        expect(codeStyle.color, lightTheme.colorScheme.onSurfaceVariant);
        expect(codeStyle.backgroundColor, lightTheme.colorScheme.surfaceContainer);
        expect(codeStyle.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveStyle uses Theme-based defaults for Code (Dark Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: darkTheme);
        final resolver = TextfStyleResolver(context);
        final codeStyle = resolver.resolveStyle(TokenType.codeMarker, _baseStyle);

        expect(codeStyle.fontFamily, 'monospace');
        expect(codeStyle.color, darkTheme.colorScheme.onSurfaceVariant);
        expect(codeStyle.backgroundColor, darkTheme.colorScheme.surfaceContainer);
        expect(codeStyle.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveLinkStyle uses Theme-based defaults (Light Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);
        final linkStyle = resolver.resolveLinkStyle(_baseStyle);

        expect(linkStyle.color, lightTheme.colorScheme.primary);
        expect(linkStyle.decoration, TextDecoration.underline);
        expect(linkStyle.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveLinkStyle uses Theme-based defaults (Dark Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: darkTheme);
        final resolver = TextfStyleResolver(context);
        final linkStyle = resolver.resolveLinkStyle(_baseStyle);

        expect(linkStyle.color, darkTheme.colorScheme.primary);
        expect(linkStyle.decoration, TextDecoration.underline);
        expect(linkStyle.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveLinkHoverStyle defaults to normal style without options (Light Theme)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);
        final linkStyle = resolver.resolveLinkStyle(_baseStyle);
        final hoverStyle = resolver.resolveLinkHoverStyle(_baseStyle);

        expect(hoverStyle, linkStyle);
      });

      testWidgets('resolveLinkMouseCursor uses DefaultStyles', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);
        expect(resolver.resolveLinkMouseCursor(), DefaultStyles.urlMouseCursor);
      });

      testWidgets('resolveOnUrlTap/Hover return null', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: lightTheme);
        final resolver = TextfStyleResolver(context);
        expect(resolver.resolveOnUrlTap(), isNull);
        expect(resolver.resolveOnUrlHover(), isNull);
      });
    });

    // --- Scenario 2: Single TextfOptions Ancestor ---
    group('Single TextfOptions Ancestor', () {
      // Define options commonly used in this group
      final rootOptions = TextfOptions(
        boldStyle: _rootBoldStyle,
        urlStyle: _rootUrlStyle,
        urlHoverStyle: _rootUrlHoverStyle,
        urlMouseCursor: _rootCursor,
        onUrlTap: _rootOnTap,
        onUrlHover: _rootOnHover,
        child: Container(),
      );

      testWidgets('resolveStyle uses specified option style (Bold)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.boldMarker, _baseStyle);
        expect(style.fontWeight, _rootBoldStyle.fontWeight);
        expect(style.color, _rootBoldStyle.color);
        expect(style.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveStyle falls back for unspecified option style (Italic)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.italicMarker, _baseStyle);
        expect(style.fontStyle, DefaultStyles.italicStyle(_baseStyle).fontStyle);
        expect(style.color, _baseStyle.color);
        expect(style.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveLinkStyle uses specified option style', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveLinkStyle(_baseStyle);
        expect(style.color, _rootUrlStyle.color); // Purple from options
        expect(style.fontSize, _rootUrlStyle.fontSize); // 18 from options
        expect(style.decoration, isNull); // No decoration defined in options or base
        expect(style.fontFamily, _baseStyle.fontFamily); // Base family
      });

      testWidgets('resolveLinkHoverStyle uses specified option style', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveLinkHoverStyle(_baseStyle);
        expect(style.backgroundColor, _rootUrlHoverStyle.backgroundColor);
        expect(style.color, _rootUrlStyle.color);
        expect(style.fontSize, _rootUrlStyle.fontSize);
      });

      testWidgets('resolveLinkMouseCursor uses specified option cursor', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        expect(resolver.resolveLinkMouseCursor(), _rootCursor);
      });

      testWidgets('resolveOnUrlTap/Hover uses specified option callbacks', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(tester, theme: ThemeData.light(), rootOptions: rootOptions);
        final resolver = TextfStyleResolver(context);

        expect(resolver.resolveOnUrlTap(), same(_rootOnTap));
        expect(resolver.resolveOnUrlHover(), same(_rootOnHover));
      });
    });

    // --- Scenario 3: Nested TextfOptions ---
    group('Nested TextfOptions', () {
      // Define options commonly used in this group
      final rootOptions = TextfOptions(
        boldStyle: _rootBoldStyle,
        italicStyle: _rootItalicStyle,
        urlStyle: _rootUrlStyle,
        urlHoverStyle: _rootUrlHoverStyle, // Added Root Hover Style
        urlMouseCursor: _rootCursor, // Added Root Cursor
        onUrlTap: _rootOnTap,
        onUrlHover: _rootOnHover, // Added Root Hover Callback
        child: Container(),
      );
      final childOptions = TextfOptions(
        italicStyle: _childItalicStyle,
        codeStyle: _childCodeStyle,
        urlStyle: _childUrlStyle,
        onUrlTap: _childOnTap,
        child: Container(),
      );

      testWidgets('resolveStyle uses nearest ancestor (Child Italic)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.italicMarker, _baseStyle);
        expect(style.fontStyle, _childItalicStyle.fontStyle);
        expect(style.backgroundColor, _childItalicStyle.backgroundColor);
        expect(style.color, _baseStyle.color);
        expect(style.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveStyle uses nearest ancestor (Child Code)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.codeMarker, _baseStyle);
        expect(style.fontFamily, _childCodeStyle.fontFamily);
        expect(style.color, _childCodeStyle.color);
        expect(style.backgroundColor, isNull);
        expect(style.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveStyle inherits from higher ancestor (Root Bold)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.boldMarker, _baseStyle);
        expect(style.fontWeight, _rootBoldStyle.fontWeight);
        expect(style.color, _rootBoldStyle.color);
        expect(style.fontSize, _baseStyle.fontSize);
      });

      testWidgets('resolveStyle falls back to Theme/Default if unspecified anywhere (Strike)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveStyle(TokenType.strikeMarker, _baseStyle);
        expect(style.decoration, DefaultStyles.strikethroughStyle(_baseStyle).decoration);
        expect(style.color, _baseStyle.color);
      });

      testWidgets('resolveLinkStyle uses nearest ancestor (Child override)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveLinkStyle(_baseStyle);
        expect(style.decoration, _childUrlStyle.decoration); // None from child
        expect(style.color, _baseStyle.color); // Black from base (child didn't define color)
        expect(style.fontSize, _baseStyle.fontSize); // 16 from base (child didn't define size)
      });

      testWidgets('resolveLinkHoverStyle inherits from higher ancestor (Root)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        final style = resolver.resolveLinkHoverStyle(_baseStyle);
        expect(style.backgroundColor, _rootUrlHoverStyle.backgroundColor); // Yellow from Root
        expect(style.decoration, _childUrlStyle.decoration); // Inherits normal style prop from Child
        expect(style.color, _baseStyle.color); // Inherits color from base merged with child's normal option
      });

      testWidgets('resolveLinkMouseCursor inherits from higher ancestor (Root)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        expect(resolver.resolveLinkMouseCursor(), _rootCursor); // Expect Root's cursor
      });

      testWidgets('resolveOnUrlTap uses nearest ancestor (Child override)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        expect(resolver.resolveOnUrlTap(), same(_childOnTap));
      });

      testWidgets('resolveOnUrlHover inherits from higher ancestor (Root)', (tester) async {
        // pump and resolve inside testWidgets
        final context = await pumpWithOptions(
          tester,
          theme: ThemeData.light(),
          rootOptions: rootOptions,
          childOptions: childOptions,
        );
        final resolver = TextfStyleResolver(context);

        expect(resolver.resolveOnUrlHover(), same(_rootOnHover)); // Expect Root's callback
      });
    });
  });
}
