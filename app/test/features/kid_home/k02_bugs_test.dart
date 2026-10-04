// K02 (Kid PIN, `/kid-pin`) adversarial suite — Stage 6 bug hunt, iteration 2.
//
// K02-BUG-1..5 are all FIXED and run un-skipped in the plain suite as
// regressions (K02-BUG-5 is the iteration-2 build's no-PIN latch; its fix
// releases the latch on the declined path). Nothing is parked here any more —
// if a future proof is parked with `skip: true`, it carries its bug id in the
// test description (Flutter's `testWidgets` takes a `bool?` skip, so the id
// cannot live in the skip argument) and runs with:
//
//   flutter test test/features/kid_home/k02_bugs_test.dart --run-skipped \
//     --plain-name K02-BUG
//
// Everything else in this file runs in the plain suite as evidence for the
// categories checked clean: 0/1/6 children, long names, money values, rapid
// double taps (digits/back/lock), deep links and back navigation, restart
// persistence, mode guards, dark contrast, 320 px + 1.3 scale overflow,
// async gaps, BST/GMT clock independence, the shared keypad grid and
// accessibility actions.
//
// Findings and suggested fixes: docs/screens/K02/6_bugs.md.

import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/pin_hash.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps the full app at [route] with optional kid mode / width / scale.
Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-pin',
  bool kidMode = true,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<AppModeController>().selectMode(
    kidMode ? AppMode.kid : AppMode.parent,
  );
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Settles route transitions and pending Drift emissions.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _enter(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).last);
    await tester.pump();
  }
}

/// Loads the bundled faces so text metrics match a device run (same shape as
/// `kid_pin_view_test.dart`); without it wrapped-line pins drift.
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

Future<void> _setNickname(String childId, String nickname) async {
  final db = GetIt.instance<AppDatabase>();
  await (db.update(db.children)..where((c) => c.id.equals(childId))).write(
    ChildrenCompanion(nickname: Value(nickname)),
  );
}

Future<void> _setActive(String? id) async {
  final db = GetIt.instance<AppDatabase>();
  await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
    AppStateCompanion(activeChildId: Value<String?>(id)),
  );
  await GetIt.instance<AppSession>().refresh();
}

/// Inserts an extra child (optionally PIN-protected) into the seeded family.
Future<void> _insertChild(
  String id,
  String nickname, {
  String? pin,
  String ageBand = '7-9',
}) async {
  final db = GetIt.instance<AppDatabase>();
  await db
      .into(db.children)
      .insert(
        ChildrenCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          nickname: nickname,
          ageBand: Value(ageBand),
          avatarColour: const Value('sky'),
          pinHash: pin == null ? const Value.absent() : Value(hashPin(pin)),
        ),
      );
}

/// Seeds [name] as Maya's nickname, pumps the PIN screen and asserts the
/// avatar initial is whole and crash-free. One cycle per test: chaining
/// several `runAsync` cycles inside a single `testWidgets` deadlocks the
/// binding's runAsync lock (learned the hard way in this file).
Future<void> _assertInitial(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    await _setNickname('maya', name);
    await GetIt.instance<AppSession>().refresh();
  });
  await _pump(tester);
  final avatar = tester.widget<NestAvatar>(find.byType(NestAvatar));
  expect(avatar.initial, isNotEmpty, reason: 'blank initial for "$name"');
  expect(
    tester.takeException(),
    isNull,
    reason: 'the initial for "$name" must not throw',
  );
  await disposeApp(tester);
}

/// The visible `Text` strings, sorted — a cheap whole-screen text snapshot.
List<String> _texts(WidgetTester tester) {
  final data =
      tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList()
        ..sort();
  return data;
}

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Swaps the registered repository for a feature-local fake.
Future<void> _useFake(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

const _leo = KidChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '4-6',
  avatarColour: 'peach',
  coins: 45,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  happiness: 0,
  pinSet: false,
);

