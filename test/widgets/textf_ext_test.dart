import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

void main() {
  group('TextfExt', () {
    testWidgets('renders identically to Textf constructor', (tester) async {
      // Build both variants side by side
      await tester.pumpWidget(
        neutralTestApp(
          child: const Column(
            children: [
              Textf('Hello **bold** *italic*'),
            ],
          ),
        ),
      );

      // Capture the widget tree from the constructor version
      final constructorFinder = find.byType(Textf);
      expect(constructorFinder, findsOneWidget);
      final constructorWidget = tester.widget<Textf>(constructorFinder);

      // Now build the extension version
      await tester.pumpWidget(
        neutralTestApp(
          child: Column(
            children: [
              'Hello **bold** *italic*'.textf(),
            ],
          ),
        ),
      );

      final extensionFinder = find.byType(Textf);
      expect(extensionFinder, findsOneWidget);
      final extensionWidget = tester.widget<Textf>(extensionFinder);

      // Verify they produce the same widget configuration
      expect(extensionWidget.data, constructorWidget.data);
      expect(extensionWidget.style, constructorWidget.style);
      expect(extensionWidget.textAlign, constructorWidget.textAlign);
      expect(extensionWidget.maxLines, constructorWidget.maxLines);
    });

    testWidgets('forwards all parameters', (tester) async {
      const testStyle = TextStyle(fontSize: 20);

      await tester.pumpWidget(
        neutralTestApp(
          child: 'Test **text**'.textf(
            style: testStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      );

      final widget = tester.widget<Textf>(find.byType(Textf));
      expect(widget.data, 'Test **text**');
      expect(widget.style, testStyle);
      expect(widget.textAlign, TextAlign.center);
      expect(widget.maxLines, 1);
      expect(widget.overflow, TextOverflow.ellipsis);
      expect(widget.softWrap, isFalse);
    });

    testWidgets('forwards placeholders', (tester) async {
      await tester.pumpWidget(
        neutralTestApp(
          child: 'Hello {icon}'.textf(
            placeholders: {
              'icon': const WidgetSpan(child: SizedBox(width: 16, height: 16)),
            },
          ),
        ),
      );

      final widget = tester.widget<Textf>(find.byType(Textf));
      expect(widget.placeholders, isNotNull);
      expect(widget.placeholders, contains('icon'));
    });
  });

  group('TextfStringExt', () {
    test('plain text returns unchanged', () {
      expect('Hello world'.stripFormatting(), 'Hello world');
    });

    test('bold markers stripped', () {
      expect('**bold**'.stripFormatting(), 'bold');
    });

    test('link reduced to display text', () {
      expect('[click](url)'.stripFormatting(), 'click');
    });

    test('unpaired marker preserved', () {
      expect('2 * 3'.stripFormatting(), '2 * 3');
    });

    test('placeholder preserved', () {
      expect('{icon}'.stripFormatting(), '{icon}');
    });
  });
}
