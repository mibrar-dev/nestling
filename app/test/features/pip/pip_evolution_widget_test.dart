// K07 pixel-geometry pins, measured against `design/screens/light/K07-evolution.png`
// (390x844 @1x; the PNG is 3x, so every number below was read in CSS px).
//
// The numbers come from the design PNG's own ink runs:
//
//   lock box       x 313..370, y 46..102        (.lock-btn.lg, right, 56)
//   stage slot     y 105..355                    (.k7-stage, 250)
//   title line     y 371..405 (34)              (.kid-title 28/34)
//   sub            y 421..447 (26)               (.kid-body 18/26)
//   speech bubble  y 463..529 (66 = 2 lines)     (.speech; borders 463..465/526..528)
//   stat cards     y 545..629 (84), x 20..130 / 140..250 / 260..370
//   bar top border y 721..724                    (.kid-bar)
//   CTA            y 736..800, x 20..370         (.btn-kid.lilac, 64)
//   home pill      y 825..830                    (.home-indicator, 34 block)
//
// Everything measured on the design is pinned within a small tolerance; the
// DB-driven text inside the pinned boxes (the stage word, the numbers) is not
// asserted — the UI VERDICT RULE exempts DB content from the pixel comparison.
//
// Two things every row here depends on, both established in this suite
// (`quest_library_design_geometry_test.dart`):
//
//   * the bundled Inter/Nunito faces are loaded through `FontLoader`, because
//     the default widget-test font gives every glyph the same advance — the
//     hero heading wraps to three lines and every row below it drifts ~68 px;
//   * the device insets are faked (47 top / 34 bottom), because the bar's
//     `SafeArea` reserve only exists on a real phone (with zero insets the
//     bar is 89 tall and its top lands on y 755 instead of the design's 721).
//
// The design-pinned rows run at Pip STAGE 4, the stage the PNG was drawn at
// ("Pip grew into a Songbird!", line 55). That matters: at real Nunito Black
// 28 px the stage-4 title measures 346.3 px and the stage-3 one ("Fledgling")
// 351.7 px against a 350 px content box — so the demo child's heading wraps to
// two lines, exactly as the browser would for the same string, and every row
// below it moves by one 34 px line. `1_plan.md`'s vertical map is a stage-4
// map, so it is pinned at stage 4 and the stage-3 shift is pinned separately
// (no silent drift is left to the UI stage).

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_background.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_stage.dart';

import '../../test_scope.dart';

/// The bundled faces, loaded into the test font manager (see the header).
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

/// Design vs app, in CSS px. A design value plus the ±2 px the UI VERDICT
/// RULE allows.
void expectRect(
  Rect actual,
  double designLeft,
  double designTop,
  double designWidth,
  double designHeight, {
  String? what,
  double tolerance = 2,
}) {
  final label = what == null ? '' : '$what: ';
  expect(actual.left, closeTo(designLeft, tolerance), reason: '${label}left');
  expect(actual.top, closeTo(designTop, tolerance), reason: '${label}top');
  expect(
    actual.width,
    closeTo(designWidth, tolerance),
    reason: '${label}width',
  );
  expect(
    actual.height,
    closeTo(designHeight, tolerance),
    reason: '${label}height',
  );
}

/// The stage the K07 PNGs were drawn at (`Pip grew into a Songbird!`,
/// `1_plan.md` §(a).11's vertical map). See the header note on why the
/// design-pinned rows run at this stage and not the demo's stage 3.
const int _designStage = 4;

