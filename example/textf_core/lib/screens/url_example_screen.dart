// example/lib/screens/url_example_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../widgets/example_card.dart';

class UrlExampleScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const UrlExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  State<UrlExampleScreen> createState() => _UrlExampleScreenState();
}

class _UrlExampleScreenState extends State<UrlExampleScreen> {
  String _hoveredUrl = '';
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _handleUrlTap(String url, String rawDisplayText) {
    if (!mounted) return;
    _removeOverlay(); // Remove overlay BEFORE showing Snackbar

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Link Tapped: $rawDisplayText',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.lightBlueAccent,
          onPressed: () => _launchUrl(url),
        ),
      ),
    );
    // _launchUrl(url); // Optional auto-launch
  }

  void _handleLinkHover(String url, String rawDisplayText, {required bool isHovering}) {
    if (!mounted) return;
    // Optimization: Only update state/overlay if hover status or URL changes,
    // or if we are definitely starting to hover over a valid URL.
    if (isHovering != _isHovering || (isHovering && url != _hoveredUrl)) {
      setState(() {
        _hoveredUrl = isHovering ? url : '';
        _isHovering = isHovering;
      });

      if (isHovering && url.isNotEmpty) {
        _showUrlOverlay(url);
      } else {
        _removeOverlay();
      }
    } else if (!isHovering && _overlayEntry != null) {
      // Ensure overlay is removed if hover stops
      _removeOverlay();
    }
  }

  void _showUrlOverlay(String url) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          // Wrap with Material for context
          child: Material(
            type: MaterialType.transparency, // Don't draw Material background
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              // Use theme colors for better adaptation
              color: Theme.of(context)
                  . //
                  colorScheme
                  .surfaceContainerHighest
                  .withValues(
                    alpha: 0.95,
                  ),
              child: Text(
                url,
                style: TextStyle(
                  color: Theme.of(context) //
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 12,
                  decoration: TextDecoration.none, // Prevent underline here
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        // Might throw if called after dispose or during tree modifications, ignore.
        // print("Error removing overlay: $e");
      } finally {
        _overlayEntry = null;
        // If we are removing the overlay, reset the hover state too
        if (_isHovering && mounted) {
          setState(() {
            _isHovering = false;
            _hoveredUrl = '';
          });
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    // ... (launch URL logic remains the same)
    if (!mounted) return;

    final Uri uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final bool canLaunch = await url_launcher.canLaunchUrl(uri);
      if (!mounted) return; // Check mount status after async gap

      if (canLaunch) {
        final bool launched = await url_launcher.launchUrl(uri);
        if (!mounted) return;

        if (!launched) {
          // Handle case where launchUrl returns false despite canLaunchUrl being true
          messenger.showSnackBar(
            _buildUrlSnackBar('Could not open $url', Icons.warning_amber, Colors.orange.shade700),
          );
        }
      } else {
        messenger.showSnackBar(
          _buildUrlSnackBar('Cannot open URL: $url', Icons.error_outline, Colors.red.shade700),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        _buildUrlSnackBar('Error opening URL: $e', Icons.error_outline, Colors.red.shade700),
      );
    }
  }

  SnackBar _buildUrlSnackBar(String message, IconData icon, Color backgroundColor) {
    // ... (SnackBar builder remains the same)
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the icon based on the current theme mode
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Examples'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleThemeMode,
          ),
        ],
      ),
      body: TextfOptions(
        // Parent options provide callbacks
        onLinkTap: _handleUrlTap,
        onLinkHover: _handleLinkHover,
        linkStyle: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.none,
        ),
        linkHoverStyle: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
        linkMouseCursor: SystemMouseCursors.click,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Use standard list constructor
            // --- Basic URL Example ---
            const ExampleCard(
              title: 'Basic URL',
              description: 'Simple URL using default styling from TextfOptions',
              code: '''
Textf(
  'Visit [Flutter website](https://flutter.dev) '
  'for more information,
)''',
              child: Textf(
                'Visit [Flutter website](https://flutter.dev) for more information',
              ),
            ),
            const SizedBox(height: 16),

            // --- URL with Hover Effect Example ---
            const ExampleCard(
              title: 'URL with Hover Effect',
              description: 'Demonstrates URL hover interaction (hover to see URL at bottom)',
              code: '''
TextfOptions(
  linkStyle: TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.none,
  ),
  linkHoverStyle: TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
    decorationColor: Colors.blue,
  ),
  child: Textf(
    'Hover over [this link](https://example.com) '
    'to see the effect',

  ),
)
''',
              child: TextfOptions(
                linkStyle: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.none,
                ),
                linkHoverStyle: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
                child: Textf(
                  'Hover over [this link](https://example.com) '
                  'to see the effect',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Multiple URLs Example ---
            const ExampleCard(
              title: 'Multiple URLs',
              description: 'Multiple URLs in a single text block',
              code: '''
Textf(
  'Visit [Flutter](https://flutter.dev) '
  'or [Dart](https://dart.dev) websites,
)''',
              child: Textf(
                'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev) websites',
              ),
            ),
            const SizedBox(height: 16),

            // --- Formatted URL Text Example ---
            const ExampleCard(
              // THIS SHOULD NOW WORK FOR CLICK TOO
              title: 'Formatted URL Text',
              description: 'URL display text with other formatting applied',
              code: '''
Textf(
  'Check out [**bold link**](https://example.com) '
  '[*italic link*](https://example.org)'
  'and [Link with ^*^](https://example.org)',
)''',
              child: Textf(
                'Check out [**bold link**](https://example.com) '
                '[*italic link*](https://example.org)'
                'and [Link with ^*^](https://example.org)',
              ),
            ),
            const SizedBox(height: 16),

            // --- Nested Formatting Example ---
            const ExampleCard(
              // THIS SHOULD NOW WORK FOR CLICK TOO
              title: 'Nested Formatting in URL Text',
              description: 'URL display text with nested formatting (bold > italic)',
              code: '''
Textf(
  'Link with [**nested _italic_ style**](https://example.net)',
)''',
              child: Textf(
                'Link with [**nested _italic_ style**](https://example.net)',
              ),
            ),
            const SizedBox(height: 16),

            // --- Email URL Example ---
            const ExampleCard(
              title: 'Email URL',
              description: 'URL with mailto: protocol',
              code: '''
Textf(
  'Contact [support](mailto:support@example.com) '
  'for assistance',
)''',
              child: Textf(
                'Contact [support](mailto:support@example.com) for assistance',
              ),
            ),
            const SizedBox(height: 16),

            // --- Special Characters Example ---
            const ExampleCard(
              title: 'URL with Special Characters',
              description: 'URL containing query parameters and fragments',
              code: '''
Textf(
  'Search for [Package Textf]'
  '(https://pub.dev/packages?q=textf+markdown#results)',
)''',
              child: Textf(
                'Search for [Package Textf]'
                '(https://pub.dev/packages?q=textf+markdown#results)',
              ),
            ),
            const SizedBox(height: 16),

            // --- Normalization Example ---
            const ExampleCard(
              title: 'URL Needing Normalization',
              description: 'URL without protocol (should get http:// added)',
              code: 'Textf(\n  \'Visit [Google](google.com)\',\n)',
              child: Textf(
                'Visit [Google](google.com)',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
