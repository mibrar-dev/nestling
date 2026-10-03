// P09 · Quest editor — loading, failure and navigation states.
//
// `1_plan.md` §4 lists three states the in-memory Drift app scope can never
// reach on its own: the `?id=` fetch spinner (`QuestEditorView`'s
// `FutureBuilder`), the route's `_QuestLoadFailure` retry block and the
// `editorStatus == failure` toast. The scope's real repository always loads
// and always writes, so these tests decorate it with [_FaultyRepository]:
// reads still come from Drift (every database assertion below is real), only
// the behaviour under test is broken on purpose.
//
// Navigation is pinned by ROUTE, never by a screen's copy: `Save`, `Cancel`,
// `Delete` and the "Quest not found" back link must all land on
// `/quests`, and `Cancel` must pop (not `go`) when the editor was pushed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/views/quest_library_view.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// The real repository with injectable faults.
class _FaultyRepository implements QuestsRepository {
  _FaultyRepository(
    this._inner, {
    this.failFirstWatch = false,
    this.failWrites = false,
    this.holdGet = false,
    this.holdWrites = false,
    Object? writeError,
  }) : _writeError = writeError ?? StateError('disk full');

  final QuestsRepository _inner;

  /// The first `watchItems()` subscription errors instead of emitting.
  final bool failFirstWatch;

  /// `createQuest` / `updateQuest` / `deleteQuest` throw BEFORE touching
  /// Drift, so the stored rows are provably untouched.
  final bool failWrites;

  /// `getQuest` returns a future that never completes — the editor's
  /// `ConnectionState.waiting` branch.
  final bool holdGet;

  /// Writes park on a [Completer] the test releases with [releaseWrites] —
  /// the editor's in-flight `saving` state (BUG-P09-2's guard).
  final bool holdWrites;

  /// The error every write throws when [failWrites] is set. Defaults to an
  /// operational failure (`StateError('disk full')`, which the bloc surfaces
  /// verbatim); pass an [ArgumentError] to exercise the parent-safe mapping.
  final Object _writeError;

  int watchCalls = 0;
  final List<Quest> written = <Quest>[];
  final List<String> deleted = <String>[];
  final List<Completer<void>> _pending = <Completer<void>>[];

  /// Lets every parked write finish (the "user came back" half of the test).
  void releaseWrites() {
    for (final completer in _pending) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pending.clear();
  }

  /// Reads the row straight from Drift, bypassing the faults.
  Future<Quest?> stored(String id) => _inner.getQuest(id);

  @override
  Stream<List<Quest>> watchItems() {
    watchCalls++;
    if (failFirstWatch && watchCalls == 1) {
      return Stream<List<Quest>>.error(Exception('offline'));
    }
    return _inner.watchItems();
  }

  @override
  Future<Quest?> getQuest(String id) {
    if (holdGet) {
      return Completer<Quest?>().future;
    }
    return _inner.getQuest(id);
  }

  @override
  Future<void> createQuest(Quest quest) {
    written.add(quest);
    if (failWrites) {
      return Future<void>.error(_writeError);
    }
    if (holdWrites) {
      return _park();
    }
    return _inner.createQuest(quest);
  }

  @override
  Future<void> updateQuest(Quest quest) {
    written.add(quest);
    if (failWrites) {
      return Future<void>.error(_writeError);
    }
    if (holdWrites) {
      return _park();
    }
    return _inner.updateQuest(quest);
  }

  @override
  Future<void> deleteQuest(String id) {
    deleted.add(id);
    if (failWrites) {
      return Future<void>.error(_writeError);
    }
    if (holdWrites) {
      return _park();
    }
    return _inner.deleteQuest(id);
  }

