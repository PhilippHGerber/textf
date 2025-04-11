// example/lib/screens/url_example_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart'; // Main library
import 'package:url_launcher/url_launcher.dart'
    as url_launcher; // For launching URLs

import '../widgets/example_card.dart'; // Reusable card for examples

class UrlExampleScreen extends StatefulWidget {
  const UrlExampleScreen({super.key});

  @override
  State<UrlExampleScreen> createState() => _UrlExampleScreenState();
}

class _UrlExampleScreenState extends State<UrlExampleScreen> {
  // State variables to track interactions
  String _lastTappedUrl = '';
  String _lastTappedDisplayText = ''; // Raw display text including formatting
  String _hoveredUrl = '';
  String _hoveredDisplayText = ''; // Raw display text including formatting
  bool _isHovering = false;

  // --- Interaction Callbacks ---

  void _handleUrlTap(String url, String displayText) {
    // This function is called ONLY when a link span's recognizer is tapped.

    // Use the current context from the State object.
    // Ensure the widget is still mounted before proceeding.
    if (!mounted) return;

    // Update the persistent status display at the bottom
    setState(() {
      _lastTappedUrl = url;
      _lastTappedDisplayText = displayText;
    });

    // --- Show SnackBar ---
    // Remove any existing snackbar first to prevent overlap if tapped quickly
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Using the raw display text here as requested by TextfOptions contract
        content: Text('Tapped link: "$displayText" ($url)'),
        duration: const Duration(seconds: 3), // Slightly longer duration
        behavior: SnackBarBehavior.floating, // Optional: Make it float
        action: SnackBarAction(
          label: 'LAUNCH',
          onPressed: () => _launchUrl(url), // Launch the tapped URL
        ),
      ),
    );
    // --- End SnackBar ---

    // Optional: Automatically launch URL on tap (commented out by default)
    // _launchUrl(url);
  }

  void _handleUrlHover(String url, String displayText, bool isHovering) {
    if (!mounted) return;

    // Update state for the persistent status display
    if (isHovering != _isHovering || url != _hoveredUrl) {
      setState(() {
        _hoveredUrl = isHovering ? url : '';
        _hoveredDisplayText = isHovering ? displayText : '';
        _isHovering = isHovering;
      });
    }
  }

  // --- URL Launching ---

  Future<void> _launchUrl(String url) async {
    // Use the current context from the State object.
    if (!mounted) return;

    final Uri uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context); // Cache messenger

    if (await url_launcher.canLaunchUrl(uri)) {
      try {
        final bool launched = await url_launcher.launchUrl(uri);
        if (!mounted) return; // Check again after async gap
        if (launched) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('URL Launched Successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Should generally not happen if canLaunchUrl was true, but handle defensively
          messenger.showSnackBar(
            SnackBar(
              content: Text('Could not launch $url (launchUrl returned false)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error launching $url: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not launch $url (canLaunchUrl returned false)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Wrap examples needing options in a single TextfOptions provider
    return TextfOptions(
      // Provide the callbacks that will be used by Textf widgets below
      onUrlTap: _handleUrlTap, // Connects tap gesture to our state handler
      onUrlHover: _handleUrlHover,

      // Define default link appearance (can be overridden locally)
      urlStyle: const TextStyle(
        color: Colors.blue, // Standard blue link color
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue, // Match underline color
      ),
      urlHoverStyle: const TextStyle(
        color: Colors.deepPurple, // Change color on hover
        fontWeight: FontWeight.bold, // Make it bold on hover
        decoration: TextDecoration.underline, // Keep underline on hover
      ),
      urlMouseCursor: SystemMouseCursors.click, // Standard hand cursor

      child: Scaffold(
        // Provides the Scaffold needed for SnackBar
        appBar: AppBar(
          title: const Text('URL Examples'),
        ),
        body: SelectionArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- Example Cards ---
                    // (Keep all the ExampleCard widgets from the previous version here)
                    // ... (Basic URL, Custom Styled, Hover Effect, Multiple, Formatted, etc.) ...

                    // Example Card: Basic URL
                    const ExampleCard(
                      title: 'Basic URL',
                      description:
                          'Simple URL using default styling from TextfOptions',
                      code:
                          'Textf(\n  \'Visit [Flutter website](https://flutter.dev) for more information\',\n)',
                      child: Textf(
                        'Visit [Flutter website](https://flutter.dev) for more information',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: Custom Styled URL (Override)
                    ExampleCard(
                      title: 'Custom Styled URL (Override)',
                      description:
                          'URL with specific styling overriding TextfOptions',
                      code:
                          'TextfOptions(\n  urlStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),\n  urlHoverStyle: TextStyle(backgroundColor: Colors.yellow),\n  child: Textf(\n    \'Check out [Textf documentation](https://pub.dev/packages/textf)\',\n  ),\n)',
                      child: TextfOptions(
                        urlStyle: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                        urlHoverStyle: TextStyle(
                          backgroundColor: Colors.teal.shade100,
                          decoration: TextDecoration.none,
                        ),
                        // Note: onUrlTap/onUrlHover will still be inherited unless overridden here too
                        child: const Textf(
                          'Check out [Textf documentation](https://pub.dev/packages/textf)',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: URL with Hover Effect
                    const ExampleCard(
                      title: 'URL with Hover Effect',
                      description:
                          'Demonstrates URL hover interaction (using styles from parent TextfOptions)',
                      code:
                          'Textf(\n  \'Hover over [this link](https://example.com) to see the effect\',\n)',
                      child: Textf(
                        'Hover over [this link](https://example.com) to see the effect',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: Multiple URLs
                    const ExampleCard(
                      title: 'Multiple URLs',
                      description: 'Multiple URLs in a single text block',
                      code:
                          'Textf(\n  \'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev) websites\',\n)',
                      child: Textf(
                        'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev) websites',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: Formatted URL Text
                    const ExampleCard(
                      title: 'Formatted URL Text',
                      description:
                          'URL display text with other formatting applied',
                      code:
                          'Textf(\n  \'Check out [**bold link**](https://example.com) and [*italic link*](https://example.org)\',\n)',
                      child: Textf(
                        'Check out [**bold link**](https://example.com) and [*italic link*](https://example.org)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: Nested Formatting in URL Text
                    const ExampleCard(
                      title: 'Nested Formatting in URL Text',
                      description:
                          'URL display text with nested formatting (bold > italic)',
                      code:
                          'Textf(\n  \'Link with [**nested _italic_ style**](https://example.net)\',\n)',
                      child: Textf(
                        'Link with [**nested _italic_ style**](https://example.net)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: Email URL
                    const ExampleCard(
                      title: 'Email URL',
                      description: 'URL with mailto: protocol',
                      code:
                          'Textf(\n  \'Contact [support](mailto:support@example.com) for assistance\',\n)',
                      child: Textf(
                        'Contact [support](mailto:support@example.com) for assistance',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: URL with Special Characters
                    const ExampleCard(
                      title: 'URL with Special Characters',
                      description:
                          'URL containing query parameters and fragments',
                      code:
                          'Textf(\n  \'Search for [Flutter widgets](https://pub.dev/packages?q=flutter+widgets#results)\',\n)',
                      child: Textf(
                        'Search for [Flutter widgets](https://pub.dev/packages?q=flutter+widgets#results)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example Card: URL Needing Normalization
                    const ExampleCard(
                      title: 'URL Needing Normalization',
                      description:
                          'URL without protocol (should get http:// added)',
                      code: 'Textf(\n  \'Visit [Google](google.com)\',\n)',
                      child: Textf(
                        'Visit [Google](google.com)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing before status bar
                  ],
                ),
              ),

              // --- Interaction Status Display (Bottom Bar) ---
              _buildInteractionStatus(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Status Display ---

  Widget _buildInteractionStatus() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest, // Use semantic color
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Take only needed vertical space
        children: [
          Text(
            'Interaction Status:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Last Tapped:',
            _lastTappedUrl.isEmpty
                ? 'N/A'
                : '"$_lastTappedDisplayText" ($_lastTappedUrl)',
          ),
          const SizedBox(height: 4),
          _buildStatusRow(
            'Hovering:',
            _isHovering ? '"$_hoveredDisplayText" ($_hoveredUrl)' : 'No',
          ),
          if (_lastTappedUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
                onPressed: () => _launchUrl(_lastTappedUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Launch Last Tapped URL',
                    style: TextStyle(fontSize: 12)),
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow
                .ellipsis, // Prevent long URLs/text from overflowing
            maxLines: 2, // Allow up to 2 lines for display text + URL
          ),
        ),
      ],
    );
  }
}
