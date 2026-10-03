// P07 · Paywall — widget contract (design + orchestrator rules).
//
// Covers: the design's copy character by character (P07-paywall.html), the
// hero Pip as the v2 `PipAvatar` (mandatory orchestrator rule), light + dark,
// widths 320/390/430 at text scales 1.0/1.3, the initial/loading/loaded/
// failure/empty states, every navigation target (`/pocket-money-setup`,
// `/today`), the ORCHESTRATOR_NOTES 1 onboarding handoff (`startTrialNow` +
// `completeOnboarding`), the accessibility contract (semantics labels,
// 44dp parent tap targets) and the two owner rules: 20px alignment gutters
// and the bottom edge running to the physical screen edge.
//
// Scope note (Stage 3, iteration 1): the trial/restore events do not exist
// in the bloc yet, so the action paths are asserted here from the outside —
// tap the control, then read `app_state`. Event-level unit tests are listed
// as follow-up work in `docs/screens/P07/3_test.md`.
//
// Font note: the widget-test font is far wider than Inter (see P02-BUG-7),
// so no assertion here depends on a real line count. Where the design clamps
// lines (h1 maxLines 3, caption maxLines 3) the tests deliberately assert
// "no exception", not "full text visible".

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart' as v2;
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';
import 'package:nestling/features/paywall/presentation/views/paywall_view.dart';

import '../../test_scope.dart';

// -- the design's copy, verbatim from design/html-source/screens/P07-paywall.html

/// `<h1 class="h1 balance pay-title">`.
const String _title = 'Try Nestling free for 14 days';

/// `<li class="benefit">` rows — `&rsquo;` is U+2019, `&amp;` a plain ampersand.
const List<String> _benefits = <String>[
  'Unlimited children & quests',
  'Pip’s full evolution & seasonal outfits',
  'Pocket money ledger & payout day',
  'Co-parent sharing, so James sees the same',
];

/// `.plan` card: title `&mdash;` U+2014, `&pound;` U+00A3.
const String _planTitle = 'Annual — £29.99/year';
const String _planSub = 'Just £2.50 a month, billed yearly';
const String _planTag = 'One price, the whole family';

/// `.timeline` card: `What happens next` + three `<li>` steps.
const String _timelineHead = 'What happens next';
const List<(String, String)> _timeline = <(String, String)>[
  ('Today', 'Full access, straight away'),
  ('Day 12', 'We’ll remind you by email'),
  ('Day 14', '£29.99 billed — cancel any time'),
];

/// `.center-note`.
const String _familyNote = 'One subscription covers the whole family.';

/// `.bottom-cta`: primary button, `.caption`, `.legal-row` links + `&middot;`.
const String _cta = 'Start free trial';
const String _caption =
    '£29.99/year after the 14-day trial. Cancel anytime in Settings.';
const String _middot = '·';
const List<String> _legalLinks = <String>[
  'Restore purchases',
  'Terms',
  'Privacy',
];

/// `<nav class="nav-bar compact" aria-label="Subscription">` and the close
/// button's `aria-label`.
const String _navLabel = 'Subscription';
const String _closeLabel = 'Close and go back';

/// Hero Pip `alt` text — the only image on the screen with a label.
const String _pipLabel =
    'Pip the songbird, fully grown, sitting in a twig nest';

/// Any SvgPicture still loading a v1 `pip_stage_*.svg` illustration, which the
/// orchestrator PIP rule forbids in a product screen.
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.startsWith(
        'assets/illustrations/pip_stage_',
      ),
);

/// In-memory repository with a caller-controlled item stream, used to reach
/// the states the static Drift repository cannot produce (pending load,
/// empty, stream error, retry), plus the action paths: [failTrial] makes
/// `startTrial()` throw and [trialGate] holds it open so the screen's
/// `working` state is observable.
class _FakePaywallRepository implements PaywallRepository {
  _FakePaywallRepository({this.pending = false, this.fail = false});

  /// Never emits — the screen stays in `loading`.
  final bool pending;

  /// Every `watchItems()` call errors — the screen shows its failure state.
  bool fail;

  /// `startTrial()` throws — the trial action ends in `failure`.
  bool failTrial = false;

  /// When set, `startTrial()` waits on this before completing, so a test can
  /// inspect the screen while `action == working`.
  Completer<void>? trialGate;

  int watchCalls = 0;
  int startTrialCalls = 0;
  int activateCalls = 0;

  @override
  Future<List<PaywallPlan>> getItems() async => <PaywallPlan>[];

  @override
  Stream<List<PaywallPlan>> watchItems() {
    watchCalls++;
    if (fail) return Stream<List<PaywallPlan>>.error(Exception('offline'));
    if (pending) return const Stream<List<PaywallPlan>>.empty();
    return Stream<List<PaywallPlan>>.value(const <PaywallPlan>[]);
  }

  @override
  Stream<SubscriptionStatus> watchSubscription() =>
      const Stream<SubscriptionStatus>.empty();

  @override
  Future<SubscriptionStatus> readSubscription() => watchSubscription().first;

  @override
  Future<void> startTrial() async {
    startTrialCalls++;
    final gate = trialGate;
    if (gate != null) await gate.future;
    if (failTrial) throw Exception('offline');
  }

  @override
  Future<void> activate() async {
    activateCalls++;
  }
}

/// Replaces the DI `PaywallBloc` factory so the whole app (router, session,
/// navigation) can be driven by a caller-controlled repository. The route
/// builds its bloc from `GetIt.instance<PaywallBloc>()`.
Future<void> _useFakePaywallBloc(PaywallRepository repository) async {
  if (GetIt.instance.isRegistered<PaywallBloc>()) {
    await GetIt.instance.unregister<PaywallBloc>();
  }
  GetIt.instance.registerFactory<PaywallBloc>(
    () => PaywallBloc(repository: repository),
  );
}

