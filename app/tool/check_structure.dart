// Checks the structure rules of docs/code-conventions.md that can be checked
// mechanically: file size, one widget per file, and the direction of the
// dependencies between the layers.
//
// Run from the app folder:
//
//   dart run tool/check_structure.dart
//   dart run tool/check_structure.dart --update-baseline
//
// The files that broke a rule before this check existed are listed in
// tool/structure_baseline.txt with the size they had. The check fails on a
// new violation, and on a listed file that grew. A file leaving the list is
// never added back.

import 'dart:io';

/// The size limit of a file under presentation/, where the widgets live.
const int presentationLimit = 70;

/// The size limit of every other file.
const int generalLimit = 120;

const String baselinePath = 'tool/structure_baseline.txt';

/// A broken rule in one file. [value] is the measured size for the size
/// rules and 0 for the others, so the baseline can tell a file that grew
/// from one that did not.
class Violation {
  Violation(this.rule, this.path, this.value, this.message);

  final String rule;
  final String path;
  final int value;
  final String message;

  String get key => '$rule $path';
}

/// The files the limits do not apply to, with the reason in the baseline.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.config.dart');

final RegExp _classDeclaration = RegExp(
  r'^(?:abstract |sealed |base |final |interface )*class\s+\w+',
);

/// The State of a StatefulWidget belongs with its widget, so it does not
/// count as a second widget in the file.
final RegExp _stateDeclaration = RegExp(r'\bextends\s+State<');

bool _isTopLevelClass(String line) =>
    !line.startsWith(' ') &&
    _classDeclaration.hasMatch(line) &&
    !_stateDeclaration.hasMatch(line);

String? _importTarget(String line) {
  final RegExp pattern = RegExp(r"^import\s+'([^']+)'");
  return pattern.firstMatch(line)?.group(1);
}

List<Violation> inspect(File file, String path) {
  final List<String> lines = file.readAsLinesSync();
  final List<Violation> found = <Violation>[];
  final bool presentation = path.contains('/presentation/');
  final int limit = presentation ? presentationLimit : generalLimit;

  if (lines.length > limit) {
    found.add(
      Violation(
        'size',
        path,
        lines.length,
        '${lines.length} lines, limit $limit',
      ),
    );
  }

  final int classes = lines.where(_isTopLevelClass).length;
  if (presentation && classes > 1) {
    found.add(
      Violation(
        'one-widget',
        path,
        0,
        '$classes top-level classes, one per file',
      ),
    );
  }

  for (final String line in lines) {
    final String? target = _importTarget(line);
    if (target == null || !target.startsWith('package:app/')) continue;
    final String imported = target.substring('package:app/'.length);
    if (presentation && imported.contains('/data/')) {
      found.add(
        Violation('layer', path, 0, 'presentation imports $imported'),
      );
    }
    if (path.contains('/domain/') &&
        (imported.contains('/data/') || imported.contains('/presentation/'))) {
      found.add(Violation('layer', path, 0, 'domain imports $imported'));
    }
  }
  return found;
}

Map<String, int> readBaseline() {
  final File file = File(baselinePath);
  if (!file.existsSync()) return <String, int>{};
  final Map<String, int> baseline = <String, int>{};
  for (final String line in file.readAsLinesSync()) {
    final String entry = line.split('#').first.trim();
    if (entry.isEmpty) continue;
    final List<String> parts = entry.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;
    baseline['${parts[0]} ${parts[1]}'] = int.tryParse(parts[2]) ?? 0;
  }
  return baseline;
}

void writeBaseline(List<Violation> violations) {
  final List<String> lines = <String>[
    '# Files that broke a rule of docs/code-conventions.md before',
    '# tool/check_structure.dart existed. The check fails on a new violation,',
    '# and on a file here that grew. Remove a line once the file is fixed;',
    '# never add one.',
    '#',
    '# rule  path  size',
    '',
  ];
  final Map<String, Violation> unique = <String, Violation>{};
  for (final Violation v in violations) {
    final Violation? kept = unique[v.key];
    if (kept == null || v.value > kept.value) unique[v.key] = v;
  }
  final List<String> keys = unique.keys.toList()..sort();
  for (final String key in keys) {
    final Violation v = unique[key]!;
    lines.add('${v.rule} ${v.path} ${v.value}');
  }
  File(baselinePath).writeAsStringSync('${lines.join('\n')}\n');
}

void main(List<String> arguments) {
  final Directory lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run this from the app folder.');
    exit(2);
  }

  final List<Violation> violations = <Violation>[];
  final List<File> files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  for (final File file in files) {
    final String path = file.path.replaceAll(r'\', '/');
    if (isGenerated(path)) continue;
    violations.addAll(inspect(file, path));
  }

  if (arguments.contains('--update-baseline')) {
    writeBaseline(violations);
    stdout.writeln('Wrote $baselinePath with ${violations.length} entries.');
    return;
  }

  final Map<String, int> baseline = readBaseline();
  final List<Violation> fresh = <Violation>[];
  final List<Violation> grown = <Violation>[];
  for (final Violation v in violations) {
    final int? allowed = baseline[v.key];
    if (allowed == null) {
      fresh.add(v);
    } else if (v.value > allowed) {
      grown.add(v);
    }
  }

  for (final Violation v in fresh) {
    stdout.writeln('new      ${v.path}: ${v.message}');
  }
  for (final Violation v in grown) {
    stdout.writeln('grew     ${v.path}: ${v.message}'
        ' (was ${baseline[v.key]})');
  }

  final int known = violations.length - fresh.length - grown.length;
  stdout.writeln(
    '${files.length} files, $known known violations left to fix, '
    '${fresh.length} new, ${grown.length} grown.',
  );
  if (fresh.isNotEmpty || grown.isNotEmpty) exit(1);
}
