// Shared K09 jar glyphs (My jar history rows):
// - `jarPocketMoney`: exact `K09-jar.html:85` coin-slot mark (circle r8 +
//   `M12 8v8` + `M9.5 9.5h5` + `M9.5 14.5h5`), distinct from `poundCoin`
// - `questBinsKid`: exact `K09-jar.html:90` lidded bin
//   (`M6 3h12l-2 5H8Z` + `M8 8v10a2 2 0 0 0 8 0V8`); the kid set now uses
//   it for `bins`/`bin` because K03/K04 draw no bins row and K09 is where
//   bins appears most prominently
// - gift: `K09-jar.html:95` already matches `ic_gift.svg`, so K09 reuses
//   `NestIcons.gift` (no new file)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

void main() {
  group('Shared jar glyphs: constants and files', () {
    test('asset constants point at the new files, old untouched', () {
      expect(NestIcons.jarPocketMoney, 'assets/icons/ic_jar_pocket_money.svg');
      expect(NestIcons.questBinsKid, 'assets/icons/ic_quest_bins_kid.svg');
      expect(
        NestlingIcons.jarPocketMoney,
        'assets/icons/ic_jar_pocket_money.svg',
      );
      expect(NestlingIcons.questBinsKid, 'assets/icons/ic_quest_bins_kid.svg');
      // Existing look-alikes other screens use are unchanged.
      expect(NestIcons.poundCoin, 'assets/icons/ic_pound_coin.svg');
      expect(NestIcons.questBins, 'assets/icons/ic_quest_bins.svg');
      expect(NestIcons.gift, 'assets/icons/ic_gift.svg');
      expect(NestIcons.bin, 'assets/icons/ic_bin.svg');
      expect(NestIcons.ribbon, 'assets/icons/ic_ribbon.svg');
    });

    test('new icon files exist on disk', () {
      expect(File('assets/icons/ic_jar_pocket_money.svg').existsSync(), isTrue);
      expect(File('assets/icons/ic_quest_bins_kid.svg').existsSync(), isTrue);
      expect(File('assets/icons/ic_gift.svg').existsSync(), isTrue);
    });

    test('ic_jar_pocket_money.svg is the exact K09 coin-slot glyph', () {
      final svg = _readIcon('ic_jar_pocket_money.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K09-jar.html line 85 `.k9-ico` pocket-money `<svg>`.
      expect(svg, contains('cx="12" cy="12" r="8"'));
      expect(svg, contains('M12 8v8'));
      expect(svg, contains('M9.5 9.5h5'));
      expect(svg, contains('M9.5 14.5h5'));
      // It is NOT the pound-coin letterform.
      expect(svg, isNot(contains('M14.6 7.5')));
    });

    test('ic_quest_bins_kid.svg is the exact K09 lidded-bin glyph', () {
      final svg = _readIcon('ic_quest_bins_kid.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K09-jar.html line 90 `.k9-ico` bins `<svg>`.
      expect(svg, contains('M6 3h12l-2 5H8Z'));
      expect(svg, contains('M8 8v10a2 2 0 0 0 8 0V8'));
      // It is NOT the parent handled case.
      expect(svg, isNot(contains('M3 7h13v9H3z')));
    });

    test('gift already matches K09: no new jarGift file needed', () {
      // K09-jar.html line 95 `.k9-ico` birthday `<svg>`: rect + mid line +
      // vertical + two bow loops. ic_gift.svg draws exactly those (the two
      // straight strokes are combined into one `m` subpath).
      final svg = _readIcon('ic_gift.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      expect(svg, contains('y="9"'));
      expect(svg, contains('M3 13h18'));
      expect(svg, contains('v12'));
      expect(svg, contains('S9.5 3 7 3a2.2 2.2 0 0 0 0 6'));
      expect(svg, contains('s2.5-6 5-6a2.2 2.2 0 0 1 0 6'));
    });

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.jarPocketMoney,
        NestIcons.questBinsKid,
        NestIcons.gift,
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

  group('Shared jar glyphs: questIconFor bins split', () {
    test('kid bins uses the K09 lidded bin, parent keeps P09', () {
      expect(
        questIconFor('bins', audience: NestAudience.kid),
        NestIcons.questBinsKid,
      );
      expect(
        questIconFor('bin', audience: NestAudience.kid),
        NestIcons.questBinsKid,
      );
      expect(
        questIconFor('bins', audience: NestAudience.parent),
        NestIcons.questBins,
      );
      expect(
        questIconFor('bin', audience: NestAudience.parent),
        NestIcons.questBins,
      );
      expect(NestIcons.questBinsKid, isNot(NestIcons.questBins));
    });

    test('kid bins asset file exists', () {
      final asset = questIconFor('bins', audience: NestAudience.kid);
      expect(
        File('assets/${asset.replaceFirst('assets/', '')}').existsSync(),
        isTrue,
        reason: 'kid `bins` → $asset',
      );
    });
  });
}
