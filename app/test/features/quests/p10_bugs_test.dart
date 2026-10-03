// P10 · Quest library — Stage 6 bug proofs (iteration 1).
//
// Every proof here fails on the iteration-1 tree (`de831ed`). Stage 3
// (TEST, iteration 2) removed the per-group `skip:` markers that the bug hunt
// had left in place — the loop forbids skipping tests — so each proof runs and
// each bug stays visible in `flutter test` until its fix lands. The geometry
// proofs run with the bundled Inter/Nunito faces loaded through `FontLoader`
// (the notes' "real-font geometry test") and pin items 1–5 of
// `ORCHESTRATOR_NOTES.md` at 390×844.
//
//   BUG-P10-1  major  same-frame double-tap stacks two /quest-editor routes
//   BUG-P10-2  major  .trow title/meta centred; design starts them at x+64
//   BUG-P10-3  minor  search + category chips are inert on the Active tab
//   BUG-P10-4  minor  16 px extra padding below the last row (48 vs design 32)
//   BUG-P10-5  major  search prefix icon is 48×48 at x+0; design is 24 at x+16
//   BUG-P10-6  major  segmented track 44/36 high; design .segmented is 52/44
//   BUG-P10-7  major  tab-bar content sits 34 px low; design bar top is y=726

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/views/quest_editor_view.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/quests_routes.dart';

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

