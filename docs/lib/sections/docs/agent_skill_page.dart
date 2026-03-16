// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/code_panel.dart';
import '/widgets/docs_pager.dart';
import '/widgets/section_header.dart';
import '../../router/docs_routes.dart';

/// AI Agent Skill documentation page.
class AgentSkillPage extends StatelessWidget {
  const AgentSkillPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'AI Agent Skill',
                subtitle: 'Give AI coding agents instant knowledge of Textf',
              ),
              const SizedBox(height: 32),
              _WhatIsItSection(cs: cs, theme: theme),
              const SizedBox(height: 32),
              _InstallSection(cs: cs, theme: theme),
              const SizedBox(height: 32),
              _WhatItKnowsSection(cs: cs, theme: theme),
              const SizedBox(height: 48),
              const DocsPager(current: DocsRoutes.agentSkill),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatIsItSection extends StatelessWidget {
  const _WhatIsItSection({required this.cs, required this.theme});

  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is pkg:skills?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        const Textf(
          '`pkg:skills` is a package that lets you install AI agent skills — '
          'structured knowledge files that give AI coding assistants deep understanding '
          "of a library's API, patterns, and best practices. Once installed, "
          'any compatible AI agent can use the skill to give you accurate, '
          'idiomatic suggestions without needing to read documentation itself.',
        ),
      ],
    );
  }
}

class _InstallSection extends StatelessWidget {
  const _InstallSection({required this.cs, required this.theme});

  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Installation', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        const Textf(
          'Once `textf` is a dependency in your project, activate `pkg:skills` globally '
          'and run `skills get`:',
        ),
        const SizedBox(height: 12),
        const CodePanel(code: 'dart pub global activate skills\nskills get'),
        const SizedBox(height: 12),
        TextfOptions(
          onLinkTap: (url, _) => launchUrl(Uri.parse(url)),
          child: const Textf(
            'See [pub.dev/packages/skills](https://pub.dev/packages/skills) for full setup and supported IDEs.',
          ),
        ),
      ],
    );
  }
}

class _WhatItKnowsSection extends StatelessWidget {
  const _WhatItKnowsSection({required this.cs, required this.theme});

  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What the skill covers', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _BulletItem(
          theme: theme,
          text: '**Formatting syntax** — all markers, flanking rules, nesting limits, and escaping',
        ),
        _BulletItem(
          theme: theme,
          text: '**`Textf` widget** — drop-in for `Text`, placeholders, caching, and extensions',
        ),
        _BulletItem(
          theme: theme,
          text:
              '**`TextfEditingController`** — live formatting in `TextField`, marker visibility modes',
        ),
        _BulletItem(
          theme: theme,
          text: '**`TextfOptions`** — style inheritance, link callbacks, script offset factors',
        ),
        _BulletItem(
          theme: theme,
          text: '**Best practices** — performance tips, when to use Textf, and common patterns',
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
          ),
          Expanded(child: Textf(text)),
        ],
      ),
    );
  }
}
