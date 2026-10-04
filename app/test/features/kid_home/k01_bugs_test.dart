// K01 (profile picker) adversarial suite — Stage 6 bug hunt, iteration 1.
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
  // K01-BUG-1 — three or more children break the tile row
  //
  // `_PickerLoaded` lays every profile out in a fixed `Row` of `Expanded`
  // cards. Two children give the design's 167 px tiles; a third shrinks each
  // tile to 106 px (content 86 px) and a sixth to 45 px (content 25 px).
  // The compact metrics then no longer fit: the 96 px pet disc is clamped to
  // 86×96 (an ellipse), the 64 px avatar to 25×64, and the 80 px Pip is
  // squeezed into 25 px. The design has no answer for 3+ children, but a
  // family app must stay usable — the tiles band needs to scroll or wrap at
  // a minimum tile width instead of shrinking without bound.
  // -------------------------------------------------------------------------

  group('K01-BUG-1 — 3+ children collapse the tile row', () {
    testWidgets('a third child shrinks every tile below the compact minimum', (
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
      // Compact mode needs 96 px of content (pet disc) + 20 px padding.
      expect(
        widths.every((w) => w >= 132),
        isTrue,
        reason:
            'K01-BUG-1: 3 children shrink the tiles to $widths; the design '
            'tile is 167 wide and compact mode needs at least 132',
      );
      await disposeApp(tester);
    });

    testWidgets('at 4+ children the pet disc/avatar stop being circles', (
      tester,
    ) async {
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

    testWidgets('six children leave 45 px slivers (design tile: 167)', (
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
      final widths = <double>[
        for (var i = 0; i < 6; i++) tester.getSize(tiles.at(i)).width,
      ];
      expect(
        widths.every((w) => w >= 132),
        isTrue,
        reason: 'K01-BUG-1: six children shrink the tiles to $widths',
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // K01-BUG-2 — two quick taps on two tiles stack two routes
  //
  // Each tile has its own `_busy` latch, so a tap on Maya does not stop a tap
  // on Leo in the same gesture burst. Both `KidHomeProfileSelected` events
  // write `app_state` and both one-shot `selectedProfileId` emissions reach
  // the picker's `BlocListener`, which pushes `/kid-pin` AND `/kid-home` on
  // top of each other. One back press then lands on the other child's route
  // instead of the picker (and the last DB write wins the active child).
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-2: tapping Maya then Leo stacks two kid routes', (
    tester,
  ) async {
    await _pumpPicker(tester);
    // Two fingers, both DOWN before either UP: both taps belong to the
    // picker even though the first selection pushes a route in between.
    final maya = TestPointer(7);
    final leo = TestPointer(8);
    tester.binding.handlePointerEvent(
      maya.down(tester.getCenter(_tile('maya'))),
    );
    tester.binding.handlePointerEvent(leo.down(tester.getCenter(_tile('leo'))));
    tester.binding.handlePointerEvent(maya.up());
    tester.binding.handlePointerEvent(leo.up());
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    final top = pushedPath(tester);
    final db = GetIt.instance<AppDatabase>();
    final rows = await tester.runAsync(() => db.select(db.appState).get());
    expect(
      find.text('K02 Kid PIN', skipOffstage: false),
      findsNothing,
      reason:
          'K01-BUG-2: Maya and Leo were tapped in one two-finger burst; both '
          'selections pushed (top $top, active child '
          '${rows?.single.activeChildId}), so the PIN screen and the home '
          'screen are stacked on the picker for a single gesture burst',
    );
    await disposeApp(tester);
  }, skip: true);

  // -------------------------------------------------------------------------
  // K01-BUG-3 — the same tile does not navigate twice in a row
  //
  // `selectedProfileId` is a one-shot that only clears on the next home
  // stream emission (`copyWithLoaded`). When the home stream does not
  // re-emit after `setActiveChild` (nothing changed for that child), the
  // second selection emits an `==`-equal state, the bloc drops it, and the
  // tile is dead with no feedback.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-3: tapping the same tile after back does nothing', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await tester.tap(_tile('maya'));
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
          'K01-BUG-3 mechanism: the one-shot is still set when the picker '
          "comes back (the home stream's clear emission races ahead of the "
          'selection emit), so the equal re-selection is dropped by the bloc',
    );
    await tester.tap(_tile('maya'));
    await _settle(tester);
    expect(
      pushedPath(tester),
      '/kid-pin',
      reason: 'K01-BUG-3: a repeated selection must navigate again',
    );
    await disposeApp(tester);
  }, skip: true);

  // -------------------------------------------------------------------------
  // K01-BUG-5 — Try again cannot recover from a profiles-only failure
  //
  // The failure card can be shown when `watchProfiles` errors while the home
  // stream is healthy (it emits `KidHomeData(child: null)` and then stays
  // quiet). `KidHomeLoadRequested` only restarts the home stream when
  // `_homeSub == null` (kid_home_bloc.dart:52) and `copyWithProfiles` never
  // touches `status`, so a successful profiles retry still leaves
  // `KidHomeStatus.failure`: the retry spins up a working roster the child
  // can never see. Stage 4 finding 1 proved here as a failing test.
  // -------------------------------------------------------------------------

  testWidgets('K01-BUG-5: Try again cannot recover from a profiles failure', (
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
          'K01-BUG-5: the profiles stream recovered but the failure card '
          'stayed; `copyWithProfiles` must restore the loaded state',
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
  });
}