void main() {
  setUpAll(_loadBundledFonts);

  group(
    'BUG-P10-1 — same-frame double-tap on a push site stacks two editors',
    () {
      testWidgets('+ Add pushes two /quest-editor routes', (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);

        // Two taps in the same frame: the second must be swallowed by a
        // per-frame push guard (the P08 `_PushOnce` pattern), not push again.
        final add = find.byType(QuestAddButton).first;
        await tester.tap(add);
        await tester.tap(add);
        await tester.pumpAndSettle();

        expect(
          find.byType(QuestEditorView, skipOffstage: false),
          findsOneWidget,
          reason: 'a double-tap must not stack two editor routes',
        );

        // The user-visible effect: one back press must leave the editor.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(currentPath(tester), QuestsRoutePaths.library);

        await disposeApp(tester);
      });

      testWidgets('an Active row pushes two /quest-editor routes', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);

        await tester.tap(find.text('Active (12)'));
        await tester.pumpAndSettle();

        final row = find.byType(QuestIdeaRow).first;
        await tester.tap(row);
        await tester.tap(row);
        await tester.pumpAndSettle();

        expect(
          find.byType(QuestEditorView, skipOffstage: false),
          findsOneWidget,
          reason: 'a double-tap must not stack two editor routes',
        );

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(currentPath(tester), QuestsRoutePaths.library);

        await disposeApp(tester);
      });
    },
  );

  group('BUG-P10-2 — .trow text is centred, the design starts it at x+64', () {
    testWidgets('title and meta left-align to the tile gap', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final card = tester.getRect(
        find.byKey(const ValueKey<String>('quest-idea-idea-bed')),
      );
      final title = tester.getRect(find.text('Make your bed'));
      final meta = tester.getRect(find.text('5 coins · Ages 4+ · Bedroom'));

      // `.trow { padding:12px; gap:12px }` + a 40 px tile: both lines start
      // at card left + 12 + 40 + 12 = 64 (HTML `.nm`/`.mt` are start-aligned).
      expect(title.left - card.left, closeTo(64, 2));
      expect(meta.left - card.left, closeTo(64, 2));

      await disposeApp(tester);
    });
  });

  group('BUG-P10-3 — the Active tab controls are inert', () {
    testWidgets('typing in the search field does not narrow the list', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Active (12)'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestIdeaRow), findsWidgets);

      // Fix-agnostic expectation: on the Active tab the visible search box
      // must either be hidden, or filter the list it sits above. Today it is
      // visible, accepts text, and changes nothing.
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields, 'bins');
        await tester.pump();

        // 'Empty the dishwasher' is the top alphabetical Active row and does
        // not match 'bins': a working search must remove it.
        expect(
          find.text('Empty the dishwasher'),
          findsNothing,
          reason: 'search text must narrow the visible list',
        );
      }

      await disposeApp(tester);
    });
  });

  group('BUG-P10-4 — end-of-list spacing is 48, the design says 32', () {
    testWidgets('16 px extra below the last row', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final lastRow = find.byKey(
        const ValueKey<String>('quest-idea-idea-reading'),
      );
      final gap =
          tester.getRect(find.byType(ListView)).bottom -
          tester.getRect(lastRow).bottom;

      // `.scroll { padding: 0 20px 32px }` and `.scroll > * + *` adds no
      // margin after the last child: the design's end-of-list gap is 32.
      expect(gap, NestSpacing.s8);

      await disposeApp(tester);
    });
  });

  group(
    'BUG-P10-5 — search prefix icon is 48×48, the design is 24 at x+16',
    () {
      testWidgets('the magnifier keeps the design slot', (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.library);

        // `NestTextField.search` renders the `.search` row itself (a 52-high
        // bordered box) with the editable inside it, so "the field" is the
        // NestTextField — Material's bare `TextField` is only the input box
        // that starts after the icon and the gap.
        final field = tester.getRect(find.byType(NestTextField));
        final icon = tester.getRect(
          find
              .descendant(
                of: find.byType(NestTextField),
                matching: find.byType(NestIcon),
              )
              .first,
        );

        // `.search { padding: 4px 16px; gap: 10px }` with a 24 px svg:
        // the glyph is 24×24 and starts 16 px inside the field.
        expect(icon.width, 24);
        expect(icon.height, 24);
        expect(icon.left - field.left, closeTo(16, 2));

        await disposeApp(tester);
      });
    },
  );

  group('BUG-P10-6 — segmented track is 44/36, the design is 52/44', () {
    testWidgets('track, thumb and the 16/0/16 chain below it', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final track = tester.getRect(find.byType(NestSegmented<String>));
      final ink = find.descendant(
        of: find.byType(NestSegmented<String>),
        matching: find.byType(Ink),
      );

      // `.segmented { padding: 4px }` around 44 px buttons (the CSS
      // `min-height:44px` beats `height:40px`): 4 + 44 + 4 = 52.
      expect(track.height, 52);
      expect(tester.getRect(ink.first).height, 44);

      // The note's items 3–4 chain: segmented → 16 → search → 0 → chips →
      // 16 → first card (`.scroll > * + *` minus the `.chipscroll` reset).
      // The field is the `NestTextField` box, not the editable inside it.
      final field = tester.getRect(find.byType(NestTextField));
      final chips = tester.getRect(find.byType(QuestCategoryChips));
      final card = tester.getRect(
        find.byKey(const ValueKey<String>('quest-idea-idea-bed')),
      );
      expect(field.top - track.bottom, NestSpacing.s4);
      expect(chips.top - field.bottom, 0);
      expect(card.top - chips.bottom, NestSpacing.s4);

      await disposeApp(tester);
    });
  });

  group('BUG-P10-7 — tab-bar content sits 34 px below the design', () {
    testWidgets('Today icon centre matches the design bar top', (tester) async {
      await setUpTestScope();
      // The design frame has the 34 px home strip below the 84 px bar, and a
      // real device reports both insets (P05's pattern).
      const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      final icon = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.home,
        ),
      );

      // `.tab-bar` top = 844 − 34 (home strip) − 84 (bar) = 726; content =
      // 726 + 8 (bar pad) + 2 (tab pad) + 12 (half icon) = 748.
      expect(icon.center.dy, closeTo(748, 2));

      await disposeApp(tester);
    });
  });

  group('BUG-P10-8 — the view silently degrades when its DI lookup fails', () {
    testWidgets('a lost repository renders the empty Ideas state', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = GetIt.instance<QuestsRepository>();
      await pumpAppRoute(tester, QuestsRoutePaths.library);
      expect(find.byType(QuestAddButton), findsWidgets);

      // Simulate a DI-order/build failure: the view's per-build
      // `isRegistered` guard turns a missing repository into an empty list.
      await GetIt.instance.unregister<QuestsRepository>();
      await repository.createQuest(
        const Quest(
          id: 'q-trigger',
          title: 'Trigger a rebuild',
          detail: 'Once · 5 coins',
          icon: 'leaf',
          coins: 5,
          repeatRule: 'once',
          days: '',
          dueLabel: null,
          needsApproval: false,
          assigneeChildId: null,
          active: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // `state.ideas` must come from the bloc/repository, not a live GetIt
      // probe: the screen must not swap 10 templates for "No ideas found".
      expect(find.byType(QuestAddButton), findsWidgets);

      await disposeApp(tester);
    });
  });
}
