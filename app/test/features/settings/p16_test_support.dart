// P16 Settings — shared harness for every settings test.
//
// Three things the P16 tests need:
//
// 1. The REAL app at `/settings` (`pumpSettingsApp`) — DI, router, shell tab
//    bar and the seeded in-memory Drift database — on a surface of a chosen
//    width / height / text scale / theme. `pumpAppRoute` hard-codes 390x844 at
//    scale 1.0 and light theme; the responsive sweep needs 320 and 430, both
//    text scales and dark mode.
// 2. The bundled families. Widget tests do NOT load Inter/Nunito
//    automatically and the fallback face is much wider, which invents
//    overflows that do not happen on device (see P14's `p14_test_support.dart`
//    for the same reasoning). Every test that measures geometry or asserts
//    "no overflow" calls [loadP16Fonts].
// 3. A faked DEVICE time zone, so the move banner is reachable in the real
//    app: `FamilyZoneService` is re-registered in the test's own GetIt before
//    the first frame, which is what `settings_di.dart` resolves for the bloc.
//    No platform channel, no simulator.
//
// Raw DB access always goes through [settingRows] / [familyZoneId] /
// [childRows]: an assertion about what a tap really wrote reads the table,
// never the widget's optimistic state.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';
import 'package:nestling/features/settings/presentation/widgets/p16_transient_guard.dart';
import 'package:nestling/features/settings/settings_routes.dart';

import '../../test_scope.dart';

/// The instant every test is pinned to (Sat 3 Oct 2026 09:41 Europe/London =
/// 08:41Z) by `app/test/flutter_test_config.dart`. October is BST, so London
/// is `GMT+1` and Dubai `GMT+4` on this day.
final DateTime p16PinnedNowUtc = DateTime.utc(2026, 10, 3, 8, 41);

/// Loads the bundled Inter/Nunito faces into the test font manager.
Future<void> loadP16Fonts() async {
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

/// The device surface the designs were drawn at (390x844).
const Size p16DesignSize = Size(390, 844);

/// Pumps the real app at `/settings` on a chosen surface.
///
/// [prepare] runs against the seeded in-memory database BEFORE the first
/// frame, so a test can open the screen on the empty seed. [deviceZone] fakes
/// the phone's zone (the move banner only appears when it differs from the
/// stored family zone).
Future<void> pumpSettingsApp(
  WidgetTester tester, {
  Size size = p16DesignSize,
  double textScale = 1.0,
  ThemeMode theme = ThemeMode.light,
  bool seedDemo = true,
  Future<void> Function(AppDatabase database)? prepare,
  String? deviceZone,
}) async {
  final database = await setUpTestScope(seedDemo: seedDemo);
  if (prepare != null) {
    await prepare(database);
    // `setUpTestScope` only refreshes the session when it seeds the demo, so
    // a hand-seeded database (the empty seed) has to be picked up here or the
    // router would redirect the app to /welcome.
    await GetIt.instance<AppSession>().refresh();
  }
  if (deviceZone != null) {
    await GetIt.instance.unregister<FamilyZoneService>();
    GetIt.instance.registerSingleton<FamilyZoneService>(
      FamilyZoneService(database, deviceZoneReader: () async => deviceZone),
    );
  }
  await pumpAppRoute(tester, SettingsRoutePaths.settings, theme: theme);
  _resetTransientGuard();
  _applySurface(tester, size: size, textScale: textScale);
  await tester.pump();
  await settleSettings(tester);
}

/// Clears the static tap guard before the first frame.
///
/// `P16TransientGuard` is process-wide state (a `static DateTime?`), so a test
/// that closes a modal leaves a 300 ms suppression window behind for the NEXT
/// test in the same isolate — which would silently swallow that test's first row
/// tap and look like a broken screen. Both pumps call this; iteration 3 added
/// it to [pumpSettingsSurface] as well, since that pump had been left out when
/// the guard landed (every test using it so far only reads the screen, so
/// nothing failed).
void _resetTransientGuard() => P16TransientGuard.reset();

/// Lets the real database deliver the bloc's watched streams.
///
/// `SettingsBloc` serves the screen from `emit.forEach` over Drift query
/// streams. Under a widget test's fake clock those never fire, so the screen
/// would sit in its loading state forever — the screen is fine, the harness
/// has to give the event loop real time (`pumpAndSettle` cannot help: the
/// loading spinner animates forever). Same reason P14's `rewardIdsInAppOrder`
/// is wrapped in `tester.runAsync`.
Future<void> settleSettings(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [SettingsView] directly around [bloc] — the only way to hold the
/// screen in its loading or failure state, which the route itself resolves
/// before the first frame is asserted on.
Future<void> pumpSettingsSurface(
  WidgetTester tester,
  SettingsBloc bloc, {
  Size size = p16DesignSize,
  double textScale = 1.0,
  ThemeMode theme = ThemeMode.light,
}) async {
  _resetTransientGuard();
  _applySurface(tester, size: size, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: const SettingsView(),
      ),
    ),
  );
  await tester.pump();
  await settleSettings(tester);
}

void _applySurface(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// A bloc around the test database with a faked device zone, for the direct
/// [pumpSettingsSurface] pump. `null` means "unreadable device zone", which is
/// the unit-test default: no move banner.
SettingsBloc settingsBlocWithDeviceZone({String? deviceZone}) {
  final database = GetIt.instance<AppDatabase>();
  return SettingsBloc(
    repository: GetIt.instance<SettingsRepository>(),
    zoneService: FamilyZoneService(
      database,
      deviceZoneReader: deviceZone == null
          ? () async => throw Exception('no device zone')
          : () async => deviceZone,
    ),
  );
}

/// The settings scroll, addressed from inside [SettingsView] so the shell's
/// own scrollables can never be picked up by mistake.
Finder settingsScrollable() => find
    .descendant(
      of: find.byType(SettingsView),
      matching: find.byType(Scrollable),
    )
    .first;

/// Scrolls the settings list until [finder] is on screen (the ListView builds
/// lazily, so rows below the fold are not in the tree yet).
Future<void> scrollSettingsTo(WidgetTester tester, Finder finder) async {
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: settingsScrollable(),
  );
  await tester.pumpAndSettle();
}

