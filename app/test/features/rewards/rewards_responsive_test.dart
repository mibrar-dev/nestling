// P14 Rewards manager — responsive sweep.
//
// Owner rules exercised here:
//   ALIGNMENT  — one 20 px gutter on both sides; every card, the intro and
//                `+ New reward` hang off the same edges; 16 px between cards.
//   BOTTOM EDGE — no bar on this screen; the page must carry its own tint to
//                the physical bottom edge in both themes (no coloured strip).
//   COPY/tokens — nothing scales a colour or a size by hand.
//
// Matrix: widths 320 / 390 / 430 (the design is 390), text scale 1.0 and 1.3
// (the app clamps to 1.0–1.3, see `_clampTextScaler` in app.dart), light and
// dark. The bundled fonts are loaded (see p14_test_support.dart) — without
// them the fallback font invents an overflow that does not exist on device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart';

import '../../test_scope.dart';
import 'p14_test_support.dart';

NestTokens tokensFor(ThemeMode theme) =>
    (theme == ThemeMode.dark ? NestTheme.dark() : NestTheme.light())
        .extension<NestTokens>()!;

/// One (device, text scale, keyboard) combination for the sheet sweep.
class _KeyboardCase {
  const _KeyboardCase({
    required this.width,
    required this.height,
    required this.scale,
    required this.keyboard,
  });

  final int width;
  final int height;
  final double scale;

  /// iOS keyboard height in logical px (260 = compact, 336 = with the
  /// predictive row).
  final double keyboard;
}

