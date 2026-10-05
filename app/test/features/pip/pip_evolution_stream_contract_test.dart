// K07 · Pip evolves — the VIEW side of iteration 2's per-stream contract,
// plus the two layout edges the FittedBox and the bar change introduced.
//
// `2a` pinned the state contract and `pip_evolution_view_test.dart` pins the
// happy path, but three things the build changed had no test at all:
//
//   * **A NEST failure on `/pip-evolution`.** Iteration 2 deleted the sibling
//     branch (`if (nest != null) return _EvolutionFailure(...)`) so the screen
//     reads `state.evolutionStatus` only. The suite had the opposite case (the
//     nest healthy, K07 failing → the failure card) and nothing for this one:
//     the mirror, which is the direction the deleted branch used to break. It is
//     also the direction the real streams take — `watchEvolution()`'s first
//     emission needs real Drift I/O, so a sibling failure can land FIRST.
//   * **The `.kid-bar` ink rule** (`4_review.md` finding 5): the 3 px rule and
//     the button are now both conditional on there being a CTA. Nothing
//     asserted it, so unifying the bar again would have gone unnoticed.
//   * **The stage slot's `FittedBox`** (`K07-BUG-2`): below 350 px of slot
//     content the three fixed-size pieces downscale as one. The proof covers
//     390 and 320; **430** — the third width the brief names — was never
//     checked, so a threshold keyed on "not 390" instead of "< 350" would have
//     passed.
//
// Plus two pure edges: `questsFinished: 0` must not fall back to the row count
// (a `?? ` trap an `isPositive` check would fall into), and an action outcome
// must carry both arrival flags and both error slots, so a K06 toast can never
// re-arm or clear a stream's status.
//
// Harness rules honoured here: no database write ever happens while the app is
// pumping (that deadlocks this project's AppSession watch — see the notes in
// `k07_bugs_test.dart`), every pump is bounded (`pumpAndSettle` hangs on the
// loading spinner), and every widget test ends with `disposeApp` INSIDE the body
// (RULES §7.1).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_stage.dart';

import '../../test_scope.dart';

/// K06's stream fails; K07's is the real repository one. The state contract
/// says a sibling failure can neither fake readiness nor fake a failure, so
/// this screen must reach its celebration regardless.
class _NestFailsRepository extends PipRepositoryImpl {
  _NestFailsRepository({required super.db});

  @override
  Stream<PipNest?> watchNest() =>
      Stream<PipNest?>.error(Exception('nest down'));
}

/// K06's stream fails immediately and K07's is still in flight — the real
/// streams' ordering (the error is delivered in a microtask, the first healthy
/// emission needs Drift I/O). Broadcast so the release below can be delivered
/// after the bloc has subscribed.
class _NestFailsGatedEvolutionRepository extends PipRepositoryImpl {
  _NestFailsGatedEvolutionRepository({required super.db})
    : evolutionGate = StreamController<PipEvolution?>.broadcast();

  final StreamController<PipEvolution?> evolutionGate;

  @override
  Stream<PipNest?> watchNest() =>
      Stream<PipNest?>.error(Exception('nest down'));

  @override
  Stream<PipEvolution?> watchEvolution() => evolutionGate.stream;

  Future<void> closeGate() async {
    await evolutionGate.close();
  }
}

/// Both streams silent: the loading state, with nothing of the sibling's to
/// leak in.
class _SilentRepository extends PipRepositoryImpl {
  _SilentRepository({required super.db})
    : nestGate = StreamController<PipNest?>.broadcast(),
      evolutionGate = StreamController<PipEvolution?>.broadcast();

  final StreamController<PipNest?> nestGate;
  final StreamController<PipEvolution?> evolutionGate;

  @override
  Stream<PipNest?> watchNest() => nestGate.stream;

  @override
  Stream<PipEvolution?> watchEvolution() => evolutionGate.stream;

  Future<void> closeGates() async {
    await nestGate.close();
    await evolutionGate.close();
  }
}

/// Both load streams error: the failure card, on K07's own status.
class _BothStreamsFailRepository extends PipRepositoryImpl {
  _BothStreamsFailRepository({required super.db});

  @override
  Stream<PipNest?> watchNest() =>
      Stream<PipNest?>.error(Exception('nest down'));

  @override
  Stream<PipEvolution?> watchEvolution() =>
      Stream<PipEvolution?>.error(Exception('evolution down'));
}

/// K06's stream is healthy; K07's is driven by hand, so a MID-SESSION failure
/// (an emission followed by an error) can be delivered deterministically.
class _GatedEvolutionOnlyRepository extends PipRepositoryImpl {
  _GatedEvolutionOnlyRepository({required super.db})
    : evolutionGate = StreamController<PipEvolution?>.broadcast();

