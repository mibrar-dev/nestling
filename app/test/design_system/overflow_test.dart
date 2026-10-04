import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_screens.dart';

import 'test_harness.dart';

/// Overflow hardening across the whole design system.
///
/// Pumps every component (plus the P08/K03 preview compositions) at widths
/// 320 / 360 / 390 / 430 and textScalers 1.0 / 1.3 in light and dark, and
/// asserts:
/// * no RenderFlex overflow (no FlutterError),
/// * no ellipsized button/chip labels with realistic short labels
///   (`didExceedMaxLines` on any Text inside a button/chip = fail),
/// * tap targets >= 44 (parent) / >= 56 (kid).
///
/// Labels are intentionally short and realistic. Button and chip labels
/// wrap instead of ellipsizing (enforced below); only list titles keep
/// maxLines + ellipsis, covered by the per-component tests instead.
void main() {
  const widths = [320.0, 360.0, 390.0, 430.0];
  const scalers = [1.0, 1.3];
  const modes = [ThemeMode.light, ThemeMode.dark];

  final groups = <String, Widget Function()>{
    'parent buttons': _parentButtons,
    'kid buttons': _kidButtons,
    'chips and inputs': _chipsAndInputs,
    'cards and lists': _cardsAndLists,
    'overlays and misc': _overlaysAndMisc,
    'chrome': _chrome,
    'previews': _previews,
  };

  for (final entry in groups.entries) {
    group(entry.key, () {
      for (final width in widths) {
        for (final scaler in scalers) {
          for (final mode in modes) {
            testWidgets('w${width.toInt()} scaler$scaler ${mode.name}', (
              tester,
            ) async {
              await pumpNest(
                tester,
                SingleChildScrollView(child: entry.value()),
                mode: mode,
                surface: Size(width, 844),
                textScale: scaler,
              );
              expect(
                tester.takeException(),
                isNull,
                reason: 'RenderFlex overflow in ${entry.key}',
              );
              _expectNoButtonEllipsis(tester, entry.key);
              _expectMinTapTargets(tester, entry.key);
            });
          }
        }
      }
    });
  }
  ownerQaRegressions();
}

Widget _parentButtons() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NestButton(label: 'Get started', onPressed: () {}),
      const SizedBox(height: 8),
      NestButton(
        label: 'Secondary',
        variant: NestButtonVariant.secondary,
        onPressed: () {},
      ),
      const SizedBox(height: 8),
      NestButton(
        label: 'Ghost',
        variant: NestButtonVariant.ghost,
        onPressed: () {},
      ),
      const SizedBox(height: 8),
      NestButton(
        label: 'Delete',
        variant: NestButtonVariant.dangerGhost,
        onPressed: () {},
      ),
      const SizedBox(height: 8),
      NestButton(
        label: 'Review',
        minHeight: 44,
        fullWidth: false,
        fontSize: 15,
        horizontalPadding: 18,
        onPressed: () {},
      ),
      const SizedBox(height: 8),
      NestAppleButton(label: 'Apple', onPressed: () {}),
      const SizedBox(height: 8),
      NestGoogleButton(label: 'Google', onPressed: () {}),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: NestFab(label: 'New', icon: NestIcons.plus, onPressed: () {}),
      ),
      const SizedBox(height: 8),
      NestStepper(valueText: '3', onDecrease: () {}, onIncrease: () {}),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NestLockButton(large: false, onPressed: () {}),
          const SizedBox(width: 8),
          NestIconButton(
            icon: NestIcons.plus,
            semanticLabel: 'Add',
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}

