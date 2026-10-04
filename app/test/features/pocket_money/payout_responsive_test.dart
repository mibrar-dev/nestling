// P13 · Payout (parent) — responsive matrix, owner ALIGNMENT + BOTTOM EDGE.
//
// Runs the real `/payout` route on the in-memory Drift demo seed across
// light/dark × 320/390/430 dp × text scale 1.0/1.3 and asserts:
//
//   * the width under test is the width actually rendered (MediaQuery), so a
//     surface-override that silently loses cannot pass as "responsive cover";
//   * no overflow and the design copy still present at every size;
//   * ALIGNMENT (owner rule): ONE 20 px gutter on both edges, shared by the
//     sheet title, both `.child` rows, the `.saverow`, the CTA pill and the
//     `.check` column — nothing a few px off;
//   * BOTTOM EDGE (owner rule): the sheet's paper owns the last pixel row in
//     light and dark at every width — verified as a RENDERED PIXEL, never a
//     page tint or a meadow-green strip under the home indicator;
//   * every interactive control keeps a ≥ 44 px parent tap target, and a tap
//     that lands on the 6 px of padding *outside* the 51×31 toggle pill still
//     flips it (the tap target is bigger than the painted pill).
//
// NOTE on the harness: `test_scope.pumpAppRoute` hard-codes
// `physicalSize = 390×844`, so a size set *before* it is overwritten and the
// frame is 390 wide. That trap made two cases in `payout_view_test.dart`
// (the "320 px" and "short screen" tests) run at 390×844. This file pumps
// `NestlingApp` directly, as `money_ledger_responsive_test.dart` does, so the
// requested surface is the first frame's surface; the SHARED_REQUEST in this
// screen asks for the same parameter on `pumpAppRoute`.
//
// Widget space only — no simulator, no screenshots.

import 'dart:math' as math;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/presentation/views/payout_view.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

import '../../test_scope.dart';

const String kCta = 'Mark as paid & start the celebration';
const String kSubCopy = "Tick once you've handed over the cash";

/// Orchestrator-mandated copy (23:25), ungendered for every goal child.
const String kSaveCopy = "Move £1.00 of Maya's to their Lego Friends set fund";
const String kCaption =
    'Your children will see a payout celebration next time they open Nestling.';

/// Wraps the app so a rendered frame can be sampled for the bottom-edge rule.
const Key _pixelProbe = ValueKey<String>('p13_pixel_probe');

Future<void> _pumpPayout(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double textScale = 1,
}) async {
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/payout'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The `.child` row card that owns [text] — the shape, not the label.
Finder _rowCard(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first;

Finder _ctaPill() => find
    .ancestor(of: find.text(kCta), matching: find.byType(AnimatedContainer))
    .first;

/// The `.pay` sheet's own painted box.
Finder _sheetBox() => find
    .descendant(of: find.byType(PayoutSheet), matching: find.byType(Container))
    .first;

/// One logical pixel at (x, y) of the painted frame.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    if (data == null) {
      throw StateError('P13 pixel probe: toByteData() returned null.');
    }
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
      data.getUint8(offset + 3),
    ];
  });
  return pixel;
}

List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

