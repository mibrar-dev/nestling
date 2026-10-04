// P16 Settings — responsive sweep and page geometry.
//
// Owner rules exercised here:
//   ALIGNMENT — one 20 px gutter on both sides; the title, every section
//               label, every card, every list and the lock hint all hang off
//               the same edges, and share the width between them.
//   BOTTOM EDGE — the parent shell's tab bar carries its own surface to the
//               physical edge; the page must not show a tinted strip under it.
//   COPY — nothing scales a colour or a size by hand: rows stay `maxLines: 1`
//               with an ellipsis instead of wrapping or clipping.
//   TAP TARGETS — parent mode is 44 px (`--tap-parent`); P16 has no kid
//               surface (kid mode never reaches /settings — the router gates
//               it, `test/app/router_redirect_test.dart`).
//
// Matrix: widths 320 / 390 / 430 (the design is 390), text scale 1.0 and 1.3
// (the app clamps to that range), light and dark. The bundled fonts are loaded
// (see p16_test_support.dart) — without them the fallback face invents an
// overflow that does not exist on device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

/// Every block the screen currently has laid out hangs off the same 20 px
/// gutter (the ListView builds lazily, so this runs at every scroll stop).
Future<void> expectOneGutter(
  WidgetTester tester,
  int width,
  String where,
) async {
  final title = find.text('Family & settings');
  if (title.evaluate().isNotEmpty) {
    expect(
      tester.getRect(title).left,
      NestSpacing.padSide,
      reason: 'title left at $where',
    );
  }
  // Iteration 2: the section labels render through the screen-local
  // `_P16Sect` (the shared `NestSectionLabel` pins an 18 px line box and
  // drifted every card by ~2 px), so a `find.byType(NestSectionLabel)` loop
  // now iterates over NOTHING and asserts nothing. Address the labels by
  // their rendered copy instead, and require at least one to be on screen —
  // a finder that matches nothing must never read as "aligned".
  var seenLabels = 0;
  for (final label in kP16SectionLabels) {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) continue;
    seenLabels++;
    expect(
      tester.getRect(finder).left,
      NestSpacing.padSide,
      reason: 'section label "$label" left at $where',
    );
  }
  if (title.evaluate().isNotEmpty) {
    expect(
      seenLabels,
      greaterThan(0),
      reason: 'a section label is on screen at $where',
    );
  }
}

/// Stable key for a (theme, text scale) pair — `double.toString()` on the
/// literal `1` would otherwise disagree with the loop's `1.0`.
String _scaleKey(ThemeMode theme, double scale) =>
    '${theme.name}@${scale.toStringAsFixed(1)}';

/// The design's section labels, upper-cased exactly as the screen renders them
/// (`.sect { text-transform: uppercase }`).
const List<String> kP16SectionLabels = <String>[
  'FAMILY',
  'CHILDREN',
  'SUBSCRIPTION',
  'TIME ZONE',
  'NOTIFICATIONS',
  'PRIVACY',
  'ABOUT',
];

