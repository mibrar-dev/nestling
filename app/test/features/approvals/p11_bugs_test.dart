// P11 · Approvals — Stage 6 bug proofs (iteration 1).
//
// Every proof in this file FAILS on the iteration-1 tree (checkpoint
// `ba946d7`). Each group is marked `skip: '<bug id>'` so the suite stays
// green until the fix lands (the TEST stage removes the markers and runs the
// proofs — the P10 iteration-1 convention). Nothing in `lib/` was touched by
// this stage; the fixes are described in `docs/screens/P11/6_bugs.md`.
//
//   BUG-P11-1  major  rapid repeat decisions double-credit quest bonuses
//                     (concurrent `approve()` / `approveAll()` writes)
//   BUG-P11-2  major  "Not yet" overwrites an approved decision and the
//                     quest_bonus ledger row stays
//   BUG-P11-3  minor  BST spring-forward mislabels "Yesterday" as "Today"
//   BUG-P11-4  minor  both card buttons show the spinner, only the tapped one
//                     should (plan §1)
//
// Evidence and proposed fixes: docs/screens/P11/6_bugs.md. Seeds are pinned
// to Sat 3 Oct 2026 by test/flutter_test_config.dart; the seeded `quest_bonus`
// rows total 300p (9 rows) before any approval.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/views/approvals_view.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_time.dart';

import '../../test_scope.dart';

/// Seeded `quest_bonus` rows and their total before any approval (Maya 6 +
/// Leo 3: 12+68+12+40+40+28+40+35+25).
const int _seedBonusRows = 9;
const int _seedBonusPence = 300;

/// `quest_bonus` ledger rows, optionally filtered to one quest note.
Future<List<LedgerEntry>> _bonusRows(AppDatabase db, {String? note}) async {
  final rows = await (db.select(
    db.ledgerEntries,
  )..where((r) => r.type.equals('quest_bonus'))).get();
  if (note == null) return rows;
  return rows.where((r) => r.note == note).toList();
}

/// Bounded pump loop (the running app always schedules frames, so
/// `pumpAndSettle` never converges here).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

/// One completion row by id.
Future<QuestCompletion> _completion(AppDatabase db, int id) =>
    (db.select(db.questCompletions)..where((c) => c.id.equals(id))).getSingle();

