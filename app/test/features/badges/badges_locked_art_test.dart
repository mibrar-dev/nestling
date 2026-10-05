// K11 · My badges — locked-medal art regression (stage 3, iteration 3).
//
// Iteration 3 rebuilt the five still-to-do medals as a local
// `lockedMedalSvg(id)` (`badge_grid_cell.dart`, ORCHESTRATOR_NOTES.md 06:55,
// mandatory): the dashed ring is INK (`#1E1B3A` — the HTML keeps the FIRST of
// the locked `<circle>`'s two `stroke` attributes) and the ribbon
// `opacity=".4"` sits on the WHOLE `<path>` (fill AND 3 px ink stroke
// together). The shared `badge_*` asset files paint the ring `#6E6A8A` and
// are no longer used for these ids.
//
// `badges_view_test.dart` pins `bins-out` only (string + widget, light +
// dark) and `badges_art_test.dart` pins "an SVG, never the rosette" —
// neither would catch a SWAPPED glyph (bins-out drawing tidy-hero's basket)
// or a theme-dependent string. This file pins, per id and per theme:
//
//   * the pumped cell draws `SvgPicture.string` (not the shared asset);
//   * its SVG carries its OWN glyph marker and none of the other four;
//   * the ink ring, the whole-element ribbon opacity and the cream disc;
//   * the light and dark strings are IDENTICAL (medals keep own colours).
//
// Plus: the four earned ids still take the shared-asset path in BOTH states
// (plan §a — art is per id, the earned flag only flips border + sub), and
// `lockedMedalSvg` on an unknown id keeps the ring/ribbon/disc with an empty
// glyph (no crash, never the grey asset ring).
//
// No database, no clock, no `google_fonts`, no simulator. `pumpNest` cells
// need no `disposeApp` (no app scope is opened).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';

import '../../design_system/test_harness.dart';

/// The five design ids that render the local locked medal, each with the
/// glyph marker transcribed from `K11-badges.html:80-123` (also the pins in
/// `badges_view_test.dart`'s locked-art group).
const Map<String, String> _lockedMarkers = <String, String>{
  'bins-out': 'M21 28h22',
  'biscuit-sitter': 'cy="42"',
  'tidy-hero': 'M41 33H23',
  'early-bird': 'cy="38"',
  'plant-waterer': 'M25 30h14',
};

/// The four earned ids that render the shared coloured asset in both states.
const List<String> _earnedIds = <String>[
  'first-quest',
  'bed-maker-7',
  'kind-helper',
  'bookworm',
];

