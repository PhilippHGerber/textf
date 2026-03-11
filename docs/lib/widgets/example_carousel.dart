// ignore_for_file: no-magic-number

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

/// A carousel that auto-advances through formatting examples every 3 seconds.
///
/// Shows a [PageView] with code + live Textf preview pairs and page indicator dots.
class ExampleCarousel extends StatefulWidget {
  const ExampleCarousel({super.key});

  @override
  State<ExampleCarousel> createState() => _ExampleCarouselState();
}

class _ExampleCarouselState extends State<ExampleCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  static const _autoAdvanceDuration = Duration(seconds: 3);

  static const List<({String label, String code})> _examples = [
    (
      label: 'Bold, italic & code',
      code: '**Bold**, *italic*, `code`',
    ),
    (
      label: 'Links',
      code: '[Flutter](https://flutter.dev)',
    ),
    (
      label: 'Highlight & underline',
      code: '==highlight== and ++underline++',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(_autoAdvanceDuration, (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _examples.length;
      unawaited(
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _examples.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final example = _examples[index];
              return AnimatedOpacity(
                opacity: _currentPage == index ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        example.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        example.code,
                        style: const TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextfOptions(
                        onLinkTap: (url, _) => _launchUrl(url),
                        child: Textf(
                          example.code,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_examples.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
