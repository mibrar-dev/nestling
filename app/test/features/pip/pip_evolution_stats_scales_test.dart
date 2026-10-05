// K07 · the stat row and the celebration copy at EVERY width and EVERY text
// scale.
//
// Iteration 4's build fixed two bugs with one line each:
//
//   * **K07-BUG-6** (major) — the three `.k7-stats` cards were *centred* against
//     one another (`Row`'s default `CrossAxisAlignment.center`), so a card whose
//     `FittedBox(scaleDown)` shrank less was painted shorter and the row's top
//     and bottom edges splayed: 2.40 px at 320 px with the demo seed, 11.67 px
//     with a 9-digit coin total at 390. The fix is `IntrinsicHeight` +
//     `CrossAxisAlignment.stretch`, i.e. the CSS default `align-items: stretch`
//     (`.k7-stats` has no `align-items`).
//   * **K07-BUG-7** (minor) — the app-only `maxLines: 4` on the hero (whose
//     default overflow is a HARD clip) and `maxLines: 2` + ellipsis on the
//     sub-line (which carries the count) were dropped; the design clamps
//     neither `.k7-hero` nor `.k7-sub`, and `.scroll` scrolls.
//
// The live proofs pin one width for the cards and *computed* line counts for the
// caps. This file generalises both across the matrix this stage's brief names —
// 320 / 390 / 430 x light + dark x text scale 1.0 / 1.3 / 2.0 — and pins the two
// properties a fix like this must NOT break:
//
//   * **the cards must still grow with the text scale.** A pinned card height
//     would have "fixed" the splay by freezing the row, which is the opposite of
//     what accessibility needs — that is exactly why the bug stage asked for
//     `IntrinsicHeight` rather than a fixed height, and nothing tested it.
//   * **the caps must stay dropped**, measured on the RENDERED paragraphs
//     (`didExceedMaxLines`) rather than on a computed line count.
//
// **Real Nunito is mandatory in this file.** With the fallback test font all
// three stat labels measure the same width, so K07-BUG-6 is invisible there
// (fallback @320 px: three cards of 54.08 px, drift 0.00; real Nunito @320 px:
// 76.88 / 77.05 / 81.68, drift 2.40) — a pass at this font would be a lie.
// `FontLoader` mutates the engine's font collection for the rest of the test
// process, so every test here loads it in `setUp` and no test in this file may
// rely on the fallback font (the same reason `k07_bugs_test.dart` keeps its
// real-font tests last in the file).
//
// Harness rules: no database write ever happens while the app is pumping (that
// deadlocks this project's AppSession watch), every pump is bounded
// (`pumpAndSettle` hangs on the loading spinner), and every widget test ends
// with `disposeApp` INSIDE the body (RULES §7.1). The device insets are faked
// (47 top / 34 bottom) because the bar's `SafeArea` only sees them on a real
// device.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_stats.dart';

import '../../test_scope.dart';

/// The bundled faces (see the header: the fallback font hides the defect).
Future<void> loadK07Fonts() async {
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

/// The three `.k7-stats > div` boxes, left to right.
List<Rect> statCards(WidgetTester tester) => <Rect>[
  for (final key in <String>[
    'k07-card-quests',
    'k07-card-coins',
    'k07-card-stage',
  ])
    tester.getRect(find.byKey(Key(key))),
];

/// The spread of [values] — 0 when they are all equal.
double spread(List<double> values) =>
    values.reduce((a, b) => a > b ? a : b) -
    values.reduce((a, b) => a < b ? a : b);

/// `true` when the rendered paragraph under [key] is running past its
/// `maxLines` (a hard clip for the hero, an ellipsis for the sub).
bool exceedsMaxLines(WidgetTester tester, String key) => tester
    .renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(RichText),
      ),
    )
    .didExceedMaxLines;

