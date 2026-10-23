import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

/// Verifies that Flutter's [SelectionArea] seamlessly spans across [Textf] links
/// (which are built as [WidgetSpan]s) on Flutter 3.47+, both via SelectAll and drag
/// gestures, across plain and formatted links, while preserving single-tap
/// [TextfOptions.onLinkTap] dispatch
/// (issues/link-selection/01-verify-selection-across-links.md).
void main() {
  group('SelectionArea across links', () {
    testWidgets('SelectAll on plain link without onLinkTap', (tester) async {
      const text = 'Before [a link](https://e.com) after.';
      SelectedContent? selectedContent;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
      );

      _selectAll(tester);
      await tester.pumpAndSettle();

      expect(selectedContent?.plainText, 'Before a link after.');
    });

    testWidgets('SelectAll on plain link with onLinkTap', (tester) async {
      const text = 'Before [a link](https://e.com) after.';
      SelectedContent? selectedContent;
      var tapCount = 0;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
        onLinkTap: (url, displayText) => tapCount++,
      );

      _selectAll(tester);
      await tester.pumpAndSettle();

      expect(selectedContent?.plainText, 'Before a link after.');
      expect(tapCount, 0, reason: 'Select all should not trigger onLinkTap');
    });

    testWidgets('SelectAll on formatted link [**bold** link] without onLinkTap', (tester) async {
      const text = 'Before [**bold** link](https://e.com) after.';
      SelectedContent? selectedContent;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
      );

      _selectAll(tester);
      await tester.pumpAndSettle();

      expect(selectedContent?.plainText, 'Before bold link after.');
    });

    testWidgets('SelectAll on formatted link [**bold** link] with onLinkTap', (tester) async {
      const text = 'Before [**bold** link](https://e.com) after.';
      SelectedContent? selectedContent;
      var tapCount = 0;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
        onLinkTap: (url, displayText) => tapCount++,
      );

      _selectAll(tester);
      await tester.pumpAndSettle();

      expect(selectedContent?.plainText, 'Before bold link after.');
      expect(tapCount, 0, reason: 'Select all should not trigger onLinkTap');
    });

    testWidgets('Drag selection from Before to after across plain link', (tester) async {
      const text = 'Before [a link](https://e.com) after.';
      SelectedContent? selectedContent;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
      );

      await _dragAcrossFirstParagraph(tester);

      expect(selectedContent?.plainText, 'Before a link after.');
    });

    testWidgets('Drag selection across plain link with onLinkTap does not trigger callback', (
      tester,
    ) async {
      const text = 'Before [a link](https://e.com) after.';
      SelectedContent? selectedContent;
      var tapCount = 0;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
        onLinkTap: (url, displayText) => tapCount++,
      );

      await _dragAcrossFirstParagraph(tester);

      expect(selectedContent?.plainText, 'Before a link after.');
      expect(tapCount, 0, reason: 'Drag selection should not trigger onLinkTap');
    });

    testWidgets('Drag selection across formatted link [**bold** link]', (tester) async {
      const text = 'Before [**bold** link](https://e.com) after.';
      SelectedContent? selectedContent;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
      );

      await _dragAcrossFirstParagraph(tester);

      expect(selectedContent?.plainText, 'Before bold link after.');
    });

    testWidgets('Drag selection across formatted link [**bold** link] with onLinkTap', (
      tester,
    ) async {
      const text = 'Before [**bold** link](https://e.com) after.';
      SelectedContent? selectedContent;
      var tapCount = 0;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onSelectionChanged: (content) => selectedContent = content,
        onLinkTap: (url, displayText) => tapCount++,
      );

      await _dragAcrossFirstParagraph(tester);

      expect(selectedContent?.plainText, 'Before bold link after.');
      expect(tapCount, 0, reason: 'Drag selection should not trigger onLinkTap');
    });

    testWidgets('Tapping a link inside SelectionArea calls onLinkTap once', (tester) async {
      const text = 'Before [a link](https://e.com) after.';
      String? tappedUrl;
      String? tappedText;
      var tapCount = 0;

      await _pumpSelectableTextf(
        tester,
        data: text,
        onLinkTap: (url, displayText) {
          tappedUrl = url;
          tappedText = displayText;
          tapCount++;
        },
      );

      final linkFinder = find.text('a link', findRichText: true);
      expect(linkFinder, findsOneWidget);

      await tester.tap(linkFinder);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(tappedUrl, 'https://e.com');
      expect(tappedText, 'a link');
    });
  });
}

Future<void> _pumpSelectableTextf(
  WidgetTester tester, {
  required String data,
  ValueChanged<SelectedContent?>? onSelectionChanged,
  void Function(String url, String displayText)? onLinkTap,
}) {
  return pumpTextfWidget(
    tester,
    data: data,
    textfOptions: onLinkTap != null
        ? TextfOptions(
            onLinkTap: onLinkTap,
            child: const SizedBox.shrink(),
          )
        : null,
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    wrap: (child) => SelectionArea(
      onSelectionChanged: onSelectionChanged,
      child: child,
    ),
  );
}

void _selectAll(WidgetTester tester) {
  tester
      .state<SelectableRegionState>(find.byType(SelectableRegion))
      .selectAll(SelectionChangedCause.keyboard);
}

Future<void> _dragAcrossFirstParagraph(WidgetTester tester) async {
  final outerParagraph = tester.renderObject<RenderParagraph>(
    find.byType(RichText).first,
  );

  final startPos = outerParagraph.localToGlobal(
    Offset(2, outerParagraph.size.height / 2),
  );
  final endPos = outerParagraph.localToGlobal(
    Offset(outerParagraph.size.width - 2, outerParagraph.size.height / 2),
  );

  final gesture = await tester.startGesture(startPos, kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(endPos);
  await gesture.up();
  await tester.pumpAndSettle();
}
