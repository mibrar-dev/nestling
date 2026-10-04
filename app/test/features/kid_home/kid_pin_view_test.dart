// K02 Kid PIN (`/kid-pin`) view tests: layout matrix, design geometry,
// semantics actions, PIN submit outcomes, no-PIN auto-advance, and the
// loading/failure states. Every pumped app ends with `disposeApp`.
//
// Stage 3 (test) added the groups below the original five:
//   * `K02 tap targets`        — ACCESSIBILITY ACTIONS / RULES §8 (>= 56 kid)
//   * `K02 every tap …`       — every control reaches the right route
//   * `K02 entry announcements` — dots / in-flight / entry-limit semantics
//   * `K02 layout invariants`  — gutters, centring, dark parity, bottom edge
//   * `K02 design-copy parity` — bytes read from `K02-pin.html`, never typed
// Keypad PITCH is deliberately not pinned: ORCHESTRATOR_NOTES (07:13) has the
// shared `NestKeypad` grid fix on main (`shared/keypad_grid`), so these tests
// assert version-independent invariants (72 px keys, uniform pitch, centred,
// inside the gutters) and stay green across the merge.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/views/kid_pin_view.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

import '../../test_scope.dart';

Future<void> _pumpRoute(
  WidgetTester tester, {
  String route = '/kid-pin',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).last);
    await tester.pump();
  }
}

/// Test seam around `verifyPin`: lets a test script right/wrong answers
/// without forking the real repository.
class _PinStub {
  bool hang = false;
  bool fail = false;
  bool nextOk = true;
  int verifyCalls = 0;
  String? lastPin;
  bool hangLoad = false;
  bool loadFail = false;
}

class _WrappingRepo implements KidHomeRepository {
  _WrappingRepo(this._real, this.stub);

  final KidHomeRepository _real;
  final _PinStub stub;

  @override
  Future<bool> verifyPin(String childId, String pin) async {
    stub.verifyCalls++;
    stub.lastPin = pin;
    if (stub.hang) {
      // Never completes, and holds NO timer (a delayed() would leak a
      // pending Timer into test teardown).
      await Completer<void>().future;
    }
    if (stub.fail) throw Exception('verify down');
    return stub.nextOk;
  }

  @override
  Stream<KidChild?> watchActiveChild() => _real.watchActiveChild();

  @override
  Stream<KidHomeData> watchHome() {
    if (stub.hangLoad) return const Stream<KidHomeData>.empty();
    if (stub.loadFail) {
      return Stream<KidHomeData>.error(Exception('home down'));
    }
    return _real.watchHome();
  }

  @override
  Future<List<KidQuest>> getItems() => _real.getItems();

  @override
  Stream<List<KidQuest>> watchItems() => _real.watchItems();

  @override
  Stream<List<KidChild>> watchProfiles() => _real.watchProfiles();

  @override
  Future<void> setActiveChild(String childId) => _real.setActiveChild(childId);

  @override
  Future<void> completeQuest(String childId, String questId) =>
      _real.completeQuest(childId, questId);

  @override
  List<String> stepsFor(String questId) => _real.stepsFor(questId);
}

Future<void> _patchVerify(_PinStub stub) async {
  final real = GetIt.instance<KidHomeRepository>();
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(
    _WrappingRepo(real, stub),
  );
}