/// The subscription card, found through its own copy rather than a widget key.
///
/// ORCHESTRATOR_NOTES (06:58) item 1 orders the local subcard fork reverted to
/// the shared `NestCard`, and the integrator deliberately deferred that. Both
/// shells render a `Container`, so addressing the card by copy keeps this suite
/// measuring the DESIGN in either world: the design numbers (16 px radius,
/// 14/16 padding) are what the assertions below carry, and a bare
/// `NestCard` — `NestRadii.allL` 24 px, `all(16)` padding — fails them with a
/// legible design message instead of "found 0 widgets with key".
Finder subscriptionCard() => find
    .ancestor(
      of: find.text('Nestling Annual · £29.99/year'),
      matching: find.byType(Container),
    )
    .first;

/// Scrolls the settings list back UP until [finder] is on screen.
///
/// [`scrollSettingsTo`] walks down only (`scrollUntilVisible` maps a positive
/// delta to a downward drag), so anything above the current offset — the move
/// banner, the title — has to come back with this. A negative delta is what
/// flips the direction.
Future<void> scrollSettingsUpTo(WidgetTester tester, Finder finder) async {
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    -240,
    scrollable: settingsScrollable(),
  );
  await tester.pumpAndSettle();
}

/// Raw `settings` rows for the seeded family.
Future<List<Setting>> settingRows() {
  final db = GetIt.instance<AppDatabase>();
  return (db.select(
    db.settings,
  )..where((s) => s.familyId.equals(Seed.familyId))).get();
}

/// The stored family zone (`families.time_zone`).
Future<String> familyZoneId() async {
  final db = GetIt.instance<AppDatabase>();
  final row = await (db.select(
    db.families,
  )..where((f) => f.id.equals(Seed.familyId))).getSingle();
  return row.timeZone;
}

/// Raw `children` rows, in table order.
Future<List<ChildrenData>> childRows() {
  final db = GetIt.instance<AppDatabase>();
  return (db.select(
    db.children,
  )..where((c) => c.familyId.equals(Seed.familyId))).get();
}

/// Every semantics node in the pumped tree that exposes a tap action.
///
/// Text fields are excluded for the same reason P14 excludes them: the
/// framework gives an editable its own node whose label lives on a sibling,
/// and `NestTextField` is shared code — counting it would report a shared
/// component's announcement style, not a P16 defect. Every other tappable node
/// must announce itself.
List<SemanticsNode> tappableNodes(WidgetTester tester) {
  final views = tester.binding.renderViews;
  final root = views.isEmpty
      ? null
      : views.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root == null) {
    throw StateError(
      'no semantics tree: call tester.ensureSemantics() and pump first',
    );
  }
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap) &&
        !data.flagsCollection.isTextField) {
      found.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found;
}

/// Tokens for [theme] without pumping anything.
NestTokens p16Tokens(ThemeMode theme) =>
    (theme == ThemeMode.dark ? NestTheme.dark() : NestTheme.light())
        .extension<NestTokens>()!;

/// The [node]'s rect in view coordinates.
///
/// Row labels merge with their row's other text (Flutter announces one node
/// per gesture boundary), so `find.bySemanticsLabel` cannot address P16's rows
/// by their copy — the semantics tree has to be walked instead.
Rect p16NodeRect(WidgetTester tester, SemanticsNode node) {
  // Each node's `transform` maps it into its PARENT's space, so the rect in
  // view coordinates is the node's rect with every ancestor transform applied
  // in turn, then divided by the device pixel ratio (the chain ends at the
  // render view, which is in physical pixels). The result is the same space
  // `tester.getRect` reports, so the two are directly comparable.
  var rect = node.rect;
  for (SemanticsNode? step = node; step != null; step = step.parent) {
    final transform = step.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  final ratio = tester.view.devicePixelRatio;
  return Rect.fromLTRB(
    rect.left / ratio,
    rect.top / ratio,
    rect.right / ratio,
    rect.bottom / ratio,
  );
}

/// Activates [node] the way a screen reader does.
///
/// `tester.semantics.performAction` needs a Finder that matches exactly one
/// node, and P16's rows merge their title, subtitle and chevron into one node
/// (so no `find.bySemanticsLabel` can address them). Going through the
/// semantics owner by node id performs the action on the node the test
/// actually inspected.
Future<void> p16ActivateSemantics(
  WidgetTester tester,
  SemanticsNode node,
) async {
  final data = node.getSemanticsData();
  if (!data.hasAction(SemanticsAction.tap)) {
    throw StateError('"${data.label}" exposes no SemanticsAction.tap');
  }
  // The same call `tester.semantics.performAction` makes once its Finder has
  // resolved to this node — reached through the node so a merged label can
  // still be addressed.
  node.owner!.performAction(node.id, SemanticsAction.tap);
  await tester.pump();
}

/// Every tappable node whose announced label contains [fragment].
///
/// Substring, not equality: on P16 the row title, its subtitle and its
/// chevron are announced by ONE node, and the toggle rows merge their title
/// with the switch's own label.
List<SemanticsNode> p16Announcing(WidgetTester tester, String fragment) =>
    tappableNodes(tester)
        .where((node) => node.getSemanticsData().label.contains(fragment))
        .toList();
