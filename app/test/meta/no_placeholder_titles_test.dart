// Guard: shared tests must never assert foundation placeholder titles.
//
// Every real screen replaces its placeholder scaffold title, but the route
// path is stable — so shared tests assert `pushedPath` / `currentPath`
// (see `test_scope.dart`), never the title text. This test scans every
// Dart file under `test/` and fails if a placeholder-title finder remains.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no shared test asserts a placeholder screen title', () {
    // Matches finders like find.text('K08 Reward shop') — a K/P id, two
    // digits, a space, then the placeholder copy. Real copy such as
    // 'Pip' or 'Play all' has no digits, so it never matches.
    final placeholder = RegExp(
      'find\\.text\\(\\s*[\'"][KP][0-9]{2}\\s+[^\'"]*[\'"]',
    );
    final root = Directory('test');
    expect(root.existsSync(), isTrue, reason: 'run from app/ (flutter test)');
    final offenders = <String>[];
    for (final entry
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      // This guard documents the pattern with words only; it holds no
      // concrete title, but skip itself so the rule stays self-hosting.
      if (entry.path.endsWith('no_placeholder_titles_test.dart')) {
        continue;
      }
      final source = entry.readAsStringSync();
      for (final match in placeholder.allMatches(source)) {
        final line = source.substring(0, match.start).split('\n').length;
        offenders.add('${entry.path}:$line');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'placeholder-title assertions break on every real screen; assert '
          'pushedPath/currentPath instead. Offenders: $offenders',
    );
  });
}