void main() {
  setUpAll(loadBundledFonts);

  for (final width in <int>[320, 390, 430]) {
    for (final scale in <double>[1, 1.3]) {
      testWidgets('$width px at text scale $scale: aligned, no overflow', (
        tester,
      ) async {
        for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
          await pumpRewardsApp(
            tester,
            width: width,
            textScale: scale,
            theme: theme,
          );

          final tokens = tokensFor(theme);
          expect(
            tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
            tokens.paper,
            reason: 'the page must carry $theme paper to the edge',
          );

          final cards = find.byType(RewardCard);
          expect(cards, findsNWidgets(6), reason: 'the DB renders six rows');

          // One gutter: 20 px in, 20 px out, for every card.
          var previousBottom = 0.0;
          for (var i = 0; i < 6; i++) {
            final rect = tester.getRect(cards.at(i));
            expect(
              rect.left,
              NestSpacing.padSide,
              reason: 'card $i left edge at $width px / $scale',
            );
            expect(
              rect.width,
              width - 2 * NestSpacing.padSide,
              reason: 'card $i width at $width px / $scale',
            );
            if (i > 0) {
              expect(
                rect.top - previousBottom,
                NestSpacing.s4,
                reason: 'card $i must sit 16 px under card ${i - 1}',
              );
            }

            previousBottom = rect.bottom;
          }

          // The card surface is `surface`, never `paper`.
          final decoration =
              tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: cards.first,
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration;
          expect(
            decoration.color,
            tokens.surface,
            reason: 'cards use the $theme surface token',
          );

          // Fixed shapes survive the sweep.
          final toggle = tester.getRect(find.byType(NestToggle).first);
          expect(toggle.height, NestDevice.tapParent);
          final edit = tester.getRect(
            find.bySemanticsLabel(demoEditLabels['r-screen']!),
          );
          expect(edit.size, const Size(44, 44));
          expect(edit.right, width - NestSpacing.padSide - NestSpacing.s3);

          // The button shares the same edges as the cards.
          await tester.ensureVisible(
            find.byKey(const ValueKey('p14_new_reward')),
          );
          await tester.pumpAndSettle();
          final button = tester.getRect(
            find.byKey(const ValueKey('p14_new_reward')),
          );
          expect(button.left, NestSpacing.padSide);
          expect(button.right, width - NestSpacing.padSide);
          expect(button.height, 52);

          // Row copy stays on one line and ellipsizes rather than wrapping.
          final name = tester.widget<Text>(
            find.text('30 min extra screen time'),
          );
          expect(name.maxLines, 1);
          expect(name.overflow, TextOverflow.ellipsis);
          final rowLabel = tester.widget<Text>(find.text('Needs my OK').first);
          expect(rowLabel.maxLines, 1);

          expect(
            tester.takeException(),
            isNull,
            reason: 'no overflow at $width px / scale $scale / $theme',
          );

          await disposeApp(tester);
        }
      });
    }
  }

  testWidgets('the editor sheet opens and fits at every width / scale', (
    tester,
  ) async {
    for (final width in <int>[320, 390, 430]) {
      for (final scale in <double>[1, 1.3]) {
        await pumpRewardsApp(tester, width: width, textScale: scale);
        await tester.ensureVisible(
          find.byKey(const ValueKey('p14_new_reward')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
        await tester.pumpAndSettle();

        expect(find.byType(RewardEditorSheet), findsOneWidget);
        expect(
          tester.getRect(find.byKey(const ValueKey('p14_save'))).height,
          52,
          reason: 'Save at $width px / scale $scale',
        );
        expect(
          tester.getRect(find.bySemanticsLabel('Increase price')).size,
          const Size(NestDevice.tapParent, NestDevice.tapParent),
          reason: 'the stepper keeps its 44 px targets at $width px / $scale',
        );
        expect(
          tester.getRect(find.byType(NestToggle).last).height,
          NestDevice.tapParent,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'the sheet must fit at $width px / scale $scale',
        );

        await disposeApp(tester);
      }
    }
  });

  // The height axis of the responsive matrix. `pumpRewardsApp` at 844 covers
  // the no-keyboard case; a real keyboard is an INSET that shrinks the space
  // the sheet can use, and short devices have much less of it. P14-B08 was a
  // hand-derived chrome budget that under-counted the 44 px close button and
  // the text scaler, so the form overflowed once the keyboard capped it; the
  // budget is now measured by the layout engine. Every row below is a
  // regression guard on that, including the ones where Save starts *below*
  // the keyboard and has to be scrolled to.
  const keyboardCases = <_KeyboardCase>[
    _KeyboardCase(width: 390, height: 844, scale: 1, keyboard: 300),
    _KeyboardCase(width: 390, height: 844, scale: 1.3, keyboard: 336),
    _KeyboardCase(width: 375, height: 667, scale: 1, keyboard: 260),
    _KeyboardCase(width: 375, height: 667, scale: 1.3, keyboard: 260),
    _KeyboardCase(width: 360, height: 640, scale: 1.3, keyboard: 260),
    // The narrowest and shortest surface we support (iPhone SE, 320×568) at
    // the largest text scale with a keyboard: Save starts *behind* the
    // keyboard here, so this is the row that actually exercises the scroll
    // escape rather than just the no-overflow assertion.
    _KeyboardCase(width: 320, height: 568, scale: 1.3, keyboard: 260),
  ];

  for (final device in keyboardCases) {
    testWidgets('the sheet fits a ${device.keyboard.toInt()} px keyboard on '
        '${device.width}x${device.height} at scale ${device.scale}', (
      tester,
    ) async {
      await pumpRewardsApp(
        tester,
        width: device.width,
        height: device.height,
        textScale: device.scale,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      // The parent focuses the name field; on iOS the keyboard is an inset
      // over the Flutter view rather than a resize.
      await tester.tap(find.byKey(const ValueKey('p14_name_field')));
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding(bottom: device.keyboard * 3);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.takeException(),
        isNull,
        reason: 'the sheet chrome must never overflow (P14-B08)',
      );

      final keyboardTop = device.height - device.keyboard;
      final save = tester.getRect(find.byKey(const ValueKey('p14_save')));
      if (save.bottom > keyboardTop) {
        // Too little room to show everything, so the body must scroll rather
        // than strand the control the parent is reaching for. Drive the
        // Scrollable that OWNS the Save button: `find.byType(Scrollable)`
        // also matches the name field's internal scrollable, and picking the
        // wrong one silently scrolls nothing.
        final formScroll = find
            .ancestor(
              of: find.byKey(const ValueKey('p14_save')),
              matching: find.byType(Scrollable),
            )
            .first;
        final position = tester
            .widget<Scrollable>(formScroll)
            .controller!
            .position;
        expect(
          position.maxScrollExtent,
          greaterThan(0),
          reason: 'Save starts under the keyboard, so the form must scroll',
        );
        while (position.pixels < position.maxScrollExtent) {
          await tester.drag(formScroll, const Offset(0, -120));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
        }
      }
      expect(
        tester.getRect(find.byKey(const ValueKey('p14_save'))).bottom,
        lessThanOrEqualTo(keyboardTop),
        reason: 'Save must be reachable above the keyboard',
      );
      expect(tester.takeException(), isNull, reason: 'after scrolling');

      await disposeApp(tester);
    });
  }

  testWidgets('the resting editor sheet is the design height in both modes', (
    tester,
  ) async {
    // The keyboard work must not have moved the resting sheet. The create
    // sheet (no Delete) and the edit sheet (with Delete) are both pinned:
    // measured before iteration 2 was 422→794 and 362→794 respectively.
    await pumpRewardsApp(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(RewardEditorSheet)),
      const Rect.fromLTRB(20, 422, 370, 794),
      reason: 'create sheet',
    );
    await tester.tap(find.byKey(const ValueKey('p14_cancel')));
    await tester.pumpAndSettle();

    // Cancelling leaves the list where `ensureVisible` parked it, so bring
    // the first card back on screen before addressing its edit button.
    final editFirst = find.bySemanticsLabel('Edit 30 min extra screen time');
    await tester.ensureVisible(editFirst);
    await tester.pumpAndSettle();
    await tester.tap(editFirst);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(RewardEditorSheet)),
      const Rect.fromLTRB(20, 362, 370, 794),
      reason: 'edit sheet is taller by the Delete button',
    );
    expect(find.byKey(const ValueKey('p14_delete')), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('the empty state fits and its action works at 320 px / 1.3', (
    tester,
  ) async {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await pumpRewardsApp(
        tester,
        width: 320,
        textScale: 1.3,
        theme: theme,
        seedDemo: false,
        prepare: Seed.empty,
      );

      expect(find.text('No rewards yet'), findsOneWidget);
      expect(find.byType(RewardCard), findsNothing);
      // `NestEmptyState` adds its own 16 px inner padding, so the action sits
      // inside the 20 px gutter rather than on it — what matters is that it
      // never leaves the gutter and stays a full-width-ish target.
      final action = tester.getRect(
        find.byKey(const ValueKey('p14_empty_new_reward')),
      );
      expect(action.left, greaterThanOrEqualTo(NestSpacing.padSide));
      expect(action.right, lessThanOrEqualTo(320 - NestSpacing.padSide));
      expect(action.height, greaterThanOrEqualTo(52));
      expect(tester.takeException(), isNull, reason: 'empty state at $theme');

      await tester.tap(find.byKey(const ValueKey('p14_empty_new_reward')));
      await tester.pumpAndSettle();
      expect(find.byType(RewardEditorSheet), findsOneWidget);

      await disposeApp(tester);
    }
  });

  testWidgets('the page tint runs to the bottom edge in both themes', (
    tester,
  ) async {
    // BOTTOM EDGE: with no bottom bar the Scaffold itself is the surface. A
    // coloured strip under the last child would show up here as a Scaffold
    // background that is not the `paper` token.
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await pumpRewardsApp(tester, theme: theme);
      final tokens = tokensFor(theme);
      expect(
        tokens.paper,
        isNot(
          tokensFor(theme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark)
              .paper,
        ),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        tokens.paper,
      );
      // The last visible pixel of the list belongs to the same surface.
      final scaffoldRect = tester.getRect(find.byType(Scaffold));
      expect(scaffoldRect.bottom, NestLogical.height);
      expect(find.byType(NestTabBar), findsNothing);
      expect(find.byType(NestBottomCta), findsNothing);

      await disposeApp(tester);
    }
  });
}
