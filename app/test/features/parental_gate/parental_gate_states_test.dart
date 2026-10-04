// P17 parental-gate state, responsive and a11y matrix.
//
// Covers the orchestrator's test matrix: light + dark, widths 320 / 390 / 430,
// textScale 1.0 and 1.3, no overflow anywhere, the app's 1.0–1.3 scaler clamp,
// EFFECTIVE (painted) keypad tap targets — the `FittedBox` shrinks the layout
// box but the on-screen key must stay ≥ 56 (kid minimum) at 320 — the dark
// surface colours, and caption contrast in both themes.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

import '../../test_scope.dart';

Future<void> _pump(
  WidgetTester tester, {
  String route = '/parental-gate',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// WCAG relative-luminance contrast ratio for two opaque colours (sRGB).
double _contrast(Color a, Color b) {
  double channel(double s) =>
      s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();

  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  final la = lum(a);
  final lb = lum(b);
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// The rect a render object paints at, transform included.
Rect _painted(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

List<Rect> _paintedRects(WidgetTester tester, Finder finder) {
  final rects = <Rect>[];
  for (final element in finder.evaluate()) {
    final ro = element.renderObject;
    if (ro is RenderBox && ro.hasSize) rects.add(_painted(ro));
  }
  return rects;
}

Finder _keyInks() =>
    find.byWidgetPredicate((w) => w is Ink && w.width == 72 && w.height == 72);

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('responsive matrix', () {
    for (final width in const <double>[320, 390, 430]) {
      for (final scale in const <double>[1, 1.3]) {
        for (final theme in const <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('$width px @ textScale $scale · ${theme.name} '
              'renders without overflow', (tester) async {
            await _pump(tester, width: width, textScale: scale, theme: theme);

            expect(find.text('Grown-ups only'), findsOneWidget);
            expect(find.text('Type the answer in numbers:'), findsOneWidget);
            expect(find.text('Back to Pip'), findsOneWidget);
            expect(
              find.text('This keeps settings and purchases safe.'),
              findsOneWidget,
            );
            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(_keyInks(), findsNWidgets(11));
            expect(tester.takeException(), isNull);

            // The card keeps its 24 px gutters and never leaves the canvas.
            final modal = tester.getRect(find.byType(NestModal));
            expect(modal.left, moreOrLessEquals(24, epsilon: 0.5));
            expect(modal.right, moreOrLessEquals(width - 24, epsilon: 0.5));
            // … or scrolls internally instead of clipping the cancel button.
            final cancel = find.ancestor(
              of: find.text('Back to Pip'),
              matching: find.byType(NestButton),
            );
            expect(
              tester.getSize(cancel).height,
              greaterThanOrEqualTo(NestDevice.tapKid),
            );
            expect(find.text('Back to Pip'), findsOneWidget);
            await disposeApp(tester);
          });
        }
      }
    }

    testWidgets('a 2.0 system scale is clamped to the supported 1.3', (
      tester,
    ) async {
      await _pump(tester, textScale: 1.3);
      final at13 = tester.getRect(find.byType(NestModal));
      await disposeApp(tester);

      await _pump(tester, textScale: 2);
      final at20 = tester.getRect(find.byType(NestModal));
      expect(at20.height, moreOrLessEquals(at13.height, epsilon: 0.5));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('kid tap targets (painted, not layout)', () {
    for (final width in const <double>[320, 390, 430]) {
      testWidgets('every key keeps a ≥56 px rect at ${width.toInt()} px', (
        tester,
      ) async {
        await _pump(tester, width: width, textScale: 1.3);
        final keys = _paintedRects(tester, _keyInks());
        expect(keys, hasLength(11));
        for (final key in keys) {
          expect(
            key.width,
            greaterThanOrEqualTo(NestDevice.tapKid),
            reason: 'a kid-mode key must stay ≥56 on screen at $width px',
          );
          expect(key.height, greaterThanOrEqualTo(NestDevice.tapKid));
        }
        // The ghost cancel is full width and ≥56 too.
        final cancel = tester.getRect(
          find.ancestor(
            of: find.text('Back to Pip'),
            matching: find.byType(NestButton),
          ),
        );
        expect(cancel.height, greaterThanOrEqualTo(NestDevice.tapKid));
        expect(cancel.width, greaterThanOrEqualTo(width - 2 * 24 - 2 * 20));
        await disposeApp(tester);
      });
    }

    testWidgets('the retry escape in the failure state is ≥44 px', (
      tester,
    ) async {
      final repo = GetIt.instance<ParentalGateRepository>();
      await GetIt.instance.unregister<ParentalGateRepository>();
      GetIt.instance.registerSingleton<ParentalGateRepository>(
        _FailingRepository(),
      );
      addTearDown(() async {
        await GetIt.instance.unregister<ParentalGateRepository>();
        GetIt.instance.registerSingleton<ParentalGateRepository>(repo);
      });

      await _pump(tester);
      expect(find.text('Try again'), findsOneWidget);
      final retry = tester.getRect(
        find.ancestor(
          of: find.text('Try again'),
          matching: find.byType(NestButton),
        ),
      );
      expect(retry.height, greaterThanOrEqualTo(NestDevice.tapParent));
      // The failure body also keeps the 56 px kid escape.
      final cancel = tester.getRect(
        find.ancestor(
          of: find.text('Back to Pip'),
          matching: find.byType(NestButton),
        ),
      );
      expect(cancel.height, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('dark mode surfaces', () {
    testWidgets('the card paints the dark surface, not the light one', (
      tester,
    ) async {
      await _pump(tester, theme: ThemeMode.dark);
      final context = tester.element(find.byType(NestModal));
      final tokens = context.nest;
      expect(tokens.isDark, isTrue);
      final decoration =
          tester
                  .widgetList<Container>(
                    find.byWidgetPredicate(
                      (w) =>
                          w is Container &&
                          w.decoration is BoxDecoration &&
                          (w.decoration! as BoxDecoration).borderRadius ==
                              NestRadii.allXl,
                    ),
                  )
                  .first
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, tokens.surface);
      expect(decoration.boxShadow, isNotNull);
      // Kid keys lose their shadow in dark (NestKeypad) but keep the ring.
      final scrim = _scrimColour(tester);
      expect(scrim, isNotNull);
      expect(scrim!.a, greaterThan(0));
      await disposeApp(tester);
    });
  });

  group('contrast', () {
    testWidgets('caption colour contrast is readable on both themes', (
      tester,
    ) async {
      for (final mode in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await _pump(tester, theme: mode);
        final tokens = tester.element(find.byType(NestModal)).nest;
        expect(
          _contrast(tokens.surface, tokens.ink2),
          greaterThanOrEqualTo(4.5),
          reason: 'caption / instruction ink-2 on the card surface ($mode)',
        );
        expect(
          _contrast(tokens.surface, tokens.ink),
          greaterThanOrEqualTo(4.5),
        );
        // The lock tile pairs lilac on lilac-tint (decorative, but keep it
        // legible in both themes).
        expect(_contrast(tokens.lilacTint, tokens.lilac), greaterThan(2));
        await disposeApp(tester);
      }
    });
  });
}

/// The scrim's `ColoredBox` colour, or null when it is missing.
Color? _scrimColour(WidgetTester tester) {
  for (final element in find.byType(ColoredBox).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderBox || !ro.hasSize) continue;
    final rect = _painted(ro);
    if (rect.width == 390 && rect.height == 844) {
      return (element.widget as ColoredBox).color;
    }
  }
  return null;
}

/// Streams an error so the view lands in its failure state.
class _FailingRepository extends ParentalGateRepository {
  static const ParentalGateChallenge _challenge = ParentalGateChallenge(
    id: 'failing',
    title: 'Grown-ups only',
    detail: 'This keeps settings and purchases safe.',
    a: 7,
    b: 6,
  );

  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      <ParentalGateChallenge>[_challenge];

  @override
  Stream<List<ParentalGateChallenge>> watchItems() =>
      Stream<List<ParentalGateChallenge>>.error(Exception('no gate'));

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) => _challenge;
}
