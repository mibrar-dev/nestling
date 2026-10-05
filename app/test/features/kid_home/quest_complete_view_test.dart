// K05 quest-complete view tests: copy parity, the child's own Pip, the
// database-driven growth card, every tap destination, the semantics contract
// (every control exposes `SemanticsAction.tap` and drives real navigation),
// the loading / failure / no-child / deep-link states, and the layout
// geometry (every painted rect against the design PNG ÷3, both themes,
// 320 px + 1.3x text without overflow).
//
// The happy path runs on the real seeded Drift database (`Seed.demo` has
// Maya, 175 lifetime coins, mochi/sunny Pip at stage 3, `q-tidy` worth 15);
// the states a healthy database cannot produce (silent stream, stream error,
// no active child) use a feature-local fake repository registered over the
// real one, exactly like `quest_detail_view_test.dart` does for K04.
//
// Every pumped app ends with `disposeApp` (see test_scope.dart) so Drift's
// deferred stream-close timer is drained.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
// `hide PipMood`: the barrel exports the v1 `PipMood` from `pip_rive.dart`,
// which collides with the v2 one `PipAvatar` uses (same shape as K04).
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

import '../../test_scope.dart';

/// The demo child, mirrored from `Seed.demo` (Maya: 120 coins, 175 lifetime,
/// mochi/sunny Pip at stage 3).
const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
  pipTotalCoins: 175,
);

/// The second demo child (Leo: bolt/sky Pip at stage 2), mirrored from
/// `Seed.demo`. Only the roster-rebuild probe needs him; CHILD order stays
/// Maya-then-Leo everywhere.
const KidChild _leo = KidChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '5-6',
  avatarColour: 'sky',
  coins: 45,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  happiness: 3,
  pinSet: true,
  pipTotalCoins: 60,
);

KidQuest _quest({
  String id = 'q-tidy',
  String title = 'Tidy your bedroom',
  int coins = 15,
  String status = 'to_do',
}) {
  return KidQuest(
    id: '$id:maya',
    title: title,
    detail: 'To do · +$coins',
    questId: id,
    icon: 'bed',
    coins: coins,
    status: status,
  );
}

/// The states a healthy seeded database cannot produce.
class _FakeKidHomeRepository extends KidHomeRepository {
  _FakeKidHomeRepository({
    this.items = const <KidQuest>[],
    this.child = _maya,
    this.failLoad = false,
    this.hang = false,
    // `secondRoster` → `liveProfiles` + `pushRoster`.
    this.liveProfiles = false,
  });

  List<KidQuest> items;
  KidChild? child;
  bool failLoad;
  bool hang;

  /// Serve the roster from a controller the test drives, so a roster change
  /// can arrive AFTER the first frame (see `pushRoster`).
  bool liveProfiles = false;
  final StreamController<List<KidChild>> _profiles =
      StreamController<List<KidChild>>.broadcast();

  /// Pushes a new roster to the bloc. Only valid with [liveProfiles].
  void pushRoster(List<KidChild> roster) => _profiles.add(roster);

  Future<void> closeProfiles() => _profiles.close();

  @override
  Future<List<KidQuest>> getItems() async => items;

  @override
  Stream<List<KidQuest>> watchItems() {
    if (hang) return const Stream<List<KidQuest>>.empty();
    if (failLoad) return Stream<List<KidQuest>>.error(Exception('items down'));
    return Stream<List<KidQuest>>.value(items);
  }

  @override
  Stream<List<KidChild>> watchProfiles() {
    if (liveProfiles) return _profiles.stream;
    final roster = child == null ? const <KidChild>[] : <KidChild>[child!];
    return Stream<List<KidChild>>.value(roster);
  }