Widget _kidButtons() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final color in NestKidButtonColor.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NestKidButton(
            label: color.name,
            color: color,
            onPressed: () {},
          ),
        ),
      Row(
        children: [
          Expanded(
            child: NestKidButton(
              label: 'Pip',
              color: NestKidButtonColor.lilac,
              minHeight: 66,
              axis: Axis.vertical,
              gap: NestSpacing.s1,
              fontSize: 17,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: NestKidButton(
              label: 'Shop',
              color: NestKidButtonColor.coin,
              minHeight: 66,
              axis: Axis.vertical,
              gap: NestSpacing.s1,
              fontSize: 17,
              onPressed: () {},
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      NestKidButton(
        label: 'Get it',
        minHeight: 56,
        borderRadius: NestRadii.m,
        fontSize: 17,
        onPressed: () {},
      ),
    ],
  );
}

Widget _chipsAndInputs() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          NestChip(label: 'Daily', onSelected: (_) {}),
          NestChip(label: 'To do', selected: true, onSelected: (_) {}),
          const NestChip(label: 'Static'),
        ],
      ),
      const SizedBox(height: 8),
      NestSegmented<String>(
        options: const [
          NestSegmentOption(value: 'a', label: 'Maya'),
          NestSegmentOption(value: 'b', label: 'Leo'),
        ],
        value: 'a',
        onChanged: (_) {},
      ),
      const SizedBox(height: 8),
      const NestToggle(value: true, onChanged: null, semanticLabel: 'Toggle'),
      const SizedBox(height: 8),
      const NestTextField(label: 'Name', hintText: 'Ada'),
      const SizedBox(height: 8),
      NestDayPicker(
        days: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        selected: const {0},
        onChanged: (_) {},
      ),
      const SizedBox(height: 8),
      const Wrap(
        spacing: 8,
        children: [
          NestCoinPill(amount: '120'),
          NestCoinPill(amount: '15', size: NestCoinPillSize.small),
          NestCoinPill(amount: '15', size: NestCoinPillSize.xSmall),
          NestCoinPill(amount: '20', size: NestCoinPillSize.large),
        ],
      ),
      const SizedBox(height: 8),
      const Row(
        children: [
          NestMoney(amount: 4.20),
          SizedBox(width: 8),
          NestBadgeCount(count: 3),
        ],
      ),
      const SizedBox(height: 8),
      const NestProgress(fraction: 0.5),
      const SizedBox(height: 8),
      const NestProgress(fraction: 0.5, kid: true),
    ],
  );
}

Widget _cardsAndLists() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const NestCard(child: Text('Standard', maxLines: 1)),
      const SizedBox(height: 8),
      const NestCard(variant: NestCardVariant.inset, child: Text('Inset')),
      const SizedBox(height: 8),
      const NestCard(variant: NestCardVariant.hero, child: Text('Hero')),
      const SizedBox(height: 8),
      const NestList(
        children: [
          NestListRow(title: 'Make bed', subtitle: 'Daily'),
          NestListRow(
            title: 'Read',
            subtitle: 'Daily',
            leadingAsset: NestIcons.book,
            tint: NestTileTint.lilac,
            trailing: NestCoinPill(amount: '10', size: NestCoinPillSize.xSmall),
          ),
          NestListRow(title: 'Pager row', leadingAsset: NestIcons.book),
        ],
      ),
      const SizedBox(height: 8),
      NestQuestCard(title: 'Tidy room', meta: 'Maya', onTap: () {}),
      const SizedBox(height: 8),
      NestKidQuestCard(title: 'Read', coinAmount: '+10', onTap: () {}),
      const SizedBox(height: 8),
      const Row(
        children: [
          NestAvatar(initial: 'M', size: NestAvatarSize.s32),
          SizedBox(width: 8),
          NestAvatar(initial: 'L'),
          SizedBox(width: 8),
          NestAvatar(initial: 'M', size: NestAvatarSize.s64),
        ],
      ),
      const SizedBox(height: 8),
      const NestPagerDots(count: 3, index: 0),
      const SizedBox(height: 8),
      const NestSectionLabel(label: 'Group'),
    ],
  );
}

