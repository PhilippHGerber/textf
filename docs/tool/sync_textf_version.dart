// Regenerates `lib/generated/textf_version.dart` from the root textf
// `pubspec.yaml`. The docs app depends on textf via workspace resolution, so
// the root pubspec version is exactly the version the docs site ships against.
//
// Run from the `docs/` directory before building:
//
//     dart run tool/sync_textf_version.dart
//
// This keeps the version shown in the UI in sync with the package with a
// single command — no manual editing of the generated file.
import 'dart:io';

void main() {
  final pubspec = File('../pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('❌ Could not find ../pubspec.yaml (run from the docs/ dir).');
    exit(1);
  }

  final match = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    stderr.writeln('❌ No `version:` field found in ../pubspec.yaml.');
    exit(1);
  }

  final version = (match.group(1) ?? '').trim();
  final output = File('lib/generated/textf_version.dart');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND.
//
// Run `dart run tool/sync_textf_version.dart` to regenerate this file from the
// root textf pubspec.yaml.

/// The version of the `textf` package this documentation site is built against.
const String textfVersion = '$version';
''');

  stdout.writeln('✅ Wrote lib/generated/textf_version.dart (textf $version)');
}
