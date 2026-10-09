// ignore_for_file: avoid-top-level-members-in-tests, prefer-match-file-name

/// Architectural & static enforcement seam (PRD "Testing Seams" §3, §8).
///
/// Text scans over the package sources:
///
/// - `T-ARCH-01`: nothing in `lib/` imports, exports or `@docImport`s a design-system library
///   (Flutter's material/cupertino libraries, `material_ui`, `cupertino_ui`). A forbidden
///   `@docImport` gets retarget advice instead of a bare failure (DEP-1, DEP-4).
/// - `T-ARCH-02`: unit tests in `test/unit/` neither import a design-system library nor build a
///   Material app shell; they run on widgets-layer hosts only.
/// - `T-ARCH-03`: no design-system symbol (`Theme.of`, `ThemeData`, `ColorScheme`, `Colors.x`,
///   `CupertinoTheme`, `CupertinoColors`, bracketed `[Theme]` links) appears in `lib/` — in
///   practice only comments and dartdoc can contain one, since `lib/` cannot import them
///   (DEP-5, DEP-6). A line may name a symbol on purpose with an allow tag on that line or the
///   line above: `// textf-guard-allow: <symbol>` (or `///`).
///
/// Each guard is a pure function over `(path, source)`, exercised against synthetic sources
/// (proving it fails on a violation) and then against the real tree.
///
/// Self-scan: this file lives in `test/unit/`, so `T-ARCH-02` scans it too. Rather than
/// excluding itself, it never spells the forbidden forms verbatim: they are assembled from the
/// fragments below at runtime.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fragment of the Flutter Material library URI (`package:flutter/<this>.dart`).
const String _material = 'material';

/// Identifier of the Material app shell, assembled so this file never contains it verbatim.
const String _materialApp =
    'Material'
    'App';

/// One guard finding: a 1-based line in a package-relative `path`.
typedef _ArchViolation = ({String path, int line, String message});

/// Design-system library URIs that `lib/` (and `test/unit/`) must not depend on.
final RegExp _forbiddenLibrary = RegExp(
  r'^package:(?:flutter/(?:material|cupertino)\.dart$|flutter/src/(?:material|cupertino)/'
  '|material_ui/|cupertino_ui/)',
);

/// An `import`/`export` directive, or a `/// @docImport` line (group 1), with its URI (group 2).
final RegExp _directive = RegExp(
  r'''^\s*(?:(///\s*@docImport)|import|export)\s+['"]([^'"]+)['"]''',
);

/// Use of the Material app shell identifier.
final RegExp _materialAppUse = RegExp('\\b$_materialApp\\b');

/// Design-system symbols that must not appear in `lib/` (PRD §8, wayfinder 14).
///
/// Matches identifier forms, not English prose: the capitalized class name `Theme` (bare,
/// backticked, bracketed or as `Theme.of`/`Theme.maybeOf`) matches, while the lower-case noun
/// "theme" and "Theming" never do.
final RegExp _designSystemSymbol = RegExp(
  r'\[(?:Theme|ThemeData|ColorScheme|Colors|CupertinoTheme\w*|CupertinoColors)(?:\.\w+)?\]'
  r'|\b(?:ThemeData|ColorScheme|Theme(?:\.\w+)?|CupertinoTheme\w*|CupertinoColors(?:\.\w+)?'
  r'|Colors\.\w+)\b',
);

/// The inline escape hatch, anywhere in a `//` or `///` comment:
/// `// textf-guard-allow: Theme.of, ThemeData`.
final RegExp _allowTag = RegExp(r'//.*?textf-guard-allow:\s*(.+)$');

/// Returns the directives in [source] that name a forbidden design-system library.
List<_ArchViolation> _findForbiddenDirectives(String path, String source) {
  final List<String> lines = const LineSplitter().convert(source);
  final List<_ArchViolation> violations = [];
  for (int i = 0; i < lines.length; i++) {
    final RegExpMatch? match = _directive.firstMatch(lines[i]);
    final String uri = match?.group(2) ?? '';
    if (match == null || !_forbiddenLibrary.hasMatch(uri)) continue;
    final String message = match.group(1) != null
        ? "Forbidden @docImport '$uri'. Do not delete; retarget to "
              "'package:flutter/widgets.dart' or 'package:flutter/painting.dart' to preserve "
              'dartdoc symbol resolution.'
        : "Forbidden import/export '$uri'. textf is design-system neutral (ADR 0004, ADR 0005): "
              'use the narrowest of package:flutter/widgets.dart, painting.dart, gestures.dart, '
              'services.dart or foundation.dart instead.';
    violations.add((path: path, line: i + 1, message: message));
  }
  return violations;
}

