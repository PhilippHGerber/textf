import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../sections/docs/agent_skill_page.dart';
import '../sections/docs/editing_controller_page.dart';
import '../sections/docs/format_page.dart';
import '../sections/docs/overview_page.dart';
import '../sections/docs/quickstart_page.dart';
import '../sections/docs/styling_page.dart';
import '../sections/docs/widgets_page.dart';
import '../sections/editor/editor_section.dart';
import '../sections/home_section.dart';
import '../shell/playground_shell.dart';
import 'docs_routes.dart';

Page<void> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final appRouter = GoRouter(
  initialLocation: DocsRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          PlaygroundShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const HomeSection()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/docs',
              redirect: (_, __) => DocsRoutes.overview,
            ),
            GoRoute(
              path: '/docs/overview',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const OverviewPage()),
            ),
            GoRoute(
              path: '/docs/quickstart',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const QuickstartPage()),
            ),
            GoRoute(
              path: '/docs/formatting',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const FormatPage()),
            ),
            GoRoute(
              path: '/docs/placeholders',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const WidgetsPage()),
            ),
            GoRoute(
              path: '/docs/styling',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const StylingPage()),
            ),
            GoRoute(
              path: '/docs/text-field',
              pageBuilder: (context, state) => _buildPageWithTransition(
                context,
                state,
                const EditingControllerPage(),
              ),
            ),
            GoRoute(
              path: '/docs/agent-skill',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const AgentSkillPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/editor',
              pageBuilder: (context, state) =>
                  _buildPageWithTransition(context, state, const EditorSection()),
            ),
          ],
        ),
      ],
    ),
  ],
);
