// P11 · Approvals — real-font layout anchors.
//
// The UI VERDICT RULE measures the screen against
// `design/screens/{light,dark}/P11-approvals.png` (±2 px, no uniform vertical
// shift). These tests pin the SAME anchors in code, at 390×844 @3x, with the
// bundled Inter/Nunito faces loaded through `FontLoader` — without the real
// faces the test fallback font is ~10% wider and every wrapped line shifts the
// cards down (the helper copy alone goes 2 lines → 3), which is exactly the
// uniform-shift failure the rule forbids. Pattern copied from P10's
// `p10_bugs_test.dart` geometry proofs.
//
// Design values come from the P11 box model (measured off the PNG row/column
// profile: banner 107–171, cards 187/341/495, gutters 20/370) and from
// `1_plan.md` §1 "Expected-y positions".
//
// Deliberate deviation, pinned so nobody "fixes" it: the design's
// `.bottom-cta` ends 34 px above the physical edge (the home-indicator strip
// is paper) so its button sits at 734–786; `NestBottomCta` runs the surface to
// the edge per the OWNER bottom-edge rule, which moves the button to 776–828
// (always 16 above the physical bottom). Both are asserted below.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_loaded_body.dart';

import '../../test_scope.dart';

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

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

/// Design-measured value ±2 px (UI VERDICT RULE tolerance).
Matcher _near(double expected) => closeTo(expected, 2);

