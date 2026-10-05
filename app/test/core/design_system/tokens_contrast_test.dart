import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

// Shared design-system token contrast (WCAG 2.1 AA).
//
// Computes the WCAG relative-luminance ratio for the real text/background
// token pairs in BOTH themes. Body text needs >= 4.5, large bold
// (>= 18pt bold, e.g. the 28px w900 kid title) needs >= 3. If a pair fails,
// the expectation reports it with the measured ratio. Token colours are
// never changed here — the orchestrator decides.

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double wcagRatio(Color text, Color background) {
  final a = _luminance(text);
  final b = _luminance(background);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('token contrast (WCAG AA)', () {
    // Body text pairs: 13-16px regular/semibold on their surfaces.
    final bodyPairs =
        <
          String,
          (Color Function(NestSchemeColors), Color Function(NestSchemeColors))
        >{
          'ink/paper': ((c) => c.ink, (c) => c.paper),
          'ink2/surface': ((c) => c.ink2, (c) => c.surface),
          'ink3/surface': ((c) => c.ink3, (c) => c.surface),
          'onLeaf/leaf': ((c) => c.onLeaf, (c) => c.leaf),
          'coinInk/coinTint': ((c) => c.coinInk, (c) => c.coinTint),
          'leafInk/leafTint': ((c) => c.leafInk, (c) => c.leafTint),
          'sky/skyTint': ((c) => c.sky, (c) => c.skyTint),
          'danger/surface': ((c) => c.danger, (c) => c.surface),
          'onWarm/coin': ((c) => c.onWarm, (c) => c.coin),
          'onAccent/lilacStrong': ((c) => c.onAccent, (c) => c.lilacStrong),
          'onHero/heroBg': ((c) => c.onHero, (c) => c.heroBg),
        };

    for (final theme in const <(String, NestSchemeColors)>[
      ('light', NestColors.light),
      ('dark', NestColors.dark),
    ]) {
      final name = theme.$1;
      final colors = theme.$2;
      for (final entry in bodyPairs.entries) {
        test('$name ${entry.key} body text >= 4.5', () {
          final text = entry.value.$1(colors);
          final bg = entry.value.$2(colors);
          final ratio = wcagRatio(text, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name ${entry.key} contrast ${ratio.toStringAsFixed(2)} '
                'below WCAG AA 4.5 (orchestrator decides, colours unchanged)',
          );
        });
      }

      // Large bold: the 28px w900 kid title on the sky-gradient top colour.
      test('$name kid title on kidSkyTop large bold >= 3', () {
        final ratio = wcagRatio(colors.ink, colors.kidSkyTop);
        expect(
          ratio,
          greaterThanOrEqualTo(3),
          reason:
              '$name ink/kidSkyTop contrast ${ratio.toStringAsFixed(2)} '
              'below WCAG large-bold 3 (orchestrator decides)',
        );
      });

      // The hero caption tone on its fill.
      test('$name onHero2 on heroBg >= 4.5', () {
        final ratio = wcagRatio(colors.onHero2, colors.heroBg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$name onHero2/heroBg contrast ${ratio.toStringAsFixed(2)} '
              'below 4.5 (orchestrator decides)',
        );
      });
    }
  });
}