/// Returns the design-system couplings in a `test/unit/` [source]: forbidden library
/// directives and code lines using the Material app shell. Comment lines are skipped, so a
/// test may document that it avoids the shell.
List<_ArchViolation> _findUnitTestCoupling(String path, String source) {
  final List<_ArchViolation> violations = _findForbiddenDirectives(path, source);
  final List<String> lines = const LineSplitter().convert(source);
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('//')) continue;
    if (_materialAppUse.hasMatch(lines[i])) {
      violations.add((
        path: path,
        line: i + 1,
        message:
            'Unit tests must not build a $_materialApp. Host widgets on the widgets layer '
            '(`neutralTestApp` in test/widgets/pump_textf_widget.dart, or a bare '
            '`Directionality`).',
      ));
    }
  }
  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

/// Returns the design-system symbols in [source] that no allow tag exempts.
List<_ArchViolation> _findDesignSystemReferences(String path, String source) {
  final List<String> lines = const LineSplitter().convert(source);
  final List<Set<String>> allowed = [for (final line in lines) _allowedSymbols(line)];
  final List<_ArchViolation> violations = [];
  for (int i = 0; i < lines.length; i++) {
    for (final RegExpMatch match in _designSystemSymbol.allMatches(lines[i])) {
      final String symbol = _stripBrackets(match.group(0) ?? '');
      final bool exempt = allowed[i].contains(symbol) || (i > 0 && allowed[i - 1].contains(symbol));
      if (exempt) continue;
      violations.add((
        path: path,
        line: i + 1,
        message:
            "Design-system reference '$symbol'. textf reads no design-system theme "
            '(ADR 0005, DEP-6): correct the comment, or, if it must name the symbol (e.g. to '
            'document its absence), add `// textf-guard-allow: $symbol` on or directly above '
            'this line.',
      ));
    }
  }
  return violations;
}

Set<String> _allowedSymbols(String line) {
  final String? list = _allowTag.firstMatch(line)?.group(1);
  if (list == null) return const {};
  return {
    for (final String entry in list.split(RegExp(r'[,\s]+')))
      if (entry.isNotEmpty) _stripBrackets(entry),
  };
}

/// Brackets of a doc link, and punctuation that prose may leave after an allow-tag entry.
final RegExp _symbolNoise = RegExp(r'[\[\]]|[.,;:!?)]+$');

String _stripBrackets(String symbol) => symbol.replaceAll(_symbolNoise, '');

/// The package root: the nearest ancestor of the working directory whose `pubspec.yaml`
/// declares `name: textf`. Keeps the scans independent of where `flutter test` runs.
Directory _packageRoot() {
  final RegExp nameLine = RegExp(r'^name:\s*textf\s*$', multiLine: true);
  Directory dir = Directory.current.absolute;
  while (true) {
    final File pubspec = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (pubspec.existsSync() && nameLine.hasMatch(pubspec.readAsStringSync())) return dir;
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('No textf pubspec.yaml above ${Directory.current.path}');
    }
    dir = parent;
  }
}

/// All `.dart` files under the package-relative [relativeDir], keyed by package-relative
/// path with `/` separators.
Map<String, String> _dartSources(String relativeDir) {
  final String root = _packageRoot().path;
  final Directory dir = Directory('$root${Platform.pathSeparator}$relativeDir');
  final List<File> files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final File file in files)
      file.path.substring(root.length + 1).replaceAll(Platform.pathSeparator, '/'): file
          .readAsStringSync(),
  };
}

/// `lib/` sources, read once (top-level finals are initialized lazily).
final Map<String, String> _libSources = _dartSources('lib');

