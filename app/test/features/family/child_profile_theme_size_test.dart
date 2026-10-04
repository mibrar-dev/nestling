// P15 · Child profile — themes, sizes, scales and tap targets.
//
// `child_profile_view_test.dart` pins the 390-wide light-mode geometry against
// the design PNG. This file proves the other half of the matrix the stage
// brief asks for: the same screen in DARK mode, at 320 / 390 / 430, with the
// text scaler at 1.0 and 1.3, plus the accessibility contracts that are not
// about copy:
//
//   * every band keeps the 20 px gutter at every width (OWNER ALIGNMENT);
//   * every card fill is a TOKEN (`surface`), never `ink`, in both themes
//     (1_plan.md: "hero fill is `surface`, never `ink`");
//   * every control clears the 44 px parent tap target (≥ 56 would be the
//     kid-mode floor — this is a parent screen, and the rows happen to be
//     the 60 px list rows, so both are asserted);
//   * every image/icon node carries a label (ACCESSIBILITY: icon buttons);
//   * the shell clamps the text scaler to 1.0–1.3, so a 2.0 system setting
//     cannot break the layout either.
//
// P15 renders no `NestIconButton`, so "icon buttons" here means every
// `isImage` semantics node on the screen (the Pip art, the three list-row
// icons and the four tab-bar icons): none of them may be unlabelled.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/presentation/views/child_profile_view.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

import '../../test_scope.dart';

const _route = '/child-profile';

/// The measured light-mode bands (`design/screens/light/P15-child-profile.png`
/// ÷ 3) — dark mode must not move a single pixel of them.
const _heroTop = 47.0;
const _heroHeight = 164.0;
const _statsTop = 227.0;
const _statsHeight = 82.0;
const _pipTop = 325.0;
const _pipHeight = 116.0;
const _listTop = 457.0;
const _listHeight = 180.0;
const _dangerTop = 653.0;
const _dangerHeight = 80.0;

