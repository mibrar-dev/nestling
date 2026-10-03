// P09 · Quest editor — what the stored row does to the form (iteration 2).
//
// A quest row can hold values the editor's six tiles, three pills and two
// bounds were never designed around: a legacy icon key, an assignee whose
// child has been deleted on another screen, an archived row, an out-of-range
// coin count (see `quest_editor_coin_rules_test.dart`). Each of those is a
// *data* answer the editor has to give, and each one used to be either a
// silently rewritten row or a control that could not be operated:
//
//   BUG-P09-3  an icon key outside the six tiles lit no tile at all
//   BUG-P09-5  an assignee the roster no longer lists left every pill unselected
//              and kept the dangling id on save
//   review  9  editing an archived quest resurrected it (`active: true`)
//   review  5  the view wrote its own `detail` copy on every save
//
// The rows are planted straight into Drift because the repository is not the
// thing under test — the EDITOR's reading of them is.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
// Prefixed: `app_database.dart` also exports a generated `Quest` ROW class,
// which has no `detail` (it is computed on read). Every `Quest` below is the
// domain entity.
import 'package:nestling/features/quests/domain/entities/quest.dart' as domain;
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Plants a quest row directly in Drift so it can hold values the repository
/// would refuse to write (or that no seed produces).
Future<void> _plant(
  AppDatabase db, {
  required String id,
  String title = 'Planted quest',
  String icon = 'hoover',
  int coins = 15,
  String repeatRule = 'weekly',
  String days = '6',
  String? assigneeChildId = 'maya',
  bool active = true,
}) => db
    .into(db.quests)
    .insert(
      QuestsCompanion.insert(
        id: id,
        familyId: Seed.familyId,
        title: title,
        icon: Value(icon),
        coins: Value(coins),
        repeatRule: Value(repeatRule),
        days: Value(days),
        dueLabel: const Value('Before tea (5pm)'),
        dueTimeLocal: const Value('17:00'),
        needsApproval: const Value(true),
        assigneeChildId: Value(assigneeChildId),
        active: Value(active),
      ),
    );

QuestIconTile _tile(WidgetTester tester, String key) => tester
    .widget<QuestIconTile>(find.byKey(ValueKey<String>('quest-icon-$key')));

bool _pillSelected(WidgetTester tester, String id) => tester
    .widget<QuestPersonPill>(find.byKey(ValueKey<String>('quest-assignee-$id')))
    .selected;

Future<domain.Quest?> _stored(String id) =>
    GetIt.instance<QuestsRepository>().getQuest(id);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Legacy icon keys the family's own rows use, and the tile that now stands
/// for them (`_questIcons.aliases`).
const List<(String stored, String tile)> _iconAliases = <(String, String)>[
  ('sofa', 'bed'),
  ('plate', 'dishwasher'),
  ('bins', 'bin'),
  ('shirt', 'bin'),
  ('bag', 'bin'),
  ('leaf', 'paw'),
];

