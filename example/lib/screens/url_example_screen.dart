import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../widgets/example_card.dart';
import '../widgets/selectable_scaffold.dart';

class UrlExampleScreen extends StatefulWidget {
  const UrlExampleScreen({super.key});

  @override
  State<UrlExampleScreen> createState() => _UrlExampleScreenState();
}

class _UrlExampleScreenState extends State<UrlExampleScreen> {
  String _lastTappedUrl = '';
  String _lastTappedDisplayText = '';
  String _hoveredUrl = '';
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return SelectableScaffold(
      appBar: AppBar(
        title: const Text('URL Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic URL example
            ExampleCard(
              title: 'Basic URL',
              description: 'Simple URL with default styling',
              code: 'Textf(\n  \'Visit [Flutter website](https://flutter.dev) for more information\',\n)',
              child: TextfOptions(
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Visit [Flutter website](https://flutter.dev) for more information',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Styled URL example
            ExampleCard(
              title: 'Custom Styled URL',
              description: 'URL with custom styling',
              code:
                  'TextfOptions(\n  urlStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),\n  child: Textf(\n    \'Check out [Textf documentation](https://pub.dev/packages/textf)\',\n  ),\n)',
              child: TextfOptions(
                urlStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Check out [Textf documentation](https://pub.dev/packages/textf)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // URL with hover effect
            ExampleCard(
              title: 'URL with Hover Effect',
              description: 'Demonstrates URL hover interaction (desktop/web only)',
              code:
                  'TextfOptions(\n  urlStyle: TextStyle(color: Colors.blue),\n  urlHoverStyle: TextStyle(color: Colors.red),\n  onUrlHover: (url, displayText, isHovering) {\n    // Handle hover state\n  },\n  child: Textf(\n    \'Hover over [this link](https://example.com) to see the effect\',\n  ),\n)',
              child: TextfOptions(
                urlStyle: const TextStyle(color: Colors.blue),
                urlHoverStyle: const TextStyle(color: Colors.red),
                onUrlHover: _handleUrlHover,
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Hover over [this link](https://example.com) to see the effect',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Multiple URLs in one text
            ExampleCard(
              title: 'Multiple URLs',
              description: 'Multiple URLs in a single text block',
              code: 'Textf(\n  \'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev) websites\',\n)',
              child: TextfOptions(
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev) websites',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formatted URL text
            ExampleCard(
              title: 'Formatted URL Text',
              description: 'URL display text with other formatting applied',
              code:
                  'Textf(\n  \'Check out [**bold link**](https://example.com) and [*italic link*](https://example.org)\',\n)',
              child: TextfOptions(
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Check out [**bold link**](https://example.com) and [*italic link*](https://example.org)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email URL example
            ExampleCard(
              title: 'Email URL',
              description: 'URL with mailto: protocol',
              code: 'Textf(\n  \'Contact [support](mailto:support@example.com) for assistance\',\n)',
              child: TextfOptions(
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Contact [support](mailto:support@example.com) for assistance',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // URL with special characters
            ExampleCard(
              title: 'URL with Special Characters',
              description: 'URL containing query parameters and fragments',
              code:
                  'Textf(\n  \'Search for [Flutter widgets](https://pub.dev/packages?q=flutter+widgets#results)\',\n)',
              child: TextfOptions(
                onUrlTap: _handleUrlTap,
                child: const Textf(
                  'Search for [Flutter widgets](https://pub.dev/packages?q=flutter+widgets#results)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Interactive URL demo section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URL Interaction Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Last tapped URL
                    Text(
                      'Last Tapped URL:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('URL: $_lastTappedUrl'),
                    Text('Display Text: $_lastTappedDisplayText'),

                    const SizedBox(height: 16),

                    // Hover information (for desktop/web)
                    Text(
                      'Hover Status:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('URL: $_hoveredUrl'),
                    Text('Hovering: ${_isHovering ? 'Yes' : 'No'}'),

                    const SizedBox(height: 16),

                    // Launch URL button
                    if (_lastTappedUrl.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(_lastTappedUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Last Tapped URL'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUrlTap(String url, String displayText) {
    setState(() {
      _lastTappedUrl = url;
      _lastTappedDisplayText = displayText;
    });
    // Uncomment to automatically launch URLs when tapped
    // _launchUrl(url);
  }

  void _handleUrlHover(String url, String displayText, bool isHovering) {
    setState(() {
      _hoveredUrl = url;
      _isHovering = isHovering;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
      await url_launcher.launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }
}
