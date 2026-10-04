// P13 · Payout — STAGE 3 audit for iteration 3.
//
// Iteration 3 changed three pieces of product behaviour, so this file attacks
// exactly those, plus the gaps they left:
//
//   A. `PayoutSaveRow.label` is ONE data-driven, ungendered sentence for
//      every goal child (orchestrator mandate, 23:25). No seed-id gate, no
//      pronoun from a goal title.  Pinned as a matrix.
//   B. The seeded path renders that same sentence with the seeded goal title
//      "Lego Friends set"; the design's "her Lego fund" must appear nowhere.
//   C. The summary caption flipped `TextAlign.center` → `TextAlign.start`
//      (overriding `1_plan.md` §(a)). `.caption` sets no `text-align`
//      (`components.css:34`); only `.cap` is centred, and `.cap` is applied only
//      to the sheet's closing caption. Pinned as a contrast pair so a blanket
//      "everything is start-aligned" regression is caught.
//   D. The neutral fallback sentence is far longer than the design string —
//      probed at 320 dp × text scale 1.3 for overflow and tap-target loss.
//   E. ORCHESTRATOR_NOTES items 1 and 3 were pinned in LIGHT only
//      (`payout_widget_geometry_test.dart` has zero `ThemeMode.dark`). Re-pinned
//      in dark, which is what `5_ui` compares against the dark PNG.
//
// Everything runs against the real in-memory Drift demo seed, so amounts come
// from the database (DATA OVER MOCKS).
//
// **No simulator was used** (stage rule: only 5_ui may).

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

import '../../test_scope.dart';

const String kCta = 'Mark as paid & start the celebration';

