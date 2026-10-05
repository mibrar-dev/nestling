// K07 · Pip evolves — accessibility (RULES §8, DESIGN_SPEC §0.9).
//
// What this file proves, in the order the rules state them:
//
//   * every interactive element exposes `SemanticsAction.tap`, and performing
//     that action drives the REAL behaviour (a real route change or a real DB
//     reload) — never a pointer tap, which VoiceOver cannot produce;
//   * every interactive element is at least the KID minimum tap target
//     (56x56), the parent minimum (44) being the weaker bound here;
//   * every icon-only control carries a spoken label (the design's own
//     `aria-label`), and every NON-control advertises no tap action, so a
//     screen reader never meets a phantom button;
//   * the same holds on the failure and no-child cards, which have their own
//     controls.
//
// The in-memory Drift DB is seeded with `Seed.demo` (Maya, stage 3); the
// failure path swaps in a repository whose streams error, the no-child path
// re-seeds with `Seed.empty`. Every widget test ends with `disposeApp` INSIDE
// the body (RULES §7.1).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';

import '../../test_scope.dart';

/// Both K07 load streams error while [fail] is true, so the failure card's
/// "Try again" can really reload (the K06 flaky-repository pattern). BOTH must
/// fail: the bloc keeps the loaded screen while either stream has data.
class _FlakyEvolutionRepository extends PipRepositoryImpl {
  _FlakyEvolutionRepository({required super.db});

  bool fail = true;

  @override
  Stream<PipNest?> watchNest() {
    if (fail) return Stream<PipNest?>.error(Exception('down'));
    return super.watchNest();
  }

  @override
  Stream<PipEvolution?> watchEvolution() {
    if (fail) return Stream<PipEvolution?>.error(Exception('down'));
    return super.watchEvolution();
  }
}

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

/// Bounded pumps: `pumpAndSettle` would hang on the loading spinner's endless
/// animation.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps until [ready] matches (bounded to ~3 s of real time), then settles.
///
/// The screen's data arrives over real Drift streams, so a fixed fake-clock
/// delay is a race: on a loaded machine (several stages running suites at
/// once) 600 ms of fake time can pass before the query has answered, and the
/// assertions then read the LOADING screen instead of the state under test.
/// Waiting for the state itself makes the whole file order- and
/// load-independent.
Future<void> _pumpUntil(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  await _settle(tester);
}

/// The real VoiceOver/TalkBack activation, after checking the node advertises
/// the action (RULES §8).
void performTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'the control must expose SemanticsAction.tap',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

bool hasTap(WidgetTester tester, Finder finder) {
  return tester
      .getSemantics(finder)
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);
}

/// Every label in the whole screen's semantics tree that advertises
/// `SemanticsAction.tap` on a node flagged as a BUTTON, in traversal order.
///
/// Enumerating the tree (instead of a hand-picked list of finders) is what
/// makes the sweep exhaustive: a node that accidentally acquired a tap action
/// would show up here even if no assertion named it.
///
/// Only button-flagged nodes are counted. Every shared control in the app
/// (`NestKidButton`, `NestLockButton`, the tab bar) additionally exposes its
/// inner `GestureDetector`/`InkWell` as an UNLABELLED tap node inside the
/// labelled parent — a design-system characteristic, identical on K06 and P08
/// (measured; see `3_test.md` §Observations), not something a screen can fix
/// (RULES §1 forbids editing `core/`). The screen-level contract this file
/// enforces is: exactly the expected labelled buttons are tappable, and
/// nothing informative is.
List<String> tappableLabels(WidgetTester tester) {
  // Anchored on the Scaffold's own semantics node rather than the pipeline
  // owner's root: `rootSemanticsNode` only exists once the whole tree has been
  // flushed, which a just-settled screen does not guarantee (it silently
  // yielded an empty sweep). The Scaffold sits above every control this screen
  // owns, so its subtree IS the screen.
  final labels = <String>[];
  final seen = <int>{};
  void walk(SemanticsNode node) {
    if (!seen.add(node.id)) return; // a merged tree can share a child
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap) && data.flagsCollection.isButton) {
      labels.add(data.label);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.getSemantics(find.byType(Scaffold).first));
  // Sorted: the assertion is about WHICH nodes are controls, not about the
  // framework's traversal order (which follows paint order).
  return labels..sort();
}

/// The kid minimum from DESIGN_SPEC §0.9. K07 is a kid screen, so 56 — the
/// parent minimum of 44 would be the weaker, wrong bound here.
const double _minTap = NestDevice.tapKid;

