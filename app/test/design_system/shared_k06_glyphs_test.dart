// Shared K06 glyphs (Pip nest):
// - wardrobeSunHat / kidPlay / kidFeed exact `K06-pip.html` glyphs under
//   NEW names, old look-alikes untouched
// - Bath (`bubbles`) already matches the design, so no new glyph was added

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

void main() {
  group('Shared K06 glyphs: constants and files', () {
    test('asset constants point at the new files, old untouched', () {
      expect(NestIcons.wardrobeSunHat, 'assets/icons/ic_wardrobe_sun_hat.svg');
      expect(NestIcons.kidFeed, 'assets/icons/ic_kid_feed.svg');
      expect(NestIcons.kidPlay, 'assets/icons/ic_kid_play.svg');
      expect(
        NestlingIcons.wardrobeSunHat,
        'assets/icons/ic_wardrobe_sun_hat.svg',
      );
      expect(NestlingIcons.kidFeed, 'assets/icons/ic_kid_feed.svg');
      expect(NestlingIcons.kidPlay, 'assets/icons/ic_kid_play.svg');
      // Existing look-alikes other screens use are unchanged.
      expect(NestIcons.sunHat, 'assets/icons/ic_sun_hat.svg');
      expect(NestIcons.feedBowl, 'assets/icons/ic_feed_bowl.svg');
      expect(NestIcons.ball, 'assets/icons/ic_ball.svg');
      expect(NestIcons.bubbles, 'assets/icons/ic_bubbles.svg');
      expect(NestIcons.crown, 'assets/icons/ic_crown.svg');
      expect(NestIcons.scarf, 'assets/icons/ic_scarf.svg');
      expect(NestIcons.wellies, 'assets/icons/ic_wellies.svg');
    });

    test('new icon files exist on disk', () {
      expect(File('assets/icons/ic_wardrobe_sun_hat.svg').existsSync(), isTrue);
      expect(File('assets/icons/ic_kid_feed.svg').existsSync(), isTrue);
      expect(File('assets/icons/ic_kid_play.svg').existsSync(), isTrue);
    });

    test('ic_wardrobe_sun_hat.svg is the exact K06 design glyph', () {
      final svg = _readIcon('ic_wardrobe_sun_hat.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K06-pip.html line 74 `.k6-ward` sun-hat `<svg>`.
      expect(svg, contains('M3 16h18l-1.6 2.4H4.6z'));
      expect(svg, contains('M7 16a5 5 0 0 1 10 0z'));
    });

    test('ic_kid_feed.svg is the exact K06 design glyph', () {
      final svg = _readIcon('ic_kid_feed.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K06-pip.html line 67 `.k6-care` Feed `<svg>`.
      expect(svg, contains('M3 11h18a9 9 0 0 1-18 0Z'));
      expect(svg, contains('M12 11V5'));
      expect(svg, contains('M9 5a3 3 0 0 1 6 0'));
    });

    test('ic_kid_play.svg is the exact K06 design glyph', () {
      final svg = _readIcon('ic_kid_play.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K06-pip.html line 68 `.k6-care` Play `<svg>`.
      expect(svg, contains('cx="12" cy="12" r="9"'));
      expect(svg, contains('M5 7.5c4 1 7 3.5 8 7.5'));
      expect(svg, contains('M19 7.5c-4 1-7 3.5-8 7.5'));
    });

    test('Bath already matches the design: no new glyph needed', () {
      // K06-pip.html line 69 `.k6-care` Bath `<svg>` is three bubbles;
      // ic_bubbles.svg draws exactly those, so K06 keeps using it.
      final svg = _readIcon('ic_bubbles.svg');
      expect(svg, contains('cx="9" cy="15" r="5"'));
      expect(svg, contains('cx="16" cy="9.5" r="3.5"'));
      expect(svg, contains('cx="16.5" cy="17.5" r="2.5"'));
    });

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.wardrobeSunHat,
        NestIcons.kidFeed,
        NestIcons.kidPlay,
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
}