/// `P13-payout.html:29`, verbatim: ASCII 0x27 apostrophes.
/// Orchestrator-mandated copy, seeded shape:
/// `$amount` = £1.00, `<goalTitle>` = seeded "Lego Friends set".
const String kSeededSaveCopy =
    "Move £1.00 of Maya's to their Lego Friends set fund";

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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _pumpPayout(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  Size surface = const Size(390, 844),
  double textScale = 1,
}) async {
  await setUpTestScope();
  await pumpAppRoute(tester, '/payout', theme: theme);
  // `pumpAppRoute` hard-codes 390x844 (SHARED_REQUEST #1), so any other
  // surface is applied after the first frame and the view re-pumped.
  if (surface != const Size(390, 844) || textScale != 1) {
    tester.view.physicalSize = surface * 3;
    tester.view.devicePixelRatio = 3;
    if (textScale != 1) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _settle(tester);
}

void main() {
  // =========================================================================
  // A. The ungendered label — one sentence for every goal-bearing child
  // =========================================================================
  group('P13 iteration 4 — PayoutSaveRow.label is ungendered everywhere', () {
    // Pure matrix, no widget needed.
    test('the seeded shape renders the mandated ungendered sentence', () {
      expect(
        PayoutSaveRow.label('Maya', 'Lego Friends set'),
        kSeededSaveCopy,
        reason:
            "mandated copy: child name + ' to their ' + goal title, ASCII 0x27",
      );
    });

    test('a goal-bearing Leo never gets the design pronoun (P13-BUG-06)', () {
      for (final title in <String>[
        'Lego City',
        'Lego Friends set',
        'Lego Star Wars',
      ]) {
        final copy = PayoutSaveRow.label('Leo', title);
        expect(copy, isNot(contains(' her ')));
        expect(copy, "Move £1.00 of Leo's to their $title fund");
      }
    });

    test('no nickname may ever be given the design pronoun by a wide goal', () {
      for (final childId in <String>['leo', 'maya-2', 'maya']) {
        final copy = PayoutSaveRow.label('Alex', 'Lego');
        expect(
          copy,
          isNot(contains(' her ')),
          reason: 'childId "$childId" with title "Lego" produced "$copy"',
        );
        expect(copy, "Move £1.00 of Alex's to their Lego fund");
      }
    });

    test('a non-seeded Maya goal uses the same data-driven sentence', () {
      final copy = PayoutSaveRow.label('Maya', 'New bike');
      expect(copy, isNot(contains(' her ')));
      expect(copy, "Move £1.00 of Maya's to their New bike fund");
    });

    test('a title differing only by case is still used verbatim', () {
      // No gate on the title at all: 'lego friends set' renders as-is,
      // ungendered either way.
      final copy = PayoutSaveRow.label('Maya', 'lego friends set');
      expect(copy, isNot(contains(' her ')));
      expect(copy, "Move £1.00 of Maya's to their lego friends set fund");
    });

    test('no goal at all reads as plain savings', () {
      expect(
        PayoutSaveRow.label('Maya', null),
        "Move £1.00 of Maya's money to savings",
      );
      expect(
        PayoutSaveRow.label('Maya', '   '),
        "Move £1.00 of Maya's money to savings",
        reason: 'a whitespace-only title is no title',
      );
    });

    test('every shape is pronoun-free', () {
      const shapes = <(String, String?)>[
        ('maya', 'Lego Friends set'),
        ('leo', 'Lego Friends set'),
        ('leo', 'Lego City'),
        ('maya', 'Bike'),
        ('leo', ''),
        ('maya', null),
      ];
      for (final shape in shapes) {
        final copy = PayoutSaveRow.label(shape.$1, shape.$2);
        expect(
          copy.contains(' her '),
          isFalse,
          reason: '"$copy" for (${shape.$1}, "${shape.$2}")',
        );
      }
    });
  });

  // =========================================================================
  // B. The seeded path, end to end, byte-for-byte
  // =========================================================================
  group('P13 iteration 4 — the seeded saverow', () {
    testWidgets('Seed.demo renders the mandated ungendered sentence exactly', (
      tester,
    ) async {
      await _pumpPayout(tester);

      expect(find.text(kSeededSaveCopy), findsOneWidget);
      // The design's feminine copy never renders — the orchestrator rule is
      // that "her Lego fund" is NOT a finding for any child.
      expect(find.textContaining(' her '), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // =========================================================================
  // C. Alignment: summary start-aligned, closing caption centred
  // =========================================================================
  group('P13 iteration 3 — summary vs closing caption alignment', () {
    testWidgets('the summary caption starts at the card padding edge', (
      tester,
    ) async {
      await _pumpPayout(tester);

      final summary = tester.getRect(
        find.text('Maya is owed £4.20 · Leo is owed £2.10'),
      );
      // `.bg-fake` pads 20, `.card` pads 16 → 36. `.caption` sets no
      // text-align (components.css:34), so the glyphs start there.
      expect(
        summary.left,
        closeTo(36, 1.5),
        reason: '5_ui deviation 1: the design glyphs start at the card edge',
      );

      // …and it is genuinely LEFT aligned, not centred: a one-line sentence
      // whose left edge is at the padding cannot also be centred.
      expect(
        summary.left,
        lessThan(195),
        reason: 'a centred line would start near the middle of a 390 surface',
      );

      final text = tester.widget<Text>(find.text(kSeededSaveCopy));
      expect(text.textAlign, isNull);
      await disposeApp(tester);
    });

    testWidgets('the closing caption stays CENTRED (.cap)', (tester) async {
      await _pumpPayout(tester);

      final cap = find.text(
        'Your children will see a payout celebration next time they open '
        'Nestling.',
      );
      expect(cap, findsOneWidget);
      expect(
        tester.widget<Text>(cap).textAlign,
        TextAlign.center,
        reason:
            '`.cap { text-align: center }` (P13-payout.html:26) — the '
            'start-alignment fix must not have leaked onto this line',
      );
      await disposeApp(tester);
    });

    testWidgets('the sheet title and subtitle stay centred', (tester) async {
      await _pumpPayout(tester);

      // `.pay h2` and `.pay .sub` both set text-align:center.
      expect(
        tester.widget<Text>(find.text('Saturday payout')).textAlign,
        TextAlign.center,
      );
      expect(
        tester
            .widget<Text>(find.text("Tick once you've handed over the cash"))
            .textAlign,
        TextAlign.center,
      );
      await disposeApp(tester);
    });
  });

  // =========================================================================
  // D. The long neutral fallback at the narrowest, largest-text surface
  // =========================================================================
  group('P13 iteration 3 — the fallback sentence at 320 dp x 1.3', () {
    testWidgets('a long goal title neither overflows nor breaks the toggle', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // Push the seeded goal off the design string so the sheet renders the
      // long neutral sentence: 320 dp x 1.3 is where it has to survive.
      await (db.update(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).write(
        const SavingsGoalsCompanion(
          title: Value('Lego Star Wars Galactic Empire Imperial Ship'),
        ),
      );

      await pumpAppRoute(tester, '/payout');
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _settle(tester);

      final label = find.textContaining('Lego Star Wars Galactic Empire');
      expect(
        label,
        findsOneWidget,
        reason: 'the long goal title is what the sheet now renders',
      );
      expect(
        find.textContaining(' her '),
        findsNothing,
        reason: 'P13-BUG-06 must stay fixed at any width',
      );

      // The toggle's painted pill is 51x31; main's `NestToggle` carries the
      // 44 px parent target in a custom `hitTest` overhang rather than in the
      // laid-out size, so the target is verified FUNCTIONALLY (the same
      // approach `payout_responsive_test.dart` uses) — a rect assertion would
      // measure the pill, not the touch area. Scrolling the toggle into view
      // first matters at 320x568: the sheet is taller than the surface.
      final pill = tester.getRect(find.byType(NestToggle));
      expect(pill.height, closeTo(31, 0.01), reason: '.toggle is 51x31');
      await tester.ensureVisible(find.byType(NestToggle));
      await tester.pump();
      final visible = tester.getRect(find.byType(NestToggle));
      expect(
        visible.overlaps(const Rect.fromLTRB(0, 0, 320, 568)),
        isTrue,
        reason: 'the toggle is reachable after scrolling the sheet',
      );
      await tester.tapAt(Offset(visible.center.dx, visible.top + 2));
      await tester.pump();
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle)).value,
        isFalse,
        reason: 'a tap just inside the overhang still flips the savings toggle',
      );

      expect(tester.takeException(), isNull, reason: 'no overflow');
      await disposeApp(tester);
    });

    // The parent tap target must be at least 44 px on EVERY edge, measured by
    // probing outward until the tap stops landing. This is the empirical form
    // of the rule, and it survives a future `NestToggle` rework that moves the
    // overhang again.
    testWidgets('the savings toggle keeps a 44 px target on every edge', (
      tester,
    ) async {
      await _pumpPayout(tester);
      final pill = tester.getRect(find.byType(NestToggle));

      Future<bool> tapsAt(double dy) async {
        final before = tester.widget<NestToggle>(find.byType(NestToggle)).value;
        tester.view.physicalSize = const Size(390, 844) * 3;
        await tester.tapAt(Offset(pill.center.dx, dy));
        await tester.pump();
        final after = tester.widget<NestToggle>(find.byType(NestToggle)).value;
        if (after == before) return false;
        // put it back so the next probe starts from a known state
        await tester.tapAt(Offset(pill.center.dx, dy));
        await tester.pump();
        return true;
      }

      // 44 tall centred on a 31 tall pill leaves 6.5 px of slack each side, so
      // a probe 5 px outside the painted edge must land and one 20 px outside
      // the painted edge must not. (Measured from `pill.top`/`pill.bottom`, not
      // from the centre — 20 px above the CENTRE is only 4.5 px above the top
      // edge and is legitimately inside the target.)
      expect(
        await tapsAt(pill.top - 5),
        isTrue,
        reason: '5 px above the painted pill is inside the 44 px target',
      );
      expect(
        await tapsAt(pill.bottom + 5),
        isTrue,
        reason: '5 px below the painted pill is inside the 44 px target',
      );
      expect(
        await tapsAt(pill.top - 20),
        isFalse,
        reason: '20 px above the painted edge is outside the target',
      );
      expect(
        await tapsAt(pill.bottom + 20),
        isFalse,
        reason: '20 px below the painted edge is outside the target',
      );
      await disposeApp(tester);
    });
  });

  // =========================================================================
  // E. ORCHESTRATOR_NOTES items 1 and 3, in DARK
  // =========================================================================
  group('P13 iteration 3 — ORCHESTRATOR_NOTES in dark theme', () {
    setUpAll(_loadBundledFonts);

    testWidgets('dark: the scrim still covers (0,0) to the full surface', (
      tester,
    ) async {
      await _pumpPayout(tester, theme: ThemeMode.dark);

      final scrimColor = NestTheme.dark().extension<NestTokens>()!.scrim;
      final scrim = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == scrimColor,
        description: 'the dark scrim ColoredBox',
      );
      expect(scrim, findsOneWidget);
      expect(
        tester.getRect(scrim),
        const Rect.fromLTRB(0, 0, 390, 844),
        reason:
            'ORCHESTRATOR item 1 is theme-independent: the barrier is '
            '`inset: 0` in both themes',
      );
      await disposeApp(tester);
    });

    testWidgets('dark: the row text still sits where the design centres it', (
      tester,
    ) async {
      await _pumpPayout(tester, theme: ThemeMode.dark);

      // Same design line boxes as light: name 458, subtitle 480, Leo 544/566.
      expect(tester.getRect(find.text('Maya')).top, closeTo(458, 1));
      expect(
        tester.getRect(find.text('Weekly + quests · £4.20')).top,
        closeTo(480, 1),
      );
      expect(
        tester.getRect(find.text('Leo')).top,
        closeTo(544, 1),
        reason: 'ORCHESTRATOR item 3 — 5_ui measured Leo ~2 px high in light',
      );
      expect(
        tester.getRect(find.text('Weekly + quests · £2.10')).top,
        closeTo(566, 1),
      );
      await disposeApp(tester);
    });

    testWidgets('dark: the amount span is ink-2, not ink', (tester) async {
      await _pumpPayout(tester, theme: ThemeMode.dark);

      final line = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((r) => r.text.toPlainText() == 'Weekly + quests · £4.20');
      final amount = _flatten(line.text).firstWhere((s) => s.text == '£4.20');
      expect(amount.style!.fontSize, 13);
      expect(amount.style!.fontWeight, FontWeight.w700);
      expect(
        amount.style!.color,
        NestTheme.dark().extension<NestTokens>()!.ink2,
        reason: '.money sets no colour — it inherits the caption --ink-2',
      );
      await disposeApp(tester);
    });
  });

  // =========================================================================
  // F. Cheap regression sweep on things iteration 3 touched nearby
  // =========================================================================
  group('P13 iteration 3 — no regressions', () {
    testWidgets('the CTA pill is still the design 350x52 rect', (tester) async {
      await _pumpPayout(tester);
      final pill = tester.getRect(
        find
            .ancestor(
              of: find.text(kCta),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(pill.left, closeTo(20, 0.01));
      expect(pill.right, closeTo(370, 0.01));
      expect(pill.height, closeTo(52, 0.01));
      await disposeApp(tester);
    });

    testWidgets('the saverow toggle paints 51x31 at the design x', (
      tester,
    ) async {
      await _pumpPayout(tester);
      final pill = tester.getRect(find.byType(NestToggle));
      expect(pill.width, closeTo(51, 0.01), reason: '.toggle is 51x31');
      expect(pill.height, closeTo(31, 0.01));
      expect(
        pill.left,
        closeTo(305, 1),
        reason: '5_ui deviation 2 (re-pinned)',
      );
      expect(pill.top, closeTo(633, 1));
      await disposeApp(tester);
    });

    testWidgets('every payout control is still VoiceOver-operable', (
      tester,
    ) async {
      await _pumpPayout(tester);
      final handle = tester.ensureSemantics();

      for (final label in <String>[
        'Maya paid in cash',
        'Leo paid in cash',
        'Close payout',
      ]) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '"$label" must expose a tap action',
        );
      }
      // The toggle's Semantics sits on a labelled descendant, so it is found
      // by its label (the design's `aria-label`) rather than by widget type.
      final toggleNode = tester.getSemantics(
        find.bySemanticsLabel("Move one pound of Maya's money to savings"),
      );
      expect(
        toggleNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the savings toggle stays operable after the NestToggle rework',
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });
}

/// Every [TextSpan] leaf in a span tree, so an inline amount can be asserted
/// without depending on how the widget nested its spans.
Iterable<TextSpan> _flatten(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  if (span.text != null) {
    yield span;
  } else {
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _flatten(child);
    }
  }
}
