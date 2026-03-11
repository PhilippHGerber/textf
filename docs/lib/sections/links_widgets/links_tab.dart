// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/example_card.dart';
import '/widgets/section_header.dart';

class LinksTab extends StatelessWidget {
  const LinksTab({super.key});

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Links',
          subtitle: 'Use [label](url) syntax to create tappable links.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Basic link',
          description: 'Tap to open URL via onLinkTap',
          code: '[pub.dev](https://pub.dev/packages/textf)',
          child: _BasicLinkDemo(),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'onLinkTap callback',
          description: 'Intercept taps to show a SnackBar instead',
          code: 'TextfOptions(\n'
              '  onLinkTap: (url, text) => showSnackBar(url),\n'
              "  child: Textf('[tap me](https://pub.dev)'),\n"
              ')',
          child: _SnackBarLinkDemo(),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Link with formatted label',
          description: 'Links can contain inline formatting',
          code: '[**Bold ==highlight==** link](https://pub.dev/packages/textf)',
          child: TextfOptions(
            onLinkTap: (url, _) => _launchUrl(url),
            child: const Textf('[**Bold ==highlight==** link](https://pub.dev/packages/textf)'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BasicLinkDemo extends StatelessWidget {
  const _BasicLinkDemo();

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return TextfOptions(
      onLinkTap: (url, _) => _launchUrl(url),
      child: const Textf('[pub.dev](https://pub.dev/packages/textf)'),
    );
  }
}

class _SnackBarLinkDemo extends StatelessWidget {
  const _SnackBarLinkDemo();

  @override
  Widget build(BuildContext context) {
    return TextfOptions(
      onLinkTap: (url, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tapped: $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: const Textf('[tap me](https://pub.dev/packages/textf)'),
    );
  }
}
