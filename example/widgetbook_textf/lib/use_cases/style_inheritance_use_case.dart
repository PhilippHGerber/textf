// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Style Inheritance',
  type: Textf,
)
Widget styleInheritanceUseCase(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Style Inheritance:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),

              // Root level TextfOptions
              TextfOptions(
                // Root styles
                boldStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
                linkStyle: const TextStyle(
                  color: Colors.purple,
                  decoration: TextDecoration.underline,
                ),
                italicStyle: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example with root level styles
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Root Level:'),
                          Textf(
                            'This uses **root bold** and *root italic* and [root link](https://example.com)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Mid-level TextfOptions that overrides some styles but inherits others
                    TextfOptions(
                      italicStyle: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green,
                        backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                      ),
                      codeStyle: const TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Colors.grey,
                        color: Colors.white,
                      ),
                      // No boldStyle override, will inherit from root
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mid Level:'),
                                Textf(
                                  'This uses **inherited bold**, *overridden italic*, `mid code` and [inherited link](https://example.com)',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),

                          Divider(),

                          // Leaf level TextfOptions that overrides some additional styles
                          TextfOptions(
                            // Override URL style but inherit other styles
                            linkStyle: TextStyle(
                              color: Colors.orange,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.bold,
                            ),
                            // No boldStyle or italicStyle override
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Leaf Level:'),
                                  Textf(
                                    'This uses **inherited bold**, *inherited italic*, `inherited code` and [overridden link](https://example.com)',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