/// Runs [guard] over every source in [sources] and renders the findings one per line.
List<String> _scan(
  Map<String, String> sources,
  List<_ArchViolation> Function(String path, String source) guard,
) {
  return [
    for (final MapEntry<String, String> entry in sources.entries)
      for (final _ArchViolation v in guard(entry.key, entry.value))
        '${v.path}:${v.line}: ${v.message}',
  ];
}

void main() {
  group('T-ARCH-01 forbidden library import guard', () {
    test('flags imports and exports of design-system libraries', () {
      final String source = [
        "import 'dart:ui';",
        "import 'package:flutter/$_material.dart';",
        'import "package:flutter/cupertino.dart" show CupertinoColors;',
        "import 'package:material_ui/material_ui.dart';",
        "export 'package:cupertino_ui/cupertino_ui.dart';",
        "import 'package:flutter/src/$_material/colors.dart';",
      ].join('\n');

      final List<_ArchViolation> violations = _findForbiddenDirectives('lib/a.dart', source);

      expect([for (final v in violations) v.line], [2, 3, 4, 5, 6]);
      expect(violations.first.path, 'lib/a.dart');
      expect(violations.first.message, contains("Forbidden import/export 'package:flutter/"));
      expect(violations.first.message, contains('package:flutter/widgets.dart'));
    });

    test('a forbidden @docImport gets retarget advice, not a bare failure', () {
      final String source = [
        '/// Links [Text].',
        "/// @docImport 'package:flutter/$_material.dart';",
        'library;',
      ].join('\n');

      final List<_ArchViolation> violations = _findForbiddenDirectives('lib/textf.dart', source);

      expect(violations, hasLength(1));
      expect(violations.single.line, 2);
      expect(
        violations.single.message,
        "Forbidden @docImport 'package:flutter/$_material.dart'. Do not delete; retarget to "
        "'package:flutter/widgets.dart' or 'package:flutter/painting.dart' to preserve dartdoc "
        'symbol resolution.',
      );
    });

    test('allows the neutral Flutter layers, relative imports and prose mentions', () {
      final String source = [
        "import 'package:flutter/widgets.dart';",
        "import 'package:flutter/painting.dart';",
        "import 'package:flutter/gestures.dart';",
        "import 'package:flutter/services.dart';",
        "import 'package:flutter/foundation.dart';",
        "import '../core/default_styles.dart';",
        "/// @docImport 'package:flutter/widgets.dart';",
        "// Never import 'package:flutter/$_material.dart' here.",
        "final uri = 'package:flutter/$_material.dart';",
      ].join('\n');

      expect(_findForbiddenDirectives('lib/a.dart', source), isEmpty);
    });

    test('lib/ imports no design-system library', () {
      expect(_libSources, isNotEmpty);
      expect(
        _scan(_libSources, _findForbiddenDirectives),
        isEmpty,
        reason: 'lib/ must depend only on widgets, painting, gestures, services and foundation.',
      );
    });

    test("the barrel's @docImport targets the widgets layer", () {
      expect(
        _libSources['lib/textf.dart'],
        contains("/// @docImport 'package:flutter/widgets.dart';"),
      );
    });
  });

  group('T-ARCH-02 unit test decoupling guard', () {
    test('flags a Material import and the Material app shell in code', () {
      final String source = [
        "import 'package:flutter/$_material.dart';",
        "import 'package:flutter_test/flutter_test.dart';",
        'void main() {',
        '  final w = $_materialApp(home: Text("x"));',
        '  final v = const $_materialApp();',
        '}',
      ].join('\n');

      final List<_ArchViolation> violations = _findUnitTestCoupling(
        'test/unit/a_test.dart',
        source,
      );

      expect([for (final v in violations) v.line], [1, 4, 5]);
      expect(violations[1].message, contains('neutralTestApp'));
    });

    test('ignores comment lines and neutral hosts', () {
      final String source = [
        "import 'package:flutter/widgets.dart';",
        '/// Hosted without a $_materialApp or Theme.',
        '// $_materialApp would bring Material defaults.',
        'final w = neutralTestApp(child: WidgetsApp(color: c, builder: b));',
        'final x = Directionality(textDirection: TextDirection.ltr, child: y);',
      ].join('\n');

      expect(_findUnitTestCoupling('test/unit/a_test.dart', source), isEmpty);
    });

    test('test/unit/ has no Material import and no Material app shell', () {
      final Map<String, String> sources = _dartSources('test/unit');
      expect(sources, contains('test/unit/arch_test.dart'));
      expect(
        _scan(sources, _findUnitTestCoupling),
        isEmpty,
        reason: 'Unit tests must stay decoupled from design systems (PRD user story 25).',
      );
    });
  });

  group('T-ARCH-03 doc comment reference guard', () {
    test('flags design-system identifier forms and doc links', () {
      final List<String> lines = [
        '/// Falls back to Theme.of(context).',
        '/// Reads [ThemeData] from the tree.',
        '/// Uses the ColorScheme primary.',
        '///   boldStyle: TextStyle(color: Colors.red),',
        '/// See [Theme].',
        '/// See [Colors.blue].',
        '// Reads CupertinoTheme.of(context).',
        '/// Uses CupertinoColors.systemBlue.',
        "const hint = 'ThemeData';",
        '/// Considers `TextfOptions`, `Theme`, and defaults.',
        '/// Aware of TextfOptions and the application Theme.',
        '/// Falls back to Theme.maybeOf(context).',
      ];

      final List<_ArchViolation> violations = _findDesignSystemReferences(
        'lib/a.dart',
        lines.join('\n'),
      );

      expect(
        [for (final v in violations) (v.line, v.message.split("'")[1])],
        [
          (1, 'Theme.of'),
          (2, 'ThemeData'),
          (3, 'ColorScheme'),
          (4, 'Colors.red'),
          (5, 'Theme'),
          (6, 'Colors.blue'),
          (7, 'CupertinoTheme'),
          (8, 'CupertinoColors.systemBlue'),
          (9, 'ThemeData'),
          (10, 'Theme'),
          (11, 'Theme'),
          (12, 'Theme.maybeOf'),
        ],
      );
      expect(violations.first.message, contains('// textf-guard-allow: Theme.of'));
    });

    test('does not flag the English word "theme" or look-alike identifiers', () {
      final String source = [
        '/// textf reads no theme; see Theming 2.0 and the design-system theme docs.',
        '/// Themes and colors come from the effective root style.',
        'final Color linkColor = options.linkColor;',
        'final myColors = textColors.primary;',
        'final colorScheme = 1;',
      ].join('\n');

      expect(_findDesignSystemReferences('lib/a.dart', source), isEmpty);
    });

    test('an allow tag on the same or the preceding line exempts only the named symbol', () {
      final String source = [
        '/// Never calls Theme.of. textf-guard-allow: Theme.of', // 1: exempt, same line
        '// textf-guard-allow: ThemeData, [ColorScheme]', // 2: tag names ThemeData itself
        '/// No ThemeData and no [ColorScheme] is read.', // 3: exempt by line 2
        '/// Nor is ThemeData.', // 4: tag is two lines up -> flagged
        '/// textf-guard-allow: Colors.red',
        '/// Not Colors.blue either.', // 6: different symbol -> flagged
        '/// Reads no [Theme]. // textf-guard-allow: Theme.', // 7: trailing prose dot ignored
      ].join('\n');

      final List<_ArchViolation> violations = _findDesignSystemReferences('lib/a.dart', source);

      expect([for (final v in violations) v.line], [4, 6]);
    });

    test('lib/ names no design-system symbol without an allow tag', () {
      expect(_libSources, isNotEmpty);
      expect(
        _scan(_libSources, _findDesignSystemReferences),
        isEmpty,
        reason: 'Stale design-system prose in lib/ (DEP-6).',
      );
    });
  });

  group('public-surface decisions', () {
    // Not a design-system guard, but the same kind of static check: PRD §2 and decision
    // ticket 13 keep TextfOptionsData a read-only snapshot, and Dart cannot assert a
    // method's absence without `dynamic`.
    test('TextfOptionsData declares no copyWith', () {
      final String? source = _libSources['lib/src/widgets/textf_options_data.dart'];
      expect(source, isNotNull);
      expect(source, isNot(contains(RegExp(r'\bTextfOptionsData\s+copyWith\s*[(<]'))));
    });
  });
}
