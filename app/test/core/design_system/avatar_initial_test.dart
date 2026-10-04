// Shared avatar-initial helper (K02-BUG-1 / SHARED_REQUEST #3).
//
// `nickname[0]` indexes UTF-16 code units, so an emoji-leading nickname
// (`🐝 Bee`, which P05 accepts) produced an unpaired surrogate and
// `toUpperCase()` threw `string is not well-formed UTF-16`, failing the
// whole frame. `nestAvatarInitial` returns the first grapheme cluster
// instead, so every display is safe without blocking emoji input.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

void main() {
  group('nestAvatarInitial', () {
    test('returns the emoji grapheme for an emoji-leading name', () {
      expect(nestAvatarInitial('🐝 Bee'), '🐝');
    });

    test('preserves an accented capital', () {
      expect(nestAvatarInitial('Émile'), 'É');
    });

    test('upper-cases a lowercase letter', () {
      expect(nestAvatarInitial('maya'), 'M');
    });

    test('returns the whole ZWJ sequence as one grapheme', () {
      expect(nestAvatarInitial('👨‍👩‍👧 Fam'), '👨‍👩‍👧');
    });

    test('empty name returns the fallback', () {
      expect(nestAvatarInitial(''), '?');
      expect(nestAvatarInitial('', fallback: 'S'), 'S');
      expect(nestAvatarInitial('', fallback: ''), '');
    });

    test('whitespace-only name returns the fallback', () {
      expect(nestAvatarInitial(' '), '?');
      expect(nestAvatarInitial('   '), '?');
      expect(nestAvatarInitial(' ', fallback: '•'), '•');
    });

    test('leading whitespace is ignored', () {
      expect(nestAvatarInitial('  maya'), 'M');
      expect(nestAvatarInitial('  🐝 Bee'), '🐝');
    });

    test('single emoji without text is returned as-is', () {
      expect(nestAvatarInitial('🐝'), '🐝');
    });
  });

  group('avatar initial widget regression (K02-BUG-1)', () {
    testWidgets('/who-is-playing renders with a 🐝 Bee child', (tester) async {
      final db = await setUpTestScope();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'bee',
              familyId: Seed.familyId,
              nickname: '🐝 Bee',
              ageBand: const Value('7-9'),
              avatarColour: const Value('sky'),
              pipStage: const Value(1),
            ),
          );

      await pumpAppRoute(tester, '/who-is-playing');

      expect(tester.takeException(), isNull);
      expect(currentPath(tester), '/who-is-playing');
      final initials = tester
          .widgetList<NestAvatar>(find.byType(NestAvatar))
          .map((avatar) => avatar.initial)
          .toList();
      expect(initials, contains('🐝'));
      await disposeApp(tester);
    });

    testWidgets('/kid-home renders with a 🐝 Bee active child', (tester) async {
      final db = await setUpTestScope();
      await (db.update(db.children)..where((child) => child.id.equals('maya')))
          .write(const ChildrenCompanion(nickname: Value('🐝 Bee')));

      await pumpAppRoute(tester, '/kid-home');

      expect(tester.takeException(), isNull);
      expect(currentPath(tester), '/kid-home');
      final initials = tester
          .widgetList<NestAvatar>(find.byType(NestAvatar))
          .map((avatar) => avatar.initial)
          .toList();
      expect(initials, contains('🐝'));
      await disposeApp(tester);
    });
  });
}
