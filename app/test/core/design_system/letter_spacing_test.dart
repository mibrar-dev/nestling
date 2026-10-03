// Letter-spacing must match the design CSS: 0 unless the CSS sets it.
//
// Only `.display` (-.01em) and `.status-time` (-.01em) in
// `design/html-source/components.css`, plus the screen overrides listed
// below, set letter-spacing. Everything else uses the browser default of 0.
// A null Flutter letterSpacing would inherit the Material 3 theme value
// (e.g. 0.25, 0.5), so every [NestType] style carries an explicit value.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

void main() {
  group('NestType letterSpacing matches the design CSS', () {
    // (style name, style, expected letterSpacing, CSS source)
    final cases = <(String, TextStyle Function(), double, String)>[
      (
        'display',
        NestType.display,
        -0.34,
        'components.css .display letter-spacing:-.01em x 34px',
      ),
      ('h1', NestType.h1, 0, 'components.css .h1 sets none (browser 0)'),
      ('h2', NestType.h2, 0, 'components.css .h2 sets none (browser 0)'),
      ('h3', NestType.h3, 0, 'components.css .h3 sets none (browser 0)'),
      ('body', NestType.body, 0, 'components.css .body sets none (browser 0)'),
      (
        'bodyStrong',
        NestType.bodyStrong,
        0,
        'components.css .body sets none (browser 0)',
      ),
      (
        'bodySmall',
        NestType.bodySmall,
        0,
        'components.css .body-s sets none (browser 0)',
      ),
      (
        'bodySmallStrong',
        NestType.bodySmallStrong,
        0,
        'components.css .body-s sets none (browser 0)',
      ),
      (
        'caption',
        NestType.caption,
        0,
        'components.css .caption sets none (browser 0)',
      ),
      (
        'fieldLabel',
        NestType.fieldLabel,
        0,
        'components.css .field label sets none (browser 0)',
      ),
      (
        'sectionLabel',
        NestType.sectionLabel,
        0.78,
        'P16-settings.html .sect / P08-today.html .qgroup '
            'letter-spacing:.06em x 13px',
      ),
      (
        'chipLabel',
        NestType.chipLabel,
        0,
        'components.css .chip sets none (browser 0)',
      ),
      (
        'chipSmall',
        NestType.chipSmall,
        0,
        'components.css .badge-count / P08 .status-chip set none (browser 0)',
      ),
      (
        'navCompact',
        NestType.navCompact,
        0,
        'components.css .nav-bar.compact .nav-title sets none (browser 0)',
      ),
      (
        'tabLabel',
        NestType.tabLabel,
        0,
        'components.css .tab sets none (browser 0)',
      ),
      (
        'buttonLabel',
        NestType.buttonLabel,
        0,
        'components.css .btn sets none (browser 0)',
      ),
      (
        'money',
        NestType.money,
        0,
        'components.css .money sets none (browser 0)',
      ),
      (
        'statusTime',
        NestType.statusTime,
        -0.15,
        'components.css .status-time letter-spacing:-.01em x 15px',
      ),
      (
        'kidBody',
        NestType.kidBody,
        0,
        'components.css .kid-body sets none (browser 0)',
      ),
      (
        'kidTitle',
        NestType.kidTitle,
        0,
        'components.css .kid-title sets none (browser 0)',
      ),
      (
        'kidHero',
        NestType.kidHero,
        0,
        'components.css .kid-hero sets none (browser 0)',
      ),
      (
        'kidName',
        NestType.kidName,
        0,
        'K03 design .k3-top name sets none (browser 0)',
      ),
      (
        'kidCaption',
        NestType.kidCaption,
        0,
        'K03 design copy under the name sets none (browser 0)',
      ),
      (
        'kidChipLabel',
        NestType.kidChipLabel,
        0,
        'K03 status chip label sets none (browser 0)',
      ),
      (
        'buttonKid',
        NestType.buttonKid,
        0,
        'components.css .btn-kid sets none (browser 0)',
      ),
      (
        'coinPill',
        NestType.coinPill,
        0,
        'components.css .coin-pill sets none (browser 0)',
      ),
    ];

    for (final (name, build, expected, source) in cases) {
      test('$name is $expected ($source)', () {
        expect(build().letterSpacing, expected, reason: source);
      });
    }
  });

  group('rendered text resolves to the CSS letter-spacing', () {
    Future<void> pumpAndExpectZero(WidgetTester tester, Widget child) async {
      await pumpNest(tester, child);
      final paragraphs = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .toList();
      expect(paragraphs, isNotEmpty);
      for (final paragraph in paragraphs) {
        for (final spacing in _resolvedSpacings(
          paragraph.text,
          const TextStyle(),
        )) {
          // Null renders as no extra spacing, i.e. 0.
          expect(spacing ?? 0, 0);
        }
      }
    }

    testWidgets('NestButton label resolves to 0', (tester) async {
      await pumpAndExpectZero(
        tester,
        NestButton(label: 'Create account', onPressed: () {}),
      );
    });

    testWidgets('NestChip label resolves to 0', (tester) async {
      await pumpAndExpectZero(
        tester,
        NestChip(label: 'Sat', onSelected: (_) {}),
      );
    });

    testWidgets('NestTextField labels resolve to 0', (tester) async {
      await pumpAndExpectZero(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
      );
    });

    testWidgets('body text resolves to 0 in the app theme', (tester) async {
      await pumpAndExpectZero(
        tester,
        Text('Agree to the privacy policy to continue', style: NestType.body()),
      );
    });
  });
}

/// Every span's letterSpacing resolved through its inherited chain, so a
/// null on a leaf still counts the spacing it actually renders with.
List<double?> _resolvedSpacings(InlineSpan span, TextStyle parent) {
  if (span is! TextSpan) {
    return <double?>[parent.letterSpacing];
  }
  final effective = parent.merge(span.style);
  final out = <double?>[effective.letterSpacing];
  for (final child in span.children ?? const <InlineSpan>[]) {
    out.addAll(_resolvedSpacings(child, effective));
  }
  return out;
}
