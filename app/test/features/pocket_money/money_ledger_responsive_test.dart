// P12 Money ledger — responsive geometry, owner alignment + bottom-edge rules.
//
// Runs the real `/money` route on the in-memory Drift demo seed across
// light/dark × 320/390/430 dp × text scale 1.0/1.3 and asserts:
//
//   * no overflow and every screen's copy still present at every size;
//   * ALIGNMENT (owner rule): one 20 px gutter on both edges, shared by the
//     segmented track, the hero card, the goal card, the history card and
//     both row buttons — nothing a few px off;
//   * BOTTOM EDGE (owner rule): the tab bar's SURFACE runs to the physical
//     bottom edge (with and without an OS home inset), never a page-coloured
//     strip around the home indicator;
//   * every interactive control keeps a ≥ 44 px tap target in parent mode.
//
// Widget space only — no simulator, no screenshots.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// Wraps the app so a rendered frame can be sampled for the bottom-edge rule.
const Key _pixelProbe = ValueKey<String>('p12_pixel_probe');

Future<void> _pumpMoney(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double textScale = 1,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/money'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The ledger is taller than the viewport; park it at the end so the row
/// buttons and the footer caption are built.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).first,
    const Offset(0, -1400),
    1200,
  );
  await tester.pumpAndSettle();
}

/// One logical pixel at (x, y) of the painted frame.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      data!.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
      data.getUint8(offset + 3),
    ];
  });
  return pixel;
}

/// The opaque RGBA bytes of [color] at 8-bit precision.
List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

Finder _heroCard() => find
    .ancestor(
      of: find.textContaining('is owed'),
      matching: find.byType(NestCard),
    )
    .first;

Finder _goalCard() => find
    .ancestor(
      of: find.textContaining('Lego Friends set'),
      matching: find.byType(NestCard),
    )
    .first;

Finder _historyCard() => find
    .ancestor(of: find.text('History'), matching: find.byType(NestCard))
    .first;

Finder _segmented() => find.byType(NestSegmented<String>);

Finder _addMoney() => find.widgetWithText(NestButton, 'Add money');
Finder _recordSpending() => find.widgetWithText(NestButton, 'Record spending');

