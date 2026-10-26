import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/components/link_validator.dart';

void main() {
  group('normalizeUrl', () {
    test('adds https:// to URLs without a scheme', () {
      expect(normalizeUrl('example.com'), 'https://example.com');
    });

    test('does not modify URLs that already have a scheme (https)', () {
      expect(normalizeUrl('https://example.com'), 'https://example.com');
    });

    test('does not modify URLs that already have a scheme (ftp)', () {
      expect(normalizeUrl('ftp://example.com'), 'ftp://example.com');
    });

    test('does not modify URLs that already have a scheme (mailto)', () {
      expect(normalizeUrl('mailto:test@example.com'), 'mailto:test@example.com');
    });

    test('does not modify URLs that already have a scheme (tel)', () {
      expect(normalizeUrl('tel:+1234567890'), 'tel:+1234567890');
    });

    test('does not modify relative paths', () {
      expect(normalizeUrl('/path/to/page'), '/path/to/page');
    });

    test('does not modify anchor links', () {
      expect(normalizeUrl('#section1'), '#section1');
    });

    test('trims whitespace from URLs', () {
      expect(normalizeUrl('  example.com  '), 'https://example.com');
    });

    test('handles empty strings', () {
      expect(normalizeUrl(''), '');
    });

    group('edge cases', () {
      test('handles URLs with query parameters', () {
        expect(normalizeUrl('example.com?q=search'), 'https://example.com?q=search');
      });

      test('handles file protocol', () {
        expect(normalizeUrl('file:///path/to/file'), 'file:///path/to/file');
      });

      test('handles custom protocols', () {
        expect(normalizeUrl('myapp://deeplink'), 'myapp://deeplink');
      });

      test('handles URL-encoded characters', () {
        expect(
          normalizeUrl('example.com/path%20with%20spaces'),
          'https://example.com/path%20with%20spaces',
        );
      });

      test('handles international domain names', () {
        expect(normalizeUrl('例え.jp'), 'https://例え.jp');
      });

      test('handles whitespace-only string', () {
        expect(normalizeUrl('   '), '');
      });
    });
  });
}