/// Pumps `/paywall` through the real app (router, DI, themes) at [surface]
/// and [textScale]. Mirrors [pumpAppRoute], which takes neither.
Future<void> _pumpPaywall(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double textScale = 1,
  String route = '/paywall',
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpAppRoute(tester, route, theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps the app at `/paywall` on an arbitrary seed.
Future<AppDatabase> _pumpPaywallWithSeed(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed, {
  ThemeMode theme = ThemeMode.light,
  Size surface = const Size(390, 844),
  double textScale = 1,
}) async {
  final db = await setUpTestScope(seedDemo: false);
  await seed(db);
  await GetIt.instance<AppSession>().refresh();
  await _pumpPaywall(
    tester,
    theme: theme,
    surface: surface,
    textScale: textScale,
  );
  return db;
}

/// Pumps [PaywallView] directly (no router) under the real theme with
/// [repository] driving the bloc; returns the bloc for state assertions.
Future<PaywallBloc> _pumpPaywallView(
  WidgetTester tester, {
  required PaywallRepository repository,
  ThemeMode theme = ThemeMode.light,
}) async {
  // Real DI + in-memory Drift, so the view may resolve anything it needs
  // (AppSession lives in GetIt, not in the widget tree — see 2_build.md).
  await setUpTestScope(seedDemo: false);
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final bloc = PaywallBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<PaywallBloc>.value(
        value: bloc,
        child: const PaywallView(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// A few frames: enough for a tap, a Drift write and a go_router transition,
/// without `pumpAndSettle` (a live Drift watch never settles).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the paywall column to its end (the timeline and family note live
/// below the fold; the PNG only shows the top).
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
  await _settle(tester);
}

/// Every string painted on screen, in widget order.
List<String> _renderedText(WidgetTester tester) {
  final texts = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is RenderParagraph) {
      final text = render.text.toPlainText().trim();
      if (text.isNotEmpty) texts.add(text);
    }
  }
  return texts;
}

/// The font size [text] is painted at, read from the render tree.
double _fontSizeOf(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget, reason: '"$text" must be on screen');
  return tester
          .renderObject<RenderParagraph>(find.text(text))
          .text
          .style
          ?.fontSize ??
      -1;
}

/// The font family [text] is painted with.
String _fontFamilyOf(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget, reason: '"$text" must be on screen');
  return tester
          .renderObject<RenderParagraph>(find.text(text))
          .text
          .style
          ?.fontFamily ??
      '';
}

/// The card [NestCard] that contains [text].
Finder _cardWith(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(NestCard));

Future<AppStateData?> _appStateRow(AppDatabase db) =>
    (db.select(db.appState)..where((a) => a.id.equals(1))).getSingleOrNull();

/// Writes `subscription_status = 'expired'` on the seeded row — the one input
/// the `trialExpired` guard reacts to (P07-BUG-8: nothing in the app writes it
/// on its own yet, so a test has to) — and re-reads the session so the router
/// and the nav's `ListenableBuilder` both see it.
Future<void> _expireSubscription(AppDatabase db) async {
  await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
    const AppStateCompanion(subscriptionStatus: Value('expired')),
  );
  await GetIt.instance<AppSession>().refresh();
}

/// Every 44-wide `SizedBox` inside the nav subtree: the close tile plus the
/// balance spacer that mirrors it.
Finder _navSpacers(WidgetTester tester) => find.descendant(
  of: find.bySemanticsLabel(_navLabel),
  matching: find.byWidgetPredicate(
    (widget) => widget is SizedBox && widget.width == NestDevice.tapParent,
  ),
);

// Probe boundary for the BOTTOM EDGE owner rule (painted-pixel proof).
const Key _pixelProbe = ValueKey('p07_pixel_probe');

