import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class PlaceholderExampleScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const PlaceholderExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placeholder Examples'),
        actions: [
          IconButton(
            icon: Icon(
              currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ExampleCard(
              title: 'Dynamic Widget Insertion',
              description:
                  'Seamlessly inject custom Flutter widgets directly into your formatted text flow.',
              code: '''
Textf(
  'Hello! This is a star icon: {0}. And this is a ~~cat~~ bird: {1}',
  inlineSpans: [
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Icon(Icons.star, color: Colors.amber),
    ),
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Image.asset('bird.png'),
    ),
  ],
)''',
              child: Textf(
                'Hello! This is a star icon: {0}. And this is a ~~cat~~ bird: {1}',
                style: const TextStyle(fontSize: 18),
                inlineSpans: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/img/bird.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ExampleCard(
              title: 'Rich Media Support',
              description:
                  'Support for animated GIFs and other media assets, allowing for more dynamic content.',
              code: '''
Textf(
  'Witness the flight of the bird: {0}',
  inlineSpans: [
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Image.asset('bird.gif'),
    ),
  ],
)''',
              child: Textf(
                'Witness the flight of the bird: {0}',
                style: const TextStyle(fontSize: 18),
                inlineSpans: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/img/bird.gif',
                      width: 48,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ExampleCard(
              title: 'Contextual Style Inheritance',
              description:
                  'Inserted spans automatically inherit the formatting of the surrounding text, such as **bold** or _italic_ styles.',
              code: '''
Textf(
  'This is **bold {0}** and _italic {1}_.',
  inlineSpans: [
    TextSpan(text: " [ICON] "), // Inherits Bold
    WidgetSpan(child: Image.asset('../coffee.png')), // Inherits Italic context
  ],
)''',
              child: Textf(
                'This is **bold {0}** and _italic {1}_.',
                style: const TextStyle(fontSize: 18),
                inlineSpans: [
                  const TextSpan(text: " [ICON] "),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/img/coffee.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ExampleCard(
              title: 'Interactive Links with Media',
              description:
                  'Create rich, interactive links by embedding icons or images directly within the clickable area.',
              code: '''
TextfOptions(
  onLinkTap: (url, _) => print(url),
  child: Textf(
    'Visit [Flutter {0}](https://flutter.dev) to learn more.',
    inlineSpans: [
      WidgetSpan(child: Image.asset('bird.png')),
    ],
  ),
)''',
              child: TextfOptions(
                onLinkTap: (url, _) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Launching: $url')),
                  );
                },
                child: Textf(
                  'Visit [Flutter {0}](https://flutter.dev) to learn more.',
                  style: const TextStyle(fontSize: 18),
                  inlineSpans: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Image.asset(
                        'assets/img/bird.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ExampleCard(
              title: 'Custom Inline Components',
              description:
                  'Build complex inline elements like badges, tags, or status indicators using standard Flutter widgets.',
              code: '''
Textf(
  'The user {0} has been successfully verified.',
  inlineSpans: [
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
    ),
  ],
)''',
              child: Textf(
                'The user {0} has been successfully verified.',
                style: const TextStyle(fontSize: 18),
                inlineSpans: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
