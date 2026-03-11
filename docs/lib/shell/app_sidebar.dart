// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/docs_routes.dart' show DocsRoutes;
import '../theme/theme_mode_notifier.dart';

/// Desktop sidebar (240px wide) for the Textf Playground.
///
/// Shows the logo, primary navigation (Home, Docs, Live Editor),
/// expandable Docs sub-items, and bottom action buttons.
class AppSidebar extends StatefulWidget {
  const AppSidebar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _sidebarWidth = 240.0;

  static const List<String> _docsSubRoutes = [
    DocsRoutes.overview,
    DocsRoutes.quickstart,
    DocsRoutes.formatting,
    DocsRoutes.placeholders,
    DocsRoutes.styling,
    DocsRoutes.textField,
  ];

  static const _docsSubLabels = [
    'Overview',
    'Quickstart',
    'Formatting',
    'Placeholders',
    'Styling',
    'TextField',
  ];

  static const List<IconData> _docsSubIcons = [
    Icons.info_outline,
    Icons.rocket_launch_outlined,
    Icons.format_bold,
    Icons.widgets_outlined,
    Icons.palette_outlined,
    Icons.edit_note,
  ];

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.path;

    final isHome = currentPath == DocsRoutes.home;
    final isDocs = currentPath.startsWith('/docs');
    final isEditor = currentPath == DocsRoutes.editor;

    return SizedBox(
      width: _sidebarWidth,
      child: ColoredBox(
        color: cs.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(context, theme, cs),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    selected: isHome,
                    onTap: () => context.go(DocsRoutes.home),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Docs',
                    selected: isDocs,
                    trailing: AnimatedRotation(
                      turns: isDocs ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 18),
                    ),
                    onTap: () {
                      if (!isDocs) {
                        context.go(DocsRoutes.overview);
                      }
                    },
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isDocs ? _docsSubLabels.length * 40.0 : 0,
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: _docsSubLabels.length * 40.0,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: List.generate(_docsSubLabels.length, (i) {
                            return _SubNavItem(
                              icon: _docsSubIcons[i],
                              label: _docsSubLabels[i],
                              selected: currentPath == _docsSubRoutes[i],
                              onTap: () => context.go(_docsSubRoutes[i]),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.edit_note,
                    label: 'Live Editor',
                    selected: isEditor,
                    trailing: _NewBadge(),
                    onTap: () => context.go(DocsRoutes.editor),
                  ),
                ],
              ),
            ),
            _buildBottomActions(context, cs, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ThemeData theme, ColorScheme cs) {
    return InkWell(
      onTap: () => context.go(DocsRoutes.home),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Textf(
              '**Textf**',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'for Flutter',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ColorScheme cs, bool isDark) {
    final themeNotifier = ThemeModeNotifier.of(context);

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
                  child: Image.asset('assets/img/pub-dev.png', height: 20),
                ),
                tooltip: 'pub.dev',
                onPressed: () => _launchUrl('https://pub.dev/packages/textf'),
              ),
              IconButton(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
                  child: Image.asset('assets/img/github.png', height: 20),
                ),
                tooltip: 'GitHub',
                onPressed: () => _launchUrl('https://github.com/PhilippHGerber/textf'),
              ),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: 'Toggle theme',
                onPressed: () {
                  themeNotifier.value =
                      themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (trailing case final t?) t,
          ],
        ),
      ),
    );
  }
}

class _SubNavItem extends StatelessWidget {
  const _SubNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.only(left: 32, right: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer.withValues(alpha: 0.4) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
