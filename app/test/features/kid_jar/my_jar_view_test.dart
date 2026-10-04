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

import 'package:drift/drift.dart' show Value;
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

/// Pumps the app over a freshly seeded in-memory database and returns it, so
/// a proof can read the rows the screen renders out of the SAME instance the
/// app is running on instead of whatever a previous test happened to leave
/// behind in GetIt. [onSeededDb] runs after the seed and before the first
/// frame, for the tests that need the database to differ from the seed.
Future<AppDatabase> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
  Future<void> Function(AppDatabase db)? onSeededDb,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await onSeededDb?.call(db);
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
  return db;
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

    // K09-BUG-4 (review finding 2): a payer can credit past the target (P13's
    // payout), so the card itself must clamp `remainingPence` — the seed's
    // 1550/2499 never reaches this, the direct widget pump does.
    testWidgets('an over-saved goal reads £0.00 to go, never a positive gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: JarGoalCard(
                  title: 'Lego Friends set',
                  savedPence: 3150,
                  targetPence: 2499,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('£31.50'), findsOneWidget);
      expect(find.text('100% there!'), findsOneWidget);
      expect(find.text('£0.00 to go'), findsOneWidget);
      expect(find.text('£6.51 to go'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('K09 database-driven goal, headings and the hero line', () {
    // The goal figures are DATA, not design mocks: the child's goal row is
    // what the card, the progress bar, the jar fill and the announced
    // percentage all read. The seed stops at 1550/2499 (62 %), so the
    // finished end of the range is written straight into the database and the
    // whole screen is asked what it says (K09-BUG-4's screen-level shape).
    testWidgets('a goal reached in the database reads 100% all the way up', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(
        tester,
        onSeededDb: (db) async {
          await (db.update(db.savingsGoals)
                ..where((g) => g.id.equals('goal-lego')))
              .write(const SavingsGoalsCompanion(savedPence: Value(2499)));
        },
      );

      expect(find.text('£24.99'), findsOneWidget);
      expect(find.text('£0.00 to go'), findsOneWidget);
      expect(find.text('100% there!'), findsOneWidget);
      expect(
        tester.widget<NestProgress>(find.byType(NestProgress)).fraction,
        closeTo(1, 0.0001),
      );
      expect(
        tester
            .widget<JarIllustration>(find.byType(JarIllustration))
            .fillFraction,
        closeTo(1, 0.0001),
        reason: 'a full jar must fill to the top of the interior',
      );
      expect(
        find.bySemanticsLabel('100% of the Lego Friends set saved'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    // `Seed.empty` proves the CHILDLESS jar; this proves the child who has money
    // in the jar but no savings goal at all — the other real shape the screen
    // has to survive, driven by the database rather than a fake.
    testWidgets('a child with money in but no savings goal still gets a jar', (
      tester,
    ) async {
      await _pumpRoute(
        tester,
        onSeededDb: (db) async {
          await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
            const AppStateCompanion(activeChildId: Value('leo')),
          );
        },
      );

      // Leo is owed £2.10 (150 base + 35 + 25 quest bonuses, `Seed.demo`).
      expect(find.text('£2.10'), findsOneWidget);
      expect(find.text('coming on Saturday'), findsOneWidget);
      // No goal means no card, no bar, no "to go" line and an empty jar — but
      // the hero, the weekday, the list and the footer all stay.
      expect(find.byType(JarGoalCard), findsNothing);
      expect(find.byType(NestProgress), findsNothing);
      expect(find.textContaining('to go'), findsNothing);
      expect(
        tester
            .widget<JarIllustration>(find.byType(JarIllustration))
            .fillFraction,
        0,
      );
      expect(find.text('What went in'), findsOneWidget);
      expect(
        find.text('+£1.50'),
        findsWidgets,
        reason: "Leo's weekly base, this week and last (both 150p)",
      );
      expect(find.byType(JarHistoryCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    // The title is the screen's only heading: a screen reader must be able to
    // jump straight to it, and no other node on K09 may claim to be one.
    testWidgets('the title is the only announced heading', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);

      final title = tester.getSemantics(find.text('My jar')).getSemanticsData();
      expect(title.label, 'My jar');
      expect(title.flagsCollection.isHeader, isTrue);
      expect(
        tester
            .getSemantics(find.text('What went in'))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isFalse,
        reason: 'the section label is a plain kid-title, not a heading node',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    // The hero is the one line that must never wrap or truncate: 40 px Nunito
    // at 1.3x on the narrowest supported screen is exactly where an
    // ellipsised `£4.20` would hide the amount. `FittedBox(scaleDown)` is the
    // sanctioned answer (`1_plan.md` §e).
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'the hero amount stays whole at 320 px / 1.3x in ${theme.name}',
        (tester) async {
          await _pumpRoute(tester, width: 320, textScale: 1.3, theme: theme);

          expect(tester.takeException(), isNull);
          final amount = tester.widget<Text>(find.text('£4.20'));
          expect(amount.maxLines, 1);
          expect(amount.softWrap, isFalse);
          expect(amount.overflow, isNull, reason: 'no ellipsis on the hero');
          expect(find.textContaining('…'), findsNothing);

          // Scale-down, not clip: the hero's own fitted box stays inside the
          // gutters. (Scoped to the amount — `SvgPicture` on the goal card
          // wraps itself in a `FittedBox` too, so `find.byType` is ambiguous.)
          final heroBox = find.ancestor(
            of: find.text('£4.20'),
            matching: find.byType(FittedBox),
          );
          expect(heroBox, findsOneWidget);
          expect(tester.widget<FittedBox>(heroBox).fit, BoxFit.scaleDown);
          expect(
            tester.getRect(heroBox).width,
            lessThanOrEqualTo(320 - 2 * NestSpacing.padSide),
          );
          await disposeApp(tester);
        },
      );
    }
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
    //
    // The database it reads is the one `_pumpRoute` returns — the same
    // instance the app runs on. Reading GetIt *before* the pump only worked
    // while an earlier test in this file left a seeded registration behind,
    // so this proof died the moment the loop ran it on its own, the way bug
    // proofs are verified (`--plain-name`):
    //   Bad state: GetIt: Object/factory with type AppDatabase is not
    //   registered inside GetIt.            (review finding 3)
    testWidgets(
      "K09-BUG-3: a quest-bonus row shows the quest's own kid glyph",
      (tester) async {
        final db = await _pumpRoute(tester);
        final quests = await db.select(db.quests).get();
        final keyForTitle = <String, String>{
          for (final quest in quests) quest.title: quest.icon,
        };

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
    // Main landed both (`app/test/design_system/shared_jar_glyphs_test.dart`):
    // pocket money is `NestIcons.jarPocketMoney`, the design's exact coin-slot
    // mark (`K09-jar.html:85`), and the gift needs no new file because
    // `NestIcons.gift` already draws `:95` exactly. This reads the rendered
    // disc of both seeded rows.
    testWidgets('K09-BUG-3b: pocket-money and gift rows use the shared jar '
        'glyphs', (tester) async {
      await _pumpRoute(tester);

      String rowGlyph(String title) {
        final row = find
            .ancestor(
              of: find.text(title).first,
              matching: find.byType(Container),
            )
            .first;
        return tester
            .widget<NestIcon>(
              find.descendant(of: row, matching: find.byType(NestIcon)),
            )
            .assetName;
      }

      expect(
        rowGlyph('Pocket money'),
        NestIcons.jarPocketMoney,
        reason:
            "row 1 is the design's geometric coin-slot mark, not `poundCoin`",
      );
      // `Birthday money` (row 6) sits below the design's fold.
      await _reveal(tester, 'Birthday money');
      expect(
        rowGlyph('Birthday money'),
        NestIcons.gift,
        reason: 'the design gift (`K09-jar.html:95`) is the shared gift asset',
      );
      await disposeApp(tester);
    });

    // The pure mapping under those discs: every entry type resolves to its
    // design glyph, and an unknown quest key falls back to the resolver's own
    // `questCard` — never to the parent bins glyph the screen used before
    // K09-BUG-3.
    test('jarEntryGlyph maps every type and falls back like the resolver', () {
      expect(
        jarEntryGlyph('quest_bonus', 'hoover'),
        questIconFor('hoover', audience: NestAudience.kid),
      );
      expect(jarEntryGlyph('quest_bonus', 'bins'), NestIcons.questBinsKid);
      expect(jarEntryGlyph('quest_bonus', ''), NestIcons.questCard);
      expect(jarEntryGlyph('quest_bonus', 'nonsense'), NestIcons.questCard);
      expect(jarEntryGlyph('gift', ''), NestIcons.gift);
      expect(jarEntryGlyph('weekly_base', ''), NestIcons.jarPocketMoney);
      expect(jarEntryGlyph('anything_else', ''), NestIcons.jarPocketMoney);
    });
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