domain.Badge _badge(String id, {required bool earned}) => domain.Badge(
  id: id,
  title: id,
  detail: earned ? 'Got it!' : 'Keep going!',
  icon: 'medal',
  description: '',
  earned: earned,
  earnedAt: null,
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

/// The SVG string the pumped cell actually drew.
String _drawnSvg(WidgetTester tester) {
  final picture = tester.widget<SvgPicture>(
    find.descendant(
      of: find.byType(BadgeGridCell),
      matching: find.byType(SvgPicture),
    ),
  );
  final loader = picture.bytesLoader;
  expect(loader, isA<SvgStringLoader>(), reason: 'the local locked medal');
  return (loader as SvgStringLoader).provideSvg(null);
}

void main() {
  group('K11 locked medal strings (ORCHESTRATOR_NOTES 06:55)', () {
    test('every todo id keeps the ink ring, ribbon opacity and disc', () {
      for (final id in _lockedMarkers.keys) {
        final svg = lockedMedalSvg(id);
        expect(
          svg,
          contains('stroke="#1E1B3A" stroke-dasharray="5 4"'),
          reason: '$id ring is ink, 3 px, dasharray 5 4',
        );
        expect(
          svg,
          isNot(contains('stroke="#6E6A8A" stroke-dasharray')),
          reason: '$id ring is never the grey asset stroke',
        );
        expect(
          svg,
          contains('<path fill="#6E6A8A" stroke="#1E1B3A"'),
          reason: '$id ribbon keeps the design fill + ink stroke',
        );
        expect(svg, contains('opacity=".4"'), reason: '$id ribbon at 40 %');
        expect(
          svg,
          contains('fill="#F3EEE5"'),
          reason: '$id disc keeps its cream fill',
        );
      }
    });

    test('an unknown id keeps the frame with an empty glyph', () {
      // The cell never calls this path (unknown ids fall back to the rosette
      // in `_art`), but the function must not crash or emit the grey ring
      // if it ever does.
      final svg = lockedMedalSvg('mystery-badge');
      expect(svg, contains('stroke="#1E1B3A" stroke-dasharray="5 4"'));
      expect(svg, contains('opacity=".4"'));
      expect(svg, contains('fill="#F3EEE5"'));
      expect(svg, isNot(contains('stroke="#6E6A8A" stroke-dasharray')));
      for (final marker in _lockedMarkers.values) {
        expect(svg, isNot(contains(marker)));
      }
    });
  });

  group('K11 locked medals at the widget level', () {
    for (final MapEntry(key: id, value: marker) in _lockedMarkers.entries) {
      testWidgets('$id draws only its own glyph, light and dark', (
        tester,
      ) async {
        await _pumpCell(
          tester,
          _badge(id, earned: false),
          mode: ThemeMode.light,
        );
        expect(tester.takeException(), isNull);
        final light = _drawnSvg(tester);
        expect(light, contains(marker), reason: '$id own glyph in light');

        await _pumpCell(
          tester,
          _badge(id, earned: false),
          mode: ThemeMode.dark,
        );
        expect(tester.takeException(), isNull);
        final dark = _drawnSvg(tester);
        expect(dark, contains(marker), reason: '$id own glyph in dark');

        expect(
          dark,
          light,
          reason: '$id medal keeps fixed illustration colours in both themes',
        );
        for (final MapEntry(key: other, value: foreign)
            in _lockedMarkers.entries) {
          if (other == id) continue;
          expect(
            light,
            isNot(contains(foreign)),
            reason: '$id must not draw the $other glyph (light)',
          );
          expect(
            dark,
            isNot(contains(foreign)),
            reason: '$id must not draw the $other glyph (dark)',
          );
        }
      });
    }

    testWidgets('an earned todo id keeps its own medal, never the rosette', (
      tester,
    ) async {
      // Plan §a known limitation: newly-earned badges keep the design's own
      // grey art (solid border + "Got it!" flip only). Pinned for all five so
      // a future refactor cannot silently rosette them.
      for (final MapEntry(key: id, value: marker) in _lockedMarkers.entries) {
        await _pumpCell(
          tester,
          _badge(id, earned: true),
          mode: ThemeMode.light,
        );
        expect(tester.takeException(), isNull, reason: id);
        expect(find.byType(SvgPicture), findsOneWidget, reason: id);
        expect(find.byType(NestIcon), findsNothing, reason: '$id no rosette');
        expect(
          _drawnSvg(tester),
          contains(marker),
          reason: '$id keeps its glyph when earned',
        );
      }
    });
  });

  group('K11 earned medals keep the shared-asset path', () {
    testWidgets('the four earned ids never use the string loader (light)', (
      tester,
    ) async {
      for (final id in _earnedIds) {
        for (final earned in <bool>[true, false]) {
          await _pumpCell(
            tester,
            _badge(id, earned: earned),
            mode: ThemeMode.light,
          );
          expect(tester.takeException(), isNull, reason: '$id earned=$earned');
          final picture = tester.widget<SvgPicture>(
            find.descendant(
              of: find.byType(BadgeGridCell),
              matching: find.byType(SvgPicture),
            ),
          );
          expect(
            picture.bytesLoader,
            isNot(isA<SvgStringLoader>()),
            reason: '$id earned=$earned renders the shared coloured asset',
          );
          expect(find.byType(NestIcon), findsNothing, reason: '$id no rosette');
        }
      }
    });

    testWidgets('the four earned ids never use the string loader (dark)', (
      tester,
    ) async {
      for (final id in _earnedIds) {
        for (final earned in <bool>[true, false]) {
          await _pumpCell(
            tester,
            _badge(id, earned: earned),
            mode: ThemeMode.dark,
          );
          expect(tester.takeException(), isNull, reason: '$id earned=$earned');
          final picture = tester.widget<SvgPicture>(
            find.descendant(
              of: find.byType(BadgeGridCell),
              matching: find.byType(SvgPicture),
            ),
          );
          expect(
            picture.bytesLoader,
            isNot(isA<SvgStringLoader>()),
            reason: '$id earned=$earned renders the shared coloured asset',
          );
        }
      }
    });
  });
}
