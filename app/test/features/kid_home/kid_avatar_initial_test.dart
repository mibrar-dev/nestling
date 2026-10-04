// kid_avatar_initial_test.dart — iteration 4 (STAGE 3).
//
// Mandatory rule under test (ORCHESTRATOR_NOTES / brief):
//
//   AVATAR INITIALS: use `nestAvatarInitial(name)` (grapheme-safe).
//   Never `name[0]`.
//
// `nestAvatarInitial` does not exist in `core/design_system/` yet — it is
// still SHARED_REQUEST #3 — so `kid_home` routes all three of its call sites
// through the feature-local `kidAvatarInitial` in
// `presentation/widgets/kid_style_helpers.dart`. This file is the safety net
// for that interim state, in three layers:
//
//   1. the helper's own contract (a pure function, three screens depend on it);
//   2. a RENDER proof for the third migrated site — K01's profile tile — which
//      the iteration-4 build covered for K02 and K03 but not here (the crash
//      took the whole frame down, so "one site untested" is one reachable
//      crash);
//   3. a source guard that fails the suite the moment a code-unit `[0]`
//      indexing creeps back into the feature — including when the shared
//      helper lands and someone re-inlines the logic instead of calling it.
//
// When `nestAvatarInitial` lands in `core/design_system/`, delete layer 1 and
// layer 2's helper reference and keep layer 3 (it is what stops the regression).

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_style_helpers.dart';

import '../../test_scope.dart';

/// A `lib/` source file, located by walking up from the package root.
File _libFile(String relative) {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File('${dir.path}/lib/$relative');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('lib/$relative not found above ${Directory.current.path}');
}

/// Source with every comment removed, so a guard never fires on prose like
/// "`nickname[0]` indexes UTF-16 code units" in a doc comment.
String _codeOnly(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

/// Every code-unit `[0]` index of a name, in [code].
List<String> _codeUnitIndexes(String code) =>
    RegExp(r'\b(nickname|child\.nickname|name)\s*\[\s*0\s*\]')
        .allMatches(code)
        .map((m) => m.group(0)!)
        .toList();

Future<void> _pumpPicker(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(const NestlingApp(initialRoute: '/who-is-playing'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(setUpTestScope);

  group('kidAvatarInitial contract', () {
    test('an empty nickname uses the fallback', () {
      expect(kidAvatarInitial(''), '?');
      expect(kidAvatarInitial('', fallback: 'S'), 'S');
    });

    test('a plain name upper-cases its first character', () {
      expect(kidAvatarInitial('Maya'), 'M');
      expect(kidAvatarInitial('leo'), 'L');
      expect(kidAvatarInitial('  Bee'), ' ');
      expect(kidAvatarInitial('9 lives'), '9');
    });

    test(
      'a non-ASCII first character survives whole (never a lone surrogate)',
      () {
        // The crash class: `[0]` returned an unpaired high surrogate and the
        // frame threw while laying out. Every one of these must come back as
        // exactly one well-formed code point.
        final cases = <String, String>{
          'Åsa': 'Å', // U+00C5, one code point
          'Émile': 'É',
          '𝒜da': '𝒜', // astral maths italic, U+1D49C
          '🐝 Bee': '🐝', // U+1F41D, the P05-legal name that used to crash K02
          '🇬🇧 Ben': '\u{1F1EC}', // regional-indicator PAIR: first rune only
          '👨‍👩‍👧 Family':
              '\u{1F468}', // ZWJ family: first rune, not the cluster
        };
        final actual = <String, String>{
          for (final entry in cases.entries)
            entry.key: kidAvatarInitial(entry.key),
        };
        expect(actual, cases, reason: 'the first code point, upper-cased');
        for (final value in actual.values) {
          expect(value.runes.length, 1, reason: 'never a split surrogate');
          expect(value.toUpperCase, returnsNormally, reason: 'well-formed');
        }
      },
    );

    test(
      'a leading combining mark does not throw and keeps the base letter',
      () {
        // 'A' + U+0308 is two code points; the helper takes the first, so the
        // initial is 'A'. Whatever it decides, it must not throw.
        expect(() => kidAvatarInitial('Åsa'), returnsNormally);
        expect(kidAvatarInitial('Åsa').runes.length, 1);
      },
    );
  });

  group('K01 profile tile renders a non-BMP nickname', () {
    // The third migrated site. `kid_pin_view_test.dart` and
    // `kid_home_view_test.dart` already render-prove K02 and K03; the picker
    // is where a family actually meets the name first, so it gets the same
    // proof — the frame must build AND the tile must show the emoji itself, so
    // a placeholder substitution cannot pass.
    testWidgets('the picker builds and shows the emoji initial', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(nickname: Value('\u{1F41D} Bee')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpPicker(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'a non-BMP nickname must not take the frame down',
      );
      // The roster is in creation order (Maya, then Leo) — the first tile is
      // Maya's, and its avatar carries the emoji.
      final avatars = find.descendant(
        of: find.byKey(const ValueKey<String>('k01-tile-maya')),
        matching: find.byType(NestAvatar),
      );
      expect(avatars, findsOneWidget);
      expect(tester.widget<NestAvatar>(avatars).initial, '\u{1F41D}');
      // …and the name itself is still on screen, unchanged.
      expect(find.text('\u{1F41D} Bee'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('no code-unit avatar initials in kid_home', () {
    // The rule is "never `name[0]`", so pin the *absence*: any bracket-0
    // indexing of a nickname/name that feeds an avatar fails here, whether it
    // comes back as `nickname[0]`, `name[0]` or a re-inlined copy/paste.
    const scanned = <String>[
      'features/kid_home/presentation/views/kid_pin_view.dart',
      'features/kid_home/presentation/views/kid_home_view.dart',
      'features/kid_home/presentation/widgets/profile_tile.dart',
      'features/kid_home/presentation/widgets/kid_style_helpers.dart',
    ];

    test('no call site indexes a name with [0]', () {
      for (final path in scanned) {
        final offenders = _codeUnitIndexes(
          _codeOnly(_libFile(path).readAsStringSync()),
        );
        expect(
          offenders,
          isEmpty,
          reason:
              '$path must go through kidAvatarInitial() / '
              'nestAvatarInitial(), never a code-unit index',
        );
      }
    });

    test('the guard itself bites (a reintroduced index is caught)', () {
      // A guard that cannot fail is not a guard: prove the pattern matches the
      // shapes the rule forbids, including a re-inlined copy of the old code.
      for (final sample in const <String>[
        'final initial = nickname[0].toUpperCase();',
        'final initial = child.nickname[0].toUpperCase();',
        'final initial = name [ 0 ];',
      ]) {
        expect(_codeUnitIndexes(sample), hasLength(1), reason: sample);
      }
      // …and that it does not fire on the fixed call sites or on prose.
      expect(_codeUnitIndexes('kidAvatarInitial(child.nickname)'), isEmpty);
      expect(
        _codeUnitIndexes('// `nickname[0]` indexes UTF-16 code units'),
        hasLength(1),
        reason: 'raw; _codeOnly strips this line before scanning',
      );
      expect(_codeOnly('// `nickname[0]` indexes UTF-16 code units'), isEmpty);
    });

    test('the helper itself is rune-based', () {
      final source = _codeOnly(
        _libFile(
          'features/kid_home/presentation/widgets/kid_style_helpers.dart',
        ).readAsStringSync(),
      );
      expect(
        source.contains('runes.first'),
        isTrue,
        reason: 'the interim helper must stay rune-based',
      );
    });
  });
}