Widget _overlaysAndMisc() {
  return const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NestModal(title: 'Title', child: Text('Body')),
      SizedBox(height: 8),
      NestToast(message: 'Saved'),
      SizedBox(height: 8),
      NestEmptyState(title: 'Empty', message: 'Nothing here yet'),
      SizedBox(height: 8),
      NestBottomSheet(title: 'Sheet', child: Text('Content')),
      SizedBox(height: 8),
      NestPetStage(speech: 'Go!', pipSize: 120),
      SizedBox(height: 8),
      NestPinDots(total: 4, filled: 2),
      SizedBox(height: 8),
      _KeypadProbe(),
    ],
  );
}

class _KeypadProbe extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return NestKeypad(onKey: (_) {}, onDelete: () {});
  }
}

Widget _chrome() {
  const items = [
    NestTabItem(label: 'Today', icon: NestIcons.home),
    NestTabItem(label: 'Quests', icon: NestIcons.quests),
    NestTabItem(label: 'Money', icon: NestIcons.money),
    NestTabItem(label: 'Family', icon: NestIcons.family),
  ];
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const NestStatusBar(),
      const NestNavBar(title: 'Pocket money'),
      const NestNavBar(title: 'Waiting', compact: true),
      const NestBottomCta(child: Text('CTA')),
      NestTabBar(items: items, currentIndex: 0, onTap: (_) {}),
      const NestHomeIndicator(),
    ],
  );
}

Widget _previews() {
  return const GalleryScreens();
}

/// Fails when any Text inside a button/chip exceeded its max lines
/// (i.e. a realistic short label got ellipsized = cramped geometry).
void _expectNoButtonEllipsis(WidgetTester tester, String group) {
  const buttonTypes = <Type>{
    NestButton,
    NestKidButton,
    NestFab,
    NestAppleButton,
    NestGoogleButton,
    NestChip,
  };
  for (final element in find.byType(Text).evaluate()) {
    var insideButton = false;
    element.visitAncestorElements((ancestor) {
      if (buttonTypes.contains(ancestor.widget.runtimeType)) {
        insideButton = true;
      }
      return !insideButton;
    });
    if (!insideButton) {
      continue;
    }
    final renderObject = element.renderObject;
    if (renderObject is RenderParagraph && renderObject.didExceedMaxLines) {
      fail(
        'Ellipsized button/chip label in $group: '
        '"${(element.widget as Text).data}"',
      );
    }
  }
}

