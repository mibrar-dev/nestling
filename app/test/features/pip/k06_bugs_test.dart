// K06 (Pip's nest) adversarial suite — Stage 6 bug hunt.
//
// Bug proofs are skipped with `skip: true` and carry their bug id in the
// test description (Flutter's `test`/`testWidgets` take a bool skip, so the
// id cannot live in the skip argument), exactly like the K01/K03 precedent.
// `flutter test --run-skipped <file>` runs them all; each one FAILS until
// its bug is fixed.
//
// ITERATION 2: all six iteration-1 proofs are FIXED and run live. Stage 2a
// took K06-BUG-1 (lost update in the repository's read-modify-write care
// path) and K06-BUG-2 (concurrent buys overspending a 120-coin balance) by
// making both writes atomic and conditional; stage 2b took K06-BUG-3
// (heading apostrophe), K06-BUG-4 (nest art box), K06-BUG-5 (equal
// care-button heights) and K06-BUG-6 (the invisible dashed locked border).
// This iteration also adds: the dark-mode half of the K06-BUG-6 pixel
// proof, two green end-to-end two-thumb burst regressions (care and
// wardrobe), and the one parked iteration-2 finding, K06-BUG-7 (a buy
// refused by the fresh balance is silent — no kind toast).
//   flutter test test/features/pip/k06_bugs_test.dart --run-skipped --plain-name K06-BUG-7
//
// Evidence, repro and suggested fixes for every finding live in
// docs/screens/K06/6_bugs.md. This stage does not change product code.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_care_button.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _coins(AppDatabase db, [String childId = 'maya']) async {
  final row = await (db.select(
    db.children,
  )..where((c) => c.id.equals(childId))).getSingle();
  return row.coins;
}

Future<bool> _owned(AppDatabase db, String item, [String id = 'maya']) async {
  final row = await (db.select(
    db.pipWardrobe,
  )..where((w) => w.childId.equals(id) & w.item.equals(item))).getSingle();
  return row.owned;
}

/// Waits (real async) until [ready] holds, up to ~3 s. Used before a burst
/// so the bloc has cached the loaded nest, exactly like the widget does.
Future<void> _waitFor(bool Function() ready) async {
  for (var i = 0; i < 300 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue, reason: 'the nest did not finish loading');
}

