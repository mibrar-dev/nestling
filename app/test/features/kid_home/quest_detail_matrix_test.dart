// K04 quest-detail render matrix: {light, dark} × {320, 390, 430} ×
// {1.0, 1.3} text scale — 12 pumps of the real seeded Drift database.
//
// Iteration 1 ran K04 light-only at 320/390, so dark mode and the 430 width had
// no coverage at all. Two owner rules are only observable across this matrix:
//
//   BOTTOM EDGE — the bar's surface must reach the physical screen edge in BOTH
//   modes. `design/screens/dark/K04-quest-detail.png` actually shows a meadow
//   strip under the dark bar; the owner rule overrides the designs, so the app
//   is asserted NOT to reproduce it. Proven structurally (the bar is the last
//   child of the body Column, so nothing can paint below it) as well as
//   geometrically (rect bottom == 844, full bleed width).
//
//   ALIGNMENT — 20 px side gutters hold at every width: the steps card and both
//   buttons share the same left/right edges, and the centred tile / pill /
//   cheer row re-centre on the new midpoint instead of drifting.
//
// Dark-mode colour assertions read the tokens from the theme extension rather
// than hard-coding hex, and additionally assert dark surface != light surface so
// a light-mode colour leaking into the dark theme cannot pass.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// The `.kid-bar` surface: the only Container with a top-only 3 px border
/// (cards and tiles border all four sides, so the shape identifies it).
Finder _barSurface() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final box = widget.decoration;
  if (box is! BoxDecoration) return false;
  final border = box.border;
  return border is Border && border.top.width == 3 && border.left.width == 0;
});

/// Radius-24 + shadowed Containers are the tile (120 wide) and the steps card
/// (≥ 200 wide); the bar has no radius and no shadow. Splitting on rendered
/// width is a shape-based match, so it works in both themes (the geometry test
/// hard-codes the light ink/surface hex and cannot be reused here).
Finder _radius24Shadowed() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final box = widget.decoration;
  if (box is! BoxDecoration) return false;
  final border = box.border;
  return box.borderRadius == BorderRadius.circular(24) &&
      box.boxShadow != null &&
      border is Border &&
      border.top.width > 0;
});

List<Rect> _radius24Rects(WidgetTester tester) {
  final finder = _radius24Shadowed();
  final rects = <Rect>[
    for (var i = 0; i < finder.evaluate().length; i++)
      tester.getRect(finder.at(i)),
  ]..sort((a, b) => a.width.compareTo(b.width));
  return rects;
}

/// The steps card: the wider of the two radius-24 shadowed boxes.
Rect _cardRect(WidgetTester tester) => _radius24Rects(tester).last;

/// The icon tile: the narrower one (120 px square).
Rect _tileRect(WidgetTester tester) => _radius24Rects(tester).first;

Container _cardWidget(WidgetTester tester) =>
    tester.widget<Container>(_radius24Shadowed().last);

/// The `.k4-dot` ring at [index] (40 px circle).
Finder _dot(int index) => find
    .byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final box = widget.decoration;
      return box is BoxDecoration &&
          box.shape == BoxShape.circle &&
          widget.constraints?.maxHeight == 40;
    })
    .at(index);

Color _dotFill(WidgetTester tester, int index) =>
    (tester.widget<Container>(_dot(index)).decoration! as BoxDecoration).color!;