/// Fails when a tappable surface is smaller than its platform minimum.
void _expectMinTapTargets(WidgetTester tester, String group) {
  void atLeast(
    Finder finder,
    double minW,
    double minH,
    String what, {
    bool skipIfAbsent = false,
  }) {
    final count = finder.evaluate().length;
    if (count == 0) {
      if (skipIfAbsent) {
        return;
      }
      fail('Missing $what in $group for tap-target check');
    }
    for (var i = 0; i < count; i++) {
      final size = tester.getSize(finder.at(i));
      if (size.width < minW - 0.5 || size.height < minH - 0.5) {
        fail(
          'Tap target $what #${i + 1} in $group is '
          '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}'
          ' < ${minW.toStringAsFixed(0)}x${minH.toStringAsFixed(0)}',
        );
      }
    }
  }

  switch (group) {
    case 'parent buttons':
      atLeast(find.byType(NestButton), 44, 44, 'NestButton');
      atLeast(find.byType(NestLockButton), 44, 44, 'NestLockButton');
      atLeast(find.byType(NestIconButton), 44, 44, 'NestIconButton');
    case 'kid buttons':
      atLeast(find.byType(NestKidButton), 56, 56, 'NestKidButton');
    case 'chips and inputs':
      // Interactive chips lay out at the design's 32 px; the 44 tap minimum
      // is an overlaid hit test, not layout (shared batch 2 — proven by the
      // tap-outside tests in shared_batch2_test.dart, not by layout size).
      atLeast(
        find.byWidgetPredicate(
          (w) => w is NestChip && w.onSelected != null,
          description: 'interactive NestChip',
        ),
        44,
        32,
        'interactive NestChip',
      );
      atLeast(find.byType(NestSegmented<String>), 44, 44, 'NestSegmented');
      // Shared batch 5: the toggle lays out at the design's 51x31 track; the
      // 59x44 tap minimum is an overlaid hit test, not layout (like NestChip
      // above — proven by tap-outside tests in shared_batch5_test.dart).
      atLeast(find.byType(NestToggle), 51, 31, 'NestToggle');
      atLeast(find.byType(NestTextField), 44, 44, 'NestTextField');
      atLeast(find.byType(NestDayPicker), 44, 44, 'NestDayPicker');
    case 'cards and lists':
      atLeast(find.byType(NestListRow), 44, 44, 'NestListRow');
      atLeast(find.byType(NestSectionLabel), 4, 12, 'NestSectionLabel');
    case 'chrome':
      atLeast(find.byType(NestNavBar), 44, 44, 'NestNavBar');
      atLeast(find.byType(NestTabBar), 300, 84, 'NestTabBar');
    case 'previews':
      atLeast(
        find.byType(NestButton),
        44,
        44,
        'preview NestButton',
        skipIfAbsent: true,
      );
      atLeast(
        find.byType(NestKidButton),
        56,
        56,
        'preview NestKidButton',
        skipIfAbsent: true,
      );
    case 'overlays and misc':
      break;
  }
}