/// Pumps the whole app at [_route] on a given surface, exactly like
/// `test_scope.dart:pumpAppRoute` but with width / scale / theme knobs.
Future<void> _pumpAt(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The fill of the [NestCard] (or `.stat` tile) that carries [key].
Color _fill(WidgetTester tester, Key key) => _fillOf(tester, find.byKey(key));

/// The fill of the outermost decorated [Container] under [ancestor].
///
/// Only the card itself is read: a [NestListRow]'s first descendant Container
/// is its 40 px icon TILE (`sky`/`leaf`/`coin` tint), not the list card.
Color _fillOf(WidgetTester tester, Finder ancestor) {
  final container = tester.widget<Container>(
    find.descendant(of: ancestor, matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// Loads the bundled Inter/Nunito faces, so text measurements here are the
/// ones a device renders (the same helper `child_profile_view_test.dart`
/// uses). Without them Flutter's test font is much wider than Inter and
/// perfectly good paragraphs look ellipsised.
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

/// Every `isImage` node on screen, with its label.
List<({int id, String label})> _imageNodes(WidgetTester tester) {
  final found = <({int id, String label})>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.flagsCollection.isImage) {
      found.add((id: node.id, label: data.label));
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  // `rootPipelineOwner` has no SemanticsOwner in a widget test (the owner
  // hangs off the pumped render view) — the same walk
  // `test/features/rewards/p14_test_support.dart:tappableSemanticsNodes` uses.
  final views = tester.binding.renderViews;
  final root = views.isEmpty
      ? null
      : views.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root == null) {
    throw StateError(
      'no semantics tree: call tester.ensureSemantics() and pump first',
    );
  }
  walk(root);
  return found;
}

void main() {
  // The row-copy checks below measure TEXT, so the bundled faces must be
  // loaded — the same reason `child_profile_view_test.dart` does it. Without
  // them the test font is far wider than Inter and every paragraph looks
  // ellipsised.
  setUpAll(_loadBundledFonts);

  group('P15 surfaces are token-driven in both themes', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: cards, tiles and ink follow the tokens', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpAt(tester, theme: theme);

        final tokens = tester.element(find.byType(ChildProfileBody)).nest;
        expect(tokens.isDark, theme == ThemeMode.dark);

        // Every band is a `surface` card — never `ink` (which is what a dark
        // theme would render as an unreadable black-on-black block).
        for (final key in const <String>[
          'p15-hero',
          'p15-stat-quests',
          'p15-stat-coins',
          'p15-stat-days',
          'p15-pip',
        ]) {
          final fill = _fill(tester, Key(key));
          expect(fill, tokens.surface, reason: '$key must be surface');
          expect(fill, isNot(tokens.ink), reason: '$key must never be ink');
        }
        expect(_fillOf(tester, find.byType(NestList)), tokens.surface);

        // The page behind the cards is `paper`, and the type is `ink`/`ink2`
        // /`ink3` — tokens only, no literal colours (RULES: design system).
        // Scoped to P15's OWN Scaffold: the indexed-stack shell also builds
        // Today/Quests/Money, and `find.byType(Scaffold).first` is one of
        // those, not this screen.
        final scaffold = tester.widget<Scaffold>(
          find
              .descendant(
                of: find.byType(ChildProfileView),
                matching: find.byType(Scaffold),
              )
              .first,
        );
        expect(scaffold.backgroundColor, tokens.paper);
        expect(_styleOf(tester, 'Maya').color, tokens.ink);
        expect(
          _styleOf(tester, 'Age 7\u20139 \u00B7 Pip is a Fledgling').color,
          tokens.ink2,
        );
        expect(_styleOf(tester, 'Change \u203A').color, tokens.ink3);

        await disposeApp(tester);
      });

      testWidgets('${theme.name}: the bands do not move', (tester) async {
        await setUpTestScope();
        await _pumpAt(tester, theme: theme);

        expect(_rect(tester, 'p15-hero').top, closeTo(_heroTop, 0.01));
        expect(_rect(tester, 'p15-hero').height, closeTo(_heroHeight, 0.01));
        expect(_rect(tester, 'p15-stat-quests').top, closeTo(_statsTop, 0.01));
        expect(
          _rect(tester, 'p15-stat-quests').height,
          closeTo(_statsHeight, 0.01),
        );
        expect(_rect(tester, 'p15-pip').top, closeTo(_pipTop, 0.01));
        expect(_rect(tester, 'p15-pip').height, closeTo(_pipHeight, 0.01));
        expect(
          tester.getRect(find.byType(NestList)).top,
          closeTo(_listTop, 0.01),
        );
        expect(
          tester.getRect(find.byType(NestList)).height,
          closeTo(_listHeight, 0.01),
        );
        expect(_rect(tester, 'p15-danger').top, closeTo(_dangerTop, 0.01));
        expect(
          _rect(tester, 'p15-danger').height,
          closeTo(_dangerHeight, 0.01),
        );

        await disposeApp(tester);
      });
    }
  });

  group('P15 holds up at every width and text scale', () {
    const widths = <double>[320, 390, 430];
    const scales = <double>[1, 1.3];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('w$width · text scale $scale: no overflow, gutters hold', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpAt(tester, width: width, textScale: scale);

          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow or build error at w$width s$scale',
          );
          expect(find.text('Maya'), findsOneWidget);

          // OWNER ALIGNMENT: 20 px gutters on both sides for every band.
          for (final key in const <String>[
            'p15-hero',
            'p15-pip',
            'p15-danger',
          ]) {
            final rect = _rect(tester, key);
            expect(rect.left, closeTo(NestSpacing.padSide, 0.01), reason: key);
            expect(
              rect.right,
              closeTo(width - NestSpacing.padSide, 0.01),
              reason: key,
            );
          }
          final list = tester.getRect(find.byType(NestList));
          expect(list.left, closeTo(NestSpacing.padSide, 0.01));
          expect(list.right, closeTo(width - NestSpacing.padSide, 0.01));

          // The stat grid is `1fr 1fr 1fr` with a 10 gap — never a fixed tile
          // width — and all three tiles share one height.
          final quests = _rect(tester, 'p15-stat-quests');
          final coins = _rect(tester, 'p15-stat-coins');
          final days = _rect(tester, 'p15-stat-days');
          final tileWidth = (width - 2 * NestSpacing.padSide - 2 * 10) / 3;
          for (final rect in <Rect>[quests, coins, days]) {
            expect(rect.width, closeTo(tileWidth, 0.01));
            expect(rect.height, closeTo(quests.height, 0.01));
          }
          expect(coins.left - quests.right, closeTo(10, 0.01));
          expect(days.left - coins.right, closeTo(10, 0.01));

          // The 44 px parent floor survives the larger type.
          for (final key in const <String>[
            'p15-row-pin',
            'p15-row-quests',
            'p15-row-money',
            'p15-remove',
          ]) {
            expect(
              _rect(tester, key).height,
              greaterThanOrEqualTo(NestDevice.tapParent),
              reason: key,
            );
          }

          await disposeApp(tester);
        });
      }
    }

    testWidgets('the danger card scrolls into view at 320 · scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester, width: 320, textScale: 1.3);

      // The smallest surface plus the largest permitted type makes the column
      // taller than the viewport, so the last band must be scrollable to.
      await tester.scrollUntilVisible(
        find.byKey(const Key('p15-danger')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('p15-danger')), findsOneWidget);
      expect(find.text('Remove Maya from family'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the shell clamps the scaler to 1.3', (tester) async {
      await setUpTestScope();
      await _pumpAt(tester, textScale: 1.3);
      final at13 = _rect(tester, 'p15-hero');
      await disposeApp(tester);

      await setUpTestScope();
      await _pumpAt(tester, textScale: 2);
      final at20 = _rect(tester, 'p15-hero');
      await disposeApp(tester);

      expect(at20, at13, reason: 'the shell pins the scaler to 1.0–1.3');
    });
  });

  group('P15 accessibility beyond the copy', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: every icon/image node is labelled', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await setUpTestScope();
        await _pumpAt(tester, theme: theme);

        final images = _imageNodes(tester);
        // Pip art + the three list-row icons + the four tab-bar icons.
        expect(images.length, greaterThanOrEqualTo(8));
        for (final node in images) {
          expect(
            node.label.trim(),
            isNotEmpty,
            reason: 'image node ${node.id} must announce something',
          );
        }

        handle.dispose();
        await disposeApp(tester);
      });
    }

    // ORCHESTRATOR_NOTES.md item 1 (18:15 QA of cmp_light_1): the row
    // subtitles must render IN FULL — no early ellipsis — and the trailing
    // `Change ›` / `›` must take only its intrinsic width so the subtitle
    // column gets the rest.
    testWidgets('no list-row paragraph is ellipsised at 390', (tester) async {
      await setUpTestScope();
      await _pumpAt(tester);

      for (final key in const <String>[
        'p15-row-pin',
        'p15-row-quests',
        'p15-row-money',
      ]) {
        final paragraphs = find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(RichText),
        );
        expect(
          paragraphs,
          findsNWidgets(3),
          reason: '$key: title, subtitle, trailing',
        );
        for (final paragraph in paragraphs.evaluate()) {
          final render = paragraph.renderObject! as RenderParagraph;
          expect(
            render.didExceedMaxLines,
            isFalse,
            reason:
                '$key: "${render.text.toPlainText()}" must not be ellipsised',
          );
        }
      }

      // The trailing takes its intrinsic width, not a share of the row.
      final trailing = find.text('Change \u203A');
      final style = tester.widget<Text>(trailing).style!;
      final painter = TextPainter(
        text: TextSpan(text: 'Change \u203A', style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(
        tester.getSize(trailing).width,
        closeTo(painter.width, 0.01),
        reason: 'the trailing control keeps its intrinsic width',
      );

      await disposeApp(tester);
    });

    testWidgets('rows are kid-grade 60 px tall, the danger button is 48', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpAt(tester);

      // `.list-row` is 60 in the design — above both floors (44 parent,
      // 56 kid), so no screen-specific padding is needed.
      for (final key in const <String>[
        'p15-row-pin',
        'p15-row-quests',
        'p15-row-money',
      ]) {
        expect(
          _rect(tester, key).height,
          greaterThanOrEqualTo(NestDevice.tapKid),
        );
      }
      expect(
        _rect(tester, 'p15-remove').height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(_rect(tester, 'p15-remove').height, closeTo(48, 0.01));

      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the danger row opens the confirm', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await _pumpAt(tester);

      // The real effect of the semantics action is the modal, not a stub.
      tester.semantics.performAction(
        find.semantics.byLabel('Remove Maya from family'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove Maya?'), findsOneWidget);

      for (final label in <String>['Cancel', 'Remove']) {
        final node = tester.getSemantics(find.text(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must be operable by VoiceOver/TalkBack',
        );
        // The tap TARGET is the button, not the label inside it.
        expect(
          tester.getRect(find.widgetWithText(NestButton, label)).height,
          greaterThanOrEqualTo(NestDevice.tapParent),
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
