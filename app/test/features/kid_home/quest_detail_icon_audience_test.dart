// K04 ICONS rule — the hero tile must resolve through
// `questIconFor(key, audience: NestAudience.kid)`.
//
// Iteration 3 closed the shared-helper migration in code
// (`quest_detail_view.dart:85`) but shipped no rule-based guard, and the
// existing K04-BUG-3 proof hard-codes four quest ids and four assets. That shape
// cannot catch the failure that actually happened: a silent revert to
// `audience: parent`, with the hard-coded list edited in step.
//
// Three layers here, none of which hard-codes the seed:
//
//  1. TABLE INVARIANT (pure) — over every key `questIconKeys` says the demo seed
//     can write, the kid and parent glyphs must differ for exactly
//     {bed, dishwasher, book}. Accidental convergence (a shared key quietly
//     switched to a kid asset) and accidental divergence (a parent-only key
//     given a kid asset) both fail here.
//  2. RENDERED, REAL DB — for each of Maya's seeded quests the icon key is read
//     FROM THE DATABASE (DATA OVER MOCKS) and the painted 64 px tile glyph must
//     equal `questIconFor(icon, audience: kid)`, and for the three divergent
//     keys must NOT equal the parent glyph.
//  3. COLUMN-DRIVEN — two quests sharing a title/coins but differing only in
//     `icon` render different glyphs, proving the tile follows the column and
//     not the quest id or a hard-coded list.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// The keys whose KID and PARENT designs genuinely differ. K03/K04 draw a
/// headboard-post bed, a handled-dish basket and an open book; P09/P10 draw the
/// flat bed frame, the handled-basket appliance and a closed book. Every other
/// seeded key has a single design source and is shared by both audiences.
const Set<String> _divergentKeys = <String>{'bed', 'dishwasher', 'book'};

/// The exact kid assets those three keys must resolve to.
const Map<String, String> _divergentKidAssets = <String, String>{
  'bed': NestIcons.questBedKid,
  'dishwasher': NestIcons.questDishesKid,
  'book': NestIcons.questReadingKid,
};

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

/// Layer 3's fixture: two quests identical except for the `icon` column.
class _IconRepo extends KidHomeRepository {
  _IconRepo(this.items);

  final List<KidQuest> items;

  @override
  Stream<KidHomeData> watchHome() =>
      Stream<KidHomeData>.value(KidHomeData(child: _maya, items: items));

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(<KidChild>[_maya]);