void main() {
  group('P09 icon aliases (BUG-P09-3)', () {
    setUp(setUpTestScope);

    for (final (stored, tile) in _iconAliases) {
      testWidgets('"$stored" lights the $tile tile and only that one', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await _plant(db, id: 'q-alias', icon: stored);
        await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-alias');

        expect(_tile(tester, tile).selected, isTrue, reason: '$stored → $tile');
        final selected = tester
            .widgetList<QuestIconTile>(find.byType(QuestIconTile))
            .where((candidate) => candidate.selected)
            .toList();
        expect(
          selected,
          hasLength(1),
          reason: 'a radiogroup with two highlighted tiles is worse than none',
        );
        await disposeApp(tester);
      });
    }

    testWidgets('saving without tapping keeps the stored icon key', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-alias', icon: 'shirt');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-alias');

      // The alias only decides which tile is HIGHLIGHTED — the row keeps its
      // own key unless the parent taps a tile.
      await _save(tester);
      expect((await tester.runAsync(() => _stored('q-alias')))?.icon, 'shirt');
      await disposeApp(tester);
    });

    testWidgets('tapping a tile is what rewrites the key', (tester) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-alias', icon: 'shirt');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-alias');

      await tester.tap(find.byKey(const ValueKey<String>('quest-icon-book')));
      await tester.pump();
      await _save(tester);
      expect((await tester.runAsync(() => _stored('q-alias')))?.icon, 'book');
      await disposeApp(tester);
    });

    testWidgets('the six tiles draw the design glyphs in design order', (
      tester,
    ) async {
      // ORCHESTRATOR_NOTES 17:57 item 1: the design's `.icons` is
      // Bed, Dishes, Hoover (selected), Book, Bins, Paw. The Dishes tile draws
      // the DS `basket` because the design's SVG IS a handled basket
      // (SHARED_REQUEST §4 still asks for `ic_dishwasher`).
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      final tiles = tester.widgetList<QuestIconTile>(
        find.byType(QuestIconTile),
      );
      expect(tiles.map((tile) => tile.label).toList(), <String>[
        'Bed',
        'Dishes',
        'Hoover',
        'Book',
        'Bins',
        'Paw',
      ]);
      expect(tiles.map((tile) => tile.icon).toList(), <String>[
        NestIcons.bed,
        NestIcons.basket,
        NestIcons.hoover,
        NestIcons.book,
        NestIcons.bin,
        NestIcons.paw,
      ]);
      expect(tiles.elementAt(2).selected, isTrue, reason: 'Hoover is default');
      await disposeApp(tester);
    });
  });

  group('P09 assignee integrity (BUG-P09-5)', () {
    setUp(setUpTestScope);

    testWidgets('an assignee that is no longer listed falls back to Anyone', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // The orphan a deleted child leaves behind: `assigneeChildId` has no
      // foreign key, so the id survives in the row.
      await _plant(db, id: 'q-orphan', assigneeChildId: 'nobody');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-orphan');

      expect(_pillSelected(tester, 'anyone'), isTrue);
      expect(_pillSelected(tester, 'maya'), isFalse);
      expect(_pillSelected(tester, 'leo'), isFalse);
      final selected = tester
          .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
          .where((pill) => pill.selected)
          .toList();
      expect(selected, hasLength(1), reason: 'exactly one pill is ever active');
      await disposeApp(tester);
    });

    testWidgets('saving an orphan clears the dangling id', (tester) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-orphan', assigneeChildId: 'nobody');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-orphan');

      await _save(tester);
      expect(
        (await tester.runAsync(() => _stored('q-orphan')))?.assigneeChildId,
        isNull,
      );
      await disposeApp(tester);
    });

    testWidgets('a listed assignee is never hijacked by the fallback', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-leo', assigneeChildId: 'leo');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-leo');

      expect(_pillSelected(tester, 'leo'), isTrue);
      expect(_pillSelected(tester, 'anyone'), isFalse);

      await _save(tester);
      expect(
        (await tester.runAsync(() => _stored('q-leo')))?.assigneeChildId,
        'leo',
        reason: 'the roster check must not rewrite a valid assignee',
      );
      await disposeApp(tester);
    });

    testWidgets('a new quest still defaults to the first child', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(
        _pillSelected(tester, 'maya'),
        isTrue,
        reason: 'creation order (Maya, Leo) — never alphabetical',
      );
      await disposeApp(tester);
    });

    testWidgets('the roster is live: a child added on another screen appears', (
      tester,
    ) async {
      // The roster moved out of the build into ONE `initState` subscription
      // (review finding 11), so the risk is a latched snapshot. It has to be a
      // live stream: a parent can add a child on the family screen while this
      // form is open (they come back through the sheet).
      final db = await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('Annabella'), findsNothing);

      await tester.runAsync(
        () => db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'child-new',
                familyId: Seed.familyId,
                nickname: 'Annabella',
                createdAt: Value(DateTime.utc(2026, 10, 4)),
              ),
            ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Annabella'), findsOneWidget);
      expect(
        tester
            .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
            .map((pill) => pill.label),
        <String>['Maya', 'Leo', 'Annabella', 'Anyone'],
        reason: 'creation order — the new child is last, before Anyone',
      );
      await disposeApp(tester);
    });
  });

  group('P09 archived rows and the stored detail', () {
    setUp(setUpTestScope);

    testWidgets('editing an archived quest does not resurrect it', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-archived', active: false);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-archived');

      await tester.enterText(find.byType(TextField).first, 'Still archived');
      await tester.pump();
      await _save(tester);

      final stored = await tester.runAsync(() => _stored('q-archived'));
      expect(stored?.title, 'Still archived', reason: 'the edit landed');
      expect(
        stored?.active,
        isFalse,
        reason: 'a title edit must not put an archived row back in the library',
      );
      await disposeApp(tester);
    });

    testWidgets('a new quest is stored active', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Fresh quest');
      await tester.pump();
      await _save(tester);

      final saved = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getItems(),
      );
      expect(
        saved!.firstWhere((quest) => quest.title == 'Fresh quest').active,
        isTrue,
      );
      await disposeApp(tester);
    });

    testWidgets('`detail` is the repository recomputation, not a stale copy', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-detail', title: 'Detail check', coins: 20);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-detail');

      await tester.tap(find.byKey(const ValueKey<String>('increase')));
      await tester.pump();
      await tester.tap(find.text('Once'));
      await tester.pump();
      await _save(tester);

      final stored = await tester.runAsync(() => _stored('q-detail'));
      expect(stored?.coins, 21);
      expect(stored?.repeatRule, 'once');
      expect(
        stored?.detail,
        'Once · 21 coins',
        reason: 'recomputed on read from the row, never a value the view wrote',
      );
      await disposeApp(tester);
    });

    testWidgets('switching to Once clears the stored day CSV', (tester) async {
      final db = await setUpTestScope();
      await _plant(db, id: 'q-days', days: '1,3,5');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-days');
      expect(
        tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected,
        <int>{0, 2, 4},
      );

      await tester.tap(find.text('Once'));
      await tester.pump();
      expect(find.byType(NestDayPicker), findsNothing);
      await _save(tester);

      expect(
        (await tester.runAsync(() => _stored('q-days')))?.days,
        '',
        reason: 'a non-weekly quest stores no day CSV',
      );
      await disposeApp(tester);
    });
  });
}