/// A tap target must be at least [_minTap] square. Only the TAPPABLE area
/// counts, so the shared button's 6 px `--sh-kid` shadow room is inside it.
void expectTapTarget(WidgetTester tester, String key, {String? reason}) {
  final rect = tester.getRect(find.byKey(Key(key)));
  expect(
    rect.width,
    greaterThanOrEqualTo(_minTap),
    reason: reason ?? '$key width',
  );
  expect(
    rect.height,
    greaterThanOrEqualTo(_minTap),
    reason: reason ?? '$key height',
  );
}

/// Maya's seeded values — expectations only; the screen hard-codes none.
const int _mayaQuestsDone = 4;
const int _mayaTotalCoins = 175;
const int _mayaStage = 3;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  /// Pumps `/pip-evolution` and waits for the state under test.
  ///
  /// [ready] is the control that proves which state the screen is in: the
  /// celebration CTA on the loaded screen, `Try again` on the failure card,
  /// `Choose` on the no-child card. Nothing else is rendered on every state, so
  /// it is the one thing to wait for.
  Future<void> pumpEvolution(
    WidgetTester tester, {
    ThemeMode theme = ThemeMode.light,
    String ready = 'k07-cta',
  }) async {
    await pumpAppRoute(tester, '/pip-evolution', theme: theme);
    await _pumpUntil(tester, find.byKey(Key(ready)));
  }

  /// `Seed.empty()` = an onboarded family with no children, so
  /// `app_state.active_child_id` is null and both K07 streams load a null.
  Future<void> emptySeed(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
    });
  }

  group('every control advertises a tap action', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the CTA and the lock', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpEvolution(tester, theme: theme);

        expect(
          hasTap(tester, find.bySemanticsLabel('Meet Fledgling Pip')),
          isTrue,
          reason: 'the CTA',
        );
        expect(
          hasTap(tester, find.bySemanticsLabel('Grown-ups')),
          isTrue,
          reason: 'the lock',
        );
        semantics.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('the failure card’s Try again', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_FlakyEvolutionRepository(db: db));
      await pumpEvolution(tester, ready: 'k07-retry');

      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(hasTap(tester, find.bySemanticsLabel('Try again')), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the no-child card’s Choose', (tester) async {
      final semantics = tester.ensureSemantics();
      await emptySeed(tester);
      await pumpEvolution(tester, ready: 'k07-choose');

      expect(find.text("Who's playing?"), findsOneWidget);
      expect(hasTap(tester, find.bySemanticsLabel('Choose')), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the lock and the CTA are the ONLY tappable nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      // Exactly two, read from the whole semantics tree: nothing on this
      // screen may read as a phantom button.
      expect(tappableLabels(tester), <String>[
        'Grown-ups',
        'Meet Fledgling Pip',
      ]);
      // The lock's own label is the design's aria-label, not the shared
      // component's default.
      expect(find.bySemanticsLabel('Grown-ups only'), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('every control meets the kid tap target (≥ 56)', () {
    testWidgets('the lock and the CTA', (tester) async {
      await pumpEvolution(tester);

      expectTapTarget(tester, 'k07-lock');
      expectTapTarget(tester, 'k07-cta');
      // The CTA is the design's `.btn-kid`: 64 painted, plus the 6 px
      // `--sh-kid` shadow room the shared button reserves underneath.
      expect(
        tester.getRect(find.byKey(const Key('k07-cta'))).height,
        greaterThanOrEqualTo(64),
      );
      await disposeApp(tester);
    });

    testWidgets('the failure card’s Try again', (tester) async {
      await _useRepository(_FlakyEvolutionRepository(db: db));
      await pumpEvolution(tester, ready: 'k07-retry');

      expectTapTarget(tester, 'k07-retry');
      await disposeApp(tester);
    });

    testWidgets('the no-child card’s Choose', (tester) async {
      await emptySeed(tester);
      await pumpEvolution(tester, ready: 'k07-choose');

      expectTapTarget(tester, 'k07-choose');
      await disposeApp(tester);
    });

    testWidgets('the targets hold at 320 px and text scale 1.3', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAppRoute(tester, '/pip-evolution');
      // `pumpAppRoute` pins 390x844 itself, so apply the width after it.
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pump();
      await _settle(tester);
      expect(
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
        320,
        reason: 'this test must really run at 320 logical px',
      );

      expectTapTarget(tester, 'k07-lock');
      expectTapTarget(tester, 'k07-cta');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('spoken labels', () {
    testWidgets('the lock speaks the design’s own aria-label', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      // `<button class="lock-btn lg" … aria-label="Grown-ups">`
      final node = tester.getSemantics(find.byKey(const Key('k07-lock')));
      expect(node.getSemanticsData().label, 'Grown-ups');
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the CTA speaks its visible label once', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      // The shared `NestKidButton` excludes its inner label so VoiceOver does
      // not announce the text twice: exactly ONE node carries the label, and it
      // is a real button with the tap action attached.
      expect(find.bySemanticsLabel('Meet Fledgling Pip'), findsOneWidget);
      final node = tester
          .getSemantics(find.byKey(const Key('k07-cta')))
          .getSemanticsData();
      expect(node.label, 'Meet Fledgling Pip');
      expect(node.hasAction(SemanticsAction.tap), isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the new Pip is announced as an image, the old one is not', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      final image = tester
          .getSemantics(find.byKey(const Key('k07-new-pip')))
          .getSemanticsData();
      expect(image.flagsCollection.isImage, isTrue);
      expect(image.label, "Maya's Pip, a fledgling");
      expect(image.hasAction(SemanticsAction.tap), isFalse);

      // The design's `alt=""` on the old slot: decorative, so it must not be
      // announced at all.
      expect(
        find.descendant(
          of: find.byKey(const Key('k07-old-pip')),
          matching: find.bySemanticsLabel(RegExp('.')),
        ),
        findsNothing,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the stats row is one merged sentence, not six fragments', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      expect(
        tester
            .getSemantics(find.byKey(const Key('k07-stats')))
            .getSemanticsData()
            .label,
        '$_mayaQuestsDone quests done, $_mayaTotalCoins coins grown, '
        'stage $_mayaStage of 4',
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('non-controls advertise no tap action', () {
    testWidgets('nothing informative on the loaded screen reads as a button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      for (final key in <String>[
        'k07-title',
        'k07-sub',
        'k07-speech',
        'k07-stats',
        'k07-caption',
        'k07-stage',
        'k07-old-pip',
        'k07-arrow',
      ]) {
        expect(
          hasTap(tester, find.byKey(Key(key))),
          isFalse,
          reason: '$key is display-only',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the failure card has no phantom control', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_FlakyEvolutionRepository(db: db));
      await pumpEvolution(tester, ready: 'k07-retry');

      // The Pip on the failure card stands in for the child, so it is an
      // image at most — never a button. Only the retry and the lock are
      // controls on this card.
      expect(find.byKey(const Key('k07-cta')), findsNothing);
      expect(hasTap(tester, find.text('Oh no! Pip got lost.')), isFalse);
      expect(hasTap(tester, find.text("Let's try again.")), isFalse);
      expect(hasTap(tester, find.byKey(const Key('k07-lock'))), isTrue);
      expect(hasTap(tester, find.byKey(const Key('k07-retry'))), isTrue);
      expect(tappableLabels(tester), <String>['Grown-ups', 'Try again']);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the no-child card has no phantom control', (tester) async {
      final semantics = tester.ensureSemantics();
      await emptySeed(tester);
      await pumpEvolution(tester, ready: 'k07-choose');

      expect(find.byKey(const Key('k07-cta')), findsNothing);
      expect(hasTap(tester, find.text("Who's playing?")), isFalse);
      expect(hasTap(tester, find.byKey(const Key('k07-choose'))), isTrue);
      expect(hasTap(tester, find.byKey(const Key('k07-lock'))), isTrue);
      expect(tappableLabels(tester), <String>['Choose', 'Grown-ups']);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('the real VoiceOver actions drive the real behaviour', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the CTA goes to Pip’s nest (/pip)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpEvolution(tester, theme: theme);
        expect(currentPath(tester), '/pip-evolution');

        performTap(tester, find.bySemanticsLabel('Meet Fledgling Pip'));
        await _settle(tester);

        expect(currentPath(tester), '/pip');
        semantics.dispose();
        await disposeApp(tester);
      });

      testWidgets('${theme.name}: the lock pushes the parental gate', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpEvolution(tester, theme: theme);

        performTap(tester, find.bySemanticsLabel('Grown-ups'));
        await _settle(tester);

        expect(pushedPath(tester), '/parental-gate');
        semantics.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('Try again really reloads the screen', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _FlakyEvolutionRepository(db: db);
      await _useRepository(repo);
      await pumpEvolution(tester, ready: 'k07-retry');
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);

      repo.fail = false;
      performTap(tester, find.bySemanticsLabel('Try again'));
      await _settle(tester);

      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(currentPath(tester), '/pip-evolution');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Choose really routes to the picker', (tester) async {
      final semantics = tester.ensureSemantics();
      await emptySeed(tester);
      await pumpEvolution(tester, ready: 'k07-choose');

      performTap(tester, find.bySemanticsLabel('Choose'));
      await _settle(tester);

      expect(pushedPath(tester), '/who-is-playing');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('one VoiceOver tap on the lock opens one gate', (tester) async {
      // The screen guards double taps with a `_busy` flag; a burst must not
      // stack two gate routes on the Navigator.
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      performTap(tester, find.bySemanticsLabel('Grown-ups'));
      performTap(tester, find.bySemanticsLabel('Grown-ups'));
      await _settle(tester);

      expect(pushedPath(tester), '/parental-gate');
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}