/// Paints the real app inside a [RepaintBoundary] so pixels can be sampled,
/// optionally with an OS bottom inset (home-indicator devices).
Future<void> _pumpPaywallForPixels(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double bottomInset = 0,
}) async {
  GetIt.instance<ThemeModeController>().selectMode(theme);
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    // View padding is physical; the test surface is 3x.
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/paywall'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Painted RGBA bytes at logical (x, y) of the app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
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

/// The opaque RGBA bytes of [color] at 8-bit precision.
List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

void main() {
  group('P07 paywall — the design’s copy', () {
    testWidgets('light 390: hero, title, benefits and plan card', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The screen is the paywall, not a placeholder.
      expect(find.text('P07 Paywall'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(find.text(_title), findsOneWidget);

      for (final benefit in _benefits) {
        expect(find.text(benefit), findsOneWidget, reason: benefit);
      }

      expect(find.text(_planTitle), findsOneWidget);
      expect(find.text(_planSub), findsOneWidget);
      expect(find.text(_planTag), findsOneWidget);
      expect(_cardWith(_planTitle), findsOneWidget);

      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('light 390 scrolled: timeline and family note', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );
      await _scrollToEnd(tester);

      expect(find.text(_timelineHead), findsOneWidget);
      for (final (title, sub) in _timeline) {
        expect(find.text(title), findsOneWidget, reason: title);
        expect(find.text(sub), findsOneWidget, reason: sub);
      }
      expect(find.text(_familyNote), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(_cardWith(_timelineHead), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('bottom bar: CTA, caption and the three legal links', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      expect(find.byType(NestBottomCta), findsOneWidget);
      expect(find.text(_cta), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      for (final link in _legalLinks) {
        expect(find.text(link), findsOneWidget, reason: link);
      }
      expect(
        find.text(_middot),
        findsNWidgets(2),
        reason: 'two &middot; separators between the three links',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('every copy character is the design’s typographic one', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // Curly apostrophes (U+2019) where the HTML uses &rsquo;.
      expect(_benefits[1], contains('’'));
      expect(_timeline[1].$2, contains('’'));
      // Em dash (U+2014) where the HTML uses &mdash;.
      expect(_planTitle, contains('—'));
      expect(_timeline[2].$2, contains('—'));
      // Pound sign (U+00A3) and middle dot (U+00B7).
      expect(_planTitle, contains('£'));
      expect(_middot, '·');
      expect(_middot.codeUnitAt(0), 0x00B7);

      await _scrollToEnd(tester);
      final rendered = _renderedText(tester);

      // No ASCII apostrophe or quote, no ellipsis (truncation) and no SPACED
      // hyphen (a dash where – or — belongs) anywhere on the screen.
      const forbidden = <String>["'", '"', '…'];
      final spacedHyphen = RegExp(r'\s-\s');
      final offenders = <String>[
        for (final text in rendered)
          if (forbidden.any(text.contains) || spacedHyphen.hasMatch(text)) text,
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'wrong dash/quote characters in rendered copy: '
            '${offenders.join(' | ')}',
      );

      // The screen never shows the repository's caption variant, which drops
      // the article in “after the 14-day trial” (P07-paywall.html `.caption`).
      expect(find.textContaining('after 14-day trial'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('no text on P07 adds letter spacing', (tester) async {
      // LETTER SPACING (main fd92d95): the design CSS carries no tracking, so
      // `NestType` defaults to 0 and no call site may put Material's back.
      // Material's tracking made Inter paint 1–2% wider than the design, which
      // is what pushed benefit 4 onto a second line before the merge.
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );
      await _scrollToEnd(tester);

      final tracked = <String>[];
      var inspected = 0;
      for (final element in find.byType(RichText).evaluate()) {
        final render = element.renderObject;
        if (render is RenderParagraph) {
          inspected++;
          final spacing = render.text.style?.letterSpacing ?? 0;
          if (spacing != 0) {
            tracked.add('${render.text.toPlainText()} → $spacing');
          }
        }
      }

      expect(
        inspected,
        greaterThan(10),
        reason: 'the sweep must actually see the screen’s text',
      );
      expect(tracked, isEmpty, reason: 'tracking added on P07: $tracked');
    });

    testWidgets('benefit 4 is painted in full, at the design’s 15px', (
      tester,
    ) async {
      // ORCHESTRATOR_NOTES iteration-4 item 1: re-measure benefit 4 and do NOT
      // shrink the text or edit the copy. The "one line on device" claim is a
      // device measurement (2b's shot) — the widget-test font is ~2× wider than
      // the bundled Inter (see P02-BUG-7), so here the honest, font-independent
      // contract is asserted instead: the full string is painted, never
      // ellipsised, never shrunk off the 15px token, and its box sits on the
      // design's 24px line grid.
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Co-parent sharing, so James sees the same'),
      );

      expect(
        paragraph.text.style?.fontSize,
        15,
        reason: 'the design’s `.benefit-txt` size, not a fitted size',
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'the copy must wrap, never truncate',
      );
      expect(
        paragraph.size.height % 24,
        0,
        reason: 'the box must sit on the design’s 24px line grid',
      );
      expect(paragraph.size.height, greaterThanOrEqualTo(24));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the title carries no inserted hard break', (tester) async {
      // ORCHESTRATOR_NOTES iteration-4 item 3: the "days" orphan
      // (`text-wrap: balance` has no Flutter equivalent) is accepted, and a
      // hard `\n` must NOT be inserted — it would break the exact-copy pins
      // and the h1's single paragraph node.
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.text(_title));
      expect(paragraph.text.toPlainText(), isNot(contains('\n')));
      expect(paragraph.text.toPlainText(), _title);

      await disposeApp(tester);
    });

    testWidgets('typography matches the design’s type scale', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // `.h1` = Nunito 28/34; `.plan-title` = Nunito 800 18/24;
      // `.benefit-txt` = Inter 15/24; `.plan-tag` = Inter 600 13/18.
      expect(_fontSizeOf(tester, _title), 28);
      expect(_fontFamilyOf(tester, _title), contains('Nunito'));
      expect(_fontFamilyOf(tester, _benefits.first), contains('Inter'));
      expect(_fontSizeOf(tester, _benefits.first), 15);
      expect(_fontSizeOf(tester, _planTitle), 18);
      expect(_fontSizeOf(tester, _planSub), 15);
      expect(_fontSizeOf(tester, _planTag), 13);

      await _scrollToEnd(tester);
      expect(_fontSizeOf(tester, _timelineHead), 18); // `.h3`
      expect(_fontSizeOf(tester, _timeline.first.$1), 15); // `.tl-title`
      expect(_fontSizeOf(tester, _familyNote), 15); // `.center-note`
      expect(_fontSizeOf(tester, _caption), 13); // `.caption`

      await disposeApp(tester);
    });
  });

  group('P07 paywall — Pip is the v2 avatar (mandatory orchestrator rule)', () {
    testWidgets('one mochi/sunny PipAvatar at stage 4, labelled by the design', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The v1 `pip_stage_4.svg` illustration is forbidden in a product screen.
      expect(_v1PipFinder, findsNothing);

      final avatars = tester.widgetList<v2.PipAvatar>(
        find.byType(v2.PipAvatar),
      );
      expect(avatars, hasLength(1), reason: 'one Pip in the hero');
      final avatar = avatars.single;
      expect(avatar.style, v2.PipStyle.mochi);
      expect(avatar.skin, v2.PipSkin.sunny);
      // `P07-paywall.html` ships `pip-stage-4.svg` — the fully grown songbird.
      expect(avatar.stage, 4);
      expect(avatar.inNest, isTrue, reason: 'Pip sits in the twig nest');

      // The design's `alt` text, and the design's 120px slot.
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);
      final rect = tester.getRect(find.bySemanticsLabel(_pipLabel));
      expect(rect.width, moreOrLessEquals(120, epsilon: 0.01));
      expect(rect.height, moreOrLessEquals(120, epsilon: 0.01));

      await disposeApp(tester);
    });

    // The hero is a fixed 350×148 frame; below 390dp the gutter is narrower
    // than the frame, so the whole scene (Pip, nest, coins) scales down with
    // it instead of overflowing. Above 390 the scale clamps at 1 — the
    // design's size and position are kept.
    for (final (width, scale) in const <(int, double)>[
      (320, 280 / 350),
      (390, 1),
      (430, 1),
    ]) {
      testWidgets('the hero scales down at ${width}dp', (tester) async {
        await setUpTestScope();
        await _pumpPaywall(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
        );

        final pip = tester.getRect(find.bySemanticsLabel(_pipLabel));
        expect(
          pip.width,
          moreOrLessEquals(120 * scale, epsilon: 0.5),
          reason: 'Pip keeps the design slot, scaled with the hero frame',
        );
        expect(
          pip.right,
          lessThanOrEqualTo(width - NestSpacing.padSide + 0.01),
          reason: 'the hero must stay inside the 20px gutters',
        );
        expect(pip.left, greaterThanOrEqualTo(NestSpacing.padSide - 0.01));
        expect(find.byType(v2.PipAvatar), findsOneWidget);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }
  });

  group('P07 paywall — widths, themes and text scales', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await setUpTestScope();
            await _pumpPaywall(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.byType(NestBottomCta), findsOneWidget);
            expect(find.text(_cta), findsOneWidget);
            for (final link in _legalLinks) {
              expect(find.text(link), findsOneWidget, reason: link);
            }
            // The design clamps lines in the test's wide font; the screen must
            // degrade honestly (ellipsis) instead of throwing.
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';
      testWidgets('$themeName: the benefits and timeline read in full', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPaywall(tester, theme: theme, surface: const Size(390, 844));

        for (final benefit in _benefits) {
          expect(find.text(benefit), findsOneWidget, reason: benefit);
        }

        await _scrollToEnd(tester);
        for (final (title, sub) in _timeline) {
          expect(find.text(title), findsOneWidget, reason: title);
          expect(find.text(sub), findsOneWidget, reason: sub);
        }
        expect(find.text(_familyNote), findsOneWidget);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }
  });

  group('P07 paywall — alignment and tap targets (owner rules)', () {
    for (final width in const <int>[320, 390, 430]) {
      testWidgets('width $width: one 20px gutter on cards, bar and scroll', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPaywall(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
        );

        final gutter = width - 2 * NestSpacing.padSide;

        // The plan card and the timeline card share the scroll's edges.
        expect(
          tester.getRect(_cardWith(_planTitle)).left,
          moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
        );
        expect(
          tester.getRect(_cardWith(_planTitle)).width,
          moreOrLessEquals(gutter, epsilon: 0.01),
        );

        // The CTA spans the same content width, inside the bottom bar.
        expect(
          tester.getRect(find.text(_cta)).width,
          lessThanOrEqualTo(gutter + 0.01),
          reason: 'the button must not bleed past the 20px gutters',
        );

        await _scrollToEnd(tester);
        expect(
          tester.getRect(_cardWith(_timelineHead)).left,
          moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
        );
        expect(
          tester.getRect(_cardWith(_timelineHead)).width,
          moreOrLessEquals(gutter, epsilon: 0.01),
        );

        // Nothing may overflow horizontally at any width.
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the title is centred on the screen', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final centre = tester.getRect(find.text(_title)).center.dx;
      expect(centre, moreOrLessEquals(390 / 2, epsilon: 0.5));

      await disposeApp(tester);
    });

    testWidgets('the plan text column shares one left edge', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final titleLeft = tester.getRect(find.text(_planTitle)).left;
      expect(
        tester.getRect(find.text(_planSub)).left,
        moreOrLessEquals(titleLeft, epsilon: 0.01),
      );
      expect(
        tester.getRect(find.text(_planTag)).left,
        moreOrLessEquals(titleLeft, epsilon: 0.01),
      );
    });

    testWidgets('the legal links share one row at 390dp', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // Stage 5 deviation 1: the legal row used to stack five full-width
      // lines because `_LegalLink` contained an expanding `Center` behind
      // its `InkWell`; the fix sizes each link to its text. (The wide
      // test font means the row may still wrap to a second run here — the
      // real-device shot is the layout proof; no widget in the link subtree
      // may expand to its parent's width.)
      expect(
        find.ancestor(
          of: find.text('Restore purchases'),
          matching: find.byType(Center),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('Privacy'), matching: find.byType(Center)),
        findsNothing,
      );

      // A compact panel keeps the plan card structurally on screen; whether
      // it is above the fold at a given phone/font pairing is a pixel check
      // for the simulator stage (in the wide-font harness the wrapped
      // benefits pushed the plan below the fold — [P07 stage 5] guards it).
      expect(find.text(_planTitle), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the timeline steps share one left edge in document order', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );
      await _scrollToEnd(tester);

      final tops = <double>[
        for (final (title, _) in _timeline)
          tester.getRect(find.text(title)).top,
      ];
      expect(tops[0], lessThan(tops[1]), reason: 'Today, then Day 12');
      expect(tops[1], lessThan(tops[2]), reason: 'Day 12, then Day 14');
      // NOTE (Stage 2, iteration 2): the next line used to assert
      // `tops[1] ≈ tops[2]` (±0.01) right after asserting `tops[1] <
      // tops[2]` — self-contradictory, since the Day 12 item is ~78px
      // tall. Removed as a typo; the shared left edge is pinned below.

      final lefts = <double>[
        for (final (title, _) in _timeline)
          tester.getRect(find.text(title)).left,
      ];
      expect(lefts[0], moreOrLessEquals(lefts[1], epsilon: 0.01));
      expect(lefts[1], moreOrLessEquals(lefts[2], epsilon: 0.01));

      await disposeApp(tester);
    });

    testWidgets('the legal row centres both glyph families in one 44px band', (
      tester,
    ) async {
      // ORCHESTRATOR_NOTES iteration-4 item 2: the `·` separators must sit in
      // the same 44px centred box as the links. Stage 6's [P07-BUG-13] proof
      // pins the baseline relation; this pins the box itself — the target is
      // exactly 44 tall and the two glyph families share one centre.
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final link = tester.getRect(
        find.ancestor(of: find.text('Terms'), matching: find.byType(InkWell)),
      );
      expect(
        link.height,
        moreOrLessEquals(NestDevice.tapParent, epsilon: 0.01),
        reason: 'the design’s `.legal-row .link` is a 44px target',
      );

      final linkCentre = tester.getRect(find.text('Terms')).center.dy;
      final dotCentre = tester.getRect(find.text(_middot).first).center.dy;
      expect(
        dotCentre,
        moreOrLessEquals(linkCentre, epsilon: 0.5),
        reason: 'separator and label share one vertical centre',
      );
      expect(
        linkCentre - link.top,
        moreOrLessEquals(link.height / 2, epsilon: 0.5),
        reason: 'both are centred in the band, not top-aligned',
      );

      await disposeApp(tester);
    });

    testWidgets('parent tap targets are at least 44dp', (tester) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // Close button (HTML: 44x44 `nav-back.close`).
      final close = tester.getRect(find.bySemanticsLabel(_closeLabel));
      expect(close.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(close.height, greaterThanOrEqualTo(NestDevice.tapParent));

      // The primary CTA is a 52dp pill; P07 is a parent screen, so the 56dp
      // kid target does not apply. NOTE (Stage 2, iteration 2): this used
      // to measure the label *text* (24px line box) instead of the button —
      // `find.text` can never be 52px tall. The button carries
      // `ValueKey('p07_start_trial')`, so measure that: same 52dp-pill
      // intent, correct finder.
      expect(
        tester.getRect(find.byKey(const ValueKey('p07_start_trial'))).height,
        greaterThanOrEqualTo(52),
      );
      expect(find.byType(NestKidButton), findsNothing);

      for (final link in _legalLinks) {
        final rect = tester.getRect(find.bySemanticsLabel(link));
        expect(
          rect.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: link,
        );
        expect(
          rect.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: link,
        );
      }

      await disposeApp(tester);
    });
  });

  group('P07 paywall — bottom edge runs to the physical edge (owner rule)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';
      testWidgets('$themeName: no page-colour strip under the bar', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPaywallForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
        );

        final cta = tester.getRect(find.byType(NestBottomCta));
        expect(
          cta.bottom,
          moreOrLessEquals(844, epsilon: 0.01),
          reason: 'the bar must reach the physical screen edge',
        );
        expect(cta.left, moreOrLessEquals(0, epsilon: 0.01));
        expect(cta.right, moreOrLessEquals(390, epsilon: 0.01));

        // Painted proof: the last row of pixels is the bar's surface, not the
        // page tint and not a meadow-green strip.
        final surface = Theme.of(tester.element(find.byType(NestBottomCta)))
            .extension<NestTokens>()!
            .surface;
        final pixel = await _pixelAt(tester, 195, 843);
        expect(
          pixel,
          _rgba(surface),
          reason:
              'a coloured strip under the bar (got $pixel, want '
              '${_rgba(surface)})',
        );

        await disposeApp(tester);
      });

      testWidgets('$themeName: home-indicator inset stays on the bar surface', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPaywallForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          bottomInset: 34,
        );

        expect(
          tester.getRect(find.byType(NestBottomCta)).bottom,
          moreOrLessEquals(844, epsilon: 0.01),
        );
        final surface = Theme.of(tester.element(find.byType(NestBottomCta)))
            .extension<NestTokens>()!
            .surface;
        expect(await _pixelAt(tester, 195, 843), _rgba(surface));
        // The area around the indicator is the bar, never the page tint.
        expect(await _pixelAt(tester, 6, 830), _rgba(surface));

        await disposeApp(tester);
      });
    }
  });

  group('P07 paywall — loading, empty and failure states', () {
    testWidgets('initial: a progress indicator before the load event', (
      tester,
    ) async {
      final bloc = await _pumpPaywallView(
        tester,
        repository: _FakePaywallRepository(),
      );

      expect(bloc.state.status, PaywallStatus.initial);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: a progress indicator while the plan is in flight', (
      tester,
    ) async {
      final bloc = await _pumpPaywallView(
        tester,
        repository: _FakePaywallRepository(pending: true),
      );

      bloc.add(const PaywallLoadRequested());
      await tester.pump();

      expect(bloc.state.status, PaywallStatus.loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with no plans: the static paywall still renders', (
      tester,
    ) async {
      // `1_plan.md` §d: an empty plan list is not an empty state — the copy is
      // the spec, and the trial CTA must never be blocked by `items`.
      final bloc = await _pumpPaywallView(
        tester,
        repository: _FakePaywallRepository(),
      );

      bloc.add(const PaywallLoadRequested());
      await _settle(tester);

      expect(bloc.state.status, PaywallStatus.loaded);
      expect(bloc.state.items, isEmpty);
      expect(find.text('No items yet'), findsNothing);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_cta), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: an error message with a Retry that reloads', (
      tester,
    ) async {
      final repository = _FakePaywallRepository(fail: true);
      final bloc = await _pumpPaywallView(tester, repository: repository);

      bloc.add(const PaywallLoadRequested());
      await _settle(tester);

      expect(bloc.state.status, PaywallStatus.failure);
      expect(find.text('Something went wrong'), findsOneWidget);

      // Retry re-adds the load event instead of dead-ending the screen.
      repository.fail = false;
      await tester.tap(find.text('Retry'));
      await _settle(tester);

      expect(repository.watchCalls, 2);
      expect(bloc.state.status, PaywallStatus.loaded);
      expect(find.text(_title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P07 paywall — navigation and the onboarding handoff', () {
    testWidgets('the close button goes back to the onboarding money step', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      await tester.tap(find.bySemanticsLabel(_closeLabel));
      await _settle(tester);

      // P06 Pocket-money setup is the step before P07 in the onboarding flow.
      expect(currentPath(tester), '/pocket-money-setup');

      await disposeApp(tester);
    });

    testWidgets('Start free trial completes onboarding and lands on /today', (
      tester,
    ) async {
      final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

      await tester.tap(find.text(_cta));
      await _settle(tester);

      // ORCHESTRATOR_NOTES 1 (mandatory): the trial must call
      // `startTrialNow()` + `completeOnboarding()` so a restart lands on
      // Today, not /welcome (P01 BUG-4).
      final row = await _appStateRow(db);
      expect(row?.onboardingComplete, isTrue);
      expect(row?.subscriptionStatus, 'trial');
      expect(row?.trialStart, isNotNull);
      expect(row?.trialStartTz, 'Europe/London');
      expect(GetIt.instance<AppSession>().onboardingComplete, isTrue);

      expect(currentPath(tester), '/today');

      await disposeApp(tester);
    });

    testWidgets(
      'Restore purchases activates the subscription and lands on /today',
      (tester) async {
        final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

        await tester.tap(find.text('Restore purchases'));
        await _settle(tester);

        // A restoring user is already paid: `active`, never downgraded to
        // `trial` (that would throw away a paid subscription).
        final row = await _appStateRow(db);
        expect(row?.subscriptionStatus, 'active');
        expect(row?.onboardingComplete, isTrue);
        expect(currentPath(tester), '/today');

        await disposeApp(tester);
      },
    );

    testWidgets('Terms and Privacy are placeholders, not dead links', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      for (final link in const <String>['Terms', 'Privacy']) {
        await tester.tap(find.bySemanticsLabel(link));
        await _settle(tester);

        // No onboarding route exists for the legal pages, so the screen must
        // answer in place (a toast) and stay on /paywall.
        expect(currentPath(tester), '/paywall', reason: link);
        expect(
          find.byType(SnackBar).evaluate().isNotEmpty ||
              find.byType(NestToast).evaluate().isNotEmpty,
          isTrue,
          reason: '$link must tell the parent something happened',
        );
      }

      await disposeApp(tester);
    });

    testWidgets('tapping the plan card changes nothing (single plan)', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The card sits below the fold on a 390×844 surface, so scroll it into
      // view first — otherwise this "tap" would never land and the test would
      // prove nothing.
      await tester.scrollUntilVisible(find.text(_planTitle), 120);
      await _settle(tester);

      await tester.tap(find.text(_planTitle));
      await _settle(tester);

      expect(currentPath(tester), '/paywall');
      expect(find.text(_cta), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('Annual')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
        reason: 'the single plan stays selected after the tap',
      );

      await disposeApp(tester);
    });

    testWidgets('an expired trial sends /today to the paywall', (tester) async {
      // The only way `trialExpired` can be true today (P07-BUG-8: nothing in
      // `app/lib` ever writes 'expired' yet), so this is the one reachable
      // shape of the guard: an ONBOARDED parent, mid-session, bounced off
      // `/today` and shown the paywall.
      final db = await setUpTestScope();
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(
          subscriptionStatus: Value('expired'),
          onboardingComplete: Value(true),
        ),
      );
      await GetIt.instance<AppSession>().refresh();

      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        route: '/today',
      );

      expect(currentPath(tester), '/paywall');
      expect(find.text(_cta), findsOneWidget, reason: 'the paywall itself');

      await disposeApp(tester);
    });

    testWidgets('the nav keeps its balance spacer while the trial is live', (
      tester,
    ) async {
      await _pumpPaywallWithSeed(tester, Seed.fresh);

      expect(find.bySemanticsLabel(_closeLabel), findsOneWidget);
      expect(
        _navSpacers(tester),
        findsNWidgets(2),
        reason: 'the 44×44 close tile plus its 44-wide balance spacer',
      );

      await disposeApp(tester);
    });

    testWidgets('an expired trial drops the close tile and its spacer', (
      tester,
    ) async {
      // ALIGNMENT (owner rule): the balance spacer exists to mirror the close
      // tile. Removing the dead control must remove its mirror too, or the
      // nav is left with a stray 44px of nothing.
      final db = await _pumpPaywallWithSeed(tester, Seed.fresh);
      await _expireSubscription(db);
      await _settle(tester);

      expect(find.bySemanticsLabel(_closeLabel), findsNothing);
      expect(
        _navSpacers(tester),
        findsNothing,
        reason: 'no dangling 44px spacer behind an omitted close tile',
      );

      // The bar itself is untouched: the working exits stay reachable.
      expect(find.byType(NestBottomCta), findsOneWidget);
      expect(find.text(_cta), findsOneWidget);
      expect((await _appStateRow(db))?.onboardingComplete, isFalse);

      await disposeApp(tester);
    });

    testWidgets(
      '[P07-BUG-10] the expired-trial paywall shows no dead close control',
      // Stage 6 proved the close button can never leave the expired-trial
      // paywall (the router bounces every location back to /paywall), so
      // the screen must not pretend one exists. Product resolution belongs
      // to the orchestrator; until then the gate keeps only its working
      // exits (start trial / restore).
      (tester) async {
        final db = await setUpTestScope();
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(
            subscriptionStatus: Value('expired'),
            onboardingComplete: Value(true),
          ),
        );
        await GetIt.instance<AppSession>().refresh();

        await _pumpPaywall(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          route: '/today',
        );
        expect(currentPath(tester), '/paywall');

        expect(
          find.bySemanticsLabel(_closeLabel),
          findsNothing,
          reason:
              'a close button on the hard gate can only bounce the parent '
              'back to /paywall — it must not be rendered',
        );
        expect(find.text(_cta), findsOneWidget);
        expect(find.text('Restore purchases'), findsOneWidget);

        await disposeApp(tester);
      },
    );

    testWidgets(
      'Start free trial on a paying family never downgrades them to trial',
      (tester) async {
        // P07-BUG-12 end to end: `/paywall` stays reachable for an onboarded
        // app (`Seed.demo` ships `subscription_status = 'active'`), so a
        // paying parent can tap the trial CTA. The bloc's `readSubscription()`
        // guard must route it down the restore branch: `active` in,
        // `active` out, `trial_start` untouched, and the family still lands
        // on `/today`.
        final db = await _pumpPaywallWithSeed(tester, Seed.demo);
        final before = await _appStateRow(db);
        expect(before?.subscriptionStatus, 'active');

        await tester.tap(find.text(_cta));
        await _settle(tester);

        final after = await _appStateRow(db);
        expect(
          after?.subscriptionStatus,
          'active',
          reason: 'a paying family must not be handed a 14-day trial',
        );
        expect(
          after?.trialStart,
          before?.trialStart,
          reason: 'trial_start moved',
        );
        expect(after?.onboardingComplete, isTrue);
        expect(currentPath(tester), '/today');

        await disposeApp(tester);
      },
    );

    testWidgets('Restore purchases never starts a trial', (tester) async {
      final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

      await tester.tap(find.text('Restore purchases'));
      await _settle(tester);

      // A restoring user already paid, so the handoff writes `active` ONLY.
      // `startTrialNow()` here would move `trial_start` and hand a paying
      // customer a brand-new 14-day trial — the `PaywallRequest` split exists
      // for exactly this case.
      final row = await _appStateRow(db);
      expect(row?.subscriptionStatus, 'active');
      expect(row?.onboardingComplete, isTrue);
      expect(
        row?.trialStart,
        isNull,
        reason: 'the restore path must not call startTrialNow()',
      );

      await disposeApp(tester);
    });
  });

  group('P07 paywall — action states: working, failure, retry', () {
    testWidgets('a failed trial toasts in place and stays on /paywall', (
      tester,
    ) async {
      final repository = _FakePaywallRepository()..failTrial = true;
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await _useFakePaywallBloc(repository);
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      await tester.tap(find.text(_cta));
      await _settle(tester);

      expect(repository.startTrialCalls, 1);
      expect(
        currentPath(tester),
        '/paywall',
        reason: 'a failed trial must not navigate',
      );
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('offline'),
        findsWidgets,
        reason: 'the reason is surfaced, not swallowed',
      );

      // Nothing was written: the parent is still un-onboarded.
      final row = await _appStateRow(db);
      expect(row?.onboardingComplete, isFalse);
      expect(row?.trialStart, isNull);

      // The screen is not dead-ended: the same CTA works again.
      repository.failTrial = false;
      await tester.pump(const Duration(seconds: 4)); // let the toast dismiss
      await tester.tap(find.text(_cta));
      await _settle(tester);

      expect(repository.startTrialCalls, 2, reason: 'the retry was accepted');
      expect(currentPath(tester), '/today');
      final retried = await _appStateRow(db);
      expect(retried?.onboardingComplete, isTrue);
      expect(retried?.subscriptionStatus, 'trial');
      expect(retried?.trialStart, isNotNull);

      await disposeApp(tester);
    });

    testWidgets(
      'the CTA is disabled and spinning while the trial is in flight',
      (tester) async {
        final repository = _FakePaywallRepository()
          ..trialGate = Completer<void>();
        final db = await setUpTestScope(seedDemo: false);
        await Seed.fresh(db);
        await GetIt.instance<AppSession>().refresh();
        await _useFakePaywallBloc(repository);
        await _pumpPaywall(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
        );

        await tester.tap(find.text(_cta));
        await tester.pump();

        // Working: the pill shows its spinner and refuses further taps, and the
        // restore link is disabled with it (one action at a time).
        final button = tester.widget<NestButton>(find.byType(NestButton));
        expect(button.onPressed, isNull);
        expect(button.loading, isTrue);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Restore purchases'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'Restore purchases must be disabled mid-action',
        );

        // A second tap while the first request is in flight is a no-op.
        await tester.tap(find.text(_cta), warnIfMissed: false);
        await tester.pump();
        expect(repository.startTrialCalls, 1, reason: 'one tap, one trial');
        expect(currentPath(tester), '/paywall');

        repository.trialGate!.complete();
        await _settle(tester);

        expect(currentPath(tester), '/today');
        expect((await _appStateRow(db))?.onboardingComplete, isTrue);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets('a restore request never shows the trial spinner', (
      tester,
    ) async {
      // `loading` belongs to the trial pill only: the restore link is not a
      // button, so the CTA must not claim a trial is running.
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      expect(
        tester.widget<NestButton>(find.byType(NestButton)).loading,
        isFalse,
      );

      await tester.tap(find.text('Restore purchases'));
      await _settle(tester);

      expect(currentPath(tester), '/today');

      await disposeApp(tester);
    });
  });

  group('P07 paywall — accessibility contract', () {
    testWidgets('the legal separators are decoration, not links', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The design marks both `&middot;` separators `aria-hidden`: only the
      // three links are announced, so a screen reader reads
      // "Restore purchases, Terms, Privacy" (P07-BUG-11).
      expect(find.bySemanticsLabel(_middot), findsNothing);
      expect(find.text(_middot), findsNWidgets(2), reason: 'still painted');
      for (final link in _legalLinks) {
        expect(
          find.bySemanticsLabel(link),
          findsOneWidget,
          reason: 'the link itself is still announced',
        );
      }

      await disposeApp(tester);
    });
    testWidgets('the nav bar and every control carry a semantics label', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      expect(find.bySemanticsLabel(_navLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);

      final close = tester
          .getSemantics(find.bySemanticsLabel(_closeLabel))
          .getSemanticsData();
      expect(close.label, _closeLabel);
      expect(close.flagsCollection.isButton, isTrue);
      expect(close.hasAction(SemanticsAction.tap), isTrue);

      for (final link in _legalLinks) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(link))
            .getSemanticsData();
        expect(data.label, link, reason: link);
        expect(data.flagsCollection.isButton, isTrue, reason: link);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: link);
      }

      // The selected plan is announced as selected (one plan, pre-selected).
      // NOTE (Stage 2, iteration 2): `flagsCollection.isSelected` is a
      // `Tristate` (engine `SemanticsFlags`), which the `isTrue` matcher
      // (bool-only) can never match — same assertion as `isButton` above,
      // but with the correctly-typed matcher.
      final plan = tester
          .getSemantics(find.bySemanticsLabel(RegExp('Annual')))
          .getSemanticsData();
      expect(plan.flagsCollection.isSelected, Tristate.isTrue);

      await disposeApp(tester);
    });

    testWidgets('decorative hero art and tick marks stay out of semantics', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      // The nest and the three coins are `alt=""` in the design, and the
      // benefits' ticks are `aria-hidden`, so none of them may announce
      // itself; the hero's only labelled image is Pip. The pattern below
      // legitimately matches exactly two labels — the hero title (it
      // contains "Nestling") and Pip's alt — so the assertion is "no
      // THIRD match", i.e. nothing decorative contributes its own node.
      final decorativeMatches = find
          .bySemanticsLabel(
            RegExp('nest|coin|tick|checkmark', caseSensitive: false),
          )
          .evaluate()
          .map(
            (element) => (element as RenderObjectElement)
                .renderObject
                .debugSemantics
                ?.label,
          )
          .where(
            (label) => label != null && label != _pipLabel && label != _title,
          )
          .toList();
      expect(decorativeMatches, isEmpty);
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);

      // Each benefit is one labelled row, tick excluded.
      for (final benefit in _benefits) {
        expect(find.bySemanticsLabel(benefit), findsOneWidget, reason: benefit);
      }

      await disposeApp(tester);
    });
  });

  group('P07 paywall — static copy under every seed', () {
    testWidgets('demo, empty and fresh render the identical paywall', (
      tester,
    ) async {
      // DATA OVER MOCKS: P07 is marketing copy for a family that does not
      // exist yet, so no seed may change a pixel of it — and the seeded
      // children (Maya, Leo) must never leak onto the screen.
      final snapshots = <String>[];

      for (final seed in const <String>['demo', 'empty', 'fresh']) {
        await _pumpPaywallWithSeed(tester, switch (seed) {
          'demo' => Seed.demo,
          'empty' => Seed.empty,
          _ => Seed.fresh,
        });

        await _scrollToEnd(tester);
        snapshots.add(
          [
            for (final text in _renderedText(tester))
              if (!_legalLinks.contains(text)) text,
          ].join(' | '),
        );
        await disposeApp(tester);
      }

      expect(snapshots.toSet(), hasLength(1), reason: snapshots.join('\n\n'));
      final snapshot = snapshots.first;
      for (final expected in <String>[
        _title,
        ..._benefits,
        _planTitle,
        _planSub,
        _planTag,
        _timelineHead,
        for (final (title, sub) in _timeline) ...<String>[title, sub],
        _familyNote,
        _cta,
      ]) {
        expect(snapshot, contains(expected), reason: expected);
      }
      // 'James' is the design's co-parent name, not a seeded child.
      expect(snapshot, contains('James'));
      expect(snapshot, isNot(contains('Maya')));
      expect(snapshot, isNot(contains('Leo')));
    });
  });

  group('P07 paywall — route wiring', () {
    testWidgets('the route provides a bloc that loads the annual plan', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPaywall(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
      );

      final bloc = BlocProvider.of<PaywallBloc>(
        tester.element(find.byType(PaywallView)),
      );
      await _settle(tester);

      expect(bloc.state.status, PaywallStatus.loaded);
      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.items.single.id, 'annual');
      expect(bloc.state.items.single.title, _planTitle);

      await disposeApp(tester);
    });

    testWidgets('/paywall is reachable while onboarding is still incomplete', (
      tester,
    ) async {
      await _pumpPaywallWithSeed(tester, Seed.fresh);

      // The router guard must let the last onboarding step through, otherwise
      // the onboarding flow dead-ends on P06.
      expect(currentPath(tester), '/paywall');
      expect(find.text(_cta), findsOneWidget);

      await disposeApp(tester);
    });
  });
}