/// Pump helper. `pumpAppRoute` pins the surface to 390x844, so a requested
/// width is re-applied AFTER the pump — the K06 view test's `_pumpNest`
/// sets it before and therefore runs the whole width matrix at 390 (see
/// 6_bugs.md, test-infrastructure note). Probes here measure the real
/// width.
Future<void> _pumpPip(
  WidgetTester tester, {
  double width = NestDevice.width,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpAppRoute(tester, '/pip', theme: theme);
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
}

/// WCAG relative luminance for a Flutter colour.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between [a] and [b].
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// RepaintBoundary key for the locked-border pixel probe.
const Key _pixelProbe = ValueKey<String>('k06_pixel_probe');

/// Pumps `/pip` inside a [RepaintBoundary] so painted pixels can be sampled.
Future<void> _pumpPipForPixels(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(
    NestDevice.width * 3,
    NestDevice.height * 3,
  );
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/pip'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Number of border-band pixels along the tile's top border band
/// (y = top + 1): the 3 px stroke of a painted border reads differently from
/// the surface fill. Light theme: the `ink-2` stroke is dark on the light
/// `surface-2` fill → [bright] false counts it. Dark theme: `ink-2` is light
/// on the dark fill → [bright] true. Scans the full width so a dashed stroke
/// is caught regardless of the dash phase.
Future<int> _topBandPixels(
  WidgetTester tester,
  Rect tile, {
  required bool bright,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  var hits = 0;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final y = (tile.top + 1).round();
    for (
      var x = (tile.left + 4).round();
      x <= (tile.right - 4).round();
      x += 2
    ) {
      final o = (y * image.width + x) * 4;
      final r = data.getUint8(o) / 255;
      final g = data.getUint8(o + 1) / 255;
      final b = data.getUint8(o + 2) / 255;
      final l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      if (bright ? l > 0.6 : l < 0.4) hits++;
    }
  });
  return hits;
}

// ---------------------------------------------------------------------------
// Bug proofs. The six iteration-1 proofs run live as the regression guard
// (K06-BUG-1 / K06-BUG-2 the logic layer's races, K06-BUG-3 … K06-BUG-6 the
// UI layer's). K06-BUG-7 is parked with `skip: true` until the buy-feedback
// gap is fixed.
// ---------------------------------------------------------------------------

void main() {
  group('K06 bug proofs', () {
    test('K06-BUG-1: two rapid Feed taps must spend 10 coins, not 5', () async {
      // Regression for the fixed lost update: `_care` used to read the
      // child row, then write `kid.coins - cost` from that stale read, and
      // the bloc processes events concurrently (bloc 9 default), so two
      // taps in a burst both read 120 and both wrote 115. It is one
      // conditional UPDATE now; the burst must charge both taps.
      final db = AppDatabase.memory();
      await Seed.demo(db);
      final bloc = PipBloc(repository: PipRepositoryImpl(db: db));
      final sub = bloc.stream.listen((_) {});
      bloc.add(const PipLoadRequested());
      await _waitFor(() => bloc.state.status == PipStatus.loaded);

      bloc
        ..add(const PipCareRequested(PipCareKind.feed))
        ..add(const PipCareRequested(PipCareKind.feed));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(
        await _coins(db),
        110,
        reason: 'two 5-coin feeds must deduct 10 coins (120 - 5 - 5)',
      );
      await sub.cancel();
      await bloc.close();
      await db.close();
    });

    test('K06-BUG-2: two quick wardrobe buys must not overspend a 120-coin balance', () async {
      // Regression for the fixed overspend: the bloc pre-check still uses
      // the cached `state.nest.profile.coins`, and `buyItem` used to
      // re-check affordability outside its transaction, so both taps
      // (Wellies 40 + Crown 120) succeeded from a 120-coin balance. The
      // atomic transaction now lets exactly one through.
      final db = AppDatabase.memory();
      await Seed.demo(db);
      final bloc = PipBloc(repository: PipRepositoryImpl(db: db));
      final sub = bloc.stream.listen((_) {});
      bloc.add(const PipLoadRequested());
      await _waitFor(() => bloc.state.status == PipStatus.loaded);

      bloc
        ..add(const PipWardrobeBuyRequested('wellies'))
        ..add(const PipWardrobeBuyRequested('crown'));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final wellies = await _owned(db, 'wellies');
      final crown = await _owned(db, 'crown');
      expect(
        <bool>[wellies, crown].where((b) => b).length,
        1,
        reason:
            'only one of 40 + 120 can be afforded from 120 coins; '
            'measured wellies=$wellies crown=$crown coins=${await _coins(db)}',
      );
      await sub.cancel();
      await bloc.close();
      await db.close();
    });

    testWidgets(
      "K06-BUG-3: the heading must be the HTML source's ASCII \"Pip's wardrobe\"",
      (tester) async {
        // The HTML source (and both design PNGs) use an ASCII apostrophe
        // (U+0027). The screen renders U+2019 instead. Orchestrator COPY
        // rule; K01 fixed the same class of bug to ASCII.
        await setUpTestScope();
        await _pumpPip(tester);
        expect(
          find.text("Pip's wardrobe"),
          findsOneWidget,
          reason: 'design/html-source/screens/K06-pip.html uses 0x27',
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'K06-BUG-4: the nest art box must be 230 x 206, not 230 x 230',
      (tester) async {
        // `.k6-pet .nest { width:230px; height:206px }` (K06-pip.html).
        // The design PNG renders the nest at the same 206 scale (measured
        // outer ellipse width 173 px = 202 x 206/240; the app draws
        // 202 x 230/240 = 194 px, 12 % too large, rim ~14 px too high).
        await setUpTestScope();
        await _pumpPip(tester);
        final nest = find
            .descendant(
              of: find.byKey(const Key('k06-pet')),
              matching: find.byType(SvgPicture),
            )
            .first;
        expect(
          tester.getSize(nest),
          const Size(230, 206),
          reason: 'the nest SvgPicture is stretched to 230 x 230',
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'K06-BUG-5: at text scale 1.3 the three care buttons share one height',
      (tester) async {
        // `.k6-care` is a flex row: every `.btn-kid` stretches to the
        // tallest column. Flutter's Row (crossAxisAlignment.start) lets the
        // Play column grow (the 19 px Free pill at 1.3) while Feed and Bath
        // stay at their 91 px floor: measured 96 / 101 / 96.
        await setUpTestScope();
        await _pumpPip(tester, textScale: 1.3);
        final heights = <double>[
          for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
            tester.getSize(find.byKey(Key(id))).height,
        ];
        expect(
          heights.toSet(),
          hasLength(1),
          reason:
              'design stretches all three care buttons to equal height; '
              'measured $heights',
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'K06-BUG-6: locked wardrobe tiles paint the 3 px dashed ink border',
      (tester) async {
        // `.k6-item.locked` paints a 3 px dashed `ink-2` border (HTML source
        // + both design PNGs; the UI stage's D1 measures the same in the
        // simulator). The screen-local `_DashedBorderPainter` is attached as
        // `CustomPaint.painter`, which paints BEHIND the child — and the
        // child Container's opaque `surface-2` decoration then covers the
        // whole tile, border band included, so no border is visible.
        await setUpTestScope();
        await _pumpPipForPixels(tester);
        final owned = tester.getRect(find.byKey(const Key('k06-ward-scarf')));
        final locked = tester.getRect(
          find.byKey(const Key('k06-ward-wellies')),
        );

        expect(
          await _topBandPixels(tester, owned, bright: false),
          greaterThan(0),
          reason: 'control: the owned tile must show its solid ink border',
        );
        expect(
          await _topBandPixels(tester, locked, bright: false),
          greaterThan(0),
          reason: 'the locked tile must show the dashed ink-2 border',
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'K06-BUG-6 (dark): locked wardrobe tiles paint the dashed border too',
      (tester) async {
        // Same proof in the night theme: `ink-2` is light on the dark
        // `surface-2` fill, so the band scan counts bright pixels instead.
        await setUpTestScope();
        await _pumpPipForPixels(tester, theme: ThemeMode.dark);
        final owned = tester.getRect(find.byKey(const Key('k06-ward-scarf')));
        final locked = tester.getRect(
          find.byKey(const Key('k06-ward-wellies')),
        );
        expect(
          await _topBandPixels(tester, owned, bright: true),
          greaterThan(0),
          reason: 'control: the owned tile border is visible in dark mode',
        );
        expect(
          await _topBandPixels(tester, locked, bright: true),
          greaterThan(0),
          reason: 'the locked tile dashed border must be visible in dark mode',
        );
        await disposeApp(tester);
      },
    );

    test(
      'K06-BUG-7: a buy refused by the fresh balance must still be announced',
      () async {
        // Since the iteration-2 atomics, `buyItem` refuses a purchase the
        // blocs stale pre-check cannot see (the sibling tap spent the coins
        // first). The refusal is silent: `buyItem` returns void, so the bloc
        // never emits `kPipNotEnoughCoins` and the child gets no feedback
        // for the second tile (1_plan.md section 1f: locked-tile failure ->
        // kind toast). The money is safe; the feedback is missing.
        final db = AppDatabase.memory();
        await Seed.demo(db);
        final bloc = PipBloc(repository: PipRepositoryImpl(db: db));
        final sub = bloc.stream.listen((_) {});
        bloc.add(const PipLoadRequested());
        await _waitFor(() => bloc.state.status == PipStatus.loaded);

        bloc
          ..add(const PipWardrobeBuyRequested('wellies'))
          ..add(const PipWardrobeBuyRequested('crown'));
        await Future<void>.delayed(const Duration(milliseconds: 300));

        final wellies = await _owned(db, 'wellies');
        final crown = await _owned(db, 'crown');
        expect(
          <bool>[wellies, crown].where((b) => b).length,
          1,
          reason: 'one of 40 + 120 fits in 120 coins',
        );
        expect(
          bloc.state.actionError,
          kPipNotEnoughCoins,
          reason:
              'the refused purchase must announce "Not enough coins yet — '
              'keep going!"; measured ${bloc.state.actionError}',
        );
        await sub.cancel();
        await bloc.close();
        await db.close();
      },
      skip: true,
    );
  });

  // -------------------------------------------------------------------------
  // Clean probes (green)
  // -------------------------------------------------------------------------

  group('K06 probes', () {
    testWidgets('an empty family shows the choose-a-player state', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await _pumpPip(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.text('Choose'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('an empty wardrobe hides the heading and keeps the caption', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.delete(
        db.pipWardrobe,
      )..where((w) => w.childId.equals('maya'))).go();
      await _pumpPip(tester);
      expect(find.textContaining('wardrobe'), findsNothing);
      expect(find.byKey(const Key('k06-caption')), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('9999 lifetime coins clamps the bar and stays affordable', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(9999), pipTotalCoins: Value(9999)),
      );
      await _pumpPip(tester);
      expect(find.text('9999 coins'), findsOneWidget);
      expect(
        tester.widget<NestProgress>(find.byType(NestProgress)).fraction,
        1,
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('with 3 coins Bath stays operable while Feed disables', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(3)),
      );
      await _pumpPip(tester);
      final feed = tester.getSemantics(
        find.bySemanticsLabel('Feed Pip, costs 5 coins'),
      );
      expect(feed.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        feed.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );

      final bathFinder = find.bySemanticsLabel('Bathe Pip, costs 3 coins');
      final bath = tester.getSemantics(bathFinder);
      expect(bath.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      bath.owner!.performAction(bath.id, SemanticsAction.tap);
      await tester.pump(const Duration(milliseconds: 300));
      expect(await _coins(db), 0);
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('a deep-linked Back lands on /kid-home', (tester) async {
      await setUpTestScope();
      await _pumpPip(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a Grown-ups burst opens one gate and back returns', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPip(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.tap(find.bySemanticsLabel('Grown-ups'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/parental-gate');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/pip');
      await disposeApp(tester);
    });

    testWidgets('Leo renders his own Bolt / sky Pip at stage 2', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('leo')),
      );
      await _pumpPip(tester);
      expect(find.text('Pip · Hatchling'), findsOneWidget);
      final avatar = tester.widget<PipAvatar>(
        find
            .descendant(
              of: find.byKey(const Key('k06-pet')),
              matching: find.byType(PipAvatar),
            )
            .first,
      );
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.stage, 2);
      await disposeApp(tester);
    });

    testWidgets('six children and a long UK nickname still render the nest', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(nickname: Value('Maximilian-Alexander')),
      );
      for (var i = 0; i < 4; i++) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'extra$i',
                familyId: Seed.familyId,
                nickname: 'Extra child $i',
                createdAt: Value(DateTime.utc(2026, 9, 19, 9, i)),
              ),
            );
      }
      await _pumpPip(tester);
      expect(find.text('Pip · Fledgling'), findsOneWidget);
      expect(find.byKey(const Key('k06-grow')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a real 320 px surface at 1.3x renders without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPip(tester, width: 320, textScale: 1.3);
      final media = MediaQuery.sizeOf(
        tester.element(find.byType(Navigator).first),
      );
      expect(media.width, 320, reason: 'the probe must run at a real 320 px');
      expect(find.byType(PipCareButton), findsNWidgets(3));
      expect(find.byType(PipWardrobeTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a two-thumb care burst charges every tap (feed + bath)', (
      tester,
    ) async {
      // Iteration-2 regression: the two recognizers fire in one turn and the
      // atomic `_care` must charge each one against the current balance.
      final db = await setUpTestScope();
      await _pumpPip(tester);
      final feed = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('k06-feed'))),
      );
      final bath = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('k06-bath'))),
      );
      await feed.up();
      await bath.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(await _coins(db), 112, reason: '120 - 5 - 3');
      await disposeApp(tester);
    });

    testWidgets('a two-thumb buy burst cannot overspend (wellies + crown)', (
      tester,
    ) async {
      // Iteration-2 regression: both tiles pass the stale in-bloc
      // affordability pre-check; the transaction may only let one through.
      final db = await setUpTestScope();
      await _pumpPip(tester);
      final wellies = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('k06-ward-wellies'))),
      );
      final crown = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('k06-ward-crown'))),
      );
      await wellies.up();
      await crown.up();
      await tester.pump(const Duration(milliseconds: 600));
      final ownedWellies = await _owned(db, 'wellies');
      final ownedCrown = await _owned(db, 'crown');
      expect(
        <bool>[ownedWellies, ownedCrown].where((b) => b).length,
        1,
        reason: '40 + 120 cannot both fit in 120 coins',
      );
      expect(await _coins(db), ownedWellies ? 80 : 0);
      await disposeApp(tester);
    });

    testWidgets('copy keeps the design middle dot and em dash', (tester) async {
      await setUpTestScope();
      await _pumpPip(tester);
      expect(find.text('Pip · Fledgling'), findsOneWidget);
      expect(find.text('Growing into a Songbird'), findsOneWidget);
      expect(
        find.text('Nothing here is a chore — it is all just for fun.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    test('dark-mode K06 colour pairs keep at least 4.5:1', () {
      const c = NestColors.dark;
      final pairs = <(String, Color, Color)>[
        ('Feed label on peach', c.onWarm, c.peach),
        ('Play label on sky', c.onAccent, c.sky),
        ('Bath label on surface', c.ink, c.surface),
        ('Owned on surface', c.leafInk, c.surface),
        ('Locked name on surface-2', c.ink2, c.surface2),
        ('Free pill text on surface', c.ink, c.surface),
        ('Growth heading on lilac-tint', c.ink, c.lilacTint),
        ('Growth caption on lilac-tint', c.ink2, c.lilacTint),
        ('Section heading on sky', c.ink, c.kidSkyBottom),
        ('Caption on meadow', c.ink2, c.kidMeadow),
      ];
      for (final (name, fg, bg) in pairs) {
        expect(
          _contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$name is below the 4.5:1 floor',
        );
      }
    });

    test('care spending and wardrobe buys survive a database reopen', () async {
      final dir = Directory.systemTemp.createTempSync('k06_bugs_persist');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final file = File('${dir.path}/nestling.db');
      var db = AppDatabase(NativeDatabase(file));
      await Seed.demo(db);
      var repo = PipRepositoryImpl(db: db);
      await repo.feed('maya');
      await repo.buyItem('maya', 'wellies');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      repo = PipRepositoryImpl(db: db);
      expect(await _coins(db), 75);
      expect(await _owned(db, 'wellies'), isTrue);
      await db.close();
    });

    test(
      'the nest follows a live active-child switch maya -> leo -> none',
      () async {
        final db = AppDatabase.memory();
        await Seed.demo(db);
        final repo = PipRepositoryImpl(db: db);
        final children = <String>[];
        final sub = repo.watchNest().listen(
          (n) => children.add(n?.profile.childId ?? 'none'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(children.last, 'maya');

        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(children.last, 'leo');

        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value(null)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(children.last, 'none');
        await sub.cancel();
        await db.close();
      },
    );

    test('a stale active child id resolves to the no-child nest', () async {
      final db = AppDatabase.memory();
      await Seed.demo(db);
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('ghost')),
      );
      final repo = PipRepositoryImpl(db: db);
      expect(await repo.watchNest().first, isNull);
      await db.close();
    });
  });
}
