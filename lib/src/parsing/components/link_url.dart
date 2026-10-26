/// Normalizes a link URL so that it is launchable.
///
/// Trims surrounding whitespace, then keeps URLs that already carry a scheme
/// (`https:`, `mailto:`, `tel:`, `file:`, custom schemes), `#` anchors and `/`
/// relative paths unchanged. Anything else is treated as a web address and
/// gets `https://` prepended. Blank input normalizes to the empty string.
String normalizeUrl(String url) {
  final String trimmed = url.trim();

  if (trimmed.isEmpty) return trimmed;
  if (_hasScheme(trimmed)) return trimmed;
  if (trimmed.startsWith('#') || trimmed.startsWith('/')) return trimmed;

  return 'https://$trimmed';
}

/// Whether [url] starts with a URI scheme: a colon that appears before any
/// `/`, `?` or `#` (so `google.com/foo:bar` has none, `mailto:user` has one).
bool _hasScheme(String url) {
  final int colonIndex = url.indexOf(':');
  if (colonIndex == -1) return false;

  for (final String delimiter in const ['/', '?', '#']) {
    final int delimiterIndex = url.indexOf(delimiter);
    if (delimiterIndex != -1 && colonIndex > delimiterIndex) return false;
  }

  return true;
}
