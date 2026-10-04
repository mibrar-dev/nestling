// K02 Kid PIN (`/kid-pin`) view tests: layout matrix, design geometry,
// semantics actions, PIN submit outcomes, no-PIN auto-advance, and the
// loading/failure states. Every pumped app ends with `disposeApp`.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';

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
  });
}
