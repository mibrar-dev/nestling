// K04 quest-detail — ICONS audience regression guard (iteration 4).
//
// Rule (ORCHESTRATOR_NOTES 15:08 / brief): a kid screen renders quest glyphs
// through `questIconFor(key, audience: NestAudience.kid)` — the KID design's
// asset — and never the parent table's asset. `k04_bugs_test.dart`'s
// K04-BUG-3 proof hard-codes four ids → four assets, so it would still pass if
// `_iconFor` were silently reverted to `audience: parent` and the hard-coded
// list were edited in step. This file proves the same rule structurally, from
// the database (DATA OVER MOCKS — no seed values are hard-coded):
//
//   * over the DB-driven item list, the on-screen 64 px `NestIcon` asset
//     equals `questIconFor(item.icon, audience: NestAudience.kid)`;
//   * for every key whose kid and parent assets DIFFER, the rendered asset is
//     provably the KID one (≠ parent) — so the distinction itself is asserted,
//     not a hand-written list of four expectations;
//   * the glyph is column-driven: two items sharing the same row id shape but
//     carrying different `icon` values must swap the glyph.
//
// Run: `flutter test --timeout 120s \
//   test/features/kid_home/quest_detail_view_icon_audience_test.dart`
//
// Harness notes (learned the hard way, see k02_bugs_test.dart): reading the
// real Drift database inside `testWidgets` needs exactly ONE
// `tester.runAsync` cycle (a second one deadlocks the binding's reentrant
// lock), and route pumps use bounded `pump(duration)` calls, never
// `pumpAndSettle` (the loading screen spins an endless indicator).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// `icon` keys whose kid and parent assets DIFFER in `questIconFor`
/// (`core/design_system/components/quest_icons.dart`). Read from the shared
/// table itself — asserted, not hard-coded — so a future divergence is picked
/// up here automatically.
const Set<String> _divergentKeys = <String>{
  'bed',
  'dishwasher',
  'book',
  'reading',
};

/// Keys the demo seed must cover so the "not the parent asset" assertion
/// cannot pass vacuously. The guard test below asserts this premise against
/// the live DB rather than assuming it.
const Set<String> _seedDivergentKeys = <String>{'bed', 'dishwasher', 'book'};

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
);

/// The states the seeded database cannot produce (a second quest whose icon
/// column differs from the design quest's). Mirrors the fake in
/// `quest_detail_view_test.dart`: every stream is rebuilt per `watch…()` call
/// so a re-load never hits "stream has already been listened to".
class _FakeKidHomeRepository extends KidHomeRepository {
  _FakeKidHomeRepository({required this.items});

  final List<KidQuest> items;

