// Shared reward glyphs (K08 + P14):
// - six exact K08 `.k8-art` SVGs under new `reward*` names, old untouched
// - `rewardIconFor` is the single source; P14 `rewardIconSpec` delegates to it
// - every seeded key resolves to an asset file that exists

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';

import 'test_harness.dart';

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

void main() {
  group('Shared reward glyphs: constants and files', () {
    test('asset constants point at the new files, old untouched', () {
      expect(NestIcons.rewardTv, 'assets/icons/ic_reward_tv.svg');
      expect(NestIcons.rewardFilm, 'assets/icons/ic_reward_film.svg');
      expect(NestIcons.rewardMoon, 'assets/icons/ic_reward_moon.svg');
      expect(NestIcons.rewardCake, 'assets/icons/ic_reward_cake.svg');
      expect(NestIcons.rewardCoffee, 'assets/icons/ic_reward_coffee.svg');
      expect(NestIcons.rewardPlate, 'assets/icons/ic_reward_plate.svg');
      expect(NestlingIcons.rewardTv, 'assets/icons/ic_reward_tv.svg');
      expect(NestlingIcons.rewardFilm, 'assets/icons/ic_reward_film.svg');
      expect(NestlingIcons.rewardMoon, 'assets/icons/ic_reward_moon.svg');
      expect(NestlingIcons.rewardCake, 'assets/icons/ic_reward_cake.svg');
      expect(NestlingIcons.rewardCoffee, 'assets/icons/ic_reward_coffee.svg');
      expect(NestlingIcons.rewardPlate, 'assets/icons/ic_reward_plate.svg');
      // Existing look-alikes other screens may use are unchanged.
      expect(NestIcons.screenTime, 'assets/icons/ic_screen_time.svg');
      expect(NestIcons.film, 'assets/icons/ic_film.svg');
      expect(NestIcons.filmStrip, 'assets/icons/ic_film_strip.svg');
      expect(NestIcons.clock, 'assets/icons/ic_clock.svg');
      expect(NestIcons.moon, 'assets/icons/ic_moon.svg');
      expect(NestIcons.chefHat, 'assets/icons/ic_chef_hat.svg');
      expect(NestIcons.cafe, 'assets/icons/ic_cafe.svg');
      expect(NestIcons.pizza, 'assets/icons/ic_pizza.svg');
    });

    test('ic_reward_tv.svg is the exact K08 TV glyph', () {
      final svg = _readIcon('ic_reward_tv.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 0 `.k8-art` `<svg>`.
      expect(
        svg,
        contains('<rect x="2.5" y="4" width="19" height="13" rx="2.5"/>'),
      );
      expect(svg, contains('M8 21h8M12 17v4'));
    });

    test('ic_reward_film.svg is the exact K08 film-strip glyph', () {
      final svg = _readIcon('ic_reward_film.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 1.
      expect(
        svg,
        contains('<rect x="2.5" y="4" width="19" height="16" rx="2.5"/>'),
      );
      expect(svg, contains('M7 4v16M17 4v16'));
      expect(svg, contains('M2.5 9h4.5M2.5 15h4.5M17 9h4.5M17 15h4.5'));
    });

    test('ic_reward_moon.svg is the exact K08 crescent glyph', () {
      final svg = _readIcon('ic_reward_moon.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 2 (note the closing Z).
      expect(svg, contains('M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z'));
    });

    test('ic_reward_cake.svg is the exact K08 baking glyph', () {
      final svg = _readIcon('ic_reward_cake.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 3 (basket/bucket, not a chef hat).
      expect(svg, contains('M8 10.5a4 4 0 0 1 8 0'));
      expect(
        svg,
        contains(
          'M5 10.5h14l-1.2 9.2A2 2 0 0 1 15.8 21.5H8.2a2 2 0 0 1-2-1.8Z',
        ),
      );
      expect(svg, contains('M12 4.5v3'));
    });

    test('ic_reward_coffee.svg is the exact K08 takeaway-cup glyph', () {
      final svg = _readIcon('ic_reward_coffee.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 4 (domed lid + tapered body).
      expect(svg, contains('M12 3.5a5 5 0 0 1 5 5H7a5 5 0 0 1 5-5Z'));
      expect(
        svg,
        contains(
          'M9 8.5h6l-1.5 11.2a1.6 1.6 0 0 1-1.6 1.3h-.8a1.6 1.6 0 0 1-1.6-1.3Z',
        ),
      );
    });

    test('ic_reward_plate.svg is the exact K08 dinner glyph', () {
      final svg = _readIcon('ic_reward_plate.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K08-shop.html card 5 (plain triangle + outline dots).
      expect(
        svg,
        contains('M12 3 3.2 18.8a1 1 0 0 0 .9 1.4h15.8a1 1 0 0 0 .9-1.4Z'),
      );
      expect(svg, contains('<circle cx="10" cy="12" r="1.1"/>'));
      expect(svg, contains('<circle cx="14.5" cy="15" r="1.1"/>'));
      expect(svg, contains('<circle cx="9.5" cy="16.5" r="1.1"/>'));
    });

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.rewardTv,
        NestIcons.rewardFilm,
        NestIcons.rewardMoon,
        NestIcons.rewardCake,
        NestIcons.rewardCoffee,
        NestIcons.rewardPlate,
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

  group('Shared reward glyphs: single source map', () {
    test('rewardIconFor covers every seeded key plus fallback', () {
      expect(rewardIconKeys, <String>{
        'tv',
        'film',
        'moon',
        'cake',
        'coffee',
        'plate',
      });
      expect(rewardIconFor('tv'), NestIcons.rewardTv);
      expect(rewardIconFor('film'), NestIcons.rewardFilm);
      expect(rewardIconFor('moon'), NestIcons.rewardMoon);
      expect(rewardIconFor('cake'), NestIcons.rewardCake);
      expect(rewardIconFor('coffee'), NestIcons.rewardCoffee);
      expect(rewardIconFor('plate'), NestIcons.rewardPlate);
      // Unknown keys fall back to the neutral gift glyph.
      expect(rewardIconFor('waffle'), NestIcons.gift);
      expect(rewardIconFor(''), NestIcons.gift);
    });

    test(
      'every seeded reward key resolves to an asset file that exists',
      () async {
        final db = AppDatabase.memory();
        try {
          await Seed.demo(db);
          final rows = await db.select(db.rewards).get();
          expect(rows.map((r) => r.icon).toSet(), <String>{
            'tv',
            'film',
            'moon',
            'cake',
            'coffee',
            'plate',
          });
          for (final row in rows) {
            final asset = rewardIconFor(row.icon);
            expect(
              File('assets/${asset.replaceFirst('assets/', '')}').existsSync(),
              isTrue,
              reason: 'missing asset for icon `${row.icon}` → $asset',
            );
          }
        } finally {
          await db.close();
        }
      },
    );

    test('P14 rewardIconSpec is the single source (art == rewardIconFor)', () {
      const expectedTints = <String, NestTileTint>{
        'tv': NestTileTint.sky,
        'film': NestTileTint.lilac,
        'moon': NestTileTint.peach,
        'cake': NestTileTint.coin,
        'coffee': NestTileTint.leaf,
        'plate': NestTileTint.leaf,
      };
      for (final entry in expectedTints.entries) {
        final spec = rewardIconSpec(entry.key);
        expect(
          spec.asset,
          rewardIconFor(entry.key),
          reason: 'P14 art for `${entry.key}` must come from rewardIconFor',
        );
        expect(spec.tint, entry.value);
        // Legacy map agrees (backward compat, same single source).
        expect(rewardIconSpecs[entry.key]!.asset, rewardIconFor(entry.key));
      }
      // Unknown keys fall back to the neutral gift tile.
      final fallback = rewardIconSpec('waffle');
      expect(fallback.asset, NestIcons.gift);
      expect(fallback.tint, NestTileTint.neutral);
    });
  });
}
