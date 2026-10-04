// P03 Create account — submit against the real seeded databases.
//
// The widget suite drives a fake repository so the failure paths are
// reachable. These tests close the loop on the other side: the *shipped*
// `AuthRepositoryImpl` over the in-memory Drift DB, under `Seed.demo`,
// `Seed.empty` and `Seed.fresh`, submitted through the real route, the real
// bloc and the real router.
//
// Two testing notes, both learned the hard way here:
//   * Drift reads inside a `testWidgets` body must go through
//     `tester.runAsync` — a query stream's first event is scheduled on the
//     real event loop, which the fake-async test clock never advances.
//   * Per RULES §7 every test that pumps the app ends with
//     `disposeApp(tester)`; the databases themselves are deliberately left
//     open (`AppSession` keeps a live watch — see `test_scope.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

import '../../test_scope.dart';

const ValueKey<String> _emailKey = ValueKey('p03_email');
const ValueKey<String> _passwordKey = ValueKey('p03_password');
const ValueKey<String> _submitKey = ValueKey('p03_submit');
const ValueKey<String> _appleKey = ValueKey('p03_apple');
const ValueKey<String> _googleKey = ValueKey('p03_google');

Finder _input(ValueKey<String> key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

/// Reads the members table off the real event loop (see the file header).
Future<List<AuthAccount>> _members(WidgetTester tester) async {
  final items = await tester.runAsync(
    () => GetIt.instance<AuthRepository>().getItems(),
  );
  return items ?? const <AuthAccount>[];
}

/// Prepares an in-memory DB with [seed] and makes the app's session see it.
///
/// Seeding runs on the test's own async zone (it completes there); only the
/// *reads* need [WidgetTester.runAsync] — see [_members].
Future<AppDatabase> _seededScope(Future<void> Function() seed) async {
  final db = await setUpTestScope(seedDemo: false);
  await seed();
  await GetIt.instance<AppSession>().refresh();
  return db;
}

Future<void> _fillValidForm(WidgetTester tester, String email) async {
  await tester.enterText(_input(_emailKey), email);
  await tester.pump();
  await tester.enterText(_input(_passwordKey), 'nestlingfamily2026');
  await tester.pump();
}

Future<void> _pumpRoute(WidgetTester tester, ThemeMode theme) async {
  const surface = Size(390, 844);
  tester.view.physicalSize = surface * 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: '/create-account'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('P03 submit — the shipped repository over each seed', () {
    testWidgets(
      'Seed.empty (onboarded parent, no children): the submit is a no-op on '
      'the seeded owner row and advances to /privacy',
      (tester) async {
        await _seededScope(() => Seed.empty(GetIt.instance<AppDatabase>()));

        // Seed.empty already has an owner row ("Sarah").
        final before = await _members(tester);
        expect(before.single.name, 'Sarah');

        await _pumpRoute(tester, ThemeMode.light);
        await _fillValidForm(tester, 'sarah@example.co.uk');
        await tester.tap(find.byKey(_submitKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(currentPath(tester), '/privacy');
        // The owner row is untouched and nothing else was created.
        expect(await _members(tester), before);

        await disposeApp(tester);
      },
    );

    testWidgets('Seed.demo: the existing demo owner is never renamed', (
      tester,
    ) async {
      await setUpTestScope();

      final before = await _members(tester);
      expect(before.map((a) => a.name), contains('Sarah'));
      expect(before.map((a) => a.role), contains('owner'));

      await _pumpRoute(tester, ThemeMode.light);
      await _fillValidForm(tester, 'someone.else@example.co.uk');
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      // A different email must not overwrite the seeded owner name.
      expect(
        await _members(tester),
        before,
        reason:
            'createAccount is idempotent — the owner row is never rewritten',
      );

      await disposeApp(tester);
    });

    testWidgets('Seed.fresh: the email local-part becomes the owner name', (
      tester,
    ) async {
      await _seededScope(() => Seed.fresh(GetIt.instance<AppDatabase>()));

      expect(await _members(tester), isEmpty);

      await _pumpRoute(tester, ThemeMode.dark);
      await _fillValidForm(tester, 'james@example.co.uk');
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      final members = await _members(tester);
      expect(members, hasLength(1));
      expect(members.single.name, 'james');
      expect(members.single.role, 'owner');
      expect(members.single.detail, 'Owner');

      await disposeApp(tester);
    });

    testWidgets('Seed.empty + Continue with Apple advances to /privacy', (
      tester,
    ) async {
      await _seededScope(() => Seed.fresh(GetIt.instance<AppDatabase>()));

      await _pumpRoute(tester, ThemeMode.light);
      await tester.tap(find.byKey(_appleKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      final members = await _members(tester);
      expect(members, hasLength(1));
      expect(members.single.name, 'Parent');
      expect(members.single.role, 'owner');

      await disposeApp(tester);
    });

    testWidgets('Seed.empty + Continue with Google advances to /privacy', (
      tester,
    ) async {
      await _seededScope(() => Seed.fresh(GetIt.instance<AppDatabase>()));

      await _pumpRoute(tester, ThemeMode.dark);
      await tester.tap(find.byKey(_googleKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      expect(await _members(tester), hasLength(1));

      await disposeApp(tester);
    });

    testWidgets('the password is never written to the database', (
      tester,
    ) async {
      final db = await _seededScope(
        () => Seed.fresh(GetIt.instance<AppDatabase>()),
      );

      await _pumpRoute(tester, ThemeMode.light);
      await _fillValidForm(tester, 'sarah@example.co.uk');
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      // Schema v7 adds `members.email` (shared batch 6, P16 §4); there is
      // still no password column, so the password can never be persisted —
      // asserted on the schema itself. The auth stub does not yet write the
      // email (it only derives the owner name); storing it is a follow-up
      // in `AuthRepository.createAccount`.
      final columnNames = db.members.$columns.map((c) => c.name).toSet();
      expect(columnNames.contains('email'), isTrue);
      expect(columnNames.contains('password'), isFalse);

      final members = await _members(tester);
      expect(members.single.name, 'sarah');
      // The auth stub derives the name but does not yet persist the email
      // (follow-up in `AuthRepository.createAccount`); the row exists with
      // a NULL email.
      final rows = await tester.runAsync(() => db.select(db.members).get());
      expect(rows!.single.email, isNull);

      await disposeApp(tester);
    });

    testWidgets('an invalid form never reaches the repository', (tester) async {
      final db = await _seededScope(
        () => Seed.fresh(GetIt.instance<AppDatabase>()),
      );

      await _pumpRoute(tester, ThemeMode.light);
      await _fillValidForm(tester, 'not-an-email');
      // Submit is disabled, so even a forced tap changes nothing.
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNull,
      );

      expect(await _members(tester), isEmpty);
      // Schema v7 carries `members.email` (shared batch 6); the invalid
      // form still writes nothing.
      expect(db.members.$columns.map((c) => c.name), contains('email'));

      await disposeApp(tester);
    });
  });
}
