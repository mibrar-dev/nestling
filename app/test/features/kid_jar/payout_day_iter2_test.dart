// K10 · Payout day — iteration 2 (stage 3 TEST): regression proofs for the
// three fixes iteration 1 asked for, plus the two matrix dimensions that still
// had ZERO coverage after iteration 1.
//
// What iteration 2 changed in the screen (commit 905a54a):
//
//   K10-BUG-3 (major, mine)  320 px / 1.3× ellipsized the note-2 title and the
//                            `£9.49 to go` money string. Fixed in
//                            `payout_note.dart` (the `.k10-t` 2-line clamp was
//                            removed — the design clamps nothing) and in
//                            `payout_fund_card.dart` (each `.k10-amts b` amount
//                            now sits in `FittedBox(scaleDown)` instead of
//                            `Flexible` + ellipsis).
//   K10-BUG-2 (minor)        `goalPercent` now reads the CLAMPED fraction, so
//                            an overshot goal reads `100% there!`.
//   K10-BUG-1 (minor)        both `*Requested` handlers carry a `_closing`
//                            guard, so a same-tick load+close cannot leak a
//                            subscription or `add` on a closed bloc.
//
// What this file adds on top of iteration 1's `payout_day_matrix_test.dart`
// (76 tests) — deliberately NOT duplicating it:
//
//   1. The fixes are proven at the level the screen renders them, not just in
//      the entity: the two amounts at 320/1.3 are WHOLE (the paragraph's
//      `didExceedMaxLines` is false) AND their painted width is the natural
//      width, i.e. the FittedBox really shrank the glyphs instead of cutting
//      them. Iteration 1's green cell proves "not truncated"; this proves
//      "legible" — a scale factor below ~0.8 would be a new defect.
//   2. The design cell must be UNCHANGED by the fix: at 390 and 430, 1.0× and
//      1.3×, the amounts row is pixel-identical to iteration 1 (same rects,
//      scale 1.0 — no shrink where nothing was overflowing). A fix that
//      shrank the money everywhere would be caught here.
//   3. The unclamped note title must still GIVE the card its 2-line height at
//      the design cell (the ±2 px geometry band) — i.e. removing the clamp did
//      not quietly change the card rhythm at 390.
//   4. K10-BUG-2 through the WIDGET: the real `recordPayout` overshoot renders
//      `100% there!` + `£0.00 to go` + a full bar + a `100%` progress
//      semantics label, in both themes (the bugs file covers the caption; this
//      covers the bar and the spoken value, which the caption test cannot see).
//   5. **Short viewports — the dimension NO K10 test ever covered.** Every K10
//      test (geometry, view, matrix) pumps 390×844. A 667-tall phone (iPhone
//      SE / 13 mini) and a 568-tall one (SE 1st gen) put the celebration in a
//      much shorter scroll viewport: the jar-rain box (180×270) plus the title
//      already fill half of it, so the notes and the Pip row are below the fold
//      at 390 and even more so at 568. Nothing pinned that the screen still
//      scrolls to the Pip row, that the bar keeps its rect, or that nothing
//      overflows. Now it does — at 844, 667 and 568, light and dark.
//   6. The empty and failure frames on a SHORT viewport: their single-column
//      copy + a 96 px glyph + a 64 px button must fit (or scroll) at 568, not
//      overflow the 325 px the Expanded leaves after the chrome and the bar.
//
// No screen code is patched by this stage. No simulator was booted, installed
// on, screenshot or driven (only `5_ui` may use one). No `google_fonts`, no
// `DateTime.now()` (the clock is pinned to Sat 3 Oct 2026 09:41 Europe/London
// by `test/flutter_test_config.dart`); every pumped app ends with `disposeApp`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderBox, RenderFittedBox, RenderParagraph;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/kid_jar_routes.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_jar_rain.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';

import '../../test_scope.dart';

const String _title = "It's payout day!";
const String _paid = 'Mum marked £3.80 as paid';
const String _moved = '£5.50 went into your Lego Friends set';
const String _goal = 'Lego Friends set';
const String _saved = '£15.50';
const String _toGo = '£9.49 to go';
const String _percent = '62% there!';
const String _pipSays = 'Pip says well done, Maya!';
const String _thanks = 'Thanks Mum!';

/// The heights a K10 test has ever pumped before this file: the design's 844,
/// an iPhone 13 mini / SE-class 667, and a first-gen SE 568. Every K10 test
/// before iteration 2 used ONLY 844, at every width and both themes.
const List<double> _heights = <double>[844, 667, 568];

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

