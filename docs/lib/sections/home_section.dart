// ignore_for_file: no-magic-number

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/docs_routes.dart';
import '../widgets/example_carousel.dart';
import '../widgets/feature_card.dart';
import '../widgets/section_header.dart';
import '../widgets/title_animation.dart';

/// Home section — hero + content landing page.
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroSection(
            onLaunchUrl: _launchUrl,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),
                    SectionHeader(
                      title: 'See It In Action',
                      subtitle: 'Live formatting as you type',
                    ),
                    SizedBox(height: 24),
                    TitleAnimation(),
                    SizedBox(height: 80),
                    SectionHeader(
                      title: 'Two Drop-in Replacements',
                      subtitle: 'Swap one class name — get formatting for free',
                    ),
                    SizedBox(height: 24),
                    _FeatureCardsRow(),
                    SizedBox(height: 80),
                    SectionHeader(
                      title: 'Formatting Showcase',
                      subtitle: 'Everything Textf can render',
                    ),
                    SizedBox(height: 24),
                    ExampleCarousel(),
                    SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onLaunchUrl,
  });

  final Future<void> Function(String) onLaunchUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final heroHeight = math.max(size.height / 2, 420).toDouble();

    final builtWithText = Textf(
      'Built with {flutter} and {dart}. Made with {love}.',
      placeholders: {
        'flutter': WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset('assets/img/flutter.png', height: 16),
        ),
        'dart': WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset('assets/img/dart.png', height: 16),
        ),
        'love': WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.favorite, color: Colors.pink[300], size: 18),
        ),
      },
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.88),
      ),
      textAlign: TextAlign.center,
    );

    final isDark = theme.brightness == Brightness.dark;
    final gradientStart = isDark ? cs.primaryContainer : cs.primary;
    final gradientEnd = isDark ? cs.primaryContainer : cs.primary.withValues(alpha: 0.8);

    return Container(
      constraints: BoxConstraints(minHeight: heroHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientStart,
            Color.lerp(gradientStart, gradientEnd, 0.55) ?? gradientStart,
            gradientEnd,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -80,
            right: -100,
            child: _Blob(size: 350, color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.18)),
          ),
          Positioned(
            bottom: 20,
            left: -120,
            child: _Blob(size: 300, color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.12)),
          ),
          Positioned(
            top: heroHeight * 0.3,
            left: 40,
            child: _Blob(size: 140, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 20,
            left: size.width * 0.4,
            child: _Blob(size: 80, color: Colors.white.withValues(alpha: 0.08)),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 80),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: heroHeight * 0.08),
                  Text(
                    'Textf',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 72,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextfOptions(
                    codeStyle: const TextStyle(
                      fontFamily: 'Roboto Mono',
                    ),
                    child: Textf(
                      'Markdown-like inline formatting. Drop-in for `Text()`.',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _Badge(label: 'Zero deps', icon: Icons.check_circle_outline),
                      _Badge(label: 'O(N) parser', icon: Icons.speed),
                      _Badge(label: 'Drop-in', icon: Icons.swap_horiz),
                      _Badge(label: 'Live editing', icon: Icons.edit),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => onLaunchUrl('https://pub.dev/packages/textf'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.onPrimary.withValues(alpha: 0.85),
                          foregroundColor: cs.primary,
                        ),
                        icon: Image.asset('assets/img/pub-dev.png', height: 20, color: cs.primary),
                        label: const Text('pub.dev'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onLaunchUrl('https://github.com/PhilippHGerber/textf'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        icon: ColorFiltered(
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          child: Image.asset('assets/img/github.png', height: 18),
                        ),
                        label: const Text('GitHub'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => context.go(DocsRoutes.editor),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Live Editor →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // full width with dark overlay for better contrast
              // margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
              ),
              child: Center(child: builtWithText),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardsRow extends StatelessWidget {
  const _FeatureCardsRow();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    const cardA = FeatureCard(
      icon: Icons.text_fields,
      title: '`Textf` Widget',
      description: 'Replace `Text` with `Textf` — your strings render with **bold**, *italic*, '
          '`code`, ==highlights==, [links](.), and more.',
    );
    const cardB = FeatureCard(
      icon: Icons.edit_outlined,
      title: '`TextfEditingController`',
      description: 'Replace `TextEditingController` to render formatting live in `TextField` '
          'as the user types — _no extra widgets needed_.',
    );
    const cardC = FeatureCard(
      icon: Icons.palette_outlined,
      title: '`TextfOptions`',
      description: 'Hierarchical style configuration via `InheritedWidget`. '
          'Override **bold**, *italic*, `code` styles per subtree.',
    );

    if (isWide) {
      return const IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cardA),
            SizedBox(width: 16),
            Expanded(child: cardB),
            SizedBox(width: 16),
            Expanded(child: cardC),
          ],
        ),
      );
    }
    return const Column(
      children: [
        cardA,
        SizedBox(height: 16),
        cardB,
        SizedBox(height: 16),
        cardC,
      ],
    );
  }
}
