// P13 payout — geometry pins (`.pay` stack), real fonts.
//
// Every number is measured off `design/screens/light/P13-payout.png` ÷3 (the
// logical 390×844 surface) and asserted on the rendered RECT of the visible
// background/border, not on where a label lands:
//
//   .status-bar 47                                     → title box   55…89
//   .ptitle    padding-top 8, 28/34                   → card top   101
//   .card      16 pad + 18 caption                    → card 101…151
//   .pay::before margin 4 / 5 pill / margin 12        → h2 372…402
//   .pay h2    Nunito 24/30 w900                      → sub 406…426
//   .pay .sub  14/20, margin-top 4, spacer 14         → child1  440
//   .child     14 pad + 48 check + 14                 → child1 440…516
//   spacer 10                                          → child2  526…602
//   spacer 10                                          → saverow 612…684
//   spacer 14                                          → CTA    698…750
//   spacer 8 + caption 13/18 × 2                      → sheet  bottom 844
//
// Real fonts are loaded (the Ahem fallback the rest of the suite runs under
// cannot catch a metric drift, and the card heights depend on the text).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

import '../../test_scope.dart';

/// Design rects in logical pixels (`P13-payout.png` ÷3).
const Rect designChildRow1 = Rect.fromLTRB(20, 440, 370, 516);
const Rect designChildRow2 = Rect.fromLTRB(20, 526, 370, 602);
const Rect designSaveRow = Rect.fromLTRB(20, 612, 370, 684);
const Rect designCta = Rect.fromLTRB(20, 698, 370, 750);

/// Design sheet: bottom-anchored, 501 tall (844 − 343).
const double designSheetHeight = 501;

/// UI-verdict tolerance: ±2 px on every rendered rect.
const double tolerance = 2;

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

Future<void> _pumpPayout(WidgetTester tester) async {
  await setUpTestScope();
  await pumpAppRoute(tester, '/payout');
}

Finder _text(String value) => find.text(value);

/// The card whose copy is [text] — the shape, not the label.
Finder _cardOwning(String text) =>
    find.ancestor(of: _text(text), matching: find.byType(Container)).first;

void expectRectNear(Rect actual, Rect design) {
  expect(actual.left, closeTo(design.left, tolerance), reason: 'left');
  expect(actual.top, closeTo(design.top, tolerance), reason: 'top');
  expect(actual.right, closeTo(design.right, tolerance), reason: 'right');
  expect(actual.bottom, closeTo(design.bottom, tolerance), reason: 'bottom');
}

/// Every [TextSpan] in a rich line, however deeply nested.
List<TextSpan> _flatten(InlineSpan span) {
  if (span is! TextSpan) return const <TextSpan>[];
  return <TextSpan>[
    span,
    for (final child in span.children ?? const <InlineSpan>[])
      ..._flatten(child),
  ];
}

