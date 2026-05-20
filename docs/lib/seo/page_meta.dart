/// Immutable metadata for a single page/route.
final class PageMeta {
  /// Creates a [PageMeta] with the given [title], [description], and optional
  /// [canonicalPath].
  const PageMeta({
    required this.title,
    required this.description,
    this.canonicalPath,
  });

  /// The page title (without site name suffix).
  final String title;

  /// The page description used for SEO meta tags.
  final String description;

  /// The canonical URL path (e.g. `/docs/quickstart`). Defaults to `""` when
  /// null, which resolves to the site root.
  final String? canonicalPath;

  static const String _baseUrl = 'https://textf.philippgerber.li';
  static const String _siteName = 'Textf Docs';

  /// Returns the full title with the site name appended (e.g.
  /// `"Quickstart | Textf Docs"`).
  String get fullTitle => '$title | $_siteName';

  /// Returns the absolute canonical URL for this page.
  String get canonicalUrl => '$_baseUrl${canonicalPath ?? ""}';
}
