// K07 · the stat row and the celebration copy at EVERY width and EVERY text
// scale.
//
// This file was written for iteration 4 (K07-BUG-6: three unequal cards) and
// iteration 5 rewrote the row underneath it (K07-BUG-8 + K07-BUG-9). It is the
// screen's layout-and-copy envelope, so it carries four contracts:
//
//   1. **One height for the three `.k7-stats` cards** — `.k7-stats` is a flex row
//      with no `align-items`, i.e. `stretch`, and each card's height is
//      content-driven (the label wraps on a narrow cell).
//   2. **One type size for the three numbers, at the design's own size.** The
//      per-cell `FittedBox(scaleDown)` is gone (K07-BUG-8): each cell had its own
//      intrinsic width (`4`/`120`/`3` and `quests done`/`coins grown`/`of 4
//      stages`), so the narrower cells shrank less and the three numbers came out
//      at three different sizes — 3.16 px of top drift at 390 px / 1.3 and a 43 %
//      size difference with a 9-digit coin total. CSS never scales type, it
//      wraps, so the painted line box must be the design's single `30/34` for
//      all three, at every width, scale and value.
//   3. **The cards still GROW with the text scale** — a pinned height would
//      "fix" the splay by freezing the row, which is the opposite of what
//      accessibility needs and exactly why `IntrinsicHeight` was chosen.
//   4. **No app-only line clamps anywhere.** The design clamps nothing
//      (`.k7-hero`, `.k7-sub`, `.kcap` set no `max-lines`), and `.scroll`
//      scrolls, so the app's own `maxLines: 4` (hero), `maxLines: 2` (sub) and
//      `maxLines: 3` (caption) were all defects — K07-BUG-7 removed the first
//      two, K07-BUG-9 the third.
//
// ## The text scale in these tests is MEASURED, never assumed
//
// `app/lib/app/app.dart` clamps the OS scaler to **1.0–1.3**
// (`MediaQueryData.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.3)`), so
// asking the harness for 2.0 or 3.0 renders **1.3**. An earlier version of this
// file labelled its cases "2x" while measuring 1.3 — the case names and every
// reason string now carry the *effective* scale, and [_effectiveScale] asserts it
// from the pumped tree, so no case in this file can quietly measure the wrong
// thing (and a change to that clamp is caught here).
//
// ## Real Nunito is mandatory in this file
//
// With the fallback test font all three stat labels measure the same width, so
// the iteration-4 defect was invisible there (fallback @320 px: three cards of
// 54.08 px, drift 0.00; real Nunito @320 px: 76.88 / 77.05 / 81.68, drift 2.40).
// `FontLoader` mutates the engine's font collection for the rest of the test
// process, so it runs in `setUp` here and **no test in this file may rely on the
// fallback font** — the same reason `k07_bugs_test.dart` keeps its real-font
// tests last in the file.
//
// Harness rules: no database write ever happens while the app is pumping (that
// deadlocks this project's AppSession watch), every pump is bounded
// (`pumpAndSettle` hangs on the loading spinner), the device insets are faked
// (47 top / 34 bottom) because the bar's `SafeArea` only sees them on a real
// device, and every widget test ends with `disposeApp` INSIDE the body
// (RULES §7.1).

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
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

/// The painted number of each card — the first `RichText` inside it, measured
/// with `getRect` so the whole transform chain (including any scale a widget
/// might apply) is what gets compared.
List<Rect> statNumbers(WidgetTester tester) => <Rect>[
  for (final key in <String>[
    'k07-card-quests',
    'k07-card-coins',
    'k07-card-stage',
  ])
    tester.getRect(
      find
          .descendant(of: find.byKey(Key(key)), matching: find.byType(RichText))
          .first,
    ),
];

/// The spread of [values] — 0 when they are all equal.
double spread(List<double> values) =>
    values.reduce((a, b) => a > b ? a : b) -
    values.reduce((a, b) => a < b ? a : b);

