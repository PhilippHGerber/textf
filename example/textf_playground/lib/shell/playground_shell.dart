// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/sections/editor/editor_section.dart';
import '/sections/formats/formats_section.dart';
import '/sections/links_widgets/links_widgets_section.dart';
import '/sections/real_world/real_world_section.dart';
import '/sections/styling/styling_section.dart';

class PlaygroundShell extends StatefulWidget {
  const PlaygroundShell({
    required this.currentThemeMode,
    required this.toggleThemeMode,
    super.key,
  });

  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  @override
  State<PlaygroundShell> createState() => _PlaygroundShellState();
}

class _PlaygroundShellState extends State<PlaygroundShell> {
  int _selectedIndex = 0;

  static const _labels = [
    'Formats',
    'Links & Widgets',
    'Styling',
    'Live Editor',
    'Real-World',
  ];

  static const List<IconData> _icons = [
    Icons.format_bold,
    Icons.link,
    Icons.palette_outlined,
    Icons.edit_note,
    Icons.apps_outlined,
  ];

  static const _wideBreakpoint = 600.0;
  static const _extendedBreakpoint = 800.0;

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final brightness = theme.brightness;
    final themeIcon =
        brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    return AppBar(
      title: const Textf('**Textf** Playground'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: ColorFiltered(
            colorFilter: ColorFilter.mode(
              theme.colorScheme.onSurface,
              BlendMode.srcIn,
            ),
            child: Image.asset('assets/img/pub-dev.png', height: 20),
          ),
          tooltip: 'pub.dev',
          onPressed: () => _launchUrl('https://pub.dev/packages/textf'),
        ),
        IconButton(
          icon: ColorFiltered(
            colorFilter: ColorFilter.mode(
              theme.colorScheme.onSurface,
              BlendMode.srcIn,
            ),
            child: Image.asset('assets/img/github.png', height: 20),
          ),
          tooltip: 'GitHub',
          onPressed: () => _launchUrl('https://github.com/PhilippHGerber/textf'),
        ),
        IconButton(
          icon: Icon(themeIcon),
          tooltip: 'Toggle Theme',
          onPressed: widget.toggleThemeMode,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wideBreakpoint;
    final isExtended = width >= _extendedBreakpoint;

    final body = IndexedStack(
      index: _selectedIndex,
      children: [
        const FormatsSection(),
        const LinksWidgetsSection(),
        const StylingSection(),
        EditorSection(
          currentThemeMode: widget.currentThemeMode,
          toggleThemeMode: widget.toggleThemeMode,
        ),
        const RealWorldSection(),
      ],
    );

    final railDestinations = List<NavigationRailDestination>.generate(
      _labels.length,
      (i) => NavigationRailDestination(
        icon: Icon(_icons[i]),
        label: Text(_labels[i]),
      ),
    );

    final navDestinations = List<NavigationDestination>.generate(
      _labels.length,
      (i) => NavigationDestination(
        icon: Icon(_icons[i]),
        label: _labels[i],
      ),
    );

    if (isWide) {
      return Scaffold(
        appBar: _buildAppBar(theme),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: isExtended,
              destinations: railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: navDestinations,
      ),
    );
  }
}