/// Loads the bundled faces so text metrics match a device run (same shape
/// as `kid_home_geometry_test.dart`): without it the dots/pill/keypad
//anchors drift by whole wrapped lines.
Future<void> _loadBundledFonts() async {
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

void main() {
  setUp(() async {
    await _loadBundledFonts();
    await setUpTestScope();
  });

  group('K02 layout matrix', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    for (final (String themeName, ThemeMode theme) in themes) {
      for (final width in const <double>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          testWidgets('$themeName ${width.toInt()}px scale $scale renders', (
            tester,
          ) async {
            await _pumpRoute(
              tester,
              width: width,
              textScale: scale,
              theme: theme,
            );
            expect(
              find.text('Hi Maya! Enter your secret code'),
              findsOneWidget,
            );
            expect(find.text('NESTLING'), findsOneWidget);
            expect(
              find.text('Forgot it? Just ask a grown-up.'),
              findsOneWidget,
            );
            expect(find.textContaining('£'), findsNothing);
            expect(tester.takeException(), isNull);
            await disposeApp(tester);
          });
        }
      }
    }
  });

  group('K02 geometry + shapes (390/light)', () {
    testWidgets('avatar disc, mark pill shape, dots, keypad row', (
      tester,
    ) async {
      await _pumpRoute(tester);
      // Avatar disc: 128 circle, design x 131–259, y 109–237.
      final discFinder = find.ancestor(
        of: find.byType(NestAvatar),
        matching: find.byType(Container),
      );
      final disc = tester.getRect(discFinder.first);
      expect(disc.width, 128);
      expect(disc.height, 128);
      expect(disc.left, closeTo(131, 2));
      expect(disc.top, closeTo(109, 2));
      // Mark pill text present with its 1.28 tracking is on the Text.
      final mark = tester.widget<Text>(find.text('NESTLING'));
      expect(mark.style?.letterSpacing, 1.28);
      expect(mark.style?.fontSize, 16);
      // The pill's BACKGROUND rect, not just where the text lands (P05
      // lesson, review finding 3): tinted, fully-rounded, centred, 26 tall.
      final pill = find.byWidgetPredicate((w) {
        final d = w is Container ? w.decoration : null;
        return d is BoxDecoration &&
            d.shape != BoxShape.circle &&
            d.borderRadius != null;
      });
      expect(pill, findsOneWidget);
      final pillRect = tester.getRect(pill);
      expect(pillRect.center.dx, closeTo(195, 2));
      expect(pillRect.height, closeTo(26, 2));
      // Every key disc is the design's 72×72 kid circle (SHAPES, not text).
      final keyDiscs = find.descendant(
        of: find.byType(NestKeypad),
        matching: find.byWidgetPredicate((w) {
          if (w is! Ink) return false;
          final d = w.decoration;
          return d is BoxDecoration && d.shape == BoxShape.circle;
        }),
      );
      expect(keyDiscs, findsNWidgets(11));
      for (var i = 0; i < 11; i++) {
        final rect = tester.getRect(keyDiscs.at(i));
        expect(rect.width, 72);
        expect(rect.height, 72);
      }
      // Two key taps → two filled dots among the four 18px circles.
      await _enterPin(tester, '12');
      final dotFinder = find.descendant(
        of: find.byType(NestPinDots),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(dotFinder, findsNWidgets(4));
      final first = tester.getRect(dotFinder.first);
      expect(first.width, 18);
      expect(first.top, closeTo(331 + 8, 2));
      await disposeApp(tester);
    });

    testWidgets('no overflow at 320x1.3 and 430', (tester) async {
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
      await setUpTestScope();
      await _pumpRoute(tester, width: 430);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('K02 semantics', () {
    testWidgets('every control is a labelled tap target; dots are not', (
      tester,
    ) async {
      await _pumpRoute(tester);
      for (final label in <String>[
        'Digit 0',
        for (var i = 1; i <= 9; i++) 'Digit $i',
        'Delete',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      for (final label in <String>[
        'Back',
        'Grown-ups',
        for (var i = 0; i <= 9; i++) 'Digit $i',
        'Delete',
      ]) {
        final node = tester.getSemantics(find.bySemanticsLabel(label).first);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must be tabbable',
        );
      }
      // Dots node has a label but NO tap action.
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      final dotsNode = tester.getSemantics(
        find.bySemanticsLabel(RegExp('0 of 4 entered')).first,
      );
      expect(
        dotsNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      // A digit performAction fills a dot (real state, not just label).
      final one = tester.getSemantics(find.bySemanticsLabel('Digit 1').first);
      one.owner!.performAction(one.id, SemanticsAction.tap);
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('1 of 4 entered')), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K02 PIN flow', () {
    testWidgets('correct PIN (1234) navigates to /kid-home', (tester) async {
      await _pumpRoute(tester);
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('wrong PIN toasts, clears dots, stays; retry works', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await _enterPin(tester, '9999');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      expect(currentPath(tester), '/kid-pin');
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      // Retry with the right code still works (unlimited retries).
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a 5th digit is ignored and delete on empty is a no-op', (
      tester,
    ) async {
      final stub = _PinStub()..hang = true;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      await tester.tap(find.text('5'));
      await tester.pump();
      final del = tester.getSemantics(find.bySemanticsLabel('Delete').first);
      del.owner!.performAction(del.id, SemanticsAction.tap);
      await tester.pump();
      // Delete cleared the 1 digit; empty delete is a no-op.
      final del2 = tester.getSemantics(find.bySemanticsLabel('Delete').first);
      del2.owner!.performAction(del2.id, SemanticsAction.tap);
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      // 4 digits start one check; a 5th key tap is swallowed.
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('7').last);
      await tester.pump();
      expect(stub.verifyCalls, 1);
      expect(stub.lastPin, '1234');
      await disposeApp(tester);
    });

    testWidgets('back-to-back 4th-digit taps submit once', (tester) async {
      final stub = _PinStub()..hang = true;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      await _enterPin(tester, '123');
      await tester.tap(find.text('4').last);
      await tester.tap(find.text('4').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(stub.verifyCalls, 1);
      await disposeApp(tester);
    });
  });

  group('K02 states + modes', () {
    testWidgets('Leo (no PIN) auto-advances to /kid-home', (tester) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('no active child shows chooser', (tester) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>(null)),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.text('Choose'), findsOneWidget);
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/who-is-playing');
      await disposeApp(tester);
    });

    testWidgets('hanging stream → PIN loading; failed stream → retry card', (
      tester,
    ) async {
      final real = GetIt.instance<KidHomeRepository>();
      final stub = _PinStub()..hangLoad = true;
      await GetIt.instance.unregister<KidHomeRepository>();
      GetIt.instance.registerSingleton<KidHomeRepository>(
        _WrappingRepo(real, stub),
      );
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel('Loading your secret code'), findsOneWidget);
      await disposeApp(tester);
      await setUpTestScope();

      final stub2 = _PinStub()..loadFail = true;
      final real2 = GetIt.instance<KidHomeRepository>();
      await GetIt.instance.unregister<KidHomeRepository>();
      GetIt.instance.registerSingleton<KidHomeRepository>(
        _WrappingRepo(real2, stub2),
      );
      await _pumpRoute(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text("Let's try again."), findsOneWidget);
      // Retry recovers once the repo is healthy again.
      stub2.loadFail = false;
      await tester.tap(find.text('Try again'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'an empty family (Seed.empty) shows the chooser, not a keypad',
      (tester) async {
        // `Seed.empty` = onboarded parent, no children (the P08b shape).
        final db = await setUpTestScope(seedDemo: false);
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
        await _pumpRoute(tester);
        expect(find.text("Who's playing?"), findsOneWidget);
        expect(find.byType(NestKeypad), findsNothing);
        expect(find.byType(NestPinDots), findsNothing);
        await tester.tap(find.text('Choose'));
        await tester.pumpAndSettle();
        expect(currentPath(tester), KidHomeRoutePaths.picker);
        await disposeApp(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // ACCESSIBILITY ACTIONS + RULES §8 — tap targets. K02 is a kid screen, so
  // every control must keep the 56 px kid minimum (`.lock-btn.lg` /
  // `.nav-back.lg` are 56 in the design; keypad keys are 72).
  // -------------------------------------------------------------------------
  group('K02 tap targets', () {
    testWidgets('digits, Delete, Back and the lock are all >= 56 px', (
      tester,
    ) async {
      await _pumpRoute(tester);
      for (final label in <String>[
        for (var i = 0; i <= 9; i++) 'Digit $i',
        'Delete',
        'Back',
        'Grown-ups',
      ]) {
        final rect = tester.getRect(find.bySemanticsLabel(label).first);
        expect(
          rect.width,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$label width',
        );
        expect(
          rect.height,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$label height',
        );
      }
      // The design's two 56 px controls match the token exactly.
      expect(
        tester.getSize(find.byType(NestIconButton).first),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      expect(
        tester.getSize(find.byType(NestLockButton).first),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      await disposeApp(tester);
    });

    testWidgets('the key discs are 72 px squares (design .keypad button)', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final keys = _keyFinder();
      expect(keys, findsNWidgets(11)); // 1-9, 0, Delete
      for (var i = 0; i < 11; i++) {
        final rect = tester.getRect(keys.at(i));
        expect(rect.width, 72, reason: 'key $i width');
        expect(rect.height, 72, reason: 'key $i height');
      }
      await disposeApp(tester);
    });

    testWidgets('the chooser and retry buttons keep the kid minimum', (
      tester,
    ) async {
      // No active child -> `Choose`.
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>(null)),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      final choose = tester.getRect(
        find.ancestor(
          of: find.text('Choose'),
          matching: find.byType(NestKidButton),
        ),
      );
      expect(choose.height, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(choose.width, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(
        tester.getSize(find.text('Choose')).height,
        lessThan(choose.height),
      );
      await disposeApp(tester);
      await setUpTestScope();

      // Failing stream -> `Try again`.
      final real = GetIt.instance<KidHomeRepository>();
      final stub = _PinStub()..loadFail = true;
      await GetIt.instance.unregister<KidHomeRepository>();
      GetIt.instance.registerSingleton<KidHomeRepository>(
        _WrappingRepo(real, stub),
      );
      await _pumpRoute(tester);
      final retry = tester.getRect(
        find.ancestor(
          of: find.text('Try again'),
          matching: find.byType(NestKidButton),
        ),
      );
      expect(retry.height, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(retry.width, greaterThanOrEqualTo(NestDevice.tapKid));
      await disposeApp(tester);
    });

    testWidgets('the keypad blank slot is not announced as a control', (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel(RegExp('blank')), findsNothing);
      // Every announced control in the keypad is a labelled button: 11 taps,
      // nothing unnamed (the 12th cell is the decorative blank).
      expect(
        _keyFinder(),
        findsNWidgets(11),
        reason: 'no extra/unnamed keypad button',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Every tap reaches the right route (ACCESSIBILITY ACTIONS: `performAction`
  // must drive the real navigation, not only a label).
  // -------------------------------------------------------------------------
  group('K02 every tap reaches its route', () {
    testWidgets('Back by tap and by VoiceOver both land on the picker', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final back = tester.getSemantics(find.bySemanticsLabel('Back').first);
      back.owner!.performAction(back.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);

      await setUpTestScope();
      await _pumpRoute(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);
    });

    testWidgets('Back pops a K02 that K01 pushed', (tester) async {
      await _pumpRoute(tester, route: KidHomeRoutePaths.picker);
      await tester.tap(find.byKey(const ValueKey<String>('k01-tile-maya')));
      // The tile tap runs a real Drift `setActiveChild` write — drain it or
      // the pushed route is still on its loading UI (K01-BUG-3 harness note).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), KidHomeRoutePaths.pin);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);
    });

    testWidgets('the lock opens the grown-up gate and keeps the typed code', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.tap(find.bySemanticsLabel('Digit 1'));
      await tester.pump();
      final lock = tester.getSemantics(
        find.bySemanticsLabel('Grown-ups').first,
      );
      lock.owner!.performAction(lock.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), KidHomeRoutePaths.pin);
      expect(
        find.bySemanticsLabel(RegExp('1 of 4 entered')),
        findsOneWidget,
        reason: 'the half-typed code survives the gate detour',
      );
      await disposeApp(tester);
    });

    testWidgets('a rapid lock double tap pushes exactly one gate', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      // One pop lands back on the PIN screen; a second gate would leave the
      // gate on top and the finder below would find nothing.
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), KidHomeRoutePaths.pin);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the lock works in the loading state too', (tester) async {
      final real = GetIt.instance<KidHomeRepository>();
      final stub = _PinStub()..hangLoad = true;
      await GetIt.instance.unregister<KidHomeRepository>();
      GetIt.instance.registerSingleton<KidHomeRepository>(
        _WrappingRepo(real, stub),
      );
      await _pumpRoute(tester);
      expect(find.byType(NestKeypad), findsNothing);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      await disposeApp(tester);
    });

    testWidgets('the accepted code leaves the PIN screen for good', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), KidHomeRoutePaths.home);
      expect(
        find.byType(KidPinView),
        findsNothing,
        reason: 'a correct code replaces the stack; Back must not return here',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Entry announcements + entry limits.
  // -------------------------------------------------------------------------
  group('K02 entry announcements and limits', () {
    testWidgets('the dots count up, then announce the in-flight check', (
      tester,
    ) async {
      final stub = _PinStub()..hang = true;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      for (var i = 1; i <= 3; i++) {
        await tester.tap(find.bySemanticsLabel('Digit $i').first);
        await tester.pump();
        expect(
          find.bySemanticsLabel(RegExp('$i of 4 entered')),
          findsOneWidget,
        );
      }
      await tester.tap(find.bySemanticsLabel('Digit 4'));
      await tester.pump();
      expect(stub.verifyCalls, 1);
      expect(stub.lastPin, '1234');
      // While the check runs the dots announce the check itself, and the
      // counting label is gone (no double announcement).
      expect(
        find.bySemanticsLabel(RegExp('Checking your code')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('4 of 4 entered')), findsNothing);
      // Keys are inert mid-check: the code cannot grow past four digits.
      await tester.tap(find.bySemanticsLabel('Digit 9'));
      await tester.pump();
      expect(stub.verifyCalls, 1);
      await disposeApp(tester);
    });

    testWidgets('a wrong attempt re-arms the keypad for a fresh code', (
      tester,
    ) async {
      final stub = _PinStub()..nextOk = false;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 300));
      expect(stub.verifyCalls, 1);
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      stub.nextOk = true;
      await tester.tap(find.bySemanticsLabel('Digit 1'));
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('1 of 4 entered')), findsOneWidget);
      await _enterPin(tester, '234');
      await tester.pump(const Duration(milliseconds: 400));
      expect(stub.verifyCalls, 2);
      expect(stub.lastPin, '1234');
      expect(currentPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('a verifyPin error nudges like a wrong code, never the card', (
      tester,
    ) async {
      final stub = _PinStub()..fail = true;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), KidHomeRoutePaths.pin);
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      expect(
        find.text('Oh no! Pip got lost.'),
        findsNothing,
        reason: 'the home stream is healthy; this is not the failure card',
      );
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      // The nudge is announced (live region) — screen readers must hear it.
      final toast = tester.getSemantics(
        find.bySemanticsLabel(RegExp("That didn't work. Try again.")).first,
      );
      expect(toast.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      // Still usable: the next attempt goes through.
      stub
        ..fail = false
        ..nextOk = true;
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 400));
      expect(stub.verifyCalls, 2);
      expect(currentPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('a no-PIN child auto-advances without any verify call', (
      tester,
    ) async {
      final stub = _PinStub();
      await _patchVerify(stub);
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), KidHomeRoutePaths.home);
      expect(
        stub.verifyCalls,
        0,
        reason: 'no PIN to check: the repository auto-passes, no dispatch',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Layout invariants that hold across the shared keypad-pitch fix.
  // -------------------------------------------------------------------------
  group('K02 layout invariants', () {
    testWidgets('the screen lands on the 1_plan.md design anchors (390/1.0)', (
      tester,
    ) async {
      // With the shared keypad-grid fix on main (b1bfb4e, ORCHESTRATOR_NOTES
      // 07:13) and `fit: NestKeypadFit.shrinkWrap` at the call site, K02 is
      // pixel-exact against the design HTML again — grid x 77–313, key rows
      // 393/475/557/639, caption 731. These are the anchors `1_plan.md` lists
      // (cross-checked against the PNG by pixel scan); a regression in the
      // shared pitch or in K02's spacing fails here instead of at the UI gate.
      await _pumpRoute(tester);
      final keys = _keyFinder();
      for (var col = 0; col < 3; col++) {
        expect(
          tester.getRect(keys.at(col)).left,
          closeTo(77 + 82 * col, 2),
          reason: 'column $col',
        );
      }
      for (var row = 0; row < 4; row++) {
        // Rows 1-3 hold 1-9 (indexes 0-8); row 4 holds `0` then `Delete`.
        final index = row < 3 ? row * 3 : 9;
        expect(
          tester.getRect(keys.at(index)).top,
          closeTo(393 + 82 * row, 2),
          reason: 'row ${row + 1}',
        );
      }
      expect(
        tester.getRect(keys.at(10)).top,
        closeTo(639, 2),
        reason: 'Delete',
      );
      expect(
        tester.getRect(find.text('Forgot it? Just ask a grown-up.')).top,
        closeTo(731, 2),
      );
      expect(
        tester.getRect(find.text('Hi Maya! Enter your secret code')).top,
        closeTo(285, 2),
      );
      expect(tester.getRect(find.byType(NestPinDots)).top, closeTo(331, 2));
      expect(
        tester.getRect(find.bySemanticsLabel('Back').first).top,
        closeTo(47, 2),
      );
      expect(
        tester.getRect(find.bySemanticsLabel('Grown-ups').first).top,
        closeTo(47, 2),
      );
      await disposeApp(tester);
    });

    testWidgets('keys are centred, evenly pitched and inside the gutters', (
      tester,
    ) async {
      for (final width in const <double>[320, 390, 430]) {
        await _pumpRoute(tester, width: width);
        final keys = _keyFinder();
        final rects = <Rect>[
          for (var i = 0; i < keys.evaluate().length; i++)
            tester.getRect(keys.at(i)),
        ];
        final centre = width / 2;
        // The grid as a whole sits on the column centre (its keys are of
        // course spread across it).
        final gridLeft = rects.map((r) => r.left).reduce(math.min);
        final gridRight = rects.map((r) => r.right).reduce(math.max);
        expect(
          ((gridLeft + gridRight) / 2 - centre).abs(),
          lessThanOrEqualTo(1),
          reason: 'keypad centred at ${width}px',
        );
        for (final rect in rects) {
          expect(
            rect.left,
            greaterThanOrEqualTo(NestSpacing.padSide),
            reason: 'left gutter at ${width}px',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(width - NestSpacing.padSide),
            reason: 'right gutter at ${width}px',
          );
        }
        // Uniform row pitch (three equal steps down the four rows).
        final tops = <double>[
          rects[0].top,
          rects[3].top,
          rects[6].top,
          rects[9].top,
        ];
        final pitches = <double>[
          for (var i = 1; i < tops.length; i++) tops[i] - tops[i - 1],
        ];
        for (final pitch in pitches) {
          expect(pitch, closeTo(pitches.first, 0.5));
        }
        // Uniform column pitch within a row.
        expect(
          rects[1].left - rects[0].left,
          closeTo(rects[2].left - rects[1].left, 0.5),
        );
        expect(
          rects[10].left - rects[9].left,
          closeTo(rects[1].left - rects[0].left, 0.5),
          reason: 'row 4 keeps the same column pitch as rows 1-3',
        );
        await disposeApp(tester);
        await setUpTestScope();
      }
    });

    testWidgets('headings, pill, dots and caption share the 20 px gutters', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final markPill = find.ancestor(
        of: find.text('NESTLING'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius ==
                  BorderRadius.circular(999),
        ),
      );
      for (final finder in <Finder>[
        find.text('Hi Maya! Enter your secret code'),
        markPill,
        find.byType(NestPinDots),
        find.text('Forgot it? Just ask a grown-up.'),
        find.byType(NestKeypad),
      ]) {
        final rect = tester.getRect(finder.first);
        expect(
          (rect.center.dx - 195).abs(),
          lessThanOrEqualTo(1),
          reason: 'centred on the 390 px column: $finder',
        );
        expect(
          rect.left,
          greaterThanOrEqualTo(NestSpacing.padSide - 1),
          reason: 'left gutter: $finder',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(390 - NestSpacing.padSide + 1),
          reason: 'right gutter: $finder',
        );
      }
      // The pill keeps its CSS shape: 22 px line box + 2 px padding a side.
      expect(tester.getSize(markPill.first).height, 26);
      expect(tester.getSize(markPill.first).width, greaterThan(0));
      await disposeApp(tester);
    });

    testWidgets('the pill and the key discs are pinned as SHAPES', (
      tester,
    ) async {
      // SHAPES rule: compare the visible BACKGROUND/BORDER rect, never just
      // where the text lands (the P05 lesson). The mark pill's tinted
      // background and its pill radius are asserted here, not inferred from
      // the Text style.
      await _pumpRoute(tester);
      final tokens = NestContext(tester.element(find.text('NESTLING'))).nest;
      final pill = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('NESTLING'),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).borderRadius ==
                        BorderRadius.circular(999),
              ),
            )
            .first,
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(decoration.color, tokens.lilacTint, reason: '.mark background');
      expect(
        decoration.borderRadius,
        BorderRadius.circular(999),
        reason: '.mark border-radius',
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('NESTLING'),
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is Container &&
                          w.decoration is BoxDecoration &&
                          (w.decoration! as BoxDecoration).borderRadius ==
                              BorderRadius.circular(999),
                    ),
                  )
                  .first,
            )
            .width,
        tester.getSize(find.text('NESTLING')).width + 2 * NestSpacing.s3,
        reason: '.mark padding 0 12',
      );

      // Every key disc: 72 circle, kid ink border, kid shadow (light) —
      // the same tones for all eleven cells, blank excluded.
      final kid = NestContext(tester.element(find.byType(NestKeypad))).nestKid;
      final inks = find.descendant(
        of: find.byType(NestKeypad),
        matching: find.byType(Ink),
      );
      expect(inks, findsNWidgets(11));
      for (var i = 0; i < inks.evaluate().length; i++) {
        final box =
            (tester.widget<Ink>(inks.at(i)).decoration as BoxDecoration?)!;
        expect(box.shape, BoxShape.circle, reason: 'key $i');
        expect(tester.getSize(inks.at(i)).width, 72, reason: 'key $i');
        expect(box.color, tokens.surface, reason: 'key $i fill');
        expect(
          box.border,
          Border.all(color: tokens.ink, width: kid.borderWidth),
          reason: 'key $i kid border',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('dark mode keeps the light geometry and flips the tokens', (
      tester,
    ) async {
      Future<Map<String, Rect>> capture(ThemeMode theme) async {
        await _pumpRoute(tester, theme: theme);
        final markPill = find.ancestor(
          of: find.text('NESTLING'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).borderRadius ==
                    BorderRadius.circular(999),
          ),
        );
        return <String, Rect>{
          'back': tester.getRect(find.bySemanticsLabel('Back').first),
          'lock': tester.getRect(find.bySemanticsLabel('Grown-ups').first),
          'say': tester.getRect(find.text('Hi Maya! Enter your secret code')),
          'mark': tester.getRect(markPill.first),
          'dots': tester.getRect(find.byType(NestPinDots)),
          'keypad': tester.getRect(find.byType(NestKeypad)),
          'caption': tester.getRect(
            find.text('Forgot it? Just ask a grown-up.'),
          ),
        };
      }

      final light = await capture(ThemeMode.light);
      await disposeApp(tester);
      await setUpTestScope();
      final dark = await capture(ThemeMode.dark);
      await disposeApp(tester);
      await setUpTestScope();

      for (final key in light.keys) {
        expect(
          dark[key],
          light[key],
          reason: 'dark must not move $key (only tones differ)',
        );
      }
    });

    testWidgets('the filled/empty dot and disc tones follow the theme', (
      tester,
    ) async {
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await _pumpRoute(tester, theme: theme);
        await tester.tap(find.bySemanticsLabel('Digit 1'));
        await tester.pump();
        final dots = find.descendant(
          of: find.byType(NestPinDots),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        final filled =
            tester.widget<DecoratedBox>(dots.at(0)).decoration as BoxDecoration;
        final empty =
            tester.widget<DecoratedBox>(dots.at(1)).decoration as BoxDecoration;
        final tokens = NestContext(tester.element(find.byType(NestPinDots)))
            .nest;
        expect(filled.color, tokens.ink, reason: 'filled dot = ink');
        expect(empty.color, tokens.surface, reason: 'empty dot = surface');
        expect(
          tokens.isDark,
          theme == ThemeMode.dark,
          reason: 'the test really switched theme',
        );
        // The 128 disc paints the theme's lilac tint (one visual disc).
        final disc = find.ancestor(
          of: find.byType(NestAvatar),
          matching: find.byType(Container),
        );
        final decoration =
            tester.widget<Container>(disc.first).decoration! as BoxDecoration;
        expect(decoration.color, tokens.lilacTint);
        await disposeApp(tester);
        await setUpTestScope();
      }
    });

    testWidgets('no bottom bar: the shared meadow reaches the physical edge', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final meadow = tester.getRect(find.byType(NestMeadow).first);
      expect(meadow.height, NestMeadowGeometry.defaultHeight);
      expect(meadow.width, 390, reason: 'full width');
      expect(meadow.bottom, 844, reason: 'pinned to the physical edge');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        Colors.transparent,
        reason: 'no opaque strip may hide the meadow (BOTTOM EDGE rule)',
      );
      expect(find.byType(NestBottomCta), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the failure card shows PipAvatar, never a v1 illustration', (
      tester,
    ) async {
      final real = GetIt.instance<KidHomeRepository>();
      final stub = _PinStub()..loadFail = true;
      await GetIt.instance.unregister<KidHomeRepository>();
      GetIt.instance.registerSingleton<KidHomeRepository>(
        _WrappingRepo(real, stub),
      );
      await _pumpRoute(tester);
      expect(find.byType(PipAvatar), findsOneWidget);
      final source = _libSource(
        'features/kid_home/presentation/views/kid_pin_view.dart',
      ).readAsStringSync();
      expect(source.contains('pip_stage_'), isFalse);
      expect(source.contains('google_fonts'), isFalse);
      expect(source.contains('GoogleFonts'), isFalse);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // COPY — the design bytes are READ from `K02-pin.html`, never transcribed,
  // so this group can never approve whatever the app happens to draw.
  // -------------------------------------------------------------------------
  group('K02 design-copy parity', () {
    testWidgets('mark, greeting and caption are the design bytes', (
      tester,
    ) async {
      final html = _designSource('K02-pin.html').readAsStringSync();
      final mark = _decodeEntities(
        _capture(html, '<div class="mark">([^<]*)</div>'),
      );
      final say = _decodeEntities(
        _capture(html, '<div class="say">([^<]*)</div>'),
      );
      final caption = _decodeEntities(
        _capture(html, '<p class="kcap"[^>]*>([^<]*)</p>'),
      );

      // The greeting's name is DB-driven (DATA OVER MOCKS); every other byte
      // has to match the source exactly.
      KidChild? child;
      await tester.runAsync(() async {
        child = await GetIt.instance<KidHomeRepository>()
            .watchActiveChild()
            .first;
      });
      await _pumpRoute(tester);
      expect(find.text(mark), findsOneWidget);
      expect(
        find.text(say.replaceFirst('Maya', child!.nickname)),
        findsOneWidget,
      );
      expect(find.text(caption), findsOneWidget);
      // K02's copy is plain ASCII in the design, so a curly apostrophe or
      // en dash anywhere on this screen is a drift from the source.
      for (final rendered in <String>[
        mark,
        say.replaceFirst('Maya', child!.nickname),
        caption,
      ]) {
        expect(
          rendered.runes.every((rune) => rune < 0x80),
          isTrue,
          reason: 'design copy is ASCII: "$rendered"',
        );
      }
      // The design carries no error copy: the wrong-code nudge is app-only.
      expect(html.contains('try again'), isFalse);
      await disposeApp(tester);
    });

    testWidgets('the icon-button labels are the design aria-labels', (
      tester,
    ) async {
      final html = _designSource('K02-pin.html').readAsStringSync();
      await _pumpRoute(tester);
      for (final label in const <String>['Back', 'Grown-ups', 'Delete']) {
        expect(
          html.contains('aria-label="$label"'),
          isTrue,
          reason: 'design aria-label for $label',
        );
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 2 — the FIXES_1 build. Each of these pins what a fix PROMISES,
  // so a regression lands here instead of at the UI gate:
  //   * K02-BUG-2's `maxLines: 3` must not reflow the design's single line;
  //   * review #4's `_BottomInset` must honour the real inset in all three
  //     fallback states, with the 34 px design floor;
  //   * SHARED_REQUEST #1 (`NestType.kidSay` / `kidMark`) must land without
  //     moving a metric or the one letter-spacing case K02 owns.
  // -------------------------------------------------------------------------
  group('K02 iteration 2 fixes', () {
    testWidgets('the greeting keeps the design single line at 390/1.0', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final greeting = find.text('Hi Maya! Enter your secret code');
      // The design's `.say` is one 26 px line for the seeded nickname.
      expect(
        tester.getSize(greeting).height,
        closeTo(26, 1),
        reason: 'one line, not two',
      );
      expect(
        tester.renderObject<RenderParagraph>(greeting).didExceedMaxLines,
        isFalse,
      );
      // K02-BUG-2's fix stays: the cap is 3, so a long name cannot be cut.
      expect(tester.widget<Text>(greeting).maxLines, 3);
      await disposeApp(tester);
    });

    testWidgets('the longest legal nickname is never clipped', (tester) async {
      // P05 accepts 24 characters; at the narrowest width and the largest
      // accessibility scale the sentence must still fit inside the cap.
      // `setUpTestScope` re-seeds the demo DB, so the nickname is re-applied
      // on every pass of the matrix.
      Future<void> useLongName() async {
        await tester.runAsync(() async {
          final db = GetIt.instance<AppDatabase>();
          await (db.update(
            db.children,
          )..where((c) => c.id.equals('maya'))).write(
            const ChildrenCompanion(nickname: Value('Maximilian-Alexander-Jr')),
          );
          await GetIt.instance<AppSession>().refresh();
        });
      }

      const greeting = 'Hi Maximilian-Alexander-Jr! Enter your secret code';
      for (final width in const <double>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          await useLongName();
          await _pumpRoute(tester, width: width, textScale: scale);
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(greeting))
                .didExceedMaxLines,
            isFalse,
            reason: 'nickname must not be cut at ${width.toInt()}px / $scale',
          );
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
          await setUpTestScope();
        }
      }
    });

    testWidgets('only .mark carries tracking, and both type styles match CSS', (
      tester,
    ) async {
      await _pumpRoute(tester);
      // LETTER SPACING (orchestrator known case): `.mark` is 1.28 at the call
      // site, every other string is 0. Sweeping the whole visible text tree
      // catches a stray tracking value anywhere on the screen.
      final tracked = <double, List<String>>{};
      for (final element in find.byType(Text).evaluate()) {
        final text = element.widget as Text;
        final spacing = text.style?.letterSpacing;
        if (spacing == null) continue;
        tracked
            .putIfAbsent(spacing, () => <String>[])
            .add(text.data ?? '<rich text>');
      }
      expect(tracked.keys, everyElement(anyOf(0, 1.28)));
      expect(tracked[1.28], <String>[
        'NESTLING',
      ], reason: '1.28 belongs to .mark only (.08em x 16)');

      // SHARED_REQUEST #1: `NestType.kidSay` / `NestType.kidMark` are still
      // open, so the local call-site styles are pinned to the CSS metrics —
      // landing the shared entries must not move a single number.
      final mark = tester.widget<Text>(find.text('NESTLING')).style!;
      expect(mark.fontFamily, 'Nunito');
      expect(mark.fontWeight, FontWeight.w900, reason: '.mark weight');
      expect(mark.fontSize, 16);
      expect(mark.height, closeTo(22 / 16, 0.001), reason: '.mark 16/22');
      final say = tester
          .widget<Text>(find.text('Hi Maya! Enter your secret code'))
          .style!;
      expect(say.fontFamily, 'Nunito');
      expect(say.fontWeight, FontWeight.w800, reason: '.say weight');
      expect(say.fontSize, 20);
      expect(say.height, closeTo(26 / 20, 0.001), reason: '.say 20/26');
      expect(say.letterSpacing, 0);
      await disposeApp(tester);
    });

    testWidgets('the loading state reserves the real bottom inset', (
      tester,
    ) async {
      final measured = await _insetProbes(
        tester,
        prepare: (_) => _registerRepo(_PinStub()..hangLoad = true),
        probe: find.byType(CircularProgressIndicator),
      );
      _expectInsetFloor(measured);
    });

    testWidgets('the failure card reserves the real bottom inset', (
      tester,
    ) async {
      final measured = await _insetProbes(
        tester,
        prepare: (_) => _registerRepo(_PinStub()..loadFail = true),
        probe: find.text('Try again'),
      );
      _expectInsetFloor(measured);
    });

    testWidgets('the chooser reserves the real bottom inset', (tester) async {
      final measured = await _insetProbes(
        tester,
        // `setUp` already seeded the scope; only the active-child pointer
        // has to change (a null child renders the chooser).
        prepare: (tester) async {
          final db = GetIt.instance<AppDatabase>();
          await tester.runAsync(() async {
            await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
              const AppStateCompanion(activeChildId: Value<String?>(null)),
            );
            await GetIt.instance<AppSession>().refresh();
          });
        },
        probe: find.text('Choose'),
      );
      _expectInsetFloor(measured);
    });

    testWidgets('a wrong-code nudge cannot outlive the successful retry', (
      tester,
    ) async {
      final stub = _PinStub()..nextOk = false;
      await _patchVerify(stub);
      await _pumpRoute(tester);
      await _enterPin(tester, '9999');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      stub.nextOk = true;
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), KidHomeRoutePaths.home);
      expect(
        find.text("That didn't work. Try again."),
        findsNothing,
        reason: 'the child must not read "try again" after the code worked',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 3 — K02-BUG-5's fix: the no-PIN auto-advance latch is released
  // on the DECLINE path. Two promises, tested here from a fresh harness:
  //   * while a PIN-protected child is active nothing may navigate (the
  //     release must not become a bypass — K02-BUG-3's protection), and the
  //     PIN screen stays fully interactive;
  //   * a no-PIN child that comes back afterwards really does advance.
  //
  // The pair fake is needed because the decline only happens when the two
  // children swap inside one frame, which real awaited writes cannot do.
  // -------------------------------------------------------------------------
  group('K02 iteration 3 fixes', () {
    testWidgets('a declined auto-advance leaves a live PIN screen', (
      tester,
    ) async {
      final roster = await _seededRoster(tester);
      final fake = _PairRepo();
      await _useRepo(fake);
      await _pumpRoute(tester);
      // Leo (no PIN) then Maya (PIN) in one turn: the post-frame re-check
      // declines, so K02 must stay on the PIN screen.
      fake
        ..emit(roster.leo)
        ..emit(roster.maya);
      await _settleK02(tester);
      expect(currentPath(tester), KidHomeRoutePaths.pin);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      expect(find.byType(NestKeypad), findsOneWidget);
      // Several frames later nothing may have navigated by itself: releasing
      // the latch must never let a PIN child through.
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        currentPath(tester),
        KidHomeRoutePaths.pin,
        reason: 'a released latch must not become a PIN bypass',
      );
      // And the screen the fix left behind is fully interactive.
      await _enterPin(tester, '9999');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      await _enterPin(tester, '1234');
      await _settleK02(tester);
      expect(currentPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('the released latch advances the returning no-PIN child', (
      tester,
    ) async {
      final roster = await _seededRoster(tester);
      final fake = _PairRepo();
      await _useRepo(fake);
      await _pumpRoute(tester);
      fake
        ..emit(roster.leo)
        ..emit(roster.maya); // declined
      await _settleK02(tester);
      expect(currentPath(tester), KidHomeRoutePaths.pin);
      fake.emit(roster.leo); // the no-PIN child comes back
      await _settleK02(tester);
      expect(
        currentPath(tester),
        KidHomeRoutePaths.home,
        reason: 'the decline must not latch the auto-advance off forever',
      );
      // K02's own loader must be gone — not K03's transient one, which is
      // why this checks the K02-specific label rather than a spinner.
      expect(find.bySemanticsLabel('Loading your secret code'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('repeated alternation never advances a PIN child', (
      tester,
    ) async {
      final roster = await _seededRoster(tester);
      final fake = _PairRepo();
      await _useRepo(fake);
      await _pumpRoute(tester);
      for (var i = 0; i < 3; i++) {
        fake
          ..emit(roster.leo)
          ..emit(roster.maya);
        await _settleK02(tester);
        expect(
          currentPath(tester),
          KidHomeRoutePaths.pin,
          reason: 'pass $i must keep the PIN screen',
        );
      }
      fake.emit(roster.leo);
      await _settleK02(tester);
      expect(currentPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });
  });
}

/// The eleven announced keypad controls, in tree order
/// (1-9, then `0`, then `Delete`; the blank cell is excluded).
Finder _keyFinder() => find.descendant(
  of: find.byType(NestKeypad),
  matching: find.bySemanticsLabel(RegExp(r'^(Digit [0-9]|Delete)$')),
);

/// Settles without `pumpAndSettle`: the destination screens can carry an
/// infinite `CircularProgressIndicator`, which would never settle. Two
/// round-trips are enough for a post-frame navigation *and* for the outgoing
/// route to finish its transition and leave the tree — which matters when the
/// assertion is "the previous screen's fallback is gone".
Future<void> _settleK02(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// The seeded roster as real rows (Maya: PIN `1234`, Leo: no PIN), read once
/// through the real repository before a fake takes its place.
Future<({KidChild maya, KidChild leo})> _seededRoster(
  WidgetTester tester,
) async {
  late List<KidChild> profiles;
  await tester.runAsync(() async {
    profiles = await GetIt.instance<KidHomeRepository>().watchProfiles().first;
  });
  return (
    maya: profiles.firstWhere((c) => c.id == 'maya'),
    leo: profiles.firstWhere((c) => c.id == 'leo'),
  );
}

/// Hands a hand-written repository to the app for this test.
Future<void> _useRepo(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Scripted home stream: the test pushes whole `KidHomeData` snapshots in one
/// turn, which is the only way to reproduce the no-PIN → PIN swap that the
/// post-frame re-check has to decline (real awaited writes cannot land two
/// children inside one frame). `verifyPin` mirrors the seed: Maya's code is
/// `1234`, Leo has no code at all.
class _PairRepo implements KidHomeRepository {
  final StreamController<KidHomeData> home =
      StreamController<KidHomeData>.broadcast();

  /// Pushes one home snapshot for [child] (no quests, no ledger).
  void emit(KidChild child) => home.add(KidHomeData(child: child));

  @override
  Stream<KidHomeData> watchHome() => home.stream;

  @override
  Stream<KidChild?> watchActiveChild() => home.stream.map((h) => h.child);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      const Stream<List<KidChild>>.empty();

  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Future<bool> verifyPin(String childId, String pin) async => pin == '1234';

  @override
  List<String> stepsFor(String questId) => const <String>[];

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// Registers [stub] as the app's `KidHomeRepository` for this test.
Future<void> _registerRepo(_PinStub stub) async {
  final real = GetIt.instance<KidHomeRepository>();
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(
    _WrappingRepo(real, stub),
  );
}

/// Review #4: the fallback states reserve `max(viewPadding.bottom, 34)` — the
/// real inset with the design's 34 px floor. [prepare] runs ONCE (before any
/// pump: a Drift write inside `tester.runAsync` after a fresh `setUpTestScope`
/// never completes, because the scope's own pending work is fake-async), then
/// `/kid-pin` is pumped three times with a bottom inset of 20, 34 and 60
/// logical px and the [probe]'s vertical centre is measured each time.
///
/// The scope deliberately survives between measurements — the screen is
/// re-pumped, not re-seeded, so what is compared is purely the inset.
Future<Map<double, double>> _insetProbes(
  WidgetTester tester, {
  required Future<void> Function(WidgetTester tester) prepare,
  required Finder probe,
}) async {
  await prepare(tester);
  final measured = <double, double>{};
  for (final inset in const <double>[20, 34, 60]) {
    await _pumpRoute(tester);
    final physical = inset * 3;
    tester.view.padding = FakeViewPadding(bottom: physical);
    tester.view.viewPadding = FakeViewPadding(bottom: physical);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    measured[inset] = tester.getRect(probe.first).center.dy;
    // BOTTOM EDGE: whatever the inset, the shared meadow keeps reaching the
    // physical edge — no strip may appear below the fallback content.
    expect(
      tester.getRect(find.byType(NestMeadow).first).bottom,
      844,
      reason: 'meadow pinned to the physical edge at inset $inset',
    );
    await disposeApp(tester);
  }
  addTearDown(() {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
  });
  return measured;
}

/// The two assertions every `_insetProbes` measurement must satisfy: below the
/// 34 px floor the layout does not move, above it the centred block follows
/// the real inset exactly (half of the extra reserve, the block being
/// centred).
void _expectInsetFloor(Map<double, double> measured) {
  expect(measured[20], closeTo(measured[34]!, 0.5));
  expect(measured[60], closeTo(measured[34]! - 13, 1));
}

/// The design source for [name], located by walking up from the package root.
File _designSource(String name) {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File('${dir.path}/design/html-source/screens/$name');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/$name not found above '
    '${Directory.current.path}',
  );
}

/// A `lib/` source file, located the same way.
File _libSource(String relative) {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File('${dir.path}/lib/$relative');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('lib/$relative not found above ${Directory.current.path}');
}

/// First capture group of [pattern] in [source] — fails loudly when the
/// design markup changes shape (the copy must never be transcribed here).
String _capture(String source, String pattern) {
  final match = RegExp(pattern).firstMatch(source);
  if (match == null) {
    throw StateError('design source no longer matches /$pattern/');
  }
  return match.group(1)!;
}

const Map<String, String> _htmlEntities = <String, String>{
  '&ndash;': '–',
  '&mdash;': '—',
  '&rsquo;': '’',
  '&lsquo;': '‘',
  '&ldquo;': '“',
  '&rdquo;': '”',
  '&hellip;': '…',
  '&nbsp;': ' ',
  '&middot;': '·',
  '&amp;': '&',
  '&quot;': '"',
  '&lt;': '<',
  '&gt;': '>',
  '&#9003;': '⌫',
};

String _decodeEntities(String raw) {
  var out = raw;
  _htmlEntities.forEach((entity, character) {
    out = out.replaceAll(entity, character);
  });
  return out;
}