void main() {
  setUpAll(loadP16Fonts);

  for (final width in <int>[320, 390, 430]) {
    for (final scale in <double>[1, 1.3]) {
      testWidgets(
        '$width px at text scale $scale: one gutter, no overflow, both themes',
        (tester) async {
          for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
            await pumpSettingsApp(
              tester,
              size: Size(width.toDouble(), p16DesignSize.height),
              textScale: scale,
              theme: theme,
            );
            final tokens = p16Tokens(theme);
            final gutter = width - 2 * NestSpacing.padSide;

            // The page carries its own paper to the top of the shell chrome.
            expect(
              tester
                  .widget<Scaffold>(
                    find
                        .descendant(
                          of: find.byType(SettingsView),
                          matching: find.byType(Scaffold),
                        )
                        .first,
                  )
                  .backgroundColor,
              tokens.paper,
              reason: '$theme paper at $width / $scale',
            );

            // ALIGNMENT: the title, every section label and every card share
            // one gutter and one content width.
            await expectOneGutter(tester, width, '$theme $width/$scale top');
            for (var i = 0; i < 3; i++) {
              final lists = find.byType(NestList);
              final built = lists.evaluate().length;
              for (var l = 0; l < built; l++) {
                final list = tester.getRect(lists.at(l));
                expect(
                  list.left,
                  NestSpacing.padSide,
                  reason: 'list $l left at $theme $width/$scale',
                );
                expect(list.width, gutter, reason: 'list $l width');
              }
              final cards = find.byKey(const ValueKey('p16_subcard'));
              for (var c = 0; c < cards.evaluate().length; c++) {
                final rect = tester.getRect(cards.at(c));
                expect(rect.left, NestSpacing.padSide, reason: 'card $c left');
                expect(rect.width, gutter, reason: 'card $c width');
              }
              if (i == 2) break;
              await tester.drag(settingsScrollable(), const Offset(0, -320));
              await tester.pumpAndSettle();
              await expectOneGutter(
                tester,
                width,
                '$theme $width/$scale page ${i + 1}',
              );
            }

            // BOTTOM EDGE: the bar surface runs to the physical edge.
            expect(
              tester.getRect(find.byType(NestTabBar)).bottom,
              p16DesignSize.height,
              reason: 'no coloured strip below the bar ($theme)',
            );

            // FIXED SHAPES: the switch lays out at the design's 51x31 track
            // (shared batch 5) whatever the width or text scale.
            final toggles = find.byType(NestToggle);
            expect(toggles, findsNWidgets(3), reason: 'three switches');
            for (var i = 0; i < 3; i++) {
              expect(
                tester.getRect(toggles.at(i)).size,
                const Size(51, 31),
                reason: 'switch $i keeps the design track',
              );
            }

            expect(
              tester.takeException(),
              isNull,
              reason: 'no overflow at $width px / scale $scale / $theme',
            );

            await disposeApp(tester);
          }
        },
      );
    }
  }

  testWidgets('the section labels carry the design typography and scale with '
      'the text scaler', (tester) async {
    // Iteration 2: the labels render through the screen-local `_P16Sect`
    // (`.sect`: 13/700 uppercase, `letter-spacing:.06em`, ink-2) instead of
    // the shared `NestSectionLabel`. The component measures Inter's natural
    // line box with a one-off `TextPainter`, so what has to hold here is that
    // the copy is upper-cased, the style is the design's, the label shares the
    // gutter, and the box grows with the text scaler instead of clipping the
    // glyphs. The exact pixel height belongs to the UI stage's remeasure.
    final heights = <String, double>{};
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final scale in <double>[1, 1.3]) {
        await pumpSettingsApp(tester, textScale: scale, theme: theme);
        final tokens = p16Tokens(theme);

        // Measured at the top, where the first label is already on screen: the
        // loop below only ever scrolls DOWN, and `scrollUntilVisible` cannot
        // walk back up.
        heights[_scaleKey(theme, scale)] = tester
            .getRect(find.text('FAMILY'))
            .height;

        for (final label in kP16SectionLabels) {
          // The list builds lazily: a label below the fold is not in the tree
          // yet, so scroll it on before addressing it.
          await scrollSettingsTo(tester, find.text(label));
          final finder = find.text(label);
          expect(
            finder,
            findsOneWidget,
            reason: '"$label" at $theme / scale $scale',
          );
          final text = tester.widget<Text>(finder);
          final style = text.style!;
          expect(style.fontSize, 13, reason: '"$label" font size');
          expect(style.fontWeight, FontWeight.w700, reason: '"$label" weight');
          expect(
            style.letterSpacing,
            closeTo(13 * 0.06, 0.001),
            reason: '"$label" letter-spacing is .06em of 13 px',
          );
          expect(style.color, tokens.ink2, reason: '"$label" colour ($theme)');
          expect(text.maxLines, 1, reason: '"$label" stays on one line');
          expect(text.overflow, TextOverflow.ellipsis, reason: '"$label"');
          expect(
            tester.getRect(finder).left,
            NestSpacing.padSide,
            reason: '"$label" shares the 20 px gutter',
          );
        }

        await disposeApp(tester);
      }
    }

    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      expect(
        heights[_scaleKey(theme, 1.3)],
        closeTo(heights[_scaleKey(theme, 1)]! * 1.3, 0.6),
        reason:
            '$theme: the label box must grow with the text scaler (a probe '
            'measured without the scaler would clip the glyphs)',
      );
    }
  });

  testWidgets('the subscription subcard is a 16 px surface card, not a page '
      'tint', (tester) async {
    // `.subcard { background: var(--surface); border-radius: var(--r-m);
    // box-shadow: var(--sh-1); padding: 14px 16px }` (P16-B06 moved this off
    // `NestCard.standard`, whose radius is 24).
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await pumpSettingsApp(tester, theme: theme);
      final tokens = p16Tokens(theme);
      final card = find.byKey(const ValueKey('p16_subcard'));
      expect(card, findsOneWidget, reason: 'one subcard at $theme');

      final decoration =
          tester.widget<Container>(card).decoration! as BoxDecoration;
      expect(
        decoration.color,
        tokens.surface,
        reason: 'subcard surface ($theme)',
      );
      expect(
        decoration.borderRadius,
        NestRadii.allM,
        reason: 'r-m is 16 px, not NestCard.standard 24, at $theme',
      );
      expect(decoration.boxShadow, tokens.cardShadow, reason: 'sh-1 at $theme');
      expect(
        tester.widget<Container>(card).padding,
        const EdgeInsets.symmetric(
          horizontal: NestSpacing.s4,
          vertical: NestSpacing.gap14,
        ),
        reason: '.subcard padding is 14/16 at $theme',
      );
      await disposeApp(tester);
    }
  });

  testWidgets('row copy stays on one line and ellipsizes instead of wrapping', (
    tester,
  ) async {
    // The narrowest surface at the largest scale: the rows that could break
    // are the long ones (a member e-mail, a Pip summary, the zone row).
    await pumpSettingsApp(
      tester,
      size: Size(320, p16DesignSize.height),
      textScale: 1.3,
    );

    for (final copy in <String>[
      'sarah@example.co.uk',
      'Invited · awaiting reply',
      'Pip: Fledgling · 120 coins',
      'Nickname + age band only',
    ]) {
      final text = tester.widget<Text>(find.text(copy));
      expect(text.maxLines, 1, reason: '"$copy"');
      expect(text.overflow, TextOverflow.ellipsis, reason: '"$copy"');
    }

    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('the lock hint shares the gutter and wraps instead of clipping', (
    tester,
  ) async {
    await pumpSettingsApp(
      tester,
      size: Size(320, p16DesignSize.height),
      textScale: 1.3,
    );
    await scrollSettingsTo(tester, find.text('Help & feedback'));

    final hint = find
        .ancestor(
          of: find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.textSpan?.toPlainText() == 'Kid mode needs parent gate — On',
          ),
          matching: find.byType(Container),
        )
        .first;
    final rect = tester.getRect(hint);
    expect(rect.left, NestSpacing.padSide);
    expect(rect.width, 320 - 2 * NestSpacing.padSide);
    expect(rect.height, greaterThan(0));
    expect(tester.takeException(), isNull, reason: 'the hint must not clip');

    await disposeApp(tester);
  });

  for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'the move banner shares the gutter and stays tappable ($theme)',
      (tester) async {
        await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai', theme: theme);

        final banner = tester.getRect(
          find.byKey(const ValueKey('p16_move_banner')),
        );
        expect(banner.left, NestSpacing.padSide, reason: 'banner left');
        expect(banner.width, p16DesignSize.width - 2 * NestSpacing.padSide);
        // The banner is a leaf-tint card in both themes, never the page paper.
        expect(
          (tester
                      .widget<Container>(
                        find.byKey(const ValueKey('p16_move_banner')),
                      )
                      .decoration!
                  as BoxDecoration)
              .color,
          p16Tokens(theme).leafTint,
          reason: 'banner surface at $theme',
        );
        for (final key in const <String>[
          'p16_move_switch',
          'p16_move_not_now',
        ]) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(
            rect.height,
            greaterThanOrEqualTo(NestDevice.tapParent),
            reason: '$key is ${rect.size}',
          );
          expect(rect.left, greaterThanOrEqualTo(NestSpacing.padSide));
          expect(rect.right, lessThanOrEqualTo(370));
        }
        // Copy is the orchestrator's sentence, on two rows at most.
        expect(
          find.text(
            'Looks like you’re in Dubai now. Switch the family time zone? '
            'History keeps London times; future days follow Dubai.',
          ),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  }

  testWidgets('the subscription card keeps the design padding at 320 / 1.3', (
    tester,
  ) async {
    await pumpSettingsApp(
      tester,
      size: Size(320, p16DesignSize.height),
      textScale: 1.3,
    );

    final card = find.byKey(const ValueKey('p16_subcard'));
    expect(card, findsOneWidget);
    final title = tester.getRect(find.text('Nestling Annual · £29.99/year'));
    final cardRect = tester.getRect(card);
    expect(title.left, cardRect.left + NestSpacing.s4, reason: '16 px inset');
    // `.linkrow { min-height: 52px }` — the row, not its 15 px label.
    final linkRow = find
        .ancestor(
          of: find.text('Manage subscription'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(
      tester.getRect(linkRow).height,
      52,
      reason: '.linkrow min-height 52',
    );
    expect(
      tester.getRect(find.text('Manage subscription')).height,
      lessThan(52),
      reason: 'the label sits inside the 52 px row',
    );
    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });

  testWidgets('the title carries the design h1 metrics with no tracking', (
    tester,
  ) async {
    await pumpSettingsApp(tester);

    final title = tester.widget<Text>(find.text('Family & settings'));
    final style = title.style!;
    // `.ptitle` = 28/34 Nunito 900, and the design CSS sets no tracking.
    expect(style.fontSize, 28);
    expect(style.height, 34 / 28);
    expect(style.fontWeight, FontWeight.w900);
    expect(style.letterSpacing, 0);

    await disposeApp(tester);
  });
}
