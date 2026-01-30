// Tests for LinkHandler edge cases in URL normalization and processing.

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/components/link_handler.dart';

void main() {
  group('LinkHandler URL Edge Cases', () {
    group('normalizeUrl additional cases', () {
      // test('handles URLs with port numbers', () {
      // not supported
      // expect(
      //   LinkHandler.normalizeUrl('localhost:8080'),
      //   'https://localhost:8080',
      // );
      //});

      test('handles URLs with query parameters', () {
        expect(
          LinkHandler.normalizeUrl('example.com?q=search'),
          'https://example.com?q=search',
        );
      });

      test('handles file protocol', () {
        expect(
          LinkHandler.normalizeUrl('file:///path/to/file'),
          'file:///path/to/file',
        );
      });

      test('handles custom protocols', () {
        expect(
          LinkHandler.normalizeUrl('myapp://deeplink'),
          'myapp://deeplink',
        );
      });

      test('handles URL-encoded characters', () {
        final result = LinkHandler.normalizeUrl('example.com/path%20with%20spaces');
        expect(result, 'https://example.com/path%20with%20spaces');
      });

      test('handles international domain names', () {
        final result = LinkHandler.normalizeUrl('例え.jp');
        expect(result, 'https://例え.jp');
      });

      test('handles whitespace-only string', () {
        expect(LinkHandler.normalizeUrl('   '), '');
      });
    });
  });
}