NestTokens _tokens(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NestCoinPill)))
        .extension<NestTokens>()!;

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required ThemeMode mode,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(mode);
  await tester.pumpWidget(
    const NestlingApp(initialRoute: KidHomeRoutePaths.detail),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The body Column: status bar, top row, scrolling body, bar. Used to prove the
/// bar is LAST, so no coloured strip can exist under it.
Column _bodyColumn(WidgetTester tester) {
  final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
  return scaffold.body! as Column;
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  const widths = <double>[320, 390, 430];
  const scales = <double>[1, 1.3];
  const modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

  group('K04 render matrix — no overflow, copy intact, gutters aligned', () {
    for (final mode in modes) {
      for (final width in widths) {
        for (final scale in scales) {
          final label =
              '${mode.name} ${width.toInt()}px @ ${scale.toStringAsFixed(1)}x';
          testWidgets(label, (tester) async {
            await _pump(tester, width: width, textScale: scale, mode: mode);

            expect(
              tester.takeException(),
              isNull,
              reason: '$label must not overflow or throw',
            );
            expect(find.text('Tidy your bedroom'), findsOneWidget);
            expect(find.text('Clothes in the basket'), findsOneWidget);
            expect(find.text('Books on the shelf'), findsOneWidget);
            expect(find.text('I did it!'), findsOneWidget);

            // ALIGNMENT: the card and both buttons share the 20 px gutters.
            final card = _cardRect(tester);
            expect(card.left, NestSpacing.padSide, reason: '$label card left');
            expect(
              card.right,
              width - NestSpacing.padSide,
              reason: '$label card right',
            );

            final buttons = find.byType(NestKidButton);
            expect(buttons, findsNWidgets(2));
            for (var i = 0; i < 2; i++) {
              final rect = tester.getRect(buttons.at(i));
              expect(
                rect.left,
                NestSpacing.padSide,
                reason: '$label button $i',
              );
              expect(
                rect.right,
                width - NestSpacing.padSide,
                reason: '$label button $i',
              );
            }

            // Centred elements re-centre on the new midpoint.
            expect(
              _tileRect(tester).center.dx,
              closeTo(width / 2, 0.5),
              reason: '$label tile centred',
            );
            expect(
              tester.getRect(find.byType(NestCoinPill)).center.dx,
              closeTo(width / 2, 0.5),
              reason: '$label pill centred',
            );
            // The CHEER ROW (Pip + gap + bubble) is centred, not the bubble
            // itself: the design puts the 64 px Pip left of a 240 px bubble, so
            // the bubble's own centre sits right of the midpoint (233 at 390 —
            // matching `bubble x 113…353`). Measure the row's outer edges.
            //
            // At 1.3x the checklist pushes the cheer row below the fold, so it
            // is not built until scrolled to — which is also the proof that the
            // screen stays usable at large text instead of overflowing.
            await tester.drag(find.byType(ListView), const Offset(0, -600));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            expect(
              tester.takeException(),
              isNull,
              reason: '$label must not overflow once scrolled either',
            );
            final pip = tester.getRect(find.byType(PipAvatar));
            final bubble = tester.getRect(find.byType(NestSpeechBubble));
            expect(
              (pip.left + bubble.right) / 2,
              closeTo(width / 2, 0.5),
              reason: '$label cheer row centred',
            );
            expect(
              bubble.left - pip.right,
              NestSpacing.s3,
              reason: '$label: `.k4-cheer` gap is 12',
            );

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group('K04 bottom edge — the bar surface reaches the physical edge', () {
    for (final mode in modes) {
      testWidgets('${mode.name}: full bleed to 844, nothing painted below', (
        tester,
      ) async {
        await _pump(tester, width: 390, textScale: 1, mode: mode);

        final bar = tester.getRect(_barSurface());
        expect(bar.left, 0);
        expect(bar.right, 390);
        expect(
          bar.bottom,
          844,
          reason: 'the surface box runs to the physical bottom edge',
        );

        // Structural proof: the bar is the body Column's last child, so no
        // meadow, sky or page tint can show under it or around the home pill.
        final column = _bodyColumn(tester);
        expect(
          column.children.last,
          same(tester.widget(_barSurface())),
          reason: 'the bar must be the last thing painted',
        );

        // And the bar is filled with the THEME's surface token.
        final box =
            tester.widget<Container>(_barSurface()).decoration!
                as BoxDecoration;
        final tokens = _tokens(tester);
        expect(box.color, tokens.surface);
        expect(box.border, isA<Border>());
        expect((box.border! as Border).top.width, 3);

        await disposeApp(tester);
      });
    }

    testWidgets('dark surface is genuinely dark, not a light-mode leak', (
      tester,
    ) async {
      // Pinned hexes from `tokens/colors.dart`. Asserting the pair catches both
      // a hard-coded light colour and a swapped theme.
      const darkSurface = Color(0xFF1F1C2E);
      const lightSurface = Color(0xFFFFFFFF);
      await _pump(tester, width: 390, textScale: 1, mode: ThemeMode.dark);
      expect(_tokens(tester).surface, darkSurface);
      final box =
          tester.widget<Container>(_barSurface()).decoration! as BoxDecoration;
      expect(box.color, darkSurface);
      expect(
        (_cardWidget(tester).decoration! as BoxDecoration).color,
        darkSurface,
        reason: 'the steps card shares the dark surface',
      );
      expect(darkSurface, isNot(lightSurface));
      await disposeApp(tester);
    });

    testWidgets('light surface is white, and differs from dark', (
      tester,
    ) async {
      const lightSurface = Color(0xFFFFFFFF);
      const darkSurface = Color(0xFF1F1C2E);
      await _pump(tester, width: 390, textScale: 1, mode: ThemeMode.light);
      expect(_tokens(tester).surface, lightSurface);
      final box =
          tester.widget<Container>(_barSurface()).decoration! as BoxDecoration;
      expect(box.color, lightSurface);
      expect(lightSurface, isNot(darkSurface));
      await disposeApp(tester);
    });
  });

  group('K04 in dark — the taps still go where they go', () {
    testWidgets('I did it! celebrates from dark', (tester) async {
      await _pump(tester, width: 390, textScale: 1, mode: ThemeMode.dark);
      await tester.tap(find.text('I did it!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The real repository flips q-tidy, so the celebration pushes K05.
      expect(pushedPath(tester), KidHomeRoutePaths.complete);
      await disposeApp(tester);
    });

    testWidgets('a step still toggles from dark', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, width: 390, textScale: 1, mode: ThemeMode.dark);
      final leaf = _tokens(tester).leaf;
      final surface = _tokens(tester).surface;
      final before = tester
          .getSemantics(find.bySemanticsLabel('Books on the shelf, not ticked'))
          .getSemanticsData();
      expect(before.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.text('Books on the shelf'));
      await tester.pump();
      expect(
        find.bySemanticsLabel('Books on the shelf, ticked'),
        findsOneWidget,
      );
      // The dot switched to the DARK theme's leaf token (not the light one).
      expect(_dotFill(tester, 2), leaf);
      expect(leaf, isNot(surface));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the bottom Back leaves the screen from dark', (tester) async {
      await _pump(tester, width: 390, textScale: 1, mode: ThemeMode.dark);
      await tester.tap(find.text('Back').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });
  });
}
