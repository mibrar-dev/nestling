// K08 · Reward shop — the audience glyph rule (orchestrator rule, iteration 2).
//
// Kid screens must render the KID design's glyphs, parent screens the parent
// ones: `rewardIconFor(key, audience: …)`
// (`core/design_system/components/reward_icons.dart`). K08 reaches it through
// its own one-line forwarder
// (`features/kid_shop/presentation/widgets/shop_reward_icons.dart`), which is
// feature-owned and therefore testable here.
//
// These assertions are about ART FIDELITY, so they pin exact asset paths and
// the ABSENCE of the parent glyphs: the stage-4 UI check had to catch the
// chef's hat (baking) and the sit-down mug (café) by eye, which is exactly
// what this file makes mechanical.
//
// Run directly:
//   flutter test --timeout 120s test/features/kid_shop/shop_reward_icons_test.dart

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/components/reward_icons.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_icons.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// The six `rewards.icon` keys `Seed.demo` writes, in creation order, with the
/// asset the K08 design (`.k8-art`) draws for each.
const Map<String, String> _kidGlyphs = <String, String>{
  'tv': NestIcons.rewardTv,
  'film': NestIcons.rewardFilm,
  'moon': NestIcons.rewardMoon,
  'cake': NestIcons.rewardCake,
  'coffee': NestIcons.rewardCoffee,
  'plate': NestIcons.rewardPlate,
};

/// The one `NestIcon` inside each card's `.k8-art` disc, in grid order.
List<NestIcon> _cardIcons(WidgetTester tester) => tester
    .widgetList<NestIcon>(
      find.descendant(
        of: find.byType(ShopRewardCard),
        matching: find.byType(NestIcon),
      ),
    )
    .toList();

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('shopRewardIcon resolves the KID design glyphs', () {
    test('every seeded icon key maps to its exact .k8-art asset', () {
      for (final entry in _kidGlyphs.entries) {
        expect(
          shopRewardIcon(entry.key),
          entry.value,
          reason: 'rewardIconFor("${entry.key}") must be the K08 design glyph',
        );
      }
      expect(rewardIconKeys, _kidGlyphs.keys.toSet());
    });

    test('it is the shared map asked for the kid audience', () {
      for (final key in _kidGlyphs.keys) {
        expect(
          shopRewardIcon(key),
          rewardIconFor(key, audience: NestAudience.kid),
          reason: 'K08 must not fork the map; the audience is what differs',
        );
      }
    });

    test('an unknown key falls back to the neutral gift glyph', () {
      // A reward created on another device writes whatever key that device had.
      expect(shopRewardIcon('hovercraft'), NestIcons.gift);
      expect(shopRewardIcon(''), NestIcons.gift);
      expect(
        rewardIconFor('hovercraft', audience: NestAudience.kid),
        NestIcons.gift,
      );
    });

    test('no seeded key resolves to the PARENT design glyph', () {
      // The parent branch is a different drawing for five of the six keys, so
      // an accidental `audience: parent` (or a re-forked local map) shows up
      // here instead of in a screenshot.
      final parentOnly = <String, String>{
        'tv': NestIcons.screenTime,
        'film': NestIcons.film,
        'moon': NestIcons.clock,
        'cake': NestIcons.chefHat,
        'coffee': NestIcons.rewardCoffeeParent,
      };
      for (final entry in parentOnly.entries) {
        expect(
          shopRewardIcon(entry.key),
          isNot(entry.value),
          reason: '"${entry.key}" must not use the parent glyph',
        );
        // …and the two really are different assets.
        expect(entry.value, isNot(NestIcons.gift));
      }
      // `plate` is shared by both designs on purpose (P14's HTML has no
      // dinner row), so it is the one key that may coincide.
      expect(shopRewardIcon('plate'), NestIcons.rewardPlate);
    });

    test('the assets the map points at really exist in the bundle', () {
      for (final entry in _kidGlyphs.entries) {
        expect(
          entry.value,
          startsWith('assets/icons/'),
          reason: 'rewardIconFor("${entry.key}") must be a bundled asset',
        );
      }
    });
  });

  group('the rendered card draws the kid glyph', () {
    testWidgets('all six seeded cards paint the K08 design glyphs', (
      tester,
    ) async {
      await setUpTestScope();
      await _pump(tester);

      final icons = _cardIcons(tester);
      expect(icons, hasLength(6));
      // Creation order: tv, film, moon, cake, coffee, plate.
      expect(
        icons.map((icon) => icon.assetName).toList(),
        _kidGlyphs.values.toList(),
      );
      for (final icon in icons) {
        expect(icon.size, 32, reason: '.k8-art is a 32 px glyph in a 56 disc');
        expect(icon.color, isNotNull, reason: 'the disc tints the glyph');
      }
      await disposeApp(tester);
    });

    testWidgets('a reward with an unknown key paints the gift glyph', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.rewards)
          .insert(
            RewardsCompanion.insert(
              id: 'r-odd',
              familyId: Seed.familyId,
              title: 'Something from another device',
              icon: const Value('hovercraft'),
              coinPrice: 10,
            ),
          );
      await _pump(tester);

      final icons = _cardIcons(tester);
      expect(icons, hasLength(7));
      expect(
        icons.last.assetName,
        NestIcons.gift,
        reason: 'an unknown key must never leave an empty disc',
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