/// Owner simulator-QA regressions (dark-mode round).
///
/// * segmented thumb: 52px track, 44px buttons (`.segmented`: 4px padding
///   around buttons whose min-height:44px beats height:40px), sh-1 visible
///   in light, 1px line border and no shadow in dark;
/// * parent quest check: 28px visual ring with a 44px hit area;
/// * icon tiles: 40x40, radius 12, 24px icon centred;
/// * keypad: 8px grid padding, 1px line border and no shadow in dark;
/// * buttons size to intrinsic content and labels wrap, never ellipsize.
void ownerQaRegressions() {
  group('owner qa', () {
    testWidgets('segmented geometry and dark border', (tester) async {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        await pumpNest(
          tester,
          NestSegmented<String>(
            options: const [
              NestSegmentOption(value: 'a', label: 'Maya'),
              NestSegmentOption(value: 'b', label: 'Leo'),
            ],
            value: 'a',
            onChanged: (_) {},
          ),
          mode: mode,
        );
        expect(tester.getSize(find.byType(NestSegmented<String>)).height, 52);
        expect(tester.getSize(find.byType(InkWell).first).height, 44);
        final thumb = find
            .descendant(
              of: find.byType(NestSegmented<String>),
              matching: find.byType(Ink),
            )
            .first;
        final decoration =
            tester.widget<Ink>(thumb).decoration! as BoxDecoration;
        if (mode == ThemeMode.dark) {
          expect(decoration.border, isNotNull);
          expect(decoration.boxShadow, isNull);
        } else {
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.border, isNull);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('parent check ring 28 with 44 hit area', (tester) async {
      await pumpBothModes(
        tester,
        NestQuestCard(
          title: 'Put the bins out',
          meta: 'Maya · 15 coins',
          done: false,
          onToggled: (_) {},
          onTap: () {},
        ),
      );
      final face = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == NestDevice.checkRing &&
            widget.height == NestDevice.checkRing,
      );
      expect(face, findsOneWidget);
      expect(tester.getSize(find.bySemanticsLabel('Mark done')).height, 44);
    });

    testWidgets('tile 40x40 r12 with centred 24 icon', (tester) async {
      await pumpBothModes(
        tester,
        const NestList(
          children: [
            NestListRow(
              title: 'Read',
              subtitle: 'Daily',
              leadingAsset: NestIcons.book,
              tint: NestTileTint.lilac,
            ),
          ],
        ),
      );
      final tile = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).borderRadius ==
                BorderRadius.circular(NestSpacing.s3),
      );
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile), const Size(40, 40));
      expect(tester.getSize(find.byType(NestIcon)), const Size(24, 24));
      final distance =
          (tester.getCenter(tile) - tester.getCenter(find.byType(NestIcon)))
              .distance;
      expect(distance, lessThan(0.5));
    });

    testWidgets('keypad grid geometry and dark treatment', (tester) async {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        await pumpNest(
          tester,
          SizedBox(
            width: 302,
            child: NestKeypad(onKey: (_) {}, onDelete: () {}),
          ),
          mode: mode,
        );
        // CSS `.keypad` grid in the 302px P17 card content box: 3 equal
        // columns over 302-48 padding with 10px gaps -> 88px column pitch;
        // 72px rows with 10px gaps -> 82px row pitch.
        final oneLeft = tester.getTopLeft(find.text('1'));
        final twoLeft = tester.getTopLeft(find.text('2'));
        final fourTop = tester.getTopLeft(find.text('4'));
        expect(twoLeft.dx - oneLeft.dx, moreOrLessEquals(88));
        expect(fourTop.dy - oneLeft.dy, moreOrLessEquals(82));
        final key = find
            .descendant(of: find.byType(NestKeypad), matching: find.byType(Ink))
            .first;
        final decoration = tester.widget<Ink>(key).decoration! as BoxDecoration;
        if (mode == ThemeMode.dark) {
          expect(decoration.border, isNotNull);
          expect(decoration.boxShadow, isNull);
        } else {
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.border, isNull);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('wrap buttons size intrinsically, labels wrap', (tester) async {
      await pumpBothModes(
        tester,
        Wrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: [
            NestButton(label: 'Sheet', fullWidth: false, onPressed: () {}),
            NestButton(label: 'Modal', fullWidth: false, onPressed: () {}),
            NestButton(label: 'Toast', fullWidth: false, onPressed: () {}),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      for (final label in const ['Sheet', 'Modal', 'Toast']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      await pumpBothModes(
        tester,
        NestButton(
          label: 'A long label that must wrap onto more lines, never clip',
          onPressed: () {},
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
    testWidgets('pet feet stand inside the nest', (tester) async {
      // Golden-ish position lock on VISIBLE content (not widget boxes):
      // Pip's drawn feet sit at svg-y 207/240 of pip_stage_3.svg, so the
      // test re-derives their absolute position the way the component
      // does. Feet must land inside the nest's vertical bounds (front rim
      // overlaps the lower body), never floating above a detached nest.
      const feetInSvg = 207 / 240;
      await pumpBothModes(
        tester,
        const SizedBox(width: 350, child: NestPetStage(pipSize: 120)),
      );
      final layers = find.descendant(
        of: find.byType(NestPetStage),
        matching: find.byType(SvgPicture),
      );
      expect(layers.evaluate().length, 3);
      // Tree order: nest back, Pip, nest front.
      final nestTop = tester.getTopLeft(layers.at(0)).dy;
      final pipTop = tester.getTopLeft(layers.at(1)).dy;
      final pipH = tester.getSize(layers.at(1)).height;
      final feet = pipTop + feetInSvg * pipH;
      final nestBottom =
          tester.getTopLeft(layers.at(2)).dy +
          tester.getSize(layers.at(2)).height;
      expect(feet, greaterThan(nestTop));
      expect(feet, lessThanOrEqualTo(nestBottom));
      // K03 proportions at 350: nest ≈ 200 wide, Pip ≈ 120 tall.
      expect(
        tester.getSize(layers.at(0)).width,
        moreOrLessEquals(217, epsilon: 1),
      );
      expect(pipH, moreOrLessEquals(119.4, epsilon: 1));
    });
  });
}
