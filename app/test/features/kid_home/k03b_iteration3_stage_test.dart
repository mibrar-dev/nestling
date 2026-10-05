// K03b iteration-3 stage probes (TEST stage, iteration 3).
//
// Scope: the iteration-3 decision (ORCHESTRATOR_NOTES 06:44, K03B-BUG-6) —
// `KidHomeRepository.completeQuest` completes a quest with
// `needsApproval == false` terminally (`approved` + `decidedAt` + a
// `quest_bonus` ledger credit in the same transaction, mirroring the
// approvals `approve` path) — and every remaining BLoC event/state path that
// can touch the shared kid home while it shows the celebration.
//
// What already exists (not repeated here):
// * `k03b_all_done_bloc_test.dart` — `allDone` truth table + bloc paths
//   (load all-done/partial/empty, last-quest celebration, silent no-op,
//   failed write, stream error, load failure, silence, demo/period/empty
//   DB proofs).
// * `k03b_all_done_view_test.dart` — light+dark × 320/390/430 × 1.0/1.3
//   matrix, empty/loading/error channels, shapes, owner rules, shared design
//   system, navigation, accessibility.
// * `k03b_bugs_test.dart` — geometry proofs, ROW ORDER/ROW META, BUG-6
//   approvals-queue proof (un-skipped iteration 3).
// * `kid_home_repository_test.dart` — BUG-6 terminal write contract
//   (flip path, insert path, retry, approval quests stay pending).
// * `kid_home_bloc_test.dart` — every event for the K03 (4/6) shape,
//   including K01 profiles/selection and K02 PIN.
//
// What this file adds:
// A. blocTest/plain bloc proofs that the K01-roster, selection and K02-PIN
//    events preserve the celebration (allDone stays true).
// B. DB-backed proofs that a terminal (no-approval) completion still reaches
//    the celebration: `approved` + `decidedAt` + exactly one ledger credit,
//    absent from the P11 queue, creation order kept, bloc lands on allDone.
// C. DB-backed widget proofs that the terminal shape renders the K03b screen
//    (light + dark/320/1.3): `All done!`, `6 of 6 done`, the `+N` coin chip
//    on the no-approval card, tap targets, semantics tap → `/pip`.
// D. Source hygiene for the touched feature files: no `google_fonts`, no
//    `DateTime.now()`, `/kid-home-done` still renders `KidHomeView`.
//
// Conventions: in-memory Drift DB via `setUpTestScope` (Seed.demo), DB
// writes BEFORE the first pump (a `runAsync` cannot complete once a frame
// has been pumped), `flutter test --timeout 120s`, every pumped app ends
// with `disposeApp(tester)`, never a simulator.

import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
  pipTotalCoins: 175,
);

const KidChild _leo = KidChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '4-6',
  avatarColour: 'peach',
  coins: 45,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  happiness: 4,
  pinSet: false,
  pipTotalCoins: 60,
);

KidQuest _quest(String questId, String status, {bool needsApproval = true}) =>
    KidQuest(
      id: '$questId:maya',
      title: 'Quest $questId',
      detail: '',
      questId: questId,
      icon: 'book',
      coins: 10,
      status: status,
      needsApproval: needsApproval,
    );

/// Six quests, every one finished — the shape `kid_all_done` produces.
List<KidQuest> _allDoneItems() => <KidQuest>[
  _quest('q0', 'approved'),
  _quest('q1', 'done_pending'),
  _quest('q2', 'approved'),
  _quest('q3', 'done_pending'),
  _quest('q4', 'approved'),
  _quest('q5', 'done_pending'),
];

/// All six finished, one of them terminally (approved + no approval flag —
/// the BUG-6 write shape). Still 6 of 6: the flag never changes the count.
List<KidQuest> _terminalAllDoneItems() => <KidQuest>[
  _quest('q0', 'approved'),
  _quest('q1', 'done_pending'),
  _quest('q2', 'approved'),
  _quest('q3', 'done_pending'),
  _quest('q4', 'approved'),
  _quest('q5', 'approved', needsApproval: false),
];

