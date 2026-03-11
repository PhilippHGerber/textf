// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme_mode_notifier.dart';
import 'app_sidebar.dart';

class PlaygroundShell extends StatelessWidget {
  const PlaygroundShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _mobileBreakpoint = 600.0;
  static const _desktopBreakpoint = 1024.0;

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final themeNotifier = ThemeModeNotifier.of(context);

    return AppBar(
      title: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => navigationShell.goBranch(0),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Textf('**Textf**'),
        ),
      ),
      centerTitle: true,
      actions: [
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
          tooltip: 'Toggle Theme',
          onPressed: () {
            themeNotifier.value =
                themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    // Desktop: sidebar + content, no AppBar
    if (width >= _desktopBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(navigationShell: navigationShell),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Tablet: AppBar + Drawer + body
    if (width >= _mobileBreakpoint) {
      return Scaffold(
        appBar: _buildAppBar(context, theme),
        drawer: Drawer(child: AppSidebar(navigationShell: navigationShell)),
        body: navigationShell,
      );
    }

    // Mobile: AppBar + Drawer + BottomNavigationBar
    return Scaffold(
      appBar: _buildAppBar(context, theme),
      drawer: Drawer(child: AppSidebar(navigationShell: navigationShell)),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Editor'),
        ],
      ),
    );
  }
}
