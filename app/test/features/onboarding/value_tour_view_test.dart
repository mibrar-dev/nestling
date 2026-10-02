// P02 Value tour — widget contract.
//
// Covers: the static tour copy and preview cards, light + dark themes,
// widths 320/390/430 at text scales 1.0/1.3, pager behaviour (Next taps,
// swipe, reduced-motion jump), navigation to /create-account, every
// OnboardingBloc status (initial/loading/empty/loaded/failure), the
// PipAvatar orchestrator rule and the accessibility contract (semantic
// labels, 44dp parent tap targets, no kid controls).
//
// The tour is static marketing copy (mirroring OnboardingRepositoryImpl._steps
// verbatim), so every bloc status renders the identical screen — the same
// pattern as P01 `welcome_view_test.dart`.

import 'dart:async';
import 'dart:math' as math;

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
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart' as v2;
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:nestling/features/onboarding/presentation/views/value_tour_view.dart';
import 'package:nestling/features/onboarding/presentation/widgets/value_tour_preview_row.dart';

import '../../test_scope.dart';

const String _step1Title = 'Set quests in seconds';
// ORCHESTRATOR_NOTES 2 (mandatory): the design's exact punctuation —
// curly double quotes (U+201C/201D) and an em dash, not straight quotes.
const String _step1Body =
    'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
    'your own.';
const String _step2Title = 'Pip grows as they help';
const String _step2Body =
    'Every finished quest feeds Pip the bird, from egg to songbird.';
const String _step3Title = 'Pocket money, sorted';
const String _step3Body =
    'No bank card needed — we keep score, you pay your way.';
const String _pipLabel = 'Pip the fledgling bird';

/// The card date chip is part of the illustration, not live data:
/// ORCHESTRATOR_NOTES 1 (mandatory) pins the design's static `Sat 4 Oct`
/// (`P02-value-tour.html:68` and `:115`) instead of a derived payout date.
const String _dateChip = 'Sat 4 Oct';

/// Seed variants the tour must render identically under (ORCHESTRATOR_NOTES
/// 1: the tour is an illustration, so no seed may change a pixel of it).
enum _Seed { demo, empty, fresh }

/// Any SvgPicture still loading a v1 `pip_stage_*.svg` illustration.
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.startsWith(
        'assets/illustrations/pip_stage_',
      ),
);

/// In-memory repository with a caller-controlled item stream, used to reach
/// the states the Drift repository cannot (pending load, empty, stream error).
class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this._items);

  final Stream<List<OnboardingStep>> _items;

  @override
  Future<List<OnboardingStep>> getItems() => _items.first;

  @override
  Stream<List<OnboardingStep>> watchItems() => _items;

  @override
  Stream<bool> watchComplete() => Stream<bool>.value(true);

  @override
  Future<void> completeOnboarding() async {}
}

