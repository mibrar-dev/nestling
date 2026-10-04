// P17 parental-gate view tests: exact copy (character-for-character with
// `design/html-source/screens/P17-parental-gate.html`), keypad fill / delete,
// wrong-answer retry + announcement, correct-answer unlock → parent mode
// (pop when the gate was pushed, `/today` when it was the entry route),
// ghost cancel in both push shapes, every interactive node's
// `SemanticsAction.tap`, the dialog / digits / keypad semantics labels, the
// loading, failure, retry and disabled-gate states, and the Seed.empty
// fallback backdrop.
//
// Database-backed: `setUpTestScope` + Seed.demo. Loading / failure / disabled
// use a feature-local fake repository swapped in before pumping. Every pumped
// app ends with `disposeApp` (see test_scope.dart).
//
// Date independence: nothing here reads the wall clock. The challenge comes
// from the registered `ParentalGateRepository` (exactly what the bloc gets)
// and the fakes carry a fixed 7×6 challenge, so the suite behaves the same
// whether the app clock is the real one or pinned to the demo story day.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

import '../../test_scope.dart';

/// Emits [challenge], then whatever [swap] is pushed — so a test can change the
/// live question while the gate is open (any settings write re-emits).
class _SequenceRepository extends ParentalGateRepository {
  /// Always starts on the design's 7 × 6 challenge; [swap] moves it on.
  static const ParentalGateChallenge challenge = designChallenge;

  final StreamController<List<ParentalGateChallenge>> _swaps =
      StreamController<List<ParentalGateChallenge>>.broadcast();

  void swap(ParentalGateChallenge next) =>
      _swaps.add(<ParentalGateChallenge>[next]);

  Future<void> dispose() => _swaps.close();

  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      <ParentalGateChallenge>[challenge];

  @override
  Stream<List<ParentalGateChallenge>> watchItems() =>
      Stream<List<ParentalGateChallenge>>.multi((controller) {
        controller.add(<ParentalGateChallenge>[challenge]);
        _swaps.stream.listen(controller.add);
      });

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) => challenge;
}

/// The design's own challenge — used by the fakes so their copy and digits
/// are fixed regardless of the day the suite runs on.
const ParentalGateChallenge designChallenge = ParentalGateChallenge(
  id: 'design',
  title: 'Grown-ups only',
  detail: 'This keeps settings and purchases safe.',
  a: 7,
  b: 6,
);

/// A second question (3 × 9 = 27) for challenge-swap scenarios.
const ParentalGateChallenge otherChallenge = ParentalGateChallenge(
  id: 'other',
  title: 'Grown-ups only',
  detail: 'This keeps settings and purchases safe.',
  a: 3,
  b: 9,
);

/// The live challenge the screen will show, read from the same repository the
/// bloc uses (never hard-coded: the plan forbids pinning the day). Drift needs
/// the real event loop, hence [WidgetTester.runAsync].
Future<ParentalGateChallenge> liveChallenge(WidgetTester tester) async {
  final items = (await tester.runAsync(
    () => GetIt.instance<ParentalGateRepository>().getItems(),
  ))!;
  expect(items, hasLength(1));
  return items.single;
}

/// Controllable repository for loading/failure: `hang` silently emits
/// nothing, `fail` errors the stream, otherwise it emits [challenge].
class _FakeRepository extends ParentalGateRepository {
  _FakeRepository({
    this.hang = false,
    this.fail = false,
    this.failTimes = 1 << 30,
  });

  final bool hang;

  /// Whether the stream errors (before [failTimes] retries).
  final bool fail;
  final int failTimes;

  /// Fixed so the fakes never depend on the day the suite runs on.
  ParentalGateChallenge get challenge => designChallenge;

  int _calls = 0;

  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      <ParentalGateChallenge>[challenge];

  @override
  Stream<List<ParentalGateChallenge>> watchItems() {
    _calls++;
    if (hang) {
      return const Stream<List<ParentalGateChallenge>>.empty();
    }
    if (fail && _calls <= failTimes) {
      return Stream<List<ParentalGateChallenge>>.error(Exception('no gate'));
    }
    return Stream<List<ParentalGateChallenge>>.value(<ParentalGateChallenge>[
      challenge,
    ]);
  }

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) => challenge;
}

