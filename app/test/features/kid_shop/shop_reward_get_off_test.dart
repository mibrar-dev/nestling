// K08 · Reward shop — the `.k8-get.off` "Save up!" colourway
// (stage 3, iteration 3).
//
// `SHARED_REQUEST.md` §1 asked the design-system owner for the disabled
// colourway the CSS already specifies:
//   .k8-get.off { background: var(--surface-2); color: var(--ink-2) }
// i.e. the SAME 3 px ink border, `--sh-kid` shadow and 17 px w900 label as the
// on-state button, but the greyed pair at FULL opacity — not the 0.45 wash the
// shared button paints for any other disabled colourway. `shared_batch8` added
// `NestKidButtonColor.muted` and K08 uses it.
//
// This file pins what that means for the screen, in BOTH themes, because a
// colourway that is only right in light mode is a defect:
//   * the painted fill is `surface-2` and the label is `ink-2`;
//   * the control is at full opacity (no 0.45 disabled wash);
//   * the box is unchanged: 56 tall painted, radius 16, 3 px ink border,
//     `--sh-kid` shadow — a colour swap must not move anything;
//   * it is still DISABLED: `enabled: false` and no tap action;
//   * the affordable cards keep the `leaf` pair at full opacity, so the two
//     states are told apart by colour, not by a wash.
//
// Run directly:
//   flutter test --timeout 120s test/features/kid_shop/shop_reward_get_off_test.dart

import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// The card the demo seed leaves out of reach: the 150-coin park café.
const int _cafeCard = 4;

Finder _cardButton(int index) => find.descendant(
  of: find.byType(ShopRewardCard).at(index),
  matching: find.byType(NestKidButton),
);

/// The painted button box inside [NestKidButton] — the `AnimatedContainer`
/// that carries `.k8-get`'s fill, border, radius and shadow.
Finder _painted(int index) => find
    .descendant(
      of: _cardButton(index),
      matching: find.byType(AnimatedContainer),
    )
    .last;

/// The whole control's opacity wrapper (`NestKidButton` paints 0.45 over any
/// disabled colourway except `muted`).
Finder _opacity(int index) =>
    find.descendant(of: _cardButton(index), matching: find.byType(Opacity));

BoxDecoration _decoration(WidgetTester tester, int index) =>
    tester.widget<AnimatedContainer>(_painted(index)).decoration!
        as BoxDecoration;