/// Pumps `/value-tour` through the real app (router, DI, themes) at [surface]
/// and [textScale]. Mirrors [pumpAppRoute], which does not take size/scale.
Future<void> _pumpTour(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpAppRoute(tester, '/value-tour', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [ValueTourView] directly (no router) under the real theme with
/// [repository] driving the bloc; returns the bloc for state assertions.
Future<OnboardingBloc> _pumpTourView(
  WidgetTester tester, {
  required OnboardingRepository repository,
  required ThemeMode theme,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final bloc = OnboardingBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<OnboardingBloc>.value(
        value: bloc,
        child: const ValueTourView(),
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

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('p02_next')));
  await tester.pumpAndSettle();
}

/// The tour card that contains [text] (all three are [NestCard]s).
Finder _cardWith(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(NestCard));

/// The shared Skip action in the compact nav bar. The design-system
/// `_NavActionButton` owns the labeled node (no feature key), so tests
/// target its [InkWell] — the only one inside `NestNavBar` on this screen —
/// for size, tap action and geometry, and the `Skip` semantics node for
/// label/button.
Finder get _skipInkwell => find.descendant(
  of: find.byType(NestNavBar),
  matching: find.byType(InkWell),
);

/// The single progress bar inside [card].
NestProgress _progressIn(WidgetTester tester, Finder card) =>
    tester.widget<NestProgress>(
      find.descendant(of: card, matching: find.byType(NestProgress)),
    );

/// Probe boundary for the BOTTOM EDGE owner rule (painted-pixel proof).
const Key _pixelProbe = ValueKey('p02_pixel_probe');

/// Pumps the real app inside a [RepaintBoundary] so painted pixels can be
/// sampled, optionally with an OS bottom inset (home-indicator devices).
Future<void> _pumpTourForPixels(
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
      child: NestlingApp(initialRoute: '/value-tour'),
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
  group('P02 value tour — copy, theming, width and scale', () {
    testWidgets('light: renders card 1, dots, step copy and CTAs', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Orchestrator rule: NestStatusBar only reserves height — the OS
      // draws the real status bar, so no mock clock glyphs in the app.
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Today’s quests'), findsOneWidget);
      expect(find.text(_dateChip), findsWidgets);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Put the bins out'), findsOneWidget);
      expect(find.text('Reading – 20 minutes'), findsOneWidget);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(find.text('4 of 6 quests done today'), findsOneWidget);
      expect(find.text('New quest'), findsOneWidget);
      expect(find.byType(NestPagerDots), findsOneWidget);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: renders the same content without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('Today’s quests'), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await setUpTestScope();
            await _pumpTour(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.text(_step1Title), findsOneWidget);
            expect(find.text('Next'), findsOneWidget);
            expect(find.text('Skip'), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group(
    'P02 value tour — Pip is the v2 avatar (mandatory orchestrator rule)',
    () {
      testWidgets('exactly 4 PipAvatars, all mochi/sunny, stages [3,1,2,3]', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        // The v1 onboarding SVGs must never render in a product screen.
        expect(_v1PipFinder, findsNothing);

        // The main Pip lives on step 2: advance the pager so its semantics
        // node is onscreen (offscreen nodes stay out of the semantics tree).
        await _tapNext(tester);

        final avatars = tester
            .widgetList<v2.PipAvatar>(find.byType(v2.PipAvatar))
            .toList();
        expect(avatars.map((a) => a.stage).toList(), const [3, 1, 2, 3]);
        for (final avatar in avatars) {
          expect(avatar.style, v2.PipStyle.mochi);
          expect(avatar.skin, v2.PipSkin.sunny);
        }

        // The main Pip fills its 158x158 slot and carries the design alt text.
        final mainRect = tester.getRect(find.bySemanticsLabel(_pipLabel));
        expect(mainRect.width, moreOrLessEquals(158, epsilon: 0.01));
        expect(mainRect.height, moreOrLessEquals(158, epsilon: 0.01));

        await disposeApp(tester);
      });
    },
  );

  group('P02 value tour — the design’s copy, character by character', () {
    // ORCHESTRATOR_NOTES 2 (mandatory): every page's copy must match
    // P02-value-tour.html exactly. Page 1's block is in the HTML
    // (`:128-129`, with &ldquo;/&rdquo;/&mdash;); pages 2–3 come from the same
    // tour step list (DESIGN_SPEC §5 P02) and are pinned here so a copy edit
    // has to be deliberate.
    const steps = <(String, String)>[
      (
        'Set quests in seconds',
        'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
            'your own.',
      ),
      (
        'Pip grows as they help',
        'Every finished quest feeds Pip the bird, from egg to songbird.',
      ),
      (
        'Pocket money, sorted',
        'No bank card needed — we keep score, you pay your way.',
      ),
    ];

    for (var i = 0; i < steps.length; i++) {
      testWidgets('step ${i + 1} title and body are the design’s', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );
        for (var advance = 0; advance < i; advance++) {
          await _tapNext(tester);
        }

        expect(find.text(steps[i].$1), findsOneWidget, reason: 'title');
        expect(find.text(steps[i].$2), findsOneWidget, reason: 'body');
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the repository’s step copy matches what the view renders', (
      tester,
    ) async {
      // The view renders static copy and the route-level bloc feeds the
      // repository's list, so the two must be the same strings: a loaded
      // screen (or a future refactor that reads the bloc) must never show
      // different punctuation than the pre-load frame.
      await setUpTestScope();
      final steps = await GetIt.instance<OnboardingRepository>().getItems();
      expect(steps, hasLength(3));

      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      for (var i = 0; i < steps.length; i++) {
        if (i > 0) {
          await _tapNext(tester);
        }
        expect(find.text(steps[i].title), findsOneWidget, reason: 'title $i');
        expect(find.text(steps[i].detail), findsOneWidget, reason: 'body $i');
      }

      // The repository carries the design's punctuation too, not the older
      // straight-quote string (ORCHESTRATOR_NOTES 2).
      const step1Detail =
          'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
          'your own.';
      expect(steps.map((step) => step.detail).toList(), const [
        step1Detail,
        'Every finished quest feeds Pip the bird, from egg to songbird.',
        'No bank card needed — we keep score, you pay your way.',
      ]);

      await disposeApp(tester);
    });

    testWidgets('the card heads use the design’s U+2019 apostrophes', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('Today’s quests'), findsOneWidget);
      await _tapNext(tester);
      expect(find.text('Pip’s nest'), findsOneWidget);
      await _tapNext(tester);
      expect(find.text('Maya’s jar'), findsOneWidget);

      // The straight-apostrophe variants must not exist anywhere: the design
      // uses &rsquo; throughout (`P02-value-tour.html:68, 99, 111`).
      for (final straight in const [
        "Today's quests",
        "Pip's nest",
        "Maya's jar",
      ]) {
        expect(find.text(straight), findsNothing, reason: 'no ASCII fallback');
      }

      await disposeApp(tester);
    });
  });

  group('P02 value tour — orchestrator rule: copy characters', () {
    // Orchestrator COPY rule + ORCHESTRATOR_NOTES 2 (mandatory): the design's
    // typographic characters exactly — curly apostrophes and quotes, en/em
    // dashes, the middle dot — compared against
    // design/html-source/screens/P02-value-tour.html. The literals below are
    // the design's own characters, and each special character is additionally
    // pinned by code point so a same-wrong-character change cannot slip
    // through. These assertions are font-independent, which matters here: the
    // widget-test font is ~2x wider than real Inter and cannot judge line
    // fitting (see `p02_bugs_test.dart` P02-BUG-7 for the device evidence).
    const readingTitle = 'Reading \u2013 20 minutes'; // &ndash;
    const headQuests = 'Today\u2019s quests'; // &rsquo;
    const headNest = 'Pip\u2019s nest';
    const headJar = 'Maya\u2019s jar';
    const subWeekly = 'Maya \u00b7 weekly'; // &middot;
    const subOnce = 'Leo \u00b7 once';
    const subDaily = 'Maya \u00b7 daily';
    const caption = '175 of 250 coins \u00b7 Pip evolves at 250';

    testWidgets('every design character is the typographic code point', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // en dash (U+2013) where the design uses &ndash;
      expect(readingTitle, contains('\u2013'));
      expect(readingTitle, isNot(contains('\u002D')));
      // curly apostrophe (U+2019) where the design uses &rsquo;
      for (final head in const [headQuests, headNest, headJar]) {
        expect(head, contains('\u2019'));
        expect(head, isNot(contains("\u0027")));
      }
      // middle dot (U+00B7) where the design uses &middot;
      for (final sub in const [subWeekly, subOnce, subDaily, caption]) {
        expect(sub, contains('\u00b7'));
        expect(sub, isNot(contains('\u002E')), reason: 'no ASCII period');
      }
      // curly double quotes (U+201C / U+201D) and an em dash (U+2014)
      expect(_step1Body, contains('\u201C'));
      expect(_step1Body, contains('\u201D'));
      expect(_step1Body, contains('\u2014'));
      expect(_step3Body, contains('\u2014'));
      expect(
        _step2Body.contains('\u2014'),
        isFalse,
        reason: 'the egg-to-songbird copy has no dash in the design',
      );

      // …and the same characters reach the screen.
      expect(find.text(readingTitle), findsOneWidget);
      expect(find.text(headQuests), findsOneWidget);
      await _tapNext(tester);
      expect(find.text(caption), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('all three pages render exactly the design’s characters', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Copy per page, straight from P02-value-tour.html (strings that appear
      // once per page; the duplicated subs are asserted with their counts).
      final perPage = <List<String>>[
        [
          headQuests,
          'Sat 4 Oct',
          'Empty the dishwasher',
          'Put the bins out',
          readingTitle,
          'Tidy your bedroom',
          '4 of 6 quests done today',
          'New quest',
        ],
        // 'Fledgling' appears twice on this card (chip + label).
        [headNest, caption, 'Next stage: Songbird'],
        [headJar, 'Weekly base', 'Total', 'No bank card needed'],
      ];

      final rendered = <String>{};
      expect(find.text(subWeekly), findsNWidgets(2), reason: 'rows 1 and 4');
      for (var page = 0; page < 3; page++) {
        for (final text in perPage[page]) {
          expect(
            find.text(text),
            findsOneWidget,
            reason: 'page ${page + 1}: "$text"',
          );
        }
        for (final element in find.byType(RichText).evaluate()) {
          final render = element.renderObject;
          if (render is RenderParagraph) {
            final text = render.text.toPlainText().trim();
            if (text.isNotEmpty) {
              rendered.add(text);
            }
          }
        }
        if (page < 2) {
          await _tapNext(tester);
        }
      }

      // No ASCII quotes or ellipsis anywhere: the design sets none, and an
      // ellipsis can only come from truncation. Hyphens need care — the
      // design *does* use a plain one inside "ready-made", so only a SPACED
      // hyphen (a dash where – or — belongs) is a character regression.
      const forbidden = <String>[
        "\u0027", // ASCII apostrophe
        '\u0022', // ASCII quote
        '\u2026', // ellipsis (only truncation introduces one)
      ];
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

      // The design's own word-level hyphen survives (ready-made, U+002D).
      expect(_step1Body, contains('ready-made'));
      expect(_step1Body, isNot(matches(spacedHyphen)));

      await disposeApp(tester);
    });
  });

  group('P02 value tour — ValueTourFitText contract (P02-BUG-10)', () {
    // The preview title must render the design's names in full at 390
    // (ORCHESTRATOR_NOTES 3) without ever painting below 0.92 of the 15dp
    // token size (P02-BUG-10). Both halves are decided by the
    // slot ÷ natural-width ratio, so these tests measure the natural width
    // themselves and hand the widget exact slots — which makes them immune
    // to the ~2x-wide widget-test font and true for any font.

    /// Natural single-line width of [text] in [style] at the ambient scaler.
    double naturalWidthOf(
      WidgetTester tester,
      String text,
      TextStyle style,
      double textScale,
    ) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(textScale),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    /// The scale [title] is painted at, measured from the render tree.
    double paintedScaleOf(WidgetTester tester, String title) {
      final fitted = find.ancestor(
        of: find.text(title),
        matching: find.byType(FittedBox),
      );
      if (fitted.evaluate().isEmpty) return 1;
      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final ratio = tester.getSize(fitted.first).width / paragraph.size.width;
      return ratio.clamp(0, 1).toDouble();
    }

    /// Pumps [title] in a slot [slotRatio]× its natural width.
    Future<void> pumpFitted(
      WidgetTester tester, {
      required String title,
      required TextStyle style,
      required double slotRatio,
      required double textScale,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // The widget measures with MediaQuery's scaler, so the probe below must
      // use the same one or the slot would not be the ratio we asked for.
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final natural = naturalWidthOf(tester, title, style, textScale);
      final slot = natural * slotRatio;
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: slot,
                child: ValueTourFitText(text: title, style: style),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    const title = 'Empty the dishwasher';
    const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    for (final textScale in const <double>[1, 1.3]) {
      testWidgets(
        'a slot at or above 0.92 scales, never truncates ($textScale)',
        (tester) async {
          for (final slotRatio in const <double>[1, 0.95, 0.92]) {
            await pumpFitted(
              tester,
              title: title,
              style: style,
              slotRatio: slotRatio,
              textScale: textScale,
            );

            final painted = paintedScaleOf(tester, title);
            expect(
              painted,
              moreOrLessEquals(slotRatio, epsilon: 0.02),
              reason:
                  'slot ${slotRatio}x natural must paint at that scale — fitting '
                  'is always preferred over truncating',
            );
            expect(
              tester
                  .renderObject<RenderParagraph>(find.text(title))
                  .didExceedMaxLines,
              isFalse,
              reason:
                  'at ${slotRatio}x the name still fits on one line in full',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }
        },
      );

      testWidgets('a starved slot ellipsises at full size ($textScale)', (
        tester,
      ) async {
        await pumpFitted(
          tester,
          title: title,
          style: style,
          slotRatio: 0.5,
          textScale: textScale,
        );

        expect(
          find.ancestor(of: find.text(title), matching: find.byType(FittedBox)),
          findsNothing,
          reason:
              'below 0.92 the widget must not fit — that is the BUG-10 shrink',
        );
        expect(
          tester.widget<Text>(find.text(title)).style?.fontSize,
          moreOrLessEquals(15, epsilon: 0.01),
          reason:
              "the fallback paints the design's 15dp token size (the ambient "
              'scaler is applied by MediaQuery on top, never baked in)',
        );
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(title))
              .didExceedMaxLines,
          isTrue,
          reason: 'a starved slot truncates honestly instead of shrinking',
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  });

  group('P02 value tour — orchestrator ruling: child order', () {
    testWidgets('seeded children keep insertion order, not alphabetical', (
      tester,
    ) async {
      // Orchestrator ruling: children are always listed in the order they
      // were added (Maya, then Leo), never alphabetically — in every screen
      // and repository. Seed.demo inserts maya before leo (seed.dart:182,
      // :204); alphabetical would yield [leo, maya], so this assertion
      // actually discriminates between the two rules.
      final db = await setUpTestScope();

      final ordered = await db.select(db.children).get();
      expect(
        ordered.map((child) => child.id).toList(),
        ['maya', 'leo'],
        reason:
            'children must come back in insertion order; alphabetical order '
            'would be [leo, maya] and would break every roster that pairs a '
            'child with their quests',
      );
      expect(
        ordered.map((child) => child.id).toList(),
        isNot(['leo', 'maya']),
        reason: 'alphabetical order is explicitly ruled out',
      );
    });
  });

  group('P02 value tour — pager behaviour', () {
    testWidgets('Next advances one step at a time, then becomes Continue', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 1);
      expect(find.byKey(const ValueKey('p02_next')), findsOneWidget);

      await _tapNext(tester);
      expect(find.text(_step3Title), findsOneWidget);
      expect(find.text(_step3Body), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 2);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_next')), findsNothing);
      expect(find.text('Maya’s jar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('two fast taps advance one step, never skip a page', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Review 7: `_goTo` animates to an explicit target (not `nextPage`),
      // so a second tap mid-flight retargets the same page instead of
      // advancing from the current offset.
      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pumpAndSettle();

      expect(
        find.text(_step2Title),
        findsOneWidget,
        reason: 'two taps in quick succession must land on step 2, not step 3',
      );
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 1);
      expect(find.byKey(const ValueKey('p02_continue')), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('swipe left advances, swipe right returns', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text(_step2Title), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);

      await disposeApp(tester);
    });

    testWidgets('reduced motion still advances via jump', (tester) async {
      final bloc = OnboardingBloc(
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[]),
        ),
      );
      addTearDown(bloc.close);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          darkTheme: NestTheme.dark(),
          home: Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(disableAnimations: true),
                child: BlocProvider<OnboardingBloc>.value(
                  value: bloc,
                  child: const ValueTourView(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pump();

      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P02 value tour — navigation', () {
    testWidgets('Skip opens /create-account', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('Continue on the last step opens /create-account', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      await _tapNext(tester);
      await tester.tap(find.byKey(const ValueKey('p02_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('Next on steps 1-2 stays on /value-tour', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });

    testWidgets('tapping a preview row does not navigate', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();

      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });
  });

  group('P02 value tour — BLoC states render the identical tour', () {
    setUp(() {});

    testWidgets('initial: tour renders before the load event', (tester) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );

      expect(bloc.state.status, OnboardingStatus.initial);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: tour renders while no items have arrived', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loading);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with no items: still the full tour', (tester) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items, isEmpty);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with items: the same static tour', (tester) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[
            OnboardingStep(
              id: 'quests',
              title: _step1Title,
              detail: _step1Body,
            ),
          ]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: a repository error never blocks the tour', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.failure);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P02 value tour — accessibility', () {
    testWidgets('labels, pager group and tap targets meet the contract', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // The step title is the screen's only heading (HTML `<h1>`).
      final titleData = tester
          .getSemantics(find.text(_step1Title))
          .getSemanticsData();
      expect(titleData.flagsCollection.isHeader, isTrue);

      // The pager exposes its group label, updating per step (HTML
      // `role=group` aria-label).
      expect(
        find.bySemanticsLabel('Tour preview, step 1 of 3'),
        findsOneWidget,
      );

      // Skip and Next expose button semantics with their labels. Skip's
      // labeled node is shared design-system code (no feature key), so the
      // label/button come from its semantics node and the activation action
      // from its own InkWell.
      final skipData = tester
          .getSemantics(find.bySemanticsLabel('Skip'))
          .getSemanticsData();
      expect(skipData.label, 'Skip');
      expect(skipData.flagsCollection.isButton, isTrue);
      expect(
        tester
            .getSemantics(_skipInkwell)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      final nextData = tester
          .getSemantics(find.byKey(const ValueKey('p02_next')))
          .getSemanticsData();
      expect(nextData.label, 'Next');
      expect(nextData.flagsCollection.isButton, isTrue);

      // Decorative chrome carries no semantics; P02 has no icon-only
      // buttons and no kid controls.
      expect(find.bySemanticsLabel('9:41'), findsNothing);
      expect(find.byType(NestIconButton), findsNothing);
      expect(find.byType(NestKidButton), findsNothing);

      // Parent rule: Skip is at least 44x44, Next is a 52dp pill CTA.
      final skipSize = tester.getSize(_skipInkwell);
      final nextSize = tester.getSize(find.byKey(const ValueKey('p02_next')));
      expect(skipSize.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(skipSize.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(nextSize.height, greaterThanOrEqualTo(52));
      expect(nextSize.width, 390 - 2 * NestSpacing.padSide);

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      final skipSize = tester.getSize(_skipInkwell);
      final nextSize = tester.getSize(find.byKey(const ValueKey('p02_next')));
      expect(skipSize.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(nextSize.height, greaterThanOrEqualTo(52));
      expect(nextSize.width, 320 - 2 * NestSpacing.padSide);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — route wiring and Drift seeds', () {
    testWidgets('route provides a working bloc whose load reaches loaded', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // `BlocProvider` is lazy and the static tour never reads the bloc, so
      // the route's `OnboardingLoadRequested` only runs on the first read —
      // after which the state machine loads the three steps (observed
      // behaviour, pinned deliberately; no user impact on P02).
      final bloc = BlocProvider.of<OnboardingBloc>(
        tester.element(find.byType(ValueTourView)),
      );
      await tester.pump();
      await tester.pump();
      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items.map((step) => step.title), const [
        _step1Title,
        _step2Title,
        _step3Title,
      ]);

      await disposeApp(tester);
    });

    testWidgets('the illustration is byte-identical under every seed', (
      tester,
    ) async {
      // ORCHESTRATOR_NOTES 1 (mandatory): the value tour is a MARKETING
      // carousel shown before any family exists, so its cards carry the
      // design's static copy — NOT the database. Proof: card 1 renders the
      // same rows, subs, coin values, date chip and progress caption under
      // Seed.demo (Maya 120 coins, 3 approvals, 12 quests), Seed.empty
      // (onboarded parent, no children) and Seed.fresh (nothing at all).
      final snapshots = <String>[];

      for (final seed in const <_Seed>[_Seed.demo, _Seed.empty, _Seed.fresh]) {
        final db = await setUpTestScope(seedDemo: seed == _Seed.demo);
        if (seed == _Seed.empty) {
          await Seed.empty(db);
          await GetIt.instance<AppSession>().refresh();
        } else if (seed == _Seed.fresh) {
          await Seed.fresh(db);
          await GetIt.instance<AppSession>().refresh();
        }
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        final card = _cardWith('Today’s quests');
        final rows = tester
            .widgetList<ValueTourPreviewRow>(
              find.descendant(
                of: card,
                matching: find.byType(ValueTourPreviewRow),
              ),
            )
            .map((row) => '${row.title} / ${row.subtitle} / ${row.coins}')
            .join(' ; ');
        final chip = tester
            .widget<NestChip>(
              find.descendant(of: card, matching: find.byType(NestChip)),
            )
            .label;
        snapshots.add(
          '$rows || chip=$chip || ${_progressIn(tester, card).fraction} || '
          '${find.text('4 of 6 quests done today').evaluate().length}',
        );

        await disposeApp(tester);
      }

      expect(snapshots.toSet(), hasLength(1), reason: snapshots.join('\n'));
      // …and that one snapshot is the design's copy, not the seed's.
      final snapshot = snapshots.first;
      expect(snapshot, contains('Empty the dishwasher / Maya · weekly / 15'));
      expect(snapshot, contains('Put the bins out / Leo · once / 15'));
      expect(snapshot, contains('Reading – 20 minutes / Maya · daily / 10'));
      expect(snapshot, contains('Tidy your bedroom / Maya · weekly / 15'));
      expect(snapshot, contains('chip=Sat 4 Oct'));
    });

    testWidgets('Seed.empty (onboarded, no children): identical tour', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();

      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Seed.fresh: /value-tour renders during first-run setup', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(currentPath(tester), '/value-tour');
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — pager geometry and card content', () {
    for (final width in const <int>[320, 390, 430]) {
      testWidgets('width $width: card clamps and the next card peeks', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
          textScale: 1,
        );

        final cardW = math.min(310, math.max(240, width - 80)).toDouble();
        final rect = tester.getRect(_cardWith('Today’s quests'));
        expect(rect.left, moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01));
        expect(rect.width, moreOrLessEquals(cardW, epsilon: 0.01));

        // The next card starts one pitch later (cardW + the 12px design gap,
        // c2 left 342 = 20 + 310 + 12), clipped by the pager edge exactly
        // like the design's peek.
        final peek = tester.getRect(_cardWith('Pip’s nest'));
        expect(
          peek.left,
          moreOrLessEquals(NestSpacing.padSide + cardW + 12, epsilon: 0.01),
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('card 1 previews the design rows, coins and progress', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith('Today’s quests');
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      // ORCHESTRATOR_NOTES 1 (mandatory): the design's own illustration copy
      // (P02-value-tour.html:72-88), not Seed.demo's assignee/repeat values.
      expect(inCard(find.text('Maya · weekly')), findsNWidgets(2));
      expect(inCard(find.text('Leo · once')), findsOneWidget);
      expect(inCard(find.text('Maya · daily')), findsOneWidget);
      expect(inCard(find.text(_dateChip)), findsOneWidget);
      expect(inCard(find.text('4 of 6 quests done today')), findsOneWidget);

      final pills = tester
          .widgetList<NestCoinPill>(inCard(find.byType(NestCoinPill)))
          .map((pill) => pill.amount)
          .toList();
      expect(pills, const ['15', '15', '10', '15']);
      expect(
        _progressIn(tester, card).fraction,
        moreOrLessEquals(4 / 6, epsilon: 1e-9),
      );

      // The dashed add-row is a non-interactive preview whose label stays
      // exposed as plain text (the HTML does not hide it).
      expect(inCard(find.text('New quest')), findsOneWidget);
      expect(inCard(find.bySemanticsLabel('New quest')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('card 2 shows the Pip stage copy', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);

      final card = _cardWith('Pip’s nest');
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      expect(inCard(find.text('Fledgling')), findsNWidgets(2)); // chip + label
      expect(
        inCard(find.text('175 of 250 coins · Pip evolves at 250')),
        findsOneWidget,
      );
      expect(inCard(find.text('Next stage: Songbird')), findsOneWidget);

      final chip = tester.widget<NestChip>(inCard(find.byType(NestChip)));
      expect(chip.label, 'Fledgling');
      expect(chip.selected, isTrue);
      expect(
        _progressIn(tester, card).fraction,
        moreOrLessEquals(0.7, epsilon: 1e-9),
      );

      await disposeApp(tester);
    });

    testWidgets('card 3 ledger shows the design’s static illustration', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      await _tapNext(tester);

      // ORCHESTRATOR_NOTES 1 (mandatory): the jar card is an illustration, so
      // the ledger is the design's static copy (P02-value-tour.html:113-119:
      // £3.00 base + £1.20 quests = £4.20), not a live read of the family and
      // child rows.
      final card = _cardWith('Maya’s jar');
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      expect(inCard(find.text('coming on Saturday')), findsOneWidget);
      expect(inCard(find.text('Weekly base')), findsOneWidget);
      expect(inCard(find.text('£3.00')), findsOneWidget);
      expect(inCard(find.text('Quests (120 coins)')), findsOneWidget);
      expect(inCard(find.text('+£1.20')), findsOneWidget);
      expect(inCard(find.text('Total')), findsOneWidget);
      expect(inCard(find.text('£4.20')), findsNWidgets(2));
      expect(inCard(find.text(_dateChip)), findsOneWidget);
      expect(inCard(find.text('No bank card needed')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('starved titles keep full size and ellipsise, never shrink', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      // ORCHESTRATOR_NOTES 3 (mandatory) + P02-BUG-10: below the 0.92 bound
      // the slot must NOT contain a FittedBox (which would read < 0.9 there)
      // — the title renders at the full 15dp style and truncates honestly.
      // (In the wide widget-test font every title is starved at this
      // surface, so all four take the fallback path.)
      for (final title in const <String>[
        'Empty the dishwasher',
        'Put the bins out',
        'Reading – 20 minutes',
        'Tidy your bedroom',
      ]) {
        final text = find.text(title);
        expect(
          find.ancestor(of: text, matching: find.byType(FittedBox)),
          findsNothing,
          reason:
              'below the bound "$title" must not sit in a FittedBox (it '
              'would paint below 0.9x); it keeps full size and ellipsises.',
        );
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(
          paragraph.didExceedMaxLines,
          isTrue,
          reason:
              '"$title" overruns its slot here, so the honest fallback is a '
              'visible ellipsis at full size — not a silent shrink.',
        );
        expect(
          tester.widget<Text>(text).style?.fontSize,
          moreOrLessEquals(15, epsilon: 0.01),
        );
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('steps 2-3 hold at 320dp with text scale 1.3', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      await _tapNext(tester);
      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapNext(tester);
      expect(find.text(_step3Title), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('pager height follows the text-scale rule at 1.0', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400, epsilon: 0.01),
      );

      await disposeApp(tester);
    });

    testWidgets('pager height follows the text-scale rule at 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1.3,
      );

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400 * 1.3, epsilon: 0.01),
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — live configuration changes', () {
    testWidgets('resize keeps the current step and the pager intact', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      await _tapNext(tester);
      expect(find.text(_step3Title), findsOneWidget);

      // `didChangeDependencies` rebuilds the PageController whenever the
      // viewport fraction changes (card-width clamp), seeded with the
      // current page — a rotation must not reset the tour to step 1.
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(_step3Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 2);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);

      // …and the clamped card width still follows the new viewport (card 1 is
      // disposed on page 3, so measure the card that is on screen).
      final cardW = math.min(310, math.max(240, 320 - 80)).toDouble();
      expect(
        tester.getRect(_cardWith('Maya’s jar')).width,
        moreOrLessEquals(cardW, epsilon: 0.01),
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a live text-scale change grows the pager and keeps the step', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400, epsilon: 0.01),
      );

      // Accessibility settings can change under the app: the pager height is
      // the clamped scale (1.0…1.3) times the 400dp design box.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400 * 1.3, epsilon: 0.01),
      );
      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 1);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — pager controls', () {
    testWidgets('the dashed add-rows are labels, not controls', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // `.pv-add` rows are illustration text in the design (no button, no
      // link): each announces as plain text, carries no tap action, and
      // neither pages the pager nor navigates.
      for (var step = 0; step < 3; step++) {
        if (step > 0) {
          await _tapNext(tester);
        }
        final label = const [
          'New quest',
          'Next stage: Songbird',
          'No bank card needed',
        ][step];

        expect(find.text(label), findsOneWidget, reason: 'step ${step + 1}');
        expect(
          tester
              .getSemantics(find.text(label))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'the design exposes this row as text, not a control',
        );

        await tester.tap(find.text(label), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index,
          step,
          reason: 'tapping the add-row must not change the page',
        );
        expect(currentPath(tester), '/value-tour');
      }

      await disposeApp(tester);
    });

    testWidgets('dots are non-interactive indicators', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byType(NestPagerDots));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });

    testWidgets('swiping to the last step swaps the CTA to Continue', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_step3Title), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_next')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('p02_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('swiping back at step 1 stays on step 1', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });
  });

  group('P02 value tour — accessibility extensions', () {
    testWidgets('pager group and dots labels follow the current step', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        find.bySemanticsLabel('Tour preview, step 1 of 3'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);

      // Dots are indicators, not controls (the HTML has plain spans).
      expect(find.bySemanticsLabel('Go to page 1'), findsNothing);
      expect(find.bySemanticsLabel('Go to page 2'), findsNothing);
      expect(find.bySemanticsLabel('Go to page 3'), findsNothing);

      await _tapNext(tester);

      expect(
        find.bySemanticsLabel('Tour preview, step 2 of 3'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('preview add-rows expose plain-text labels', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Non-interactive, but exposed (the HTML does not hide them).
      expect(find.bySemanticsLabel('New quest'), findsOneWidget);

      await _tapNext(tester);
      expect(find.bySemanticsLabel('Next stage: Songbird'), findsOneWidget);

      await _tapNext(tester);
      expect(find.bySemanticsLabel('No bank card needed'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('status bar reserves height only; no back affordance', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        NestDevice.statusH,
      );
      expect(tester.getSize(find.byType(NestHomeIndicator)).height, 0);
      expect(find.byType(BackButton), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('Continue is a full-width 52dp target with button semantics', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      await _tapNext(tester);

      final size = tester.getSize(find.byKey(const ValueKey('p02_continue')));
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, 390 - 2 * NestSpacing.padSide);

      final data = tester
          .getSemantics(find.byKey(const ValueKey('p02_continue')))
          .getSemanticsData();
      expect(data.label, 'Continue');
      expect(data.flagsCollection.isButton, isTrue);

      await disposeApp(tester);
    });

    testWidgets('dark: card surface comes from the dark tokens', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith('Today’s quests');
      final container = tester.widget<Container>(
        find.descendant(of: card, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final darkSurface = tester.element(card).nest.surface;
      final lightSurface = NestTheme.light().extension<NestTokens>()!.surface;

      expect(decoration.color, darkSurface);
      expect(darkSurface, isNot(lightSurface));

      await disposeApp(tester);
    });
  });

  group('P02 value tour — static copy is data-independent', () {
    setUp(() {});

    testWidgets('late repository emissions never change the copy', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.fromIterable(<List<OnboardingStep>>[
            const <OnboardingStep>[],
            const <OnboardingStep>[
              OnboardingStep(
                id: 'late',
                title: 'DIFFERENT TITLE',
                detail: 'DIFFERENT BODY',
              ),
            ],
          ]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items.map((step) => step.title), const [
        'DIFFERENT TITLE',
      ]);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('DIFFERENT TITLE'), findsNothing);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Owner rule — BOTTOM EDGE: the area below the bottom bar, down to the
  // physical screen edge, must carry the SAME surface colour as the bar
  // itself. A page-tint strip under the CTA panel is a UI failure in light
  // and dark mode alike.
  // -------------------------------------------------------------------------
  group('P02 value tour — owner rule: bottom edge', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';

      testWidgets('$themeName: no page-colour strip under the CTA panel', (
        tester,
      ) async {
        await setUpTestScope();
        // A 34dp OS inset (home-indicator device) is where a strip shows up:
        // the bar content is lifted, the surface must not be.
        await _pumpTourForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          bottomInset: 34,
        );

        final bar = tester.getRect(find.byType(NestBottomCta));
        expect(
          bar.bottom,
          moreOrLessEquals(844, epsilon: 0.01),
          reason:
              'the CTA panel must run to the physical screen edge; ending it '
              'at ${bar.bottom} exposes page colour below the bar',
        );

        // Painted-pixel proof: the last row of pixels the OS draws over must
        // be the bar surface, not the scaffold paper underneath.
        final tokens = tester.element(find.byType(NestBottomCta)).nest;
        expect(
          tokens.paper,
          isNot(tokens.surface),
          reason:
              'the probe must discriminate: page colour and bar surface are '
              'different colours, so a strip below the bar cannot pass',
        );
        final edgePixel = await _pixelAt(tester, 195, 843);
        expect(
          edgePixel,
          _rgba(tokens.surface),
          reason:
              'the strip below the bar (y=843, inside the 34dp inset) must be '
              'the bar surface ${_rgba(tokens.surface)}; the scaffold paper '
              '${_rgba(tokens.paper)} must not show through there',
        );

        await disposeApp(tester);
      });

      testWidgets('$themeName: bar surface is flush with the edge inset 0', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTourForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
        );

        final bar = tester.getRect(find.byType(NestBottomCta));
        expect(bar.bottom, moreOrLessEquals(844, epsilon: 0.01));

        final tokens = tester.element(find.byType(NestBottomCta)).nest;
        final edgePixel = await _pixelAt(tester, 195, 843);
        expect(edgePixel, _rgba(tokens.surface));

        await disposeApp(tester);
      });
    }
  });

  // -------------------------------------------------------------------------
  // Owner rule — ALIGNMENT: consistent 20px side gutters, cards and bars on
  // the same edges, nothing a few px off.
  // -------------------------------------------------------------------------
  group('P02 value tour — owner rule: alignment', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: 20px gutters on every edge', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpTour(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
            textScale: 1,
          );

          final cardW = math.min(310, math.max(240, width - 80)).toDouble();
          final card = tester.getRect(_cardWith('Today’s quests'));
          final cta = tester.getRect(find.byKey(const ValueKey('p02_next')));
          final skip = tester.getRect(_skipInkwell);
          final bar = tester.getRect(find.byType(NestBottomCta));

          // Step copy and the CTA button both sit on the 20px gutter.
          expect(
            tester.getTopLeft(find.text(_step1Title)).dx,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(
            cta.left,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(
            cta.right,
            moreOrLessEquals(width - NestSpacing.padSide, epsilon: 0.01),
          );

          // The card shares the copy's left edge; its right edge is the
          // design's clipped peek (card 1 spans 20 … 20+cardW at 390).
          expect(
            card.left,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(card.width, moreOrLessEquals(cardW, epsilon: 0.01));

          // The bar is full-bleed (its panel owns the edge rule) and Skip is
          // right-aligned to the same gutter as the button.
          expect(bar.left, 0);
          expect(bar.right, moreOrLessEquals(width.toDouble(), epsilon: 0.01));
          expect(
            skip.right,
            moreOrLessEquals(width - NestSpacing.padSide, epsilon: 0.01),
          );

          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        });
      }
    }

    testWidgets('card content shares one inner left edge', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith('Today’s quests');
      final cardRect = tester.getRect(card);
      // The card pads its content by s4; every row of that content — head,
      // preview rows, progress bar, dashed add-row — starts on that one edge
      // (the preview-row *titles* sit further in, after their 36dp icon
      // tile, so the row container is the reference).
      final inner = cardRect.left + NestSpacing.s4;
      final rows = find.byType(ValueTourPreviewRow);
      expect(rows, findsNWidgets(4));

      for (final finder in <Finder>[
        find.text('Today’s quests'),
        rows.first,
        find.descendant(of: card, matching: find.byType(NestProgress)),
        find.ancestor(
          of: find.text('New quest'),
          matching: find.byType(CustomPaint),
        ),
      ]) {
        expect(
          tester.getTopLeft(finder).dx,
          moreOrLessEquals(inner, epsilon: 0.01),
          reason: 'every card row must start on the same inner edge',
        );
      }

      await disposeApp(tester);
    });
  });
}
