// K01 view tests over the in-memory Drift database (Seed.demo): the exact
// design copy, Maya-then-Leo order, per-child PipAvatar look, tile taps
// persist the active child and push the right route, accessibility taps,
// loading / failure / empty states, and the 320 px + 1.3 scale matrix.
//
// Database-backed tests use `setUpTestScope`; the loading/error paths,
// which a healthy database cannot produce, use a feature-local fake
// repository registered over the real one in GetIt. Every pumped app
// ends with `disposeApp` (see test_scope.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

import '../../test_scope.dart';

/// Feature-local kid_home repository fake (same shape as K03's): the
/// picker only reads profiles + active child; selection writes are
/// recorded so tests can assert the bloc round-trip.
class _FakeKidHomeRepository implements KidHomeRepository {
  _FakeKidHomeRepository({this.hangLoad = false, this.failTimes = 0});

  final List<KidChild> profiles = const <KidChild>[];
  bool hangLoad;

  /// Number of `watchHome` errors to emit before the stream recovers.
  int failTimes;

  final List<String> activeChildWrites = <String>[];
  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Stream<List<KidChild>> watchProfiles() {
    return Stream<List<KidChild>>.value(profiles);
  }

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(null);

  @override
  Stream<KidHomeData> watchHome() async* {
    if (hangLoad) {
      await Completer<void>().future; // never emits
      return;
    }
    if (failTimes > 0) {
      failTimes -= 1;
      throw Exception('home down');
    }
    yield const KidHomeData(child: null);
  }