void main() {
  setUpAll(_loadBundledFonts);
  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pump(WidgetTester tester) => pumpAppRoute(tester, '/approvals');

  group('P11 layout anchors match the design (390×844)', () {
    testWidgets('status bar reserve, compact nav bar and title', (
      tester,
    ) async {
      await pump(tester);

      // `NestStatusBar` reserves 47; the OS draws the glyphs (ignored by the
      // STATUS BAR rule).
      expect(tester.getRect(find.byType(NestStatusBar)).height, _near(47));
      // `.nav-bar.compact`: padding 4/12/12 around the 44 back button.
      final nav = tester.getRect(find.byType(NestNavBar));
      expect(nav.top, _near(47));
      expect(nav.bottom, _near(107));
      expect(nav.left, 0);
      expect(nav.right, NestDevice.width);

      // `.nav-bar.compact .nav-title` — Nunito 18/24 w800, centred, 24 high.
      final title = tester.getRect(find.text('Waiting for you (3)'));
      expect(title.top, _near(61));
      expect(title.height, _near(24));
      expect(title.center.dx, _near(195));

      await disposeApp(tester);
    });

    testWidgets('helper banner is 107–171, 20 gutters, radius 16', (
      tester,
    ) async {
      await pump(tester);

      final banner = tester.getRect(find.byType(ApprovalsHelperBanner));
      expect(banner.top, _near(107));
      expect(banner.height, _near(64));
      expect(banner.left, _near(NestSpacing.padSide));
      expect(banner.right, _near(NestDevice.width - NestSpacing.padSide));
      // Two 20-high lines inside 12/14 padding: 12 + 2×20 + 12 = 64. A third
      // line would silently push every card down 20 px.
      expect(tester.getRect(find.text(approvalsHelperCopy)).height, _near(40));

      await disposeApp(tester);
    });

    testWidgets('card tops 187 / 341 / 495, each 138 high, 16 apart', (
      tester,
    ) async {
      await pump(tester);

      final cards = <String>[
        'Maya · Empty the dishwasher',
        'Maya · Lay the table',
        'Leo · Make your bed',
      ];
      const expectedTops = <double>[187, 341, 495];
      for (var i = 0; i < cards.length; i++) {
        final rect = tester.getRect(_cardFor(cards[i]));
        expect(rect.top, _near(expectedTops[i]), reason: cards[i]);
        expect(rect.height, _near(138), reason: cards[i]);
        // `.scroll` padding 0 20px, `.appr` fills the width.
        expect(rect.left, _near(NestSpacing.padSide), reason: cards[i]);
        expect(rect.right, _near(NestDevice.width - NestSpacing.padSide));
        if (i > 0) {
          final previous = tester.getRect(_cardFor(cards[i - 1]));
          expect(rect.top - previous.bottom, _near(NestSpacing.s4));
        }
      }

      await disposeApp(tester);
    });

    testWidgets('card internals: 44 avatar at x 36, row buttons 48 at x 36', (
      tester,
    ) async {
      await pump(tester);
      final card = tester.getRect(_cardFor('Maya · Empty the dishwasher'));

      // `.hd` — avatar 44 square, 16 px card padding, 10 px gap.
      final avatar = tester.getRect(find.byType(NestAvatar).first);
      expect(avatar.size, const Size(44, 44));
      expect(avatar.left, card.left + NestSpacing.s4);
      expect(avatar.top, card.top + NestSpacing.s4);
      // `.who` — 16/22 w700, two px below the avatar's top edge (the text
      // block is 42 high inside the 44 avatar row).
      final who = tester.getRect(find.text('Maya · Empty the dishwasher'));
      expect(who.left, avatar.right + NestSpacing.gap10);
      expect(who.height, _near(22));
      expect(who.top, _near(card.top + 17));

      // `.appr .row` — 14 below `.hd`, 48-high pills, 10 apart, card padding 16.
      final notYet = tester.getRect(
        find.byKey(const ValueKey<String>('p11_not_yet_1')),
      );
      final approve = tester.getRect(
        find.byKey(const ValueKey<String>('p11_approve_1')),
      );
      expect(notYet.top, _near(card.top + 74));
      expect(notYet.height, _near(48));
      expect(notYet.left, card.left + NestSpacing.s4);
      expect(approve.top, notYet.top);
      expect(approve.left - notYet.right, _near(NestSpacing.gap10));
      expect(approve.width, _near(notYet.width));
      // The row ends 16 px above the card's bottom edge.
      expect(card.bottom - approve.bottom, _near(NestSpacing.s4));

      await disposeApp(tester);
    });

    testWidgets('bottom CTA: 52-high pill, 20 gutters, surface to the edge', (
      tester,
    ) async {
      await pump(tester);

      final cta = tester.getRect(find.byType(NestBottomCta));
      final screen = tester.getRect(find.byType(Scaffold).first);
      final button = tester.getRect(
        find.byKey(const ValueKey<String>('p11_approve_all')),
      );
      // `.bottom-cta .btn { min-height: 52 }`; the button always sits 16 px
      // above the PHYSICAL bottom (surface runs to the edge — OWNER rule;
      // the design's paper strip below 809 would put it at 734–786).
      expect(button.height, _near(52));
      expect(screen.bottom - button.bottom, _near(NestSpacing.s4));
      expect(button.left, _near(NestSpacing.padSide));
      expect(button.right, _near(NestDevice.width - NestSpacing.padSide));
      expect(cta.bottom, screen.bottom);
      expect(cta.left, screen.left);
      expect(cta.right, screen.right);

      await disposeApp(tester);
    });

    testWidgets('everything stays on the 20 px gutter grid', (tester) async {
      await pump(tester);

      final lefts = <double>[
        tester.getRect(find.byType(ApprovalsHelperBanner)).left,
        for (final who in <String>[
          'Maya · Empty the dishwasher',
          'Maya · Lay the table',
          'Leo · Make your bed',
        ])
          tester.getRect(_cardFor(who)).left,
        tester
            .getRect(find.byKey(const ValueKey<String>('p11_approve_all')))
            .left,
      ];
      final rights = <double>[
        tester.getRect(find.byType(ApprovalsHelperBanner)).right,
        for (final who in <String>[
          'Maya · Empty the dishwasher',
          'Maya · Lay the table',
          'Leo · Make your bed',
        ])
          tester.getRect(_cardFor(who)).right,
        tester
            .getRect(find.byKey(const ValueKey<String>('p11_approve_all')))
            .right,
      ];
      for (final edge in <double>[...lefts, ...rights]) {
        expect(
          edge == NestSpacing.padSide ||
              edge == NestDevice.width - NestSpacing.padSide,
          isTrue,
          reason: 'edge $edge',
        );
      }

      await disposeApp(tester);
    });
  });

  group('P11 layout anchors hold in dark mode', () {
    testWidgets('same anchors with dark tokens', (tester) async {
      await pumpAppRoute(tester, '/approvals', theme: ThemeMode.dark);

      expect(
        tester.getRect(find.byType(ApprovalsHelperBanner)).top,
        _near(107),
      );
      expect(tester.getRect(find.text(approvalsHelperCopy)).height, _near(40));
      expect(
        tester.getRect(_cardFor('Maya · Empty the dishwasher')).top,
        _near(187),
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('p11_approve_all')))
            .height,
        _near(52),
      );

      await disposeApp(tester);
    });
  });
}
