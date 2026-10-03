// P11 · Approvals — view tests.
//
// Route-level: pumps the real app at `/approvals` over the seeded in-memory
// database, so the cards assert DATABASE values (Maya · Empty the dishwasher
// / Today 8:12am / 15 coins), not the designs' mock rows ("Tidy your
// bedroom", "Yesterday 5:40pm"). DATA OVER MOCKS.
//
// Only view/widget concerns live here; repository + bloc tests are the logic
// builder's files (approvals_repository_test.dart, approvals_bloc_test.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/views/approvals_view.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_loaded_body.dart';

import '../../test_scope.dart';

/// Byte-exact helper copy: U+201C / U+201D and an em dash (U+2014).
const String _helperCopy =
    '“Not yet” sends a kind note — no coins are taken away.';

/// Every seeded pending approval, newest first (P11 plan §0).
const _seedRows = <(String child, String quest, String when, int coins)>[
  ('Maya', 'Empty the dishwasher', 'Today 8:12am', 15),
  ('Maya', 'Lay the table', 'Today 8:05am', 10),
  ('Leo', 'Make your bed', 'Today 7:58am', 5),
];

/// `Text.rich` cards do not match `find.textContaining`; match the flattened
/// span text instead so the `.tm` line can be asserted exactly.
Finder _richText(String plain) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == plain,
);

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

/// Taps one of the two row buttons on the card whose `.who` line is [whoLine].
Future<void> _tapRowButton(
  WidgetTester tester,
  String whoLine,
  String label,
) async {
  await tester.tap(
    find.descendant(
      of: _cardFor(whoLine),
      matching: find.widgetWithText(NestButton, label),
    ),
  );
  await tester.pump();
  await _settle(tester);
}

