// K11 · My badges — badge-art contract (stage 3, iteration 1).
//
// `ORCHESTRATOR_NOTES.md` (02:40, mandatory):
//   "every one of the nine ids must render its own design medal (bins-out
//    bin, biscuit-sitter paw/biscuit, tidy-hero basket, early-bird sun,
//    plant-waterer can) in BOTH earned and locked states, light and dark …
//    The generic rosette fallback is only for ids not in the design."
//
// This is the test side of that note. Two halves, because a widget cannot
// report which asset string it was handed:
//
//   1. ASSET LEVEL — all nine `NestlingIllustrations.badge*` files exist and
//      load from the bundle, and no two ids share one file (a typo that points
//      two ids at one drawing would otherwise ship silently).
//   2. CELL LEVEL — each of the nine design ids, pumped as a real
//      `BadgeGridCell` in earned AND locked state, light AND dark, draws an
//      SVG medal and never the neutral rosette; an id outside the design does
//      fall back to the rosette.
//
// The ids come from the test, not the seed, so this holds before and after the
// nine-badge seed correction lands on `main` (`SHARED_REQUEST.md`).
//
// No simulator. No `DateTime.now`, no `google_fonts`.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';

import '../../design_system/test_harness.dart';

/// The nine ids the design draws, with the asset each must render.
const List<(String, String, String)> _designBadges = <(String, String, String)>[
  ('first-quest', 'First quest', NestlingIllustrations.badgeFirstQuest),
  ('bed-maker-7', 'Bed maker ×7', NestlingIllustrations.badgeBedMaker),
  ('kind-helper', 'Kind helper', NestlingIllustrations.badgeKindHelper),
  ('bookworm', 'Bookworm', NestlingIllustrations.badgeBookworm),
  ('bins-out', 'Bins out', NestlingIllustrations.badgeBinsOut),
  (
    'biscuit-sitter',
    'Biscuit sitter',
    NestlingIllustrations.badgeBiscuitSitter,
  ),
  ('tidy-hero', 'Tidy hero', NestlingIllustrations.badgeTidyHero),
  ('early-bird', 'Early bird', NestlingIllustrations.badgeEarlyBird),
  ('plant-waterer', 'Plant waterer', NestlingIllustrations.badgePlantWaterer),
];

domain.Badge _badge(String id, String title, {required bool earned}) =>
    domain.Badge(
      id: id,
      title: title,
      detail: earned ? 'Got it!' : 'Keep going!',
      icon: 'medal',
      description: '',
      earned: earned,
      earnedAt: null,
    );

Finder _art() => find.descendant(
  of: find.byType(BadgeGridCell),
  matching: find.byType(SvgPicture),
);

Finder _ribbonFallback() => find.byWidgetPredicate(
  (w) => w is NestIcon && w.assetName == NestIcons.ribbon,
);

Future<void> _pumpCell(
  WidgetTester tester,
  domain.Badge badge, {
  required ThemeMode mode,
}) => pumpNest(
  tester,
  SizedBox(width: 350, child: BadgeGridCell(badge: badge)),
  mode: mode,
);

void main() {
  group('K11 badge art at the asset level', () {
    test('the nine design medals are nine different files', () {
      final assets = <String>{};
      for (final (id, _, asset) in _designBadges) {
        expect(assets.add(asset), isTrue, reason: '$id reuses another medal');
      }
      expect(assets, hasLength(9));
    });

    test('every design medal file exists in the bundle', () async {
      for (final (id, _, asset) in _designBadges) {
        final bytes = await rootBundle.load(asset);
        expect(
          bytes.lengthInBytes,
          greaterThan(200),
          reason: '$id → $asset is missing or empty',
        );
        expect(
          String.fromCharCodes(bytes.buffer.asUint8List()),
          contains('<svg'),
          reason: '$id → $asset is not an SVG drawing',
        );
      }
    });
  });

  group('K11 badge art at the cell level', () {
    for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final earned in <bool>[true, false]) {
        testWidgets(
          'the nine design ids each draw their own medal in ${mode.name} '
          '(${earned ? 'earned' : 'locked'})',
          (tester) async {
            for (final (id, title, _) in _designBadges) {
              await _pumpCell(
                tester,
                _badge(id, title, earned: earned),
                mode: mode,
              );
              expect(tester.takeException(), isNull, reason: id);
              expect(
                _ribbonFallback(),
                findsNothing,
                reason:
                    '$id is a design badge — the rosette fallback is only for '
                    'ids that are NOT in the design',
              );
              expect(
                find.byType(NestIcon),
                findsNothing,
                reason: '$id draws its medal, never a generic glyph',
              );
              expect(
                _art(),
                findsOneWidget,
                reason: '$id must render its own SVG medal',
              );
              expect(
                tester.getSize(_art()),
                const Size(60, 60),
                reason: '$id medal is 60×60 (.k11-medal)',
              );
            }
          },
        );
      }
    }

    testWidgets('an id outside the design falls back to the rosette', (
      tester,
    ) async {
      await _pumpCell(
        tester,
        _badge('not-in-the-design', 'Mystery badge', earned: false),
        mode: ThemeMode.light,
      );
      expect(tester.takeException(), isNull);
      expect(_ribbonFallback(), findsOneWidget);
      expect(
        find.byType(NestIcon),
        findsOneWidget,
        reason: 'the rosette glyph, not a medal',
      );
    });
  });
}
