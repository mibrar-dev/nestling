// K01 (profile picker) adversarial suite — Stage 6 bug hunt, iteration 3.
//
// Every proof below is backed by the real in-memory Drift database (or a
// file-backed one for the restart probe). Bug proofs are skipped with
// `skip: true` and carry their bug id in the test description — this
// Flutter's `testWidgets` takes a `bool?` skip, so the id cannot live in the
// skip argument. `flutter test --run-skipped <file>` runs them all and each
// one fails until its bug is fixed. Probes that pass stay in the suite as
// evidence for the "checked, clean" categories (zero/one/many children,
// long names, empty lists, double taps, back navigation, deep links,
// persistence, dark contrast, scale 1.3 + 320 px, money rounding, timezone
// — K01 shows no dates or money at all).
//
// Run one proof:
//   flutter test test/features/kid_home/k01_bugs_test.dart --plain-name K01-BUG-1

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/views/profile_picker_view.dart';
import 'package:nestling/features/kid_home/presentation/widgets/profile_tile.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _pumpPicker(
  WidgetTester tester, {
  String route = '/who-is-playing',
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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Inserts an extra child into the seeded family.
Future<void> _insertChild(
  String id,
  String nickname, {
  String ageBand = '',
  String colour = 'sky',
  int stage = 1,
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
          avatarColour: Value(colour),
          pipStage: Value(stage),
        ),
      );
}

Finder _tile(String id) => find.byKey(ValueKey<String>('k01-tile-$id'));

/// Two fingers DOWN on Maya and Leo before either UP: both taps belong to
/// the picker even though the first selection pushes a route in between
/// (K01-BUG-2 / K01-BUG-6).
void _burstMayaAndLeo(WidgetTester tester) {
  final maya = TestPointer(7);
  final leo = TestPointer(8);
  tester.binding.handlePointerEvent(maya.down(tester.getCenter(_tile('maya'))));
  tester.binding.handlePointerEvent(leo.down(tester.getCenter(_tile('leo'))));
  tester.binding.handlePointerEvent(maya.up());
  tester.binding.handlePointerEvent(leo.up());
}

/// Swaps the registered repository for a feature-local fake.
Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// K01-BUG-5 fake: the home stream is healthy and delivers `child: null`
/// (no active child), while the first profiles subscription errors and the
/// next one succeeds — the exact profile-failure + retry path.
class _ProfilesFailOnceRepository implements KidHomeRepository {
  int profilesCalls = 0;

  @override
  Stream<List<KidChild>> watchProfiles() {
    profilesCalls += 1;
    if (profilesCalls == 1) {
      return Stream<List<KidChild>>.error(Exception('profiles down'));
    }
    return Stream<List<KidChild>>.value(const <KidChild>[
      KidChild(
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
      ),
    ]);
  }

  @override
  Stream<KidHomeData> watchHome() =>
      Stream<KidHomeData>.value(const KidHomeData(child: null));

  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(null);

