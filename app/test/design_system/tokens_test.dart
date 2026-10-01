import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

void main() {
  group('NestColors', () {
    test('light transcribes tokens.css :root', () {
      expect(NestColors.light.ink, const Color(0xFF1E1B3A));
      expect(NestColors.light.paper, const Color(0xFFFBF7F0));
      expect(NestColors.light.leaf, const Color(0xFF17804F));
      expect(NestColors.light.leafInk, const Color(0xFF0B5C38));
      expect(NestColors.light.onLeaf, const Color(0xFFFFFFFF));
      expect(NestColors.light.onWarm, const Color(0xFF1E1B3A));
      expect(NestColors.light.heroBg, const Color(0xFF1E1B3A));
      expect(NestColors.light.onHero2, const Color(0xFFC9C4DC));
      expect(NestColors.light.lilacStrong, const Color(0xFF6A58E8));
      expect(NestColors.light.appleBg, const Color(0xFF000000));
      expect(NestColors.light.googleLine, const Color(0xFFE7E0D4));
      expect(NestColors.light.scrim, const Color(0x731E1B3A));
      expect(NestColors.light.track, const Color(0xFFD9D3C6));
      expect(NestColors.light.aPeach, const Color(0xFFB44A1F));
      expect(NestColors.light.kidSkyTop, const Color(0xFFCFE6FF));
      expect(NestColors.light.kidHorizon, const Color(0xFFEAF7E2));
    });

    test('dark transcribes :root[data-theme="dark"]', () {
      expect(NestColors.dark.ink, const Color(0xFFF3F0FA));
      expect(NestColors.dark.paper, const Color(0xFF15131F));
      expect(NestColors.dark.surface, const Color(0xFF1F1C2E));
      expect(NestColors.dark.leaf, const Color(0xFF3CC98A));
      expect(NestColors.dark.onLeaf, const Color(0xFF0E1A14));
      expect(NestColors.dark.onWarm, const Color(0xFF1E1B3A));
      expect(NestColors.dark.heroBg, const Color(0xFF2A2640));
      expect(NestColors.dark.lilacStrong, const Color(0xFFA89BFF));
      expect(NestColors.dark.appleBg, const Color(0xFFFFFFFF));
      expect(NestColors.dark.googleBg, const Color(0xFF131314));
      expect(NestColors.dark.scrim, const Color(0x9E000000));
      expect(NestColors.dark.kidSkyTop, const Color(0xFF1B2150));
      expect(NestColors.dark.kidMeadow, const Color(0xFF1E4A3A));
    });

    test('hero fill never derives from ink', () {
      expect(NestColors.light.heroBg, isNot(NestColors.light.ink2));
      expect(NestColors.dark.heroBg, isNot(NestColors.dark.ink));
    });

    test('lerp endpoints round-trip', () {
      final mid = NestSchemeColors.lerp(NestColors.light, NestColors.dark, 0.5);
      expect(
        mid.ink,
        Color.lerp(NestColors.light.ink, NestColors.dark.ink, 0.5),
      );
      expect(
        NestSchemeColors.lerp(NestColors.light, NestColors.dark, 0).ink,
        NestColors.light.ink,
      );
      expect(
        NestSchemeColors.lerp(NestColors.light, NestColors.dark, 1).ink,
        NestColors.dark.ink,
      );
    });

    test('copyWith replaces one token', () {
      final next = NestColors.light.copyWith(leaf: const Color(0xFF000000));
      expect(next.leaf, const Color(0xFF000000));
      expect(next.ink, NestColors.light.ink);
    });
  });

  group('spacing / radii / motion', () {
    test('4pt scale and side padding', () {
      expect(NestSpacing.s1, 4);
      expect(NestSpacing.s2, 8);
      expect(NestSpacing.s3, 12);
      expect(NestSpacing.s4, 16);
      expect(NestSpacing.s5, 20);
      expect(NestSpacing.s6, 24);
      expect(NestSpacing.s8, 32);
      expect(NestSpacing.s10, 40);
      expect(NestSpacing.padSide, 20);
    });

    test('device chrome and tap targets', () {
      expect(NestDevice.statusH, 47);
      expect(NestDevice.homeH, 34);
      expect(NestDevice.tabH, 84);
      expect(NestDevice.tapParent, 44);
      expect(NestDevice.tapKid, 56);
    });

    test('radii match tokens', () {
      expect(NestRadii.s, 10);
      expect(NestRadii.m, 16);
      expect(NestRadii.l, 24);
      expect(NestRadii.xl, 32);
      expect(NestRadii.pill, 999);
    });

    test('shadows carry the spec offsets', () {
      expect(NestShadows.shKid.single.offset, const Offset(0, 6));
      expect(NestShadows.shKidDark.single.offset, const Offset(0, 6));
      expect(NestShadows.sh1.length, 2);
      expect(NestShadows.sh2.length, 1);
    });

    test('motion durations match tokens', () {
      expect(NestMotion.fast, const Duration(milliseconds: 180));
      expect(NestMotion.spring, const Duration(milliseconds: 320));
    });
  });

  group('typography', () {
    test('line heights equal lineHeight / fontSize', () {
      final display = NestType.display();
      expect(display.fontSize, 34);
      expect(display.height, 40 / 34);
      final body = NestType.body();
      expect(body.fontSize, 16);
      expect(body.height, 24 / 16);
      final kidHero = NestType.kidHero();
      expect(kidHero.fontSize, 40);
      expect(kidHero.height, 44 / 40);
      final caption = NestType.caption();
      expect(caption.fontSize, 13);
      expect(caption.height, 18 / 13);
    });

    test('money uses tabular figures', () {
      expect(
        NestType.money().fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('formatPounds needs no intl', () {
      expect(formatPounds(12.5), '£12.50');
      expect(formatPounds(0), '£0.00');
      expect(formatPounds(3), '£3.00');
    });
  });

  group('NestTheme', () {
    test('light and dark carry token extensions', () {
      final light = NestTheme.light();
      final dark = NestTheme.dark();
      expect(light.extension<NestTokens>()!.colors.ink, NestColors.light.ink);
      expect(dark.extension<NestTokens>()!.colors.ink, NestColors.dark.ink);
      expect(light.extension<NestKidTheme>(), isNotNull);
      expect(light.useMaterial3, isTrue);
      expect(light.scaffoldBackgroundColor, NestColors.light.paper);
      expect(dark.scaffoldBackgroundColor, NestColors.dark.paper);
    });
  });
}
