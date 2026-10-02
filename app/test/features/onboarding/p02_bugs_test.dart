// P02 Value tour — adversarial bug proofs (Stage 6).
//
// Iteration 1 found BUG-1..6; the iteration-2 build fixed BUG-1..3 and BUG-6
// (their proofs below are un-skipped and pass). ORCHESTRATOR_NOTES (mandatory)
// then ruled that the tour is a MARKETING ILLUSTRATION: the design's static
// copy is mandatory, not the database. That voided the BUG-4/BUG-5 "seed
// match" proofs and created P02-BUG-8; it also confirmed P02-BUG-7 (no
// truncation) and P02-BUG-9 (design typographic punctuation).
//
// The iteration-3 build fixed BUG-7, BUG-8 and BUG-9 (their proofs now pass).
// Stage 6, iteration 3 opened BUG-10: the FittedBox shrink used for BUG-7 has
// no lower bound, so at 320dp (and 390dp x 1.3) the design's 15dp titles paint
// as small as ~0.43x instead of wrapping (review iteration 3, finding 1).
// That proof is marked `skip: true` until the fix lands.
// Findings, repros and fixes: `docs/screens/P02/6_bugs.md`.
//
//   flutter test test/features/onboarding/p02_bugs_test.dart
//
// fixed  P02-BUG-1  pager 468dp vs the design's 400dp; below-pager copy clipped
// fixed  P02-BUG-2  card-1 preview rows 60dp vs the design's 38dp → titles cut
// fixed  P02-BUG-3  short screens (375x667 / 320x568) overflow or lose the copy
// fixed  P02-BUG-6  system back from /value-tour did not return to /welcome
// fixed  P02-BUG-7  titles truncated at 390dp (effectiveness now in BUG-10)
// fixed  P02-BUG-8  card subs + date chips are the design's static copy
// fixed  P02-BUG-9  curly quotes / em dash / curly apostrophes per the design
// void   P02-BUG-4  "seed subs win" — reversed by ORCHESTRATOR_NOTES 1
// void   P02-BUG-5  "derived date chip" — reversed by ORCHESTRATOR_NOTES 1
// OPEN   P02-BUG-10 preview titles shrink below 0.9x at 320dp / 1.3 (wrap, don't scale)

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/onboarding/presentation/widgets/value_tour_preview_row.dart';

import '../../test_scope.dart';