void main() {
  group('P12 Money ledger — responsive copy', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final textScale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets(
            '$themeName ${width}dp @${textScale}x: no overflow, copy intact',
            (tester) async {
              await setUpTestScope();
              await _pumpMoney(
                tester,
                theme: theme,
                surface: Size(width.toDouble(), 844),
                textScale: textScale,
              );

              expect(find.text('Pocket money'), findsOneWidget);
              expect(find.text('Maya is owed'), findsOneWidget);
              expect(find.text('£4.20'), findsOneWidget);
              expect(find.text('Lego Friends set — £24.99'), findsOneWidget);
              expect(find.text('£15.50 saved · 62%'), findsOneWidget);
              expect(find.text('History'), findsOneWidget);
              expect(find.text('Payout time'), findsOneWidget);
              expect(
                tester.takeException(),
                isNull,
                reason: 'a RenderFlex overflow must fail this size',
              );

              await _scrollToEnd(tester);
              expect(find.text('Add money'), findsOneWidget);
              expect(find.text('Record spending'), findsOneWidget);
              expect(
                find.text(
                  'Nestling keeps track — the real money stays with you.',
                ),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);

              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('P12 Money ledger — owner rule: alignment (20 px gutters)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: every block shares one gutter', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpMoney(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
          );

          const gutter = NestSpacing.padSide;
          final edge = width - gutter;

          expect(
            tester.getTopLeft(find.text('Pocket money')).dx,
            moreOrLessEquals(gutter, epsilon: 0.01),
            reason: 'the title must start on the gutter',
          );
          for (final block in <(String, Finder)>[
            ('segmented', _segmented()),
            ('hero card', _heroCard()),
            ('goal card', _goalCard()),
          ]) {
            final rect = tester.getRect(block.$2);
            expect(
              rect.left,
              moreOrLessEquals(gutter, epsilon: 0.01),
              reason: '${block.$1} left edge',
            );
            expect(
              rect.right,
              moreOrLessEquals(edge, epsilon: 0.01),
              reason: '${block.$1} right edge',
            );
          }

          // The history card is below the fold; scroll it into the tree.
          await _scrollToEnd(tester);
          final history = tester.getRect(_historyCard());
          expect(
            history.left,
            moreOrLessEquals(gutter, epsilon: 0.01),
            reason: 'history card left edge',
          );
          expect(
            history.right,
            moreOrLessEquals(edge, epsilon: 0.01),
            reason: 'history card right edge',
          );

          // The two row buttons split the same content column, so only their
          // OUTER edges sit on the gutters; they meet 10 px apart in the
          // middle (the design's `.rowbtns` gap).
          final add = tester.getRect(_addMoney());
          final spend = tester.getRect(_recordSpending());
          expect(add.left, moreOrLessEquals(gutter, epsilon: 0.01));
          expect(spend.right, moreOrLessEquals(edge, epsilon: 0.01));
          expect(spend.left - add.right, moreOrLessEquals(10, epsilon: 0.01));
          expect(
            (add.width - spend.width).abs(),
            lessThan(0.01),
            reason: 'the row buttons must be the same width',
          );

          // The footer caption is centred on the same content column.
          final footer = tester.getRect(
            find.text('Nestling keeps track — the real money stays with you.'),
          );
          expect(footer.center.dx, moreOrLessEquals(width / 2, epsilon: 0.01));
          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        });
      }
    }
  });

  group('P12 Money ledger — owner rule: bottom edge', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final bottomInset in const <double>[0, 34]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets(
          '$themeName: the tab bar runs to the edge (OS inset $bottomInset)',
          (tester) async {
            await setUpTestScope();
            await _pumpMoney(
              tester,
              theme: theme,
              surface: const Size(390, 844),
              bottomInset: bottomInset,
            );

            final bar = tester.getRect(find.byType(NestTabBar));
            expect(
              bar.bottom,
              moreOrLessEquals(844, epsilon: 0.01),
              reason:
                  'the bar must end at the physical screen edge; ending at '
                  '${bar.bottom} exposes page colour below it',
            );
            expect(bar.left, 0);
            expect(bar.right, moreOrLessEquals(390, epsilon: 0.01));

            final tokens = tester.element(find.byType(NestTabBar)).nest;
            expect(
              tokens.surface,
              isNot(tokens.paper),
              reason:
                  'the probe must discriminate: page colour and bar surface '
                  'differ, so a strip below the bar cannot pass',
            );
            expect(
              await _pixelAt(tester, 195, 843),
              _rgba(tokens.surface),
              reason:
                  'the last row (y=843) must be the bar surface '
                  '${_rgba(tokens.surface)}, not the scaffold paper '
                  '${_rgba(tokens.paper)}',
            );
            // …and it must not be the page tint either.
            expect(
              await _pixelAt(tester, 195, 843),
              isNot(_rgba(tokens.paper)),
            );

            await disposeApp(tester);
          },
        );
      }
    }
  });

  group('P12 Money ledger — tap targets (parent mode ≥ 44 dp)', () {
    for (final width in const <int>[320, 430]) {
      testWidgets('${width}dp: every control keeps a 44 px target', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await setUpTestScope();
        await _pumpMoney(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
        );

        for (final option in const <String>['Maya', 'Leo']) {
          expect(
            tester.getSize(find.text(option)).height,
            lessThanOrEqualTo(NestDevice.tapParent),
            reason: 'the label is inside a 44 px button, not a 44 px label',
          );
          final node = tester.getSemantics(find.bySemanticsLabel(option).first);
          final data = node.getSemanticsData();
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(data.rect.height, greaterThanOrEqualTo(NestDevice.tapParent));
          expect(data.rect.width, greaterThanOrEqualTo(NestDevice.tapParent));
        }

        final payout = tester.getSemantics(
          find.bySemanticsLabel(RegExp('Payout time for Maya')),
        );
        expect(
          payout.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester.getSize(find.widgetWithText(NestButton, 'Payout time')).height,
          greaterThanOrEqualTo(52),
          reason: 'the design gives the hero CTA min-height 52',
        );

        await _scrollToEnd(tester);
        for (final button in <Finder>[_addMoney(), _recordSpending()]) {
          final node = tester.getSemantics(button);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          expect(
            tester.getSize(button).height,
            greaterThanOrEqualTo(NestDevice.tapParent),
          );
        }

        // The sheet's CTA and its icon-only close control.
        await tester.tap(_addMoney());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final cta = find.widgetWithText(NestButton, 'Add money').last;
        expect(tester.getSize(cta).height, greaterThanOrEqualTo(52));
        expect(
          tester
              .getSemantics(cta)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        final close = tester.getSemantics(find.bySemanticsLabel('Close'));
        expect(close.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(
          close.getSemanticsData().rect.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
        );
        expect(tester.takeException(), isNull);

        handle.dispose();
        await disposeApp(tester);
      });
    }
  });
}