  @override
  Stream<KidChild?> watchActiveChild() {
    if (hang) return const Stream<KidChild?>.empty();
    if (failLoad) {
      return Stream<KidChild?>.error(Exception('child down'));
    }
    return Stream<KidChild?>.value(child);
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Loads the bundled faces so the metrics match a device run: on
/// `flutter_test`'s default font the pill/bubble/hero glyphs measure wider and
/// every rect below them moves (same isolation as
/// `quest_detail_geometry_test.dart`).
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

/// Re-seeds the in-memory database with `Seed.empty` (an onboarded parent with
/// no children) over the REAL repository — the production-shaped way to reach
/// the "Who's playing?" branch.
Future<void> _useEmptySeed() async {
  final db = await setUpTestScope(seedDemo: false);
  await Seed.empty(db);
  await GetIt.instance<AppSession>().refresh();
}

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.complete,
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

/// Bounded route pumps: `pumpAndSettle` is avoided because a still-loading
/// screen spins an endless progress indicator.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pushes the celebration with the `extra` K04/K03 pass, so the coin count
/// comes from the celebration rather than from a deep link with no extra.
Future<void> _pushCelebration(
  WidgetTester tester, {
  int? coins = 15,
  String questId = 'q-tidy',
}) async {
  final context = tester.element(find.byType(Navigator).first);
  unawaited(
    GoRouter.of(context).push(
      KidHomeRoutePaths.complete,
      extra: <String, Object>{
        'questId': questId,
        'childId': 'maya',
        'coins': ?coins,
      },
    ),
  );
  await _settleRoute(tester);
}

/// The design's painted rects, measured from
/// `design/screens/light/K05-quest-complete.png` ÷3.
const Rect _designPip = Rect.fromLTWH(86, 119, 218, 218);
const Rect _designCoinPill = Rect.fromLTWH(121, 403, 147.67, 40);
const Rect _designBubble = Rect.fromLTWH(75, 501, 239.67, 44);
const Rect _designCard = Rect.fromLTWH(20, 561, 350, 134);
const Rect _designProgress = Rect.fromLTWH(39, 662, 312, 16);
const Rect _designCta = Rect.fromLTWH(20, 736, 350, 64);
const Rect _designLock = Rect.fromLTWH(314, 47, 56, 56);

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The `.kid-bar` surface: the only `Container` painted `surface` with a
/// TOP-ONLY 3 px ink border (the speech bubble has the same fill but a border
/// on all four sides, so the shape identifies the bar).
Finder _barSurfaceFinder(WidgetTester tester) {
  final surface = Theme.of(tester.element(find.byType(NestKidButton)))
      .extension<NestTokens>()!
      .surface;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration || box.color != surface) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 0 &&
        border.right.width == 0 &&
        border.bottom.width == 0;
  });
}

