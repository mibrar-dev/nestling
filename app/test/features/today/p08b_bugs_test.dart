// P08b · Today empty — adversarial bug proofs (Stage 6, iterations 1–3).
//
// B01–B07 were found by this stage in iterations 1–2 and fixed by the
// builds; every proof below now runs LIVE and green:
//   B01  date line "Happy week: 4 days" on the fresh-nest state
//   B02  message named children in age order (CHILD ORDER ruling)
//   B03  whole body shifted +8 px by an inherited padding
//   B04  greeting clipped instead of wrapping at 1.3×
//   B05  "Browse ideas" underline painted ink instead of sky
//   B06  greeting clipped a long parent name (maxLines: 2)
//   B07  six long-named children lost the message tail at 1.3×
//        (maxLines: 5) — B06/B07 fixed by dropping the caps the design's
//        CSS never sets.
//
// Iteration 3 re-hunted the fixed tree at the extremes of the newly
// uncapped copy (30-char unbreakable parent name, six long-named children,
// 320 px × 1.3×, scroll + CTA) and found no new bug; that probe is pinned
// in the clean group below. Full report:
// `docs/screens/P08b/6_bugs.md`.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/views/quest_editor_view.dart';

import '../../test_scope.dart';

/// Widget tests render with Flutter's square-advance test font by default;
/// load the bundled Inter + Nunito weights so text measures like production
/// (the P08b greeting is Nunito Black 28: without it every y measurement
/// and every wrap assertion is meaningless).
Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await nunito.load();
}

Future<AppDatabase> _newFamilyScope() async {
  final db = await setUpTestScope(seedDemo: false);
  await Seed.newFamily(db);
  await GetIt.instance<AppSession>().refresh();
  return db;
}

Future<void> _insertChild(
  AppDatabase db,
  String id,
  String nickname,
  int age, {
  required DateTime createdAt,
}) async {
  await db
      .into(db.children)
      .insert(
        ChildrenCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          nickname: nickname,
          ageYears: Value(age),
          createdAt: Value(createdAt),
        ),
      );
}

Finder _addQuestButton() => find.ancestor(
  of: find.text('Add a quest'),
  matching: find.byType(NestButton),
);

