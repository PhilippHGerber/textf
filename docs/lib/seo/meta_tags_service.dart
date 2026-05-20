import 'package:universal_web/web.dart' as web;

import 'page_meta.dart';
import 'route_meta.dart';

/// Updates the HTML document's SEO meta tags for the current route.
///
/// Call [updateForRoute] from a router listener in `main()` so that every
/// navigation updates the page title, description, canonical URL, Open Graph
/// tags, and Twitter Card tags in place.
abstract final class MetaTagsService {
  /// Updates all meta tags to reflect the page registered for [path].
  static void updateForRoute(String path) => _apply(RouteMeta.forRoute(path));

  static void _apply(PageMeta meta) {
    web.document.title = meta.fullTitle;
    _setContent('meta-description', meta.description);
    _setHref('canonical-link', meta.canonicalUrl);
    _setContent('og-title', meta.fullTitle);
    _setContent('og-description', meta.description);
    _setContent('og-url', meta.canonicalUrl);
    _setContent('twitter-title', meta.fullTitle);
    _setContent('twitter-description', meta.description);
  }

  static void _setContent(String id, String value) =>
      web.document.getElementById(id)?.setAttribute('content', value);

  static void _setHref(String id, String value) =>
      web.document.getElementById(id)?.setAttribute('href', value);
}