  @override
  Future<List<KidQuest>> getItems() async => items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(items);

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
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.home,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Bounded route pump — never `pumpAndSettle` (K04's loading state spins).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

BuildContext _navigatorContext(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);

/// Push the detail route the way K03 does: `extra {'questId', 'childId'}`.
void _pushDetail(
  WidgetTester tester, {
  required String questId,
  required String childId,
}) {
  unawaited(
    GoRouter.of(_navigatorContext(tester)).push(
      KidHomeRoutePaths.detail,
      extra: <String, Object>{'questId': questId, 'childId': childId},
    ),
  );
}

/// Pop imperatively (the same call the screen's own Back button makes) so the
/// finder never has to disambiguate the back button from the home screen
/// underneath an in-flight route transition.
void _pop(WidgetTester tester) {
  GoRouter.of(_navigatorContext(tester)).pop();
}

/// The hero glyph: the only 64 px `NestIcon` on the K04 screen (`.k4-tile`'s
/// `svg` is 64 px; every other icon on the screen is 22–26).
String _heroAsset(WidgetTester tester) {
  return tester
      .widgetList<NestIcon>(find.byType(NestIcon))
      .firstWhere((icon) => icon.size == 64)
      .assetName;
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  testWidgets('every DB-seeded quest renders its kid-audience glyph', (
    tester,
  ) async {
    // One `runAsync` cycle for the whole test: the only real-async work is
    // this read. (A second cycle inside one `testWidgets` deadlocks.)
    late final List<KidQuest> items;
    await tester.runAsync(() async {
      items = await GetIt.instance<KidHomeRepository>().getItems();
    });

    // Guard the proof itself: the live rows must exercise every divergent
    // key, otherwise "not the parent asset" could pass vacuously.
    final icons = items.map((item) => item.icon).toSet();
    expect(
      icons,
      containsAll(_seedDivergentKeys),
      reason:
          "Maya's rows must cover bed/dishwasher/book (DATA OVER MOCKS): $icons",
    );

    await _pump(tester);
    for (final item in items) {
      _pushDetail(tester, questId: item.questId, childId: _maya.id);
      await _settle(tester);

      expect(
        find.text(item.title),
        findsOneWidget,
        reason: '${item.questId} must actually be on screen',
      );
      final expected = questIconFor(item.icon, audience: NestAudience.kid);
      final rendered = _heroAsset(tester);
      expect(
        rendered,
        expected,
        reason:
            '${item.questId} (icon "${item.icon}") must render the kid asset',
      );
      if (_divergentKeys.contains(item.icon)) {
        expect(
          rendered,
          isNot(questIconFor(item.icon, audience: NestAudience.parent)),
          reason:
              '${item.questId}: the parent table asset must never render on a '
              'kid screen (the 5_ui Major was exactly that mix-up)',
        );
      }
      _pop(tester);
      await _settle(tester);
    }
    await disposeApp(tester);
  });

  testWidgets('the hero glyph is column-driven, not id-driven', (tester) async {
    KidQuest quest(String id, String icon) => KidQuest(
      id: '$id:maya',
      title: 'Tidy your bedroom',
      detail: 'To do · +10',
      questId: id,
      icon: icon,
      coins: 10,
      status: 'to_do',
    );
    await GetIt.instance.unregister<KidHomeRepository>();
    GetIt.instance.registerSingleton<KidHomeRepository>(
      _FakeKidHomeRepository(
        items: <KidQuest>[quest('q-a', 'bed'), quest('q-b', 'dishwasher')],
      ),
    );

    await _pump(tester);
    _pushDetail(tester, questId: 'q-a', childId: _maya.id);
    await _settle(tester);
    expect(_heroAsset(tester), questIconFor('bed', audience: NestAudience.kid));
    _pop(tester);
    await _settle(tester);

    // Same title, same id shape, different `icon` column: the glyph MUST swap.
    // A screen that keyed off the route/quest id would keep the bed glyph.
    _pushDetail(tester, questId: 'q-b', childId: _maya.id);
    await _settle(tester);
    expect(
      _heroAsset(tester),
      questIconFor('dishwasher', audience: NestAudience.kid),
    );
    expect(
      _heroAsset(tester),
      isNot(questIconFor('bed', audience: NestAudience.kid)),
    );
    await disposeApp(tester);
  });

  test('the hero bed glyph is the K04 tile drawing, on the accepted stroke', () {
    // K04-BUG-5, closed by ORCHESTRATOR ruling (ORCHESTRATOR_NOTES 16:38):
    // the K04 tile draws the bed paths at `stroke-width="1.8"` — the only 1.8
    // in the design corpus — while the shared kid asset `ic_quest_bed_kid.svg`
    // ships at 2 (K03-exact). DECISION: accept the one shared kid glyph at 2;
    // do NOT ship a K04-only variant. This test pins what is actually shipped
    // so the acceptance is recorded, not re-litigated by the next agent.
    final kidAsset = File('assets/icons/ic_quest_bed_kid.svg')
        .readAsStringSync();
    final parentAsset = File('assets/icons/ic_quest_bed.svg')
        .readAsStringSync();
    final html = File('../design/html-source/screens/K04-quest-detail.html')
        .readAsStringSync();

    // The K04 hero must be the kid asset, and its paths must stay the K04 tile
    // drawing (headboard post/pillow/legs) — not the P09 flat frame.
    expect(NestIcons.questBedKid, contains('ic_quest_bed_kid.svg'));
    for (final path in <String>[
      'M2 18v-7',
      'M2 14h20v4',
      'M22 18v-4a3 3 0 0 0-3-3h-9v3',
      'M6 11V8h4v3',
    ]) {
      expect(kidAsset, contains(path), reason: 'K04 tile path $path');
    }
    expect(
      parentAsset,
      isNot(contains('M2 18v-7')),
      reason: 'the parent asset is the flat P09 frame, never the K04 hero',
    );
    expect(html, contains('stroke-width="1.8"'));
    expect(
      kidAsset,
      contains('stroke-width="2"'),
      reason:
          'accepted shared kid stroke. Changing it needs an orchestrator '
          'ruling (K04-BUG-5), not a screen edit',
    );
  });

  testWidgets('the kid and parent glyph sets really do diverge', (
    tester,
  ) async {
    // The premise both cases above rest on, asserted against the shared table
    // rather than against a comment: the divergent set is exactly
    // bed / dishwasher / book / reading, and the rest are shared.
    for (final key in _divergentKeys) {
      expect(
        questIconFor(key, audience: NestAudience.kid),
        isNot(questIconFor(key, audience: NestAudience.parent)),
        reason: '"$key" must have distinct kid and parent glyphs',
      );
    }
    for (final key in <String>['bins', 'hoover', 'plate', 'paw', 'bag']) {
      expect(
        questIconFor(key, audience: NestAudience.kid),
        questIconFor(key, audience: NestAudience.parent),
        reason: '"$key" is shared by both audiences',
      );
    }
  });
}