/// Hands out one broadcast payout stream per `watchLatestPayout()` call, so a
/// test can leave the screen loading (never add), show the empty state (add
/// null) or fail the stream (addError).
class _FakePayoutRepository implements KidJarRepository {
  final List<StreamController<PayoutCelebration?>> payouts =
      <StreamController<PayoutCelebration?>>[];

  final StreamController<JarSnapshot> _jar =
      StreamController<JarSnapshot>.broadcast();

  StreamController<PayoutCelebration?> get last => payouts.last;

  @override
  Future<List<JarEntry>> getItems() async => <JarEntry>[];

  @override
  Stream<List<JarEntry>> watchItems() => const Stream<List<JarEntry>>.empty();

  @override
  Stream<JarSnapshot> watchJar() => _jar.stream;

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      const Stream<JarSummary>.empty();

  @override
  Stream<PayoutCelebration?> watchLatestPayout() {
    final controller = StreamController<PayoutCelebration?>.broadcast();
    payouts.add(controller);
    return controller.stream;
  }

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}

  Future<void> dispose() async {
    for (final controller in payouts) {
      await controller.close();
    }
    await _jar.close();
  }
}

Future<void> _useFake(_FakePayoutRepository repo) async {
  await GetIt.instance.unregister<KidJarRepository>();
  GetIt.instance.registerSingleton<KidJarRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const NestlingApp(initialRoute: KidJarRoutePaths.payoutDay),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

NestTokens _tokens(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(PayoutFundCard)))
        .extension<NestTokens>()!;

/// The `.kid-bar` surface: `surface` fill with a TOP-ONLY 3 px ink border.
Finder _barSurface(WidgetTester tester) {
  final surface = _tokens(tester).surface;
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final box = widget.decoration;
    if (box is! BoxDecoration) return false;
    if (box.color != surface) return false;
    final border = box.border;
    return border is Border &&
        border.top.width == 3 &&
        border.left.width == 0 &&
        border.right.width == 0 &&
        border.bottom.width == 0;
  });
}

bool _truncated(WidgetTester tester, String line) => tester
    .renderObject<RenderParagraph>(find.text(line, skipOffstage: false))
    .didExceedMaxLines;

/// The scale the `.k10-amts` FittedBox applied to the amount [line]
/// (1.0 = untouched, < 1.0 = shrunk to fit).
double _amountScale(WidgetTester tester, String line) {
  final finder = find.text(line, skipOffstage: false);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  var node = paragraph.parent;
  while (node != null) {
    final fitted = node;
    if (fitted is RenderFittedBox) {
      final child = fitted.child;
      if (child is! RenderBox) return 1;
      final natural = child.size.width;
      return natural == 0 ? 1 : fitted.size.width / natural;
    }
    node = fitted.parent;
  }
  return 1;
}