/// Controllable fake: fresh streams per call (like the Drift repository), so
/// load/retry/live re-emission behave like production.
class _FakeRepo extends KidHomeRepository {
  _FakeRepo({List<KidQuest>? items}) : _items = items ?? _allDoneItems();

  List<KidQuest> _items;
  List<KidChild> profiles = const <KidChild>[_maya, _leo];

  final List<List<String>> completed = <List<String>>[];
  final List<String> selected = <String>[];
  final List<List<String>> verified = <List<String>>[];
  final StreamController<List<KidQuest>> _itemsPushed =
      StreamController<List<KidQuest>>.broadcast();
  final StreamController<List<KidChild>> _profilesPushed =
      StreamController<List<KidChild>>.broadcast();

  void pushItems(List<KidQuest> value) {
    _items = value;
    _itemsPushed.add(value);
  }

  void pushProfiles(List<KidChild> value) {
    profiles = value;
    _profilesPushed.add(value);
  }

  void failItemsNow(Object error) => _itemsPushed.addError(error);
  void failProfilesNow(Object error) => _profilesPushed.addError(error);

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    yield _items;
    yield* _itemsPushed.stream;
  }

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  Stream<List<KidChild>> watchProfiles() async* {
    yield profiles;
    yield* _profilesPushed.stream;
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async {
    verified.add(<String>[childId, pin]);
    return pin == '1234';
  }

  @override
  Future<void> setActiveChild(String childId) async {
    selected.add(childId);
  }

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    pushItems(<KidQuest>[
      for (final quest in _items)
        if (quest.questId == questId)
          KidQuest(
            id: quest.id,
            title: quest.title,
            detail: quest.detail,
            questId: quest.questId,
            icon: quest.icon,
            coins: quest.coins,
            status: 'done_pending',
            needsApproval: quest.needsApproval,
          )
        else
          quest,
    ]);
  }
}

/// Loading once the K01 roster has landed: the profiles stream answers
/// before the combined home stream does, so every load passes through it.
Matcher _loadingWithProfiles() => predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loading && state.profiles.length == 2,
);

Matcher _loadedAllDone() => predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loaded &&
      state.child?.nickname == 'Maya' &&
      state.doneCount == 6 &&
      state.totalCount == 6 &&
      state.allDone,
);

Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home-done',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls until all six (lazy) quest cards are built.
Future<void> _revealAllCards(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    if (find.byType(NestKidQuestCard).evaluate().length == 6) return;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
    await tester.pump();
  }
}

/// Marks `q-tidy` as needing no approval and finishes it plus `q-reading`
/// through the real repository — the iteration-3 terminal + pending pair
/// that reaches 6 of 6. Runs BEFORE the first pump.
Future<void> _finishTerminalPair() async {
  final db = GetIt.instance<AppDatabase>();
  await (db.update(db.quests)..where((q) => q.id.equals('q-tidy'))).write(
    const QuestsCompanion(needsApproval: Value(false)),
  );
  final repo = GetIt.instance<KidHomeRepository>();
  await repo.completeQuest('maya', 'q-tidy');
  await repo.completeQuest('maya', 'q-reading');
}

