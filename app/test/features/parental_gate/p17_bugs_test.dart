// P17 parental gate — adversarial bug hunt (Stage 6, iteration 2).
//
// Iteration-2 result: P17-BUG-2 (UTC-vs-London challenge day) and P17-BUG-3
// (stale entry after a challenge change) are FIXED — their proofs now run
// green (builders unskipped them). Iteration 3 closed P17-BUG-4 (backdrop
// header top-aligned its items against the CSS `.kb-top` centre), so its proof
// runs too. P17-BUG-1 (shared router redirect loop on an expired kid-mode
// trial) is still open and stays `skip:`-marked so the suite stays green;
// unskip it to see the failure.
//
// The green tests below are the clean probes from both hunts: rapid double
// activation, system back, pushed-gate unlock (gate must actually dismiss),
// disabled-gate pass-through, failure retry/leave, child-data edges (0/1/6
// children, long UK name, 9999 coins, 320 px + 1.3 scale), Leo's own Pip from
// the DB, BST boundaries for the challenge day, and stream changes after the
// gate closes. No simulator was used.
//
// Database-backed: `setUpTestScope` + Seed.demo; loading/failure probes use a
// feature-local fake repository swapped in before pumping. Every pumped app
// ends with `disposeApp` (test_scope.dart). Real async (trial-expiry writes,
// challenge reads) runs through `tester.runAsync` because a pending Drift
// stream timer would otherwise stall FakeAsync.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_state.dart';

import '../../test_scope.dart';

class MockParentalGateRepository extends Mock implements ParentalGateRepository;

const _sevenSix = ParentalGateChallenge(
  id: '2026-1-6',
  title: 'Grown-ups only',
  detail: 'This keeps settings and purchases safe.',
  a: 7,
  b: 6,
);

/// The live challenge the screen will show, read from the registered
/// repository (exactly what the bloc gets) — never hard-coded and independent
/// of the day the suite runs on. Drift needs the real event loop, hence
/// [WidgetTester.runAsync].
Future<ParentalGateChallenge> _liveChallenge(WidgetTester tester) async {
  final items = (await tester.runAsync(
    () => GetIt.instance<ParentalGateRepository>().getItems(),
  ))!;
  expect(items, hasLength(1));
  return items.single;
}

/// Fails the first `watchItems()` subscription, succeeds afterwards.
class _FailOnceRepository extends ParentalGateRepository {
  _FailOnceRepository({this.alwaysFail = false});

  final bool alwaysFail;
  var _calls = 0;

  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      <ParentalGateChallenge>[_today()];

  ParentalGateChallenge _today() => const ParentalGateChallenge(
    id: 'today',
    title: 'Grown-ups only',
    detail: 'This keeps settings and purchases safe.',
    a: 3,
    b: 9,
  );

  @override
  Stream<List<ParentalGateChallenge>> watchItems() {
    _calls += 1;
    if (alwaysFail || _calls == 1) {
      return Stream<List<ParentalGateChallenge>>.error(Exception('boom'));
    }
    return Stream<List<ParentalGateChallenge>>.value(<ParentalGateChallenge>[
      _today(),
    ]);
  }

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) => _today();
}

Future<void> _useFake(ParentalGateRepository repo) async {
  await GetIt.instance.unregister<ParentalGateRepository>();
  GetIt.instance.registerSingleton<ParentalGateRepository>(repo);
}

/// Types every digit of [answer] through the keypad's semantics actions.
Future<void> _typeAnswer(WidgetTester tester, String answer) async {
  for (final digit in answer.split('')) {
    final node = tester.getSemantics(find.bySemanticsLabel('Digit $digit'));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump();
  }
}

/// Pushes the gate from kid home through K03's lock, the real entry point.
Future<void> _pushGateFromKidHome(WidgetTester tester) async {
  GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  await pumpAppRoute(tester, '/kid-home');
  final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
  lock.owner!.performAction(lock.id, SemanticsAction.tap);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Persists an expired 14-day trial and refreshes the session (real async).
Future<void> _expireTrial(WidgetTester tester) async {
  final db = GetIt.instance<AppDatabase>();
  final session = GetIt.instance<AppSession>();
  await tester.runAsync(() async {
    await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(
        subscriptionStatus: const Value('trial'),
        trialStart: Value(
          DateTime.now().toUtc().subtract(const Duration(days: 15)),
        ),
      ),
    );
    await session.refresh();
  });
}