Future<void> _pump(WidgetTester tester, ThemeMode theme) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    group('.k8-get.off in ${theme.name}', () {
      setUp(() async {
        await setUpTestScope();
        GetIt.instance<ThemeModeController>().selectMode(theme);
      });

      testWidgets('paints surface-2 with an ink-2 label at full opacity', (
        tester,
      ) async {
        await _pump(tester, theme);
        final tokens = _tokens(tester);
        expect(tester.takeException(), isNull);

        final decoration = _decoration(tester, _cafeCard);
        expect(
          decoration.color,
          tokens.surface2,
          reason: '.k8-get.off background is --surface-2',
        );
        expect(
          tester.widget<Opacity>(_opacity(_cafeCard)).opacity,
          1,
          reason: 'the grey pair IS the disabled look; no 0.45 wash on top',
        );

        final label = tester.widget<Text>(
          find.descendant(
            of: _cardButton(_cafeCard),
            matching: find.text('Save up!'),
          ),
        );
        expect(
          label.style?.color,
          tokens.ink2,
          reason: '.k8-get.off color is --ink-2',
        );
        await disposeApp(tester);
      });

      testWidgets('the affordable cards stay leaf at full opacity', (
        tester,
      ) async {
        await _pump(tester, theme);
        final tokens = _tokens(tester);

        for (final index in <int>[0, 1, 2, 3, 5]) {
          expect(
            _decoration(tester, index).color,
            tokens.leaf,
            reason: 'card $index Get it background is --leaf',
          );
          expect(
            tester.widget<Opacity>(_opacity(index)).opacity,
            1,
            reason: 'card $index is enabled, so no wash',
          );
          final label = tester.widget<Text>(
            find.descendant(
              of: _cardButton(index),
              matching: find.text('Get it'),
            ),
          );
          expect(label.style?.color, tokens.onLeaf);
        }
        await disposeApp(tester);
      });

      testWidgets('the box is untouched: 56 tall, radius 16, 3 px ink border', (
        tester,
      ) async {
        await _pump(tester, theme);
        final tokens = _tokens(tester);

        // 62-tall widget box: 56 painted + 6 px of `--sh-kid` shadow room.
        expect(tester.getRect(_cardButton(_cafeCard)).height, closeTo(62, 2));
        final decoration = _decoration(tester, _cafeCard);
        expect(
          (decoration.border! as Border).top.width,
          3,
          reason: 'the kid border width',
        );
        expect(
          (decoration.border! as Border).top.color,
          tokens.ink,
          reason: 'the border stays ink on the off state too',
        );
        expect(
          decoration.borderRadius,
          BorderRadius.circular(NestRadii.m),
          reason: '.k8-get radius is --r-m (16)',
        );
        expect(
          decoration.boxShadow,
          isNotNull,
          reason: '--sh-kid is kept on the off state',
        );
        // Identical geometry to an affordable card: only colour differs.
        expect(
          tester.getRect(_cardButton(_cafeCard)).height,
          tester.getRect(_cardButton(0)).height,
        );
        expect(
          tester.getRect(_cardButton(_cafeCard)).width,
          tester.getRect(_cardButton(0)).width,
        );
        await disposeApp(tester);
      });

      testWidgets('it is still disabled: no tap action, reported not enabled', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _pump(tester, theme);

        final data = tester
            .getSemantics(
              find.bySemanticsLabel('Save up for Trip to the park café'),
            )
            .getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'the design draws it disabled; it must not be operable',
        );
        expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(data.flagsCollection.isButton, isTrue);
        semantics.dispose();
        await disposeApp(tester);
      });

      testWidgets('the label is still 17 px w900 in ink-2', (tester) async {
        await _pump(tester, theme);
        final tokens = _tokens(tester);
        final label = tester.widget<Text>(
          find.descendant(
            of: _cardButton(_cafeCard),
            matching: find.text('Save up!'),
          ),
        );
        final style = label.style!;
        expect(style.fontSize, 17);
        expect(style.fontWeight, FontWeight.w900);
        expect(
          style.color,
          tokens.ink2,
          reason: 'a disabled pair must still meet the label contrast',
        );
        await disposeApp(tester);
      });

      testWidgets('ink-2 on surface-2 stays readable (WCAG AA)', (
        tester,
      ) async {
        await _pump(tester, theme);
        final tokens = _tokens(tester);
        // The greyed pair replaced a 0.45 wash over white, which was ~1.9:1 in
        // light mode — unreadable. `surface-2`/`ink-2` is the design's own
        // disabled pair, so it has to clear AA on its own, with no wash.
        final contrast = _contrastRatio(tokens.surface2, tokens.ink2);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason:
              '.k8-get.off label contrast in ${theme.name} is '
              '${contrast.toStringAsFixed(2)}:1',
        );
        // And the affordable button's own pair, for reference: the new
        // colourway must not have made the enabled state the washed-out one.
        expect(
          _contrastRatio(tokens.leaf, tokens.onLeaf),
          greaterThanOrEqualTo(3),
          reason: 'the enabled kid button is a large-text control',
        );
        await disposeApp(tester);
      });
    });
  }

  group('.k8-get.off against the design', () {
    testWidgets('the two states differ by colour, not by opacity', (
      tester,
    ) async {
      await setUpTestScope();
      await _pump(tester, ThemeMode.light);

      final tokens = _tokens(tester);
      final off = _decoration(tester, _cafeCard);
      final on = _decoration(tester, 0);
      expect(
        off.color,
        isNot(on.color),
        reason: 'leaf and surface-2 must be distinguishable without a wash',
      );
      expect(off.color, tokens.surface2);
      expect(on.color, tokens.leaf);
      await disposeApp(tester);
    });

    testWidgets('a reward that becomes affordable is repainted, not stale', (
      tester,
    ) async {
      // The card's colour is derived from `item.affordable`, which comes from
      // the stream. The café costs 150 and Maya has 120, so it needs a real
      // balance change (to 200) to cross over — exactly the moment where a
      // remembered colour would go stale.
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(0)),
      );
      await _pump(tester, ThemeMode.light);
      final tokens = _tokens(tester);
      expect(
        _decoration(tester, _cafeCard).color,
        tokens.surface2,
        reason: 'at 0 coins the café is out of reach',
      );
      expect(find.text('Save up!'), findsNWidgets(6));
      expect(find.text('150 more to go'), findsOneWidget);

      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(coins: Value(200)),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Get it'), findsNWidgets(6));
      expect(find.text('Save up!'), findsNothing);
      // The note disappears with the affordability, and the fill follows.
      expect(find.text('150 more to go'), findsNothing);
      expect(
        _decoration(tester, _cafeCard).color,
        tokens.leaf,
        reason:
            'the same card repaints as affordable when the balance covers '
            'it — the fill is derived, never remembered',
      );
      expect(
        tester.widget<Opacity>(_opacity(_cafeCard)).opacity,
        1,
        reason: 'and it is enabled, so no wash',
      );
      await disposeApp(tester);
    });
  });
}

/// The live token set, read through `context.nest` from the pumped screen —
/// the same extension every widget uses, so the assertion cannot drift from
/// the palette the app actually painted.
NestTokens _tokens(WidgetTester tester) =>
    tester.element(find.byType(ShopRewardCard).first).nest;

/// WCAG 2.x relative-luminance contrast ratio between two opaque colours.
double _contrastRatio(Color a, Color b) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4) as double;
  double luminance(Color colour) =>
      0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
  final first = luminance(a);
  final second = luminance(b);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}
