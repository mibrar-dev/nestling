// P15 · Child profile — view-layer (widget) proofs.
//
// Geometry is measured against `design/screens/light/P15-child-profile.png`
// ÷ 3 (390×844 logical), never against a re-derived expectation:
//
//   ```
//   47…211  hero card          (164)   20 + 64 avatar + 10 + 30 + 20 + 20
//   227…309 three stat tiles    (82)   12 + 26 + 2×16 + 12  (grid: all equal)
//   325…441 Pip card            (116)  16 + 84 + 16
//   457…637 three list rows     (180)  3 × 60
//   653…733 danger card         (80)   16 + 48 + 16
//   ```
//
// Fonts are the bundled Inter/Nunito (`FontLoader`), so the measurements are
// the ones a device renders.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart' hide Quest;
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/views/child_profile_view.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

import '../../test_scope.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

/// Only what the status switch needs; the members stream is never rendered by
/// P15 (the tab bar has no avatar on this route).
const _me = FamilyMember(
  id: 'sarah',
  title: 'Sarah',
  detail: 'You',
  name: 'Sarah',
  role: 'owner',
  inviteStatus: 'active',
);

/// The route builds its bloc from `GetIt.instance<FamilyBloc>()`, so the
/// repository has to be swapped BEFORE the pump (`child_profile_states_test.dart`
/// uses the same seam) — the real router, shell and tab bar are still built.
Future<void> _useRepository(FamilyRepository repository) async {
  await GetIt.instance.unregister<FamilyRepository>();
  GetIt.instance.registerSingleton<FamilyRepository>(repository);
}

Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

ChildProfile _profile(WidgetTester tester) =>
    tester.widget<ChildProfileBody>(find.byType(ChildProfileBody)).profile;

/// The demo Maya profile, for the mocked-repository tests (the rows never
/// read the roster).
ChildProfile _mayaProfileFixture() => const ChildProfile(
  child: FamilyChild(
    id: 'maya',
    nickname: 'Maya',
    ageBand: '7-9',
    ageYears: 9,
    avatarColour: 'lilac',
    pinSet: true,
    pipStyle: 'mochi',
    pipSkin: 'sunny',
    pipAccessory: 'none',
    pipStage: 3,
    pipTotalCoins: 175,
    coins: 120,
    happiness: 4,
    happyDays: 4,
    weeklyBasePence: 300,
    activeQuests: 6,
    doneQuests: 4,
  ),
  questsThisWeek: 4,
  dailyActive: 4,
  weeklyActive: 2,
  onceActive: 0,
  owedPence: 420,
);

