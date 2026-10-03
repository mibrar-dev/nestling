// P04 · Privacy & consent — geometry at the design's real font metrics.
//
// The rest of the suite runs on `flutter_test`'s default font, which is much
// wider than Inter, so it can only assert relationships ("the list is the sum
// of its rows"). The `[P04-10]` proof showed the way out: load the bundled
// Inter/Nunito faces with `FontLoader` and the widget tree reproduces the
// design's own numbers, so this file pins them exactly:
//
//   rows 56 · list 224 at y 287 · h1 107/34 · standfirst 149/24 ·
//   shield 187/84 · opt card 527/94 · title one 22 px line ·
//   back chevron centre 73 · CTA 708→844 (owner bottom-edge rule)
//
// It also checks the design's letter-spacing contract. `components.css` gives
// tracking only to `.display` and `.status-time` (`-.01em`); every class this
// screen uses has none. `NestType` styles omit `letterSpacing` and inherit
// `true`, so Material's `bodyMedium` (0.25 px) leaks into each run — which is
// exactly what wrapped the opt-card title in P04-10. The view now zeroes the
// title locally (the RULES-legal half of SHARED_REQUEST §7); this test pins
// the whole screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// Loads the bundled faces so the metrics match a device run.
Future<void> loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

const List<String> _titles = <String>[
  'No ads or tracking — ever',
  'Children only need a nickname',
  'Data stored in the UK (London)',
  'Delete everything anytime',
];

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Semantics)).first;

/// Every `Text` on screen with the style it actually renders at.
List<(String, double?)> _renderedRuns(WidgetTester tester) {
  final runs = <(String, double?)>[];
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final data = text.data ?? text.textSpan?.toPlainText() ?? '';
    if (data.isEmpty) continue;
    final effective = DefaultTextStyle.of(element).style.merge(text.style);
    runs.add((data, effective.letterSpacing));
  }
  return runs;
}