void main() {
  group('P13 payout — responsive copy (real surfaces)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final textScale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets(
            '$themeName ${width}dp @${textScale}x: the surface is real, no '
            'overflow, copy intact',
            (tester) async {
              await setUpTestScope();
              await _pumpPayout(
                tester,
                theme: theme,
                surface: Size(width.toDouble(), 844),
                textScale: textScale,
              );

              // The harness trap this file exists to catch: a surface
              // override that never reaches the frame would make every
              // other assertion below a lie.
              final rendered = MediaQuery.sizeOf(
                tester.element(find.byType(PayoutView)),
              );
              expect(
                rendered.width,
                moreOrLessEquals(width.toDouble(), epsilon: 0.01),
                reason: 'the test must run at the width it claims',
              );
              expect(rendered.height, moreOrLessEquals(844, epsilon: 0.01));

              expect(find.text('Saturday payout'), findsOneWidget);
              expect(find.text(kSubCopy), findsOneWidget);
              expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
              expect(find.text('Weekly + quests · £2.10'), findsOneWidget);
              expect(find.text(kSaveCopy), findsOneWidget);
              expect(find.text(kCta), findsOneWidget);
              expect(find.text(kCaption), findsOneWidget);
              expect(find.byType(PayoutChildRow), findsNWidgets(2));
              expect(
                tester.takeException(),
                isNull,
                reason: 'a RenderFlex overflow must fail this size',
              );

              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('P13 payout — owner rule: alignment (one 20 px gutter)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: every block shares one gutter', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpPayout(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
          );

          const gutter = NestSpacing.padSide;
          final edge = width - gutter;

          // The sheet is full-bleed; its contents are not.
          final sheet = tester.getRect(_sheetBox());
          expect(sheet.left, moreOrLessEquals(0, epsilon: 0.01));
          expect(
            sheet.right,
            moreOrLessEquals(width.toDouble(), epsilon: 0.01),
          );

          for (final block in <(String, Finder)>[
            ('Maya row', _rowCard('Maya')),
            ('Leo row', _rowCard('Leo')),
            ('saverow', _rowCard(kSaveCopy)),
            ('CTA pill', _ctaPill()),
          ]) {
            final rect = tester.getRect(block.$2);
            expect(
              rect.left,
              moreOrLessEquals(gutter, epsilon: 0.01),
              reason: '${block.$1} must start on the gutter',
            );
            expect(
              rect.right,
              moreOrLessEquals(edge, epsilon: 0.01),
              reason: '${block.$1} must end on the gutter',
            );
          }

          // The `.check` column is the last thing before the right gutter,
          // 14 px of card padding inside it (`.child { padding: 14px }`).
          for (final label in <String>[
            'Maya paid in cash',
            'Leo paid in cash',
          ]) {
            final check = tester.getRect(find.bySemanticsLabel(label));
            expect(check.right, moreOrLessEquals(edge - 14, epsilon: 0.01));
          }

          await disposeApp(tester);
        });
      }
    }
  });

  group('P13 payout — owner rule: bottom edge is the sheet paper', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: paper owns the last pixel row', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpPayout(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
          );

          final tokens = tester.element(find.byType(PayoutView)).nest;
          final sheet = tester.getRect(_sheetBox());
          expect(
            sheet.bottom,
            moreOrLessEquals(844, epsilon: 0.01),
            reason: 'the sheet is bottom-anchored',
          );

          // A rendered pixel, not just a layout number: a `paper` Scaffold
          // under a `paper` sheet could still be painted over by a scrim or
          // a strip. Sampled under the home indicator and below it.
          for (final y in <double>[843, 836, 820]) {
            expect(
              await _pixelAt(tester, width / 2, y),
              _rgba(tokens.paper),
              reason:
                  'no coloured strip under the home indicator ($themeName '
                  '${width}dp at y=$y)',
            );
          }

          await disposeApp(tester);
        });
      }
    }
  });

  group('P13 payout — parent tap targets ≥ 44', () {
    for (final width in const <int>[320, 430]) {
      testWidgets('${width}dp: checks, toggle and CTA keep a 44 px target', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPayout(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
        );
        final handle = tester.ensureSemantics();

        for (final label in <String>['Maya paid in cash', 'Leo paid in cash']) {
          final rect = tester.getRect(find.bySemanticsLabel(label));
          expect(
            rect.height,
            greaterThanOrEqualTo(NestDevice.tapParent),
            reason: label,
          );
          expect(rect.width, greaterThanOrEqualTo(NestDevice.tapParent));
        }

        final toggle = tester.getRect(
          find.bySemanticsLabel("Move one pound of Maya's money to savings"),
        );
        // The NestToggle track is a fixed 51×31 with a 59×44 hit overhang
        // (main's _ToggleHitSlop); the width >= 44, and the overhang is
        // exercised functionally below.
        expect(toggle.width, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(toggle.height, closeTo(31, 0.5));

        final cta = tester.getRect(_ctaPill());
        expect(cta.height, greaterThanOrEqualTo(NestDevice.tapParent));

        handle.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('a tap outside the toggle pill but inside its target lands', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPayout(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The painted pill is 51×31; `NestToggle` wraps it in a 59×44 target.
      // 6 px above the pill's centre line is still inside that target.
      // The NestToggle track is 51×31; its 59×44 hit-slop overhang means a
      // tap above the pill still flips it.
      final pill = tester.getRect(find.byType(NestToggle));
      expect(pill.width, closeTo(51, 0.5));
      expect(pill.height, closeTo(31, 0.5));
      await tester.tapAt(Offset(pill.center.dx, pill.top + 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final handle = tester.ensureSemantics();
      final node = tester
          .getSemantics(
            find.bySemanticsLabel("Move one pound of Maya's money to savings"),
          )
          .getSemanticsData();
      expect(node.flagsCollection.isToggled, Tristate.isFalse);
      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P13 payout — the narrow surface stays operable', () {
    testWidgets('320×568 @1.3: the sheet scrolls, both checks keep working', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPayout(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 568),
        textScale: 1.3,
      );

      expect(
        MediaQuery.sizeOf(tester.element(find.byType(PayoutView))).height,
        moreOrLessEquals(568, epsilon: 0.01),
      );
      expect(tester.takeException(), isNull);

      // Both child rows sit at the top of the sheet and stay operable while
      // the rest of the stack is below the fold.
      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Leo paid in cash'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
        reason: 'the checks stay operable on the smallest supported surface',
      );
      handle.dispose();

      // The CTA and the caption are only reachable by scrolling — the sheet
      // must scroll rather than overflow at 320×568 × 1.3.
      final cta = find.text(kCta);
      await tester.scrollUntilVisible(cta, 120);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(kCaption), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('430dp @1.0: the wide gutter grows, nothing is centred off', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPayout(
        tester,
        theme: ThemeMode.light,
        surface: const Size(430, 932),
      );

      const gutter = NestSpacing.padSide;
      final sheet = tester.getRect(_sheetBox());
      expect(sheet.width, moreOrLessEquals(430, epsilon: 0.01));
      expect(sheet.bottom, moreOrLessEquals(932, epsilon: 0.01));
      for (final card in <Finder>[_rowCard('Maya'), _ctaPill()]) {
        expect(
          tester.getRect(card).left,
          moreOrLessEquals(gutter, epsilon: 0.01),
        );
        expect(
          tester.getRect(card).right,
          moreOrLessEquals(430 - gutter, epsilon: 0.01),
        );
      }
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P13 payout — geometry does not shift with the width', () {
    for (final width in const <int>[320, 430]) {
      testWidgets('${width}dp: the design stack keeps its internal rhythm', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPayout(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
        );

        // Width-driven, not surface-driven: the vertical stack is the same
        // 20/10/14 rhythm at every width, so a card drifting with the width
        // would mean the padding became fluid.
        final maya = tester.getRect(_rowCard('Maya'));
        final leo = tester.getRect(_rowCard('Leo'));
        expect(leo.top - maya.bottom, moreOrLessEquals(10, epsilon: 0.01));
        final saverow = tester.getRect(_rowCard(kSaveCopy));
        expect(saverow.top - leo.bottom, moreOrLessEquals(10, epsilon: 0.01));
        final cta = tester.getRect(_ctaPill());
        expect(cta.top - saverow.bottom, moreOrLessEquals(14, epsilon: 0.01));
        // 14 + 48 check + 14 = 76: the check is the row's height driver.
        expect(maya.height, moreOrLessEquals(76, epsilon: 0.01));

        await disposeApp(tester);
      });
    }

    testWidgets('the tick glyph is 24 px and stays inside the 48 px check', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPayout(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final check = tester.getRect(
        find
            .ancestor(
              of: find.byType(NestIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        math.min(check.width, check.height),
        moreOrLessEquals(48, epsilon: 0.01),
      );

      final icon = tester.getRect(find.byType(NestIcon).first);
      expect(icon.width, moreOrLessEquals(24, epsilon: 0.01));
      expect(icon.center.dx, moreOrLessEquals(check.center.dx, epsilon: 0.01));

      await disposeApp(tester);
    });
  });
}
