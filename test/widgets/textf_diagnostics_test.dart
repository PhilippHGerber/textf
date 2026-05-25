import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

String _diagnosticsForWidget(Widget widget) {
  final node = widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.singleLine);
  return node.toStringDeep();
}

void _onLinkTap(String url, String displayText) {
  debugPrint('Tapped: $url ($displayText)');
}

void _onLinkHover(String url, String displayText, {required bool isHovering}) {
  debugPrint('Hover: $url ($displayText), isHovering: $isHovering');
}

void main() {
  group('Textf diagnostics', () {
    test('shows configured properties when set', () {
      final description = _diagnosticsForWidget(
        const Textf(
          'Hello **world**',
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textScaler: TextScaler.linear(1.25),
          semanticsLabel: 'Label',
          locale: Locale('en', 'US'),
          strutStyle: StrutStyle(fontSize: 16),
          textWidthBasis: TextWidthBasis.longestLine,
          textHeightBehavior: TextHeightBehavior(),
          selectionColor: Colors.yellow,
          placeholders: {
            'icon': WidgetSpan(child: SizedBox.shrink()),
          },
        ),
      );

      expect(description, contains('data: "Hello **world**"'));
      expect(description, contains('style:'));
      expect(description, contains('textAlign:'));
      expect(description, contains('textDirection:'));
      expect(description, contains('maxLines:'));
      expect(description, contains('overflow:'));
      expect(description, contains('wrapping at box width'));
      expect(description, contains('textScaler:'));
      expect(description, contains('semanticsLabel: Label'));
      expect(description, contains('locale: en_US'));
      expect(description, contains('strutStyle:'));
      expect(description, contains('textWidthBasis:'));
      expect(description, contains('textHeightBehavior:'));
      expect(description, contains('selectionColor:'));
      expect(description, contains('placeholders'));
    });

    test('suppresses optional diagnostics when unset', () {
      final description = _diagnosticsForWidget(const Textf('Plain text'));

      expect(description, contains('data: "Plain text"'));
      expect(description, isNot(contains('style:')));
      expect(description, isNot(contains('textAlign:')));
      expect(description, isNot(contains('textDirection:')));
      expect(description, isNot(contains('maxLines:')));
      expect(description, isNot(contains('overflow:')));
      expect(description, isNot(contains('wrapping at box width')));
      expect(description, isNot(contains('textScaler:')));
      expect(description, isNot(contains('semanticsLabel:')));
      expect(description, isNot(contains('locale:')));
      expect(description, isNot(contains('strutStyle:')));
      expect(description, isNot(contains('textWidthBasis:')));
      expect(description, isNot(contains('textHeightBehavior:')));
      expect(description, isNot(contains('selectionColor:')));
      expect(description, isNot(contains('placeholders')));
    });
  });

  group('TextfOptions diagnostics', () {
    test('shows configured options and callback presence when set', () {
      final description = _diagnosticsForWidget(
        const TextfOptions(
          onLinkTap: _onLinkTap,
          onLinkHover: _onLinkHover,
          linkMouseCursor: SystemMouseCursors.click,
          linkAlignment: PlaceholderAlignment.middle,
          boldStyle: TextStyle(fontWeight: FontWeight.bold),
          italicStyle: TextStyle(fontStyle: FontStyle.italic),
          boldItalicStyle: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
          strikethroughStyle: TextStyle(decoration: TextDecoration.lineThrough),
          codeStyle: TextStyle(fontFamily: 'monospace'),
          underlineStyle: TextStyle(decoration: TextDecoration.underline),
          highlightStyle: TextStyle(backgroundColor: Colors.yellow),
          superscriptStyle: TextStyle(fontSize: 10),
          subscriptStyle: TextStyle(fontSize: 10),
          linkStyle: TextStyle(color: Colors.blue),
          linkHoverStyle: TextStyle(color: Colors.lightBlue),
          scriptFontSizeFactor: 0.7,
          superscriptBaselineFactor: 0.3,
          subscriptBaselineFactor: 0.2,
          strikethroughThickness: 1.5,
          child: SizedBox.shrink(),
        ),
      );

      expect(description, contains('onLinkTap'));
      expect(description, contains('onLinkHover'));
      expect(description, contains('linkMouseCursor:'));
      expect(description, contains('linkAlignment:'));
      expect(description, contains('boldStyle:'));
      expect(description, contains('italicStyle:'));
      expect(description, contains('boldItalicStyle:'));
      expect(description, contains('strikethroughStyle:'));
      expect(description, contains('codeStyle:'));
      expect(description, contains('underlineStyle:'));
      expect(description, contains('highlightStyle:'));
      expect(description, contains('superscriptStyle:'));
      expect(description, contains('subscriptStyle:'));
      expect(description, contains('linkStyle:'));
      expect(description, contains('linkHoverStyle:'));
      expect(description, contains('scriptFontSizeFactor: 0.7'));
      expect(description, contains('superscriptBaselineFactor: 0.3'));
      expect(description, contains('subscriptBaselineFactor: 0.2'));
      expect(description, contains('strikethroughThickness: 1.5'));
      expect(description, isNot(contains('child:')));
    });

    test('suppresses optional options when unset', () {
      final description = _diagnosticsForWidget(
        const TextfOptions(
          child: SizedBox.shrink(),
        ),
      );

      expect(description, isNot(contains('onLinkTap')));
      expect(description, isNot(contains('onLinkHover')));
      expect(description, isNot(contains('linkMouseCursor:')));
      expect(description, isNot(contains('linkAlignment:')));
      expect(description, isNot(contains('boldStyle:')));
      expect(description, isNot(contains('italicStyle:')));
      expect(description, isNot(contains('boldItalicStyle:')));
      expect(description, isNot(contains('strikethroughStyle:')));
      expect(description, isNot(contains('codeStyle:')));
      expect(description, isNot(contains('underlineStyle:')));
      expect(description, isNot(contains('highlightStyle:')));
      expect(description, isNot(contains('superscriptStyle:')));
      expect(description, isNot(contains('subscriptStyle:')));
      expect(description, isNot(contains('linkStyle:')));
      expect(description, isNot(contains('linkHoverStyle:')));
      expect(description, isNot(contains('scriptFontSizeFactor:')));
      expect(description, isNot(contains('superscriptBaselineFactor:')));
      expect(description, isNot(contains('subscriptBaselineFactor:')));
      expect(description, isNot(contains('strikethroughThickness:')));
      expect(description, isNot(contains('child:')));
    });
  });
}