void main() {
  setUp(() async {
    // The seeded demo database comes up with the scope; nothing in this file
    // writes to it, so the handle itself is not needed.
    await loadK07Fonts();
    await setUpTestScope();
  });

  /// Pumps `/pip-evolution` at [width] and [textScale], in [theme].
  ///
  /// `pumpAppRoute` pins 390x844 itself, so the surface is applied after the
  /// pump and the run waits for the celebration rather than trusting a
  /// fake-clock delay (the data arrives over real Drift streams).
  Future<void> pumpEvolution(
    WidgetTester tester, {
    double width = NestDevice.width,
    double textScale = 1,
    ThemeMode theme = ThemeMode.light,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    GetIt.instance<ThemeModeController>().selectMode(theme);
    await pumpAppRoute(tester, '/pip-evolution', theme: theme);
    tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
    tester.view.devicePixelRatio = 3;
    const insets = FakeViewPadding(
      top: NestDevice.statusH * 3,
      bottom: NestDevice.homeH * 3,
    );
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.reset);
    for (
      var i = 0;
      i < 60 && find.byKey(const Key('k07-cta')).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const Key('k07-cta')),
      findsOneWidget,
      reason: 'the screen must have finished loading',
    );
  }

  group('the three stat cards are ONE height, everywhere', () {
    // `.k7-stats { display: flex; gap: 10px }` with no `align-items` ⇒ stretch.
    // The card height is content-driven (the label wraps on a narrow cell and
    // the `FittedBox` scales the pair down), so "one height" has to hold at
    // every width and every text scale, in both themes.
    const cases = <({double width, double textScale, ThemeMode theme})>[
      (width: 320, textScale: 1, theme: ThemeMode.light),
      (width: 320, textScale: 1.3, theme: ThemeMode.light),
      (width: 320, textScale: 2, theme: ThemeMode.light),
      (width: 390, textScale: 1, theme: ThemeMode.light),
      (width: 390, textScale: 1.3, theme: ThemeMode.light),
      (width: 390, textScale: 2, theme: ThemeMode.light),
      (width: 430, textScale: 1, theme: ThemeMode.light),
      (width: 430, textScale: 1.3, theme: ThemeMode.light),
      (width: 430, textScale: 2, theme: ThemeMode.light),
      // Dark shares the same layout code, so it is spot-checked at the two ends
      // of the matrix rather than run nine times.
      (width: 320, textScale: 1.3, theme: ThemeMode.dark),
      (width: 430, textScale: 2, theme: ThemeMode.dark),
    ];

    for (final testCase in cases) {
      testWidgets('${testCase.theme.name} @${testCase.width.toInt()}px @'
          '${testCase.textScale}x: identical heights, tops and bottoms', (
        tester,
      ) async {
        await pumpEvolution(
          tester,
          width: testCase.width,
          textScale: testCase.textScale,
          theme: testCase.theme,
        );

        final cards = statCards(tester);
        final label =
            '${testCase.theme.name} @${testCase.width.toInt()}px @'
            '${testCase.textScale}x';
        // A 3 px ink border and a 6 px `--sh-kid` shadow make a ragged edge
        // plainly visible, and the owner ALIGNMENT rule calls any visible
        // misalignment a UI failure — so the tolerance is the measurement's,
        // not a design allowance.
        expect(
          spread(cards.map((c) => c.height).toList()),
          lessThanOrEqualTo(0.5),
          reason:
              '$label: card heights '
              '${cards.map((c) => c.height.toStringAsFixed(2)).join(' / ')} '
              '— the design stretches all three to the tallest',
        );
        expect(
          spread(cards.map((c) => c.top).toList()),
          lessThanOrEqualTo(0.5),
          reason:
              '$label: tops '
              '${cards.map((c) => c.top.toStringAsFixed(2)).join(' / ')}',
        );
        expect(
          spread(cards.map((c) => c.bottom).toList()),
          lessThanOrEqualTo(0.5),
          reason:
              '$label: bottoms '
              '${cards.map((c) => c.bottom.toStringAsFixed(2)).join(' / ')}',
        );
        // The row's own gaps are unchanged: 10 px, three equal cells on the
        // 20 px gutters (the ALIGNMENT rule's other half).
        expect(cards.first.left, closeTo(NestSpacing.padSide, 1));
        expect(
          cards.last.right,
          closeTo(testCase.width - NestSpacing.padSide, 1),
        );
        for (final gap in <double>[
          cards[1].left - cards[0].right,
          cards[2].left - cards[1].right,
        ]) {
          expect(gap, closeTo(EvolutionStatsGeometry.gap, 0.5));
        }
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }
  });

  group('the cards GROW with the text scale — they are not pinned', () {
    testWidgets('2x makes all three cards taller, and still equal', (
      tester,
    ) async {
      await pumpEvolution(tester);
      final atOne = statCards(tester);

      // A metrics change re-lays-out the live tree, so the same screen is
      // measured at Android's maximum font scale without a second pump cycle.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final atTwo = statCards(tester);

      expect(
        atTwo.first.height,
        greaterThan(atOne.first.height),
        reason:
            'a fixed card height would have "fixed" the splay by freezing the '
            'row; at 2x the labels need more room and the cards must take it '
            '(1x ${atOne.first.height.toStringAsFixed(2)} → '
            '2x ${atTwo.first.height.toStringAsFixed(2)})',
      );
      expect(
        spread(atTwo.map((c) => c.height).toList()),
        lessThanOrEqualTo(0.5),
        reason: 'still one height at 2x',
      );
      expect(spread(atTwo.map((c) => c.top).toList()), lessThanOrEqualTo(0.5));
      expect(
        spread(atTwo.map((c) => c.bottom).toList()),
        lessThanOrEqualTo(0.5),
      );
      // Growing means the content column is wrapping, not that the numbers were
      // scaled away: the value is still its full string.
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-coins'))).data,
        '175',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('the app-only line clamps stay dropped', () {
    // `.k7-hero { text-align: center; overflow-wrap: anywhere }` and
    // `.k7-sub { text-align: center }` carry no clamp in the design; in the
    // browser both grow and `.scroll` scrolls. `pip_evolution_copy_test.dart`
    // pins the hero's `maxLines` is null; the sub-line had no such pin, and its
    // cap was the one that ellipsized away the count that explains the growth.
    testWidgets('neither the hero nor the sub clamps, at 320 px and 2x', (
      tester,
    ) async {
      await pumpEvolution(tester, width: 320, textScale: 2);

      final hero = tester.widget<NestBalancedText>(
        find.byKey(const Key('k07-title')),
      );
      expect(hero.maxLines, isNull, reason: 'the design has no line clamp');
      final sub = tester.widget<Text>(find.byKey(const Key('k07-sub')));
      expect(sub.maxLines, isNull, reason: 'nor on the sub-line');
      expect(
        sub.overflow,
        isNot(TextOverflow.ellipsis),
        reason:
            'the sub-line carries the quest count, so it must not be '
            'ellipsized away at an accessibility text scale',
      );

      // Measured on the RENDERED paragraphs, not on a computed line count.
      expect(
        exceedsMaxLines(tester, 'k07-title'),
        isFalse,
        reason: 'the hero must not be cut mid-glyph',
      );
      expect(
        exceedsMaxLines(tester, 'k07-sub'),
        isFalse,
        reason: '"Because you helped N times" must render whole',
      );
      // The copy itself is unchanged by the fix: the whole sentence is there.
      expect(find.text('Because you helped 4 times'), findsOneWidget);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      // And it all still fits the scroll, CTA reachable.
      expect(find.byKey(const Key('k07-cta')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
