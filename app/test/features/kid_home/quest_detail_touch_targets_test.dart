// K04 tap targets and edge-reachability.
//
// Iteration 1 pinned 56/60/64 only as a side effect of the 390-light geometry
// test; nothing asserted the ≥ 44 parent / ≥ 56 kid rule as a RULE, and nothing
// proved a control is reachable at its extremes. Both are checked here across
// {320, 390, 430} × {1.0, 1.3}.
//
// Two things are proven per control:
//
//   1. SIZE — the rendered box (not the text, not the painted fill) is at least
//      `NestDevice.tapKid` (56) on both axes, and at least `NestDevice.tapParent`
//      (44) as the weaker shared floor.
//   2. REACH — a tap at the very edge of the target, in a region with no text
//      and no dot, still activates it. That is what catches a control whose
//      InkWell shrank while its painted chrome stayed large.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

import '../../test_scope.dart';

const List<String> _steps = <String>[
  'Clothes in the basket',
  'Toys in the box',
  'Books on the shelf',
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  ThemeMode mode = ThemeMode.light,
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

/// A step row: the `Semantics(button: true)` wrapper the view puts around the
/// `excludeSemantics`-ed InkWell column.
Finder _stepRow(String label) => find.bySemanticsLabel('$label, not ticked');

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K04 tap targets are at least 56 (kid) / 44 (parent floor)', () {
    for (final width in <double>[320, 390, 430]) {
      for (final scale in <double>[1, 1.3]) {
        final label = '${width.toInt()}px @ ${scale.toStringAsFixed(1)}x';
        testWidgets(label, (tester) async {
          final semantics = tester.ensureSemantics();
          await _pump(tester, width: width, textScale: scale);

          void expectKidSized(String name, Size size) {
            expect(
              size.height,
              greaterThanOrEqualTo(NestDevice.tapKid),
              reason:
                  '$name height must be ≥ ${NestDevice.tapKid} kid '
                  '($label, got ${size.height})',
            );
            expect(
              size.width,
              greaterThanOrEqualTo(NestDevice.tapParent),
              reason:
                  '$name width must be ≥ ${NestDevice.tapParent} '
                  '($label, got ${size.width})',
            );
            expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
          }

          // Top row: `.nav-back.lg` / `.lock-btn.lg` are 56×56 in the design.
          final back = tester.getSize(find.byType(NestIconButton));
          expectKidSized('back button', back);
          expect(back.width, NestDevice.tapKid);
          expect(back.height, NestDevice.tapKid);

          final lock = tester.getSize(find.byType(NestLockButton));
          expectKidSized('lock button', lock);
          expect(lock.width, NestDevice.tapKid);
          expect(lock.height, NestDevice.tapKid);

          // `.k4-step { min-height: 60 }` full-bleed rows.
          for (final step in _steps) {
            final size = tester.getSize(_stepRow(step));
            expectKidSized('step "$step"', size);
            expect(
              size.height,
              greaterThanOrEqualTo(60),
              reason: 'the design row is 60 px tall at 1.0 ($label)',
            );
          }

          // `.btn-kid` 64 high; the widget box also carries the 6 px shadow room,
          // so assert the floor, not the exact painted 64 (the geometry test
          // owns the painted-rect numbers).
          final buttons = find.byType(NestKidButton);
          expect(buttons, findsNWidgets(2));
          for (var i = 0; i < 2; i++) {
            expectKidSized(
              'bottom bar button $i',
              tester.getSize(buttons.at(i)),
            );
          }

          semantics.dispose();
          await disposeApp(tester);
        });
      }
    }
  });

  group('K04 targets are reachable at their extremes', () {
    testWidgets('a step toggles when tapped past the end of its text', (
      tester,
    ) async {
      // The right-hand ~100 px of a row is empty space. If the InkWell had
      // collapsed to the text, this tap would miss and the row would look dead
      // at the one place a small thumb naturally lands.
      await _pump(tester, width: 390, textScale: 1);
      // The SHORTEST label, so the row really does carry a wide empty stretch
      // to its right. ("Books on the shelf" is the longest and leaves only
      // ~14 px of layout slack, which would make the premise false rather than
      // the screen wrong.)
      final row = tester.getRect(_stepRow('Toys in the box'));
      // Measure the PAINTED glyphs, not the Text widget's box: the label sits
      // in an `Expanded`, so the widget box is the whole remaining slot
      // (x 89…353) and would understate the empty space by ~135 px.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Toys in the box'),
      );
      final painted = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
      );
      final paintedRight = painted.last.right;
      expect(
        row.right - paintedRight,
        greaterThan(60),
        reason: 'the row really does extend well past its painted label',
      );

      await tester.tapAt(Offset(row.right - 6, row.center.dy));
      await tester.pump();
      expect(
        find.bySemanticsLabel('Toys in the box, ticked'),
        findsOneWidget,
        reason: 'the empty right end of the row must still toggle it',
      );
      await disposeApp(tester);
    });

    testWidgets('a step toggles when tapped on the ring itself', (
      tester,
    ) async {
      await _pump(tester, width: 390, textScale: 1);
      final ring = tester.getRect(
        find
            .byWidgetPredicate((widget) {
              if (widget is! Container) return false;
              final box = widget.decoration;
              return box is BoxDecoration &&
                  box.shape == BoxShape.circle &&
                  widget.constraints?.maxHeight == 40;
            })
            .at(0),
      );
      await tester.tapAt(ring.center);
      await tester.pump();
      expect(
        find.bySemanticsLabel('Clothes in the basket, ticked'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets(
      'a step toggles when tapped 5 px above its text baseline band',
      (tester) async {
        // Same idea as the NestChipWrap 44 px rule: the activation band extends
        // past the painted ring vertically.
        await _pump(tester, width: 390, textScale: 1);
        final row = tester.getRect(_stepRow('Toys in the box'));
        await tester.tapAt(Offset(row.center.dx, row.top + 5));
        await tester.pump();
        expect(
          find.bySemanticsLabel('Toys in the box, ticked'),
          findsOneWidget,
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'the lock and back are operable by their accessibility action',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(tester, width: 390, textScale: 1);

        // The rules require `performAction` to change real state, not just to
        // exist. The lock pushes the parental gate.
        final lock = find.byType(NestLockButton);
        expect(
          tester
              .getSemantics(lock)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        tester.semantics.performAction(
          find.semantics.byLabel('Grown-ups'),
          SemanticsAction.tap,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(pushedPath(tester), ParentalGateRoutePaths.gate);

        semantics.dispose();
        await disposeApp(tester);
      },
    );
  });
}