  final StreamController<PipEvolution?> evolutionGate;

  @override
  Stream<PipEvolution?> watchEvolution() => evolutionGate.stream;

  Future<void> closeGate() async {
    await evolutionGate.close();
  }
}

/// Counts every subscription, so "the retry touched only the dead stream" is an
/// observation rather than an inference. [evolutionFails] flips K07's stream from
/// erroring to healthy, which is exactly what the failure card's "Try again"
/// needs to recover.
class _RecoveringEvolutionRepository extends PipRepositoryImpl {
  _RecoveringEvolutionRepository({required super.db});

  int nestCalls = 0;
  int evolutionCalls = 0;
  bool evolutionFails = true;

  @override
  Stream<PipNest?> watchNest() {
    nestCalls++;
    return super.watchNest();
  }

  @override
  Stream<PipEvolution?> watchEvolution() {
    evolutionCalls++;
    if (evolutionFails) {
      return Stream<PipEvolution?>.error(Exception('evolution down'));
    }
    return super.watchEvolution();
  }
}

/// Maya's seeded evolution, as the real repository would deliver it.
const PipEvolution _mayaEvolution = PipEvolution(
  profile: PipProfile(
    childId: 'maya',
    nickname: 'Maya',
    style: 'mochi',
    skin: 'sunny',
    accessory: 'none',
    stage: 3,
    totalCoins: 175,
    coins: 120,
    happiness: 4,
  ),
  questsDone: 4,
);

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

/// Bounded pumps: `pumpAndSettle` would hang on the loading spinner.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps until [ready] matches (bounded to ~3 s of real time), then settles.
///
/// The screen's data arrives over real Drift streams, so a fixed fake-clock
/// delay is a race on a loaded machine; waiting for the state itself is what
/// makes the file load-independent.
Future<void> _pumpUntil(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  await _settle(tester);
}

/// `pumpAppRoute` pins 390x844 itself, so a width set before the pump is
/// overwritten; apply it after and let the tree rebuild (K06/K07's pattern).
Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The bar's painted decoration, read from the keyed `Container`.
BoxDecoration barDecoration(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(const Key('k07-bar'))).decoration!
        as BoxDecoration;

/// Every string on screen, for "raw DB text must never reach a kid screen".
List<String> screenText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .toList(growable: false);

/// The celebration bar's height: 3 (rule) + 12 + 64 + 6 (`--sh-kid` room) +
/// 4 + 34 (home reserve) = 123.
const double _celebrationBarHeight = 123;