/// Lets real-async Drift work (the remove write and the stream re-emit)
/// complete inside a widget test, where plain `pump` only advances the fake
/// clock — the same helper `p04_bugs_test.dart` uses.
Future<void> _flushDrift(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadBundledFonts);

  group('P15 card bands match the design', () {
    testWidgets('hero, stats, Pip, list and danger rects', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(_profile(tester).child.nickname, 'Maya');

      final hero = tester.getRect(find.byKey(const Key('p15-hero')));
      final stats = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      final pip = tester.getRect(find.byKey(const Key('p15-pip')));
      final list = tester.getRect(find.byKey(const Key('p15-row-pin')));
      final danger = tester.getRect(find.byKey(const Key('p15-danger')));

      // `NestList` is one surface card; its first row's top IS the card top.
      final listCard = tester.getRect(find.byType(NestList));

      expect(hero.top, closeTo(47, 0.01));
      expect(hero.height, closeTo(164, 0.01));
      expect(stats.top, closeTo(227, 0.01));
      expect(stats.height, closeTo(82, 0.01));
      expect(pip.top, closeTo(325, 0.01));
      expect(pip.height, closeTo(116, 0.01));
      expect(listCard.top, closeTo(457, 0.01));
      expect(listCard.height, closeTo(180, 0.01));
      expect(list.top, closeTo(457, 0.01));
      expect(danger.top, closeTo(653, 0.01));
      expect(danger.height, closeTo(80, 0.01));

      // ALIGNMENT (owner rule): 20 px gutters, every band on the same edges.
      // The stats row spans the gutter-to-gutter width like every other band
      // (its first tile starts on the left gutter, its last ends on the right).
      final lastTile = tester.getRect(find.byKey(const Key('p15-stat-days')));
      for (final rect in <Rect>[hero, pip, listCard, danger]) {
        expect(rect.left, closeTo(NestSpacing.padSide, 0.01));
        expect(rect.right, closeTo(390 - NestSpacing.padSide, 0.01));
      }
      expect(stats.left, closeTo(NestSpacing.padSide, 0.01));
      expect(lastTile.right, closeTo(390 - NestSpacing.padSide, 0.01));

      await disposeApp(tester);
    });

    testWidgets('stat tiles are 110 wide with a 10 gap', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      final quests = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      final coins = tester.getRect(find.byKey(const Key('p15-stat-coins')));
      final days = tester.getRect(find.byKey(const Key('p15-stat-days')));

      expect(quests.width, closeTo(110, 0.01));
      expect(coins.width, closeTo(110, 0.01));
      expect(days.width, closeTo(110, 0.01));
      // `.stats { grid-template-columns: 1fr 1fr 1fr; gap: 10 }`.
      expect(coins.left - quests.right, closeTo(10, 0.01));
      expect(days.left - coins.right, closeTo(10, 0.01));
      // A grid stretches every tile to the tallest: the "Quests this week"
      // label wraps to two lines, so all three are 82 tall.
      expect(coins.height, closeTo(quests.height, 0.01));
      expect(days.height, closeTo(quests.height, 0.01));

      await disposeApp(tester);
    });
  });

  group('P15 copy is the design copy', () {
    testWidgets('exact strings, U+2013 / U+00B7 / U+203A included', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      expect(find.text('Maya'), findsOneWidget);
      expect(
        find.text('Age 7\u20139 \u00B7 Pip is a Fledgling'),
        findsOneWidget,
      );
      expect(find.text('Pip \u00B7 Fledgling'), findsOneWidget);
      expect(find.text('Evolves at 250 total coins'), findsOneWidget);
      expect(find.text('175 of 250 \u00B7 70%'), findsOneWidget);
      // Scoped to the rows: the tab bar repeats "Quests" and "Money".
      Finder inRow(String key, String text) =>
          find.descendant(of: find.byKey(Key(key)), matching: find.text(text));
      expect(find.text('Kid PIN'), findsOneWidget);
      expect(
        inRow('p15-row-pin', 'On \u00B7 Maya knows their code'),
        findsOneWidget,
      );
      expect(inRow('p15-row-pin', 'Change \u203A'), findsOneWidget);
      expect(inRow('p15-row-quests', 'Quests'), findsOneWidget);
      expect(
        inRow('p15-row-quests', '6 active \u00B7 4 daily, 2 weekly'),
        findsOneWidget,
      );
      expect(inRow('p15-row-money', 'Pocket money'), findsOneWidget);
      expect(
        find.text('\u00A33.00 a week \u00B7 Owed \u00A34.20'),
        findsOneWidget,
      );
      expect(find.text('Remove Maya from family'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P15 Pip slot', () {
    testWidgets("renders Maya's own Pip at the design's 84 px", (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.mochi);
      expect(pip.skin, PipSkin.sunny);
      expect(pip.accessory, PipAccessory.none);
      expect(pip.stage, 3);
      expect(pip.size, 84);

      // PIP ruling: the child carries Pip, so the label names HER Pip — the
      // same "a fledgling" wording P08's kid card announces.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == "Maya's Pip, a fledgling",
        ),
        findsOneWidget,
      );

      final progress = tester.widget<NestProgress>(find.byType(NestProgress));
      expect(progress.fraction, closeTo(0.7, 0.001));
      expect(progress.kid, isFalse);

      // `.piprow img { width: 84px }`, centred in the row's cross axis.
      final art = tester.getRect(find.byType(PipAvatar));
      expect(art.width, closeTo(84, 0.01));
      expect(art.height, closeTo(84, 0.01));
      expect(art.left, closeTo(36, 0.01));

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P15 navigation', () {
    testWidgets('the three rows go to PIN, the library and the ledger', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-row-quests')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/quests');
      await disposeApp(tester);

      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      await tester.tap(find.byKey(const Key('p15-row-money')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/money');
      await disposeApp(tester);

      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      await tester.tap(find.byKey(const Key('p15-row-pin')));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-pin');
      await disposeApp(tester);
    });
  });

  group('P15 accessibility', () {
    testWidgets('every control exposes SemanticsAction.tap', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      for (final key in <Key>[
        const Key('p15-row-pin'),
        const Key('p15-row-quests'),
        const Key('p15-row-money'),
        const Key('p15-remove'),
      ]) {
        final node = tester.getSemantics(find.byKey(key));
        final data = node.getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$key must be operable by VoiceOver/TalkBack',
        );
        expect(data.flagsCollection.isButton, isTrue, reason: '$key');
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the row drives the real navigation', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      tester.semantics.performAction(
        find.semantics.byLabel('Pocket money'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/money');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the PIN row pushes the PIN screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      tester.semantics.performAction(
        find.semantics.byLabel('Kid PIN'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-pin');

      handle.dispose();
      await disposeApp(tester);
    });
  });

  // ── BUG P15-BUG-1 (failing repro — do not "fix" the test) ──────────────
  // `/child-profile` is entered with a `?childId=` deep link from Today
  // (`today_loaded_body.dart:557`: `context.go('…/child-profile?childId=' …)`)
  // and P08's own test asserts that URI. P15 ignores it: `watchProfile`
  // resolves the selection from `app_state.activeChildId`
  // (`family_repository_impl.dart:156-167`), which only the `CHILD` launch
  // flag ever writes (`app/launch.dart:58`). So a parent who taps LEO on
  // Today lands on MAYA's profile. `childProfileRoute`
  // (`family_routes.dart:31`) never reads `state.uri`, and the fix belongs
  // inside this feature: read the query parameter in the route (or select on
  // it in the repository), keeping `activeChildId` as the fallback.
  group('P15 honours the ?childId deep link from Today (BUG P15-BUG-1)', () {
    testWidgets('BUG: ?childId=leo must show Leo, not the active child', (
      tester,
    ) async {
      await setUpTestScope();
      // The demo seed's `activeChildId` is 'maya' (Seed.demo), so this test
      // can only pass if the query parameter is honoured.
      await pumpAppRoute(tester, '/child-profile?childId=leo');

      expect(
        find.text('Leo'),
        findsOneWidget,
        reason: 'the deep link asked for Leo',
      );
      expect(find.text('Maya'), findsNothing);
      expect(_profile(tester).child.id, 'leo');

      await disposeApp(tester);
    });

    testWidgets("BUG: tapping Leo on Today must land on Leo's profile", (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Leo'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/child-profile');
      expect(
        find.text('Age 4\u20136 \u00B7 Pip is a Hatchling'),
        findsOneWidget,
      );
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.bolt, reason: "Leo's own Pip, not Maya's");
      expect(pip.stage, 2);
      expect(find.text('Remove Leo from family'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a deep link that agrees with the active child works', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile?childId=maya');

      expect(find.text('Maya'), findsOneWidget);
      expect(_profile(tester).child.id, 'maya');

      await disposeApp(tester);
    });

    // The route dispatches `FamilyChildSelected` BEFORE `FamilyLoadRequested`
    // (`family_routes.dart:38-48`) and the repository records the request
    // synchronously, so the requested child wins on the very FIRST emission.
    // A late persist would flash the wrong child's profile for a frame — and
    // a frame is enough to show a parent someone else's name and Pip.
    testWidgets('the requested child is never preceded by the active one', (
      tester,
    ) async {
      await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);

      await tester.pumpWidget(
        const NestlingApp(initialRoute: '/child-profile?childId=leo'),
      );

      var sawMaya = false;
      var sawLeo = false;
      for (var frame = 0; frame < 12 && !sawLeo; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        // `runAsync` lets the real-async Drift writes land between frames.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        sawMaya = sawMaya || find.text('Maya').evaluate().isNotEmpty;
        sawLeo = sawLeo || find.text('Leo').evaluate().isNotEmpty;
      }

      expect(sawLeo, isTrue, reason: 'Leo must arrive');
      expect(
        sawMaya,
        isFalse,
        reason: 'Maya must never be rendered, not even for one frame',
      );
      expect(_profile(tester).child.id, 'leo');

      await disposeApp(tester);
    });

    testWidgets('an unknown childId still falls back to the roster', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile?childId=nobody');

      // No crash, no blank screen: the first child in ADDED order (CHILD
      // ORDER ruling) is shown.
      expect(find.text('Maya'), findsOneWidget);
      expect(find.byKey(const Key('p15-hero')), findsOneWidget);

      await disposeApp(tester);
    });

    // ── P15-BUG-9 (fixed in iteration 3) ─────────────────────────────────
    // The iteration-2 fix dispatched `FamilyChildSelected` from the ROUTE's
    // `BlocProvider(create:)`, which runs once per route instance. The Family
    // branch lives in a `StatefulShellRoute.indexedStack`, so the page stays
    // MOUNTED: a second `?childId=` re-used the same page key, the builder
    // never ran again, no selection was dispatched — and the screen kept
    // showing the PREVIOUS child. Iteration 3 gave the route two followers:
    // `_ChildProfileRoute.didUpdateWidget` (the `requested` id changed) and
    // `ChildProfileView.didChangeDependencies` (the router state it reads
    // changed). The test below is the iteration-2 repro, now green.
    testWidgets('BUG P15-BUG-9: a SECOND deep link must switch the profile', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Leo'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();
      expect(_profile(tester).child.id, 'leo');

      // Back to Today, then Maya's card: same route, different child.
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Today'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/child-profile');
      expect(
        _profile(tester).child.id,
        'maya',
        reason: 'the ?childId= on this entry point asked for Maya',
      );
      expect(
        find.text('Age 7\u20139 \u00B7 Pip is a Fledgling'),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets('the same id is not re-dispatched on rebuilds or re-entry', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.value(const <FamilyMember>[_me]),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(<FamilyChild>[]));
      when(
        repo.watchProfile,
      ).thenAnswer((_) => Stream<ChildProfile?>.value(_mayaProfileFixture()));
      final selects = <String>[];
      when(() => repo.selectChild(any())).thenAnswer((invocation) async {
        selects.add(invocation.positionalArguments.first as String);
      });
      await _useRepository(repo);

      await pumpAppRoute(tester, '/child-profile?childId=leo');
      final onEntry = selects.length;
      expect(
        selects,
        everyElement('leo'),
        reason: 'only the requested id is ever persisted',
      );
      // At most twice on a cold entry: the route dispatches it, and the view
      // sees the same value once (documented as idempotent, not churn).
      expect(onEntry, lessThanOrEqualTo(2));

      // `didChangeDependencies` re-fires on ANY inherited change — a theme
      // flip, a text-scale change, a MediaQuery update. The `_seenChildId`
      // guard must swallow all of it.
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(selects.length, onEntry, reason: 'a rebuild must not re-select');

      // Re-entering the SAME deep link (Today tab → Family tab) must not
      // dispatch again either: the value did not change.
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Today'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Family'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      expect(selects.length, onEntry, reason: 'no churn on re-entry');
      expect(find.text('Maya'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a stale ?childId= cannot resurrect a removed child', (
      tester,
    ) async {
      await setUpTestScope();
      // Deep-link straight to Leo, then delete him through the UI. The URL
      // still carries `?childId=leo`, which must not bring him back.
      await pumpAppRoute(tester, '/child-profile?childId=leo');
      await _flushDrift(tester);
      await tester.pumpAndSettle();
      expect(_profile(tester).child.id, 'leo');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      // The selection falls through to the roster's first child (CHILD
      // ORDER) — never back to the deleted one.
      expect(_profile(tester).child.id, 'maya');
      expect(find.text('Remove Maya from family'), findsOneWidget);

      // Re-enter the very same stale URL: no crash, no Leo.
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Today'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();
      expect(_profile(tester).child.id, 'maya');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dropping the query keeps the child the deep link chose', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile?childId=leo');
      await _flushDrift(tester);
      await tester.pumpAndSettle();
      expect(_profile(tester).child.id, 'leo');

      // The Family tab root carries no `?childId=`; the persisted selection
      // is Leo, so the screen keeps him (no reset, no crash).
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Today'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NestTabBar),
          matching: find.text('Family'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_profile(tester).child.id, 'leo');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P15 route plumbing (iteration 3)', () {
    testWidgets('kid mode still sends the profile to the parental gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      // The stateful wrapper + stateful view must not bypass the shell's
      // parent-only redirect (`router.dart:85-109`).
      await pumpAppRoute(tester, '/child-profile?childId=leo');
      expect(currentPath(tester), '/parental-gate');
      expect(find.byType(ChildProfileView), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    // ── P15-BUG-10 (failing repro — do not "fix" the test) ───────────────
    // Iteration 3 gave `ChildProfileView` a router dependency so it could
    // follow the live `?childId=`:
    //
    //   GoRouterState.of(context).uri.queryParameters['childId']
    //
    // `GoRouterState.of` ASSERTS when there is no router ancestor, so the
    // view can no longer be mounted on its own — it throws
    // `GoError: There is no GoRouterState above the current context` in any
    // bare `MaterialApp` pump (a widget test, a preview harness, the design
    // gallery). The screen itself is unaffected (the app always builds it
    // inside `childProfileRoute`), so this is a fragility, not a regression —
    // and `GoRouter.maybeOf(context)?.state.uri` keeps the dependency
    // registration while making the read optional.
    testWidgets('BUG P15-BUG-10: the view mounts without a GoRouter', (
      tester,
    ) async {
      await setUpTestScope();
      // The app's own bloc factory; deliberately NOT closed — its
      // `emit.forEach` holds the repository streams open, exactly as in the
      // app (the `today_view_test.dart` convention).
      final bloc = GetIt.instance<FamilyBloc>()
        ..add(const FamilyLoadRequested());

      await tester.pumpWidget(
        MaterialApp(
          // The design tokens on the theme (this is what `context.nest` reads)
          // but deliberately no router: that is exactly the P15-BUG-10 stance.
          theme: NestTheme.light(),
          home: BlocProvider<FamilyBloc>.value(
            value: bloc,
            child: const ChildProfileView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.takeException(),
        isNull,
        reason: 'a view must not require a router ancestor to build',
      );
      expect(find.text('Maya'), findsOneWidget);

      await disposeApp(tester);
    });

    // The guard must be inert, not a silent skip: with no router there is no
    // query to read, so nothing may be selected. And the moment a router IS
    // above the context the very same widget follows the route again (the
    // BUG-9 repro above) — the guard is a null check, not a "give up on the
    // deep link" switch.
    testWidgets('the router-less guard selects nothing and keeps the view', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.value(const <FamilyMember>[_me]),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(<FamilyChild>[]));
      when(
        repo.watchProfile,
      ).thenAnswer((_) => Stream<ChildProfile?>.value(_mayaProfileFixture()));
      when(() => repo.selectChild(any())).thenAnswer((_) async {});
      await _useRepository(repo);

      final bloc = GetIt.instance<FamilyBloc>()
        ..add(const FamilyLoadRequested());
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<FamilyBloc>.value(
            value: bloc,
            child: const ChildProfileView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => repo.selectChild(any()));
      expect(find.text('Maya'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);

      // …and with a router above it the same view dispatches again. Twice on a
      // cold entry is expected and harmless (the route's `create` and this
      // view both dispatch the same id; `selectChild` is idempotent and
      // membership-gated) — the sibling test pins that upper bound.
      await pumpAppRoute(tester, '/child-profile?childId=leo');
      await tester.pumpAndSettle();
      verify(() => repo.selectChild('leo')).called(greaterThanOrEqualTo(1));

      await disposeApp(tester);
    });
  });

  group('P15 remove flow', () {
    testWidgets('confirm removes the child and the screen shows no-children', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(_profile(tester).child.id, 'maya');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      expect(find.text('Remove Maya?'), findsOneWidget);
      expect(
        find.text(
          'They will lose their quests, coins and Pip. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      // The watch streams re-emitted and the selection fell through to the
      // next child in ADDED order (CHILD ORDER ruling): Leo, not an empty
      // screen — and Leo's own Pip (bolt · sky · stage 2), not Maya's.
      expect(find.text('Maya'), findsNothing);
      expect(_profile(tester).child.id, 'leo');
      expect(
        find.text('Age 4\u20136 \u00B7 Pip is a Hatchling'),
        findsOneWidget,
      );
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.bolt);
      expect(pip.skin, PipSkin.sky);
      expect(pip.stage, 2);
      expect(find.text('Remove Leo from family'), findsOneWidget);

      // Removing the last child empties the family.
      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      expect(find.text('No children yet'), findsOneWidget);
      expect(
        find.text('Add your first child and their Pip will start to hatch.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('p15-hero')), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('Cancel keeps the child', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Cancel'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);

      expect(find.text('Remove Maya?'), findsNothing);
      expect(_profile(tester).child.id, 'maya');
      expect(find.byKey(const Key('p15-hero')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the empty state CTA opens the add-children funnel', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      for (final nickname in <String>['Maya', 'Leo']) {
        expect(find.text('Remove $nickname from family'), findsOneWidget);
        await tester.tap(find.byKey(const Key('p15-remove')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(NestButton, 'Remove'));
        await tester.pumpAndSettle();
        await _flushDrift(tester);
        await tester.pumpAndSettle();
      }

      expect(find.text('No children yet'), findsOneWidget);
      await tester.tap(find.widgetWithText(NestButton, 'Add a child'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/add-children');

      await disposeApp(tester);
    });
  });

  // Review finding 10: the remove-FAILURE path had no view proof. The
  // loading / failure / retry branches are covered by
  // `child_profile_states_test.dart`; this is the one that needs a mock
  // repository AND the real remove flow — tap the danger row, confirm, and a
  // DB failure must raise the toast (`ChildProfileView`'s `BlocListener`)
  // instead of replacing the screen. The screen must stay `loaded`.
  group('P15 remove failure', () {
    testWidgets('a failing removeChild toasts and keeps the profile', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.value(const <FamilyMember>[_me]),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(<FamilyChild>[]));
      when(repo.watchProfile).thenAnswer(
        (_) => Stream<ChildProfile?>.value(
          const ChildProfile(
            child: FamilyChild(
              id: 'maya',
              nickname: 'Maya',
              ageBand: '7-9',
              ageYears: 7,
              avatarColour: 'lilac',
              pinSet: true,
              pipStyle: 'mochi',
              pipSkin: 'sunny',
              pipAccessory: 'none',
              pipStage: 3,
              pipTotalCoins: 175,
              coins: 120,
              happiness: 0,
              happyDays: 8,
              weeklyBasePence: 300,
              activeQuests: 6,
              doneQuests: 4,
            ),
            questsThisWeek: 4,
            dailyActive: 4,
            weeklyActive: 2,
            onceActive: 0,
            owedPence: 420,
          ),
        ),
      );
      when(() => repo.removeChild(any())).thenThrow(Exception('offline'));
      await _useRepository(repo);

      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);

      // The toast carries the real repository error…
      expect(find.byType(NestToast), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      // …and the profile is untouched: `loaded`, not `failure`.
      expect(find.byType(ChildProfileBody), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      verify(() => repo.removeChild('maya')).called(1);

      await disposeApp(tester);
    });

    // P15-BUG-3, the user-visible half (stage 6 proved the bloc half): a
    // SECOND identical failure must raise the toast again. Equatable would
    // suppress a duplicate state, so the listener never fires twice — which
    // is why the bloc now clears the message before re-raising it.
    testWidgets('a repeated identical remove failure toasts again', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.value(const <FamilyMember>[_me]),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(<FamilyChild>[]));
      when(
        repo.watchProfile,
      ).thenAnswer((_) => Stream<ChildProfile?>.value(_mayaProfileFixture()));
      when(() => repo.removeChild(any())).thenThrow(Exception('offline'));
      await _useRepository(repo);

      await pumpAppRoute(tester, '/child-profile');

      for (var attempt = 1; attempt <= 2; attempt++) {
        await tester.tap(find.byKey(const Key('p15-remove')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(NestButton, 'Remove'));
        await tester.pumpAndSettle();
        await _flushDrift(tester);

        expect(
          find.byType(NestToast),
          findsOneWidget,
          reason: 'failure $attempt must raise its own toast',
        );
        expect(find.textContaining('offline'), findsOneWidget);
        // Still the loaded screen, never the failure panel.
        expect(find.text('Try again'), findsNothing);
        expect(find.text('Maya'), findsOneWidget);

        // Let the 3 s snackbar retire before the next tap: it floats over
        // the bottom of the column and would swallow the tap (the danger row
        // is the last thing in the scroll, by design).
        if (attempt < 2) {
          await tester.pumpAndSettle(const Duration(seconds: 4));
          expect(find.byType(NestToast), findsNothing);
        }
      }
      verify(() => repo.removeChild('maya')).called(2);

      await disposeApp(tester);
    });
  });

  // Review findings 5 + 6, closed in iteration 2.
  group('P15 hero', () {
    testWidgets('the name is announced as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      // Every other screen's title flags itself (`add_children_view.dart:196`,
      // `today_loaded_body.dart:375`, `money_ledger_view.dart:207`).
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.header == true,
        ),
        findsOneWidget,
        reason: "the child's name is this route's page title",
      );
      // The heading node announces the name itself, not just the initial.
      final node = tester.getSemantics(find.text('Maya'));
      expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a long nickname wraps and grows the hero, never truncates', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(nickname: Value('Bartholomew-Winston-Okonkwo')),
      );

      await pumpAppRoute(tester, '/child-profile');

      // `.hero h1` carries no `nowrap` and `components.css:43` gives bare h1
      // `overflow-wrap: anywhere`, so the design WRAPS (review finding 6)
      // instead of truncating: the card grows to hold the extra line.
      final name = tester.widget<Text>(
        find.text('Bartholomew-Winston-Okonkwo'),
      );
      expect(name.maxLines, greaterThan(1));
      final render = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('Bartholomew-Winston-Okonkwo'),
          matching: find.byType(RichText),
        ),
      );
      expect(
        render.size.height,
        greaterThan(render.preferredLineHeight),
        reason: 'the name really is on a second line',
      );
      expect(render.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(find.byKey(const Key('p15-hero'))).height,
        greaterThan(164),
        reason: 'the card grows to hold the second line',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the design name still renders on one line at 390', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      // The 164 px hero band in `child_profile_view_test.dart`'s geometry
      // proofs only holds while the name is one line.
      expect(tester.getRect(find.byKey(const Key('p15-hero'))).height, 164);
      expect(find.text('Maya'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a very long nickname still fits at 320 · scale 1.3', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(nickname: Value('Bartholomew-Winston-Okonkwo')),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpAppRoute(tester, '/child-profile');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      // Capped at three lines, so the stats band below is never swallowed.
      final render = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('Bartholomew-Winston-Okonkwo'),
          matching: find.byType(RichText),
        ),
      );
      expect(
        render.size.height,
        lessThanOrEqualTo(3 * render.preferredLineHeight + 0.5),
        reason: 'three lines at most, so the stats band below survives',
      );

      await disposeApp(tester);
    });
  });

  group('P15 holds up at other sizes', () {
    testWidgets('320 wide: no overflow', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      // [pumpAppRoute] pins 390x844; re-size and settle afterwards.
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      // The stat tiles shrink with the screen (never a fixed 110).
      final quests = tester.getRect(find.byKey(const Key('p15-stat-quests')));
      expect(quests.width, closeTo((320 - 40 - 20) / 3, 0.01));
      await disposeApp(tester);
    });

    testWidgets('text scale 1.3: no overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