  Future<void> _park() {
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<Quest>> getItems() => _inner.getItems();

  @override
  List<Quest> ideas() => _inner.ideas();

  // Added for the BUG-P09-1 interface addition (logic stage): pure
  // delegation, no fault injected — the coin rate is never faulty.
  @override
  Stream<int> watchCoinValuePencePerCoin() =>
      _inner.watchCoinValuePencePerCoin();
}

/// Replaces the registered repository with the decorated one. The real
/// instance is resolved first so the decorator delegates to the live,
/// in-memory database rather than a second copy of it.
Future<_FaultyRepository> _inject({
  bool failFirstWatch = false,
  bool failWrites = false,
  bool holdGet = false,
  bool holdWrites = false,
  Object? writeError,
}) async {
  final real = GetIt.instance<QuestsRepository>();
  await GetIt.instance.unregister<QuestsRepository>();
  final faulty = _FaultyRepository(
    real,
    failFirstWatch: failFirstWatch,
    failWrites: failWrites,
    holdGet: holdGet,
    holdWrites: holdWrites,
    writeError: writeError,
  );
  GetIt.instance.registerSingleton<QuestsRepository>(faulty);
  return faulty;
}

QuestSavePill _savePill(WidgetTester tester) =>
    tester.widget<QuestSavePill>(find.byType(QuestSavePill));

QuestIconTile _iconTile(WidgetTester tester, String key) => tester
    .widget<QuestIconTile>(find.byKey(ValueKey<String>('quest-icon-$key')));

Future<void> _scrollToDelete(WidgetTester tester) => tester.scrollUntilVisible(
  find.text('Delete quest'),
  200,
  scrollable: find.byType(Scrollable).first,
);

/// `insert` needs the tester for `runAsync`; a file-level late binding keeps
/// the helper a one-liner inside each test body.
late WidgetTester tester0;

void main() {
  group('P09 editor loading states', () {
    setUp(setUpTestScope);

    testWidgets('a pending ?id= fetch shows a spinner and no form', (
      tester,
    ) async {
      await _inject(holdGet: true);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');

      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(find.text('New quest'), findsNothing);
      expect(find.text('Edit quest'), findsNothing);
      expect(find.byType(QuestSavePill), findsNothing);
      expect(find.text('Hoover the stairs'), findsNothing);
      // Centred in the area under the status bar, like P10's spinner.
      final rect = tester.getRect(spinner);
      expect(rect.center.dx, closeTo(195, 1));
      await disposeApp(tester);
    });

    testWidgets('the first emission replaces the spinner with the form', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Edit quest'), findsOneWidget);
      expect(find.text('Hoover the stairs'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a failed route load shows the message and `Try again`', (
      tester,
    ) async {
      await _inject(failFirstWatch: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(QuestSavePill), findsNothing);
      expect(find.text('New quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('`Try again` re-requests and a healthy retry loads the form', (
      tester,
    ) async {
      final repository = await _inject(failFirstWatch: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.watchCalls, 1);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.watchCalls, 2);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('New quest'), findsOneWidget);
      expect(_savePill(tester).onPressed, isNotNull);
      await disposeApp(tester);
    });
  });

  group('P09 editor save failures', () {
    setUp(setUpTestScope);

    testWidgets('a failed create toasts the error and stays on the editor', (
      tester,
    ) async {
      final repository = await _inject(failWrites: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The parent is told, in place: a toast, not a silent no-op.
      expect(find.byType(NestToast), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(pushedPath(tester), QuestsRoutePaths.editor);
      expect(find.text('New quest'), findsOneWidget);

      // The attempt reached the repository…
      expect(repository.written, hasLength(1));
      expect(repository.written.single.title, 'Hoover the stairs');
      // …and nothing was stored, so the draft is still editable.
      final stored = await tester.runAsync(
        () => repository.stored(repository.written.single.id),
      );
      expect(stored, isNull);
      expect(_savePill(tester).onPressed, isNotNull);

      // Let the 3s toast timer expire before teardown.
      await tester.pump(const Duration(seconds: 4));
      await disposeApp(tester);
    });

    testWidgets('a failed update leaves the stored row untouched', (
      tester,
    ) async {
      final repository = await _inject(failWrites: true);
      final before = await tester.runAsync(() => repository.stored('q-hoover'));
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');

      await tester.enterText(
        find.byType(TextField).first,
        'Hoover the whole stairwell',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NestToast), findsOneWidget);
      expect(repository.written, hasLength(1));
      expect(repository.written.single.id, 'q-hoover');
      final after = await tester.runAsync(() => repository.stored('q-hoover'));
      expect(after?.title, before?.title);
      expect(after?.coins, before?.coins);
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await tester.pump(const Duration(seconds: 4));
      await disposeApp(tester);
    });

    testWidgets('a failed delete keeps the quest and the editor open', (
      tester,
    ) async {
      final repository = await _inject(failWrites: true);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await _scrollToDelete(tester);

      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(NestButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NestToast), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(repository.deleted, <String>['q-hoover']);
      expect(
        await tester.runAsync(() => repository.stored('q-hoover')),
        isNotNull,
      );
      expect(pushedPath(tester), QuestsRoutePaths.editor);
      expect(find.text('Edit quest'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await disposeApp(tester);
    });

    testWidgets('a programmer error shows the parent-safe copy only', (
      tester,
    ) async {
      // Review finding 4: an `ArgumentError` is a programmer error (today only
      // the repository's coins guard), so the toast carries
      // `QuestsBloc.saveFailedMessage` and the technical detail never reaches
      // the screen. Operational failures still show the repository message —
      // the test above pins that half.
      await _inject(
        failWrites: true,
        writeError: ArgumentError.value(
          9999,
          'coins',
          'Quest coins must be 1..100',
        ),
      );
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NestToast), findsOneWidget);
      expect(find.text(QuestsBloc.saveFailedMessage), findsOneWidget);
      expect(
        find.textContaining('Invalid argument'),
        findsNothing,
        reason: 'the parent never sees the raw exception',
      );
      expect(
        find.textContaining('1..100'),
        findsNothing,
        reason: 'nor the coins range detail',
      );
      expect(pushedPath(tester), QuestsRoutePaths.editor);
      // The guard is still released, so the parent can try again.
      expect(_savePill(tester).onPressed, isNotNull);

      await tester.pump(const Duration(seconds: 4));
      await disposeApp(tester);
    });

    testWidgets('`Keep it` never reaches the repository', (tester) async {
      final repository = await _inject();
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await _scrollToDelete(tester);

      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Keep it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repository.deleted, isEmpty);
      expect(find.text('Edit quest'), findsOneWidget);
      expect(
        await tester.runAsync(() => repository.stored('q-hoover')),
        isNotNull,
      );
      await disposeApp(tester);
    });
  });

  group('P09 editor save guard (BUG-P09-2)', () {
    setUp(setUpTestScope);

    testWidgets('the pill goes dead while the write is in flight', (
      tester,
    ) async {
      final repository = await _inject(holdWrites: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(_savePill(tester).onPressed, isNotNull);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // The write has not come back yet: the pill must not be tappable, or a
      // second tap dispatches a second create.
      expect(_savePill(tester).onPressed, isNull);
      expect(repository.written, hasLength(1));
      expect(
        find.text('New quest'),
        findsOneWidget,
        reason: 'no navigation yet',
      );

      repository.releaseWrites();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushedPath(tester), QuestsRoutePaths.library);
      await disposeApp(tester);
    });

    testWidgets('a second tap before the write lands dispatches nothing', (
      tester,
    ) async {
      final repository = await _inject(holdWrites: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pump();

      expect(
        repository.written,
        hasLength(1),
        reason: 'three taps, one dispatch (the guard is local, not the DB)',
      );

      repository.releaseWrites();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // …and exactly one row exists.
      final saved = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getItems(),
      );
      expect(
        saved!.where((quest) => quest.title == 'Hoover the stairs'),
        hasLength(1),
      );
      await disposeApp(tester);
    });

    testWidgets('a failed write releases the guard so the parent retries', (
      tester,
    ) async {
      final repository = await _inject(failWrites: true);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NestToast), findsOneWidget);
      expect(repository.written, hasLength(1));

      // `clearSaveGuard` runs before the toast: the pill is live again, or the
      // editor would be stuck with a dead Save and no way out.
      expect(
        _savePill(tester).onPressed,
        isNotNull,
        reason: 'the failed write must not leave the pill disabled',
      );
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        repository.written,
        hasLength(2),
        reason: 'the retry really reaches the repository again',
      );
      await tester.pump(const Duration(seconds: 4));
      await disposeApp(tester);
    });
  });

  group('P09 editor navigation', () {
    setUp(setUpTestScope);

    testWidgets('Cancel on the initial route goes to the library', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), QuestsRoutePaths.library);
      await disposeApp(tester);
    });

    testWidgets('Cancel on a pushed editor pops back to the library', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.library);
      // P10's `+ Add` pushes the editor, so `context.canPop()` is true and
      // Cancel must POP — a `go` here would strand the library's own state.
      await tester.tap(find.text('+ Add').first);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), QuestsRoutePaths.editor);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), QuestsRoutePaths.library);
      // Back on the library screen, editor gone. (Not `find.text('Quests')`:
      // the parent tab bar carries the same label.)
      expect(find.byType(QuestLibraryView), findsOneWidget);
      expect(find.byType(QuestSavePill), findsNothing);
      expect(find.text('New quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('a successful create lands on `/quests`', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Feed the cat');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), QuestsRoutePaths.library);
      await disposeApp(tester);
    });

    testWidgets('a confirmed delete lands on `/quests`', (tester) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await _scrollToDelete(tester);
      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(NestButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), QuestsRoutePaths.library);
      await disposeApp(tester);
    });

    testWidgets('`Back to quests` on an unknown id lands on `/quests`', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-nope');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Quest not found'), findsOneWidget);

      await tester.tap(find.text('Back to quests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), QuestsRoutePaths.library);
      await disposeApp(tester);
    });
  });

  group('P09 edit mode — stored data mapping', () {
    setUp(setUpTestScope);

    /// Inserts a quest straight into Drift so the editor can be opened on
    /// values the demo seed does not contain.
    Future<void> insert(Quest quest) => tester0.runAsync(
      () => GetIt.instance<QuestsRepository>().createQuest(quest),
    );

    testWidgets('a multi-day, alias-icon, Anyone quest pre-fills exactly', (
      tester,
    ) async {
      tester0 = tester;
      await insert(
        const Quest(
          id: 'q-probe',
          title: 'Water the plants',
          detail: 'Weekly · 8 coins',
          icon: 'bins', // the seed's spelling of the Bins tile
          coins: 8,
          repeatRule: 'weekly',
          days: '1,3,5', // CSV: Mon, Wed, Fri -> cells 0, 2, 4
          dueLabel: 'Before bed (7:30pm)',
          dueTimeLocal: '19:30',
          needsApproval: false,
          assigneeChildId: null, // "Anyone" must survive the roster default
          active: true,
        ),
      );

      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-probe');

      expect(find.text('Edit quest'), findsOneWidget);
      expect(find.text('Water the plants'), findsOneWidget);
      expect(find.text('= 8p at payout'), findsOneWidget);
      expect(
        tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected,
        <int>{0, 2, 4},
      );
      expect(_iconTile(tester, 'bin').selected, isTrue);
      expect(_iconTile(tester, 'hoover').selected, isFalse);
      expect(
        tester
            .widget<QuestPersonPill>(
              find.byKey(const ValueKey<String>('quest-assignee-anyone')),
            )
            .selected,
        isTrue,
        reason: 'a stored null assignee must not be overwritten by the roster',
      );
      expect(find.text('Before bed (7:30pm) ›'), findsOneWidget);
      expect(tester.widget<NestToggle>(find.byType(NestToggle)).value, isFalse);
      await disposeApp(tester);
    });

    testWidgets('a daily quest opens without the day row', (tester) async {
      tester0 = tester;
      await insert(
        const Quest(
          id: 'q-daily',
          title: 'Make the bed',
          detail: 'Daily · 5 coins',
          icon: 'bed',
          coins: 5,
          repeatRule: 'daily',
          days: '',
          dueLabel: 'Before school (8:30am)',
          dueTimeLocal: '08:30',
          needsApproval: true,
          assigneeChildId: 'maya',
          active: true,
        ),
      );

      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-daily');
      expect(find.byType(NestDayPicker), findsNothing);
      expect(
        tester
            .widget<NestSegmented<String>>(find.byType(NestSegmented<String>))
            .value,
        'daily',
      );
      expect(find.text('Before school (8:30am) ›'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the saved title is trimmed', (tester) async {
      tester0 = tester;
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(
        find.byType(TextField).first,
        '   Wipe the kitchen   ',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final saved = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getItems(),
      );
      expect(
        saved!.map((quest) => quest.title),
        contains('Wipe the kitchen'),
        reason: 'no leading or trailing spaces are stored',
      );
      await disposeApp(tester);
    });
  });

  group('P09 editor with no children (Seed.empty)', () {
    setUp(() async {
      // Onboarded parent, no children — an unseeded database would be
      // redirected to onboarding by the router guard.
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
    });

    testWidgets('`Anyone` is preselected and saved as a null assignee', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(
        tester
            .widget<QuestPersonPill>(
              find.byKey(const ValueKey<String>('quest-assignee-anyone')),
            )
            .selected,
        isTrue,
      );
      expect(find.byType(NestAvatar), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Take the bins');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), QuestsRoutePaths.library);
      final saved = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getItems(),
      );
      final created = saved!.firstWhere(
        (quest) => quest.title == 'Take the bins',
      );
      expect(created.assigneeChildId, isNull);
      expect(created.active, isTrue);
      await disposeApp(tester);
    });
  });
}