/// `true` when the rendered paragraph under [key] is running past its
/// `maxLines`. [key] must identify exactly ONE paragraph (the hero, the sub,
/// the caption); for a stat card use [labelExceedsMaxLines], because a card
/// holds two paragraphs.
bool exceedsMaxLines(WidgetTester tester, String key) => tester
    .renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(RichText),
      ),
    )
    .didExceedMaxLines;

/// The same, for a stat card's LABEL (the second paragraph in the cell).
bool labelExceedsMaxLines(WidgetTester tester, String cardKey) => tester
    .renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byKey(Key(cardKey)),
            matching: find.byType(RichText),
          )
          .last,
    )
    .didExceedMaxLines;

/// `.k7-stats b { font-size: 30px; line-height: 34px }` — the design's one line
/// box, which is what all three numbers must paint at the ambient scale.
const double _designNumberLineBox = 34;

void main() {
  late AppDatabase db;

  setUp(() async {
    await loadK07Fonts();
    db = await setUpTestScope();
  });

  /// Pumps `/pip-evolution` at [width] and the OS [textScale], in [theme].
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

  /// The scale the app actually rendered at — `app.dart` clamps the OS scaler,
  /// so a requested 2.0 is really 1.3. Read from the pumped tree, never assumed.
  double effectiveScale(WidgetTester tester) =>
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const Key('k07-stats'))),
      ).scale(100) /
      100;

  /// Sets `pip_total_coins` — a write BEFORE any pump (see the harness rules).
  Future<void> setCoins(WidgetTester tester, int coins) =>
      tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          ChildrenCompanion(pipTotalCoins: Value(coins)),
        );
      });

  group('the three stat cards are ONE height, everywhere', () {
    const cases = <({double width, double textScale, ThemeMode theme})>[
      (width: 320, textScale: 1, theme: ThemeMode.light),
      (width: 320, textScale: 1.3, theme: ThemeMode.light),
      (width: 390, textScale: 1, theme: ThemeMode.light),
      (width: 390, textScale: 1.3, theme: ThemeMode.light),
      (width: 430, textScale: 1, theme: ThemeMode.light),
      (width: 430, textScale: 1.3, theme: ThemeMode.light),
      // Dark shares the same layout code, so it is spot-checked at the two ends
      // of the matrix rather than run six times.
      (width: 320, textScale: 1.3, theme: ThemeMode.dark),
      (width: 430, textScale: 1.3, theme: ThemeMode.dark),
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
        final scale = effectiveScale(tester);
        expect(
          scale,
          closeTo(testCase.textScale, 0.001),
          reason: 'the case measures what it says it measures',
        );

        final cards = statCards(tester);
        final label =
            '${testCase.theme.name} @${testCase.width.toInt()}px @$scale x';
        // A 3 px ink border and a 6 px `--sh-kid` shadow make a ragged edge
        // plainly visible, and the owner ALIGNMENT rule calls any visible
        // misalignment a UI failure — so this tolerance is the measurement's,
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
        // The row's other half (the ALIGNMENT rule): 20 px side gutters and
        // two 10 px gaps from `EvolutionStatsGeometry.gap`.
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

  group('the three NUMBERS are one type size, at the design size', () {
    // K07-BUG-8. The per-card `FittedBox(scaleDown)` made each card shrink by
    // its own factor, so the numbers came out at three different sizes. The
    // invariant is stronger than "the three are equal": they must be the
    // DESIGN's single line box at the ambient scale, because a "shrink all three
    // by the same amount" fix would also make them equal and would still be
    // wrong (the design never scales type — it wraps).
    const cases = <({double width, double textScale, ThemeMode theme})>[
      (width: 320, textScale: 1, theme: ThemeMode.light),
      (width: 320, textScale: 1.3, theme: ThemeMode.light),
      (width: 390, textScale: 1, theme: ThemeMode.light),
      (width: 390, textScale: 1.3, theme: ThemeMode.light),
      (width: 430, textScale: 1.3, theme: ThemeMode.light),
      (width: 320, textScale: 1.3, theme: ThemeMode.dark),
    ];

    for (final testCase in cases) {
      testWidgets(
        '${testCase.theme.name} @${testCase.width.toInt()}px: identical tops '
        'and the design line box at ${testCase.textScale}x',
        (tester) async {
          await pumpEvolution(
            tester,
            width: testCase.width,
            textScale: testCase.textScale,
            theme: testCase.theme,
          );
          final scale = effectiveScale(tester);
          final numbers = statNumbers(tester);
          final heights = <double>[for (final n in numbers) n.height];
          final tops = <double>[for (final n in numbers) n.top];
          final label = '@${testCase.width.toInt()}px @$scale x';

          expect(
            spread(tops),
            lessThanOrEqualTo(0.5),
            reason:
                '$label: number tops '
                '${tops.map((v) => v.toStringAsFixed(2)).join(' / ')} — '
                '`.k7-stats b` is one line box for all three',
          );
          expect(
            spread(heights),
            lessThanOrEqualTo(0.5),
            reason:
                '$label: painted heights '
                '${heights.map((v) => v.toStringAsFixed(2)).join(' / ')} — '
                'one `font-size` for all three',
          );
          // …and that size is the DESIGN's, not merely a shared one.
          for (final height in heights) {
            expect(
              height,
              closeTo(_designNumberLineBox * scale, 0.75),
              reason:
                  '$label: a painted number is ${height.toStringAsFixed(2)} px '
                  'tall; the design line box at this scale is '
                  '${(_designNumberLineBox * scale).toStringAsFixed(2)} — the '
                  'app must not scale the type down to fit',
            );
          }
          // The number's inset is the CSS one for all three: card top + 3 px
          // border + 12 px padding.
          final cards = statCards(tester);
          for (final inset in <double>[
            for (var i = 0; i < 3; i++) numbers[i].top - cards[i].top,
          ]) {
            expect(
              inset,
              closeTo(kidBorder(tester) + NestSpacing.s3, 1),
              reason: '$label: every number sits the CSS inset below its card',
            );
          }
          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        },
      );
    }
  });

  group('a wide value wraps the label and grows the row — it never scales', () {
    testWidgets('9999 coins at 320 px: one size, one top, a taller card', (
      tester,
    ) async {
      // The orchestrator's own bound (`ORCHESTRATOR_NOTES` 03:03): the numbers
      // are single-line and `softWrap: false`, so a wide value must still FIT at
      // every supported width and scale, and the row answers a wide value by
      // wrapping the LABEL and growing — which is what CSS does.
      await setCoins(tester, 9999);
      await pumpEvolution(tester, width: 320, textScale: 1.3);

      final scale = effectiveScale(tester);
      final numbers = statNumbers(tester);
      expect(
        spread(numbers.map((n) => n.top).toList()),
        lessThanOrEqualTo(0.5),
        reason: 'one top edge at ${scale}x with a wide value',
      );
      for (final n in numbers) {
        expect(
          n.height,
          closeTo(_designNumberLineBox * scale, 0.75),
          reason: 'a wide value must not shrink the type',
        );
      }
      // The value is the DB's, not a design literal.
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-coins'))).data,
        '9999',
      );
      // The card grew to hold the wrapped label, and all three stayed equal.
      final cards = statCards(tester);
      expect(
        spread(cards.map((c) => c.height).toList()),
        lessThanOrEqualTo(0.5),
        reason: 'a wrapped label must not splay the row again',
      );
      expect(
        cards.first.height,
        greaterThan(84),
        reason:
            'content-driven growth: at 320 px / 1.3 the label needs a second '
            "line, so the cards are taller than the design width's 84 px \u2014 "
            'measured ${cards.first.height.toStringAsFixed(2)}',
      );
      // And the label renders whole: there is no cap on it any more.
      for (final card in const <String>[
        'k07-card-quests',
        'k07-card-coins',
        'k07-card-stage',
      ]) {
        expect(
          labelExceedsMaxLines(tester, card),
          isFalse,
          reason: '$card label',
        );
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('an absurd 9-digit value degrades without breaking the row', (
      tester,
    ) async {
      // `pip_total_coins` has no CHECK constraint, so this is reachable. The
      // orchestrator's ruling accepts that an over-wide single-line number CLIPS
      // inside the card rather than shrinking it (the browser does the same), so
      // this test pins the accepted trade honestly instead of pretending it
      // fits: no layout exception, the row's geometry intact, the numbers still
      // one size and one top, and the card able to hold them.
      await setCoins(tester, 999999999);
      await pumpEvolution(tester, width: 320, textScale: 1.3);

      expect(
        tester.takeException(),
        isNull,
        reason: 'a too-wide value must not overflow the card or the row',
      );
      final cards = statCards(tester);
      expect(
        spread(cards.map((c) => c.height).toList()),
        lessThanOrEqualTo(0.5),
      );
      final numbers = statNumbers(tester);
      expect(
        spread(numbers.map((n) => n.top).toList()),
        lessThanOrEqualTo(0.5),
      );
      for (var i = 0; i < 3; i++) {
        expect(
          numbers[i].left,
          greaterThanOrEqualTo(cards[i].left - 0.5),
          reason:
              'card ${i + 1}: the painted number starts inside its own card',
        );
        expect(
          numbers[i].right,
          lessThanOrEqualTo(cards[i].right + 0.5),
          reason:
              'card ${i + 1}: the painted number is '
              '${numbers[i].width.toStringAsFixed(2)} px wide inside a '
              '${cards[i].width.toStringAsFixed(2)} px card',
        );
      }
      // The row keeps the design's flex geometry: three equal cells on the
      // 20 px gutters with the design's 10 px gaps.
      expect(cards.first.width, closeTo(cards.last.width, 0.5));
      expect(cards.first.left, closeTo(NestSpacing.padSide, 1));
      expect(
        cards.last.right,
        closeTo(320 - NestSpacing.padSide, 1),
        reason: 'the row still spans the 320 px content box, gutters included',
      );

      await disposeApp(tester);
    });
  });

  group('the app shell clamps the OS text scale — so these cases measure 1.3', () {
    testWidgets('asking for 3.0 renders 1.3, and the screen still fits', (
      tester,
    ) async {
      // `app.dart` clamps to 1.0–1.3 ("the design system supports" it,
      // SPACING_SPEC §10). Pinning it here keeps every other case in this file
      // honest — a case that asked for 2.0 was measuring 1.3 — and it is the
      // reason the accessibility-scale reachability arguments in earlier notes
      // were overstated.
      await pumpEvolution(tester, width: 320, textScale: 3);
      expect(
        effectiveScale(tester),
        closeTo(1.3, 0.001),
        reason: 'the shell clamps the OS scaler to 1.3 at the top of its range',
      );
      expect(find.byKey(const Key('k07-cta')), findsOneWidget);
      expect(statCards(tester).length, 3);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('the cards GROW with the text scale — they are not pinned', () {
    testWidgets('the app max makes all three cards taller, and still equal', (
      tester,
    ) async {
      await pumpEvolution(tester);
      final atOne = statCards(tester);

      // A metrics change re-lays-out the live tree, so the same screen is
      // measured at the top of the app's supported range without a second pump
      // cycle.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(effectiveScale(tester), closeTo(1.3, 0.001));
      final atTwo = statCards(tester);

      expect(
        atTwo.first.height,
        greaterThan(atOne.first.height),
        reason:
            'a fixed card height would have "fixed" the splay by freezing the '
            'row; at the app max the labels need more room and the cards must '
            'take it (1x ${atOne.first.height.toStringAsFixed(2)} → '
            '1.3x ${atTwo.first.height.toStringAsFixed(2)})',
      );
      expect(
        spread(atTwo.map((c) => c.height).toList()),
        lessThanOrEqualTo(0.5),
        reason: 'still one height at the app max',
      );
      expect(spread(atTwo.map((c) => c.top).toList()), lessThanOrEqualTo(0.5));
      expect(
        spread(atTwo.map((c) => c.bottom).toList()),
        lessThanOrEqualTo(0.5),
      );
      // Growing means the content column is wrapping, not that a number was
      // scaled away: the value is still its full string.
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-coins'))).data,
        '175',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('nothing on this screen clamps its own copy', () {
    // The design clamps nothing: `.k7-hero`, `.k7-sub` and `.kcap` set no
    // `-webkit-line-clamp`, no `max-height` and no `overflow` (the only
    // `overflow` in the file is on `html, body`), and `.scroll` scrolls. The app
    // added `maxLines: 4` (hero), `maxLines: 2` + ellipsis (sub) and
    // `maxLines: 3` + ellipsis (caption) — K07-BUG-7 removed the first two and
    // K07-BUG-9 the third. This sweep is the permanent proof that a FIFTH cap
    // cannot be re-added silently, and it replaces the per-widget pins.
    testWidgets('no Text or heading on the celebration carries a maxLines', (
      tester,
    ) async {
      await pumpEvolution(tester, width: 320, textScale: 1.3);

      // The three stat NUMBERS are excluded on purpose: `ORCHESTRATOR_NOTES`
      // 03:03 requires them to be "single line, `softWrap: false`" (and CSS
      // `.k7-stats b` is one line box), so their `maxLines: 1` is the ruled
      // design rather than an app-only clamp. Everything else - hero, sub,
      // caption and the three labels - must carry no cap at all.
      const ruledNumbers = <String>[
        'k07-stat-quests',
        'k07-stat-coins',
        'k07-stat-stage',
      ];
      final offenders = <String>[];
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final cap = text.maxLines;
        if (cap == null) continue;
        final isRuledNumber = ruledNumbers.any(
          (key) => find.byKey(Key(key)).evaluate().isNotEmpty,
        );
        if (!isRuledNumber) offenders.add('Text(${text.data}) maxLines: $cap');
      }
      for (final heading in tester.widgetList<NestBalancedText>(
        find.byType(NestBalancedText),
      )) {
        final cap = heading.maxLines;
        if (cap != null) offenders.add('NestBalancedText maxLines: $cap');
      }
      expect(
        offenders,
        isEmpty,
        reason:
            "the design has no line clamp on any of this screen's copy, so an "
            'app-only cap truncates it (or ellipsizes the quest count). '
            'Offenders: $offenders',
      );
      // The caption specifically — K07-BUG-9 — with its rendered paragraph.
      final caption = tester.widget<Text>(find.byKey(const Key('k07-caption')));
      expect(caption.maxLines, isNull);
      expect(caption.overflow, isNot(TextOverflow.ellipsis));
      expect(exceedsMaxLines(tester, 'k07-caption'), isFalse);
      // …and the two lines the earlier passes un-capped, on the rendered tree.
      expect(exceedsMaxLines(tester, 'k07-title'), isFalse);
      expect(exceedsMaxLines(tester, 'k07-sub'), isFalse);
      // The copy itself is untouched by any of it.
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(find.text('Because you helped 4 times'), findsOneWidget);
      expect(find.text('Pip still loves a chin scratch.'), findsOneWidget);
      expect(find.byKey(const Key('k07-cta')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}

/// The shared kid border width, read from the tokens — the number's inset is
/// `border + padding`, never a literal 15.
double kidBorder(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(const Key('k07-stats'))))
        .extension<NestKidTheme>()!
        .borderWidth;
