// Audience glyphs (parent vs kid):
// - `NestAudience` parent/kid; `rewardIconFor` + `questIconFor` resolve every
//   seeded key for both audiences to an asset file that exists.
// - Parent rewards are the P14-exact glyphs; kid rewards the K08-exact glyphs
//   (plate shares K08 for both).
// - Parent quests are the P09/P10/P08-exact glyphs (questBed etc. kept);
//   kid bed/dishes/reading are the new K03/K04-exact glyphs, the rest share
//   the parent (single source).
// - P14/K03/P08/P10 delegate to the shared single source.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';
import 'package:nestling/features/today/presentation/widgets/today_loaded_body.dart';

import 'test_harness.dart';

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

void main() {
  group('Audience glyphs: new asset constants', () {
    test('kid quest + parent coffee constants point at the new files', () {
      expect(NestIcons.questBedKid, 'assets/icons/ic_quest_bed_kid.svg');
      expect(NestIcons.questDishesKid, 'assets/icons/ic_quest_dishes_kid.svg');
      expect(
        NestIcons.questReadingKid,
        'assets/icons/ic_quest_reading_kid.svg',
      );
      expect(
        NestIcons.rewardCoffeeParent,
        'assets/icons/ic_reward_coffee_parent.svg',
      );
      expect(NestlingIcons.questBedKid, 'assets/icons/ic_quest_bed_kid.svg');
      expect(
        NestlingIcons.questDishesKid,
        'assets/icons/ic_quest_dishes_kid.svg',
      );
      expect(
        NestlingIcons.questReadingKid,
        'assets/icons/ic_quest_reading_kid.svg',
      );
      expect(
        NestlingIcons.rewardCoffeeParent,
        'assets/icons/ic_reward_coffee_parent.svg',
      );
      // Parent quest exacts are untouched.
      expect(NestIcons.questBed, 'assets/icons/ic_quest_bed.svg');
      expect(NestIcons.questDishes, 'assets/icons/ic_quest_dishes.svg');
      expect(NestIcons.questHoover, 'assets/icons/ic_quest_hoover.svg');
      expect(NestIcons.questBins, 'assets/icons/ic_quest_bins.svg');
    });

    test('ic_reward_coffee_parent.svg is the exact P14 glyph', () {
      final svg = _readIcon('ic_reward_coffee_parent.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from P14-rewards.html park-café row.
      expect(svg, contains('M4 10a8 8 0 0 1 16 0'));
      expect(svg, contains('M7 10v8h10v-8M9 18v2M15 18v2'));
    });

    test('ic_quest_bed_kid.svg is the exact K03/K04 bed glyph', () {
      final svg = _readIcon('ic_quest_bed_kid.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K03-kid-home.html / K04-quest-detail.html tile.
      expect(svg, contains('M2 18v-7'));
      expect(svg, contains('M2 14h20v4'));
      expect(svg, contains('M22 18v-4a3 3 0 0 0-3-3h-9v3'));
      expect(svg, contains('M6 11V8h4v3'));
    });

    test('ic_quest_dishes_kid.svg is the exact K03 dishwasher glyph', () {
      final svg = _readIcon('ic_quest_dishes_kid.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K03-kid-home.html Empty-the-dishwasher tile.
      expect(
        svg,
        contains('<rect x="3" y="4" width="18" height="16" rx="2.5"/>'),
      );
      expect(svg, contains('M3 10h18'));
      expect(svg, contains('cx="8" cy="14.5"'));
      expect(svg, contains('M12 14h5M12 16.8h3'));
    });

    test('ic_quest_reading_kid.svg is the exact K03 reading glyph', () {
      final svg = _readIcon('ic_quest_reading_kid.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K03-kid-home.html Reading tile (open book).
      expect(svg, contains('M12 6v14'));
      expect(svg, contains('M3 4.6A2.6 2.6 0 0 1 5.6 2H11v18'));
      expect(svg, contains('M21 4.6A2.6 2.6 0 0 0 18.4 2H13v18'));
    });

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.questBedKid,
        NestIcons.questDishesKid,
        NestIcons.questReadingKid,
        NestIcons.rewardCoffeeParent,
      ]) {
        testWidgets('${mode.name}: $asset renders tinted', (tester) async {
          await pumpNest(
            tester,
            Builder(
              builder: (context) => NestIcon(asset, color: context.nest.ink),
            ),
            mode: mode,
          );
          expect(find.byType(NestIcon), findsOneWidget);
          final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
          expect(svg.colorFilter, isNotNull);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Audience glyphs: every seeded key resolves for both audiences', () {
    test('reward keys resolve for both audiences', () {
      expect(rewardIconKeys, <String>{
        'tv',
        'film',
        'moon',
        'cake',
        'coffee',
        'plate',
      });
      const parentByKey = <String, String>{
        'tv': NestIcons.screenTime,
        'film': NestIcons.film,
        'moon': NestIcons.clock,
        'cake': NestIcons.chefHat,
        'coffee': NestIcons.rewardCoffeeParent,
        'plate': NestIcons.rewardPlate,
      };
      const kidByKey = <String, String>{
        'tv': NestIcons.rewardTv,
        'film': NestIcons.rewardFilm,
        'moon': NestIcons.rewardMoon,
        'cake': NestIcons.rewardCake,
        'coffee': NestIcons.rewardCoffee,
        'plate': NestIcons.rewardPlate,
      };
      for (final key in rewardIconKeys) {
        expect(
          rewardIconFor(key, audience: NestAudience.parent),
          parentByKey[key],
          reason: 'parent reward `$key`',
        );
        expect(
          rewardIconFor(key, audience: NestAudience.kid),
          kidByKey[key],
          reason: 'kid reward `$key`',
        );
      }
      // Fallbacks stay neutral for both audiences.
      for (final audience in NestAudience.values) {
        expect(rewardIconFor('waffle', audience: audience), NestIcons.gift);
        expect(rewardIconFor('', audience: audience), NestIcons.gift);
      }
    });

    test('quest keys resolve for both audiences', () {
      expect(questIconKeys, <String>{
        'dishwasher',
        'book',
        'bins',
        'bed',
        'hoover',
        'plate',
        'paw',
        'bag',
        'leaf',
        'shirt',
        'sofa',
      });
      // Parent: P09/P10/P08-exact (questBed etc. kept; sofa falls back).
      const parentByKey = <String, String>{
        'dishwasher': NestIcons.questDishes,
        'book': NestIcons.book,
        'bins': NestIcons.questBins,
        'bed': NestIcons.questBed,
        'hoover': NestIcons.questHoover,
        'plate': NestIcons.table,
        'paw': NestIcons.paw,
        'bag': NestIcons.schoolBag,
        'leaf': NestIcons.sprout,
        'shirt': NestIcons.washingMachine,
        'sofa': NestIcons.questCard,
      };
      // Kid: K03/K04-exact where drawn, else the parent (single source).
      const kidByKey = <String, String>{
        'dishwasher': NestIcons.questDishesKid,
        'book': NestIcons.questReadingKid,
        'bins': NestIcons.questBins,
        'bed': NestIcons.questBedKid,
        'hoover': NestIcons.questHoover,
        'plate': NestIcons.table,
        'paw': NestIcons.paw,
        'bag': NestIcons.schoolBag,
        'leaf': NestIcons.sprout,
        'shirt': NestIcons.washingMachine,
        'sofa': NestIcons.questCard,
      };
      for (final key in questIconKeys) {
        expect(
          questIconFor(key, audience: NestAudience.parent),
          parentByKey[key],
          reason: 'parent quest `$key`',
        );
        expect(
          questIconFor(key, audience: NestAudience.kid),
          kidByKey[key],
          reason: 'kid quest `$key`',
        );
      }
      // Aliases keep resolving (historical spellings).
      expect(
        questIconFor('reading', audience: NestAudience.parent),
        NestIcons.book,
      );
      expect(
        questIconFor('reading', audience: NestAudience.kid),
        NestIcons.questReadingKid,
      );
      expect(
        questIconFor('bin', audience: NestAudience.parent),
        NestIcons.questBins,
      );
      expect(
        questIconFor('bin', audience: NestAudience.kid),
        NestIcons.questBins,
      );
      expect(
        questIconFor('table', audience: NestAudience.parent),
        NestIcons.table,
      );
      expect(
        questIconFor('table', audience: NestAudience.kid),
        NestIcons.table,
      );
      // Unknown keys fall back to the quest card for both audiences.
      for (final audience in NestAudience.values) {
        expect(
          questIconFor('definitely-not-an-icon', audience: audience),
          NestIcons.questCard,
        );
      }
    });

    test(
      'every seeded quest+reward key resolves to a file that exists',
      () async {
        final db = AppDatabase.memory();
        try {
          await Seed.demo(db);
          final rewards = await db.select(db.rewards).get();
          final quests = await db.select(db.quests).get();
          for (final row in rewards) {
            for (final audience in NestAudience.values) {
              final asset = rewardIconFor(row.icon, audience: audience);
              expect(
                File('assets/${asset.replaceFirst('assets/', '')}')
                    .existsSync(),
                isTrue,
                reason: 'reward `${row.icon}` (${audience.name}) → $asset',
              );
            }
          }
          for (final quest in quests) {
            for (final audience in NestAudience.values) {
              final asset = questIconFor(quest.icon, audience: audience);
              expect(
                File('assets/${asset.replaceFirst('assets/', '')}')
                    .existsSync(),
                isTrue,
                reason: 'quest `${quest.icon}` (${audience.name}) → $asset',
              );
            }
          }
        } finally {
          await db.close();
        }
      },
    );
  });

  group('Audience glyphs: merged screens delegate to the single source', () {
    test('P14 uses the parent reward glyphs', () {
      expect(
        rewardIconSpec('tv').asset,
        rewardIconFor('tv', audience: NestAudience.parent),
      );
      expect(
        rewardIconSpec('film').asset,
        rewardIconFor('film', audience: NestAudience.parent),
      );
      expect(rewardIconSpec('coffee').asset, NestIcons.rewardCoffeeParent);
      // P14 film is its own play glyph, not the K08 film-strip.
      expect(rewardIconSpec('film').asset, NestIcons.film);
      expect(rewardIconSpec('film').asset, isNot(NestIcons.rewardFilm));
    });

    test('P10 Active + P08 Today use the parent quest glyphs', () {
      expect(
        questIconAsset('dishwasher'),
        questIconFor('dishwasher', audience: NestAudience.parent),
      );
      expect(
        questIconAsset('bed'),
        questIconFor('bed', audience: NestAudience.parent),
      );
      expect(
        todayIconFor('dishwasher'),
        questIconFor('dishwasher', audience: NestAudience.parent),
      );
      expect(
        todayIconFor('bed'),
        questIconFor('bed', audience: NestAudience.parent),
      );
      expect(todayIconFor('bed'), NestIcons.questBed);
      expect(todayIconFor('dishwasher'), NestIcons.questDishes);
    });

    test('K03 kid glyphs differ from what it rendered before', () {
      // Before: appliance / closed book / sitting child.
      // Now (K03 HTML): rect dishwasher / open book / K04 bed.
      expect(
        questIconFor('dishwasher', audience: NestAudience.kid),
        NestIcons.questDishesKid,
      );
      expect(
        questIconFor('book', audience: NestAudience.kid),
        NestIcons.questReadingKid,
      );
      expect(
        questIconFor('bed', audience: NestAudience.kid),
        NestIcons.questBedKid,
      );
      expect(NestIcons.questDishesKid, isNot(NestIcons.dishwasher));
      expect(NestIcons.questReadingKid, isNot(NestIcons.book));
      expect(NestIcons.questBedKid, isNot(NestIcons.bedSit));
      expect(NestIcons.questBedKid, isNot(NestIcons.questBed));
    });
  });
}