const _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 0,
  pinSet: true,
);

/// K02-BUG-3 fake: a controllable home stream. Adding a no-PIN child and then
/// a PIN child in the same event-loop turn reproduces the auto-advance race.
class _StreamPairRepo implements KidHomeRepository {
  final StreamController<KidHomeData> home =
      StreamController<KidHomeData>.broadcast();
  bool hangVerify = false;

  @override
  Stream<KidHomeData> watchHome() => home.stream;

  @override
  Future<bool> verifyPin(String childId, String pin) async {
    if (hangVerify) await Completer<bool>().future;
    return pin == '1234';
  }

  @override
  Stream<KidChild?> watchActiveChild() => home.stream.map((h) => h.child);

  @override
  Stream<List<KidChild>> watchProfiles() => const Stream.empty();

  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream.empty();

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}

  @override
  List<String> stepsFor(String questId) => const <String>[];
}

/// Always-failing home stream: renders K02's failure card.
class _FailingHomeRepo implements KidHomeRepository {
  _FailingHomeRepo(this._real);

  final KidHomeRepository _real;

  @override
  Stream<KidHomeData> watchHome() =>
      Stream<KidHomeData>.error(Exception('home down'));

  @override
  Future<bool> verifyPin(String childId, String pin) =>
      _real.verifyPin(childId, pin);

  @override
  Stream<KidChild?> watchActiveChild() => _real.watchActiveChild();

  @override
  Stream<List<KidChild>> watchProfiles() => _real.watchProfiles();

  @override
  Future<List<KidQuest>> getItems() => _real.getItems();

  @override
  Stream<List<KidQuest>> watchItems() => _real.watchItems();

  @override
  Future<void> setActiveChild(String childId) => _real.setActiveChild(childId);

  @override
  Future<void> completeQuest(String childId, String questId) =>
      _real.completeQuest(childId, questId);

  @override
  List<String> stepsFor(String questId) => _real.stepsFor(questId);
}

/// Fails the first home stream, then delegates to the real repository — the
/// failure card's `Try again` recovery path.
class _FailOnceHomeRepo implements KidHomeRepository {
  _FailOnceHomeRepo(this._real);

  final KidHomeRepository _real;
  int homeCalls = 0;

  @override
  Stream<KidHomeData> watchHome() {
    homeCalls += 1;
    if (homeCalls == 1) {
      return Stream<KidHomeData>.error(Exception('home down'));
    }
    return _real.watchHome();
  }

  @override
  Future<bool> verifyPin(String childId, String pin) =>
      _real.verifyPin(childId, pin);

  @override
  Stream<KidChild?> watchActiveChild() => _real.watchActiveChild();

  @override
  Stream<List<KidChild>> watchProfiles() => _real.watchProfiles();

  @override
  Future<List<KidQuest>> getItems() => _real.getItems();

  @override
  Stream<List<KidQuest>> watchItems() => _real.watchItems();

  @override
  Future<void> setActiveChild(String childId) => _real.setActiveChild(childId);

  @override
  Future<void> completeQuest(String childId, String questId) =>
      _real.completeQuest(childId, questId);

  @override
  List<String> stepsFor(String questId) => _real.stepsFor(questId);
}

