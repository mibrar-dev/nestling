// K03 (kid home) adversarial test suite — Stage 6 bug hunt, iteration 7.
//
// Iteration-1 proofs K03-BUG-1..6 all run un-skipped (fixed in iteration 2:
// repo transaction/idempotency, success-driven celebration, actionNonce,
// period scoping, router guard, per-card tap latch).
//
// Iteration-2 work (kept):
// - Period-ruling probes (daily/weekly/once, London day/week, BST edges).
// - K03-BUG-7: FIXED on main (`4751c52` parses `DISABLE_ANIMATIONS=1` as
//   true). The proof asserts both `kDisableAnimations` and
//   `MediaQuery.disableAnimationsOf` inside the pumped home; it now runs in
//   the plain suite AND under `--dart-define=DISABLE_ANIMATIONS=1`.
// - K03-BUG-8/9 fixed mid-loop (per-quest celebrations, gate tap latch);
//   proofs run un-skipped.
//
// Iteration-3/4 work:
// - Owner alignment probe (20 px gutters shared by bar, cards, dock) — passes.
// - Failure / empty-quests states use PipAvatar, never v1 `pip_stage_*.svg`
//   — passes.
// - K03-BUG-10 (owner BOTTOM EDGE): fixed in iteration 4; light and dark
//   proofs assert a surface-filled box reaches the physical edge.
// - K03-BUG-11 (fixed iteration 5): silent no-op completion resets the latch
//   and evicts the pending entry. Proof runs un-skipped.
//
// Iteration-5 work:
// - Copy probe: the visible strings match the HTML source character for
//   character (ASCII apostrophes in "Let's"/"Today's"/"Mum", en dash in the
//   seed quest title) — passes.
// - K03-BUG-12 (un-skipped iteration 6): CHILD ORDER ruling now holds —
//   shared `watchChildren` orders by `createdAt` (+ `rowid`); proof runs
//   un-skipped, plus a six-children-in-one-second probe.
//
// Iteration-6 work:
// - Font migration verified: no `google_fonts` anywhere; kid styles are
//   bundled Nunito with `letterSpacing: 0` (probe).
// - K03-BUG-13 (FIXED, iteration 8): the shared explicit size mode centred the
//   scene in a nominal 419.35 px width — nest/Pip sat +34.7 px off-centre at
//   390, +69.7 px at 320 (nest overflowed its slot by 59.7 px) and +14.7 px at
//   430. `shared/pet_stage_explicit` (SHARED_REQUEST #13) lays the scene out
//   against the real content box and centres it there; K03 passes the
//   design's own box (236×188, Pip 152). All three width proofs now run.
// - K03-BUG-14 (FIXED, iteration 8): the same mode rendered a SQUARE nest, so
//   the pet block was 276 px vs the design's 236 px and the lower stack
//   shifted down; `nestHeight` makes the box height expressible. Proof runs;
//   `kid_home_geometry_test.dart` pins hearts 438 / first card 549 at real
//   fonts (shared/speech_tail moved the rows up ~9 px: the tail is now CSS
//   `::after` overflow).
//
// Iteration-7 work:
// - Landed iteration-7 UI work probed: `NestBalancedText` title at the 20 px
//   left edge, per-quest tile tints (dishwasher sky / reading lilac / tidy
//   peach), dock `wrapLabel: false` — all pass.
//
// Iteration-8 work:
// - K03-BUG-15 (FIXED, iteration 8): "Try again" used to stack live
//   subscriptions — three failed loads left a peak of 3 concurrent source
//   subscriptions (the watchActiveChild + watchItems chain) instead of ≤2, and
//   none were released. The load handler now owns a guarded
//   `StreamSubscription` (cancel-before-reload, released on error and on
//   `close()`), so stream output re-enters as the bloc-internal
//   `KidHomeDataReceived` / `KidHomeStreamFailed` events. Both proofs run
//   un-skipped and green: this file's copy of the invariant, and the
//   bloc-level one in `kid_home_bloc_test.dart`. Cross-ref: review finding 6.
// - Mid-session stream errors now keep the loaded list (`status` only drops to
//   `failure` when there is no child yet), so a single failed watch tick no
//   longer replaces the screen the child is looking at.
// - Stage-6 iteration-8 probes: a mid-session error keeps the list and a
//   fresh load recovers (the subscription was released); a real-repo child
//   switch never pairs the new child with the old child's items.
//
// Iteration-9 work (ACCESSIBILITY ACTIONS):
// - Every interactive control exposes `SemanticsAction.tap` on its announced
//   node: to-do check, card body, lock, dock Pip/Shop/My jar, Choose and
//   Try again — asserted via `getSemantics(...).getSemanticsData()`.
// - `performAction(tap)` reaches the real outcome: the check flips the DB row
//   and opens K05, the card body opens K04, the lock opens P17, Choose opens
//   the picker. K03's two `excludeSemantics: true` sites (header, hearts)
//   are display-only, not controls.
//
// Iteration-10 work:
// - The shared pet-seating fix landed; K03 adopted `_kNestBoxHeight: 188`
//   (nestW 236 / pipH 152 unchanged). All pet proofs stay green and the
//   real-font geometry pin now asserts the painted outline (198×86), rim 278
//   and Pip's feet 301. No new bugs found in this stage.
//
// The suite has NO skipped tests: every proof below runs in the plain suite.
// (If you add one, do not park it to get green — see RULES.)
//
// Probes that pass are kept as evidence for the "checked, clean" categories
// (contrast, overflow, persistence, money rounding, deep links).

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps the full app at [route] with optional kid mode / width / scale.
Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home',
  bool kidMode = true,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (kidMode) {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls the quest list until the (lazy) card column is built.
Future<void> _revealCards(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 10; i++) {
    if (find.byType(NestKidQuestCard).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(list, const Offset(0, -200));
    await tester.pump();
  }
}

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K03-BUG-1 — rapid double tap inserts a duplicate pending completion
  // -------------------------------------------------------------------------

  test('K03-BUG-1 repo: second completeQuest after done_pending creates a '
      'duplicate row', () async {
    final db = GetIt.instance<AppDatabase>();
    final repo = KidHomeRepositoryImpl(db: db);
    await repo.completeQuest('maya', 'q-reading');
    await repo.completeQuest('maya', 'q-reading');
    final rows = await db.select(db.questCompletions).get();
    final mine = rows
        .where((r) => r.questId == 'q-reading' && r.childId == 'maya')
        .toList();
    expect(
      mine.where((r) => r.status == 'done_pending'),
      hasLength(1),
      reason: 'a quest must have at most one pending completion',
    );
  });

  testWidgets(
    'K03-BUG-1 widget: double-tapping the check creates two pending rows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      // Two taps inside one frame: the route push has not been laid out yet,
      // so both hit the same check.
      await tester.tap(check);
      await tester.tap(check);
      await _settle(tester);
      final rows = await tester.runAsync(
        () => (GetIt.instance<AppDatabase>().select(
          GetIt.instance<AppDatabase>().questCompletions,
        )..where((c) => c.questId.equals('q-reading'))).get(),
      );
      semantics.dispose();
      await disposeApp(tester);
      expect(
        rows!.where((r) => r.status == 'done_pending'),
        hasLength(1),
        reason: 'rapid double tap must be idempotent',
      );
    },
  );

  // -------------------------------------------------------------------------
  // K03-BUG-2 — the celebration opens even when the save fails
  // -------------------------------------------------------------------------

  testWidgets('K03-BUG-2: a failed completion still opens the celebration', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _useFakeRepository(_FailSaveRepository());
    await _pump(tester);
    await _revealCards(tester);
    final check = find.bySemanticsLabel('Mark done').first;
    await tester.ensureVisible(check);
    await tester.pump();
    await tester.tap(check);
    await _settle(tester);
    expect(
      find.text('K05 Quest complete'),
      findsNothing,
      reason: 'do not celebrate a quest the database never recorded',
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K03-BUG-3 — identical failures after the first are never surfaced
  // -------------------------------------------------------------------------

  test('K03-BUG-3: state keeps the first actionError forever so a second '
      'identical failure is not announced', () async {
    final repo = _FailSaveRepository();
    final bloc = KidHomeBloc(repository: repo);
    final errors = <String?>[];
    final sub = bloc.stream.listen((s) => errors.add(s.actionError));
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 10,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-tidy',
        coins: 15,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    await bloc.close();
    expect(
      errors.where((e) => e != null),
      hasLength(2),
      reason: 'the second failed tap must also surface feedback',
    );
  });

  // -------------------------------------------------------------------------
  // K03-BUG-4 — "done today" counts completions from previous London days
  //
  // FIXED in iteration 2 via the main-branch ruling (PERIODS): the repo
  // scopes status to the quest's current London period with
  // `countsForCurrentPeriod`, so this proof runs un-skipped.
  // -------------------------------------------------------------------------

  testWidgets(
    'K03-BUG-4: a completion from a previous London day still reads as '
    'done today',
    (tester) async {
      final db = GetIt.instance<AppDatabase>();
      final thirtyHoursAgo = appNowUtc().subtract(const Duration(hours: 30));
      expect(
        toLondon(thirtyHoursAgo).day == toLondon(appNowUtc()).day,
        isFalse,
        reason: '30h always crosses a London calendar day',
      );
      await tester.runAsync(() async {
        await db.delete(db.questCompletions).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(10),
                createdAt: Value(thirtyHoursAgo),
                decidedAt: Value(thirtyHoursAgo),
              ),
            );
      });
      await _pump(tester);
      expect(
        find.text('0 done today'),
        findsOneWidget,
        reason: 'yesterday\u2019s approval is not done today',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K03-BUG-5 — kid-mode guard misses parent routes added after the list
  // -------------------------------------------------------------------------

  testWidgets(
    'K03-BUG-5: kid mode can deep-link to /today-empty without the gate',
    (tester) async {
      await _pump(tester, route: '/today-empty');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    },
  );

  testWidgets(
    'K03-BUG-5: kid mode can deep-link to /quest-editor without the gate',
    (tester) async {
      await _pump(tester, route: '/quest-editor');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // Edge-case probes: passing checks + further skipped bug proofs
  // -------------------------------------------------------------------------

  group('edge-case probes', () {
    testWidgets('guard still blocks /today in kid mode', (tester) async {
      await _pump(tester, route: '/today');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('deep link to /kid-home in kid mode renders the home', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('deep link to /kid-home with no active child offers picker', (
      tester,
    ) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('zero children, long nickname and 9999 coins at 320/1.3 '
        'do not overflow', (tester) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'max',
                familyId: Seed.familyId,
                nickname: 'Maximilian-Alexander',
                avatarColour: const Value('sky'),
                coins: const Value(9999),
                happiness: const Value(0),
              ),
            );
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('max')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester, width: 320, textScale: 1.3);
      expect(find.text('Hi Maximilian-Alexander!'), findsOneWidget);
      expect(find.text('9999'), findsOneWidget);
      expect(find.text('0 done today'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a family with a single child renders the home', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.childId.equals('leo'))).go();
        await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      });
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('six children in the family do not change the home', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: 'extra$i',
                  familyId: Seed.familyId,
                  nickname: 'Extra Child $i',
                ),
              );
        }
      });
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('zero-cost and long quests render with integer coins only', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-free',
                familyId: Seed.familyId,
                title:
                    'A very long quest title that should wrap to two lines '
                    'without losing its coin reward',
                coins: const Value(0),
                assigneeChildId: const Value('maya'),
              ),
            );
      });
      await _pump(tester);
      await _revealCards(tester);
      expect(find.textContaining('\u00a3'), findsNothing);
      expect(find.text('+0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('back from the celebration returns to the home with the '
        'card flipped', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      await _revealCards(tester);
      expect(find.text('Waiting for Mum'), findsNWidgets(3));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('K03-BUG-6: double-tapping a quest card stacks two detail '
        'routes', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final card = find.text('Reading \u2013 20 minutes');
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await tester.tap(card);
      await _settle(tester);
      expect(find.text('K04 Quest detail'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(
        find.text('Hi Maya!'),
        findsOneWidget,
        reason: 'one back press must leave the detail',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('K03-BUG-6: double-tapping the check stacks two celebration '
        'routes', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(
        find.text('Hi Maya!'),
        findsOneWidget,
        reason: 'one back press must leave the celebration',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    test('verified clean: a late failure emitted after bloc close does not '
        'throw', () async {
      final repo = _SlowFailRepository();
      final bloc = KidHomeBloc(repository: repo);
      _load(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _complete(bloc, 'q-reading', 10);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await bloc.close();
      // The write fails only after the bloc is closed.
      repo.fail();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('Drift file persistence survives a database reopen', () async {
      final dir = Directory.systemTemp.createTempSync('k03_restart_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/nestling.db');
      final db1 = AppDatabase(NativeDatabase(file));
      await Seed.demo(db1);
      await KidHomeRepositoryImpl(db: db1).completeQuest('maya', 'q-reading');
      await db1.close();
      final db2 = AppDatabase(NativeDatabase(file));
      final items = await KidHomeRepositoryImpl(db: db2).getItems();
      await db2.close();
      expect(
        items.singleWhere((q) => q.questId == 'q-reading').status,
        'done_pending',
      );
    });

    test('K03 token pairs meet WCAG contrast in light and dark', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final pairs = <String, (Color, Color)>{
        'light ink on skyTop': (light.ink, light.kidSkyTop),
        'light ink on skyBottom': (light.ink, light.kidSkyBottom),
        'light ink2 on skyTop': (light.ink2, light.kidSkyTop),
        'light coinInk on coinTint': (light.coinInk, light.coinTint),
        'light leafInk on leafTint': (light.leafInk, light.leafTint),
        'light onLeaf on leaf': (light.onLeaf, light.leaf),
        'light onAccent on lilacStrong': (light.onAccent, light.lilacStrong),
        'light onWarm on coin': (light.onWarm, light.coin),
        'dark ink on skyTop': (dark.ink, dark.kidSkyTop),
        'dark ink2 on skyTop': (dark.ink2, dark.kidSkyTop),
        'dark coinInk on coinTint': (dark.coinInk, dark.coinTint),
        'dark leafInk on leafTint': (dark.leafInk, dark.leafTint),
        'dark onLeaf on leaf': (dark.onLeaf, dark.leaf),
        'dark onAccent on lilacStrong': (dark.onAccent, dark.lilacStrong),
        'dark onWarm on coin': (dark.onWarm, dark.coin),
        'dark ink on surface': (dark.ink, dark.surface),
      };
      for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
        expect(
          _contrast(a, b),
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 2 — mandated PIP rendering probes
  // -------------------------------------------------------------------------

  group('mandated Pip', () {
    testWidgets('the home renders the child\u2019s own PipAvatar attributes', (
      tester,
    ) async {
      await _pump(tester);
      final avatars = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(avatars, isNotEmpty);
      expect(avatars.first.style, PipStyle.mochi);
      expect(avatars.first.skin, PipSkin.sunny);
      expect(avatars.first.accessory, PipAccessory.none);
      expect(avatars.first.stage, 3);
      await disposeApp(tester);
    });

    testWidgets('Leo deep-link uses bolt/sky/stage 2 from the database', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);
      expect(find.text('Hi Leo!'), findsOneWidget);
      // Seed change e972b46: Leo's daily school-bag approval is on the story
      // day, so the period rule still yields "Leo 2 of 4".
      expect(find.text('2 done today'), findsOneWidget);
      expect(find.text('2 of 4 done'), findsOneWidget);
      final avatars = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(avatars, isNotEmpty);
      expect(avatars.first.style, PipStyle.bolt);
      expect(avatars.first.skin, PipSkin.sky);
      expect(avatars.first.stage, 2);
      await disposeApp(tester);
    });

    testWidgets('a broken pipStage (0 then 9) is clamped, never asserted', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipStage: Value(0)),
        );
      });
      await _pump(tester);
      expect(tester.takeException(), isNull);
      var avatar = tester.widgetList<PipAvatar>(find.byType(PipAvatar)).first;
      expect(avatar.stage, 1);
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipStage: Value(9)),
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      avatar = tester.widgetList<PipAvatar>(find.byType(PipAvatar)).first;
      expect(avatar.stage, 4);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 3 — owner rules (bottom edge, alignment) and state art
  // -------------------------------------------------------------------------

  group('owner rules', () {
    testWidgets('20px gutters shared by bar, cards and dock', (tester) async {
      await _pump(tester);
      await _revealCards(tester);
      expect(
        tester.getTopLeft(find.byType(NestProgress)).dx,
        closeTo(NestSpacing.padSide, 0.01),
      );
      expect(
        tester.getTopRight(find.byType(NestProgress)).dx,
        closeTo(390 - NestSpacing.padSide, 0.01),
      );
      final firstCard = find.byType(NestKidQuestCard).first;
      expect(
        tester.getTopLeft(firstCard).dx,
        closeTo(NestSpacing.padSide, 0.01),
      );
      expect(
        tester.getTopRight(firstCard).dx,
        closeTo(390 - NestSpacing.padSide, 0.01),
      );
      final pipButton = find.ancestor(
        of: find.text('Pip'),
        matching: find.byType(NestKidButton),
      );
      final jarButton = find.ancestor(
        of: find.text('My jar'),
        matching: find.byType(NestKidButton),
      );
      expect(
        tester.getTopLeft(pipButton).dx,
        closeTo(NestSpacing.padSide, 0.01),
      );
      expect(
        tester.getTopRight(jarButton).dx,
        closeTo(390 - NestSpacing.padSide, 0.01),
      );
      await disposeApp(tester);
    });

    testWidgets('the failure state uses PipAvatar, never v1 art', (
      tester,
    ) async {
      await _useFakeRepository(_FailLoadRepository());
      await _pump(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);
      expect(
        _svgAssetNames(tester).where((a) => a.contains('pip_stage_')),
        isEmpty,
      );
      await disposeApp(tester);
    });

    testWidgets('the empty-quests state uses the child\u2019s own PipAvatar', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'nina',
                familyId: Seed.familyId,
                nickname: 'Nina',
              ),
            );
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('nina')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);
      expect(find.text('No quests today'), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);
      expect(
        _svgAssetNames(tester).where((a) => a.contains('pip_stage_')),
        isEmpty,
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 2 — period ruling probes (daily / weekly / once)
  // -------------------------------------------------------------------------

  group('period ruling', () {
    test('London day/week starts are inclusive; older completions are out', () {
      final now = DateTime.utc(2026, 10, 24, 12); // Sat 24 Oct, BST
      final dayStart = londonDayStartUtc(now);
      expect(dayStart, DateTime.utc(2026, 10, 23, 23));
      expect(countsForCurrentPeriod('daily', dayStart, now), isTrue);
      expect(
        countsForCurrentPeriod(
          'daily',
          dayStart.subtract(const Duration(seconds: 1)),
          now,
        ),
        isFalse,
      );

      final weekStart = londonWeekStartUtc(now);
      expect(weekStart, DateTime.utc(2026, 10, 18, 23)); // Mon 19 Oct, BST
      expect(countsForCurrentPeriod('weekly', weekStart, now), isTrue);
      expect(
        countsForCurrentPeriod(
          'weekly',
          weekStart.subtract(const Duration(seconds: 1)),
          now,
        ),
        isFalse,
      );

      // once: any age still counts.
      expect(countsForCurrentPeriod('once', DateTime.utc(2020), now), isTrue);
    });

    test('BST/GMT switch days start on the right UTC instants', () {
      // BST ends Sun 25 Oct 2026 01:00 UTC.
      expect(
        londonDayStartUtc(DateTime.utc(2026, 10, 24, 12)),
        DateTime.utc(2026, 10, 23, 23),
      );
      expect(
        londonDayStartUtc(DateTime.utc(2026, 10, 26, 12)),
        DateTime.utc(2026, 10, 26),
      );
      // BST starts Sun 29 Mar 2026 01:00 UTC.
      expect(
        londonDayStartUtc(DateTime.utc(2026, 3, 29, 12)),
        DateTime.utc(2026, 3, 29),
      );
      expect(
        londonDayStartUtc(DateTime.utc(2026, 3, 30, 12)),
        DateTime.utc(2026, 3, 29, 23),
      );
    });

    test('repo: a daily completion just before the London day start reads '
        'to_do; at the start it counts', () async {
      final db = GetIt.instance<AppDatabase>();
      final repo = KidHomeRepositoryImpl(db: db);
      final dayStart = londonDayStartUtc(appNowUtc());
      await (db.delete(
        db.questCompletions,
      )..where((c) => c.questId.equals('q-reading'))).go();
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('approved'),
              coins: const Value(10),
              createdAt: Value(dayStart.subtract(const Duration(seconds: 1))),
            ),
          );
      var items = await repo.getItems();
      expect(
        items.singleWhere((q) => q.questId == 'q-reading').status,
        'to_do',
      );
      await (db.update(db.questCompletions)
            ..where((c) => c.questId.equals('q-reading')))
          .write(QuestCompletionsCompanion(createdAt: Value(dayStart)));
      items = await repo.getItems();
      expect(
        items.singleWhere((q) => q.questId == 'q-reading').status,
        'approved',
      );
    });

    test(
      'repo: a weekly completion outside this London week reads to_do',
      () async {
        final db = GetIt.instance<AppDatabase>();
        final repo = KidHomeRepositoryImpl(db: db);
        final weekStart = londonWeekStartUtc(appNowUtc());
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals('q-bins'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-bins',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(15),
                createdAt: Value(
                  weekStart.subtract(const Duration(seconds: 1)),
                ),
              ),
            );
        var items = await repo.getItems();
        expect(items.singleWhere((q) => q.questId == 'q-bins').status, 'to_do');
        // The week start itself is inclusive, so it always counts.
        await (db.update(db.questCompletions)
              ..where((c) => c.questId.equals('q-bins')))
            .write(QuestCompletionsCompanion(createdAt: Value(weekStart)));
        items = await repo.getItems();
        expect(
          items.singleWhere((q) => q.questId == 'q-bins').status,
          'approved',
        );
      },
    );

    test('repo: a once quest keeps an old completion forever', () async {
      final db = GetIt.instance<AppDatabase>();
      final repo = KidHomeRepositoryImpl(db: db);
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-once',
              familyId: Seed.familyId,
              title: 'Make a time capsule',
              repeatRule: const Value('once'),
              assigneeChildId: const Value('maya'),
            ),
          );
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-once',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('approved'),
              coins: const Value(10),
              createdAt: Value(appNowUtc().subtract(const Duration(days: 400))),
            ),
          );
      final items = await repo.getItems();
      expect(
        items.singleWhere((q) => q.questId == 'q-once').status,
        'approved',
      );
    });

    testWidgets('retry after a failed completion still celebrates', (
      tester,
    ) async {
      final repo = _ToggleFailRepository();
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(repo);
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsNothing);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      repo.failComplete = false;
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('kid mode also gates /add-children and '
        '/pocket-money-setup', (tester) async {
      await _pump(tester, route: '/add-children');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
      await _pump(tester, route: '/pocket-money-setup');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 2 — new bug proofs
  // -------------------------------------------------------------------------

  /// RULES §6: `DISABLE_ANIMATIONS=1` must render still frames, and only
  /// when it was actually asked for. The shared parse is fixed (SHARED_REQUEST
  /// #5: `env_flags.dart` also compares the literal `'1'`), so this proof no
  /// longer needs a conditional skip — it runs in the plain suite and asserts
  /// the flag end to end in BOTH modes:
  ///   plain run → motion stays on (a silent always-on flag would freeze the
  ///               whole app),
  ///   `--dart-define=DISABLE_ANIMATIONS=1` → still frames everywhere.
  testWidgets('K03-BUG-7: DISABLE_ANIMATIONS is honoured in both directions', (
    tester,
  ) async {
    const requested = String.fromEnvironment('DISABLE_ANIMATIONS') != '';
    await _pump(tester);
    final context = tester.element(find.byType(PipAvatar));
    expect(
      kDisableAnimations,
      requested,
      reason: requested
          ? 'the documented =1 form must parse, or Rive Pip keeps animating '
                'and the frame never stabilises'
          : 'without the define, motion must stay on',
    );
    expect(
      MediaQuery.disableAnimationsOf(context),
      requested,
      reason: 'the app root must forward the flag to every screen',
    );
    await disposeApp(tester);
  });

  test('K03-BUG-8: a failed second completion swallows the first success '
      '(no celebration)', () async {
    final repo = _GatedCompletionRepository();
    final bloc = KidHomeBloc(repository: repo);
    final sub = bloc.stream.listen((_) {});
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 10,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-tidy',
        coins: 15,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The first write lands and flips its card; the pending set still holds
    // the second quest, so the flip celebrates the first quest anyway.
    repo.releaseFirst();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      bloc.state.justCompletedQuestId,
      'q-reading',
      reason: 'a saved quest must be celebrated even if the next tap fails',
    );
    repo.failSecond();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    await bloc.close();
  });

  testWidgets('K03-BUG-9: double-tapping the lock stacks two gate routes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final lock = find.bySemanticsLabel('Grown-ups');
    await tester.tap(lock);
    await tester.tap(lock);
    await _settle(tester);
    expect(find.text('P17 Parental gate'), findsOneWidget);
    await tester.pageBack();
    await _settle(tester);
    expect(
      find.text('Hi Maya!'),
      findsOneWidget,
      reason: 'one back press must leave the gate',
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets(
    'K03-BUG-10: the dock surface must run to the physical bottom edge',
    (tester) async {
      // Simulate the iPhone home inset; the owner rule says the dock's own
      // surface colour must fill from its top border to the screen edge —
      // no meadow/sky strip around the home-indicator area.
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(tester);
      const scheme = NestColors.light;
      final screenH =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final surfaceBoxes = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == scheme.surface,
      );
      final covering = surfaceBoxes.evaluate().where((element) {
        final rect = tester.getRect(
          find.byElementPredicate((e) => identical(e, element)),
        );
        return rect.left <= 0.5 &&
            rect.right >= 389.5 &&
            rect.bottom >= screenH - 0.5;
      });
      expect(
        covering,
        isNotEmpty,
        reason:
            'the dock surface must reach the screen bottom; a coloured '
            'strip currently shows below the dock',
      );
      await disposeApp(tester);
    },
  );

  testWidgets(
    'K03-BUG-10 dark: the dock surface must also reach the edge in dark mode',
    (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(tester, theme: ThemeMode.dark);
      const scheme = NestColors.dark;
      final screenH =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final surfaceBoxes = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == scheme.surface,
      );
      final covering = surfaceBoxes.evaluate().where((element) {
        final rect = tester.getRect(
          find.byElementPredicate((e) => identical(e, element)),
        );
        return rect.left <= 0.5 &&
            rect.right >= 389.5 &&
            rect.bottom >= screenH - 0.5;
      });
      expect(
        covering,
        isNotEmpty,
        reason: 'no meadow/sky strip below the dark dock either',
      );
      await disposeApp(tester);
    },
  );

  testWidgets(
    'K03-BUG-11: a silent no-op completion leaves the check latched',
    (tester) async {
      final repo = _SilentNoopRepository();
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(repo);
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settle(tester);
      // The write returned without an error and without a flip (quest row
      // gone). No celebration, no SnackBar — and the check must be tappable
      // again so the child can retry.
      expect(find.text('K05 Quest complete'), findsNothing);
      await tester.tap(check);
      await _settle(tester);
      expect(
        repo.calls,
        hasLength(2),
        reason: 'a retry must reach the repository after a silent no-op',
      );
      semantics.dispose();
      await disposeApp(tester);
    },
  );

  test('K03-BUG-12: profiles come in added order (Maya then Leo), never '
      'alphabetical', () async {
    final profiles = await GetIt.instance<KidHomeRepository>()
        .watchProfiles()
        .first;
    expect(profiles.map((child) => child.nickname).toList(), <String>[
      'Maya',
      'Leo',
    ], reason: 'CHILD ORDER ruling: order added, not alphabetical');
  });

  // -------------------------------------------------------------------------
  // Iteration-6 proofs — the shared explicit pet-slot size mode
  // -------------------------------------------------------------------------

  /// K03-BUG-13 (FIXED, iteration 8): the pet slot was composed in a stage box
  /// wider than the slot itself, so the nest and the Pip sat right of centre at
  /// every width and were clipped at 320.
  ///
  /// Design: `.k3-pet` centres `.nest`/`.pip` (`left: 50%` +
  /// `translateX(-50%)`) in the content column.
  /// Cause (shared, SHARED_REQUEST #13): `NestPetStage` explicit-size mode
  /// computed `stageW = nestW / 0.62 = 419.35` and `PipNestFallback` positioned
  /// children against that nominal width, but the box was clamped by the 350 px
  /// content box (390 − 2×20 gutters), so every child shifted right by
  /// `(419.35 − 350) / 2 = 34.7` px.
  /// Fix (shared, `shared/pet_stage_explicit`): explicit mode lays the scene
  /// out against `constraints.maxWidth` and centres nest + Pip in it, scaling
  /// the whole scene down instead of overflowing; K03 passes the design's own
  /// box (`nestWidth: 236, nestHeight: 188, fixedPipHeight: 152`), which paints
  /// the 198 px visible outline the report asks for.
  /// Repro: `flutter test --plain-name K03-BUG-13`.
  /// Measured (light, 390×844, no insets): nest and Pip both on the slot axis
  /// at 320 / 390 / 430, never past the slot's right edge.
  for (final width in <double>[320, 390, 430]) {
    testWidgets('K03-BUG-13: the pet slot stays centred at ${width.toInt()}px', (
      tester,
    ) async {
      await _pump(tester, width: width);
      final slot = tester.getRect(find.byType(PipNestFallback));
      final nest = tester.getRect(_nestSvgFinder().first);
      final pip = tester.getRect(find.byType(PipAvatar));
      expect(
        nest.center.dx,
        closeTo(slot.center.dx, 1),
        reason:
            '.k3-pet centres the nest; the slot is '
            '${slot.left.toStringAsFixed(1)}…${slot.right.toStringAsFixed(1)} '
            '(centre ${slot.center.dx.toStringAsFixed(1)}), the nest is '
            '${nest.left.toStringAsFixed(1)}…${nest.right.toStringAsFixed(1)}',
      );
      expect(pip.center.dx, closeTo(slot.center.dx, 1));
      expect(
        nest.right,
        lessThanOrEqualTo(slot.right + 0.5),
        reason: 'the nest must never be cut off by the slot edge',
      );
      await disposeApp(tester);
    });
  }

  /// K03-BUG-14 (FIXED, iteration 8): the same mode rendered a *square* nest
  /// box, so the pet block was ~40 px taller than the design's `.k3-pet` box
  /// and pushed the whole lower stack down (hearts 494 px instead of 448).
  /// Design: `.k3-pet` is a 236 px slot.
  /// Fix (shared, SHARED_REQUEST #13): `nestHeight` makes the box height
  /// expressible (the art fills the box, so the visible outline stays
  /// `nestWidth × 0.84`); K03 passes `nestHeight: 188` under its 236-wide box
  /// (`shared/pet_stage_seat` raised it from 156 so the bowl keeps the design's
  /// proportions and Pip sits inside it), and `kid_home_geometry_test.dart`
  /// pins the rows below at real fonts.
  /// Repro: `flutter test --plain-name K03-BUG-14`.
  testWidgets('K03-BUG-14: the pet block keeps the design 236 px slot height', (
    tester,
  ) async {
    await _pump(tester);
    final stage = tester.getRect(find.byType(PipNestFallback));
    expect(
      stage.height,
      closeTo(236, 2),
      reason:
          '.k3-pet is 236 px tall; a taller block moves the hearts, the '
          'section title, the progress bar and every card down (orchestrator '
          'QA targets for iteration 5: hearts ≈443 on the 390×844 device)',
    );
    await disposeApp(tester);
  });

  testWidgets('copy matches the K03 HTML character-for-character', (
    tester,
  ) async {
    await _pump(tester);
    await _revealCards(tester);
    // ASCII apostrophes exactly as authored in the HTML source.
    expect(find.text('Hi Maya!'), findsOneWidget);
    expect(find.text("Let's do some quests!"), findsOneWidget);
    expect(find.text('Pip is happy today'), findsOneWidget);
    expect(find.text("Today's quests"), findsOneWidget);
    expect(find.text('Waiting for Mum'), findsNWidgets(2));
    // Design en dash in the seed quest title (&ndash; in the HTML).
    expect(find.text('Reading \u2013 20 minutes'), findsOneWidget);
    expect(find.text('My jar'), findsOneWidget);
    await disposeApp(tester);
  });

  test('child order holds with six children in the same second', () async {
    final db = GetIt.instance<AppDatabase>();
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: 'zoe',
            familyId: Seed.familyId,
            nickname: 'Zoe',
          ),
        );
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: 'adam',
            familyId: Seed.familyId,
            nickname: 'Adam',
          ),
        );
    final profiles = await GetIt.instance<KidHomeRepository>()
        .watchProfiles()
        .first;
    expect(profiles.map((child) => child.nickname).toList(), <String>[
      'Maya',
      'Leo',
      'Zoe',
      'Adam',
    ], reason: 'insertion order, never alphabetical');
  });

  test('kid type styles are bundled Nunito with zero tracking', () {
    for (final style in <TextStyle>[
      NestType.kidName(),
      NestType.kidTitle(),
      NestType.kidCaption(),
      NestType.kidChipLabel(),
      NestType.kidBody(),
    ]) {
      expect(style.fontFamily, 'Nunito');
      expect(style.letterSpacing, 0, reason: 'no Material tracking');
    }
  });

  testWidgets('title uses NestBalancedText and keeps the 20px left edge', (
    tester,
  ) async {
    await _pump(tester);
    final title = find.byType(NestBalancedText);
    expect(title, findsOneWidget);
    expect(
      tester.getTopLeft(title).dx,
      closeTo(NestSpacing.padSide, 0.01),
      reason: '.kid-title is left-aligned at the owner 20px gutter',
    );
    await disposeApp(tester);
  });

  testWidgets('quest tiles carry the per-quest tints', (tester) async {
    await _pump(tester);
    await _revealCards(tester);
    final cards = tester
        .widgetList<NestKidQuestCard>(find.byType(NestKidQuestCard))
        .toList();
    Color? tintFor(String title) {
      return cards.firstWhere((card) => card.title == title).tileBackground;
    }

    const scheme = NestColors.light;
    expect(tintFor('Empty the dishwasher'), scheme.skyTint);
    expect(tintFor('Reading \u2013 20 minutes'), scheme.lilacTint);
    expect(tintFor('Tidy your bedroom'), scheme.peachTint);
    expect(
      tintFor('Put the bins out'),
      isNull,
      reason: 'unmapped icons keep the neutral surface2 tile',
    );
    await disposeApp(tester);
  });

  testWidgets('dock labels never wrap', (tester) async {
    await _pump(tester);
    final buttons = tester
        .widgetList<NestKidButton>(find.byType(NestKidButton))
        .toList();
    expect(buttons, hasLength(3));
    expect(buttons.every((button) => !button.wrapLabel), isTrue);
    await disposeApp(tester);
  });

  // K03-BUG-15 (FIXED, iteration 8 / logic layer): the load handler now owns a
  // single `StreamSubscription` and cancels it before every reload and in
  // `close()` (review finding 6). The bugs-stage proof is un-skipped; the
  // bloc-suite copy of the same invariant lives in `kid_home_bloc_test.dart`
  // (K03-BUG-15: a retry must not stack a second live subscription).
  test('K03-BUG-15: retry does not stack live stream subscriptions', () async {
    final repo = _SubCountingRepository();
    final bloc = KidHomeBloc(repository: repo);
    final sub = bloc.stream.listen((_) {});
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 40));
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 40));
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      repo.peak,
      lessThanOrEqualTo(2),
      reason: 'one live child + one live items subscription, never stacked',
    );
    expect(repo.active, 0, reason: 'failed loads release their sources');
    await sub.cancel();
    await bloc.close();
  });

  test(
    'K03 probe: mid-session error keeps the list and a load recovers',
    () async {
      final repo = _PushableHomeRepository();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      repo.push(const KidHomeData(child: _maya, items: _items2));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.status, KidHomeStatus.loaded);

      repo.pushError(Exception('watch down'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        bloc.state.status,
        KidHomeStatus.loaded,
        reason: 'the child keeps the last list on a mid-session watch error',
      );
      expect(bloc.state.items, hasLength(2));

      // The loaded screen has no retry affordance, but the subscription was
      // released, so a fresh load event recovers.
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.listens, 2);
      repo.push(const KidHomeData(child: _maya, items: _items2));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.status, KidHomeStatus.loaded);
      await sub.cancel();
      await bloc.close();
    },
  );

  test(
    'K03 probe: a child switch never pairs the new child with the old list',
    () async {
      final db = GetIt.instance<AppDatabase>();
      final repo = KidHomeRepositoryImpl(db: db);
      final states = <KidHomeData>[];
      final sub = repo.watchHome().listen(states.add);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value<String?>('leo')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await sub.cancel();
      final loaded = states.where((state) => state.child != null).toList();
      expect(loaded, isNotEmpty);
      for (final state in loaded) {
        expect(
          state.items.every((q) => q.id.endsWith(':${state.child!.id}')),
          isTrue,
          reason: 'items must belong to the paired child',
        );
      }
      expect(loaded.any((state) => state.child!.nickname == 'Leo'), isTrue);
    },
  );

  // -------------------------------------------------------------------------
  // Iteration-9 proofs — ACCESSIBILITY ACTIONS
  // -------------------------------------------------------------------------

  testWidgets('every interactive control exposes SemanticsAction.tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _revealCards(tester);

    void expectTap(Finder finder, String what) {
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: '$what must expose a tap action for VoiceOver/TalkBack',
      );
    }

    expectTap(find.bySemanticsLabel('Mark done').first, 'to-do check');
    expectTap(find.text('Reading \u2013 20 minutes'), 'quest card body');
    expectTap(find.bySemanticsLabel('Grown-ups'), 'lock button');
    expectTap(find.text('Pip'), 'dock Pip');
    expectTap(find.text('Shop'), 'dock Shop');
    expectTap(find.text('My jar'), 'dock My jar');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('performAction(tap) on the check completes the quest', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _revealCards(tester);
    // The to-do cards start below the fold; bring Reading's check into the
    // viewport so its semantics node exists in the tree.
    await tester.ensureVisible(find.text('Reading \u2013 20 minutes'));
    await tester.pump();
    final check = find.semantics.byLabel('Mark done').first;
    tester.semantics.performAction(check, SemanticsAction.tap);
    await _settle(tester);
    expect(find.text('K05 Quest complete'), findsOneWidget);
    final items = await tester.runAsync(
      () => GetIt.instance<KidHomeRepository>().getItems(),
    );
    expect(
      items!.singleWhere((q) => q.questId == 'q-reading').status,
      'done_pending',
      reason: 'the semantics action must reach the real DB write',
    );
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('performAction(tap) on the card body opens the detail', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _revealCards(tester);
    await tester.ensureVisible(find.text('Reading \u2013 20 minutes'));
    await tester.pump();
    final card = find.semantics.byLabel('Reading \u2013 20 minutes, To do');
    tester.semantics.performAction(card, SemanticsAction.tap);
    await _settle(tester);
    expect(find.text('K04 Quest detail'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('performAction(tap) on the lock opens the gate', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final lock = find.semantics.byLabel('Grown-ups');
    tester.semantics.performAction(lock, SemanticsAction.tap);
    await _settle(tester);
    expect(find.text('P17 Parental gate'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('Choose exposes tap and opens the picker', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
    await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
    await _pump(tester);
    final choose = find.semantics.byLabel('Choose');
    expect(
      choose.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );
    tester.semantics.performAction(choose, SemanticsAction.tap);
    await _settle(tester);
    expect(currentPath(tester), '/who-is-playing');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('Try again exposes a tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    await _useFakeRepository(_FailLoadRepository());
    await _pump(tester);
    final data = tester.getSemantics(find.text('Try again')).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
    await disposeApp(tester);
  });
}

// ---------------------------------------------------------------------------
// Fake repository: streams are healthy, `completeQuest` always fails.
// ---------------------------------------------------------------------------

class _SlowFailRepository extends KidHomeRepository {
  final Completer<void> _gate = Completer<void>();

  void fail() {
    if (!_gate.isCompleted) {
      _gate.completeError(Exception('save failed after dispose'));
    }
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) => _gate.future;
}

class _FailSaveRepository extends KidHomeRepository {
  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    throw Exception('save failed');
  }
}

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

const List<KidQuest> _items = <KidQuest>[
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading \u2013 20 minutes',
    detail: 'To do \u00b7 +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do \u00b7 +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];

/// Swaps the DI-registered repository for [repo] before pumping the app.
Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Asset names of every [SvgPicture] currently in the tree.
/// The nest artwork in the pet slot: the 260 px-wide picture of
/// `PipNestFallback` (painted twice — back and front rim).
Finder _nestSvgFinder() => find.descendant(
  of: find.byType(PipNestFallback),
  matching: find.byWidgetPredicate(
    (widget) => widget is SvgPicture && widget.width == 236,
  ),
);

List<String> _svgAssetNames(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((picture) => picture.bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .toList();

/// Streams error on listen (load-failure state probe).
class _FailLoadRepository extends KidHomeRepository {
  @override
  Future<List<KidQuest>> getItems() async => throw Exception('load failed');

  @override
  Stream<List<KidQuest>> watchItems() =>
      Stream<List<KidQuest>>.error(Exception('items down'));

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.error(Exception('profiles down'));

  @override
  Stream<KidChild?> watchActiveChild() =>
      Stream<KidChild?>.error(Exception('child down'));

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// Counts live source subscriptions; each stream errors shortly after
/// listen so the load-failure path (and its retry) can be exercised.
/// Pushable combined home stream (mid-session error probe).
class _PushableHomeRepository extends KidHomeRepository {
  final StreamController<KidHomeData> _home =
      StreamController<KidHomeData>.broadcast();
  int listens = 0;

  void push(KidHomeData data) => _home.add(data);

  void pushError(Object error) => _home.addError(error);

  @override
  Stream<KidHomeData> watchHome() {
    listens++;
    return _home.stream;
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

class _SubCountingRepository extends KidHomeRepository {
  int _activeChild = 0;
  int _activeItems = 0;
  int peak = 0;

  int get active => _activeChild + _activeItems;

  void _track() {
    final total = active;
    if (total > peak) peak = total;
  }

  @override
  Stream<KidChild?> watchActiveChild() {
    final controller = StreamController<KidChild?>();
    controller.onListen = () {
      _activeChild++;
      _track();
      scheduleMicrotask(() => controller.addError(Exception('child down')));
    };
    controller.onCancel = () => _activeChild--;
    return controller.stream;
  }

  @override
  Stream<List<KidQuest>> watchItems() {
    final controller = StreamController<List<KidQuest>>();
    controller.onListen = () {
      _activeItems++;
      _track();
      scheduleMicrotask(() => controller.addError(Exception('items down')));
    };
    controller.onCancel = () => _activeItems--;
    return controller.stream;
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// Healthy streams; `completeQuest` returns without an error and without
/// flipping anything — the race where the quest row vanished between load
/// and tap (`KidHomeRepositoryImpl.completeQuest` returns silently).
class _SilentNoopRepository extends KidHomeRepository {
  final List<String> calls = <String>[];

  @override
  Future<List<KidQuest>> getItems() async => _items2;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items2);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    calls.add(questId);
  }
}

void _load(KidHomeBloc bloc) => bloc.add(const KidHomeLoadRequested());

void _complete(KidHomeBloc bloc, String questId, int coins) => bloc.add(
  KidHomeQuestCompleted(childId: 'maya', questId: questId, coins: coins),
);

KidQuest _withStatus(KidQuest quest, String status) => KidQuest(
  id: quest.id,
  title: quest.title,
  detail: quest.detail,
  questId: quest.questId,
  icon: quest.icon,
  coins: quest.coins,
  status: status,
);

/// Healthy streams; `completeQuest` fails until [failComplete] is cleared,
/// then flips the quest and pushes the new list (retry probe).
class _ToggleFailRepository extends KidHomeRepository {
  bool failComplete = true;
  List<KidQuest> _items = List<KidQuest>.of(_items2);
  final StreamController<List<KidQuest>> _pushed =
      StreamController<List<KidQuest>>.broadcast();

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    yield _items;
    yield* _pushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    if (failComplete) throw Exception('save failed');
    _items = <KidQuest>[
      for (final quest in _items)
        if (quest.questId == questId)
          _withStatus(quest, 'done_pending')
        else
          quest,
    ];
    _pushed.add(_items);
  }
}

/// Each completion waits on its own gate, so a test can land the first write
/// while the second is still in flight (K03-BUG-8).
class _GatedCompletionRepository extends KidHomeRepository {
  List<KidQuest> _items = List<KidQuest>.of(_items2);
  final StreamController<List<KidQuest>> _pushed =
      StreamController<List<KidQuest>>.broadcast();
  final Completer<void> _first = Completer<void>();
  final Completer<void> _second = Completer<void>();

  void releaseFirst() {
    _items = <KidQuest>[
      for (final quest in _items)
        if (quest.questId == 'q-reading')
          _withStatus(quest, 'done_pending')
        else
          quest,
    ];
    _pushed.add(_items);
    _first.complete();
  }

  void failSecond() {
    if (!_second.isCompleted) {
      _second.completeError(Exception('save failed'));
    }
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    yield _items;
    yield* _pushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) {
    if (questId == 'q-reading') return _first.future;
    return _second.future;
  }
}

/// Two to_do quests used by the fake repositories above (`_items` is const
/// and shared with the failure fakes, which must not mutate it).
const List<KidQuest> _items2 = <KidQuest>[
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading \u2013 20 minutes',
    detail: 'To do \u00b7 +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do \u00b7 +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];