void main() {
  group('BUG-P11-1 — rapid repeat decisions double-credit quest bonuses', () {
    // Deterministic repository proof. `approve()` reads the row and checks
    // `status == 'done_pending'` OUTSIDE its transaction, so two in-flight
    // calls both pass the guard and each inserts a `quest_bonus` row.
    test(
      'concurrent approve() calls both credit the same completion',
      () async {
        final db = await setUpTestScope();
        final impl = ApprovalsRepositoryImpl(db: db);
        final items = await impl.getItems();
        final id = items
            .firstWhere((i) => i.questTitle == 'Empty the dishwasher')
            .completionId;

        await Future.wait(<Future<void>>[impl.approve(id), impl.approve(id)]);

        final rows = await _bonusRows(db, note: 'Empty the dishwasher');
        expect(
          rows,
          hasLength(1),
          reason:
              'one completion must credit exactly one quest_bonus row; '
              'found ${rows.length} (duplicate money)',
        );
      },
    );

    // Same race through `approveAll()`, which re-selects the pending set
    // and calls `approve()` per row with no claim/transaction.
    test('concurrent approveAll() calls duplicate bonus rows', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);

      await Future.wait(<Future<void>>[impl.approveAll(), impl.approveAll()]);

      final rows = await _bonusRows(db);
      final total = rows.fold<int>(0, (sum, r) => sum + r.amountPence);
      expect(
        rows,
        hasLength(_seedBonusRows + 3),
        reason: '3 seeds were pending; approveAll must credit each once',
      );
      expect(
        total,
        _seedBonusPence + 30,
        reason: 'each pending completion credits its own coins exactly once',
      );
    });

    // Real-database reachability: two taps on the bottom CTA before a frame
    // renders both reach `_onApproveAll` (bloc 9's default event transformer
    // is concurrent, and the busy state only paints on the next frame).
    testWidgets('same-frame double-tap on "Approve all" duplicates credits', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/approvals');

      final cta = find.byKey(const ValueKey<String>('p11_approve_all'));
      await tester.tap(cta);
      await tester.tap(cta);
      await _settle(tester);

      final rows = await _bonusRows(db);
      final total = rows.fold<int>(0, (sum, r) => sum + r.amountPence);
      expect(
        total,
        _seedBonusPence + 30,
        reason:
            'approving every pending quest once must add exactly 30p; '
            'found ${total - _seedBonusPence}p (duplicate credits)',
      );

      await disposeApp(tester);
    });

    // The same reachability for a single card, proven at the bloc boundary
    // with a counting stub (the repository is proven above).
    testWidgets('same-frame double-tap on Approve dispatches two writes', (
      tester,
    ) async {
      final repo = _CountingApprovalsRepository();
      final bloc = ApprovalsBloc(repository: repo)
        ..add(const ApprovalsLoadRequested());
      await _pumpApprovals(tester, bloc);
      await _settle(tester);

      final card = _cardFor('Maya · Empty the dishwasher');
      final approve = find.descendant(
        of: card,
        matching: find.widgetWithText(NestButton, 'Approve'),
      );
      await tester.tap(approve);
      await tester.tap(approve);
      await _settle(tester);

      expect(
        repo.approveCalls,
        1,
        reason:
            'two same-frame taps are one decision; the second must be '
            'absorbed (found ${repo.approveCalls} approve calls)',
      );

      await disposeApp(tester);
    });
  });

  group('BUG-P11-2 — "Not yet" overwrites an approved decision', () {
    // `markNotYet()` writes `status = 'not_yet'` with no `done_pending`
    // guard (and no transaction), so a stale/concurrent "Not yet" flips an
    // already-approved completion while its ledger bonus stays.
    test('markNotYet() after approve() keeps the bonus with not_yet', () async {
      final db = await setUpTestScope();
      final impl = ApprovalsRepositoryImpl(db: db);
      final items = await impl.getItems();
      final id = items
          .firstWhere((i) => i.questTitle == 'Empty the dishwasher')
          .completionId;

      await impl.approve(id);
      await impl.markNotYet(id);

      final row = await _completion(db, id);
      final rows = await _bonusRows(db, note: 'Empty the dishwasher');
      expect(
        row.status,
        'approved',
        reason:
            '"Not yet" must not overwrite a decision that was already made '
            '(status is ${row.status}); the bonus row is still there '
            '(${rows.length})',
      );
    });

    // Real-screen reachability: tapping Approve and then Not yet before a
    // frame renders (both buttons are still enabled) leaves the completion
    // `not_yet` AND the 15p credit in the ledger.
    testWidgets('same-frame Approve then Not yet leaves not_yet + bonus', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/approvals');

      final card = _cardFor('Maya · Empty the dishwasher');
      final approve = find.descendant(
        of: card,
        matching: find.widgetWithText(NestButton, 'Approve'),
      );
      final notYet = find.descendant(
        of: card,
        matching: find.widgetWithText(NestButton, 'Not yet'),
      );
      await tester.tap(approve);
      await tester.tap(notYet);
      await _settle(tester);

      final row = await _completion(db, 1);
      final rows = await _bonusRows(db, note: 'Empty the dishwasher');
      final consistent =
          (row.status == 'approved' && rows.length == 1) ||
          (row.status == 'not_yet' && rows.isEmpty);
      expect(
        consistent,
        isTrue,
        reason:
            'the two decisions are mutually exclusive and must stay '
            'consistent with the ledger (status=${row.status}, '
            'bonus rows=${rows.length})',
      );

      await disposeApp(tester);
    });
  });

  group('BUG-P11-3 — BST spring-forward mislabels Yesterday as Today', () {
    // `approvalDayLabel` compares calendar days with
    // `DateTime(y, m, d).difference(...).inDays` — LOCAL midnights. The UK
    // spring-forward (29 Mar 2026, 01:00 GMT → 02:00 BST) makes the
    // 29→30 Mar midnight span 23h, which truncates to 0 days. Hosts must run
    // Europe/London (this repo's machine and every UK device) for the proof
    // to reproduce.
    test('a completion from yesterday renders as Today', () {
      expect(
        approvalDayLabel(
          // London wall date Sun 29 Mar 2026 (after the jump).
          createdAtUtc: DateTime.utc(2026, 3, 29, 18),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 3, 30, 12),
        ),
        'Yesterday',
      );
    });

    test('a completion from two days back renders as Yesterday', () {
      expect(
        approvalDayLabel(
          // London wall date Sat 28 Mar 2026 (before the jump).
          createdAtUtc: DateTime.utc(2026, 3, 28, 18),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 3, 30, 12),
        ),
        'Sat 28 Mar',
      );
    });
  });

  group('BUG-P11-4 — both card buttons show the spinner', () {
    // Plan §1: `loading: true only if THIS button was tapped`. The state only
    // tracks `busyIds`, so the untapped button spins and disables too.
    testWidgets('Not yet also loads while only Approve was tapped', (
      tester,
    ) async {
      final repo = _CountingApprovalsRepository(gated: true);
      final bloc = ApprovalsBloc(repository: repo)
        ..add(const ApprovalsLoadRequested());
      await _pumpApprovals(tester, bloc);
      await _settle(tester);

      final card = _cardFor('Maya · Empty the dishwasher');
      await tester.tap(
        find.descendant(of: card, matching: find.text('Approve')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final notYet = tester.widget<NestButton>(
        find.byKey(const ValueKey<String>('p11_not_yet_1')),
      );
      expect(
        notYet.loading,
        isFalse,
        reason: 'only the tapped Approve button may show the spinner',
      );

      repo.release();
      await _settle(tester);
      await disposeApp(tester);
    });
  });
}

/// Pumps a minimal app around [ApprovalsView] with [bloc] provided.
Future<void> _pumpApprovals(WidgetTester tester, ApprovalsBloc bloc) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      home: BlocProvider<ApprovalsBloc>.value(
        value: bloc,
        child: const ApprovalsView(),
      ),
    ),
  );
  await tester.pump();
}