void main() {
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // 1 + 2 · K10-BUG-3: whole money at 320/1.3×, untouched everywhere else
  // -------------------------------------------------------------------------

  group('K10-BUG-3 fix — the amounts are whole, and only shrink where they '
      'must', () {
    // The narrowest supported cell at the largest supported text scale: the
    // exact configuration iteration 1 measured `£9.49 to g…` here.
    testWidgets('320px @1.3x: both amounts render whole and stay legible', (
      tester,
    ) async {
      await _pump(tester, width: 320, textScale: 1.3);

      for (final amount in <String>[_saved, _toGo]) {
        expect(
          _truncated(tester, amount),
          isFalse,
          reason: '$amount must not be ellipsized (K10-BUG-3)',
        );
        expect(
          find.textContaining('…'),
          findsNothing,
          reason: 'no ellipsis character may be painted at 320/1.3 (K10-BUG-3)',
        );
      }

      // The fix must SHRINK the glyphs, not cut them: the painted width of
      // each amount is its natural width when the scale is 1, and still close
      // to it when scaled. A scale factor below 0.8 would be a new defect
      // (unreadable money) traded for the truncation we removed.
      for (final amount in <String>[_saved, _toGo]) {
        final scale = _amountScale(tester, amount);
        expect(
          scale,
          greaterThanOrEqualTo(0.8),
          reason: '$amount shrank to $scale — legible money needs ≥ 0.8',
        );
        expect(
          scale,
          lessThanOrEqualTo(1),
          reason: '$amount must never be enlarged past its design size',
        );
      }

      // The note title is unclamped now, so it wraps instead of ellipsizing.
      expect(_truncated(tester, _moved), isFalse);
      expect(find.text(_moved), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    // Iteration 1 proved "not truncated" at every supported cell; this proves
    // the fix is INVISIBLE where nothing overflowed — a fix that shrank all
    // money everywhere would pass iteration 1's green cells and fail here.
    //
    // 320 @1.3× is deliberately absent: it is the ONE cell where the design's
    // money string genuinely does not fit, so the fix must shrink there
    // (measured 0.963) — see the test above.
    for (final cell in const <(double, double)>[
      (320, 1),
      (390, 1),
      (390, 1.3),
      (430, 1),
      (430, 1.3),
    ]) {
      testWidgets('${cell.$1.round()}px @${cell.$2}x: the amounts keep their '
          'design size when they already fit', (tester) async {
        await _pump(tester, width: cell.$1, textScale: cell.$2);

        for (final amount in <String>[_saved, _toGo]) {
          expect(
            _amountScale(tester, amount),
            closeTo(1, 0.001),
            reason:
                '$amount at ${cell.$1.round()}px @${cell.$2}x must render at '
                "scale 1.0 — the design's 17 px Nunito w900, untouched",
          );
        }
        await disposeApp(tester);
      });
    }

    // Dark mode must behave identically: the shrink is geometry, not a token.
    testWidgets('the 320 @1.3x shrink is the same in light and dark', (
      tester,
    ) async {
      await _pump(tester, width: 320, textScale: 1.3);
      final lightScale = _amountScale(tester, _toGo);
      await disposeApp(tester);

      await _pump(tester, width: 320, textScale: 1.3, theme: ThemeMode.dark);
      final darkScale = _amountScale(tester, _toGo);

      expect(
        darkScale,
        closeTo(lightScale, 0.0001),
        reason: 'the shrink is geometry, so both themes must measure alike',
      );
      expect(
        lightScale,
        lessThan(1),
        reason: 'and both must actually be the shrink cell',
      );
      expect(
        find.textContaining('…'),
        findsNothing,
        reason: 'no truncation in dark either',
      );
      await disposeApp(tester);
    });

    testWidgets('the amounts row keeps the design rects at the design cell', (
      tester,
    ) async {
      // Regression guard on the FIX itself: the design puts `.k10-amts` 16 px
      // inside the fund card's 3 px border, so at 390 the left amount starts
      // at x = 39 and the right one ends at x = 351, on the card's baseline.
      await _pump(tester);
      final fund = tester.getRect(find.byType(PayoutFundCard));
      final left = tester.getRect(find.text(_saved));
      final right = tester.getRect(find.text(_toGo));

      expect(fund.left, closeTo(20, 2));
      expect(fund.right, closeTo(370, 2));
      expect(left.left, closeTo(fund.left + 3 + NestSpacing.s4, 2));
      expect(right.right, closeTo(fund.right - 3 - NestSpacing.s4, 2));
      // Both amounts share one baseline row (`.k10-amts { line-height 23 }`).
      expect(left.center.dy, closeTo(right.center.dy, 1));
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // 3 · the unclamped title must not have moved the design bands
  // -------------------------------------------------------------------------

  testWidgets('390/1.0: removing the title clamp kept every design band', (
    tester,
  ) async {
    await _pump(tester);

    // The design's geometry (measured off the PNG), unchanged by iteration 2's
    // unclamped `.k10-t`: status bar 47 · chrome 47…107 · title 107…141 ·
    // rain 141…411 · note 1 427…493 · note 2 509…597 · fund 613…756 ·
    // bar 755…844. Note 2 grows with content (DATA OVER MOCKS: the seeded goal
    // name wraps to two lines where the mock's did not) — see 3_test.md §6.
    final title = tester.getRect(find.text(_title));
    expect(title.top, closeTo(107, 2));
    expect(title.height, closeTo(34, 2));

    final rain = tester.getRect(find.byType(PayoutJarRain));
    expect(rain.left, closeTo(105, 2));
    expect(rain.width, closeTo(180, 2));
    expect(rain.height, closeTo(270, 2));

    final notes = find.byType(PayoutNote);
    expect(tester.getRect(notes.at(0)).top, closeTo(427, 2));
    expect(tester.getRect(notes.at(0)).height, closeTo(66, 2));
    expect(tester.getRect(notes.at(1)).top, closeTo(509, 2));

    final fund = tester.getRect(find.byType(PayoutFundCard));
    expect(fund.top, closeTo(613, 2));
    expect(fund.width, closeTo(350, 2));

    // The bar still owns the physical bottom edge.
    final bar = tester.getRect(_barSurface(tester));
    expect(bar.bottom, 844);
    expect(bar.height, closeTo(89, 2));

    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // 4 · K10-BUG-2 through the widget
  // -------------------------------------------------------------------------

  testWidgets('an overshot goal reads 100% there, with a full bar and a 100% '
      'spoken value, in both themes', (tester) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final db = GetIt.instance<AppDatabase>();
      // Re-seed per theme: `recordPayout` accumulates into the goal, so
      // without a reset the second pass would save £55.50, not £35.50
      // (`Seed.demo` starts with `clearAll()`, so it is idempotent).
      await tester.runAsync(() => Seed.demo(db));
      await tester.runAsync(
        () => PocketMoneyRepositoryImpl(db: db).recordPayout(
          childId: 'maya',
          amountPence: 2000,
          savingsMovePence: 2000,
          goalId: 'goal-lego',
        ),
      );
      await _pump(tester, theme: theme);

      // The overshoot really is on screen: saved 3550 of a 2499 target.
      expect(find.text('£35.50'), findsOneWidget, reason: theme.name);
      expect(find.text('£0.00 to go'), findsOneWidget, reason: theme.name);
      // K10-BUG-2: the caption follows the CLAMPED fraction.
      expect(find.text('100% there!'), findsOneWidget, reason: theme.name);
      expect(find.text('142% there!'), findsNothing, reason: theme.name);

      // …and the bar agrees with the caption (a 100% caption over a part-full
      // bar would be the same bug one layer down).
      final progress = tester.widget<NestProgress>(find.byType(NestProgress));
      expect(progress.fraction, 1, reason: theme.name);

      // The spoken value must not announce a percent the bar cannot show.
      final semantics = tester.ensureSemantics();
      final label = tester
          .getSemantics(
            find.bySemanticsLabel('100% of the Lego Friends set saved'),
          )
          .getSemanticsData()
          .label;
      expect(label, '100% of the Lego Friends set saved', reason: theme.name);
      semantics.dispose();

      expect(tester.takeException(), isNull, reason: theme.name);
      await disposeApp(tester);
    }
  });

  testWidgets('the fund card still fits its gutter at 320/1.3 with an '
      'overshot goal', (tester) async {
    final db = GetIt.instance<AppDatabase>();
    await tester.runAsync(
      () => PocketMoneyRepositoryImpl(db: db).recordPayout(
        childId: 'maya',
        amountPence: 2000,
        savingsMovePence: 2000,
        goalId: 'goal-lego',
      ),
    );
    await _pump(tester, width: 320, textScale: 1.3);

    expect(find.text('100% there!'), findsOneWidget);
    for (final line in <String>['£35.50', '£0.00 to go', '100% there!']) {
      final rect = tester.getRect(find.text(line));
      expect(
        rect.left,
        greaterThanOrEqualTo(NestSpacing.padSide - 0.5),
        reason: '$line escapes the left gutter',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(320 - NestSpacing.padSide + 0.5),
        reason: '$line escapes the right gutter',
      );
    }
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // 5 · short viewports — the dimension NO K10 test covered before
  // -------------------------------------------------------------------------

  group('K10 short viewports — 844 / 667 / 568 tall', () {
    for (final height in _heights) {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        for (final scale in <double>[1, 1.3]) {
          final cell = '390px ${height.round()} tall ${theme.name} @${scale}x';

          testWidgets('$cell: the celebration renders and nothing overflows', (
            tester,
          ) async {
            await _pump(tester, height: height, textScale: scale, theme: theme);

            expect(find.text(_title), findsOneWidget, reason: cell);
            expect(find.text(_paid), findsOneWidget, reason: cell);
            expect(find.text(_moved), findsOneWidget, reason: cell);
            expect(find.text(_goal), findsOneWidget, reason: cell);
            expect(find.text(_percent), findsOneWidget, reason: cell);
            expect(find.text(_thanks), findsOneWidget, reason: cell);
            expect(find.byType(PayoutJarRain), findsOneWidget, reason: cell);
            expect(find.byType(PayoutNote), findsNWidgets(2), reason: cell);
            expect(find.byType(PayoutFundCard), findsOneWidget, reason: cell);
            expect(tester.takeException(), isNull, reason: '$cell threw');

            await disposeApp(tester);
          });

          testWidgets('$cell: the bar keeps its rect and the physical edge', (
            tester,
          ) async {
            await _pump(tester, height: height, textScale: scale, theme: theme);

            // The bar is fixed to the bottom of a SHORTER screen: it must not
            // shrink, and it must still bleed to the physical edge (owner
            // BOTTOM EDGE rule — a shorter screen makes a strip more likely,
            // not less).
            final bar = tester.getRect(_barSurface(tester));
            expect(bar.left, 0, reason: cell);
            expect(bar.right, 390, reason: cell);
            expect(bar.bottom, height, reason: cell);
            expect(bar.height, closeTo(89, 2), reason: '$cell bar height');
            expect(bar.width, 390, reason: cell);

            final button = tester.getRect(find.byType(NestKidButton));
            expect(
              button.left,
              closeTo(NestSpacing.padSide, 0.5),
              reason: cell,
            );
            expect(
              button.right,
              closeTo(390 - NestSpacing.padSide, 0.5),
              reason: cell,
            );
            expect(
              button.height,
              greaterThanOrEqualTo(NestDevice.tapKid),
              reason: '$cell CTA tap target',
            );

            expect(tester.takeException(), isNull, reason: cell);
            await disposeApp(tester);
          });
        }
      }
    }

    testWidgets('the Pip row is reachable by scrolling at every height', (
      tester,
    ) async {
      for (final height in _heights) {
        await _pump(tester, height: height);
        final before = tester.getRect(find.byType(PipAvatar));
        // At 667 the Pip row starts below the fold; at 844 it is already
        // visible. Either way it must be INSIDE the scroll viewport after a
        // drag, and it must never have escaped the gutters.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -700),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_pipSays), findsOneWidget, reason: '$height tall');
        final after = tester.getRect(find.text(_pipSays));
        expect(after.left, greaterThanOrEqualTo(0), reason: '$height tall');
        expect(after.right, lessThanOrEqualTo(390), reason: '$height tall');
        expect(before.width, greaterThan(0));
        expect(tester.takeException(), isNull, reason: '$height tall');
        await disposeApp(tester);
      }
    });

    testWidgets('320px on a 568-tall screen: the notes and bar still line up', (
      tester,
    ) async {
      await _pump(tester, width: 320, height: 568, textScale: 1.3);

      final fund = tester.getRect(find.byType(PayoutFundCard));
      expect(fund.left, closeTo(NestSpacing.padSide, 0.5));
      expect(fund.right, closeTo(320 - NestSpacing.padSide, 0.5));
      for (var i = 0; i < 2; i++) {
        final note = tester.getRect(find.byType(PayoutNote).at(i));
        expect(note.left, closeTo(fund.left, 0.01));
        expect(note.right, closeTo(fund.right, 0.01));
      }
      final bar = tester.getRect(_barSurface(tester));
      expect(bar.bottom, 568);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // 6 · the state frames on a short viewport
  // -------------------------------------------------------------------------

  group('K10 state frames on a 568-tall screen', () {
    testWidgets('loading: the spinner frame fits and the chrome stays', (
      tester,
    ) async {
      final repo = _FakePayoutRepository();
      addTearDown(repo.dispose);
      await _useFake(repo);
      await _pump(tester, height: 568, textScale: 1.3);

      expect(find.bySemanticsLabel('Loading payout day'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('empty: the copy and the button fit without overflowing', (
      tester,
    ) async {
      final repo = _FakePayoutRepository();
      addTearDown(repo.dispose);
      await _useFake(repo);
      await _pump(tester, height: 568, textScale: 1.3);
      repo.last.add(null);
      await _settle(tester);

      expect(find.text('No payout yet'), findsOneWidget);
      expect(find.text('Back home'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('failure: the copy and Try again fit, and the lock escapes', (
      tester,
    ) async {
      final repo = _FakePayoutRepository();
      addTearDown(repo.dispose);
      await _useFake(repo);
      await _pump(tester, height: 568, textScale: 1.3);
      repo.last.addError(StateError('the jar is offline'));
      await _settle(tester);

      expect(find.text('Oh no! Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester.getRect(find.byType(NestKidButton)).height,
        greaterThanOrEqualTo(NestDevice.tapKid),
      );
      expect(tester.takeException(), isNull);

      // The escape hatch must survive the short viewport too.
      await tester.tap(find.byType(NestLockButton));
      await _settle(tester);
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });
}