Future<void> _useFake(ParentalGateRepository repo) async {
  await GetIt.instance.unregister<ParentalGateRepository>();
  GetIt.instance.registerSingleton<ParentalGateRepository>(repo);
}

/// A same-length, definitely-wrong digit string for [answer] — the widget test
/// must not depend on today's product being anything in particular.
String wrongEntryOf(String answer) {
  final last = int.parse(answer[answer.length - 1]);
  final bumped = last == 9 ? 8 : last + 1;
  return '${answer.substring(0, answer.length - 1)}$bumped';
}

/// Captures `SemanticsService` announcements (the wrong-answer voice line).
List<String> captureAnnouncements(WidgetTester tester) {
  final log = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    SystemChannels.accessibility.name,
    (message) async {
      final decoded = const StandardMessageCodec().decodeMessage(
        message,
      ) as Map<Object?, Object?>;
      final data = decoded['data']! as Map<Object?, Object?>;
      if (decoded['type'] == 'announce') log.add(data['message']! as String);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      SystemChannels.accessibility.name,
      null,
    ),
  );
  return log;
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  Future<void> semanticsTap(WidgetTester tester, String label) async {
    final node = tester.getSemantics(find.bySemanticsLabel(label));
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: '"$label" must expose SemanticsAction.tap',
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    // Semantics performAction dispatches the tap via a scheduled frame:
    // pump twice so the bloc emit flushes to the next build.
    await tester.pump();
    await tester.pump();
  }

  Future<void> typeAnswer(WidgetTester tester, String answer) async {
    for (final digit in answer.split('')) {
      await semanticsTap(tester, 'Digit $digit');
    }
  }

  group('copy', () {
    testWidgets('renders the design copy, character for character', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      // Straight from P17-parental-gate.html: plain hyphen in `Grown-ups`,
      // trailing colon, full stop in the caption.
      expect(find.text('Grown-ups only'), findsOneWidget);
      expect(find.text('Type the answer in numbers:'), findsOneWidget);
      expect(find.text(challenge.question), findsOneWidget);
      expect(find.text('Back to Pip'), findsOneWidget);
      expect(
        find.text('This keeps settings and purchases safe.'),
        findsOneWidget,
      );
      // The design PNG shows a half-typed answer; a freshly opened gate is
      // empty, so no box holds a digit yet.
      expect(
        _digitBoxes(tester).every(
          (decoration) =>
              decoration.color ==
              tester.element(find.byType(NestModal)).nest.surface2,
        ),
        isTrue,
      );

      // No stray placeholder copy left from the v1 scaffold screen.
      expect(find.textContaining('P17'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the question words are spelled out, never digits', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      expect(find.text(challenge.question), findsOneWidget);
      // Numbers are never spelled with digits in the prompt (SPACING_SPEC).
      expect(challenge.question, isNot(contains(RegExp(r'\d'))));
      expect(
        tester.widget<Text>(find.text(challenge.question)).data,
        challenge.question,
      );
      await disposeApp(tester);
    });

    testWidgets('copy keeps letterSpacing 0 and the bundled faces', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      const expected = <String, String>{
        // Nunito display faces for the kid headings …
        'Grown-ups only': 'Nunito',
      };
      for (final entry in expected.entries) {
        final style = tester.widget<Text>(find.text(entry.key)).style!;
        expect(style.fontFamily, entry.value);
        expect(style.letterSpacing, 0);
      }
      // … Inter for the parent-UI lines (.body-s / .caption).
      for (final copy in const <String>[
        'Type the answer in numbers:',
        'This keeps settings and purchases safe.',
      ]) {
        final style = tester.widget<Text>(find.text(copy)).style!;
        expect(style.fontFamily, 'Inter');
        expect(style.letterSpacing, 0);
      }
      final cancel = tester.widget<Text>(find.text('Back to Pip')).style!;
      expect(cancel.letterSpacing, 0);
      await disposeApp(tester);
    });
  });

  group('keypad entry', () {
    testWidgets('a real pointer tap fills the boxes left→right', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      final total = challenge.answer.toString().length;
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final tokens = tester.element(find.byType(NestModal)).nest;

      // Fresh gate: every box is empty (surface-2 + line border).
      final empty = _digitBoxes(tester);
      expect(empty, hasLength(total));
      for (final decoration in empty) {
        expect(decoration.color, tokens.surface2);
        expect((decoration.border! as Border).top.color, tokens.line);
        expect((decoration.border! as Border).top.width, 2);
      }

      await tester.tap(find.bySemanticsLabel('Digit 1'));
      await tester.pump();

      expect(
        find.bySemanticsLabel('Answer, 1 of $total entered'),
        findsOneWidget,
      );
      // `.digit.filled` = surface + ink border; the rest stay empty.
      final filled = _digitBoxes(tester);
      expect(filled.first.color, tokens.surface);
      expect((filled.first.border! as Border).top.color, tokens.ink);
      if (total > 1) {
        expect(filled[1].color, tokens.surface2);
      }
      await disposeApp(tester);
    });

    testWidgets('every empty box carries the leaf caret (CSS ::after)', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      final total = challenge.answer.toString().length;
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final tokens = tester.element(find.byType(NestModal)).nest;
      final semantics = tester.ensureSemantics();

      // `.digit.empty::after { width:3px; height:24px; background:var(--leaf) }`
      // paints EVERY empty box, not only the next one to fill.
      expect(_carets(tester), hasLength(total));
      for (final caret in _carets(tester)) {
        expect(caret.color, tokens.leaf);
        expect((caret.borderRadius! as BorderRadius).topLeft.x, 2);
      }

      await semanticsTap(tester, 'Digit 1');
      // One box filled ⇒ one caret fewer; the rest keep theirs.
      expect(_carets(tester), hasLength(total - 1));

      await semanticsTap(tester, 'Delete');
      expect(_carets(tester), hasLength(total));

      // Filling the answer leaves no caret (and unlocks, which is covered by
      // the navigation group) — a one-digit answer is the only way to assert
      // the empty state without leaving the screen.
      if (total == 1) {
        await typeAnswer(tester, '${challenge.answer}');
        await tester.pump();
        expect(_carets(tester), isEmpty);
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('semantics taps fill, delete empties, delete is safe empty', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      final total = challenge.answer.toString().length;
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      await semanticsTap(tester, 'Digit 1');
      expect(
        find.bySemanticsLabel('Answer, 1 of $total entered'),
        findsOneWidget,
      );
      await semanticsTap(tester, 'Delete');
      expect(
        find.bySemanticsLabel('Answer, 0 of $total entered'),
        findsOneWidget,
      );
      // Delete on an empty entry is a no-op, not a crash.
      await semanticsTap(tester, 'Delete');
      expect(
        find.bySemanticsLabel('Answer, 0 of $total entered'),
        findsOneWidget,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a wrong full entry clears the boxes and announces once', (
      tester,
    ) async {
      await _useFake(_FakeRepository());
      final announcements = captureAnnouncements(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      const answer = '42';
      await typeAnswer(tester, wrongEntryOf(answer));
      await tester.pump();

      expect(find.bySemanticsLabel('Answer, 0 of 2 entered'), findsOneWidget);
      // Curly apostrophe + em dash, exactly as the view sends it.
      expect(announcements, <String>['That wasn’t right — try again']);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a new challenge announces its first wrong answer again', (
      tester,
    ) async {
      // 6_bugs observation 1: the bloc resets `attempts` when the live
      // challenge changes, so the view's announcement high-water mark must be
      // re-based on the new challenge id or the first wrong answer on the new
      // question is silent.
      final repo = _SequenceRepository();
      addTearDown(repo.dispose);
      await _useFake(repo);
      final announcements = captureAnnouncements(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      expect(find.text('seven times six'), findsOneWidget);
      await typeAnswer(tester, wrongEntryOf('42'));
      await tester.pump();
      expect(announcements, hasLength(1));

      // The settings row re-emits a different question (P16 write).
      repo.swap(otherChallenge);
      await tester.pump();
      await tester.pump();
      expect(find.text('three times nine'), findsOneWidget);
      expect(find.bySemanticsLabel('Answer, 0 of 2 entered'), findsOneWidget);

      await typeAnswer(tester, wrongEntryOf('27'));
      await tester.pump();
      expect(announcements, <String>[
        'That wasn’t right — try again',
        'That wasn’t right — try again',
      ], reason: 'the second challenge must announce its own first attempt');

      // A same-challenge re-emit must NOT announce again (no phantom repeats).
      repo.swap(otherChallenge);
      await tester.pump();
      await tester.pump();
      expect(announcements, hasLength(2));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a second wrong answer announces again (once per attempt)', (
      tester,
    ) async {
      await _useFake(_FakeRepository());
      final announcements = captureAnnouncements(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      await typeAnswer(tester, '11');
      await tester.pump();
      await typeAnswer(tester, '22');
      await tester.pump();
      expect(announcements, hasLength(2));
      // No danger styling anywhere: the retry stays calm.
      expect(find.textContaining('wrong'), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('navigation', () {
    testWidgets('the correct answer switches to parent mode at /today', (
      tester,
    ) async {
      await _useFake(_FakeRepository());
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      await typeAnswer(tester, '42');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(currentPath(tester), '/today');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('unlocking a pushed gate dismisses it and keeps the kid route', (
      tester,
    ) async {
      await _useFake(_FakeRepository());
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      // K03 pushes the gate from its lock button.
      await pumpAppRoute(tester, '/kid-home');
      final semantics = tester.ensureSemantics();

      final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
      lock.owner!.performAction(lock.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/parental-gate');

      await typeAnswer(tester, '42');
      await tester.pump();
      // Give the async AppSession write + refresh time to land (it completes
      // inside FakeAsync on the next microtask drain).
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Plan §(c): parent mode first, then pop the pushed route — and the
      // gate must actually be gone.
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(
        pushedPath(tester),
        '/kid-home',
        reason:
            'P17-BUG-1 (major): _unlock flips the app mode AND starts the async '
            'AppSession.setAppMode write BEFORE popping. The session '
            'notification reaches the router (refreshListenable = appMode + '
            'session) and re-parses the match list while the imperative push is '
            'being popped, which restores the /parental-gate route: the gate '
            'never closes and the app is left in parent mode with the '
            'grown-ups gate still covering K03. Reproduced in '
            'parental_gate_view.dart:36-49 — popping first and switching mode '
            'afterwards dismisses the gate correctly.',
      );
      expect(find.byType(NestModal), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Back to Pip pops the gate back to /kid-home', (tester) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      // Push the gate the way K03's lock does: kid home → push gate.
      await pumpAppRoute(tester, '/kid-home');
      final semantics = tester.ensureSemantics();
      final lock = tester.getSemantics(find.bySemanticsLabel('Grown-ups'));
      lock.owner!.performAction(lock.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/parental-gate');

      final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      cancel.owner!.performAction(cancel.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Back to Pip with nothing to pop goes to /kid-home', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      // Entered straight onto the gate (kid-mode redirect): canPop is false.
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      await semanticsTap(tester, 'Back to Pip');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      // Cancel must never leak into parent mode.
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      expect(challenge.answer, greaterThan(0));
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('semantics', () {
    testWidgets('every keypad key and ghost button exposes a tap action', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();
      for (var d = 0; d <= 9; d++) {
        final node = tester.getSemantics(find.bySemanticsLabel('Digit $d'));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Digit $d must be tappable',
        );
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      }
      final delete = tester.getSemantics(find.bySemanticsLabel('Delete'));
      expect(delete.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      final cancel = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      expect(cancel.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the dialog, digits group and keypad group are labelled', (
      tester,
    ) async {
      final challenge = await liveChallenge(tester);
      final total = challenge.answer.toString().length;
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      // HTML: role=dialog aria-modal aria-label="Parental gate".
      expect(find.bySemanticsLabel('Parental gate'), findsOneWidget);
      // HTML: .digits role=group, .keypad role=group aria-label="Number pad".
      expect(find.bySemanticsLabel('Number pad'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Answer, 0 of $total entered'),
        findsOneWidget,
      );
      // The delete key is the only icon button; it carries a text label.
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the dimmed kid backdrop stays out of the a11y tree', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      // The backdrop renders (design: "Hi Maya!" + 120 coins + Pip) …
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      // … but the HTML marks `.kid-bg` aria-hidden, so it must not be
      // announced behind the modal.
      expect(find.bySemanticsLabel('Hi Maya!'), findsNothing);
      expect(find.bySemanticsLabel('120'), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('states', () {
    testWidgets('loading shows a spinner, not the keypad', (tester) async {
      await _useFake(_FakeRepository(hang: true));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Digit 1'), findsNothing);
      // The frame never jumps: lock tile + title are already there.
      expect(find.text('Grown-ups only'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('loading still offers the Back to Pip escape', (tester) async {
      // 3_test obs 3 / 6_bugs obs 1: the 56 px slot under the spinner used to
      // be an empty placeholder, so only the system back gesture could leave
      // the gate. The real ghost escape now stands in it (layout-neutral: the
      // same 56 px, pinned by the loading-vs-loaded card-height geometry pin).
      await _useFake(_FakeRepository(hang: true));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      final semantics = tester.ensureSemantics();
      expect(find.text('Back to Pip'), findsOneWidget);
      final escape = tester.getSemantics(find.bySemanticsLabel('Back to Pip'));
      expect(
        escape.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the loading escape must be operable by VoiceOver/TalkBack',
      );
      await semanticsTap(tester, 'Back to Pip');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      expect(GetIt.instance<AppModeController>().mode, AppMode.kid);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('failure shows a message, Try again and Back to Pip', (
      tester,
    ) async {
      await _useFake(_FakeRepository(fail: true));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      expect(find.text('Exception: no gate'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Back to Pip'), findsOneWidget);
      // The caption still appears exactly once (inside the failure body).
      expect(
        find.text('This keeps settings and purchases safe.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Digit 1'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Try again re-loads and hands back a working keypad', (
      tester,
    ) async {
      // Fails the first watch, succeeds on the retry — the exact P17 recovery.
      await _useFake(_FakeRepository(fail: true, failTimes: 1));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();
      expect(find.text('Exception: no gate'), findsOneWidget);

      await semanticsTap(tester, 'Try again');
      await tester.pump();

      expect(find.text('Try again'), findsNothing);
      expect(find.text('seven times six'), findsOneWidget);
      expect(find.bySemanticsLabel('Answer, 0 of 2 entered'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a disabled gate passes straight through to parent mode', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await (db.update(db.settings)
            ..where((s) => s.familyId.equals(Seed.familyId)))
          .write(const SettingsCompanion(kidGateEnabled: Value(false)));
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      await tester.pump(const Duration(milliseconds: 600));
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(currentPath(tester), '/today');
      await disposeApp(tester);
    });

    testWidgets('Seed.empty: no child, but the gate still works', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      // Fallback backdrop (P08b family: an onboarded parent, no children).
      expect(find.text('Hi there!'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NestCoinPill),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );

      debugPrint('M4 pumped route');
      final challenge = await liveChallenge(tester);
      debugPrint('M5 challenge read');
      await typeAnswer(tester, '${challenge.answer}');
      debugPrint('M6 answered');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(currentPath(tester), '/today');
      semantics.dispose();
      await disposeApp(tester);
    });
  });
  group('expired trial in kid mode (ORCHESTRATOR_NOTES 09:48)', () {
    /// Ages the trial row **relative to the app's own clock**, never the wall
    /// clock: `appNowUtc()` is the pinned instant the tests run against, so a
    /// `DateTime.now()`-based 15-days-ago write would be only ~13.5 days old
    /// against the pin and the trial would not be expired at all.
    Future<void> expireTrial(WidgetTester tester) async {
      final db = GetIt.instance<AppDatabase>();
      final session = GetIt.instance<AppSession>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(
            subscriptionStatus: const Value('trial'),
            trialStart: Value(appNowUtc().subtract(const Duration(days: 20))),
          ),
        );
        await session.refresh();
      });
      expect(session.trialExpired, isTrue, reason: 'the fixture must be aged');
    }

    testWidgets('kid mode funnels to the gate instead of looping', (
      tester,
    ) async {
      await expireTrial(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/kid-home');
      await tester.pump(const Duration(milliseconds: 400));

      // Decision: "in kid mode with an expired trial, everything goes to the
      // gate, the gate is exempt". The old guard ping-ponged
      // /paywall => /parental-gate => /paywall and rendered go_router's error
      // page instead of the screen.
      expect(currentPath(tester), '/parental-gate');
      expect(find.text('Grown-ups only'), findsOneWidget);
      expect(find.textContaining('redirect loop'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the gate hands the parent to the paywall after unlocking', (
      tester,
    ) async {
      await expireTrial(tester);
      final challenge = await liveChallenge(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      // Entered on a kid screen, as in the product (K03's lock pushes it).
      await pumpAppRoute(tester, '/kid-home');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/parental-gate');
      final semantics = tester.ensureSemantics();

      await typeAnswer(tester, '${challenge.answer}');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Decision: "the parent sees the paywall after the gate" — the kid-mode
      // exemption is only for the gate, so flipping to parent mode puts the
      // aged trial straight in front of the parent.
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      expect(currentPath(tester), '/paywall');
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a live trial is untouched by the gate (no paywall detour)', (
      tester,
    ) async {
      // Seed.demo is an 'active' subscriber, so kid mode + /kid-home must stay
      // on kid home: the gate is a lock the kid opens deliberately, not a
      // trial interceptor.
      final session = GetIt.instance<AppSession>();
      expect(session.trialExpired, isFalse);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/kid-home');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/kid-home');
      expect(find.text('Grown-ups only'), findsNothing);
      await disposeApp(tester);
    });
  });

  group('persistence (IDS + TRIAL rules)', () {
    testWidgets('a gate session writes only app_mode, never the trial row', (
      tester,
    ) async {
      // Read the pre-unlock state through `AppSession` — the session is the
      // app's public window on the row, and a `tester.runAsync` DB query
      // issued after the unlock deadlocks behind `_unlock`'s in-flight write
      // (see 3_test §5), so the assertions stay on the sync getters.
      final session = GetIt.instance<AppSession>();
      await tester.runAsync(session.refresh);
      final statusBefore = session.subscriptionStatus;
      final childBefore = session.activeChildId;

      final challenge = await liveChallenge(tester);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');
      final semantics = tester.ensureSemantics();

      await typeAnswer(tester, '${challenge.answer}');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);
      semantics.dispose();
      await disposeApp(tester);

      // The new IDS rule: row ids come from `newId(prefix)`, never the clock.
      // P17 creates no rows at all — the challenge id is a date-derived
      // identity for the live question, not a row id — so a gate session may
      // only flip `app_mode`. The TRIAL rule says the same of
      // `subscription_status`: never written from here.
      expect(session.appMode, 'parent', reason: 'the one write the gate makes');
      expect(session.subscriptionStatus, statusBefore);
      expect(session.activeChildId, childBefore);
      expect(session.onboardingComplete, isTrue);
      expect(session.trialExpired, isFalse);
    });
  });
}

/// The 3×24 leaf carets (`.digit.empty::after`) inside the answer boxes.
List<BoxDecoration> _carets(WidgetTester tester) {
  final carets = <BoxDecoration>[];
  for (final element in find.byType(Container).evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is! BoxDecoration) continue;
    final box = element.renderObject! as RenderBox;
    final size = box.size;
    if ((size.width - 3).abs() > 0.5) continue;
    if ((size.height - 24).abs() > 0.5) continue;
    carets.add(decoration);
  }
  return carets;
}

/// The 56×64 digit boxes, left to right, as `Container`s with their
/// `BoxDecoration` (filled vs empty styling).
List<BoxDecoration> _digitBoxes(WidgetTester tester) {
  final boxes = <(double, BoxDecoration)>[];
  for (final element in find.byType(Container).evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is! BoxDecoration) continue;
    final box = element.renderObject! as RenderBox;
    final size = box.size;
    if ((size.width - 56).abs() > 0.5) continue;
    if ((size.height - 64).abs() > 0.5) continue;
    boxes.add((box.localToGlobal(Offset.zero).dx, decoration));
  }
  boxes.sort((a, b) => a.$1.compareTo(b.$1));
  return <BoxDecoration>[for (final entry in boxes) entry.$2];
}