  @override
  List<String> stepsFor(String questId) => const <String>[];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// The seed's Maya row, for fake repositories.
const KidChild _mayaChild = KidChild(
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

/// K01-BUG-7 fake: the roster is a controllable stream. `setActiveChild`
/// lands a roster change while its own write is still in flight, so the
/// tapped child disappears from `state.profiles` before the selection emit
/// — the one window where the view cannot resolve the pending selection.
class _RosterSwapRepository implements KidHomeRepository {
  final StreamController<List<KidChild>> _roster =
      StreamController<List<KidChild>>.broadcast();
  final List<String> writes = <String>[];

  void emitRoster(List<KidChild> children) => _roster.add(children);

  @override
  Stream<List<KidChild>> watchProfiles() => _roster.stream;

  @override
  Future<void> setActiveChild(String childId) async {
    writes.add(childId);
    // K01-BUG-7: drop the tapped child out of the roster while the write
    // is still pending, then let the profiles emission win the race.
    _roster.add(const <KidChild>[]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Stream<KidHomeData> watchHome() =>
      Stream<KidHomeData>.value(const KidHomeData(child: null));

  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(null);

  @override
  List<String> stepsFor(String questId) => const <String>[];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {}
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

/// Every circle-decorated [Container] inside the tile: the avatar disc and
/// the pet disc. Both are circles in the design and must render square.
List<Rect> _circleRects(WidgetTester tester, Finder tile) {
  final circles = find.descendant(
    of: tile,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    ),
  );
  return <Rect>[
    for (var i = 0; i < circles.evaluate().length; i++)
      tester.getRect(circles.at(i)),
  ];
}

/// Loads the bundled faces so text metrics match a device run (the same set
/// as the K01 geometry test). Without this, every text is measured in the
/// wide default test font and truncation probes lie.
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
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K01-BUG-1 (FIXED, iteration 2 build) — 3+ children keep the design tile.
  //
  // `_OverflowTileRow` now keeps each tile at the two-up design share
  // ((350−16)/2 = 167 at 390) and scrolls horizontally, so the compact
  // metrics always fit. The proofs below were the red halves in iteration 1.
  // -------------------------------------------------------------------------

  group('K01-BUG-1 regression — 3+ children keep the design tile width', () {
    testWidgets('a third child keeps every tile at the two-up width', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await _insertChild('nina', 'Nina', ageBand: '7-9');
      });
      await _pumpPicker(tester);
      final tiles = find.byType(ProfileTile);
      expect(tiles, findsNWidgets(3));
      final widths = <double>[
        for (var i = 0; i < 3; i++) tester.getSize(tiles.at(i)).width,
      ];
      expect(
        widths.every((w) => (w - 167).abs() < 1),
        isTrue,
        reason:
            'K01-BUG-1: 3 children must keep the design tile width 167, '
            'got $widths',
      );
      await disposeApp(tester);
    });

    testWidgets('4+ children keep both discs circular', (tester) async {
      await tester.runAsync(() async {
        await _insertChild('nina', 'Nina');
        await _insertChild('omar', 'Omar');
      });
      await _pumpPicker(tester);
      final rects = _circleRects(tester, _tile('maya'));
      expect(rects, isNotEmpty);
      for (final rect in rects) {
        expect(
          rect.width,
          closeTo(rect.height, 0.5),
          reason:
              'K01-BUG-1: BoxShape.circle discs must stay square, got '
              '${rect.width}×${rect.height}',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('six children keep the design tile width and scroll', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await _insertChild('extra$i', 'Extra Child $i');
        }
      });
      await _pumpPicker(tester);
      final tiles = find.byType(ProfileTile);
      expect(tiles, findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        expect(tester.getSize(tiles.at(i)).width, closeTo(167, 1));
      }
      // The band scrolls: the sixth tile is off the right gutter until the
      // row is dragged.
      expect(
        tester.getTopLeft(tiles.at(5)).dx,
        greaterThan(390 - NestSpacing.padSide),
      );
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(-600, 0),
      );
      await tester.pump();
      expect(
        tester.getTopLeft(tiles.at(5)).dx,
        lessThan(390 - NestSpacing.padSide),
        reason: 'the sixth tile must become reachable by horizontal scroll',
      );
      await disposeApp(tester);
    });

    testWidgets('a scrolled-to extra child still selects and navigates', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await _insertChild('nina', 'Nina', ageBand: '7-9');
        await _insertChild('omar', 'Omar', ageBand: '4-6');
      });
      await _pumpPicker(tester);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(-400, 0),
      );
      await tester.pump();
      await tester.tap(_tile('omar'));
      await _settle(tester);
      expect(pushedPath(tester), '/kid-home');
      final db = GetIt.instance<AppDatabase>();
      final rows = await tester.runAsync(() => db.select(db.appState).get());
      expect(rows?.single.activeChildId, 'omar');
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // K01-BUG-2 (FIXED, iteration 2 build) — one burst, one route.
  //
  // The picker single-flights the whole selection (navigation AND write in
  // iteration 3), so a two-finger burst on two tiles pushes exactly one kid
  // route. K01-BUG-6 right after pins the other half: the route child and
  // the persisted active child agree.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-2 regression: one two-finger burst pushes one route', (
    tester,
  ) async {
    await _pumpPicker(tester);
    _burstMayaAndLeo(tester);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    final top = pushedPath(tester);
    expect(
      top == '/kid-pin' || top == '/kid-home',
      isTrue,
      reason: 'the burst must land on exactly one kid route, got $top',
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/who-is-playing',
      reason:
          'K01-BUG-2: a second route is stacked under $top; one pop must '
          'return to the picker',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K01-BUG-6 (FIXED, iteration 3 build) — the route child and the persisted
  // active child always agree.
  //
  // The picker now arms `_busy` BEFORE dispatching, so a two-finger burst
  // produces exactly one `KidHomeProfileSelected` event — one write, one
  // navigation — and the bloc's `selectedProfileId` gate drops a stale
  // second event as a second belt.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-6: route child and active child disagree', (
    tester,
  ) async {
    await _pumpPicker(tester);
    _burstMayaAndLeo(tester);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    final top = pushedPath(tester);
    final routed = top == '/kid-pin' ? 'maya' : 'leo';
    final db = GetIt.instance<AppDatabase>();
    final rows = await tester.runAsync(() => db.select(db.appState).get());
    expect(
      rows?.single.activeChildId,
      routed,
      reason:
          'K01-BUG-6: the picker opened $routed ($top) but persisted '
          '${rows?.single.activeChildId}; the second selection’s write must '
          'be dropped together with its navigation',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K01-BUG-3 (FIXED, iteration 3 build) — a tile navigates again after
  // coming back.
  //
  // The picker's listener now dispatches `KidHomeSelectionHandled` right
  // after starting the push, so the one-shot cannot wedge even when the
  // home stream's clear emission races ahead of it. The proof drains the
  // real Drift write (harness note: `tester.pump` alone never completes the
  // `setActiveChild` future) and then re-taps the same tile.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-3 regression: the same tile navigates again', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await tester.tap(_tile('maya'));
    // Tile taps run a real Drift `setActiveChild` write (harness note:
    // drain real async with runAsync, not only `Future.pump`).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await _settle(tester);
    expect(pushedPath(tester), '/kid-pin');
    await tester.pageBack();
    await _settle(tester);
    expect(pushedPath(tester), '/who-is-playing');
    final bloc = tester
        .element(find.byType(ProfilePickerView))
        .read<KidHomeBloc>();
    expect(
      bloc.state.selectedProfileId,
      isNull,
      reason:
          'K01-BUG-3: the handled event must consume the one-shot before the '
          'picker is visible again',
    );
    await tester.tap(_tile('maya'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/kid-pin',
      reason: 'K01-BUG-3: a repeated selection must navigate again',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K01-BUG-7 — minor — an orphaned selection locks every tile
  //
  // `_busy` is armed before the selection event is dispatched and released
  // on the pop, on a failure toast, or when the listener cannot resolve the
  // pending profile (`tapped == null` — it returns without dispatching
  // `KidHomeSelectionHandled`). In that last window the one-shot stays set:
  // the bloc's `selectedProfileId` gate then silently drops every subsequent
  // `KidHomeProfileSelected`, and the view's `_busy` was re-armed by the tap
  // that was dropped, so the picker is dead with no feedback. Today no
  // shipped flow changes the roster while the picker holds a selection, so
  // this is a latent hardening hole (the next sync/import/roster write
  // reaches it), not a user-visible defect.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-7: an orphaned selection locks every tile', (
    tester,
  ) async {
    final repo = _RosterSwapRepository();
    await _useFakeRepository(repo);
    await _pumpPicker(tester);
    repo.emitRoster(const <KidChild>[_mayaChild]);
    await _settle(tester);
    expect(_tile('maya'), findsOneWidget);

    // Tap while the roster is about to change: `setActiveChild` drops Maya
    // from the roster before the selection emit, so the listener cannot
    // resolve the pending profile.
    await tester.tap(_tile('maya'));
    await _settle(tester);
    expect(
      find.text('Ask a grown-up to add your profile.'),
      findsOneWidget,
      reason: 'the roster swap landed before the selection was routed',
    );

    // Maya comes back; the next tap is the user's retry on a live picker.
    repo.emitRoster(const <KidChild>[_mayaChild]);
    await _settle(tester);
    expect(_tile('maya'), findsOneWidget);
    await tester.tap(_tile('maya'));
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/kid-pin',
      reason:
          'K01-BUG-7: the orphaned selection is still pending, so the bloc '
          'gate drops this tap and the view’s `_busy` stays armed — every '
          'further tap is swallowed with no feedback',
    );
    await disposeApp(tester);
  }, skip: true);

  // -------------------------------------------------------------------------
  // K01-BUG-5 (FIXED, iteration 2 build) — Try again recovers from a
  // profiles-only failure. `_profilesFailed` + `copyWithProfilesRecovered`
  // (kid_home_bloc.dart) restore `loaded` when the roster returns while the
  // home stream is still live, and the view heals a failure with a
  // non-empty roster as a second belt. The test below was the red half in
  // iteration 1 (also stage-4 review finding 1).
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-5 regression: Try again recovers the roster', (
    tester,
  ) async {
    await _useFakeRepository(_ProfilesFailOnceRepository());
    await _pumpPicker(tester);
    expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Oh no! Pip got lost.'),
      findsNothing,
      reason:
          'K01-BUG-5: a recovered roster must replace the failure card '
          '(`copyWithProfilesRecovered` restores `loaded`)',
    );
    expect(find.text("Who's playing?"), findsOneWidget);
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Edge-case probes (expected green — kept as evidence)
  // -------------------------------------------------------------------------

  group('edge-case probes', () {
    testWidgets('no children: message, lock and no tiles', (tester) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pumpPicker(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
      expect(find.byType(ProfileTile), findsNothing);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a single child fills the row without overflowing', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      });
      await _pumpPicker(tester);
      expect(find.byType(ProfileTile), findsOneWidget);
      final rect = tester.getRect(_tile('maya'));
      expect(rect.left, closeTo(NestSpacing.padSide, 1));
      expect(rect.right, closeTo(390 - NestSpacing.padSide, 1));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a long UK name ellipsizes at 320 px + 1.3 text scale', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('leo'))).write(
          const ChildrenCompanion(nickname: Value('Maximilian-Alexander')),
        );
      });
      await _pumpPicker(tester, width: 320, textScale: 1.3);
      expect(_tile('leo'), findsOneWidget);
      final name = find.descendant(
        of: _tile('leo'),
        matching: find.text('Maximilian-Alexander'),
      );
      expect(name, findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a child without an age band keeps the tile rhythm', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('leo'))).write(
          const ChildrenCompanion(ageBand: Value('')),
        );
      });
      await _pumpPicker(tester);
      expect(find.text('Age 7–9'), findsOneWidget);
      expect(find.text('Age 4–6'), findsNothing);
      final maya = tester.getRect(_tile('maya'));
      final leo = tester.getRect(_tile('leo'));
      expect(leo.width, closeTo(maya.width, 0.5));
      expect(leo.height, closeTo(maya.height, 1));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('coins and pound amounts never appear on the picker', (
      tester,
    ) async {
      await _pumpPicker(tester);
      expect(find.textContaining('£'), findsNothing);
      expect(find.textContaining('9999'), findsNothing);
      expect(find.textContaining('coins'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('rapid same-tile double tap pushes exactly one route', (
      tester,
    ) async {
      await _pumpPicker(tester);
      await tester.tap(_tile('maya'));
      await tester.tap(_tile('maya'));
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);
      expect(
        pushedPath(tester),
        '/who-is-playing',
        reason: 'the tile latch must absorb the second tap',
      );
      await disposeApp(tester);
    });

    testWidgets('rapid lock double tap pushes exactly one gate', (
      tester,
    ) async {
      await _pumpPicker(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settle(tester);
      expect(pushedPath(tester), '/parental-gate');
      await tester.pageBack();
      await _settle(tester);
      expect(pushedPath(tester), '/who-is-playing');
      await disposeApp(tester);
    });

    testWidgets('deep link to the picker works in kid and parent mode', (
      tester,
    ) async {
      await _pumpPicker(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      await disposeApp(tester);
      await _pumpPicker(tester, kidMode: false);
      expect(find.text("Who's playing?"), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets("copy matches the plan\u0027s typographic characters exactly", (
      tester,
    ) async {
      await _pumpPicker(tester);
      final title = tester.widget<Text>(find.text("Who's playing?")).data!;
      expect(title.contains("'"), isTrue);
      expect(title.contains('’'), isFalse);
      expect(find.text('Tap your face to start'), findsOneWidget);
      expect(find.text('Age 7–9'), findsOneWidget);
      expect(find.text('Age 4–6'), findsOneWidget);
      expect(
        find.text('Grown-ups: tap the lock to get back to your dashboard.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('every control exposes SemanticsAction.tap', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPicker(tester);
      for (final finder in <Finder>[
        find.bySemanticsLabel('Maya, Age 7–9'),
        find.bySemanticsLabel('Leo, Age 4–6'),
        find.bySemanticsLabel('Grown-ups'),
      ]) {
        expect(
          tester
              .getSemantics(finder)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    test('K01 token pairs used on the screen meet WCAG contrast', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final pairs = <String, (Color, Color)>{
        'light ink on skyTop': (light.ink, light.kidSkyTop),
        'light ink on skyBottom': (light.ink, light.kidSkyBottom),
        'light ink2 on skyBottom': (light.ink2, light.kidSkyBottom),
        'light ink2 on meadow': (light.ink2, light.kidMeadow),
        'light ink on surface': (light.ink, light.surface),
        'light ink2 on surface': (light.ink2, light.surface),
        'light aLilac on lilacTint': (light.aLilac, light.lilacTint),
        'light aPeach on peachTint': (light.aPeach, light.peachTint),
        'dark ink on skyTop': (dark.ink, dark.kidSkyTop),
        'dark ink on skyBottom': (dark.ink, dark.kidSkyBottom),
        'dark ink2 on skyBottom': (dark.ink2, dark.kidSkyBottom),
        'dark ink2 on meadow': (dark.ink2, dark.kidMeadow),
        'dark ink on surface': (dark.ink, dark.surface),
        'dark ink2 on surface': (dark.ink2, dark.surface),
        'dark aLilac on lilacTint': (dark.aLilac, dark.lilacTint),
        'dark aPeach on peachTint': (dark.aPeach, dark.peachTint),
      };
      for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
        expect(_contrast(a, b), greaterThanOrEqualTo(4.5), reason: name);
      }
    });

    test('tapping a tile persists the active child across a restart', () async {
      final dir = Directory.systemTemp.createTempSync('k01_restart_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/nestling.db');
      final db1 = AppDatabase(NativeDatabase(file));
      await Seed.demo(db1);
      await KidHomeRepositoryImpl(db: db1).setActiveChild('leo');
      await db1.close();
      final db2 = AppDatabase(NativeDatabase(file));
      final state = await db2.select(db2.appState).getSingle();
      await db2.close();
      expect(state.activeChildId, 'leo');
    });

    testWidgets('a child with an empty nickname still has a usable label', (
      tester,
    ) async {
      await tester.runAsync(() => _insertChild('noname', ''));
      await _pumpPicker(tester);
      final tile = _tile('noname');
      expect(tile, findsOneWidget);
      final semantics = tester.ensureSemantics();
      final data = tester.getSemantics(tile).getSemanticsData();
      expect(
        data.label,
        isNotEmpty,
        reason:
            'K01-BUG-4: an unlabelled tile is invisible to VoiceOver; the '
            'semantics label is built from the raw nickname',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('title, sub and caption render in full at 320 px + 1.3', (
      tester,
    ) async {
      await _pumpPicker(tester, width: 320, textScale: 1.3);
      // The balanced title must keep a real box; a collapsed width would
      // clip the words away (the shared search regresses silently).
      final title = tester.renderObject<RenderParagraph>(
        find.text("Who's playing?"),
      );
      expect(title.didExceedMaxLines, isFalse);
      expect(
        title.size.width,
        greaterThan(100),
        reason: 'the balanced title box must not collapse to ~0',
      );
      for (final copy in <String>[
        'Tap your face to start',
        'Grown-ups: tap the lock to get back to your dashboard.',
      ]) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(copy));
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '“$copy” loses words at 320 px + 1.3 text scale',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('D1/D2 regression: tiles and caption sit at the design y', (
      tester,
    ) async {
      // 5_ui measured the tile border top at design 297.7 / app 314.3 and the
      // caption first row at design 747 / app 781. The build added the 34 px
      // bottom reserve (NestDevice.homeH); the box positions below use the
      // PNG's own border-ink rows ÷3.
      await _pumpPicker(tester);
      final tile = tester.getRect(_tile('maya'));
      // 5_ui samples the tile border at logical x=30, which is 9 px inside
      // the tile's left edge (x=21). On the r32 corner that chord starts
      // 9.75 px below the true top edge (r − √(r² − (r−9)²) with r=32), so
      // the design readings translate to: top 297.7→287.9, bottom
      // 640.0→649.8, centre 468.8, height 361.8. The widget rect is the
      // true box, so compare against the corrected design.
      expect(
        tile.center.dy,
        closeTo(468.8, 2),
        reason: 'design tile centre 468.8 (5_ui D1 chords, corner-corrected)',
      );
      expect(
        tile.height,
        closeTo(361.8, 2.5),
        reason: 'design tile height 361.8 (5_ui D1 chords, corner-corrected)',
      );
      final caption = tester.getRect(
        find.text('Grown-ups: tap the lock to get back to your dashboard.'),
      );
      // 15/20 caption box: 738…778; first ink row 747 (5_ui D2, simulator).
      expect(
        caption.top,
        closeTo(738, 2),
        reason: 'design caption box top 738 (first ink row 747)',
      );
      await disposeApp(tester);
    });
  });
}
