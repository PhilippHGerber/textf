// ignore_for_file: prefer-match-file-name, avoid-top-level-members-in-tests
// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/marker_render_mode.dart';
import 'package:textf/src/editing/marker_visibility.dart';
import 'package:textf/src/editing/textf_editing_controller.dart';

void main() {
  group('MarkerRenderMode', () {
    group('always', () {
      test('is a MarkerRenderModeAlways', () {
        const mode = MarkerRenderMode.always;
        expect(mode, isA<MarkerRenderModeAlways>());
      });

      test('equality and hashCode', () {
        const mode1 = MarkerRenderMode.always;
        const mode2 = MarkerRenderModeAlways();
        expect(mode1, equals(mode2));
        expect(mode1.hashCode, equals(mode2.hashCode));
        expect(mode1, isNot(equals(MarkerRenderMode.hidden)));
        expect(mode1, isNot(equals(const MarkerRenderMode.active(0))));
      });

      test('toString', () {
        expect(MarkerRenderMode.always.toString(), 'MarkerRenderMode.always');
      });
    });

    group('active', () {
      test('is a MarkerRenderModeActive with cursor position', () {
        const mode = MarkerRenderMode.active(5);
        expect(mode, isA<MarkerRenderModeActive>());
        expect((mode as MarkerRenderModeActive).cursorPosition, 5);
      });

      test('equality and hashCode', () {
        const mode1 = MarkerRenderMode.active(5);
        const mode2 = MarkerRenderModeActive(5);
        const mode3 = MarkerRenderMode.active(6);
        expect(mode1, equals(mode2));
        expect(mode1.hashCode, equals(mode2.hashCode));
        expect(mode1, isNot(equals(mode3)));
        expect(mode1, isNot(equals(MarkerRenderMode.always)));
        expect(mode1, isNot(equals(MarkerRenderMode.hidden)));
      });

      test('toString', () {
        expect(const MarkerRenderMode.active(5).toString(), 'MarkerRenderMode.active(5)');
      });
    });

    group('hidden', () {
      test('is a MarkerRenderModeHidden', () {
        const mode = MarkerRenderMode.hidden;
        expect(mode, isA<MarkerRenderModeHidden>());
      });

      test('equality and hashCode', () {
        const mode1 = MarkerRenderMode.hidden;
        const mode2 = MarkerRenderModeHidden();
        expect(mode1, equals(mode2));
        expect(mode1.hashCode, equals(mode2.hashCode));
        expect(mode1, isNot(equals(MarkerRenderMode.always)));
        expect(mode1, isNot(equals(const MarkerRenderMode.active(0))));
      });

      test('toString', () {
        expect(MarkerRenderMode.hidden.toString(), 'MarkerRenderMode.hidden');
      });
    });

    test('exhaustive pattern matching', () {
      String describe(MarkerRenderMode mode) => switch (mode) {
        MarkerRenderModeAlways() => 'always',
        MarkerRenderModeActive(:final cursorPosition) => 'active at $cursorPosition',
        MarkerRenderModeHidden() => 'hidden',
      };

      expect(describe(MarkerRenderMode.always), 'always');
      expect(describe(const MarkerRenderMode.active(12)), 'active at 12');
      expect(describe(MarkerRenderMode.hidden), 'hidden');
    });

    group('isActiveInRange', () {
      test('always is active for any range', () {
        const mode = MarkerRenderMode.always;
        expect(mode.isActiveInRange(0, 10), isTrue);
        expect(mode.isActiveInRange(5, 5), isTrue);
        expect(mode.isActiveInRange(100, 200), isTrue);
      });

      test('hidden is inactive for any range', () {
        const mode = MarkerRenderMode.hidden;
        expect(mode.isActiveInRange(0, 10), isFalse);
        expect(mode.isActiveInRange(5, 5), isFalse);
        expect(mode.isActiveInRange(100, 200), isFalse);
      });

      test('active is active only when cursorPosition is within range', () {
        const mode = MarkerRenderMode.active(5);
        expect(mode.isActiveInRange(5, 10), isTrue);
        expect(mode.isActiveInRange(0, 5), isTrue);
        expect(mode.isActiveInRange(3, 7), isTrue);
        expect(mode.isActiveInRange(5, 5), isTrue);
        expect(mode.isActiveInRange(6, 10), isFalse);
        expect(mode.isActiveInRange(0, 4), isFalse);
      });
    });

    group('MarkerRenderMode.fromVisibility', () {
      test('returns always when markerVisibility is always regardless of selection', () {
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.always,
            selection: const TextSelection.collapsed(offset: 5),
          ),
          equals(MarkerRenderMode.always),
        );
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.always,
            selection: const TextSelection(baseOffset: 2, extentOffset: 5),
          ),
          equals(MarkerRenderMode.always),
        );
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.always,
            selection: const TextSelection.collapsed(offset: -1),
          ),
          equals(MarkerRenderMode.always),
        );
      });

      test('returns active when markerVisibility is whenActive and selection is collapsed', () {
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection.collapsed(offset: 8),
          ),
          equals(const MarkerRenderMode.active(8)),
        );
      });

      test('returns hidden when markerVisibility is whenActive and selection is not collapsed', () {
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection(baseOffset: 2, extentOffset: 8),
          ),
          equals(MarkerRenderMode.hidden),
        );
      });

      test('returns hidden when markerVisibility is whenActive and selection is invalid', () {
        expect(
          MarkerRenderMode.fromVisibility(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection.collapsed(offset: -1),
          ),
          equals(MarkerRenderMode.hidden),
        );
      });
    });

    group('TextfEditingController.computeRenderMode', () {
      test('returns always when markerVisibility is always regardless of selection', () {
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.always,
            selection: const TextSelection.collapsed(offset: 5),
          ),
          equals(MarkerRenderMode.always),
        );
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.always,
            selection: const TextSelection(baseOffset: 2, extentOffset: 5),
          ),
          equals(MarkerRenderMode.always),
        );
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.always,
            selection: const TextSelection.collapsed(offset: -1),
          ),
          equals(MarkerRenderMode.always),
        );
      });

      test('returns active when markerVisibility is whenActive and selection is collapsed', () {
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection.collapsed(offset: 8),
          ),
          equals(const MarkerRenderMode.active(8)),
        );
      });

      test('returns hidden when markerVisibility is whenActive and selection is not collapsed', () {
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection(baseOffset: 2, extentOffset: 8),
          ),
          equals(MarkerRenderMode.hidden),
        );
      });

      test('returns hidden when markerVisibility is whenActive and selection is invalid', () {
        expect(
          TextfEditingController.computeRenderMode(
            visibility: MarkerVisibility.whenActive,
            selection: const TextSelection.collapsed(offset: -1),
          ),
          equals(MarkerRenderMode.hidden),
        );
      });
    });
  });
}