/// Pumps `/value-tour` through the real app at [surface] and [textScale].
Future<void> _pumpTour(
  WidgetTester tester, {
  required Size surface,
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpAppRoute(tester, '/value-tour');
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _cardOne() => find.ancestor(
  // U+2019 apostrophe: ORCHESTRATOR_NOTES 2 (mandatory) requires the design's
  // exact copy punctuation, so the finders must match it exactly.
  of: find.text('Today’s quests'),
  matching: find.byType(NestCard),
);

/// Effective painted scale of a preview title.
///
/// The row renders the title inside `FittedBox(fit: scaleDown)`, whose child
/// is laid out with unbounded constraints: the paragraph's own size is the
/// type's natural (token) size and the FittedBox box is the scaled result, so
/// `slot / natural` is the effective scale. When no FittedBox wraps the title
/// (a wrap/ellipsis implementation) the type paints at token size → 1.0.
double _paintedTitleScale(WidgetTester tester, String title) {
  final fitted = find.ancestor(
    of: find.text(title),
    matching: find.byType(FittedBox),
  );
  if (fitted.evaluate().isEmpty) return 1;
  final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
  final slot = tester.getSize(fitted.first);
  final ratio = slot.width / paragraph.size.width;
  return ratio.clamp(0, 1).toDouble();
}

void main() {
  // ---------------------------------------------------------------------
  // P02-BUG-1 (MAJOR) — the pager is 468dp tall instead of the design's
  // 400dp, so the copy block below it is clipped and jammed against the CTA.
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-1a pager is the design 400dp at 390x844 (currently 468dp)',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400, epsilon: 0.01),
        reason:
            'design .pager is 400dp (SPACING_SPEC §7, PNG card y107→507). '
            'The 468dp pager pushes everything below it 68dp down and leaves '
            'the copy block with only 193dp of viewport (see BUG-1c).',
      );

      await disposeApp(tester);
    },
  );

  testWidgets(
    'P02-BUG-1b pager is 400x1.3 at text scale 1.3 (currently 468x1.3)',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844), textScale: 1.3);

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400 * 1.3, epsilon: 0.01),
        reason:
            '1_plan §a text-scale rule: pagerH = design 400 x ts. At 1.3 the '
            'screen currently reserves 608.4dp, leaving a 52dp copy viewport.',
      );

      await disposeApp(tester);
    },
  );

  testWidgets(
    'P02-BUG-1c copy viewport fits the design copy block at 390x844',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      // Design copy budget: dots top 22 + dots 18 + title gap 30 + h1 line 34
      // + gap 12 + body 2 lines 48 + bottom pad 32 = 196dp.
      expect(
        viewport.height,
        greaterThanOrEqualTo(196),
        reason:
            'at 390x844 the app leaves 193dp (844 - 47 status - 52 nav - 468 '
            'pager - 84 CTA), so the body block is clipped by the pager/CTA '
            'and the body-to-CTA gap is ~20dp against the design 54-74dp.',
      );

      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------
  // P02-BUG-2 (MAJOR) — card-1 rows are 60dp instead of the design's 38dp,
  // so every preview title ellipsises on device ("Empty th…", "Put the bi…").
  // ---------------------------------------------------------------------
  testWidgets('P02-BUG-2 card-1 preview rows match the design 38dp .pv-row', (
    tester,
  ) async {
    await setUpTestScope();
    await _pumpTour(tester, surface: const Size(390, 844));

    final rows = find.descendant(
      of: _cardOne(),
      matching: find.byType(ValueTourPreviewRow),
    );
    expect(rows, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      expect(
        tester.getSize(rows.at(i)).height,
        lessThanOrEqualTo(40),
        reason:
            'design .pv-row is 38dp (36 tile, 15/20 + 13/18, no vertical '
            'row padding, 8dp gaps). The 60dp row spends the extra width on '
            'a 40 tile / 12 gaps / larger pill and truncates every title '
            '(device screenshot docs/screens/P02/ui/app_light_1.png).',
      );
    }

    await disposeApp(tester);
  });

  // ---------------------------------------------------------------------
  // P02-BUG-3 (MAJOR) — on short devices the fixed stack (47 status + 52 nav
  // + 468 pager + 84 CTA = 651dp) cannot fit: RenderFlex overflows.
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-3a 320x568 at text scale 1.0 has no RenderFlex overflow',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(320, 568));

      expect(
        tester.takeException(),
        isNull,
        reason:
            'fixed regions alone are 651dp > 568dp (RenderFlex overflowed by '
            '83px). 1_plan §a / SPACING_SPEC §10.2 require small portrait '
            'devices to scale down without overflow.',
      );
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(
        viewport.height,
        greaterThan(0),
        reason: 'the step copy must keep a usable viewport on short screens',
      );

      await disposeApp(tester);
    },
  );

  testWidgets(
    'P02-BUG-3b 375x667 at text scale 1.3 has no RenderFlex overflow',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(375, 667), textScale: 1.3);

      expect(
        tester.takeException(),
        isNull,
        reason:
            '47 + 52 + 608.4 + 84 = 791.4dp into a 667dp screen; the app '
            'overflows by 124px (iPhone SE class + large system text).',
      );

      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------
  // P02-BUG-8 (MAJOR, OPEN) — ORCHESTRATOR_NOTES 1: the tour is a marketing
  // illustration; its cards must use the design's static copy
  // (P02-value-tour.html:72-88), not the database.
  // ---------------------------------------------------------------------
  testWidgets("P02-BUG-8a card-1 rows use the design's static copy", (
    tester,
  ) async {
    await setUpTestScope();
    await _pumpTour(tester, surface: const Size(390, 844));

    const expected = <String, String>{
      'Empty the dishwasher': 'Maya · weekly',
      'Put the bins out': 'Leo · once',
      'Reading – 20 minutes': 'Maya · daily',
      'Tidy your bedroom': 'Maya · weekly',
    };
    for (final entry in expected.entries) {
      final row = tester.widget<ValueTourPreviewRow>(
        find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(ValueTourPreviewRow),
        ),
      );
      expect(
        row.subtitle,
        entry.value,
        reason:
            'ORCHESTRATOR_NOTES 1 (mandatory): the tour is a marketing '
            'illustration; the design copy is the spec '
            '(P02-value-tour.html:72-88 → Maya·weekly, Leo·once, Maya·daily, '
            'Maya·weekly), not Seed.demo.',
      );
    }

    await disposeApp(tester);
  });

  testWidgets("P02-BUG-8b both card date chips are the design's 'Sat 4 Oct'", (
    tester,
  ) async {
    await setUpTestScope();
    await _pumpTour(tester, surface: const Size(390, 844));

    final cardOneChip = tester.widget<NestChip>(
      find.descendant(of: _cardOne(), matching: find.byType(NestChip)),
    );
    expect(
      cardOneChip.label,
      'Sat 4 Oct',
      reason:
          'ORCHESTRATOR_NOTES 1 (mandatory): the design date "Sat 4 Oct" '
          'is part of the illustration; the derived payout Saturday '
          '(currently ${cardOneChip.label}) must go.',
    );

    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pumpAndSettle();
    final jarCard = find.ancestor(
      of: find.text('£4.20').first,
      matching: find.byType(NestCard),
    );
    final jarChip = tester.widget<NestChip>(
      find.descendant(of: jarCard, matching: find.byType(NestChip)),
    );
    expect(jarChip.label, 'Sat 4 Oct', reason: 'card 3 head chip');

    await disposeApp(tester);
  });

  // ---------------------------------------------------------------------
  // P02-BUG-9 (MAJOR, OPEN) — ORCHESTRATOR_NOTES 2: copy typography must
  // match the design character by character: curly double quotes + em dash in
  // the step-1 body, curly apostrophes in the card heads.
  // ---------------------------------------------------------------------
  testWidgets(
    "P02-BUG-9 step-1 body and card heads use the design's punctuation",
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      expect(
        find.text(
          'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
          'your own.',
        ),
        findsOneWidget,
        reason:
            'P02-value-tour.html:129 uses &ldquo; &rdquo; &mdash;, not '
            'straight quotes and "or"',
      );
      expect(find.text('Today’s quests'), findsOneWidget, reason: 'U+2019');

      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pumpAndSettle();
      expect(find.text('Pip’s nest'), findsOneWidget, reason: 'U+2019');
      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pumpAndSettle();
      expect(find.text('Maya’s jar'), findsOneWidget, reason: 'U+2019');

      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------
  // P02-BUG-6 (MINOR) — back from the tour: 1_plan §c says "system back
  // returns to /welcome via the router stack", but P01 uses context.go, which
  // replaces the stack — back pops nothing and exits the app.
  // ---------------------------------------------------------------------
  testWidgets('P02-BUG-6 system back from /value-tour returns to /welcome', (
    tester,
  ) async {
    await setUpTestScope();
    await pumpAppRoute(tester, '/welcome');
    await tester.tap(find.byKey(const ValueKey('p01_get_started')));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/value-tour');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      currentPath(tester),
      '/welcome',
      reason:
          '1_plan §c promises back returns to /welcome; context.go in '
          'welcome_view.dart replaces the stack, so on Android back exits '
          'the app instead. Push the tour (or handle PopScope in P02).',
    );

    await disposeApp(tester);
  });

  // ---------------------------------------------------------------------
  // P02-BUG-7 (MAJOR, fixed) — the longest card-1 title ellipsised at the
  // design width; the iteration-3 build fixed it with a FittedBox(scaleDown)
  // title slot. The former proof here was tautological (the FittedBox lays
  // the paragraph out unbounded, so intrinsic width == laid-out width; review
  // iteration 3, finding 2) and has been replaced by the effective-scale
  // proofs below. The 390dp "one line, no U+2026" requirement is verified on
  // the device shot by the UI stage (title ink 81.0→244.0, pill at 254).
  // ---------------------------------------------------------------------

  // ---------------------------------------------------------------------
  // P02-BUG-10 (MAJOR, OPEN) — the FittedBox shrink knows no lower bound: at
  // 320dp (and 390dp × text scale 1.3) the preview titles paint far below
  // their 15dp token size instead of wrapping (review iteration 3, finding 1;
  // DESIGN_SPEC §0 rules 4/9; ORCHESTRATOR_NOTES 3 second half).
  // ---------------------------------------------------------------------
  for (final spec in const <(String, Size, double)>[
    ('P02-BUG-10a', Size(320, 844), 1.0),
    ('P02-BUG-10b', Size(320, 844), 1.3),
    ('P02-BUG-10c', Size(390, 844), 1.3),
  ]) {
    testWidgets(
      '${spec.$1} preview titles do not paint below 0.9x at '
      '${spec.$2.width.toInt()}dp x ${spec.$3}',
      (tester) async {
        await setUpTestScope();
        await _pumpTour(tester, surface: spec.$2, textScale: spec.$3);

        for (final title in const <String>[
          'Empty the dishwasher',
          'Put the bins out',
          'Reading – 20 minutes',
          'Tidy your bedroom',
        ]) {
          final scale = _paintedTitleScale(tester, title);
          expect(
            scale,
            greaterThanOrEqualTo(0.9),
            reason:
                'the title slot must wrap (or ellipsise at full size) rather '
                "than scale the design's 15/600 type below 0.9x; measured "
                'scale ${scale.toStringAsFixed(2)} for "$title". On device '
                'the current scale is ~0.60 at 320dp and ~0.43 at 320x1.3 '
                '(review iteration 3 finding 1).',
          );
        }
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
      skip: true, // P02-BUG-10
    );
  }
}
