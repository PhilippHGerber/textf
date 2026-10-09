import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/styling/link_style_configuration.dart';

void main() {
  group('LinkStyleConfiguration', () {
    const style1 = TextStyle(color: Color(0xFF1A73E8), decoration: TextDecoration.underline);
    const style2 = TextStyle(color: Color(0xFF000000));
    const hoverStyle1 = TextStyle(color: Color(0xFFE91E63));
    const hoverStyle2 = TextStyle(color: Color(0xFF1A73E8));
    const cursor1 = SystemMouseCursors.click;
    const cursor2 = SystemMouseCursors.text;
    const alignment1 = PlaceholderAlignment.baseline;
    const alignment2 = PlaceholderAlignment.middle;

    void onTap1(String url, String displayText) {}
    void onTap2(String url, String displayText) {}
    void onHover1(String url, String displayText, {required bool isHovering}) {}
    void onHover2(String url, String displayText, {required bool isHovering}) {}

    test('stores and exposes all configuration fields', () {
      final config = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );

      expect(config.style, style1);
      expect(config.hoverStyle, hoverStyle1);
      expect(config.cursor, cursor1);
      expect(config.onTap, onTap1);
      expect(config.onHover, onHover1);
      expect(config.alignment, alignment1);
    });

    test('allows null onTap and onHover callbacks', () {
      const config = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        alignment: alignment1,
      );

      expect(config.onTap, isNull);
      expect(config.onHover, isNull);
    });

    test('value equality and hashCode', () {
      final config1 = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );
      final config2 = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );
      final configDiffStyle = LinkStyleConfiguration(
        style: style2,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );
      final configDiffHoverStyle = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle2,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );
      final configDiffCursor = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor2,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment1,
      );
      final configDiffOnTap = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap2,
        onHover: onHover1,
        alignment: alignment1,
      );
      final configDiffOnHover = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover2,
        alignment: alignment1,
      );
      final configDiffAlignment = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        onTap: onTap1,
        onHover: onHover1,
        alignment: alignment2,
      );
      const configNullCallbacks = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        alignment: alignment1,
      );

      // Equality
      expect(config1, equals(config2));
      expect(config1 == config2, isTrue);
      expect(config1.hashCode, equals(config2.hashCode));

      // Inequity across each property
      expect(config1 == configDiffStyle, isFalse);
      expect(config1 == configDiffHoverStyle, isFalse);
      expect(config1 == configDiffCursor, isFalse);
      expect(config1 == configDiffOnTap, isFalse);
      expect(config1 == configDiffOnHover, isFalse);
      expect(config1 == configDiffAlignment, isFalse);
      expect(config1 == configNullCallbacks, isFalse);
      expect(config1 == Object(), isFalse);
    });

    test('toString includes all fields', () {
      const config = LinkStyleConfiguration(
        style: style1,
        hoverStyle: hoverStyle1,
        cursor: cursor1,
        alignment: alignment1,
      );

      final str = config.toString();
      expect(str, startsWith('LinkStyleConfiguration('));
      expect(str, contains('style: $style1'));
      expect(str, contains('hoverStyle: $hoverStyle1'));
      expect(str, contains('cursor: $cursor1'));
      expect(str, contains('onTap: null'));
      expect(str, contains('onHover: null'));
      expect(str, contains('alignment: $alignment1'));
    });
  });
}