/// Every `BoxDecoration` painted by a `Container` on screen — the shapes the
/// UI check must compare against the design, not just where text lands.
List<BoxDecoration> _boxDecorations(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// Pumps until the frame queue is quiet. "Approve all" writes three rows
/// through Drift, each one waking the pending stream, so a fixed number of
/// pumps would be flaky.
Future<void> _settle(WidgetTester tester) async {
  // Bounded loop rather than `pumpAndSettle`: the running app always has
  // something scheduling frames (the session's Drift watchers), so settle
  // never converges here. 20 x 50ms is far more than the writes need.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pump(WidgetTester tester, {ThemeMode theme = ThemeMode.light}) =>
      pumpAppRoute(tester, '/approvals', theme: theme);

  group('P11 approvals screen', () {
    testWidgets('title, helper copy and the three seeded cards', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(find.text(_helperCopy), findsOneWidget);
      for (final (child, quest, stamp, coins) in _seedRows) {
        expect(find.text('$child · $quest'), findsOneWidget);
        expect(_richText('$stamp · $coins coins'), findsOneWidget);
      }
      expect(find.text('Approve all (3)'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('helper copy is character-exact (curly quotes + em dash)', (
      tester,
    ) async {
      await pump(tester);

      final banner = tester.widget<Text>(find.text(_helperCopy));
      expect(banner.data, approvalsHelperCopy);
      expect(approvalsHelperCopy, contains('“'));
      expect(approvalsHelperCopy, contains('”'));
      expect(approvalsHelperCopy, contains('—'));
      expect(approvalsHelperCopy, isNot(contains('"')));
      expect(approvalsHelperCopy, isNot(contains('--')));

      await disposeApp(tester);
    });

    testWidgets('light mode paints leaf-tint helper + 24r surface cards', (
      tester,
    ) async {
      await pump(tester);
      final tokens = tester.element(find.byType(ApprovalsHelperBanner)).nest;

      final shapes = _boxDecorations(tester);
      // `.helper`: leaf-tint fill, radius 16.
      expect(
        shapes.any(
          (d) => d.color == tokens.leafTint && d.borderRadius == NestRadii.allM,
        ),
        isTrue,
        reason: 'helper banner must be a leaf-tint 16-radius box',
      );
      // `.appr`: surface fill, radius 24 — one per card.
      expect(
        shapes.where(
          (d) => d.color == tokens.surface && d.borderRadius == NestRadii.allL,
        ),
        hasLength(3),
        reason: 'three approval cards, each a 24-radius surface box',
      );

      await disposeApp(tester);
    });

    testWidgets('dark mode keeps the same shapes on dark tokens', (
      tester,
    ) async {
      await pump(tester, theme: ThemeMode.dark);

      final tokens = tester.element(find.byType(ApprovalsHelperBanner)).nest;
      final shapes = _boxDecorations(tester);
      expect(
        shapes.any(
          (d) => d.color == tokens.leafTint && d.borderRadius == NestRadii.allM,
        ),
        isTrue,
      );
      expect(
        shapes.where(
          (d) => d.color == tokens.surface && d.borderRadius == NestRadii.allL,
        ),
        hasLength(3),
      );
      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(find.text(_helperCopy), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('bottom CTA surface runs to the physical screen edge', (
      tester,
    ) async {
      await pump(tester);
      final tokens = tester.element(find.byType(NestBottomCta)).nest;

      final cta = tester.getRect(find.byType(NestBottomCta));
      final screen = tester.getRect(find.byType(Scaffold).first);
      expect(cta.left, screen.left);
      expect(cta.right, screen.right);
      expect(cta.bottom, screen.bottom);
      // No coloured strip below the bar: the CTA's own surface fills it.
      final bar = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NestBottomCta),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = bar.decoration as BoxDecoration;
      expect(decoration.color, tokens.surface);

      await disposeApp(tester);
    });

    testWidgets('approving a card drops it and renumbers the screen', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');

      expect(find.text('Maya · Empty the dishwasher'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(find.text('Approve all (2)'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('"Not yet" clears the card without an error snack', (
      tester,
    ) async {
      await pump(tester);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Not yet');

      expect(find.text('Maya · Empty the dishwasher'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('approving every card drains the inbox to the empty state', (
      tester,
    ) async {
      await pump(tester);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');
      await _tapRowButton(tester, 'Maya · Lay the table', 'Approve');
      await _tapRowButton(tester, 'Leo · Make your bed', 'Approve');

      expect(find.text('Waiting for you (0)'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.byType(ApprovalCard), findsNothing);
      // No "Approve all (0)" bar over the empty state — the CTA goes with the
      // inbox (owner bottom-edge rule: no bar, so no coloured strip either).
      expect(find.text('Approve all (0)'), findsNothing);
      expect(find.byType(NestBottomCta), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('back chevron leaves /approvals for /today', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(pushedPath(tester), '/approvals');

      await tester.tap(find.bySemanticsLabel('Back to Today'));
      await tester.pump();
      await _settle(tester);

      expect(pushedPath(tester), '/today');
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('320 wide at text scale 1.3 overflows nothing', (tester) async {
      await pump(tester);

      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(find.text('Approve all (3)'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('CTA locks while an approve-all write is in flight', (
      tester,
    ) async {
      // Stubbed repository on purpose: `ApprovalsRepositoryImpl.approveAll`
      // awaits `watchItems().first`, and a Drift query stream never delivers
      // its first event inside `testWidgets`' fake-async zone — so the real
      // button can be exercised only here. The repository itself is covered by
      // `approvals_repository_test.dart` (a plain `test`, real async).
      final gate = Completer<void>();
      final repository = _StubApprovalsRepository(approveAllGate: gate);
      final bloc = ApprovalsBloc(repository: repository)
        ..add(const ApprovalsLoadRequested());
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

      Finder cta() => find.byKey(const ValueKey<String>('p11_approve_all'));
      expect(tester.widget<NestButton>(cta()).onPressed, isNotNull);
      expect(tester.widget<NestButton>(cta()).loading, isFalse);

      await tester.tap(cta());
      await tester.pump();

      expect(tester.widget<NestButton>(cta()).loading, isTrue);
      expect(tester.widget<NestButton>(cta()).onPressed, isNull);

      gate.complete();
      await disposeApp(tester);
    });
  });

  // Owner brief, "ACCESSIBILITY ACTIONS": every interactive element must be
  // operable by VoiceOver/TalkBack, and `performAction(tap)` must drive the
  // real state — not just be present on the node.
  group('P11 semantics tap actions', () {
    testWidgets('back, both row buttons and the CTA all expose tap', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      bool taps(Finder finder) => tester
          .getSemantics(finder)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap);

      expect(taps(find.bySemanticsLabel('Back to Today')), isTrue);
      final card = _cardFor('Maya · Empty the dishwasher');
      expect(
        taps(
          find.descendant(of: card, matching: find.bySemanticsLabel('Not yet')),
        ),
        isTrue,
      );
      expect(
        taps(
          find.descendant(of: card, matching: find.bySemanticsLabel('Approve')),
        ),
        isTrue,
      );
      expect(taps(find.bySemanticsLabel('Approve all (3)')), isTrue);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on a card Approve drops that card', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);

      tester.semantics.performAction(
        // `.first` = the top card's own button (each card repeats the label).
        find.semantics.byLabel('Approve').first,
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      // Real state, not just the action flag: the row leaves the seeded inbox
      // and both counters follow the database.
      expect(find.text('Maya · Empty the dishwasher'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(find.text('Approve all (2)'), findsOneWidget);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on "Not yet" drops the card', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      final coinsBefore = await _questBonusTotal(tester);

      tester.semantics.performAction(
        find.semantics.byLabel('Not yet').first,
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      expect(find.text('Maya · Empty the dishwasher'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      // The kind note moves no money (the seeded `quest_bonus` total is the
      // wallet before the inbox was drained, so it must not change).
      expect(await _questBonusTotal(tester), coinsBefore);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the back chevron goes to /today', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(pushedPath(tester), '/approvals');

      tester.semantics.performAction(
        find.semantics.byLabel('Back to Today'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      expect(pushedPath(tester), '/today');
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('Try again exposes tap and re-runs the load', (tester) async {
      // The failure branch has no design, so it is driven with a stub whose
      // first stream is an error and whose retry succeeds.
      var attempts = 0;
      final repository = _FlakyApprovalsRepository(
        onWatch: () => attempts++ == 0
            ? Stream<List<Approval>>.error(StateError('boom'))
            : Stream<List<Approval>>.value(_StubApprovalsRepository._items),
      );
      final semantics = tester.ensureSemantics();
      final bloc = ApprovalsBloc(repository: repository)
        ..add(const ApprovalsLoadRequested());
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
      await _settle(tester);

      expect(find.text('All caught up'), findsNothing);
      final retry = find.byKey(const ValueKey<String>('p11_try_again'));
      expect(retry, findsOneWidget);
      expect(
        tester
            .getSemantics(retry)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      tester.semantics.performAction(
        find.semantics.byLabel('Try again'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      // The retry really re-subscribes: the inbox renders from the stream.
      expect(attempts, 2);
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);
      expect(find.text('All caught up'), findsNothing);
      semantics.dispose();

      await disposeApp(tester);
    });
  });
}

/// Total pence in every `quest_bonus` ledger row — the money side-effect of an
/// approval, so "Not yet moves no coins" is checked against the database and
/// not against the absence of a UI change.
Future<int> _questBonusTotal(WidgetTester tester) async {
  final db = GetIt.instance<AppDatabase>();
  final rows = await (db.select(
    db.ledgerEntries,
  )..where((row) => row.type.equals('quest_bonus'))).get();
  return rows.fold<int>(0, (sum, row) => sum + row.amountPence);
}

/// One pending row, one child — enough to keep the CTA on screen.
class _StubApprovalsRepository implements ApprovalsRepository {
  _StubApprovalsRepository({required this.approveAllGate});

  final Completer<void> approveAllGate;

  static final List<Approval> _items = <Approval>[
    Approval(
      id: '1',
      title: 'Empty the dishwasher',
      detail: 'Maya · Sat 3 Oct 8:12am',
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
  ];

  @override
  Future<List<Approval>> getItems() async => _items;

  @override
  Stream<List<Approval>> watchItems() => Stream<List<Approval>>.value(_items);

  @override
  Future<void> approve(int completionId) async {}

  @override
  Future<void> markNotYet(int completionId) async {}

  @override
  Future<void> approveAll() => approveAllGate.future;
}

/// Fails the first `watchItems()` (the bloc's `failure` branch) and serves
/// real rows on the retry, so "Try again" can be proven end to end without a
/// second database.
class _FlakyApprovalsRepository implements ApprovalsRepository {
  _FlakyApprovalsRepository({required this.onWatch});

  /// Called on every `watchItems()` — used to count subscriptions.
  final Stream<List<Approval>> Function() onWatch;

  @override
  Future<List<Approval>> getItems() async => _StubApprovalsRepository._items;

  @override
  Stream<List<Approval>> watchItems() => onWatch();

  @override
  Future<void> approve(int completionId) async {}

  @override
  Future<void> markNotYet(int completionId) async {}

  @override
  Future<void> approveAll() async {}
}
