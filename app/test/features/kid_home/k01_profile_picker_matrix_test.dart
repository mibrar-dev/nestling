// K01 · Who's playing? — the stage-3 matrix: every width (320/390/430) ×
// light + dark × text scale 1.0 + 1.3, the three non-loaded states, tap
// targets, accessibility labels on the icon button, and the owner rules for
// alignment (20 px gutters) and the bottom edge.
//
// Everything runs against the real in-memory Drift database (Seed.demo /
// Seed.empty). Paths a healthy database cannot produce (loading, failure,
// a rejected `setActiveChild`) use the feature-local fake repository
// registered over the real one in GetIt, exactly as
// `k01_profile_picker_view_test.dart` does.
//
// Every pumped app ends with `disposeApp` (see test_scope.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:nestling/features/kid_home/presentation/widgets/profile_tile.dart';

import '../../test_scope.dart';

const ValueKey<String> _mayaTile = ValueKey<String>('k01-tile-maya');
const ValueKey<String> _leoTile = ValueKey<String>('k01-tile-leo');

const String _title = 'Who’s playing?'; // K01-BUG-5: must be the straight '
const String _sub = 'Tap your face to start';
const String _caption =
    'Grown-ups: tap the lock to get back to your dashboard.';

/// Feature-local repository fake for the paths a healthy database cannot
/// produce: a silent stream (loading) and a failing one (the failure card).
/// `setActiveChild` can also be made to throw, which is the picker's
/// action-error path.
class _FakeKidHomeRepository implements KidHomeRepository {
  _FakeKidHomeRepository({this.hangLoad = false, this.failTimes = 0});

  List<KidChild> profiles = const <KidChild>[];
  bool hangLoad;
  int failTimes;
  bool failSelect = false;

  final List<String> activeChildWrites = <String>[];

  @override
  Future<List<KidQuest>> getItems() async => const <KidQuest>[];

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(profiles);

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
    if (failSelect) throw Exception('nope');
  }

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  double bottomInset = 0,
  bool pixels = false,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  const app = NestlingApp(initialRoute: '/who-is-playing');
  await tester.pumpWidget(
    pixels ? const RepaintBoundary(key: _probe, child: _Wrapped(app)) : app,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

const Key _probe = Key('k01-pixel-probe');

/// Lets a single const widget tree hang off the repaint boundary.
class _Wrapped extends StatelessWidget {
  const _Wrapped(this.app);

  final Widget app;

  @override
  Widget build(BuildContext context) => app;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pops the imperatively-pushed route. `tester.pageBack()` needs a back
/// button, and `/kid-home` (K03) has its own chrome, so pop the Navigator.
Future<void> _popRoute(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await _settle(tester);
}

/// Painted RGBA bytes at logical (x, y) of the probed app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_probe),
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

List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

String _themeName(ThemeMode theme) =>
    theme == ThemeMode.light ? 'light' : 'dark';

NestTokens _tokensOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ProfileTile).first))
        .extension<NestTokens>()!;

/// The seeded roster, read through the real repository so a fake can be
/// handed the same profiles the Drift-backed one produces.
Future<List<KidChild>> _demoRoster() =>
    GetIt.instance<KidHomeRepository>().watchProfiles().first;

