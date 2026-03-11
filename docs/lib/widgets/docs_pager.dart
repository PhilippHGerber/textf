import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/docs_routes.dart';

class DocsPager extends StatelessWidget {
  const DocsPager({required this.current, super.key});

  final String current;

  static const _spacing = 16.0;
  static const _verticalPadding = 32.0;
  static const List<({String route, String label})> _pages = [
    (route: DocsRoutes.overview, label: 'Overview'),
    (route: DocsRoutes.quickstart, label: 'Quickstart'),
    (route: DocsRoutes.formatting, label: 'Formatting'),
    (route: DocsRoutes.placeholders, label: 'Placeholders'),
    (route: DocsRoutes.styling, label: 'Styling'),
    (route: DocsRoutes.textField, label: 'TextField'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _pages.indexWhere((p) => p.route == current);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < _pages.length - 1;

    final prevRoute = hasPrev ? _pages[currentIndex - 1].route : null;
    final prevLabel = hasPrev ? _pages[currentIndex - 1].label : null;
    final nextRoute = hasNext ? _pages[currentIndex + 1].route : null;
    final nextLabel = hasNext ? _pages[currentIndex + 1].label : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _verticalPadding,
        horizontal: _spacing,
      ),
      child: Row(
        children: [
          Expanded(
            child: hasPrev && prevRoute != null && prevLabel != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go(prevRoute),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text('Previous: $prevLabel'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: hasNext && nextRoute != null && nextLabel != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.go(nextRoute),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text('Next: $nextLabel'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