  @override
  List<String> stepsFor(String questId) => const <String>[];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {
    activeChildWrites.add(childId);
  }

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

Future<void> _pumpPicker(
  WidgetTester tester, {
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
  await tester.pumpWidget(const NestlingApp(initialRoute: '/who-is-playing'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The child's age band in the tiles, checked against the DB value with
/// the design's en dash.
const mayaAge = 'Age 7–9';
const leoAge = 'Age 4–6';

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  testWidgets('renders the design copy with exact typographic characters', (
    tester,
  ) async {
    await _pumpPicker(tester);
    final title = find.text("Who's playing?");
    expect(title, findsOneWidget);
    expect(
      tester.widget<Text>(title).data,
      contains("'"),
      reason: 'the apostrophe is ASCII 0x27, matching the HTML source',
    );
    expect(find.text('Tap your face to start'), findsOneWidget);
    expect(
      find.text('Grown-ups: tap the lock to get back to your dashboard.'),
      findsOneWidget,
    );
    final mayaTile = find.text(mayaAge);
    final leoTile = find.text(leoAge);
    expect(mayaTile, findsOneWidget);
    expect(leoTile, findsOneWidget);
    expect(tester.widget<Text>(mayaTile).data, contains('–'));
    expect(tester.widget<Text>(leoTile).data, contains('–'));
    await disposeApp(tester);
  });

  testWidgets('two tiles in creation order, Maya then Leo', (tester) async {
    await _pumpPicker(tester);
    final maya = find.byKey(const ValueKey('k01-tile-maya'));
    final leo = find.byKey(const ValueKey('k01-tile-leo'));
    expect(maya, findsOneWidget);
    expect(leo, findsOneWidget);
    expect(
      tester.getTopLeft(maya).dx,
      lessThan(tester.getTopLeft(leo).dx),
      reason: 'Maya is listed first, never alphabetical',
    );
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Leo'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets("each tile renders the child's own PipAvatar look", (
    tester,
  ) async {
    await _pumpPicker(tester);
    final pips = tester.widgetList<PipAvatar>(find.byType(PipAvatar)).toList();
    expect(pips, hasLength(2));
    final mayaPip = pips.firstWhere((p) => p.style == PipStyle.mochi);
    expect(mayaPip.stage, 3);
    expect(mayaPip.skin, PipSkin.sunny);
    final leoPip = pips.firstWhere((p) => p.style == PipStyle.bolt);
    expect(leoPip.stage, 2);
    expect(leoPip.skin, PipSkin.sky);
    // No v1 pip_stage_*.svg art anywhere (orchestrator PIP rule).
    final v1 = find
        .byType(SvgPicture)
        .evaluate()
        .map((e) => (e.widget as SvgPicture).bytesLoader)
        .whereType<SvgAssetLoader>()
        .where((l) => l.assetName.contains('pip_stage'));
    expect(v1, isEmpty);
    await disposeApp(tester);
  });

  testWidgets('tapping Maya persists the active child and pushes the PIN', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await tester.tap(find.byKey(const ValueKey('k01-tile-maya')));
    await _settleRoute(tester);
    expect(pushedPath(tester), '/kid-pin');
    final db = GetIt.instance<AppDatabase>();
    final row = await tester.runAsync(() async {
      final rows = await db.select(db.appState).get();
      return rows.single;
    });
    expect(row?.activeChildId, 'maya');
    await disposeApp(tester);
  });

  testWidgets('tapping Leo persists the active child and pushes home', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await tester.tap(find.byKey(const ValueKey('k01-tile-leo')));
    await _settleRoute(tester);
    expect(pushedPath(tester), '/kid-home');
    final db = GetIt.instance<AppDatabase>();
    final row = await tester.runAsync(() async {
      final rows = await db.select(db.appState).get();
      return rows.single;
    });
    expect(row?.activeChildId, 'leo');
    await disposeApp(tester);
  });

  testWidgets('lock pushes the parental gate', (tester) async {
    await _pumpPicker(tester);
    await tester.tap(find.bySemanticsLabel('Grown-ups'));
    await _settleRoute(tester);
    expect(pushedPath(tester), '/parental-gate');
    await disposeApp(tester);
  });

  group('accessibility actions', () {
    bool hasTap(WidgetTester tester, Finder finder) => tester
        .getSemantics(finder)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);

    testWidgets('tiles and lock advertise tap', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPicker(tester);
      expect(hasTap(tester, find.bySemanticsLabel('Maya, Age 7–9')), isTrue);
      expect(hasTap(tester, find.bySemanticsLabel('Leo, Age 4–6')), isTrue);
      expect(hasTap(tester, find.bySemanticsLabel('Grown-ups')), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('performing the tile tap writes the active child', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPicker(tester);
      final node = tester.getSemantics(find.bySemanticsLabel('Maya, Age 7–9'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final db = GetIt.instance<AppDatabase>();
      final row = await tester.runAsync(() async {
        final rows = await db.select(db.appState).get();
        return rows.single;
      });
      expect(row?.activeChildId, 'maya');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  testWidgets('loading shows the profiles spinner', (tester) async {
    await _useFakeRepository(_FakeKidHomeRepository(hangLoad: true));
    await _pumpPicker(tester);
    expect(find.bySemanticsLabel('Loading profiles'), findsOneWidget);
    expect(find.byType(NestLockButton), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('failure shows Pip + message + reload, and Try again recovers', (
    tester,
  ) async {
    await _useFakeRepository(_FakeKidHomeRepository(failTimes: 1));
    await _pumpPicker(tester);
    expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
    expect(find.text("Let's try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // The fake repo recovers but has no profiles, so the empty-roster
    // message shows (the retry really re-subscribed).
    expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('no children shows the grown-ups message, lock still present', (
    tester,
  ) async {
    await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
    await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
    await _pumpPicker(tester);
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Tap your face to start'), findsOneWidget);
    expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
    expect(find.byType(NestLockButton), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('320 px + 1.3 text scale fits, light theme', (tester) async {
    await _pumpPicker(tester, width: 320, textScale: 1.3);
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Leo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('320 px + 1.3 text scale fits, dark theme', (tester) async {
    await _pumpPicker(
      tester,
      width: 320,
      textScale: 1.3,
      theme: ThemeMode.dark,
    );
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Leo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
}