void main() {
  setUpAll(_loadBundledFonts);

  group('P13 payout — design geometry at 390×844 (real fonts)', () {
    testWidgets('the dimmed ledger keeps the P12 title + summary card', (
      tester,
    ) async {
      await _pumpPayout(tester);

      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        moreOrLessEquals(47, epsilon: 0.01),
      );
      expect(
        tester.getRect(_text('Pocket money')).top,
        closeTo(55, tolerance),
        reason: '.status-bar 47 + .ptitle padding-top 8',
      );
      final summary = _cardOwning('Maya is owed £4.20 · Leo is owed £2.10');
      expectRectNear(
        tester.getRect(summary),
        const Rect.fromLTRB(20, 101, 370, 151),
      );
      await disposeApp(tester);
    });

    testWidgets('the sheet is 501 tall and runs to the screen edge', (
      tester,
    ) async {
      await _pumpPayout(tester);

      final sheet = tester.getRect(
        find
            .descendant(
              of: find.byType(PayoutSheet),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(sheet.height, closeTo(designSheetHeight, tolerance));
      expect(
        sheet.bottom,
        closeTo(844, 0.01),
        reason:
            'owner bottom-edge rule: the sheet paper owns the last pixel '
            'row, so no coloured strip shows under the home indicator',
      );
      expect(sheet.left, closeTo(0, 0.01));
      expect(sheet.right, closeTo(390, 0.01));
      await disposeApp(tester);
    });

    testWidgets('the child rows are the design 76 px cards', (tester) async {
      await _pumpPayout(tester);

      expectRectNear(tester.getRect(_cardOwning('Maya')), designChildRow1);
      expectRectNear(tester.getRect(_cardOwning('Leo')), designChildRow2);
      await disposeApp(tester);
    });

    testWidgets('the saverow is the design 72 px card', (tester) async {
      await _pumpPayout(tester);

      expectRectNear(
        tester.getRect(_cardOwning("Move £1.00 of Maya's to her Lego fund")),
        designSaveRow,
      );
      await disposeApp(tester);
    });

    testWidgets('the CTA pill is the design 350×52 rect', (tester) async {
      await _pumpPayout(tester);

      final cta = find.text('Mark as paid & start the celebration');
      final pill = find
          .ancestor(of: cta, matching: find.byType(AnimatedContainer))
          .first;
      expectRectNear(tester.getRect(pill), designCta);
      await disposeApp(tester);
    });

    testWidgets('the check box is 48×48 and drives the row height', (
      tester,
    ) async {
      await _pumpPayout(tester);

      // The 24 px tick stays mounted in both states, so the NestIcon is
      // always present — find its painted 48 px box.
      final check = tester.getRect(
        find
            .ancestor(
              of: find.byType(NestIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(check.width, closeTo(48, 0.01));
      expect(check.height, closeTo(48, 0.01));
      await disposeApp(tester);
    });

    testWidgets('the avatar is 44 px inside the row gutter', (tester) async {
      await _pumpPayout(tester);

      final avatar = tester.getRect(
        find.ancestor(of: _text('M'), matching: find.byType(NestAvatar)),
      );
      expect(avatar.width, closeTo(44, 0.01));
      expect(avatar.height, closeTo(44, 0.01));
      expect(avatar.left, closeTo(34, tolerance));
      await disposeApp(tester);
    });

    // ORCHESTRATOR_NOTES (iteration 2) items 2 and 3: the row's amount is a
    // `<span class="money">` INSIDE the 13 px `.caption` line — 13 px bold
    // tabular `--ink-2`, inline after the middle dot — not the separate 18 px
    // number the page-level (unused) `.child .am` rule suggests.
    //
    // Measured off `P13-payout.png` ÷3 in row 1 (440…516):
    //   `.who` = name 22 + caption 18 = 40, centred in the 48 px content box
    //   (14 pad) → name line box 458…480, caption line box 480…498.
    //   Design ink: name #1E1B3A, caption AND amount both #4A4668 (= --ink-2).
    testWidgets('the row amount is inline 13 px bold ink-2, and the text '
        'sits where the design centres it', (tester) async {
      await _pumpPayout(tester);

      final line = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere(
            (rich) => rich.text.toPlainText() == 'Weekly + quests · £4.20',
          );
      expect(line.text.toPlainText(), 'Weekly + quests · £4.20');

      TextSpan spanWith(String text) =>
          _flatten(line.text).firstWhere((span) => span.text == text);
      final captionSpan = spanWith('Weekly + quests · ');
      final amountSpan = spanWith('£4.20');
      expect(captionSpan.style!.fontSize, 13, reason: '.caption is 13/18');
      expect(amountSpan.text, '£4.20', reason: 'DATA OVER MOCKS: owed');
      expect(
        amountSpan.style!.fontSize,
        13,
        reason: 'the amount is part of the 13 px caption line',
      );
      expect(amountSpan.style!.fontWeight, FontWeight.w700);
      expect(
        amountSpan.style!.color,
        NestTheme.light().extension<NestTokens>()!.ink2,
        reason: ".money sets no colour — it inherits the caption's --ink-2",
      );
      expect(
        amountSpan.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: '.money { font-variant-numeric: tabular-nums }',
      );

      // Text position, ±1 px of the design (name 458…480, subtitle 480…498).
      final name = tester.getRect(_text('Maya'));
      expect(name.top, closeTo(458, 1), reason: 'name line box');
      expect(name.height, closeTo(22, 0.01));
      final subtitle = tester.getRect(find.text('Weekly + quests · £4.20'));
      expect(subtitle.top, closeTo(480, 1), reason: 'caption line box');
      expect(subtitle.height, closeTo(18, 0.01));

      // Leo's block is the same, one row down (526…602).
      final leoName = tester.getRect(_text('Leo'));
      expect(leoName.top, closeTo(544, 1));
      final leoSubtitle = tester.getRect(find.text('Weekly + quests · £2.10'));
      expect(leoSubtitle.top, closeTo(566, 1));

      await disposeApp(tester);
    });

    // ORCHESTRATOR_NOTES item 1: `.scrim { position: absolute; inset: 0 }`
    // covers (0,0) → (390,844) — the status-bar reserve, the "Pocket money"
    // title and the summary card all render dimmed, and the whole band above
    // the sheet is the dismiss target.
    testWidgets('the scrim barrier covers the whole screen from (0,0)', (
      tester,
    ) async {
      await _pumpPayout(tester);

      final scrim = find.byWidgetPredicate((widget) {
        final color = NestTheme.light().extension<NestTokens>()!.scrim;
        if (widget is ColoredBox) return widget.color == color;
        if (widget is DecoratedBox) {
          final decoration = widget.decoration;
          return decoration is BoxDecoration && decoration.color == color;
        }
        return false;
      });
      expect(scrim, findsOneWidget);
      expect(
        tester.getRect(scrim),
        const Rect.fromLTRB(0, 0, 390, 844),
        reason: 'design inset: 0 — no bright band above the sheet',
      );

      await disposeApp(tester);
    });
  });
}