void main() {
  late AppDatabase db;

  setUp(() async {
    await loadK07Fonts();
    db = await setUpTestScope();
  });

  Future<void> pumpEvolution(
    WidgetTester tester, {
    double width = NestDevice.width,
    double textScale = 1,
    ThemeMode theme = ThemeMode.light,
    bool deviceInsets = true,
    int? stage,
  }) async {
    if (stage != null) {
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          ChildrenCompanion(pipStage: Value(stage)),
        );
      });
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    GetIt.instance<ThemeModeController>().selectMode(theme);
    await pumpAppRoute(tester, '/pip-evolution', theme: theme);
    // `pumpAppRoute` pins 390x844 ITSELF, so a surface set before the pump is
    // overwritten; apply it after and assert it really took (K06's fix).
    tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
    tester.view.devicePixelRatio = 3;
    if (deviceInsets) {
      // The designs reserve `--status-h` 47 and `--home-h` 34; the bar's
      // `SafeArea` only sees them on a real device.
      const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
    }
    addTearDown(tester.view.reset);
    // Wait for the loaded screen instead of trusting a fixed fake-clock delay:
    // the data arrives over real Drift streams, and on a loaded machine 400 ms
    // of fake time can pass before the query answers (K06's comment on
    // `_settle` applies). Bounded to ~3 s of real time.
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
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
      width,
      reason: 'this test must really run at $width logical px',
    );
    expect(
      find.byKey(const Key('k07-cta')),
      findsOneWidget,
      reason: 'the screen must have finished loading',
    );
  }

  Rect rectOf(WidgetTester tester, String key) =>
      tester.getRect(find.byKey(Key(key)));

  group('design geometry at 390x844', () {
    testWidgets('the lock is a 56 px target on the 20 px right gutter', (
      tester,
    ) async {
      await pumpEvolution(tester, stage: _designStage);

      expectRect(
        rectOf(tester, 'k07-lock'),
        390 - NestSpacing.padSide - NestDevice.tapKid,
        NestDevice.statusH,
        NestDevice.tapKid,
        NestDevice.tapKid,
        what: '.lock-btn.lg',
      );
      await disposeApp(tester);
    });

    testWidgets('the stage slot is 250 tall directly under the top row', (
      tester,
    ) async {
      await pumpEvolution(tester, stage: _designStage);

      // `.k7-top` = lock 56 + 2 px bottom padding, so the slot starts at 105.
      expectRect(
        rectOf(tester, 'k07-stage'),
        NestSpacing.padSide,
        NestDevice.statusH + NestDevice.tapKid + NestSpacing.gap2,
        NestDevice.width - NestSpacing.padSide * 2,
        EvolutionStageGeometry.slotHeight,
        what: '.k7-stage',
      );

      // The three slots inside it, at the design's offsets from the slot.
      final slot = rectOf(tester, 'k07-stage');
      expectRect(
        rectOf(tester, 'k07-old-pip'),
        slot.left + EvolutionStageGeometry.oldLeft,
        slot.bottom -
            EvolutionStageGeometry.oldBottom -
            EvolutionStageGeometry.oldSize,
        EvolutionStageGeometry.oldSize,
        EvolutionStageGeometry.oldSize,
        what: '.k7-old',
      );
      final arrow = rectOf(tester, 'k07-arrow');
      expect(
        arrow.left,
        closeTo(slot.left + EvolutionStageGeometry.arrowLeft, 2),
      );
      expect(
        arrow.bottom,
        closeTo(slot.bottom - EvolutionStageGeometry.arrowBottom, 2),
        reason: '.k7-arrow bottom: 24px',
      );
      expectRect(
        rectOf(tester, 'k07-new-pip'),
        slot.right -
            EvolutionStageGeometry.newRight -
            EvolutionStageGeometry.newSize,
        slot.bottom - EvolutionStageGeometry.newSize,
        EvolutionStageGeometry.newSize,
        EvolutionStageGeometry.newSize,
        what: '.k7-new',
      );
      await disposeApp(tester);
    });

    testWidgets('the heading, sub, speech, stats and caption follow the CSS', (
      tester,
    ) async {
      await pumpEvolution(tester, stage: _designStage);

      // 105 + 250 (stage) = 355, then `.scroll > * + *` = 16 before each.
      expect(
        rectOf(tester, 'k07-title').top,
        closeTo(371, 2),
        reason: '.k7-hero line box (28/34)',
      );
      expect(rectOf(tester, 'k07-sub').top, closeTo(421, 2), reason: '.k7-sub');
      expect(
        rectOf(tester, 'k07-speech').top,
        closeTo(463, 2),
        reason: '.speech top border',
      );
      expect(
        rectOf(tester, 'k07-stats').top,
        closeTo(545, 2),
        reason: '.k7-stats top border',
      );
      expect(
        rectOf(tester, 'k07-caption').top,
        closeTo(645, 2),
        reason: '.kcap',
      );
      await disposeApp(tester);
    });

    testWidgets('the three stat cards are 110 wide with 10 px gaps', (
      tester,
    ) async {
      await pumpEvolution(tester, stage: _designStage);

      final row = rectOf(tester, 'k07-stats');
      // `.k7-stats` fills the scroll's content box: 390 - 2*20 = 350.
      expect(row.width, closeTo(350, 2));
      // The CARDS (painted background/border rects), not the number inside.
      final first = rectOf(tester, 'k07-card-quests');
      final second = rectOf(tester, 'k07-card-coins');
      final third = rectOf(tester, 'k07-card-stage');
      expect(first.left, closeTo(20, 2));
      expect(first.width, closeTo(110, 2));
      expect(second.left, closeTo(140, 2));
      expect(third.left, closeTo(260, 2));
      expect(third.right, closeTo(370, 2));
      // 3 + 12 + 34 + 2 + 18 + 12 + 3.
      expect(first.height, closeTo(84, 2));
      expect(first.top, closeTo(545, 2));
      await disposeApp(tester);
    });

    testWidgets(
      'the three stat NUMBERS share one top edge and one type size at 390 and '
      '320 px, scale 1.0 and 1.3, up to 9999 coins (ORCHESTRATOR_NOTES 03:03)',
      (tester) async {
        // The design sets ONE `font-size` for all three `.k7-stats b` and
        // scales nothing, so the numbers must not shrink per card even when a
        // cell is narrower than its content. This is the orchestrator's own
        // assertion: equal `getTopLeft().dy`. `pumpEvolution` runs through the
        // app shell, so the 1.3 here is the clamped value the device renders.
        for (final width in const <double>[390, 320]) {
          for (final scale in const <double>[1, 1.3]) {
            await tester.runAsync(() async {
              await (db.update(db.children)..where((c) => c.id.equals('maya')))
                  .write(const ChildrenCompanion(pipTotalCoins: Value(9999)));
            });
            await pumpEvolution(
              tester,
              stage: _designStage,
              width: width,
              textScale: scale,
            );

            double spread(List<double> values) {
              final sorted = <double>[...values]..sort();
              return sorted.last - sorted.first;
            }

            final rects = <Rect>[
              for (final cell in const <String>[
                'k07-card-quests',
                'k07-card-coins',
                'k07-card-stage',
              ])
                tester.getRect(
                  find
                      .descendant(
                        of: find.byKey(Key(cell)),
                        matching: find.byType(RichText),
                      )
                      .first,
                ),
            ];
            final tops = <double>[for (final r in rects) r.top];
            final heights = <double>[for (final r in rects) r.height];
            final label = '@${width.toInt()}px / ${scale}x';
            expect(
              spread(tops),
              lessThanOrEqualTo(0.5),
              reason:
                  '$label: number tops '
                  '${tops.map((v) => v.toStringAsFixed(2)).join(' / ')} — the '
                  'design has a single line box for all three',
            );
            expect(
              spread(heights),
              lessThanOrEqualTo(0.5),
              reason:
                  '$label: painted number heights '
                  '${heights.map((v) => v.toStringAsFixed(2)).join(' / ')} — '
                  'one `font-size` for all three, as the design sets',
            );
            await disposeApp(tester);
          }
        }
      },
    );

    testWidgets('the bottom bar reaches the physical edge with the CTA on it', (
      tester,
    ) async {
      await pumpEvolution(tester, stage: _designStage);

      final bar = rectOf(tester, 'k07-bar');
      final cta = rectOf(tester, 'k07-cta');
      // Owner bottom-edge rule: the bar's own surface runs to the screen
      // bottom — no glow strip under it, around the home indicator included.
      expect(bar.left, 0);
      expect(bar.right, NestDevice.width);
      expect(bar.bottom, closeTo(NestDevice.height, 0.5));
      // The design's ink run for the bar's 3 px top border is y 721..724.
      expect(bar.top, closeTo(721, 2), reason: '.kid-bar top border');
      // The CTA: y 736..800, x 20..370. The keyed widget is the shared
      // NestKidButton, whose box carries the 6 px `--sh-kid` shadow room under
      // the painted 64 px card (SPACING_SPEC 10.6), so the painted height is
      // 64 and the widget box 70.
      expect(cta.top, closeTo(736, 2), reason: '.btn-kid.lilac top');
      expect(cta.left, closeTo(NestSpacing.padSide, 2));
      expect(cta.right, closeTo(NestDevice.width - NestSpacing.padSide, 2));
      expect(
        cta.height - NestSpacing.gap6,
        closeTo(64, 0.5),
        reason: 'the painted CTA card is 64 tall',
      );
      await disposeApp(tester);
    });

    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '${theme.name}: the bar’s own surface reaches the edge in both themes',
        (tester) async {
          await pumpEvolution(tester, stage: _designStage, theme: theme);

          final tokens = Theme.of(
            tester.element(find.byKey(const Key('k07-bar'))),
          ).extension<NestTokens>()!;
          // The bar is painted with the SURFACE token — not the page tint, not
          // the glow. This is the owner BOTTOM EDGE rule: the area below the
          // bar, down to the physical edge and around the home indicator, must
          // be the same colour as the bar itself.
          final decoration =
              tester
                      .widget<Container>(find.byKey(const Key('k07-bar')))
                      .decoration!
                  as BoxDecoration;
          expect(decoration.color, tokens.surface);
          // …and no other layer paints below it.
          final bar = rectOf(tester, 'k07-bar');
          expect(bar.bottom, closeTo(NestDevice.height, 0.5));
          expect(
            find.descendant(
              of: find.byType(PipEvolutionGlow),
              matching: find.byKey(const Key('k07-bar')),
            ),
            findsNothing,
            reason: 'the bar sits above the glow, not inside it',
          );
          // The same geometry in dark: 3 + 12 + 64 + 6 + 4 + 34 = 123 tall.
          expect(bar.top, closeTo(721, 2), reason: '.kid-bar top border');
          expect(bar.height, closeTo(123, 1));
          await disposeApp(tester);
        },
      );
    }

    testWidgets('the sparks sit at top: 92 in a 350x250 box', (tester) async {
      await pumpEvolution(tester, stage: _designStage);

      final sparks = tester.getRect(find.byType(PipEvolutionSparks));
      expect(sparks.top, closeTo(EvolutionSparksGeometry.topFromScreen, 2));
      expect(sparks.height, EvolutionSparksGeometry.boxHeight);
      expect(sparks.width, EvolutionSparksGeometry.boxWidth);
      // Centred horizontally: (390 - 350) / 2 = 20.
      expect(sparks.left, closeTo(20, 0.5));
      // The art itself is the viewBox: 350x220 letterboxed 15 px in the box.
      expect(
        sparks.center.dy - EvolutionSparksGeometry.artSize.height / 2,
        closeTo(92 + 15, 2),
      );
      await disposeApp(tester);
    });

    testWidgets('the demo stage 3 wraps the hero by exactly one 34 px line', (
      tester,
    ) async {
      // Stage 4 first (the design's one-line heading), then the seeded stage 3.
      await pumpEvolution(tester, stage: _designStage);
      final designTitle = rectOf(tester, 'k07-title');
      expect(designTitle.height, closeTo(34, 1), reason: 'one line');
      expect(designTitle.top, closeTo(371, 2));
      await disposeApp(tester);

      await pumpEvolution(tester, stage: 3);
      final demoTitle = rectOf(tester, 'k07-title');
      // "Pip grew into a Fledgling!" is 351.7 px at real Nunito Black 28 px
      // against a 350 px content box, so — exactly like the browser with the
      // same string — it takes two lines, and every row below moves down one
      // line. The stage slot and the bar are untouched (the scroll absorbs it).
      expect(demoTitle.height, closeTo(68, 1), reason: 'two lines');
      expect(demoTitle.top, closeTo(371, 2), reason: 'same start');
      expect(
        rectOf(tester, 'k07-sub').top,
        closeTo(455, 2),
        reason: '371 + 68 + 16',
      );
      expect(
        rectOf(tester, 'k07-stats').top,
        closeTo(545 + 34, 2),
        reason: 'one 34 px line lower than the design PNG',
      );
      // The bottom bar is fixed: only the scrolling content moved.
      expect(rectOf(tester, 'k07-bar').top, closeTo(721, 2));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('fit matrix', () {
    // Every width the brief names (320 / 390 / 430) at BOTH text scales, in
    // BOTH themes: 12 combinations, each asserting no overflow/clipping fault
    // and a CTA that still works.
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in <double>[320, 390, 430]) {
        for (final textScale in <double>[1, 1.3]) {
          testWidgets('${theme.name} @${width.toInt()}px, text scale '
              '${textScale.toStringAsFixed(1)}: no overflow', (tester) async {
            await pumpEvolution(
              tester,
              width: width,
              textScale: textScale,
              theme: theme,
            );

            expect(find.byKey(const Key('k07-title')), findsOneWidget);
            expect(find.byKey(const Key('k07-cta')), findsOneWidget);
            // The whole celebration is present, not clipped away.
            expect(find.byKey(const Key('k07-stage')), findsOneWidget);
            expect(find.byKey(const Key('k07-stats')), findsOneWidget);
            expect(find.byKey(const Key('k07-caption')), findsOneWidget);
            expect(tester.takeException(), isNull);

            // The 20 px gutters hold at every width (ALIGNMENT rule).
            final cta = rectOf(tester, 'k07-cta');
            expect(
              cta.left,
              closeTo(NestSpacing.padSide, 1),
              reason: 'CTA gutter @${width.toInt()}',
            );
            expect(
              cta.right,
              closeTo(width - NestSpacing.padSide, 1),
              reason: 'CTA right gutter @${width.toInt()}',
            );
            final row = rectOf(tester, 'k07-stats');
            expect(row.left, closeTo(NestSpacing.padSide, 1));
            expect(row.right, closeTo(width - NestSpacing.padSide, 1));
            // The lock keeps the same right gutter.
            expect(
              rectOf(tester, 'k07-lock').right,
              closeTo(width - NestSpacing.padSide, 1),
            );
            // The bar still runs to the physical edge (owner rule).
            expect(
              rectOf(tester, 'k07-bar').bottom,
              closeTo(NestDevice.height, 0.5),
            );

            // The CTA still works at the narrowest width and the largest
            // text scale.
            await tester.tap(find.byKey(const Key('k07-cta')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            expect(currentPath(tester), '/pip');

            await disposeApp(tester);
          });
        }
      }
    }

    testWidgets(
      'a 320 px stage-1 child still shows one centred Pip, no overflow',
      (tester) async {
        // The degenerate slot (no old Pip, no arrow) at the tightest width.
        await tester.runAsync(() async {
          await (db.update(db.children)..where((c) => c.id.equals('maya')))
              .write(const ChildrenCompanion(pipStage: Value(1)));
        });
        await pumpEvolution(
          tester,
          width: 320,
          textScale: 1.3,
          theme: ThemeMode.dark,
        );

        expect(find.byKey(const Key('k07-new-pip')), findsOneWidget);
        expect(find.byKey(const Key('k07-old-pip')), findsNothing);
        expect(find.text('Pip grew into an Egg!'), findsOneWidget);
        // The 240 px Pip is centred in the 280 px content box.
        final slot = rectOf(tester, 'k07-stage');
        final pip = rectOf(tester, 'k07-new-pip');
        expect(
          pip.center.dx - slot.center.dx,
          closeTo(0, 1),
          reason: 'the single Pip must be centred, not right-aligned',
        );
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  });

  group('the glow geometry', () {
    testWidgets('the glow layer fills the screen over the surface colour', (
      tester,
    ) async {
      await pumpEvolution(tester);

      final glow = find.byType(PipEvolutionGlow);
      expect(glow, findsOneWidget);
      // The CSS percentages resolve against the box it fills, so the painter's
      // box must be the whole screen (never a hard-coded 390x844).
      expect(
        tester.getRect(glow).size,
        const Size(NestDevice.width, NestDevice.height),
      );
      // `background-color: var(--surface)` under the gradient.
      final box = tester.widget<ColoredBox>(
        find.descendant(of: glow, matching: find.byType(ColoredBox)),
      );
      final tokens = Theme.of(tester.element(glow)).extension<NestTokens>()!;
      expect(box.color, tokens.surface);

      await disposeApp(tester);
    });
  });

  testWidgets("a stage-4 child shows the design's own copy", (tester) async {
    await tester.runAsync(() async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(pipStage: Value(4)),
      );
    });
    await pumpEvolution(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Stage 4 has no stage 5, but the old slot is still stage 3 -> it stays.
    expect(find.byKey(const Key('k07-old-pip')), findsOneWidget);
    expect(find.text('Meet Songbird Pip'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });
}