/// Painted RGBA with a ±1 per-channel tolerance: an 8-bit screenshot of an
/// sRGB gradient lands a unit either side of the rounded token.
void _expectPixelNear(List<int> actual, Color expected, String reason) {
  final target = _rgba(expected);
  for (var channel = 0; channel < 3; channel++) {
    expect(
      (actual[channel] - target[channel]).abs(),
      lessThanOrEqualTo(1),
      reason: '$reason (channel $channel: ${actual[channel]} vs $target)',
    );
  }
  expect(actual[3], 255, reason: '$reason must be opaque');
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // The width × theme × text-scale matrix
  // -------------------------------------------------------------------------

  for (final width in const <double>[320, 390, 430]) {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final textScale in const <double>[1, 1.3]) {
        final label = '${width.toInt()}px ${_themeName(theme)} @${textScale}x';
        testWidgets('$label: title, sub, caption and two tiles all render', (
          tester,
        ) async {
          await _pump(tester, width: width, textScale: textScale, theme: theme);
          expect(find.text(_title), findsOneWidget);
          expect(find.text(_sub), findsOneWidget);
          expect(find.text(_caption), findsOneWidget);
          expect(find.byKey(_mayaTile), findsOneWidget);
          expect(find.byKey(_leoTile), findsOneWidget);
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        });

        testWidgets('$label: 20px gutters on every edge, tiles aligned', (
          tester,
        ) async {
          await _pump(tester, width: width, textScale: textScale, theme: theme);
          final maya = tester.getRect(find.byKey(_mayaTile));
          final leo = tester.getRect(find.byKey(_leoTile));
          expect(
            maya.left,
            closeTo(NestSpacing.padSide, 0.5),
            reason: 'left gutter',
          );
          expect(
            leo.right,
            closeTo(width - NestSpacing.padSide, 0.5),
            reason: 'right gutter',
          );
          expect(
            maya.width,
            closeTo(leo.width, 0.5),
            reason: 'equal tiles, never one a few px off',
          );
          expect(leo.left - maya.right, closeTo(NestSpacing.s4, 0.5));
          expect(maya.top, closeTo(leo.top, 0.01));
          expect(maya.bottom, closeTo(leo.bottom, 0.01));

          // The lock shares the same right edge as the cards.
          final lock = tester.getRect(find.byType(NestLockButton));
          expect(lock.right, closeTo(width - NestSpacing.padSide, 0.5));
          // Every drawn paragraph starts inside the same 20 px gutters.
          for (final paragraph in tester.widgetList<Text>(find.byType(Text))) {
            if (paragraph.data == null) continue;
            final rect = tester.getRect(
              find.text(paragraph.data!, skipOffstage: false),
            );
            expect(
              rect.left,
              greaterThanOrEqualTo(NestSpacing.padSide - 0.5),
              reason: '“${paragraph.data}” escapes the left gutter',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(width - NestSpacing.padSide + 0.5),
              reason: '“${paragraph.data}” escapes the right gutter',
            );
          }
          await disposeApp(tester);
        });
      }
    }
  }

  testWidgets('320px uses the compact tile metrics (plan §1 narrow rule)', (
    tester,
  ) async {
    await _pump(tester, width: 320);
    // Tile < 150 wide switches to compact: avatar 64, pet 96, Pip 80.
    expect(tester.getSize(find.byKey(_mayaTile)).width, 132);
    final avatar = tester.getSize(
      find
          .descendant(
            of: find.byKey(_mayaTile),
            matching: find.byType(NestAvatar),
          )
          .first,
    );
    expect(avatar, const Size(64, 64));
    final pip = tester.widgetList<PipAvatar>(
      find.descendant(
        of: find.byKey(_mayaTile),
        matching: find.byType(PipAvatar),
      ),
    );
    expect(pip.single.size, 80);
    await disposeApp(tester);
  });

  testWidgets('390 and 430 keep the design tile metrics', (tester) async {
    for (final width in const <double>[390, 430]) {
      await _pump(tester, width: width);
      final avatar = tester.getSize(
        find
            .descendant(
              of: find.byKey(_mayaTile),
              matching: find.byType(NestAvatar),
            )
            .first,
      );
      expect(avatar, const Size(96, 96), reason: '$width design avatar');
      final pip = tester.widgetList<PipAvatar>(
        find.descendant(
          of: find.byKey(_mayaTile),
          matching: find.byType(PipAvatar),
        ),
      );
      expect(pip.single.size, 112, reason: '$width design Pip');
      await disposeApp(tester);
    }
  });

  // -------------------------------------------------------------------------
  // Tap targets (kid minimum 56, parent minimum 44)
  // -------------------------------------------------------------------------

  for (final width in const <double>[320, 390, 430]) {
    testWidgets('${width.toInt()}px: every control meets the 56px kid target', (
      tester,
    ) async {
      await _pump(tester, width: width);
      for (final key in const <ValueKey<String>>[_mayaTile, _leoTile]) {
        final rect = tester.getRect(find.byKey(key));
        expect(
          rect.width,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$key is only ${rect.width} wide',
        );
        expect(
          rect.height,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$key is only ${rect.height} tall',
        );
      }
      final lock = tester.getRect(find.byType(NestLockButton));
      expect(lock.width, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(lock.height, greaterThanOrEqualTo(NestDevice.tapKid));
      await disposeApp(tester);
    });
  }

  testWidgets('the failure card’s Try again meets the 56px kid target', (
    tester,
  ) async {
    await _useFakeRepository(_FakeKidHomeRepository(failTimes: 1));
    await _pump(tester);
    final button = tester.getRect(find.byType(NestKidButton));
    expect(
      button.height,
      greaterThanOrEqualTo(NestDevice.tapKid),
      reason: 'NestKidButton is the shared kid control (minHeight 64)',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Accessibility labels on the icon button + real effects
  // -------------------------------------------------------------------------

  testWidgets('the lock is a labelled button whose tap action opens the gate', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
    final data = node.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, 'Grown-ups');
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await _settle(tester);
    expect(pushedPath(tester), '/parental-gate');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('each tile is a labelled button whose tap action navigates', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final db = GetIt.instance<AppDatabase>();
    final node = tester.getSemantics(find.bySemanticsLabel('Maya, Age 7–9'));
    final data = node.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await _settle(tester);
    // pinSet is read from the database, never assumed by the test.
    final mayaPin =
        await tester.runAsync(
          () => (db.select(db.children)..where((c) => c.id.equals('maya')))
              .getSingle()
              .then((row) => row.pinHash != null),
        ) ??
        false;
    expect(pushedPath(tester), mayaPin ? '/kid-pin' : '/kid-home');
    final state = await tester.runAsync(() => db.select(db.appState).get());
    expect(state?.single.activeChildId, 'maya');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('Leo’s tile tap action routes by its own pinSet', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final db = GetIt.instance<AppDatabase>();
    final leoPin =
        await tester.runAsync(
          () => (db.select(db.children)..where((c) => c.id.equals('leo')))
              .getSingle()
              .then((row) => row.pinHash != null),
        ) ??
        false;
    final node = tester.getSemantics(find.bySemanticsLabel('Leo, Age 4–6'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await _settle(tester);
    expect(pushedPath(tester), leoPin ? '/kid-pin' : '/kid-home');
    final state = await tester.runAsync(() => db.select(db.appState).get());
    expect(state?.single.activeChildId, 'leo');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('non-controls advertise no tap action (no phantom buttons)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    // The tile's name/age live INSIDE the button node on purpose (that is
    // the tile's label), so they are checked as part of it, not against it.
    for (final finder in <Finder>[
      find.text(_title),
      find.text(_sub),
      find.text(_caption),
    ]) {
      expect(
        tester
            .getSemantics(finder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
        reason: '$finder must not look pressable',
      );
    }
    // …and the button node really carries the whole tile label.
    final tile = tester.getSemantics(find.byKey(_mayaTile)).getSemanticsData();
    expect(tile.label, 'Maya, Age 7–9');
    expect(tile.hasAction(SemanticsAction.tap), isTrue);
    expect(tile.flagsCollection.isButton, isTrue);

    // The pet is announced with the design's alt text as an IMAGE. It sits
    // inside the button, so it inherits the tile's tap — but it is not a
    // second, phantom button.
    for (final (id, alt) in const <(String, String)>[
      ('k01-tile-maya', 'Pip the Fledgling'),
      ('k01-tile-leo', 'Pip the Hatchling'),
    ]) {
      final pet = tester
          .getSemantics(
            find.descendant(
              of: find.byKey(ValueKey<String>(id)),
              matching: find.bySemanticsLabel(alt),
            ),
          )
          .getSemanticsData();
      expect(pet.label, alt);
      expect(pet.flagsCollection.isImage, isTrue, reason: alt);
      expect(pet.flagsCollection.isButton, isFalse, reason: alt);
    }
    semantics.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Every tap navigates to the right route
  // -------------------------------------------------------------------------

  testWidgets('Maya’s tile pushes the PIN route', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(_mayaTile));
    await _settle(tester);
    expect(pushedPath(tester), '/kid-pin');
    await _popRoute(tester);
    expect(pushedPath(tester), '/who-is-playing');
    await disposeApp(tester);
  });

  testWidgets('Leo’s tile pushes the home route (no PIN set)', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(_leoTile));
    await _settle(tester);
    expect(pushedPath(tester), '/kid-home');
    await _popRoute(tester);
    expect(pushedPath(tester), '/who-is-playing');
    await disposeApp(tester);
  });

  testWidgets('a rejected selection shows the toast and stays put', (
    tester,
  ) async {
    // The roster comes from the real repository (inside runAsync — a Drift
    // future never completes under the test's fake clock) so the fake only
    // replaces the write.
    final roster = (await tester.runAsync(_demoRoster)) ?? const <KidChild>[];
    await _useFakeRepository(
      _FakeKidHomeRepository()
        ..failSelect = true
        ..profiles = roster,
    );
    await _pump(tester);
    expect(find.byKey(_mayaTile), findsOneWidget);
    await tester.tap(find.byKey(_mayaTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text('Hmm, that did not work. Try again.'),
      findsOneWidget,
      reason: 'the action error must be explained',
    );
    expect(
      pushedPath(tester),
      '/who-is-playing',
      reason: 'a failed write must not navigate',
    );
    expect(find.byKey(_mayaTile), findsOneWidget, reason: 'roster kept');
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // Non-loaded states
  // -------------------------------------------------------------------------

  testWidgets('loading: spinner, lock and no tiles at every width', (
    tester,
  ) async {
    for (final width in const <double>[320, 390, 430]) {
      await _useFakeRepository(_FakeKidHomeRepository(hangLoad: true));
      await _pump(tester, width: width, textScale: 1.3);
      expect(find.bySemanticsLabel('Loading profiles'), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(find.byType(ProfileTile), findsNothing);
      expect(find.text(_title), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    }
  });

  testWidgets('failure: Pip + copy + retry, and the lock still escapes', (
    tester,
  ) async {
    await _useFakeRepository(_FakeKidHomeRepository(failTimes: 1));
    await _pump(tester);
    expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
    expect(find.text("Let's try again."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(PipAvatar), findsOneWidget);
    expect(find.byKey(_mayaTile), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // The retry really re-subscribed; the fake has no profiles, so the empty
    // roster message replaces the failure card.
    expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
    expect(find.byType(NestLockButton), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('the failure retry is reachable by its semantics tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _useFakeRepository(_FakeKidHomeRepository(failTimes: 1));
    await _pump(tester);
    final node = tester.getSemantics(find.bySemanticsLabel('Try again'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('empty roster (Seed.empty): message, no tiles, lock present', (
    tester,
  ) async {
    await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
    await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await _pump(tester, textScale: 1.3, theme: theme);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_sub), findsOneWidget);
      expect(find.text('Ask a grown-up to add your profile.'), findsOneWidget);
      expect(find.byType(ProfileTile), findsNothing);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    }
  });

  // -------------------------------------------------------------------------
  // Owner rules: dark tokens + the bottom edge
  // -------------------------------------------------------------------------

  testWidgets('dark: tiles, borders and pet tints all come from dark tokens', (
    tester,
  ) async {
    await _pump(tester, theme: ThemeMode.dark);
    const dark = NestColors.dark;
    final tiles = _tokensOf(tester);
    expect(tiles.surface, dark.surface);
    expect(tiles.ink, dark.ink);
    expect(tiles.lilacTint, dark.lilacTint);
    expect(tiles.peachTint, dark.peachTint);

    Color borderOf(ValueKey<String> key) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).border != null,
              ),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      return (decoration.border! as Border).top.color;
    }

    Color fillOf(ValueKey<String> key) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).border != null,
              ),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    Color petOf(ValueKey<String> key) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).shape ==
                        BoxShape.circle &&
                    (widget.decoration! as BoxDecoration).color != null,
              ),
            )
            .last,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    for (final key in const <ValueKey<String>>[_mayaTile, _leoTile]) {
      expect(borderOf(key), dark.ink, reason: '$key border');
      expect(fillOf(key), dark.surface, reason: '$key fill');
    }
    expect(petOf(_mayaTile), dark.lilacTint);
    expect(petOf(_leoTile), dark.peachTint);
    await disposeApp(tester);
  });

  testWidgets('dark: the sky and meadow flip, nothing is hard-coded', (
    tester,
  ) async {
    await _pump(tester, theme: ThemeMode.dark, pixels: true);
    const dark = NestColors.dark;
    // The meadow hill is pinned to the physical bottom edge (meadowBottom 0).
    // Sample BELOW the caption so the probe reads paint, never a glyph.
    _expectPixelNear(
      await _pixelAt(tester, 195, 838),
      dark.kidMeadow,
      'the hill must reach the bottom edge in dark mode too',
    );
    _expectPixelNear(
      await _pixelAt(tester, 195, 8),
      dark.kidSkyTop,
      'the sky gradient comes from the dark tokens',
    );
    await disposeApp(tester);
  });

  for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      '${_themeName(theme)}: bottom edge — no bar, no strip, meadow to the edge',
      (tester) async {
        // This screen has no bottom bar, so the bottom-edge owner rule has
        // nothing to align to; the proof is that the meadow still runs to the
        // physical edge (light AND dark, with and without a 34 px OS inset).
        await _pump(tester, theme: theme, bottomInset: 34, pixels: true);
        expect(
          find.byType(NestBottomCta),
          findsNothing,
          reason: 'the picker has no CTA panel',
        );
        // NestHomeIndicator is height-only in the running app (the OS draws
        // the pill), so nothing may sit between the caption and the edge.
        expect(
          tester.getRect(find.byType(NestHomeIndicator)).height,
          0,
          reason: 'the home indicator must not reserve height here',
        );
        final expected = theme == ThemeMode.light
            ? NestColors.light.kidMeadow
            : NestColors.dark.kidMeadow;
        // y=838 sits under the caption (which ends well above 830) and
        // y=843 is the last physical row.
        for (final y in const <double>[838, 843]) {
          for (final x in const <double>[8, 195, 382]) {
            _expectPixelNear(
              await _pixelAt(tester, x, y),
              expected,
              '($x, $y) must be meadow, not a strip of another colour',
            );
          }
        }
        await disposeApp(tester);
      },
    );
  }

  testWidgets('the status bar reserves height only (OS draws the glyphs)', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(NestStatusBar), findsOneWidget);
    expect(
      find.text('9:41'),
      findsNothing,
      reason: 'the mock clock is gallery-only; the OS draws the real bar',
    );
    await disposeApp(tester);
  });
}