/// Stub repository: counts writes so the bloc boundary can be asserted, and
/// can hold `approve` open to keep the card busy.
class _CountingApprovalsRepository implements ApprovalsRepository {
  _CountingApprovalsRepository({this._gated = false});

  final bool _gated;
  final Completer<void> _gate = Completer<void>();

  int approveCalls = 0;
  int approveAllCalls = 0;

  static final List<Approval> _items = <Approval>[
    Approval(
      id: '1',
      title: 'Empty the dishwasher',
      detail: 'Maya · Today 8:12am',
      completionId: 1,
      questId: 'q-dishwasher',
      questTitle: 'Empty the dishwasher',
      childId: 'maya',
      childName: 'Maya',
      avatarColour: 'lilac',
      coins: 15,
      createdAt: DateTime.utc(2026, 10, 3, 7, 12),
      createdAtTz: 'Europe/London',
    ),
    Approval(
      id: '2',
      title: 'Lay the table',
      detail: 'Maya · Today 8:05am',
      completionId: 2,
      questId: 'q-table',
      questTitle: 'Lay the table',
      childId: 'maya',
      childName: 'Maya',
      avatarColour: 'lilac',
      coins: 10,
      createdAt: DateTime.utc(2026, 10, 3, 7, 5),
      createdAtTz: 'Europe/London',
    ),
  ];

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<List<Approval>> getItems() async => _items;

  @override
  Stream<List<Approval>> watchItems() => Stream<List<Approval>>.value(_items);

  @override
  Future<void> approve(int completionId) async {
    approveCalls++;
    if (_gated) await _gate.future;
  }

  @override
  Future<void> markNotYet(int completionId) async {}

  @override
  Future<void> approveAll() async {
    approveAllCalls++;
    if (_gated) await _gate.future;
  }
}