void main() {
  setUpAll(loadBundledFonts);

  group('P04 — design geometry at 390x844 (real Inter/Nunito)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the design numbers, exactly', (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy', theme: theme);

        // Header: chevron centre y 73, h1 line box 107→141 (28/34),
        // standfirst 149→173 (16/24) — the values read off
        // design/screens/light/P04-privacy.png ÷3.
        expect(
          tester.getCenter(find.bySemanticsLabel('Back')).dy,
          73,
          reason: 'back chevron centre (47 status + 4 + 22)',
        );
        expect(tester.getTopLeft(find.text('Your family’s privacy')).dy, 107);
        expect(
          tester.getSize(find.text('Your family’s privacy')).height,
          34,
          reason: 'h1 is 28/34',
        );
        expect(
          tester
              .getTopLeft(
                find.text('Exactly what we store — and nothing else.'),
              )
              .dy,
          149,
        );
        expect(
          tester
              .getSize(find.text('Exactly what we store — and nothing else.'))
              .height,
          24,
          reason: 'body is 16/24',
        );

        // Shield: 84 px, centred at y 229 (187 + 42).
        final shield = find.byType(NestPrivacyShield);
        expect(tester.getSize(shield), const Size(84, 84));
        expect(tester.getTopLeft(shield).dy, 187);
        expect(tester.getCenter(shield).dy, 229);

        // List: four 56 px rows at y 287, 343, 399, 455 — tiles inset 7.
        final list = find.byType(NestList);
        expect(tester.getSize(list).height, 224, reason: '4 × 56');
        expect(tester.getTopLeft(list).dy, 287);
        var expectedTop = 287.0;
        for (final title in _titles) {
          final row = _row(title);
          expect(tester.getSize(row).height, 56, reason: title);
          expect(tester.getTopLeft(row).dy, expectedTop, reason: title);
          final tile = find
              .descendant(of: row, matching: find.byType(Container))
              .first;
          expect(tester.getSize(tile), const Size(40, 40), reason: title);
          expect(
            tester.getTopLeft(tile).dy - tester.getTopLeft(row).dy,
            8,
            reason:
                '$title: 7px row padding plus the 1px the 40px tile gains when '
                'it is centred in the 42px content box (design tile tops '
                '295/351/407/463 against rows 287/343/399/455)',
          );
          expectedTop += 56;
        }

        // Opt card: 527→621 (13 + 22 + 2 + 44 + 13 = 94), one title line.
        final card = find
            .ancestor(
              of: find.text('Optional: help improve Nestling'),
              matching: find.byType(NestCard),
            )
            .first;
        expect(tester.getTopLeft(card).dy, 527);
        expect(tester.getSize(card).height, 94, reason: 'P04-10 regression');
        expect(
          tester.getSize(find.text('Optional: help improve Nestling')).height,
          22,
          reason: 'the title must stay on one 16/22 line',
        );
        expect(
          tester
              .getSize(
                find.text(
                  'Share anonymous crash reports. No names, no photos.',
                ),
              )
              .height,
          44,
          reason: 'the design wraps the opt sub to two 15/22 lines',
        );

        // Bottom bar: surface-to-edge (owner rule) and a 52 px CTA.
        final cta = find.byType(NestBottomCta);
        expect(tester.getTopLeft(cta).dy, 708);
        expect(tester.getBottomRight(cta).dy, 844, reason: 'runs to the edge');
        expect(tester.getTopLeft(cta).dx, 0);
        expect(tester.getTopRight(cta).dx, 390);
        expect(
          tester.getSize(find.byKey(const ValueKey('p04_continue'))).height,
          52,
          reason: 'the primary button is 52 tall',
        );

        // 20 px gutters, and the toggle still inside the card.
        expect(tester.getTopLeft(_row(_titles.first)).dx, 20);
        expect(tester.getTopRight(_row(_titles.first)).dx, 370);
        final toggle = find.byKey(const ValueKey('p04_crash_toggle'));
        expect(
          tester.getBottomRight(toggle).dy,
          lessThanOrEqualTo(tester.getBottomRight(card).dy),
          reason: 'the opt-in switch belongs to the opt card',
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('320dp: the same identity holds when the copy wraps', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Narrow: titles wrap to two 22 px lines, which the design system allows
      // (SPACING_SPEC §9.3 — wrap, never ellipsise). What must not change is
      // the structural identity: the list is still exactly its rows, the shield
      // is still 84, and nothing overflows.
      final list = find.byType(NestList);
      var rowSum = 0.0;
      for (final title in _titles) {
        rowSum += tester.getSize(_row(title)).height;
      }
      expect(tester.getSize(list).height, rowSum);
      expect(tester.getSize(find.byType(NestPrivacyShield)).height, 84);
      expect(tester.getTopLeft(list).dx, 20);
      expect(tester.getTopRight(list).dx, 300);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P04 — letter-spacing contract (P04-10 class)', () {
    // `components.css` sets tracking ONLY on `.display` and `.status-time`
    // (`-.01em`). `.h1`, `.body`, `.caption`, `.list-title`, `.list-sub`,
    // `.opt-title`, `.opt-sub`, `.btn` and `.footnote` all inherit the browser
    // default of 0. `NestType` omits `letterSpacing` and inherits `true`, so
    // Material's `bodyMedium` tracking (0.25) reaches every one of them —
    // which is what pushed the opt-card title over its line budget in P04-10.
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: every rendered run has no tracking', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy', theme: theme);

        final offenders = <String>[
          for (final (text, spacing) in _renderedRuns(tester))
            if (spacing != null && spacing != 0)
              '"$text" → ${spacing.toStringAsFixed(2)}px',
        ];
        expect(
          offenders,
          isEmpty,
          reason:
              'the design gives these classes no letter-spacing; a Material '
              'default leaks in through `NestType` (SHARED_REQUEST §7). The '
              'opt-card title already zeroes it locally — do the same for the '
              'rest, or fix `NestType` in core',
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the Privacy Notice dialog copy has no tracking either', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      await tester.tap(find.byKey(const ValueKey('p04_privacy_notice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final offenders = <String>[
        for (final (text, spacing) in _renderedRuns(tester))
          if (spacing != null && spacing != 0)
            '"$text" → ${spacing.toStringAsFixed(2)}px',
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'the dialog repeats the promise copy and inherits the same '
            'Material default (NestModal wraps it in its own DefaultTextStyle)',
      );

      await disposeApp(tester);
    });
  });
}