/// The `.k5-card` surface: the only `Container` painted `lilacTint`.
Finder _growthCardFinder(WidgetTester tester) {
  final lilac = Theme.of(tester.element(find.byType(NestProgress)))
      .extension<NestTokens>()!
      .lilacTint;
  return find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).color == lilac,
  );
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K05 quest complete — the celebration', () {
    // The bundled Nunito/Inter faces must be loaded BEFORE the first pump
    // that measures a pill/bubble/hero rect (see `_loadBundledFonts`).
    testWidgets('renders every element of the design', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, route: KidHomeRoutePaths.home);
      await _pushCelebration(tester);

      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      expect(find.byType(NestBalancedText), findsOneWidget);
      expect(find.byType(NestCoinPill), findsOneWidget);
      expect(find.text('+15 coins'), findsOneWidget);
      expect(
        find.bySemanticsLabel('15 coins earned'),
        findsOneWidget,
        reason: 'the pill announces the coins, not "+15 coins"',
      );
      expect(find.text('Mum will give it a thumbs-up soon.'), findsOneWidget);
      expect(find.byType(NestSpeechBubble), findsOneWidget);
      expect(find.text('Pip is doing a happy dance!'), findsOneWidget);
      expect(find.text('Pip needs 75 more coins to grow'), findsOneWidget);
      expect(find.text('175 of 250 coins'), findsOneWidget);
      expect(find.text('Next: Songbird'), findsOneWidget);
      expect(find.byType(NestProgress), findsOneWidget);
      expect(find.text('Yay! Back home'), findsOneWidget);
      expect(find.byType(NestKidButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);

      // PIP rule: the child's OWN Pip from the DB row (Maya = mochi/sunny/
      // stage 3), drawn as a `PipAvatar` — never a v1 `pip_stage_*.svg`.
      final pips = find.byType(PipAvatar);
      expect(pips, findsNWidgets(2));
      expect(tester.getSize(pips.first), const Size(218, 218));
      expect(tester.getSize(pips.last), const Size(32, 32));
      for (var i = 0; i < 2; i++) {
        final avatar = tester.widget<PipAvatar>(pips.at(i));
        expect(avatar.style, PipStyle.mochi);
        expect(avatar.skin, PipSkin.sunny);
        expect(avatar.stage, 3);
      }
      expect(
        tester.widget<PipAvatar>(pips.first).mood,
        PipMood.happy,
        reason: 'Pip is doing a happy dance',
      );

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the growth card reads the database, not the design', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      // Leo: 60 lifetime coins, bolt/sky Pip at stage 2 — every number must
      // follow the row (DATA OVER MOCKS), never the Maya design values.
      final repo = _FakeKidHomeRepository(
        child: const KidChild(
          id: 'leo',
          nickname: 'Leo',
          ageBand: '7-9',
          avatarColour: 'sky',
          coins: 45,
          pipStyle: 'bolt',
          pipSkin: 'sky',
          pipAccessory: 'none',
          pipStage: 2,
          happiness: 3,
          pinSet: true,
          pipTotalCoins: 60,
        ),
      );
      await _useFakeRepository(repo);
      await _pump(tester);

      expect(find.text('Brilliant, Leo!'), findsOneWidget);
      expect(find.text('Pip needs 190 more coins to grow'), findsOneWidget);
      expect(find.text('60 of 250 coins'), findsOneWidget);
      // Leo is a Hatchling (stage 2), so Pip grows into a Fledgling.
      expect(find.text('Next: Fledgling'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pip is 24% of the way to Fledgling'),
        findsOneWidget,
      );
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar).first);
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.stage, 2);
      // No extra on a direct launch: the pill honestly reads 0 coins rather
      // than borrowing another child's quest.
      expect(find.text('+0 coins'), findsOneWidget);

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a fully grown Pip says so and fills the bar', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(
        _FakeKidHomeRepository(
          child: const KidChild(
            id: 'maya',
            nickname: 'Maya',
            ageBand: '7-9',
            avatarColour: 'lilac',
            coins: 300,
            pipStyle: 'mochi',
            pipSkin: 'sunny',
            pipAccessory: 'none',
            pipStage: 4,
            happiness: 5,
            pinSet: true,
            pipTotalCoins: 260,
          ),
        ),
      );
      await _pump(tester);

      expect(find.text('Pip is ready to grow!'), findsOneWidget);
      expect(find.text('260 of 250 coins'), findsOneWidget);
      // Already a Songbird (stage 4): the clamp keeps "Next" on a real stage
      // instead of inventing a fifth one.
      expect(find.text('Next: Songbird'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pip is 100% of the way to Songbird'),
        findsOneWidget,
      );

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the extra coins win over the quest row', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _FakeKidHomeRepository(items: <KidQuest>[_quest()]);
      await _useFakeRepository(repo);
      await _pump(tester, route: KidHomeRoutePaths.home);
      await _pushCelebration(tester, coins: 30);

      expect(find.text('+30 coins'), findsOneWidget);
      expect(find.bySemanticsLabel('30 coins earned'), findsOneWidget);

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('without extra the named quest row supplies the coins', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = _FakeKidHomeRepository(
        items: <KidQuest>[
          _quest(id: 'q-reading', coins: 10),
          _quest(),
        ],
      );
      await _useFakeRepository(repo);
      await _pump(tester, route: KidHomeRoutePaths.home);
      // No `coins` in the extra: the view falls back to the named quest row.
      await _pushCelebration(tester, coins: null);

      expect(find.text('+15 coins'), findsOneWidget);

      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K05 quest complete — layout geometry', () {
    testWidgets('every painted rect matches the design PNG', (tester) async {
      const tolerance = 2.0;
      await _loadBundledFonts();
      await _pump(tester);

      void expectRect(Finder finder, Rect design, String what) {
        final actual = _rectOf(tester, finder);
        expect(
          (actual.left - design.left).abs(),
          lessThanOrEqualTo(tolerance),
          reason: '$what left: ${actual.left} vs design ${design.left}',
        );
        expect(
          (actual.top - design.top).abs(),
          lessThanOrEqualTo(tolerance),
          reason: '$what top: ${actual.top} vs design ${design.top}',
        );
        expect(
          (actual.width - design.width).abs(),
          lessThanOrEqualTo(tolerance),
          reason: '$what width: ${actual.width} vs design ${design.width}',
        );
        expect(
          (actual.height - design.height).abs(),
          lessThanOrEqualTo(tolerance),
          reason: '$what height: ${actual.height} vs design ${design.height}',
        );
      }

      // The Pip slot keeps the design's size and position. The design tilts it
      // `rotate(-8deg)`, which is a PAINT transform: the layout box stays the
      // design's 218×218 at x 86…304, while the painted bounds are the wider
      // rotated box. So compare the layout size (`getSize`) and the centre
      // (invariant under a rotation about the centre) — not the painted rect.
      final pip = tester.getRect(find.byType(PipAvatar).first);
      expect(
        tester.getSize(find.byType(PipAvatar).first),
        const Size(218, 218),
        reason: 'the design slot is 218 px',
      );
      expect(
        pip.center.dx,
        closeTo(_designPip.center.dx, tolerance),
        reason: 'Pip stays horizontally centred (design x 86…304)',
      );
      expect(
        pip.center.dy,
        closeTo(_designPip.center.dy, tolerance),
        reason: 'Pip stays at the design y 119…337',
      );
      expectRect(find.byType(NestCoinPill), _designCoinPill, 'coin pill');
      expectRect(find.byType(NestSpeechBubble), _designBubble, 'speech');
      expectRect(find.byType(NestProgress), _designProgress, 'progress bar');
      // The CTA is measured as the PAINTED rect: `NestKidButton`'s widget box
      // includes the 6 px shadow room it reserves under the painted button
      // (same convention as `quest_detail_geometry_test.dart`). And the bar
      // is measured RELATIVE to its own top edge: the app reserves the 34 px
      // home-indicator inset inside the bar surface (`SafeArea`) and the
      // test surface has no inset, so the bar rides 34 px lower here.
      final bar = _rectOf(tester, _barSurfaceFinder(tester));
      expect(bar.left, 0, reason: 'the bar surface runs to the screen edge');
      expect(bar.right, 390);
      expect(bar.bottom, 844, reason: 'no meadow strip under the bar');
      final ctaWidget = _rectOf(tester, find.byType(NestKidButton));
      final cta = Rect.fromLTRB(
        ctaWidget.left,
        ctaWidget.top,
        ctaWidget.right,
        ctaWidget.bottom - NestSpacing.gap6,
      );
      expect(cta.width, closeTo(_designCta.width, tolerance));
      expect(cta.height, closeTo(_designCta.height, tolerance));
      expect(cta.left, closeTo(_designCta.left, tolerance));
      expect(cta.top - bar.top, closeTo(15, tolerance));
      expectRect(find.byType(NestLockButton), _designLock, 'lock button');

      // The growth card is the widest painted surface; its rect anchors
      // everything below the speech bubble (UI CHECK MEASURES SHAPES).
      expectRect(_growthCardFinder(tester), _designCard, 'growth card');
      // 3 px border + 16 px padding ⇒ the bar inside starts at 39 and ends at
      // 351, so the card keeps the design's 20 px gutters exactly.
      final progress = _rectOf(tester, find.byType(NestProgress));
      expect(progress.left, closeTo(_designCard.left + 19, tolerance));
      expect(
        progress.right,
        closeTo(_designCard.right - 19, tolerance),
        reason: 'the card keeps its 20 px gutters + 3 px border + 16 px pad',
      );

      await disposeApp(tester);
    });

    testWidgets('the bar surface runs to the physical screen edge', (
      tester,
    ) async {
      await _pump(tester);
      final tokens = Theme.of(tester.element(find.byType(NestKidButton)))
          .extension<NestTokens>()!;
      final surface = _barSurfaceFinder(tester);
      expect(surface, findsOneWidget);
      final rect = tester.getRect(surface);
      expect(rect.left, 0, reason: 'the bar surface bleeds to the edge');
      expect(rect.right, 390, reason: 'no coloured strip under the bar');
      expect(rect.bottom, 844, reason: 'the inset belongs to the surface box');
      // The home indicator is never a coloured strip: whatever is painted
      // under the CTA is the bar's own surface.
      final barFill =
          tester.widget<Container>(surface).decoration! as BoxDecoration;
      expect(barFill.color, tokens.surface);
      expect(
        _rectOf(tester, find.byType(NestKidButton)).bottom,
        lessThanOrEqualTo(rect.bottom),
      );
      await disposeApp(tester);
    });

    testWidgets('the whole screen keeps 20 px side gutters', (tester) async {
      await _pump(tester);
      expect(_rectOf(tester, find.byType(NestKidButton)).left, closeTo(20, 1));
      expect(
        _rectOf(tester, find.byType(NestCoinPill)).center.dx,
        closeTo(195, 1),
        reason: 'the coin pill is centred like the design',
      );
      expect(
        _rectOf(tester, find.byType(NestSpeechBubble)).center.dx,
        closeTo(195, 1),
      );
      // Card, progress bar and CTA share the same 20 px edges.
      expect(_rectOf(tester, _growthCardFinder(tester)).left, closeTo(20, 1));
      expect(_rectOf(tester, _growthCardFinder(tester)).right, closeTo(370, 1));
      expect(
        _rectOf(tester, find.byType(NestKidButton)).right,
        closeTo(370, 1),
      );
      await disposeApp(tester);
    });
  });

  group('K05 quest complete — interactions', () {
    testWidgets('"Yay! Back home" goes to /kid-home', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Yay! Back home'));
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate exactly once', (
      tester,
    ) async {
      await _pump(tester);
      final lock = find.byType(NestLockButton);
      // No pump between the taps: a same-frame double tap must still push one
      // gate (K03-BUG-9 pattern).
      await tester.tap(lock);
      await tester.tap(lock);
      await _settleRoute(tester);
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      await disposeApp(tester);
    });

    testWidgets('every control exposes a tap action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      for (final label in <String>['Grown-ups', 'Yay! Back home']) {
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsWidgets, reason: '$label must be labelled');
        for (var i = 0; i < finder.evaluate().length; i++) {
          final data = tester.getSemantics(finder.at(i)).getSemanticsData();
          expect(
            data.hasAction(SemanticsAction.tap),
            isTrue,
            reason: '$label must be operable by VoiceOver/TalkBack',
          );
        }
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the accessibility actions drive real navigation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      tester.semantics.performAction(
        find.semantics.byLabel('Yay! Back home'),
        SemanticsAction.tap,
      );
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the growth card is announced as one sentence', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      expect(
        find.bySemanticsLabel(RegExp('Pip needs 75 more coins to grow')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Pip is 70% of the way to Songbird'),
        findsOneWidget,
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K05 quest complete — rebuild scope', () {
    // Review finding 9: an emission that only moves a channel this screen does
    // not draw (the K01 roster lives here) must not rebuild the 218 px Pip,
    // the burst plate and the growth card. `identical` on the built
    // `PipAvatar` is the proof: a rebuild constructs a new widget instance.
    testWidgets('a roster-only emission does not rebuild the celebration', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(liveProfiles: true);
      addTearDown(repo.closeProfiles);
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);

      // First roster: Maya, in creation order. Captured AFTER it settles, so
      // the next push is the only thing that can move the tree.
      repo.pushRoster(<KidChild>[_maya]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final before = tester.widget<PipAvatar>(find.byType(PipAvatar).first);
      final cardBefore = tester.widget<NestProgress>(find.byType(NestProgress));

      // A second, genuinely different roster (Leo joins) → the bloc emits a
      // state that differs ONLY in `profiles`, a K01 channel this screen does
      // not draw.
      repo.pushRoster(<KidChild>[_maya, _leo]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final after = tester.widget<PipAvatar>(find.byType(PipAvatar).first);
      final cardAfter = tester.widget<NestProgress>(find.byType(NestProgress));

      expect(
        identical(before, after),
        isTrue,
        reason: 'the K01 roster channel must not rebuild this screen',
      );
      expect(identical(cardBefore, cardAfter), isTrue);
      // …and the celebration is still fully on screen afterwards.
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      expect(find.text('175 of 250 coins'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);

      await disposeApp(tester);
    });
  });

  group('K05 quest complete — the other states', () {
    testWidgets('a silent stream shows the loading state', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(_FakeKidHomeRepository(hang: true));
      await _pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading your celebration'), findsOneWidget);
      // The top row is already there, so nothing jumps when the celebration
      // arrives.
      expect(find.byType(NestLockButton), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a broken stream shows Pip lost and reloads on retry', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failLoad: true);
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text("Let's try again."), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);

      repo.failLoad = false;
      await tester.tap(find.text('Try again'));
      await _settleRoute(tester);
      expect(find.text('Brilliant, Maya!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('no active child asks who is playing', (tester) async {
      await _useFakeRepository(_FakeKidHomeRepository(child: null));
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byType(NestCoinPill), findsNothing);
      await tester.tap(find.text('Choose'));
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);
    });

    testWidgets('Seed.empty (no children) asks who is playing', (tester) async {
      await _useEmptySeed();
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byType(NestCoinPill), findsNothing);
      await disposeApp(tester);
    });
  });

  group('K05 quest complete — resilience', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('loaded: 320px @ 1.3x in ${theme.name}', (tester) async {
        await _pump(tester, width: 320, textScale: 1.3, theme: theme);
        expect(find.text('Brilliant, Maya!'), findsOneWidget);
        expect(find.text('Yay! Back home'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });

      testWidgets('loading: 320px @ 1.3x in ${theme.name}', (tester) async {
        await _useFakeRepository(_FakeKidHomeRepository(hang: true));
        await _pump(tester, width: 320, textScale: 1.3, theme: theme);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });

      testWidgets('failure: 320px @ 1.3x in ${theme.name}', (tester) async {
        await _useFakeRepository(_FakeKidHomeRepository(failLoad: true));
        await _pump(tester, width: 320, textScale: 1.3, theme: theme);
        expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });

      testWidgets('no active child: 320px @ 1.3x in ${theme.name}', (
        tester,
      ) async {
        await _useFakeRepository(_FakeKidHomeRepository(child: null));
        await _pump(tester, width: 320, textScale: 1.3, theme: theme);
        expect(find.text("Who's playing?"), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('K05 quest complete — copy parity and hygiene', () {
    testWidgets('every string matches the HTML character for character', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _loadBundledFonts();
      await _pump(tester);
      // `design/html-source/screens/K05-quest-complete.html`: the hero, the
      // pill, the promise, the cheer, the card and the CTA — all `Text`.
      const expected = <String>[
        'Brilliant, Maya!',
        '+15 coins',
        'Mum will give it a thumbs-up soon.',
        'Pip is doing a happy dance!',
        'Pip needs 75 more coins to grow',
        '175 of 250 coins',
        'Next: Songbird',
        'Yay! Back home',
      ];
      for (final copy in expected) {
        expect(
          find.text(copy),
          findsOneWidget,
          reason: '$copy must render verbatim',
        );
      }
      // The lock's `aria-label` is a semantics property, not a `Text`.
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      // No curly quotes, en/em dashes or ellipsis sneak in on this screen.
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          final value = w.data ?? '';
          return RegExp('[‘’“”–—…]').hasMatch(value);
        }),
        findsNothing,
      );
      // `thumbs-up` keeps the design's hyphen-minus (U+002D), not a dash.
      final sub = tester.widget<Text>(
        find.text('Mum will give it a thumbs-up soon.'),
      );
      expect(
        sub.data!.indexOf('-'),
        25,
        reason: 'the only dash is in thumbs-up',
      );
      expect(
        sub.data!.codeUnitAt(25),
        0x2D,
        reason: 'U+002D hyphen-minus, not U+2010/2011/2013/2014',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    test('no google_fonts / clock / hand-rolled ids in the view', () {
      // Source-level hygiene: the screen layer must never reintroduce the
      // removed google_fonts, never read the wall clock, and never mint ids.
      // Plain `test`, not `testWidgets` — no widget is pumped here, so the
      // `disposeApp` drain does not apply.
      const source =
          'lib/features/kid_home/presentation/views/'
          'quest_complete_view.dart';
      final file = File('${Directory.current.path}/$source');
      expect(file.existsSync(), isTrue, reason: '$source must exist');
      final text = file.readAsStringSync();
      expect(text, isNot(contains('google_fonts')));
      expect(text, isNot(contains('GoogleFonts')));
      expect(text, isNot(contains('DateTime.now')));
      expect(text, isNot(contains('newId')));
    });
  });
}