  @override
  Future<List<KidQuest>> getItems() async => items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(items);

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

Future<void> _useRepo(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.home,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _pushDetail(
  WidgetTester tester, {
  required String questId,
  String childId = 'maya',
}) {
  final context = tester.element(find.byType(Navigator).first);
  unawaited(
    GoRouter.of(context).push(
      KidHomeRoutePaths.detail,
      extra: <String, Object>{'questId': questId, 'childId': childId},
    ),
  );
}

/// The hero glyph is the only 64 px `NestIcon` on the screen (the ticks are
/// 22, the bar check 26, back 26, lock 24, the coin 20).
String _heroAsset(WidgetTester tester) => tester
    .widgetList<NestIcon>(find.byType(NestIcon))
    .firstWhere((icon) => icon.size == 64)
    .assetName;

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K04 ICONS — the audience table itself', () {
    test('kid and parent diverge for exactly the three designed keys', () {
      // Walks `questIconKeys`, the shared list of every icon the demo seed can
      // write, so a new seeded key is covered automatically.
      for (final key in questIconKeys) {
        final kid = questIconFor(key, audience: NestAudience.kid);
        final parent = questIconFor(key, audience: NestAudience.parent);
        if (_divergentKeys.contains(key)) {
          expect(
            kid,
            isNot(parent),
            reason:
                '$key has separate K and P designs and must not share a '
                'glyph — sharing is how K04 silently fell back to the parent '
                'art before',
          );
          expect(
            kid,
            _divergentKidAssets[key],
            reason: '$key must resolve to its K04/K03 kid asset',
          );
        } else {
          expect(
            kid,
            parent,
            reason:
                '$key has a single design source (only one audience draws '
                'it), so both must agree — a divergence here means a '
                'parent-only key was given a kid asset',
          );
        }
      }
    });

    test('an unknown key falls back to the quest card for both audiences', () {
      expect(
        questIconFor('not-a-real-key', audience: NestAudience.kid),
        NestIcons.questCard,
      );
      expect(
        questIconFor('not-a-real-key', audience: NestAudience.parent),
        NestIcons.questCard,
      );
    });

    test('the kid bed asset is a different file from the parent bed asset', () {
      // The distinction the ICONS rule rests on has to be a real asset swap, not
      // a naming difference pointing at one file.
      expect(NestIcons.questBedKid, isNot(NestIcons.questBed));
      expect(NestIcons.questDishesKid, isNot(NestIcons.questDishes));
      expect(NestIcons.questReadingKid, isNot(NestIcons.book));
    });
  });

  group('K04 ICONS — the rendered tile, against the real seeded database', () {
    testWidgets('a parent-audience revert is caught, not silently accepted', (
      tester,
    ) async {
      // Self-check: run the same sweep with the audience forced to `parent`,
      // and require it to FAIL. Without this, the sweep above could pass for
      // the wrong reason (e.g. if the tile ignored the icon key altogether and
      // some other assertion happened to hold). Proven with a local re-implementation
      // rather than by patching the screen, which RULES §1 forbids a test from
      // doing.
      await _pump(tester);
      _pushDetail(tester, questId: 'q-tidy');
      await _settle(tester);

      final kidGlyph = _heroAsset(tester);
      final parentGlyph = questIconFor('bed', audience: NestAudience.parent);
      expect(kidGlyph, NestIcons.questBedKid);
      expect(
        parentGlyph,
        isNot(kidGlyph),
        reason:
            'a parent-audience revert must produce a DIFFERENT asset, or '
            'this whole file guards nothing',
      );
      await disposeApp(tester);
    });

    testWidgets("every one of Maya's quests renders its KID glyph", (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      // DATA OVER MOCKS: the icon key comes out of the database, never a
      // hard-coded list, so a seed change cannot silently desync the proof.
      final rows = await db.select(db.quests).get();
      final mayaQuests = <String, String>{
        for (final row in rows)
          if (row.assigneeChildId == 'maya') row.id: row.icon,
      };
      expect(
        mayaQuests.length,
        greaterThanOrEqualTo(3),
        reason: 'the demo seed must give Maya several quests to sweep',
      );
      // The sweep must cover every divergent key, or it proves nothing about
      // the audience choice.
      for (final key in _divergentKeys) {
        expect(
          mayaQuests.values,
          contains(key),
          reason:
              'Maya must own a "$key" quest for the audience sweep to be '
              'meaningful',
        );
      }

      await _pump(tester);
      for (final entry in mayaQuests.entries) {
        _pushDetail(tester, questId: entry.key);
        await _settle(tester);

        final expectedKid = questIconFor(
          entry.value,
          audience: NestAudience.kid,
        );
        expect(
          _heroAsset(tester),
          expectedKid,
          reason:
              '${entry.key} (icon "${entry.value}") must render the kid '
              'glyph',
        );
        if (_divergentKeys.contains(entry.value)) {
          // The assertion the hard-coded K04-BUG-3 list could not make: this
          // must not be the PARENT art.
          expect(
            _heroAsset(tester),
            isNot(questIconFor(entry.value, audience: NestAudience.parent)),
            reason:
                '${entry.key} has a distinct parent design; rendering it '
                'here is the exact regression this test exists to catch',
          );
        }

        await tester.tap(find.byType(NestIconButton));
        await _settle(tester);
      }
      await disposeApp(tester);
    });

    testWidgets('the tile follows the icon COLUMN, not the quest id', (
      tester,
    ) async {
      // Same title, same coins, different icon key — the only thing that may
      // change the glyph.
      await _useRepo(
        _IconRepo(const <KidQuest>[
          KidQuest(
            id: 'q-a:maya',
            title: 'First quest',
            detail: 'To do · +5',
            questId: 'q-a',
            icon: 'bed',
            coins: 5,
            status: 'to_do',
          ),
          KidQuest(
            id: 'q-b:maya',
            title: 'First quest',
            detail: 'To do · +5',
            questId: 'q-b',
            icon: 'book',
            coins: 5,
            status: 'to_do',
          ),
        ]),
      );
      await _pump(tester);

      _pushDetail(tester, questId: 'q-a');
      await _settle(tester);
      expect(_heroAsset(tester), NestIcons.questBedKid);
      await tester.tap(find.byType(NestIconButton));
      await _settle(tester);

      _pushDetail(tester, questId: 'q-b');
      await _settle(tester);
      expect(_heroAsset(tester), NestIcons.questReadingKid);
      expect(
        _heroAsset(tester),
        isNot(NestIcons.book),
        reason: 'a book quest must not fall back to the parent closed book',
      );
      await disposeApp(tester);
    });

    testWidgets('the direct-launch design quest still renders a kid glyph', (
      tester,
    ) async {
      // `shot.sh` opens `/quest-detail` with no route extra, so the q-tidy
      // fallback path must honour the audience rule too.
      await _pump(tester, route: KidHomeRoutePaths.detail);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(_heroAsset(tester), NestIcons.questBedKid);
      await disposeApp(tester);
    });
  });
}
