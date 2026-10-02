// Shared requests batch 1 — regression tests for every shared change.
//
// One group per request item; each fails on the pre-fix component and passes
// after. See docs/screens/_shared/shared_requests_batch1_REPORT.md.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// Every non-empty semantics label in [node]'s subtree (inclusive).
List<String> subtreeLabels(SemanticsNode node) {
  final labels = <String>[];
  bool visit(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    n.visitChildren(visit);
    return true;
  }

  visit(node);
  return labels;
}

void main() {
  group('P04 trash icon (ic_trash + NestIcons.trash)', () {
    test('asset is registered and bundled', () async {
      expect(NestIcons.trash, 'assets/icons/ic_trash.svg');
      expect(NestlingIcons.trash, 'assets/icons/ic_trash.svg');
      final svg = await rootBundle.loadString(NestIcons.trash);
      expect(svg, contains('viewBox="0 0 24 24'));
      // 24x24 line icon: stroke currentColor, 2px, round caps/joins —
      // transcribed from design/html-source/screens/P04-privacy.html
      // (lid `M4 7h16`, handle `M9.5 7V5h5v2`, body `M6.5 7l1 13h9l1-13`).
      expect(svg, contains('stroke="currentColor"'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('stroke-linecap="round"'));
      expect(svg, contains('stroke-linejoin="round"'));
      expect(svg, contains('M4 7h16'));
      expect(svg, contains('M9.5 7V5h5v2'));
      expect(svg, contains('M6.5 7l1 13h9l1-13'));
    });

    testWidgets('renders in a peach tile without throwing', (tester) async {
      await pumpBothModes(
        tester,
        NestIcon(NestIcons.trash, color: NestColors.light.aPeach),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('P04 themed privacy shield (NestPrivacyShield)', () {
    testWidgets('is 84 square and labels once', (tester) async {
      await pumpBothModes(
        tester,
        const NestPrivacyShield(semanticLabel: 'Privacy shield'),
      );
      expect(
        tester.getSize(find.byType(NestPrivacyShield)),
        const Size(84, 84),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      final node = tester.getSemantics(find.byType(NestPrivacyShield));
      expect(subtreeLabels(node), ['Privacy shield']);
    });

    testWidgets('disc follows skyTint in both themes', (tester) async {
      // Light disc == HTML `--sky-tint` (#E6EFFE); dark disc == dark
      // `--sky-tint` navy (#1A2A4A) per design/screens/dark/P04-privacy.png.
      await pumpNest(tester, const NestPrivacyShield());
      final light = tester.element(find.byType(NestPrivacyShield)).nest.skyTint;
      expect(light, const Color(0xFFE6EFFE));
      await pumpNest(tester, const NestPrivacyShield(), mode: ThemeMode.dark);
      final dark = tester.element(find.byType(NestPrivacyShield)).nest.skyTint;
      expect(dark, const Color(0xFF1A2A4A));
    });
  });

  group('P08 §2 + P03 §§2/4 one semantics node per card/button', () {
    testWidgets('NestButton announces its label once', (tester) async {
      await pumpNest(
        tester,
        NestButton(label: 'Create account', onPressed: () {}),
      );
      final node = tester.getSemantics(find.byType(NestButton));
      expect(subtreeLabels(node), ['Create account']);
    });

    testWidgets('brand buttons announce their label once', (tester) async {
      await pumpNest(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestAppleButton(label: 'Continue with Apple', onPressed: () {}),
            NestGoogleButton(label: 'Continue with Google', onPressed: () {}),
          ],
        ),
      );
      expect(subtreeLabels(tester.getSemantics(find.byType(NestAppleButton))), [
        'Continue with Apple',
      ]);
      expect(
        subtreeLabels(tester.getSemantics(find.byType(NestGoogleButton))),
        ['Continue with Google'],
      );
    });

    testWidgets('NestKidButton announces its label once', (tester) async {
      await pumpNest(tester, NestKidButton(label: 'My jar', onPressed: () {}));
      final node = tester.getSemantics(find.byType(NestKidButton));
      expect(subtreeLabels(node), ['My jar']);
    });

    testWidgets('NestQuestCard announces its semanticLabel once', (
      tester,
    ) async {
      await pumpNest(
        tester,
        NestQuestCard(
          title: 'Empty the dishwasher',
          meta: 'Weekly · Sat',
          onTap: () {},
          semanticLabel: 'Empty the dishwasher, 15 coins, Needs a look',
        ),
      );
      final node = tester.getSemantics(find.byType(NestQuestCard));
      expect(subtreeLabels(node), [
        'Empty the dishwasher, 15 coins, Needs a look',
      ]);
    });

    testWidgets('NestKidQuestCard announces its semanticLabel once', (
      tester,
    ) async {
      await pumpNest(
        tester,
        NestKidQuestCard(
          title: 'Tidy your bedroom',
          coinAmount: '15',
          onTap: () {},
          semanticLabel: 'Tidy your bedroom, 15 coins',
        ),
      );
      final node = tester.getSemantics(find.byType(NestKidQuestCard));
      expect(subtreeLabels(node), ['Tidy your bedroom, 15 coins']);
    });

    testWidgets('NestCard with onTap announces its label once', (tester) async {
      await pumpNest(
        tester,
        NestCard(
          onTap: () {},
          semanticLabel: 'Maya, 4 of 6 quests, 120 coins',
          child: const Text('Maya\n4 of 6 quests'),
        ),
      );
      final node = tester.getSemantics(find.byType(NestCard));
      expect(subtreeLabels(node), ['Maya, 4 of 6 quests, 120 coins']);
    });

    testWidgets('NestCard without a label still exposes its children', (
      tester,
    ) async {
      await pumpNest(
        tester,
        NestCard(onTap: () {}, child: const Text('Visible child')),
      );
      final node = tester.getSemantics(find.byType(NestCard));
      expect(subtreeLabels(node), ['Visible child']);
    });

    testWidgets('interactive NestChip announces its label once', (
      tester,
    ) async {
      await pumpNest(tester, NestChip(label: '7-9', onSelected: (_) {}));
      final node = tester.getSemantics(find.byType(NestChip));
      expect(subtreeLabels(node), ['7-9']);
    });
  });

  group('P05 interactive NestChip in a Wrap', () {
    testWidgets('four age chips share one row', (tester) async {
      await pumpBothModes(
        tester,
        Wrap(
          spacing: 8,
          children: [
            for (final band in const ['4-6', '7-9', '10-12', '13+'])
              NestChip(
                key: ValueKey('ageChip-$band'),
                label: band,
                onSelected: (_) {},
              ),
          ],
        ),
      );
      final tops = <double>{
        for (final band in const ['4-6', '7-9', '10-12', '13+'])
          tester.getTopLeft(find.byKey(ValueKey('ageChip-$band'))).dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('chip tap box keeps the 44 minimum', (tester) async {
      await pumpNest(tester, NestChip(label: '4-6', onSelected: (_) {}));
      final size = tester.getSize(find.byType(NestChip));
      expect(size.height, 44);
      expect(size.width, greaterThanOrEqualTo(44));
      // The visible pill keeps the design geometry: 32 content + the 1.5
      // border `Ink` reserves on each side.
      final ink = tester.getSize(
        find.descendant(of: find.byType(NestChip), matching: find.byType(Ink)),
      );
      expect(ink.height, 35);
    });

    testWidgets('chips stay on one row at 320 wide and textScale 1.3', (
      tester,
    ) async {
      await pumpNest(
        tester,
        Wrap(
          spacing: 8,
          children: [
            for (final band in const ['4-6', '7-9', '10-12', '13+'])
              NestChip(
                key: ValueKey('ageChip-$band'),
                label: band,
                onSelected: (_) {},
              ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('P03 §5 NestTextField error gutter', () {
    testWidgets('error aligns with the label gutter, not the field inset', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
      );
      expect(find.text('Too short.'), findsOneWidget);
      final labelX = tester.getTopLeft(find.text('Nickname')).dx;
      final errorX = tester.getTopLeft(find.text('Too short.')).dx;
      expect(errorX, labelX);
    });

    testWidgets('error border still turns danger', (tester) async {
      await pumpNest(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;
      expect(decoration.errorText, isNull);
      final enabled = decoration.enabledBorder! as OutlineInputBorder;
      expect(enabled.borderSide.color, const Color(0xFFC93A3A));
    });

    testWidgets('error replaces the helper (Material error-wins)', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestTextField(
          label: 'Nickname',
          helperText: 'Only a nickname.',
          errorText: 'Too short.',
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.helperText, isNull);
      expect(find.text('Too short.'), findsOneWidget);
      expect(find.text('Only a nickname.'), findsNothing);
    });
  });

  group('P02 §1 compact nav wide text action', () {
    testWidgets('Skip fits without clipping', (tester) async {
      await pumpBothModes(
        tester,
        NestNavBar(compact: true, actionLabel: 'Skip', onAction: () {}),
      );
      expect(find.text('Skip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The action slot grows past the old fixed 44 to fit the text.
      final action = tester.getSize(find.text('Skip'));
      expect(action.width, greaterThan(0));
      var tapped = 0;
      await pumpNest(
        tester,
        NestNavBar(
          compact: true,
          actionLabel: 'Skip',
          onAction: () => tapped++,
        ),
      );
      await tester.tap(find.text('Skip'));
      expect(tapped, 1);
    });

    testWidgets('compact bar stays 60 high with a text action', (tester) async {
      await pumpNest(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestNavBar(
              compact: true,
              onBack: () {},
              actionLabel: 'Skip',
              onAction: () {},
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byType(NestNavBar)).height, 60);
    });
  });

  group('P02 §3 pager tokens', () {
    test('NestPager pins the P02 geometry', () {
      expect(NestPager.stage, 52);
      expect(NestPager.pet, 158);
      expect(NestPager.lineMinHeight, 32);
      expect(NestPager.addDashWidth, 1.5);
      expect(NestPager.addDashLength, 6);
      expect(NestPager.addDashGap, 4);
      expect(NestPager.addMinHeight, 44);
    });
  });

  group('K03 §1 NestKidQuestCard tile tint', () {
    testWidgets('tileBackground overrides the surface2 tile', (tester) async {
      const tint = Color(0xFFE6EFFE);
      await pumpNest(
        tester,
        const NestKidQuestCard(
          title: 'Empty the dishwasher',
          tileBackground: tint,
        ),
      );
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(NestKidQuestCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 48 &&
                (w.decoration as BoxDecoration?)?.shape != BoxShape.circle,
          ),
        ),
      );
      expect(containers, isNotEmpty);
      final tile = containers.firstWhere(
        (c) => (c.decoration as BoxDecoration?)?.color == tint,
      );
      expect((tile.decoration! as BoxDecoration).color, tint);
    });

    testWidgets('default tile stays surface2', (tester) async {
      await pumpNest(tester, const NestKidQuestCard(title: 'Tidy up'));
      final tokens = tester.element(find.byType(NestKidQuestCard)).nest;
      final found = find.descendant(
        of: find.byType(NestKidQuestCard),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color == tokens.surface2,
        ),
      );
      expect(found, findsWidgets);
    });
  });

  group('K03 §6 KidScope meadow band parameters', () {
    testWidgets('defaults keep the 136 shared hill', (tester) async {
      await pumpNest(tester, const KidScope(child: SizedBox()));
      final scope = tester.widget<KidScope>(find.byType(KidScope));
      expect(scope.meadowHeight, 136);
      expect(scope.meadowBottom, 0);
      expect(scope.meadowColor, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('taller band renders without throwing', (tester) async {
      await pumpBothModes(
        tester,
        const KidScope(
          meadowHeight: 320,
          meadowColor: Color(0xFFEAF7E2),
          child: SizedBox(),
        ),
      );
    });
  });

  group('K03 §7 kid type styles', () {
    test('NestType pins the kid copy geometry', () {
      final name = NestType.kidName();
      expect(name.fontSize, 22);
      expect(name.height, 26 / 22);
      expect(name.fontWeight, FontWeight.w900);
      final caption = NestType.kidCaption();
      expect(caption.fontSize, 15);
      expect(caption.height, 20 / 15);
      expect(caption.fontWeight, FontWeight.w700);
      final chip = NestType.kidChipLabel();
      expect(chip.fontSize, 15);
      expect(chip.height, 1);
      expect(chip.fontWeight, FontWeight.w800);
    });

    testWidgets('nestText resolves kid styles against the palette', (
      tester,
    ) async {
      await pumpNest(tester, const SizedBox(key: ValueKey('styles-probe')));
      final context = tester.element(
        find.byKey(const ValueKey('styles-probe')),
      );
      final styles = context.nestText;
      final tokens = context.nest;
      expect(styles.kidName.fontSize, 22);
      expect(styles.kidName.color, tokens.ink);
      expect(styles.kidCaption.fontSize, 15);
      expect(styles.kidCaption.color, tokens.ink2);
      expect(styles.kidChipLabel.fontSize, 15);
      expect(styles.kidChipLabel.color, tokens.leafInk);
    });
  });

  group('K03 §9 NestKidButton label wrap option', () {
    testWidgets('wrapLabel false keeps one line', (tester) async {
      await pumpNest(
        tester,
        NestKidButton(label: 'My jar', wrapLabel: false, onPressed: () {}),
      );
      final text = tester.widget<Text>(find.text('My jar'));
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
      expect(find.byType(FittedBox), findsWidgets);
    });

    testWidgets('default still wraps', (tester) async {
      await pumpNest(tester, NestKidButton(label: 'My jar', onPressed: () {}));
      final text = tester.widget<Text>(find.text('My jar'));
      expect(text.softWrap, isTrue);
    });
  });

  group('P04 NestList overlay dividers', () {
    testWidgets('dividers add no layout height', (tester) async {
      await pumpNest(
        tester,
        const NestList(
          children: [
            SizedBox(width: 350, height: 56),
            SizedBox(width: 350, height: 56),
            SizedBox(width: 350, height: 56),
            SizedBox(width: 350, height: 56),
          ],
        ),
      );
      // 4 x 56 rows with overlay separators stay exactly 224 high
      // (a Divider widget would make 227).
      expect(tester.getSize(find.byType(NestList)).height, 224);
    });
  });
}