File _libSource(String relative) {
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

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // A. The K01-roster / selection / K02-PIN events preserve the celebration
  // -------------------------------------------------------------------------

  group('K03b iteration-3 bloc: roster, selection and PIN keep allDone', () {
    late _FakeRepo repo;

    blocTest<KidHomeBloc, KidHomeState>(
      'correct PIN emits checking then pinPassed and keeps the celebration',
      build: () {
        repo = _FakeRepo();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        predicate<KidHomeState>(
          (state) => state.status == KidHomeStatus.loading,
        ),
        _loadingWithProfiles(),
        _loadedAllDone(),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.pinChecking &&
              state.allDone,
        ),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.pinPassed &&
              !state.pinChecking &&
              state.allDone &&
              state.doneCount == 6,
        ),
      ],
      verify: (bloc) {
        expect(repo.verified, <List<String>>[
          <String>['maya', '1234'],
        ]);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'wrong PIN bumps pinWrongNonce and keeps the celebration',
      build: () {
        repo = _FakeRepo();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        predicate<KidHomeState>(
          (state) => state.status == KidHomeStatus.loading,
        ),
        _loadingWithProfiles(),
        _loadedAllDone(),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.pinChecking &&
              state.allDone,
        ),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              !state.pinChecking &&
              !state.pinPassed &&
              state.pinWrongNonce == 1 &&
              state.allDone &&
              state.doneCount == 6,
        ),
      ],
    );

    test('a profiles push keeps the celebration and the full roster', () async {
      repo = _FakeRepo();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.allDone, isTrue);
      repo.pushProfiles(const <KidChild>[_maya, _leo]);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, KidHomeStatus.loaded);
      expect(bloc.state.allDone, isTrue);
      expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
        'maya',
        'leo',
      ]);
      await sub.cancel();
      await bloc.close();
    });

    test('a mid-session profiles error keeps the celebration', () async {
      repo = _FakeRepo();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.allDone, isTrue);
      repo.failProfilesNow(Exception('one bad tick'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, KidHomeStatus.loaded);
      expect(bloc.state.allDone, isTrue);
      expect(bloc.state.doneCount, 6);
      await sub.cancel();
      await bloc.close();
    });

    test('selecting then handling a profile keeps the celebration', () async {
      repo = _FakeRepo();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.allDone, isTrue);
      bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repo.selected, <String>['leo']);
      expect(bloc.state.selectedProfileId, 'leo');
      expect(bloc.state.allDone, isTrue);
      bloc.add(const KidHomeSelectionHandled());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.selectedProfileId, isNull);
      expect(bloc.state.allDone, isTrue);
      expect(bloc.state.doneCount, 6);
      await sub.cancel();
      await bloc.close();
    });

    test(
      'a direct home emission with a terminal row still celebrates',
      () async {
        repo = _FakeRepo(items: const <KidQuest>[]);
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(
          KidHomeDataReceived(
            KidHomeData(child: _maya, items: _terminalAllDoneItems()),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.doneCount, 6);
        expect(bloc.state.totalCount, 6);
        expect(bloc.state.allDone, isTrue);
        expect(bloc.state.fraction, 1);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'a stream failure with a child on screen keeps the celebration',
      () async {
        repo = _FakeRepo();
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(bloc.state.allDone, isTrue);
        bloc.add(KidHomeStreamFailed(Exception('transient')));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.allDone, isTrue);
        expect(bloc.state.errorMessage, isNotNull);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'a profiles-only emission on initial sets the roster, never allDone',
      () async {
        repo = _FakeRepo(items: const <KidQuest>[]);
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(const KidHomeProfilesReceived(<KidChild>[_maya, _leo]));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        expect(bloc.state.status, KidHomeStatus.initial);
        expect(bloc.state.allDone, isFalse);
        await sub.cancel();
        await bloc.close();
      },
    );
  });

  // -------------------------------------------------------------------------
  // B. The BUG-6 terminal write still reaches the celebration (DB-backed)
  // -------------------------------------------------------------------------

  group(
    'K03B-BUG-6 terminal completion reaches the celebration (DB-backed)',
    () {
      Future<List<LedgerEntry>> tidyBonuses(AppDatabase db) {
        return (db.select(db.ledgerEntries)..where(
              (l) =>
                  l.childId.equals('maya') &
                  l.type.equals('quest_bonus') &
                  l.note.equals('Tidy your bedroom'),
            ))
            .get();
      }

      test(
        'no-approval completion is approved + decided with one credit',
        () async {
          final db = GetIt.instance<AppDatabase>();
          final repo = GetIt.instance<KidHomeRepository>();
          await (db.update(db.quests)..where((q) => q.id.equals('q-tidy')))
              .write(const QuestsCompanion(needsApproval: Value(false)));
          final before = await tidyBonuses(db);
          await repo.completeQuest('maya', 'q-tidy');

          final rows =
              await (db.select(db.questCompletions)..where(
                    (c) =>
                        c.questId.equals('q-tidy') & c.childId.equals('maya'),
                  ))
                  .get();
          expect(
            rows.where((c) => c.status == 'done_pending'),
            isEmpty,
            reason: 'no P11 queue row for a quest that needs no approval',
          );
          final done = rows.singleWhere((c) => c.status == 'approved');
          expect(done.decidedAt, isNotNull);
          final after = await tidyBonuses(db);
          expect(after.length, before.length + 1);
          expect(
            after
                .where((l) => before.every((b) => b.id != l.id))
                .single
                .amountPence,
            15,
          );
        },
      );

      test('the terminal pair lands on 6 of 6 in creation order', () async {
        final db = GetIt.instance<AppDatabase>();
        final repo = GetIt.instance<KidHomeRepository>();
        await (db.update(db.quests)..where((q) => q.id.equals('q-tidy'))).write(
          const QuestsCompanion(needsApproval: Value(false)),
        );
        await repo.completeQuest('maya', 'q-tidy');
        await repo.completeQuest('maya', 'q-reading');

        // The P11 queue gains the pending quest, never the terminal one.
        final approvals = await GetIt.instance<ApprovalsRepository>()
            .getItems();
        expect(approvals.where((a) => a.questId == 'q-tidy'), isEmpty);
        expect(approvals.where((a) => a.questId == 'q-reading'), hasLength(1));

        final home = await repo.watchHome().first;
        expect(home.child?.id, 'maya');
        expect(home.items, hasLength(6));
        expect(home.items.map((item) => item.questId).toList(), <String>[
          'q-dishwasher',
          'q-reading',
          'q-bins',
          'q-tidy',
          'q-hoover',
          'q-table',
        ], reason: 'creation order, never re-sorted by status');
        final tidy = home.items.singleWhere((item) => item.questId == 'q-tidy');
        expect(tidy.status, 'approved');
        expect(tidy.needsApproval, isFalse);
        final state = KidHomeState(
          status: KidHomeStatus.loaded,
          child: home.child,
          items: home.items,
        );
        expect(state.doneCount, 6);
        expect(state.totalCount, 6);
        expect(state.fraction, 1);
        expect(state.allDone, isTrue);
      });

      test(
        'a terminal retry credits nothing more and stays celebrated',
        () async {
          final db = GetIt.instance<AppDatabase>();
          final repo = GetIt.instance<KidHomeRepository>();
          await (db.update(db.quests)..where((q) => q.id.equals('q-tidy')))
              .write(const QuestsCompanion(needsApproval: Value(false)));
          final before = await tidyBonuses(db);
          await repo.completeQuest('maya', 'q-tidy');
          await repo.completeQuest('maya', 'q-tidy');
          await repo.completeQuest('maya', 'q-reading');

          final after = await tidyBonuses(db);
          expect(after.length, before.length + 1);
          final home = await repo.watchHome().first;
          final state = KidHomeState(
            status: KidHomeStatus.loaded,
            child: home.child,
            items: home.items,
          );
          expect(state.doneCount, 6);
          expect(state.allDone, isTrue);
        },
      );

      test(
        'bloc load after the terminal pair lands on the celebration',
        () async {
          final repo = GetIt.instance<KidHomeRepository>();
          final db = GetIt.instance<AppDatabase>();
          await (db.update(db.quests)..where((q) => q.id.equals('q-tidy')))
              .write(const QuestsCompanion(needsApproval: Value(false)));
          await repo.completeQuest('maya', 'q-tidy');
          await repo.completeQuest('maya', 'q-reading');
          final bloc = KidHomeBloc(repository: repo)
            ..add(const KidHomeLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(bloc.state.status, KidHomeStatus.loaded);
          expect(bloc.state.doneCount, 6);
          expect(bloc.state.allDone, isTrue);
          await bloc.close();
        },
      );
    },
  );

  // -------------------------------------------------------------------------
  // C. The terminal shape renders the K03b screen (DB-backed widget proofs)
  // -------------------------------------------------------------------------

  group('K03b iteration-3 widget: the terminal shape celebrates', () {
    testWidgets('light: terminal pair shows All done with the +N chip', (
      tester,
    ) async {
      await tester.runAsync(_finishTerminalPair);
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(find.text('My jar'), findsNothing);
      expect(
        find.text('You did everything today! Pip is so proud.'),
        findsOneWidget,
      );
      await _revealAllCards(tester);
      expect(find.byType(NestKidQuestCard), findsNWidgets(6));
      // ROW META third arm: the terminal card shows its `+15` coin chip and
      // no status chip; the two seeded approvals say `Mum said yes!` and the
      // three pending rows wait.
      final tidyCard = find.ancestor(
        of: find.text('Tidy your bedroom'),
        matching: find.byType(NestKidQuestCard),
      );
      expect(
        find.descendant(of: tidyCard, matching: find.text('+15')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tidyCard, matching: find.text('Waiting for Mum')),
        findsNothing,
      );
      expect(
        find.descendant(of: tidyCard, matching: find.text('Mum said yes!')),
        findsNothing,
      );
      expect(find.text('Mum said yes!'), findsNWidgets(2));
      expect(find.text('Waiting for Mum'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('dark 320px at 1.3: the terminal shape never overflows', (
      tester,
    ) async {
      await tester.runAsync(_finishTerminalPair);
      await _pump(tester, width: 320, textScale: 1.3, theme: ThemeMode.dark);
      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      await _revealAllCards(tester);
      expect(find.byType(NestKidQuestCard), findsNWidgets(6));
      expect(find.textContaining('£'), findsNothing);
      // Kid tap targets (≥ 56) on the terminal shape.
      expect(
        tester.getSize(find.byType(NestLockButton)).height,
        greaterThanOrEqualTo(NestDevice.tapKid),
      );
      expect(
        tester.getSize(find.byType(NestKidButton)).height,
        greaterThanOrEqualTo(NestDevice.tapKid),
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('terminal shape: Visit Pip exposes tap and opens /pip', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.runAsync(_finishTerminalPair);
      await _pump(tester);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Visit Pip'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await _settleRoute(tester);
      expect(pushedPath(tester), '/pip');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // D. Source hygiene for the touched feature files
  // -------------------------------------------------------------------------

  group('K03b iteration-3 source hygiene', () {
    test(
      'no google_fonts, no wall clock; /kid-home-done renders KidHomeView',
      () {
        final view = _libSource(
          'features/kid_home/presentation/views/kid_home_view.dart',
        ).readAsStringSync();
        final state = _libSource(
          'features/kid_home/presentation/bloc/kid_home_state.dart',
        ).readAsStringSync();
        final impl = _libSource(
          'features/kid_home/data/kid_home_repository_impl.dart',
        ).readAsStringSync();
        final routes = _libSource('features/kid_home/kid_home_routes.dart')
            .readAsStringSync();
        for (final source in <String>[view, state, impl, routes]) {
          expect(source.contains('google_fonts'), isFalse);
          expect(source.contains('GoogleFonts'), isFalse);
          expect(source.contains('DateTime.now('), isFalse);
        }
        // ONE kid home: the done route renders the same view, and the
        // placeholder view is gone.
        expect(routes.contains('KidHomeView'), isTrue);
        expect(routes.contains('KidHomeDoneView'), isFalse);
        expect(view.contains('_AllDoneBody'), isTrue);
        expect(view.contains('_AllDoneBar'), isTrue);
      },
    );
  });
}