/// A bar with no CTA: 12 + 4 + 34 — the pads and the home reserve only, with
/// neither the design's ink rule nor an empty button row.
const double _plainBarHeight = 50;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  Future<void> pumpEvolution(
    WidgetTester tester, {
    ThemeMode theme = ThemeMode.light,
    String ready = 'k07-cta',
  }) async {
    await pumpAppRoute(tester, '/pip-evolution', theme: theme);
    // The designs reserve `--status-h` 47 and `--home-h` 34, and the bar's
    // `SafeArea` only sees them on a real device. Without them the bar's
    // arithmetic below (3 + 12 + 64 + 6 + 4 + 34) loses its 34 — measured: 16
    // instead of 50 on the plain band. Faked here exactly as
    // `pip_evolution_widget_test.dart` does, AFTER the pump that pins the
    // surface itself.
    const insets = FakeViewPadding(
      top: NestDevice.statusH * 3,
      bottom: NestDevice.homeH * 3,
    );
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    await _pumpUntil(tester, find.byKey(Key(ready)));
  }

  group('the screen reads only its OWN stream', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: a NEST failure cannot take down the '
          'celebration', (tester) async {
        await _useRepository(_NestFailsRepository(db: db));
        await pumpEvolution(tester, theme: theme);

        // The screen's own stream answered, so the screen is ready — whatever
        // K06's stream did. This is the direction the deleted sibling branch
        // (`if (nest != null) return _EvolutionFailure(...)`) used to break.
        expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
        expect(find.byKey(const Key('k07-stats')), findsOneWidget);
        expect(find.byKey(const Key('k07-cta')), findsOneWidget);
        // …and never the sibling's failure card or the picker.
        expect(find.text('Oh no! Pip got lost.'), findsNothing);
        expect(find.text("Who's playing?"), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // Raw stream text is diagnostic only: no exception, no message.
        expect(
          screenText(tester)
              .where((t) => t.contains('nest down') || t.contains('Exception')),
          isEmpty,
        );
        expect(currentPath(tester), '/pip-evolution');
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('a NEST failure while this screen is still loading shows the '
        'SPINNER, then the celebration', (tester) async {
      // The real streams' ordering: the sibling error lands first, the healthy
      // emission follows. A pending screen must show the spinner — not a
      // failure card the child cannot leave, and not the picker.
      final repo = _NestFailsGatedEvolutionRepository(db: db);
      await _useRepository(repo);
      addTearDown(repo.closeGate);
      await pumpEvolution(tester, ready: 'k07-lock');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text("Who's playing?"), findsNothing);
      // K07-BUG-1's honest rule: while the screen's own stream is in flight
      // there is no recovery control at all, because there is nothing to retry.
      expect(find.byKey(const Key('k07-retry')), findsNothing);
      expect(find.byKey(const Key('k07-cta')), findsNothing);
      // The chrome is already up on the spinner (status reserve, lock, bar).
      expect(find.byKey(const Key('k07-lock')), findsOneWidget);
      expect(find.byKey(const Key('k07-bar')), findsOneWidget);

      // Release the gate with what the real repository would have delivered.
      repo.evolutionGate.add(_mayaEvolution);
      await _pumpUntil(tester, find.byKey(const Key('k07-cta')));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(find.text('Meet Fledgling Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a NEST failure still leaves the K06 mirror working: the failure card '
        'belongs to K07 alone', (tester) async {
      // Sanity on the direction the ruling protects: with BOTH streams failing,
      // K07's own status is `failure`, so the card appears — the nest's failure
      // is not what put it there.
      await _useRepository(_BothStreamsFailRepository(db: db));
      await pumpEvolution(tester, ready: 'k07-retry');

      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.byKey(const Key('k07-retry')), findsOneWidget);
      expect(find.text("Who's playing?"), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('a hiccup is not a failure card', () {
    testWidgets('a mid-session evolution failure keeps the celebration on '
        'screen', (tester) async {
      final repo = _GatedEvolutionOnlyRepository(db: db);
      await _useRepository(repo);
      addTearDown(repo.closeGate);
      await pumpEvolution(tester, ready: 'k07-lock');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.evolutionGate.add(_mayaEvolution);
      await _pumpUntil(tester, find.byKey(const Key('k07-cta')));
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);

      // Now the stream fails, having ALREADY answered: `evolutionSettled` stays
      // true, so K07 keeps its own status `loaded`. A child must not be thrown
      // out of the celebration by a hiccup (the K03 review-finding-6
      // keep-loaded rule), and the raw stream text must never appear.
      repo.evolutionGate.addError(Exception('evolution down'));
      await _settle(tester);

      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(find.byKey(const Key('k07-cta')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        screenText(tester).where((t) => t.contains('evolution down')),
        isEmpty,
      );
      // The screen is still live: the CTA really navigates.
      await tester.tap(find.byKey(const Key('k07-cta')));
      await _settle(tester);
      expect(currentPath(tester), '/pip');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Try again re-subscribes ONLY the stream that died', (
      tester,
    ) async {
      final repo = _RecoveringEvolutionRepository(db: db);
      await _useRepository(repo);
      await pumpEvolution(tester, ready: 'k07-retry');

      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(repo.nestCalls, 1, reason: 'K06 answered on the first load');
      expect(repo.evolutionCalls, 1);
      // The card's last-known Pip is the NEST's row, which is healthy.
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.stage, 3);

      repo.evolutionFails = false;
      await tester.tap(find.byKey(const Key('k07-retry')));
      await _pumpUntil(tester, find.byKey(const Key('k07-cta')));

      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(repo.evolutionCalls, 2, reason: 'the dead stream was re-listened');
      expect(
        repo.nestCalls,
        1,
        reason:
            'the healthy subscription was never released, so the retry must '
            'not re-listen it — `toLoading(restartingNest: false)` keeps '
            'K06 loaded instead of dropping it on a spinner '
            '(4_review.md finding 1)',
      );
      expect(currentPath(tester), '/pip-evolution');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group("the design's ink rule belongs to the design's button", () {
    // `4_review.md` finding 5: `.kid-bar`'s 3 px ink rule and its CTA are one
    // unit in the design. With no button there is nothing for the rule to
    // separate, and a full-width 3 px rule over a 50 px empty band read as a
    // broken button row. The SURFACE box stays on every state — that is the
    // owner BOTTOM EDGE rule, and it is asserted in each case below.

    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '${theme.name}: the celebration bar keeps the 3 px ink rule',
        (tester) async {
          await pumpEvolution(tester, theme: theme);

          final border = barDecoration(tester).border;
          expect(border, isNotNull, reason: '.kid-bar { border-top: 3px }');
          expect(
            border!.top.width,
            closeTo(contextKidBorder(tester), 0.01),
            reason: 'the shared kid border width, not a literal',
          );
          expect(barDecoration(tester).color, surfaceOf(tester));
          expect(
            tester.getRect(find.byKey(const Key('k07-bar'))).height,
            closeTo(_celebrationBarHeight, 1),
          );

          await disposeApp(tester);
        },
      );
    }

    testWidgets('the loading bar is a plain surface band, still to the edge', (
      tester,
    ) async {
      final repo = _SilentRepository(db: db);
      await _useRepository(repo);
      addTearDown(repo.closeGates);
      await pumpEvolution(tester, ready: 'k07-lock');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final decoration = barDecoration(tester);
      expect(decoration.border, isNull, reason: 'no rule without a button');
      expect(decoration.color, surfaceOf(tester));
      final bar = tester.getRect(find.byKey(const Key('k07-bar')));
      expect(bar.height, closeTo(_plainBarHeight, 1), reason: '12 + 4 + 34');
      // Owner bottom-edge rule, unchanged by the rule removal.
      expect(bar.left, 0);
      expect(bar.right, NestDevice.width);
      expect(bar.bottom, closeTo(NestDevice.height, 0.5));

      await disposeApp(tester);
    });

    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the failure bar is a plain surface band', (
        tester,
      ) async {
        await _useRepository(_BothStreamsFailRepository(db: db));
        await pumpEvolution(tester, theme: theme, ready: 'k07-retry');

        expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
        final decoration = barDecoration(tester);
        expect(decoration.border, isNull);
        expect(decoration.color, surfaceOf(tester));
        final bar = tester.getRect(find.byKey(const Key('k07-bar')));
        expect(bar.height, closeTo(_plainBarHeight, 1));
        expect(bar.bottom, closeTo(NestDevice.height, 0.5));
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the no-child bar is a plain surface band too', (tester) async {
      await tester.runAsync(() async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
      await pumpEvolution(tester, ready: 'k07-choose');

      expect(find.text("Who's playing?"), findsOneWidget);
      final decoration = barDecoration(tester);
      expect(decoration.border, isNull);
      expect(decoration.color, surfaceOf(tester));
      final bar = tester.getRect(find.byKey(const Key('k07-bar')));
      expect(bar.height, closeTo(_plainBarHeight, 1));
      expect(bar.bottom, closeTo(NestDevice.height, 0.5));

      await disposeApp(tester);
    });
  });

  group('the stage slot keeps the design geometry above 350 px', () {
    // `K07-BUG-2`'s fix downscales the slot's three fixed-size pieces only when
    // the content box is narrower than the design's 350
    // (`EvolutionStageGeometry.designSlotWidth`). The proofs cover 390 and 320;
    // 430 is the third width the brief names, and it must stay at scale 1.0 —
    // a threshold keyed on anything other than the slot's width would not have
    // been caught.

    testWidgets('at 430 px nothing is downscaled', (tester) async {
      await pumpEvolution(tester);
      await _resize(tester, 430);

      final slot = tester.getRect(find.byKey(const Key('k07-stage')));
      final grown = tester.getRect(find.byKey(const Key('k07-new-pip')));
      final arrow = tester.getRect(find.byKey(const Key('k07-arrow')));
      final old = tester.getRect(find.byKey(const Key('k07-old-pip')));

      expect(slot.width, closeTo(430 - 2 * NestSpacing.padSide, 1));
      // Design values, unscaled: `.k7-new` 240 at right 6, `.k7-arrow` 30 at
      // left 76, `.k7-old` 68 at left 2, bottom 4.
      expect(grown.width, closeTo(EvolutionStageGeometry.newSize, 0.5));
      expect(grown.height, closeTo(EvolutionStageGeometry.newSize, 0.5));
      expect(
        slot.right - grown.right,
        closeTo(EvolutionStageGeometry.newRight, 1),
        reason: "still anchored 6 px from the slot's right edge",
      );
      expect(
        arrow.left - slot.left,
        closeTo(EvolutionStageGeometry.arrowLeft, 1),
      );
      expect(arrow.width, closeTo(EvolutionStageGeometry.arrowSize, 0.5));
      expect(old.width, closeTo(EvolutionStageGeometry.oldSize, 0.5));
      expect(old.left - slot.left, closeTo(EvolutionStageGeometry.oldLeft, 1));
      // The design's own 2 px tuck, at any width above the threshold.
      expect(grown.left - arrow.right, greaterThanOrEqualTo(-2.0));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('at 320 px the three pieces downscale as ONE piece', (
      tester,
    ) async {
      await pumpEvolution(tester);
      await _resize(tester, 320);

      final slot = tester.getRect(find.byKey(const Key('k07-stage')));
      final grown = tester.getRect(find.byKey(const Key('k07-new-pip')));
      final arrow = tester.getRect(find.byKey(const Key('k07-arrow')));
      final old = tester.getRect(find.byKey(const Key('k07-old-pip')));

      // One `FittedBox` wraps all three, so they share a scale factor.
      final scale = grown.width / EvolutionStageGeometry.newSize;
      expect(scale, lessThan(1.0), reason: '320 px cannot hold 350 px of art');
      expect(
        arrow.width / EvolutionStageGeometry.arrowSize,
        closeTo(scale, 0.01),
        reason: 'the arrow scales with the Pip, not on its own',
      );
      expect(old.width / EvolutionStageGeometry.oldSize, closeTo(scale, 0.01));
      // `alignment: bottomRight` keeps the grown Pip's design inset (scaled).
      expect(
        slot.right - grown.right,
        closeTo(EvolutionStageGeometry.newRight * scale, 1.5),
      );
      // Legibility is `k07_bugs_test.dart`'s K07-BUG-2 proof; this asserts the
      // mechanism it relies on.
      expect(grown.left - arrow.right, greaterThanOrEqualTo(-2.0));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('entity + state edges', () {
    test('questsFinished: 0 is a count, not a missing value', () {
      // `int?` with `??`: a distinct-quest count of ZERO must stay zero. An
      // `isNotEmpty` / `> 0` style fallback would read it as "unknown" and put
      // the row count on a card that is about quests.
      const none = PipEvolution(
        profile: PipProfile(
          childId: 'maya',
          nickname: 'Maya',
          style: 'mochi',
          skin: 'sunny',
          accessory: 'none',
          stage: 3,
          totalCoins: 175,
          coins: 120,
          happiness: 4,
        ),
        questsDone: 3,
        questsFinished: 0,
      );
      expect(none.questsFinishedCount, 0);
      expect(none.questsDone, 3, reason: 'the sub-line still counts rows');

      // Two entities that differ only in the distinct count are different
      // states, so the card repaints.
      const four = PipEvolution(
        profile: PipProfile(
          childId: 'maya',
          nickname: 'Maya',
          style: 'mochi',
          skin: 'sunny',
          accessory: 'none',
          stage: 3,
          totalCoins: 175,
          coins: 120,
          happiness: 4,
        ),
        questsDone: 3,
        questsFinished: 4,
      );
      expect(none, isNot(four));
      expect(four.questsFinishedCount, 4);
    });

    test(
      'an action outcome carries both arrival flags and both error slots',
      () {
        // K06's care / wardrobe taps write to this same state. If either path
        // dropped a flag or a slot, a toast could silently re-arm a stream
        // (`nestSettled: false` on a loaded screen → `/pip`'s spinner again) or
        // clear a failure (`nestError: null` → the retry card disappears).
        const settled = PipState(
          status: PipStatus.loading,
          nestSettled: true,
          evolutionError: 'evolution down',
        );

        final started = settled.withActionStarted();
        expect(started.nestSettled, isTrue);
        expect(started.evolutionSettled, isFalse);
        expect(started.evolutionError, 'evolution down');
        expect(
          started.nestStatus,
          PipStatus.loaded,
          reason: 'K06 is still loaded after a K06 action',
        );
        expect(
          started.evolutionStatus,
          PipStatus.failure,
          reason: 'K07 is still failed after a K06 action',
        );

        final failed = started.withActionFailed(Exception('not enough coins'));
        expect(failed.nestSettled, isTrue);
        expect(failed.evolutionError, 'evolution down');
        expect(failed.nestStatus, PipStatus.loaded);
        expect(failed.evolutionStatus, PipStatus.failure);
        expect(failed.actionNonce, 1);
      },
    );
  });
}

/// The theme's surface token, read from the bar's own subtree so the assertion
/// is "the bar is painted with `tokens.surface`" and not a literal colour.
Color surfaceOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(const Key('k07-bar'))))
        .extension<NestTokens>()!
        .surface;

/// The shared kid border width (`context.nestKid.borderWidth`), read from the
/// same subtree — the rule's 3 px is a token, never a literal in the screen.
double contextKidBorder(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(const Key('k07-bar'))))
        .extension<NestKidTheme>()!
        .borderWidth;
