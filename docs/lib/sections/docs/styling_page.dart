import 'package:flutter/material.dart';

import '/sections/styling/styling_section.dart';
import '/widgets/docs_pager.dart';
import '../../router/docs_routes.dart';

/// Styling documentation page — wraps the existing StylingSection.
class StylingPage extends StatelessWidget {
  const StylingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          StylingSection(),
          SizedBox(height: 48),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: DocsPager(current: DocsRoutes.styling),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