void main() {
  setUp(() async {
    await _loadBundledFonts();
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K02-BUG-1 — major — FIXED iteration 2 — regression proof (un-skipped)
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-1 regression: an emoji-leading nickname renders its whole '
    'initial',
    (tester) async {
      await tester.runAsync(() async {
        await _setNickname('maya', '🐝 Bee');
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);
      final avatar = tester.widget<NestAvatar>(find.byType(NestAvatar));
      // The screen must render a whole first character with no exception.
      expect(
        tester.takeException(),
        isNull,
        reason: 'a non-BMP first character must not throw during text layout',
      );
      expect(
        avatar.initial,
        '🐝',
        reason: 'the initial must be the first rune, not half a surrogate pair',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K02-BUG-2 — minor — FIXED iteration 2 — regression proof (un-skipped)
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-2 regression: a 20-char nickname fits at 320 px + 1.3 scale',
    (tester) async {
      await tester.runAsync(() async {
        await _setNickname('maya', 'Maximilian-Alexander');
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester, width: 320, textScale: 1.3);
      const greeting = 'Hi Maximilian-Alexander! Enter your secret code';
      final para = tester.renderObject<RenderParagraph>(find.text(greeting));
      expect(
        para.didExceedMaxLines,
        isFalse,
        reason:
            'the greeting must not silently drop the end of the sentence on '
            'a 320 px screen at the 1.3 accessibility scale',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K02-BUG-3 — minor — FIXED iteration 2 — regression proof (un-skipped)
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-3 regression: a no-PIN child then a PIN child keeps the PIN '
    'screen',
    (tester) async {
      final fake = _StreamPairRepo();
      await _useFake(fake);
      await _pump(tester);
      // Two emissions in one event-loop turn: no-PIN Leo, then PIN'd Maya.
      fake.home.add(const KidHomeData(child: _leo));
      fake.home.add(const KidHomeData(child: _maya));
      await _settle(tester);
      expect(
        currentPath(tester),
        '/kid-pin',
        reason: 'Maya has a PIN; the screen must stay and ask for it',
      );
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K02-BUG-4 — minor — FIXED iteration 2 — regression proof (un-skipped)
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-4 regression: the wrong-code toast is gone after a correct '
    'retry',
    (tester) async {
      await _pump(tester);
      await _enter(tester, '9999');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      await _enter(tester, '1234');
      await _settle(tester);
      expect(currentPath(tester), '/kid-home');
      expect(
        find.text("That didn't work. Try again."),
        findsNothing,
        reason: 'the failure toast must not outlive the successful retry',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K02-BUG-5 — minor (latent) — the no-PIN latch is never released when its
  // navigation is declined (introduced by the iteration-2 fix for K02-BUG-3)
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-5: a no-PIN child after a PIN child is stuck on the loading '
    'spinner',
    (tester) async {
      final fake = _StreamPairRepo();
      await _useFake(fake);
      await _pump(tester);
      // First pair: the re-check declines the no-PIN navigation (BUG-3 fix).
      fake.home.add(const KidHomeData(child: _leo));
      fake.home.add(const KidHomeData(child: _maya));
      await _settle(tester);
      expect(currentPath(tester), '/kid-pin');
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      // The no-PIN child returns: the latch must release and advance.
      fake.home.add(const KidHomeData(child: _leo));
      await _settle(tester);
      expect(
        currentPath(tester),
        '/kid-home',
        reason:
            'a declined no-PIN navigation must not latch the auto-advance '
            'off forever',
      );
      // The PIN screen must be gone: its `_KidLoading` spinner (the
      // K02-local fallback for a no-PIN child) must not be hanging around.
      // Note: `/kid-home` gets a fresh bloc from the DI factory, and the
      // pair fake's broadcast-stream has already emitted leo, so K03's own
      // transient `_KidLoading` can legitimately remain under this harness —
      // the K02-side regression is what this assertion pins.
      expect(find.bySemanticsLabel('Loading your secret code'), findsNothing);
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K02-BUG-5 extension — the release must also work for a null-child decline
  // -------------------------------------------------------------------------

  testWidgets(
    'K02-BUG-5 extension: a null-child decline still releases the latch',
    (tester) async {
      final fake = _StreamPairRepo();
      await _useFake(fake);
      await _pump(tester);
      // No-PIN Leo schedules the advance; a null child declines it.
      fake.home.add(const KidHomeData(child: _leo));
      fake.home.add(const KidHomeData(child: null));
      await _settle(tester);
      expect(currentPath(tester), '/kid-pin');
      expect(find.text("Who's playing?"), findsOneWidget);
      // Leo returns: the released latch must let the auto-advance run again.
      fake.home.add(const KidHomeData(child: _leo));
      await _settle(tester);
      expect(
        currentPath(tester),
        '/kid-home',
        reason: 'a null-child decline must release the no-PIN latch too',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // Data edges (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 data edges (probes)', () {
    testWidgets('0 children: chooser renders; Choose taps through to K01', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await Seed.empty(GetIt.instance<AppDatabase>());
        await GetIt.instance<AppSession>().refresh();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await _pump(tester);
      await _settle(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      final choose = tester.getSemantics(find.text('Choose'));
      expect(choose.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      choose.owner!.performAction(choose.id, SemanticsAction.tap);
      await _settle(tester);
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('1 child: the PIN screen shows that child only', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      expect(find.byType(NestAvatar), findsOneWidget);
      expect(find.textContaining('Leo'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('6 children: only the active child renders; no roster leak', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await _insertChild('extra$i', 'Extra $i', pin: '1234');
        }
        await _setActive('extra2');
      });
      await _pump(tester);
      expect(find.text('Hi Extra 2! Enter your secret code'), findsOneWidget);
      expect(find.byType(NestAvatar), findsOneWidget);
      expect(find.textContaining('Extra 0'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a 20-char UK name fits at 390/1.0, 390/1.3 and 320/1.0', (
      tester,
    ) async {
      const greeting = 'Hi Maximilian-Alexander! Enter your secret code';
      for (final (double width, double scale) in const <(double, double)>[
        (390, 1),
        (390, 1.3),
        (320, 1),
      ]) {
        // Every cycle is COMPLETE: fresh GetIt scope + re-seeded DB, the
        // nickname re-applied inside `runAsync`, then pump and dispose. A
        // cycle that reuses the previous scope leaves AppSession's live Drift
        // watch pending in the fake-async queue, and the NEXT test's
        // `tester.runAsync` then waits on that queue forever — which is how
        // this file used to hang for an hour (ORCHESTRATOR_NOTES 10:32).
        await setUpTestScope();
        await tester.runAsync(() async {
          await _setNickname('maya', 'Maximilian-Alexander');
          await GetIt.instance<AppSession>().refresh();
        });
        await _pump(tester, width: width, textScale: scale);
        final para = tester.renderObject<RenderParagraph>(find.text(greeting));
        expect(
          para.didExceedMaxLines,
          isFalse,
          reason: 'greeting clipped at ${width.toInt()}px scale $scale',
        );
        await disposeApp(tester);
      }
    });

    testWidgets('a 24-char UK name (P05 max) fits at 320/1.3 and 390/1.3', (
      tester,
    ) async {
      const greeting = 'Hi Maximilian-Alexander-XX! Enter your secret code';
      for (final (double width, double scale) in const <(double, double)>[
        (320, 1.3),
        (390, 1.3),
      ]) {
        // Complete cycle per pass — see the note in the 20-char test above.
        await setUpTestScope();
        await tester.runAsync(() async {
          await _setNickname('maya', 'Maximilian-Alexander-XX');
          await GetIt.instance<AppSession>().refresh();
        });
        await _pump(tester, width: width, textScale: scale);
        final para = tester.renderObject<RenderParagraph>(find.text(greeting));
        expect(
          para.didExceedMaxLines,
          isFalse,
          reason: '24-char name clipped at ${width.toInt()}px scale $scale',
        );
        await disposeApp(tester);
      }
    });

    testWidgets('non-BMP and composed initials render whole and crash-free', (
      tester,
    ) async {
      // One cycle per test: several runAsync→pump→dispose cycles inside a
      // single testWidgets deadlocks the binding (reentrant runAsync lock).
      await _assertInitial(tester, '🇬🇧 Ben');
    });

    testWidgets('an astral math initial renders whole and crash-free', (
      tester,
    ) async {
      await _assertInitial(tester, '𝒜da');
    });

    testWidgets('a composed Latin initial renders whole and crash-free', (
      tester,
    ) async {
      await _assertInitial(tester, 'Åsa');
    });

    testWidgets('9999 coins / 999.99 base never leak onto the PIN screen', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(
            coins: Value(9999),
            weeklyBasePence: Value(99999),
          ),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester);
      expect(find.textContaining('£'), findsNothing);
      expect(find.textContaining('9999'), findsNothing);
      expect(find.textContaining('999.99'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Shared keypad grid (probe — pass): ORCHESTRATOR_NOTES 07:13 follow-up
  // -------------------------------------------------------------------------

  group('K02 shared keypad grid (probe)', () {
    testWidgets('key circles match the design grid at 390', (tester) async {
      await _pump(tester);
      final circles = find.descendant(
        of: find.byType(NestKeypad),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Ink &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      // 11 keys: 1..9, 0, delete (the blank slot paints no circle).
      expect(circles, findsNWidgets(11));
      final rects = <Rect>[
        for (var i = 0; i < 11; i++) tester.getRect(circles.at(i)),
      ];
      for (final rect in rects) {
        expect(rect.width, 72);
        expect(rect.height, 72);
      }
      // Columns 1/2/3 centres: design 113 / 195 / 277.
      expect(rects[0].center.dx, closeTo(113, 0.5));
      expect(rects[1].center.dx, closeTo(195, 0.5));
      expect(rects[2].center.dx, closeTo(277, 0.5));
      // Row tops: design 393 / 475 / 557 / 639.
      expect(rects[0].top, closeTo(393, 0.5));
      expect(rects[3].top, closeTo(475, 0.5));
      expect(rects[6].top, closeTo(557, 0.5));
      expect(rects[9].top, closeTo(639, 0.5));
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Rapid double taps (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 taps (probes)', () {
    testWidgets('rapid double-tap Back on a pushed PIN route returns once', (
      tester,
    ) async {
      await _pump(tester, route: '/who-is-playing');
      await tester.tap(find.byKey(const ValueKey<String>('k01-tile-maya')));
      // Tile taps run a real Drift write (harness note: drain with runAsync).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await _settle(tester);
      expect(pushedPath(tester), '/kid-pin');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      final second = find.bySemanticsLabel('Back');
      if (second.evaluate().isNotEmpty) {
        await tester.tap(second, warnIfMissed: false);
      }
      await _settle(tester);
      expect(pushedPath(tester), '/who-is-playing');
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Back-then-lock burst cannot stack a gate over the picker', (
      tester,
    ) async {
      await _pump(tester, route: '/who-is-playing');
      await tester.tap(find.byKey(const ValueKey<String>('k01-tile-maya')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await _settle(tester);
      expect(pushedPath(tester), '/kid-pin');
      await tester.tap(find.bySemanticsLabel('Back'));
      final lock = find.bySemanticsLabel('Grown-ups');
      if (lock.evaluate().isNotEmpty) {
        await tester.tap(lock, warnIfMissed: false);
      }
      await _settle(tester);
      expect(pushedPath(tester), '/who-is-playing');
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('rapid lock double-tap opens exactly one gate', (tester) async {
      await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settle(tester);
      expect(pushedPath(tester), '/parental-gate');
      // P17's gate has no AppBar back button since the P17 merge — its only
      // exit is the 56 px ghost `Back to Pip`, which is what a kid taps.
      // `pageBack()` finds no back button and throws.
      final backToPip = find.text('Back to Pip');
      if (backToPip.evaluate().isNotEmpty) {
        await tester.tap(backToPip);
      } else {
        await tester.pageBack();
      }
      await _settle(tester);
      expect(
        pushedPath(tester),
        '/kid-pin',
        reason: 'one exit must land back on the PIN screen, not a second gate',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Back navigation + deep links (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 back nav + deep links (probes)', () {
    testWidgets('deep-link Back goes to the picker', (tester) async {
      await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a passed PIN cannot be popped back to', (tester) async {
      await _pump(tester);
      await _enter(tester, '1234');
      await _settle(tester);
      expect(currentPath(tester), '/kid-home');
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(
        currentPath(tester),
        '/kid-home',
        reason: 'system back must not resurrect the PIN screen',
      );
      expect(find.text('Hi Maya! Enter your secret code'), findsNothing);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Restart persistence (probe — pass)
  // -------------------------------------------------------------------------

  group('K02 restart (probe)', () {
    testWidgets('restart after a wrong attempt resets dots but keeps the PIN', (
      tester,
    ) async {
      await _pump(tester);
      await _enter(tester, '9999');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      await disposeApp(tester);
      // A restart: a fresh app instance on a freshly seeded scope (Maya still
      // has PIN 1234). Re-seeding also keeps AppSession's watch from carrying
      // pending fake-async work into the next cycle — see ORCHESTRATOR_NOTES
      // (10:32) on the hour-long hang this file had.
      await setUpTestScope();
      await tester.pumpWidget(const NestlingApp(initialRoute: '/kid-pin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel(RegExp('0 of 4 entered')), findsOneWidget);
      expect(find.text("That didn't work. Try again."), findsNothing);
      await _enter(tester, '1234');
      await _settle(tester);
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Mode guard (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 mode guard (probes)', () {
    testWidgets('the lock opens the parental gate from the failure state', (
      tester,
    ) async {
      final real = GetIt.instance<KidHomeRepository>();
      await _useFake(_FailingHomeRepo(real));
      await _pump(tester);
      await _settle(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      final lock = find.byType(NestLockButton);
      expect(lock, findsOneWidget);
      final node = tester.getSemantics(lock);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(lock);
      await _settle(tester);
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('parent-mode deep link renders K02; Back lands on the picker', (
      tester,
    ) async {
      // Observed product-level behaviour (matches K01/K03 notes): kid
      // locations are reachable in parent mode; the router guards the
      // opposite direction (kid mode -> parent-only stops at the gate).
      await _pump(tester, kidMode: false);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('kid mode + expired trial: /kid-pin lands on the gate', (
      tester,
    ) async {
      // Shared kid_trial_gate ruling: in kid mode an expired trial sends
      // every location to the gate (no paywall, no redirect loop). The
      // status is driven through AppSession, never written directly.
      await tester.runAsync(() async {
        final session = GetIt.instance<AppSession>();
        await session.startTrialNow();
        final db = GetIt.instance<AppDatabase>();
        // Use the app clock (pinned via Seed.anchorOverride in tests); the
        // raw zone clock reads real wall time inside test bodies.
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(
            trialStart: Value(appNowUtc().subtract(const Duration(days: 15))),
          ),
        );
        await session.refresh();
      });
      await _pump(tester);
      await _settle(tester);
      expect(currentPath(tester), '/parental-gate');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Dark contrast (probe — pass)
  // -------------------------------------------------------------------------

  group('K02 dark contrast (probe)', () {
    testWidgets('every K02 text/background pair meets WCAG AA in dark', (
      tester,
    ) async {
      await _pump(tester, theme: ThemeMode.dark);
      final tokens = tester.element(find.byType(NestAvatar)).nest;
      // Worst-case hill-front tone: 80% meadow + 20% surface (CSS color-mix).
      final hillFront = Color.lerp(tokens.kidMeadow, tokens.surface, 0.2)!;
      final pairs = <(String, Color, Color, double)>[
        ('greeting', tokens.ink, tokens.kidSkyBottom, 3),
        ('caption over hills', tokens.ink2, hillFront, 4.5),
        ('caption over meadow', tokens.ink2, tokens.kidMeadow, 4.5),
        ('mark pill', tokens.ink, tokens.lilacTint, 4.5),
        ('keypad key', tokens.ink, tokens.surface, 4.5),
        ('avatar initial', tokens.aLilac, tokens.lilacTint, 4.5),
        ('dot border', tokens.ink, tokens.kidSkyBottom, 3),
      ];
      for (final (name, fg, bg, min) in pairs) {
        final ratio = _contrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$name contrast is ${ratio.toStringAsFixed(2)} (< $min)',
        );
      }
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // 320 px + 1.3 scale overflow (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 320 x 1.3 (probes)', () {
    testWidgets('loaded screen + wrong-PIN toast have no overflow', (
      tester,
    ) async {
      await _pump(tester, width: 320, textScale: 1.3);
      await _enter(tester, '9999');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("That didn't work. Try again."), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('failure card and chooser have no overflow', (tester) async {
      final real = GetIt.instance<KidHomeRepository>();
      await _useFake(_FailingHomeRepo(real));
      await _pump(tester, width: 320, textScale: 1.3);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('chooser has no overflow', (tester) async {
      await tester.runAsync(() async {
        await Seed.empty(GetIt.instance<AppDatabase>());
        await GetIt.instance<AppSession>().refresh();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await _pump(tester, width: 320, textScale: 1.3);
      await _settle(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Async gap (probe — pass)
  // -------------------------------------------------------------------------

  group('K02 async gap (probe)', () {
    testWidgets('pop while the PIN check hangs: no exception, no navigation', (
      tester,
    ) async {
      final fake = _StreamPairRepo()..hangVerify = true;
      await _useFake(fake);
      await _pump(tester);
      fake.home.add(const KidHomeData(child: _maya));
      await tester.pump();
      await _enter(tester, '1234');
      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(currentPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Time + money (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 time + money (probes)', () {
    testWidgets('screen text is identical across a BST -> GMT clock change', (
      tester,
    ) async {
      await _pump(tester);
      final summer = _texts(tester);
      expect(summer.any((t) => t.contains('£')), isFalse);
      expect(
        summer.any(
          (t) => RegExp(r'\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b').hasMatch(t),
        ),
        isFalse,
      );
      await disposeApp(tester);
      // Fresh scope between the two clocks (see ORCHESTRATOR_NOTES 10:32):
      // reusing the previous one leaves AppSession's Drift watch pending and
      // wedges the next `runAsync`.
      await setUpTestScope();
      // 15 Jan 2026 12:00 UTC is GMT; the story day is BST. K02 has no
      // dates, so the whole visible text tree must be byte-identical.
      await withClock(Clock.fixed(DateTime.utc(2026, 1, 15, 12)), () async {
        await tester.pumpWidget(const NestlingApp(initialRoute: '/kid-pin'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      });
      expect(_texts(tester), summer);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Accessibility (probes — pass)
  // -------------------------------------------------------------------------

  group('K02 accessibility (probes)', () {
    testWidgets('awaiting replaces the dots label; dots stay non-interactive', (
      tester,
    ) async {
      final fake = _StreamPairRepo()..hangVerify = true;
      await _useFake(fake);
      await _pump(tester);
      fake.home.add(const KidHomeData(child: _maya));
      await _settle(tester);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      await _enter(tester, '1234');
      await tester.pump(const Duration(milliseconds: 50));
      // The awaiting label lives in the screen's text node (a label-only
      // Semantics merges into its ancestor) and the dots label is gone.
      expect(
        find.bySemanticsLabel(RegExp('Checking your code')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('entered')), findsNothing);
      final checking = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Checking your code')),
      );
      expect(
        checking.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      await disposeApp(tester);
    });

    testWidgets('failure Try again exposes tap and recovers the screen', (
      tester,
    ) async {
      final real = GetIt.instance<KidHomeRepository>();
      await _useFake(_FailOnceHomeRepo(real));
      await _pump(tester);
      await _settle(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      final node = tester.getSemantics(find.text('Try again'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await _settle(tester);
      expect(find.text('Hi Maya! Enter your secret code'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
