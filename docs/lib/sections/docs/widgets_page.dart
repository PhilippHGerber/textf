import 'package:flutter/material.dart';

import '/sections/links_widgets/widgets_tab.dart';
import '/widgets/docs_pager.dart';
import '../../router/docs_routes.dart';

/// Widget placeholders documentation page — wraps the existing WidgetsTab.
class WidgetsPage extends StatelessWidget {
  const WidgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WidgetsTab(),
              SizedBox(height: 48),
              DocsPager(current: DocsRoutes.placeholders),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
