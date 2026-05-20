import '../router/docs_routes.dart';
import 'page_meta.dart';

/// Maps application routes to their [PageMeta] descriptors.
///
/// Call [forRoute] to retrieve the metadata for a given route path. If no
/// entry exists for the path, a sensible fallback is returned.
abstract final class RouteMeta {
  static const _fallback = PageMeta(
    title: 'Textf – Flutter Text Formatting Widget',
    description:
        "A drop-in replacement for Flutter's Text widget with markdown-like inline formatting. "
        'Supports bold, italic, code, links, highlights, super/subscript, strikethrough, '
        'underline, and widget placeholders with zero dependencies.',
  );

  static const Map<String, PageMeta> _data = {
    DocsRoutes.home: PageMeta(
      title: 'Textf – Flutter Text Formatting Widget',
      description:
          "Textf is a drop-in replacement for Flutter's Text widget with markdown-like inline "
          'formatting. Supports bold, italic, code, links, highlights, super/subscript, '
          'strikethrough, underline, and widget placeholders — zero dependencies.',
      canonicalPath: DocsRoutes.home,
    ),
    DocsRoutes.quickstart: PageMeta(
      title: 'Quickstart – Textf Docs',
      description:
          'Get started with Textf in three steps: add the dependency, replace Text with Textf, '
          'and use markdown-like syntax to format your Flutter text. No configuration required.',
      canonicalPath: DocsRoutes.quickstart,
    ),
    DocsRoutes.overview: PageMeta(
      title: 'Overview – Textf Docs',
      description:
          'An overview of the Textf Flutter package: architecture, rendering pipeline, style '
          'resolution, caching strategy, and how Textf fits into your Flutter app as a '
          'zero-dependency Text replacement.',
      canonicalPath: DocsRoutes.overview,
    ),
    DocsRoutes.formatting: PageMeta(
      title: 'Formatting – Textf Docs',
      description: 'Complete reference for Textf inline formatting syntax: bold (**text**), italic '
          '(_text_), code (`text`), strikethrough (~~text~~), underline (__text__, highlight '
          '(==text==), superscript (^text^), subscript (~text~), and links ([label](url)).',
      canonicalPath: DocsRoutes.formatting,
    ),
    DocsRoutes.placeholders: PageMeta(
      title: 'Placeholders – Textf Docs',
      description: "Embed arbitrary Flutter widgets inline inside formatted text using Textf's "
          '{key} placeholder syntax. Pass a map of InlineSpan builders to TextfOptions to '
          'replace placeholders with icons, images, or any widget.',
      canonicalPath: DocsRoutes.placeholders,
    ),
    DocsRoutes.styling: PageMeta(
      title: 'Styling – Textf Docs',
      description:
          'Customize the appearance of every Textf format token — bold, italic, code, links, '
          'and more — using TextfOptions. Styles cascade through the widget tree and merge '
          "with Flutter's Theme for consistent, theme-aware text formatting.",
      canonicalPath: DocsRoutes.styling,
    ),
    DocsRoutes.textField: PageMeta(
      title: 'Text Field – Textf Docs',
      description: 'Add live inline formatting to Flutter text fields with TextfEditingController. '
          'Formatting markers are rendered with applied styles as the user types, giving '
          'a rich-text editing experience without a heavyweight editor dependency.',
      canonicalPath: DocsRoutes.textField,
    ),
    DocsRoutes.agentSkill: PageMeta(
      title: 'Agent Skill – Textf Docs',
      description:
          'Use the Textf Claude Code agent skill to generate and refine Textf-formatted strings '
          'directly from your IDE. The skill understands Textf syntax and style options, '
          'helping you write correctly formatted text faster.',
      canonicalPath: DocsRoutes.agentSkill,
    ),
    DocsRoutes.editor: PageMeta(
      title: 'Live Editor – Textf Docs',
      description:
          'Try Textf formatting live in the browser. Write markdown-like syntax and see the '
          'rendered output instantly — a quick way to explore bold, italic, code, links, '
          'highlights, and all other Textf format tokens.',
      canonicalPath: DocsRoutes.editor,
    ),
  };

  /// Returns the [PageMeta] registered for [path], or a generic fallback if
  /// the path is not mapped.
  static PageMeta forRoute(String path) => _data[path] ?? _fallback;
}
