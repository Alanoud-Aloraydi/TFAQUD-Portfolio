import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String directory) =>
    Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

void main() {
  test('shared components have no feature dependencies', () {
    for (final file in dartFiles('lib/core/widgets')) {
      expect(
        file.readAsStringSync(),
        isNot(contains('package:app/features/')),
        reason: file.path,
      );
    }
  });

  test('theme does not depend on presentation components', () {
    for (final file in dartFiles('lib/core/theme')) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('package:app/core/widgets/')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('package:app/features/')),
        reason: file.path,
      );
    }
  });

  test('interface colors and motion come from the design system', () {
    final rawVisualValue = RegExp(
      r'\bAppColors\.|\bColors\.|\bColor\(0x|\bFontWeight\.|'
      r'\bDuration\(milliseconds:',
    );
    for (final directory in ['lib/core/widgets', 'lib/features', 'lib/dev']) {
      for (final file in dartFiles(directory)) {
        final path = file.path.replaceAll('\\', '/');
        if (directory == 'lib/features' &&
            !path.contains('/presentation/widgets/') &&
            !path.contains('/presentation/pages/') &&
            !path.contains('/shell/')) {
          continue;
        }
        // Generated files are owned by their generators, not this contract.
        if (RegExp(r'\.(g|freezed|config)\.dart$').hasMatch(file.path)) {
          continue;
        }
        expect(
          rawVisualValue.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    }
  });
}
