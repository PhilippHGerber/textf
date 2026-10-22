// ignore_for_file: no-empty-block, avoid-top-level-members-in-tests

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

/// One semantics node as a screen reader sees it.
typedef _Node = ({int id, String label, bool isLink, bool hasTap, int childCount});

/// Pumps [text] in a [Textf] inside [neutralTestApp], with a link tap handler unless
/// [withTapHandler] is false.
Future<void> _pump(
  WidgetTester tester,
  String text, {
  bool withTapHandler = true,
  void Function(String url, String displayText)? onLinkTap,
  Map<String, InlineSpan>? placeholders,
}) {
  final Widget textf = Textf(text, placeholders: placeholders);

  return tester.pumpWidget(
    neutralTestApp(
      child: withTapHandler
          ? TextfOptions(onLinkTap: onLinkTap ?? (url, displayText) {}, child: textf)
          : textf,
    ),
  );
}

/// The semantics owner of the test view.
SemanticsOwner? _semanticsOwner(WidgetTester tester) =>
    tester.binding.renderViews.first.owner?.semanticsOwner;

/// All semantics nodes below the root, depth first in traversal order.
List<_Node> _nodes(WidgetTester tester) {
  final SemanticsNode? root = _semanticsOwner(tester)?.rootSemanticsNode;
  final result = <_Node>[];

  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    result.add((
      id: node.id,
      label: data.label,
      isLink: data.flagsCollection.isLink,
      hasTap: data.hasAction(SemanticsAction.tap),
      childCount: node.childrenCount,
    ));
    node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(visit);
  }

  root?.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(visit);

  return result;
}

List<_Node> _linkNodes(WidgetTester tester) => _nodes(tester).where((n) => n.isLink).toList();

