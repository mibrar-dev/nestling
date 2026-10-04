// K09 · My jar — view tests over the in-memory Drift database.
//
// Scope (stage 2b, UI builder): the design's copy character-by-character, the
// navigation destinations, VoiceOver/TalkBack activation, the dark theme, the
// empty jar and the width × text-scale matrix. Design geometry against the
// real bundled Nunito metrics lives in the sibling
// `my_jar_view_geometry_test.dart` (isolated on purpose — loading the real
// faces moves every text metric on the screen, same reason as K03's
// `kid_home_geometry_test.dart`).
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_goal_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_history_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_illustration.dart';

import '../../test_scope.dart';

const String _route = '/my-jar';

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The list is lazy and the footer sits below the fold, so the scroll has to
/// move before the widget tree holds it.
Future<void> _reveal(WidgetTester tester, String text) async {
  final scroll = find.byType(Scrollable).first;
  for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(scroll, const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Hosts [JarHistoryCard] with no rows for the empty-state assertions — the
/// card is pure (theme tokens in, no bloc and no repository), so it renders
/// without `configureDependencies`, a database or a seeded child.
Widget _emptyJarHost() => MaterialApp(
  theme: NestTheme.light(),
  home: const Scaffold(
    body: Center(
      child: SizedBox(width: 350, child: JarHistoryCard(items: <JarEntry>[])),
    ),
  ),
);

void main() {
  group('K09 copy — character-exact from K09-jar.html', () {
    testWidgets('title, amount, weekday, goal, list and footer', (
      tester,
    ) async {
      await _pumpRoute(tester);

      // `K09-jar.html:47,68,69`
      expect(find.text('My jar'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('coming on Saturday'), findsOneWidget);

      // `:73,76,77,79,80`
      expect(find.text('Lego Friends set'), findsOneWidget);
      expect(find.text('£15.50'), findsOneWidget);
      expect(find.text('£9.49 to go'), findsOneWidget);
      expect(find.text('of £24.99'), findsOneWidget);
      expect(find.text('62% there!'), findsOneWidget);

      // `:82,100`
      expect(find.text('What went in'), findsOneWidget);
      await _reveal(tester, 'Mum keeps the real money');
      expect(
        find.text(
          'Mum keeps the real money. This jar just shows how well you have '
          'done.',
        ),
        findsOneWidget,
      );

      // The money-in rows the seed actually has (`1_plan.md` §b: DB wins over
      // the design's three example rows).
      expect(find.text('Pocket money'), findsWidgets);
      expect(find.text('Quest bonus'), findsWidgets);
      expect(find.text('+12p'), findsWidgets);
      // The seed's weekly base is 300p, so the row reads `+£3.00` — the
      // database is the source of truth, not the design's `+£3.80`
      // (DATA OVER MOCKS).
      expect(find.text('+£3.00'), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('the jar, progress and amount expose design labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);

      // `K09-jar.html:48`
      final jar = find.byType(JarIllustration);
      expect(jar, findsOneWidget);
      expect(
        tester.widget<JarIllustration>(jar).percentLabel,
        62,
        reason: '1550 of 2499 saved is 62% — the design figure',
      );

      // `£4.20 coming on Saturday` reads as one sentence (`1_plan.md` §e).
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .where((text) => text.isNotEmpty)
          .toList();
      expect(labels, contains('£4.20'));
      expect(labels, contains('coming on Saturday'));

      final progress = find.byType(NestProgress);
      expect(progress, findsOneWidget);
      expect(
        tester.widget<NestProgress>(progress).semanticLabel,
        '62% of the Lego Friends set saved',
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K09 navigation', () {
    testWidgets('back leaves the jar for the kid home', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('back POPS when the jar was pushed onto the stack', (
      tester,
    ) async {
      // Reached the way a child does: the K03 dock pushes /my-jar.
      await _pumpRoute(tester, route: '/kid-home');
      await tester.tap(find.text('My jar'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/my-jar');
      expect(find.byType(JarGoalCard), findsOneWidget);

      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });

  group('K09 accessibility actions (VoiceOver/TalkBack)', () {
    bool hasTap(WidgetTester tester, Finder finder) => tester
        .getSemantics(finder)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);

    testWidgets('back and the lock advertise a tap and drive the route', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);

      for (final label in <String>['Back', 'Grown-ups']) {
        final finder = find.bySemanticsLabel(label).first;
        expect(
          hasTap(tester, finder),
          isTrue,
          reason: '$label must expose SemanticsAction.tap',
        );
      }

      final lock = tester.getSemantics(
        find.bySemanticsLabel('Grown-ups').first,
      );
      lock.owner!.performAction(lock.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the history rows are display-only — no tap claimed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // A ledger row is not a control: it must not answer a tap (`1_plan.md`
      // §e), or a screen reader would promise an action that does nothing.
      final row = find.byType(JarHistoryCard);
      expect(row, findsOneWidget);
      expect(hasTap(tester, row), isFalse);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the amount and its weekday are one spoken label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel('£4.20 coming on Saturday'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K09 states', () {
    testWidgets('dark mode renders the same copy', (tester) async {
      await _pumpRoute(tester, theme: ThemeMode.dark);
      expect(find.text('My jar'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Lego Friends set'), findsOneWidget);
      expect(find.byType(JarIllustration), findsOneWidget);
      await disposeApp(tester);
    });

    // `1_plan.md` §d — the empty-jar row. A seeded demo family always has
    // money-in rows, and a childless one is redirected off `/my-jar` before
    // the card can render, so this is pumped straight at the widget: the card
    // is pure (tokens in, no bloc, no repo), which is the whole reason it was
    // split out of the view.
    testWidgets('an empty jar shows the one empty row, no amount', (
      tester,
    ) async {
      await tester.pumpWidget(_emptyJarHost());

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Finish a quest to fill your jar'), findsOneWidget);
      // No ledger amount — an empty row has nothing to add.
      expect(find.textContaining('+£'), findsNothing);
      expect(find.textContaining('+'), findsNothing);
      // It is still one design row: 60 tall inside the card's 3 px borders.
      expect(tester.getSize(find.byType(JarHistoryCard)).height, 66);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the empty row claims no tap action', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_emptyJarHost());

      expect(
        tester
            .getSemantics(find.byType(JarHistoryCard))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('ORCHESTRATOR_NOTES 18:47 — mandatory history glyphs', () {
    // "Quest-bonus rows must use questIconFor(key, audience: NestAudience.kid),
    // not the parent NestIcons.questBins." (docs/screens/K09/ORCHESTRATOR_NOTES.md)
    //
    // The ledger row carries only a free-text `note` (there is no questId on
    // `ledger_entries`), so the row's own icon key has to be resolved from the
    // quest the note names. This proof reads the seeded quests straight out of
    // the database (data over mocks) and demands the rendered disc glyph be the
    // KID glyph of that quest — not one glyph for every quest bonus.
    testWidgets(
      "K09-BUG-3: a quest-bonus row shows the quest's own kid glyph",
      (tester) async {
        final db = GetIt.instance<AppDatabase>();
        final quests = await db.select(db.quests).get();
        final keyForTitle = <String, String>{
          for (final quest in quests) quest.title: quest.icon,
        };

        await _pumpRoute(tester);

        for (final title in <String>[
          'Put the bins out',
          'Hoover the stairs',
          'Tidy your bedroom',
          'Help with the washing',
        ]) {
          final key = keyForTitle[title];
          expect(key, isNotNull, reason: '$title is a seeded quest');

          final row = find
              .ancestor(
                of: find.text(title).first,
                matching: find.byType(Container),
              )
              .first;
          final icon = find.descendant(
            of: row,
            matching: find.byType(NestIcon),
          );
          expect(icon, findsOneWidget, reason: '$title has one disc glyph');
          expect(
            tester.widget<NestIcon>(icon).assetName,
            questIconFor(key!, audience: NestAudience.kid),
            reason:
                '"$title" is the "$key" quest; the jar must show its kid '
                'glyph, not the bins glyph it uses for every bonus',
          );
        }
        await disposeApp(tester);
      },
    );

    // "The pocket-money and gift glyphs are being added on shared/jar_glyphs
    // (NestIcons.jarPocketMoney / jarGift). Use them once on main."
    //
    // BLOCKED: neither constant exists on this branch yet
    // (`grep -rn "jarPocketMoney\|jarGift" app/` → no hits), so a test naming
    // them would not compile. Recorded in 3_test.md instead. Once main lands
    // them, this is the proof:
    //
    //   expect(tester.widget<NestIcon>(icon).assetName,
    //       NestIcons.jarPocketMoney);  // row 1, "Pocket money"
    //   expect(tester.widget<NestIcon>(icon).assetName,
    //       NestIcons.jarGift);         // "Birthday money" (row 6)
  });

  group('ORCHESTRATOR_NOTES 18:47 — "coming on Saturday" colour', () {
    // The note: "check that the 'coming on Saturday' colour matches the HTML
    // (the app looks lighter)". It does not match, and the PNG says why:
    // `.k9-when` is a bare `<p class="kid-body k9-when">` and NEITHER
    // `.kid-body` (components.css:35) NOR `.k9-when` (K09-jar.html:23) sets a
    // colour, so it INHERITS `.screen { color: var(--ink) }`
    // (components.css:23) — full ink, not `--ink-2`. Measured off the design
    // PNGs: the line is 4001 px of exactly #1E1B3A (light) / #F3F0FA (dark),
    // while the `.kcap` goal captions on the same screen measure exactly
    // #4A4668 / #C9C4DC — the ink-2 the app wrongly uses here.
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'K09-BUG-2: the payout weekday is --ink, not --ink-2, in ${theme.name}',
        (tester) async {
          await _pumpRoute(tester, theme: theme);

          final when = tester.widget<Text>(find.text('coming on Saturday'));
          final tokens = Theme.of(
            tester.element(find.text('coming on Saturday')),
          ).extension<NestTokens>()!;

          expect(
            when.style?.color,
            tokens.ink,
            reason:
                "the design inherits .screen's color: var(--ink); --ink-2 "
                'renders visibly lighter (design PNG: 4001 px of exactly '
                '#1E1B3A / #F3F0FA on this line)',
          );
          // And it is genuinely NOT the ink-2 the app used to pass, so this
          // proof cannot pass by accident on a theme where they coincide.
          expect(
            when.style?.color == tokens.ink2,
            isFalse,
            reason: 'the two tokens differ in ${theme.name}',
          );
          await disposeApp(tester);
        },
      );
    }
  });

  group('K09 layout matrix', () {
    for (final width in <double>[320, 390, 430]) {
      for (final textScale in <double>[1, 1.3]) {
        for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            'no overflow at ${width}w / ${textScale}x in ${theme.name}',
            (tester) async {
              await _pumpRoute(
                tester,
                width: width,
                textScale: textScale,
                theme: theme,
              );
              await _reveal(tester, 'Mum keeps the real money');
              expect(tester.takeException(), isNull);
              expect(find.text('My jar'), findsOneWidget);
              expect(find.byType(JarGoalCard), findsOneWidget);
              expect(find.byType(JarHistoryCard), findsOneWidget);
              await disposeApp(tester);
            },
          );
        }
      }
    }
  });
}