/// Drives the P17-BUG-3 regression: load a challenge, type a digit, swap the
/// challenge mid-entry and assert the reset (the entry belonged to the old
/// question).
///
/// Kept as a helper with a parameter receiver (like the existing
/// `addAfterLoaded`) so `cascade_invocations` does not fire on the local.
Future<void> _staleEntryProof(
  ParentalGateBloc bloc,
  StreamController<List<ParentalGateChallenge>> controller,
) async {
  bloc.add(const ParentalGateLoadRequested());
  controller.add(const <ParentalGateChallenge>[_sevenSix]);
  await bloc.stream.firstWhere((s) => s.status == ParentalGateStatus.loaded);
  bloc.add(const ParentalGateDigitEntered('4'));
  await bloc.stream.firstWhere((s) => s.entered == '4');
  controller.add(const <ParentalGateChallenge>[
    ParentalGateChallenge(
      id: 'next',
      title: 'Grown-ups only',
      detail: 'This keeps settings and purchases safe.',
      a: 3,
      b: 9,
    ),
  ]);
  await bloc.stream.firstWhere((s) => s.items.first.id == 'next');
  expect(bloc.state.entered, isEmpty);
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('bug proofs (P17-BUG-1 shared; BUG-2/3/4 fixed)', () {
    // P17-BUG-1 (major, shared): app/lib/app/router.dart redirects an expired
    // kid-mode trial to /paywall, which is parent-only in kid mode and
    // redirects back to /parental-gate — a redirect loop. Unskipping this
    // proof shows go_router's error page: `Page Not Found / GoException:
    // redirect loop detected /paywall => /parental-gate => /paywall / Go to
    // home page`; every kid route (/kid-home included) is stuck the same way.
    // Fix is router.dart (shared, filed in SHARED_REQUEST.md); not fixable
    // under RULES §1.
    testWidgets('P17-BUG-1: kid mode + expired trial renders the gate', (
      tester,
    ) async {
      await _expireTrial(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Grown-ups only'), findsOneWidget);
      await disposeApp(tester);
    }, skip: true);

    test('P17-BUG-2: the challenge follows the Europe/London day (BST)', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      // London 00:30 BST, 4 Oct 2026 == 23:30 UTC, 3 Oct.
      final afterLondonMidnight = repo.challengeFor(
        DateTime.utc(2026, 10, 3, 23, 30),
      );
      // London 12:00 BST, 4 Oct 2026 == 11:00 UTC.
      final sameLondonMidday = repo.challengeFor(DateTime.utc(2026, 10, 4, 11));
      expect(afterLondonMidnight.id, sameLondonMidday.id);
      expect(afterLondonMidnight.question, sameLondonMidday.question);
    });

    test('P17-BUG-3: a challenge change resets the typed entry', () async {
      final repo = MockParentalGateRepository();
      final controller = StreamController<List<ParentalGateChallenge>>();
      when(repo.watchItems).thenAnswer((_) => controller.stream);
      final bloc = ParentalGateBloc(repository: repo);
      await _staleEntryProof(bloc, controller);
      await bloc.close();
      await controller.close();
    });

    // P17-BUG-4 (minor, screen-local) — FIXED in iteration 3, proof un-skipped:
    // `.kb-top { align-items: center }` but the app's header Row passed
    // `CrossAxisAlignment.start`, so the greeting and coin pill sat 5 px / 4 px
    // high in the 44 px row (greeting centre 72 vs the avatar's 77). The dimmed
    // header is the only backdrop strip the card does not cover;
    // `parental_gate_geometry_test.dart` pins the same fact ('the backdrop row
    // centres its items like `.kb-top`'). The fix: drop the
    // `crossAxisAlignment` argument (the default is centre).
    testWidgets('P17-BUG-4: the backdrop header centres its items', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final avatar = tester.getRect(find.byType(NestAvatar));
      final greeting = tester.getRect(find.text('Hi Maya!'));
      final pill = tester.getRect(find.byType(NestCoinPill));
      expect(
        greeting.center.dy,
        moreOrLessEquals(avatar.center.dy, epsilon: 1),
        reason: 'CSS .kb-top align-items: center',
      );
      expect(
        pill.center.dy,
        moreOrLessEquals(avatar.center.dy, epsilon: 1),
        reason: 'CSS .kb-top align-items: center',
      );
      await disposeApp(tester);
    });
  });

  group('clean probes (green)', () {
    testWidgets('double semantics activation of Back to Pip pops once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      expect(pushedPath(tester), '/parental-gate');
      final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(currentPath(tester), '/kid-home');
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('system back leaves the gate for kid home, mode unchanged', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      expect(pushedPath(tester), '/parental-gate');
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('correct answer on a pushed gate dismisses it as parent', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      expect(pushedPath(tester), '/parental-gate');
      final challenge = await _liveChallenge(tester);
      await _typeAnswer(tester, '${challenge.answer}');
      await tester.pump();
      // Let the async AppSession write + refresh land (5 × 100 ms, the
      // stage-3 §3.1 fixture).
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(currentPath(tester), '/kid-home');
      // The pushed route must actually be gone — asserting only `currentPath`
      // (the declarative location) hid the iteration-1 resurrect bug.
      expect(pushedPath(tester), '/kid-home');
      expect(find.byType(NestModal), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('failure: Try again reloads, Back to Pip leaves', (
      tester,
    ) async {
      await _useFake(_FailOnceRepository());
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      expect(pushedPath(tester), '/parental-gate');
      expect(find.text('Try again'), findsOneWidget);
      final retry = tester.getSemantics(find.bySemanticsLabel('Try again'));
      expect(retry.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      retry.owner!.performAction(retry.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel('Digit 1'), findsOneWidget);
      final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      expect(cancel.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('no children: fallback backdrop, gate still usable', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.text('Grown-ups only'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('six children, long UK name, 9999 coins at 320: no overflow', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      final session = GetIt.instance<AppSession>();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: 'extra$i',
                  familyId: Seed.familyId,
                  nickname: i == 0 ? 'Maximilian-Alexander' : 'Extra Child $i',
                  coins: const Value(9999),
                  createdAt: Value(
                    DateTime.utc(2026, 9, 20).add(Duration(minutes: i)),
                  ),
                ),
              );
        }
        await session.setActiveChild('extra0');
        await session.refresh();
      });
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const NestlingApp(initialRoute: '/parental-gate'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Hi Maximilian-Alexander'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('settings change after the gate closes emits no error', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      expect(pushedPath(tester), '/parental-gate');
      final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      final db = GetIt.instance<AppDatabase>();
      await (db.update(db.settings)
            ..where((s) => s.familyId.equals(Seed.familyId)))
          .write(const SettingsCompanion(kidGateEnabled: Value(false)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('failure state at 320 px and textScale 1.3 does not overflow', (
      tester,
    ) async {
      await _useFake(_FailOnceRepository(alwaysFail: true));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        const NestlingApp(initialRoute: '/parental-gate'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Back to Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('disabled gate pushed from kid home passes through', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(
        () =>
            (db.update(db.settings)
                  ..where((s) => s.familyId.equals(Seed.familyId)))
                .write(const SettingsCompanion(kidGateEnabled: Value(false))),
      );
      final semantics = tester.ensureSemantics();
      await _pushGateFromKidHome(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(pushedPath(tester), '/kid-home');
      expect(find.byType(NestModal), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('one child (Leo) renders his own Pip from the database', (
      tester,
    ) async {
      final session = GetIt.instance<AppSession>();
      await tester.runAsync(() async {
        await session.setActiveChild('leo');
        await session.refresh();
      });
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      expect(find.text('Hi Leo!'), findsOneWidget);
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.bolt);
      expect(pip.skin, PipSkin.sky);
      expect(pip.stage, 2);
      expect(pip.accessory, PipAccessory.none);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    test('the challenge day is stable across BST boundaries', () {
      final repo = ParentalGateRepositoryImpl(db: AppDatabase.memory());
      ParentalGateChallenge at(DateTime utc) => repo.challengeFor(utc);
      // BST ends Sun 25 Oct 2026 02:00 London: 00:30 BST (23:30Z on the 24th)
      // and 12:00 GMT (12:00Z) are the same London day.
      expect(
        at(DateTime.utc(2026, 10, 24, 23, 30)).id,
        at(DateTime.utc(2026, 10, 25, 12)).id,
      );
      // BST starts Sun 29 Mar 2026 01:00 London: 00:30 GMT (00:30Z) and
      // 12:00 BST (11:00Z) are the same London day.
      expect(
        at(DateTime.utc(2026, 3, 29, 0, 30)).id,
        at(DateTime.utc(2026, 3, 29, 11)).id,
      );
      // London midnight flips the challenge (23:30 vs 00:30 London).
      expect(
        at(DateTime.utc(2026, 10, 3, 22, 30)).id,
        isNot(at(DateTime.utc(2026, 10, 3, 23, 30)).id),
      );
      // GMT winter is UTC-aligned.
      expect(
        at(DateTime.utc(2027, 1, 15, 0, 30)).id,
        at(DateTime.utc(2027, 1, 15, 12)).id,
      );
    });
  });
}