void main() {
  group('Link semantics', () {
    group('label is the visible link text', () {
      const cases = {
        'plain': ('See [Privacy](https://e.com/p).', 'Privacy'),
        'formatted': ('See [**Terms** of _Service_](https://e.com/t).', 'Terms of Service'),
        'escaped': (r'See [a\*b](https://e.com/x).', 'a*b'),
        'placeholder': ('See [{name}](https://e.com/n).', 'Alice'),
        'superscript': ('See [x^2^](https://e.com/s).', 'x2'),
        'text widget placeholder': ('See [{who}](https://e.com/w).', 'Bob'),
        'widget placeholder without text': ('See [go{icon}](https://e.com/i).', 'go'),
      };

      for (final MapEntry(key: kind, value: (text, expected)) in cases.entries) {
        testWidgets(kind, (tester) async {
          await _pump(
            tester,
            text,
            placeholders: {
              'name': const TextSpan(text: 'Alice'),
              'who': const WidgetSpan(child: Text('Bob')),
              'icon': const WidgetSpan(child: SizedBox(width: 8, height: 8)),
            },
          );

          expect(_linkNodes(tester).map((n) => n.label), [expected]);
        });
      }
    });

    group('reading order', () {
      testWidgets('two links are read in their place in the sentence', (tester) async {
        await _pump(
          tester,
          'I agree to the [Terms of Service](https://e.com/t) and '
          '[Privacy Policy](https://e.com/p).',
        );

        final nodes = _nodes(tester).where((n) => n.childCount == 0);
        expect(nodes.map((n) => (n.label, n.isLink)), [
          ('I agree to the ', false),
          ('Terms of Service', true),
          (' and ', false),
          ('Privacy Policy', true),
          ('.', false),
        ]);
      });

      testWidgets('one link is its own node, not merged into the paragraph', (tester) async {
        await _pump(tester, 'I agree to the [Terms of Service](https://e.com/t).');

        final nodes = _nodes(tester);
        expect(nodes.where((n) => n.childCount == 0).map((n) => (n.label, n.isLink)), [
          ('I agree to the ', false),
          ('Terms of Service', true),
          ('.', false),
        ]);
        final parents = nodes.where((n) => n.childCount > 0);
        expect(parents.where((n) => n.isLink || n.hasTap), isEmpty);
      });

      testWidgets('adjacent links keep their order', (tester) async {
        await _pump(
          tester,
          '[One](https://e.com/1)[Two](https://e.com/2)[Three](https://e.com/3) end',
        );

        final leaves = _nodes(tester).where((n) => n.childCount == 0);
        expect(leaves.map((n) => n.label), ['One', 'Two', 'Three', ' end']);
      });

      testWidgets('links on separate lines keep their order', (tester) async {
        await _pump(tester, '[One](https://e.com/1)\n[Two](https://e.com/2) end\nlast');

        final leaves = _nodes(tester).where((n) => n.childCount == 0);
        expect(leaves.map((n) => n.label), ['One', '\n', 'Two', ' end\nlast']);
      });

      testWidgets('a thematic break between links adds no node', (tester) async {
        await _pump(tester, 'A [x](https://e.com/x)\n---\nB [y](https://e.com/y) end');

        final leaves = _nodes(tester).where((n) => n.childCount == 0);
        expect(leaves.map((n) => n.label), ['A ', 'x', '\n', '\nB ', 'y', ' end']);
      });

      testWidgets('a widget placeholder next to a link keeps its place', (tester) async {
        await _pump(
          tester,
          'Go {icon} to [the docs](https://e.com/d) now',
          placeholders: {
            'icon': WidgetSpan(
              child: Semantics(label: 'arrow', child: const SizedBox(width: 8, height: 8)),
            ),
          },
        );

        final leaves = _nodes(tester).where((n) => n.childCount == 0);
        expect(leaves.map((n) => n.label), ['Go ', 'arrow', ' to ', 'the docs', ' now']);
      });

      testWidgets('a superscript in a paragraph with a link is its own node', (tester) async {
        await _pump(tester, 'E = mc^2^ and [link](https://e.com/l)');

        final leaves = _nodes(tester).where((n) => n.childCount == 0);
        expect(leaves.map((n) => (n.label, n.isLink)), [
          ('E = mc', false),
          ('2', false),
          (' and ', false),
          ('link', true),
        ]);
      });
    });

    group('link node', () {
      testWidgets('a formatted link is exactly one link node', (tester) async {
        await _pump(tester, 'See [**Terms** of Service](https://e.com/t).');

        expect(_linkNodes(tester).map((n) => n.label), ['Terms of Service']);
      });

      testWidgets('only link nodes can be tapped; they have no children', (tester) async {
        await _pump(
          tester,
          'Read [**Terms**](https://e.com/t), [Privacy](https://e.com/p) and '
          '[_FAQ_](https://e.com/f).',
        );

        final nodes = _nodes(tester);
        final links = _linkNodes(tester);
        expect(links, hasLength(3));
        for (final link in links) {
          expect(link.hasTap, isTrue, reason: link.label);
          expect(link.childCount, 0, reason: link.label);
        }
        expect(nodes.where((n) => n.hasTap && !n.isLink), isEmpty);
        expect(nodes.where((n) => n.label.isEmpty && n.childCount == 0), isEmpty);
      });

      testWidgets('activating the link node calls onLinkTap once', (tester) async {
        final taps = <(String, String)>[];
        await _pump(
          tester,
          'See [**Terms**](https://e.com/t).',
          onLinkTap: (url, displayText) => taps.add((url, displayText)),
        );

        final link = _linkNodes(tester).single;
        _semanticsOwner(tester)?.performAction(link.id, SemanticsAction.tap);

        expect(taps, [('https://e.com/t', '**Terms**')]);
      });

      testWidgets('without onLinkTap the link node has no tap action', (tester) async {
        await _pump(tester, 'See [Terms](https://e.com/t).', withTapHandler: false);

        final link = _linkNodes(tester).single;
        expect(link.hasTap, isFalse);
      });
    });

    group('paragraphs without links', () {
      // Unchanged from 2.0.0: one merged node; Flutter separates the script's
      // placeholder text with line breaks.
      const cases = {
        'E = mc^2^ holds.': 'E = mc\n2\n holds.',
        '**bold** and `code` here.': 'bold and code here.',
      };

      for (final MapEntry(key: text, value: expected) in cases.entries) {
        testWidgets('"$text" stays one node', (tester) async {
          await _pump(tester, text);

          expect(_nodes(tester).map((n) => n.label), [expected]);
        });
      }
    });
  });
}
