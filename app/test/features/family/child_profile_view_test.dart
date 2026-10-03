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

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
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