void main() {
  setUpAll(_loadBundledFonts);

  // -------------------------------------------------------------------
  // Bug proofs — B01–B07 all live and green (fixed by the builds).
  // -------------------------------------------------------------------
  group('P08b bug proofs', () {
    testWidgets(
      '[P08b-B01] new-family date line reads A fresh nest, not Happy week',
      (tester) async {
        // `SEED=new_family` is the mandated P08b UI-check state: Sarah +
        // Maya + Leo, no quests. The body is the P08b empty design, so the
        // date line must be the design's "A fresh nest" — but the bloc
        // picks the suffix with `summaries.isEmpty`, and with children the
        // seed's happyDays (Maya 4) win: "Sat 3 Oct · Happy week: 4 days".
        await _newFamilyScope();
        await pumpAppRoute(tester, '/today-empty');

        expect(find.text('Your nest is quiet'), findsOneWidget);
        expect(
          find.text(
            '${formatDay(appNowUtc(), 'Europe/London')} · A fresh nest',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Happy week'), findsNothing);

        await disposeApp(tester);
      },
    );

    testWidgets('[P08b-B02] empty message names children in creation order', (
      tester,
    ) async {
      final db = await _newFamilyScope();
      // Added after Maya (9) and Leo (6), older than both: creation order
      // is Maya, Leo, Zara (CHILD ORDER ruling) — never age, never
      // alphabetical. `watchSummaries` used to re-sort summaries
      // eldest-first with a nickname tie-break, which rendered "Zara,
      // Maya and Leo"; the sort is gone.
      await _insertChild(
        db,
        'zara',
        'Zara',
        12,
        createdAt: Seed.utc(9, 19, 8).add(const Duration(minutes: 2)),
      );

      await pumpAppRoute(tester, '/today-empty');

      expect(
        find.text(
          'Add your first quest and Pip will start to hatch. '
          'Maya, Leo and Zara will see it straight away.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets(
      '[P08b-B03] empty greeting starts at the scroll origin, no 8 px pad',
      // fixed in iteration 2: no longer skipped.
      (tester) async {
        // P08b's `.greet` has no `padding-top` (that rule lives in P08's
        // local CSS only): the h1 line box starts at the status-bar bottom
        // (PNG light/dark: card top y=121 = 47 + 34 + 2 + 22 + 16). The
        // shared `_EmptyGreeting` reused P08's 8 px top padding, so the
        // greeting, card and tip all sit 8 px too low — a uniform vertical
        // shift, which the UI-verdict rule fails.
        await _newFamilyScope();
        await pumpAppRoute(tester, '/today-empty');

        expect(
          tester.getTopLeft(find.text('Good morning, Sarah')).dy,
          0,
          reason: 'h1 box starts at the scroll origin',
        );
        final card = find
            .ancestor(
              of: find.text('Your nest is quiet'),
              matching: find.byType(NestCard),
            )
            .first;
        expect(
          tester.getTopLeft(card).dy,
          74,
          reason: 'greeting 34 + 2 + 22, then the 16 px sibling margin',
        );

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P08b-B04] greeting wraps instead of clipping at text scale 1.3',
      // fixed in iteration 2: no longer skipped.
      (tester) async {
        // The design CSS leaves the h1 to wrap (no `white-space: nowrap` on
        // P08b — that is P08's rule). At 1.3× the app's `maxLines: 1`
        // ellipsis cuts the parent's name ("Good morning, Sara…").
        await _newFamilyScope();
        await pumpAppRoute(tester, '/today-empty');

        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final greeting = tester.renderObject<RenderParagraph>(
          find.text('Good morning, Sarah'),
        );
        expect(
          greeting.didExceedMaxLines,
          isFalse,
          reason: 'clipped greeting at 1.3× loses the parent name',
        );

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P08b-B05] Browse ideas underline paints sky, not ink',
      // fixed in iteration 2: no longer skipped.
      (tester) async {
        // The design PNG draws the underline in sky (pixel row y=512: all
        // (37,99,214)); the app paints it in the ambient ink (light
        // (30,27,58), dark (243,240,250)) because `decorationColor` is null
        // and the engine falls back to the default paragraph foreground.
        // Fix: set `decorationColor` to the sky token on the link style.
        await _newFamilyScope();
        await pumpAppRoute(tester, '/today-empty');

        final style = tester.widget<Text>(find.text('Browse ideas')).style!;
        expect(style.decoration, TextDecoration.underline);
        expect(style.color, NestColors.light.sky);
        expect(style.decorationColor, style.color);

        await disposeApp(tester);
      },
    );

    testWidgets('[P08b-B06] long parent name wraps at 320 px, no ellipsis', (
      tester,
    ) async {
      // The greeting caps at two lines. `Maximilian-Alexander` on a
      // 320 px device needs three even at scale 1.0 (and three at 1.3× on
      // 390), so the parent's own name is ellipsized. P08b's `.greet h1`
      // sets no nowrap/max-lines, so the CSS would wrap.
      final db = await _newFamilyScope();
      await db
          .update(db.members)
          .write(const MembersCompanion(name: Value('Maximilian-Alexander')));
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final greeting = tester.renderObject<RenderParagraph>(
        find.textContaining('Good morning'),
      );
      expect(
        greeting.didExceedMaxLines,
        isFalse,
        reason: 'a long parent name must wrap, not lose its tail',
      );

      await disposeApp(tester);
    });

    testWidgets('[P08b-B07] six long-named children keep every name at 1.3x', (
      tester,
    ) async {
      // At 1.3× the full message for six long-named children needs ~9
      // lines against the `maxLines: 5` cap, so the tail — the children
      // who "will see it straight away" — is ellipsized. At 1.0× the
      // same message fits exactly in 5 lines, so this is the
      // accessibility-scale case only.
      final db = await _newFamilyScope();
      final names = <String>[
        'Maximilian-Alexander',
        'Wilhelmina-Rose',
        'Bartholomew',
        'Persephone',
      ];
      for (var i = 0; i < names.length; i++) {
        await _insertChild(
          db,
          'kid$i',
          names[i],
          3 + i,
          createdAt: Seed.utc(9, 19, 11 + i),
        );
      }

      await pumpAppRoute(tester, '/today-empty');
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final message = tester.renderObject<RenderParagraph>(
        find.textContaining('will see it straight away'),
      );
      expect(message.didExceedMaxLines, isFalse);

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------
  // Hunted clean — regression pins for the areas probed without findings.
  // -------------------------------------------------------------------
  group('P08b probed clean (iterations 1–2)', () {
    testWidgets('/today shows the same fresh-nest empty state', (tester) async {
      // One empty state for the whole app (orchestrator item 1): the
      // simulation of a real family with no quests on /today, including the
      // fixed "A fresh nest" date line (B01's root cause was the shared
      // body/bloc predicate mismatch).
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today');

      expect(find.text('Your nest is quiet'), findsOneWidget);
      expect(
        find.text('${formatDay(appNowUtc(), 'Europe/London')} · A fresh nest'),
        findsOneWidget,
      );
      expect(find.text('Add a quest'), findsOneWidget);
      expect(find.textContaining('Happy week'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('a one-frame-apart double-tap opens one editor', (
      tester,
    ) async {
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today-empty');

      final center = tester.getCenter(_addQuestButton());
      await tester.tapAt(center);
      await tester.pump();
      await tester.tapAt(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QuestEditorView, skipOffstage: false), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('back from the editor returns to /today-empty', (tester) async {
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today-empty');

      await tester.tap(_addQuestButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/quest-editor');

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/today-empty');
      expect(find.text('Your nest is quiet'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('restart keeps the new-family empty state', (tester) async {
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today-empty');
      expect(find.text('Your nest is quiet'), findsOneWidget);

      // Tear the tree down and boot the app again over the same database.
      await disposeApp(tester);
      await tester.pumpWidget(Container());
      await pumpAppRoute(tester, '/today-empty');

      expect(find.text('Your nest is quiet'), findsOneWidget);
      expect(find.textContaining('Maya and Leo'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('Browse ideas exposes a semantics tap that navigates', (
      tester,
    ) async {
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today-empty');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final data = tester
          .getSemantics(find.bySemanticsLabel('Browse ideas'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.performAction(
        find.semantics.byLabel('Browse ideas'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/quests');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('320 px + 1.3x with both names: no clipping, no overflow', (
      tester,
    ) async {
      await _newFamilyScope();
      await pumpAppRoute(tester, '/today-empty');

      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final message = tester.renderObject<RenderParagraph>(
        find.textContaining('will see it straight away'),
      );
      expect(message.didExceedMaxLines, isFalse);

      await tester.scrollUntilVisible(
        find.text('Tip for new nests'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Tip for new nests'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('six children with long UK names keep the full message', (
      tester,
    ) async {
      final db = await _newFamilyScope();
      final names = <String>[
        'Maximilian-Alexander',
        'Wilhelmina-Rose',
        'Bartholomew',
        'Persephone',
      ];
      for (var i = 0; i < names.length; i++) {
        await _insertChild(
          db,
          'kid$i',
          names[i],
          3 + i,
          createdAt: Seed.utc(9, 19, 11 + i),
        );
      }

      await pumpAppRoute(tester, '/today-empty');

      final message = tester.renderObject<RenderParagraph>(
        find.textContaining('will see it straight away'),
      );
      expect(
        message.didExceedMaxLines,
        isFalse,
        reason: 'the sixth child must not be cut off',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('extreme names at 320 px + 1.3x: nothing clips, CTA works', (
      tester,
    ) async {
      // Iteration-3 verification of the uncapped copy at its limits: a
      // 30-char unbreakable parent name (broken by the engine), six
      // long-named children and the largest text scale on the smallest
      // width. The greeting and the whole message must render untruncated
      // and the CTAs must stay reachable.
      final db = await _newFamilyScope();
      await db
          .update(db.members)
          .write(
            const MembersCompanion(
              name: Value('Wolfeschlegelsteinhausenberger'),
            ),
          );
      final names = <String>[
        'Maximilian-Alexander',
        'Wilhelmina-Rose',
        'Bartholomew',
        'Persephone',
      ];
      for (var i = 0; i < names.length; i++) {
        await _insertChild(
          db,
          'kid$i',
          names[i],
          3 + i,
          createdAt: Seed.utc(9, 19, 8).add(Duration(minutes: 2 + i)),
        );
      }
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final greeting = tester.renderObject<RenderParagraph>(
        find.textContaining('Good morning'),
      );
      final message = tester.renderObject<RenderParagraph>(
        find.textContaining('will see it straight away'),
      );
      expect(greeting.didExceedMaxLines, isFalse);
      expect(message.didExceedMaxLines, isFalse);

      await tester.scrollUntilVisible(
        find.text('Tip for new nests'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Add a quest'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Add a quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/quest-editor');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: tab bar reaches the bottom edge, Today on', (
        tester,
      ) async {
        await _newFamilyScope();
        await pumpAppRoute(tester, '/today-empty', theme: theme);

        final screenBottom =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final bar = find.byType(NestTabBar);
        expect(bar, findsOneWidget);
        expect(tester.widget<NestTabBar>(bar).currentIndex, 0);
        final rect = tester.getRect(bar);
        expect(rect.bottom, screenBottom);
        expect(rect.height, NestDevice.tabH);

        final container = tester.widget<Container>(
          find.descendant(of: bar, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          theme == ThemeMode.light
              ? NestColors.light.surface
              : NestColors.dark.surface,
        );

        await disposeApp(tester);
      });
    }

    testWidgets('date line stays Europe/London across the BST end', (
      tester,
    ) async {
      final original = Seed.anchorOverride;
      addTearDown(() => Seed.anchorOverride = original);

      for (final (anchor, expected) in <(DateTime, String)>[
        // 24 Oct is still BST; the clocks go back at 01:00 UTC on 25 Oct.
        (DateTime.utc(2026, 10, 24), 'Sat 24 Oct · A fresh nest'),
        (DateTime.utc(2026, 10, 25), 'Sun 25 Oct · A fresh nest'),
      ]) {
        Seed.anchorOverride = anchor;
        final db = await setUpTestScope(seedDemo: false);
        await Seed.empty(db);
        // `Seed.empty` starts the trial at the real clock (not the anchor);
        // keep it active so the redirect does not send us to the paywall.
        await db
            .update(db.appState)
            .write(
              AppStateCompanion(
                trialStart: Value(anchor.subtract(const Duration(days: 1))),
              ),
            );
        await GetIt.instance<AppSession>().refresh();
        await pumpAppRoute(tester, '/today-empty');

        expect(find.text(expected), findsOneWidget);
        await disposeApp(tester);
        await tester.pumpWidget(Container());
      }
    });
  });
}
