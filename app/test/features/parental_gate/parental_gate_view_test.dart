// P17 parental-gate view tests: exact copy, keypad fill/delete, correct-answer
// unlock → parent mode + /today, ghost cancel back to kid home, per-key
// semantics taps, loading / failure / disabled-gate pass-through states.
//
// Database-backed: `setUpTestScope` + Seed.demo; loading/failure/disabled use
// a feature-local fake repository swapped in before pumping. Every pumped app
// ends with `disposeApp` (see test_scope.dart).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

import '../../test_scope.dart';

ParentalGateChallenge _todayChallenge() =>
    ParentalGateRepositoryImpl(db: GetIt.instance<AppDatabase>())
        .challengeFor(DateTime.now().toUtc());

/// Controllable repository for loading/failure: `hang` silently emits
/// nothing, `fail` errors the stream, otherwise emits today's challenge.
class _FakeRepository extends ParentalGateRepository {
  _FakeRepository({this.hang = false, this.fail = false});

  final bool hang;
  final bool fail;

  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      <ParentalGateChallenge>[_todayChallenge()];

  @override
  Stream<List<ParentalGateChallenge>> watchItems() {
    if (hang) {
      return const Stream<List<ParentalGateChallenge>>.empty();
    }
    if (fail) {
      return Stream<List<ParentalGateChallenge>>.error(Exception('no gate'));
    }
    return Stream<List<ParentalGateChallenge>>.value(<ParentalGateChallenge>[
      _todayChallenge(),
    ]);
  }

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) =>
      ParentalGateRepositoryImpl(db: GetIt.instance<AppDatabase>())
          .challengeFor(utc);
}

Future<void> _useFake(ParentalGateRepository repo) async {
  await GetIt.instance.unregister<ParentalGateRepository>();
  GetIt.instance.registerSingleton<ParentalGateRepository>(repo);
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  testWidgets('renders the exact design copy', (tester) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('Type the answer in numbers:'), findsOneWidget);
    expect(find.text(_todayChallenge().question), findsOneWidget);
    expect(find.text('Back to Pip'), findsOneWidget);
    expect(
      find.text('This keeps settings and purchases safe.'),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  testWidgets('digit keys fill the boxes left→right, delete removes', (
    tester,
  ) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    final semantics = tester.ensureSemantics();
    Future<void> tapKey(String label) async {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      // Semantics performAction dispatches the tap via a scheduled frame:
      // pump twice so the bloc emit flushes to the next build.
      await tester.pump();
      await tester.pump();
    }

    final len = _todayChallenge().answer.toString().length;
    await tapKey('Digit 4');
    expect(find.bySemanticsLabel('Answer, 1 of $len entered'), findsOneWidget);
    await tapKey('Delete');
    expect(find.bySemanticsLabel('Answer, 0 of $len entered'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('a wrong full entry clears the boxes again', (tester) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    final semantics = tester.ensureSemantics();
    Future<void> tapKey(String label) async {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump();
    }

    final answer = _todayChallenge().answer;
    // Type a deliberately wrong full entry (answer+1, capped to the same
    // digit count is not needed — any wrong full-length string resets).
    final wrong = '${answer + 1}'.substring(0, answer.toString().length);
    for (final c in wrong.split('')) {
      await tapKey('Digit $c');
    }
    await tester.pump();
    final len = _todayChallenge().answer.toString().length;
    expect(find.bySemanticsLabel('Answer, 0 of $len entered'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('correct answer switches to parent mode at /today', (
    tester,
  ) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    final semantics = tester.ensureSemantics();
    Future<void> tapKey(String label) async {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump();
    }

    for (final c in '${_todayChallenge().answer}'.split('')) {
      await tapKey('Digit $c');
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
    expect(currentPath(tester), '/today');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('Back to Pip pops the gate back to /kid-home', (tester) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    // Push the gate the way K03's lock does: kid home → push gate.
    await pumpAppRoute(tester, '/kid-home');
    final semantics = tester.ensureSemantics();
    final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
    lock.owner!.performAction(lock.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pushedPath(tester), '/parental-gate');

    final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
    cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(currentPath(tester), '/kid-home');
    expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('every keypad key and ghost button exposes a tap action', (
    tester,
  ) async {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    final semantics = tester.ensureSemantics();
    for (var d = 0; d <= 9; d++) {
      final node = tester.getSemantics(find.bySemanticsLabel('Digit $d'));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'Digit $d must be tappable',
      );
    }
    final delete = tester.getSemantics(find.bySemanticsLabel('Delete'));
    expect(delete.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
    expect(cancel.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('loading shows a spinner, not the keypad', (tester) async {
    await _useFake(_FakeRepository(hang: true));
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Digit 1'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('failure shows a message, Try again and Back to Pip', (
    tester,
  ) async {
    await _useFake(_FakeRepository(fail: true));
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    expect(find.text('Exception: no gate'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Back to Pip'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('a disabled gate passes straight through to parent mode', (
    tester,
  ) async {
    final db = GetIt.instance<AppDatabase>();
    await (db.update(db.settings)
          ..where((s) => s.familyId.equals(Seed.familyId)))
        .write(const SettingsCompanion(kidGateEnabled: Value(false)));
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await pumpAppRoute(tester, '/parental-gate');
    await tester.pump(const Duration(milliseconds: 600));
    expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
    expect(currentPath(tester), '/today');
    await disposeApp(tester);
  });
}
