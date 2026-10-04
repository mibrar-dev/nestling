// K07 (Pip evolves, `/pip-evolution`) — Stage 6 adversarial bug proofs.
//
// ITERATION 2. No product code changed in this stage (RULES §1: a bug hunt may
// add only `app/test/features/pip/**` and `docs/screens/K07/**`); iteration
// 1's K07-BUG-1/2 are re-measured against the current tree and still fail, so
// they keep their ids and proofs. K07-BUG-3 is new.
//
// Every `testWidgets`/`test` carrying a `K07-BUG-n` id FAILS by design, so the
// suite stays green: each is parked with `skip: true` (Flutter's `test` takes a
// BOOL skip — the id lives in the description, the repo convention from
// `k06_bugs_test.dart`). Run them all with
//
//   cd app && flutter test --timeout 120s --run-skipped \
//       test/features/pip/k07_bugs_test.dart
//
// and drop `skip: true` in the fix commit. The `cleared:` / `control:` tests
// are NOT skipped: they pin what the hunt cleared, so the fixes cannot be
// "remove the guard" / "hard-code the demo numbers".
//
// Hunt matrix (the brief's list) and where each item is pinned:
//   0 children / no active child ....... `control: no active child…`
//   a child picked afterwards .......... `control: the no-child card…` (new)
//   1 child, 6 children, ghost child .... control + K07-BUG-1
//   active-child switch (Maya -> Leo) .. `control: switching…` (new)
//   long UK name, 9999 coins ............ control (passing)
//   repeated quest completion .......... K07-BUG-3 (new)
//   rapid double taps ................... controls (passing)
//   back nav / deep link / gate ......... controls (passing)
//   Drift persistence across reopen ..... covered in iteration 1 (cleared)
//   dark-mode contrast .................. cleared in iteration 1
//   text scale 1.3 + width 320 .......... K07-BUG-2 + control
//   async gaps (stream still in flight) . K07-BUG-1, K07-BUG-2,
//                                           `control: a late emission after…` (new)
//   timezone / money rounding ........... n/a — K07 reads no clock and no £
//                                          (lifetime integer counters only)
//
// ASYNC-GAP NOTE (learned the hard way): a Drift WRITE issued while the app is
// pumped inside `tester.runAsync` can deadlock this harness when the written
// table is one a live watch is sitting on (measured: an INSERT into
// `quest_completions` with `watchCompletionsForChild` live hangs at the
// `await db.insert`, and `--timeout` cannot fire inside the fake-async zone).
// So K07-BUG-3's widget proof writes BEFORE the first pump, and its second
// proof is a plain real-async `test` with no widget tree at all.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';

import '../../test_scope.dart';

/// K07-BUG-1 repro repository: the NEST stream is real (the demo seed makes it
/// emit a full nest promptly), while the EVOLUTION stream stays open and
/// silent — it has neither emitted a value NOR failed. That is exactly what a
/// slow `watchEvolution()` looks like to the bloc, and `watchEvolution`
/// combines two Drift tables (profile + completions) against the nest's three
/// (profile + wardrobe + ordered stages), so the two streams are genuinely
/// unordered.
class _PendingEvolutionRepository extends PipRepositoryImpl {
  _PendingEvolutionRepository({required super.db, required this.delivered});

  /// Silent until the test closes it: no value, no error.
  final StreamController<PipEvolution?> evolutionGate =
      StreamController<PipEvolution?>.broadcast();

  /// What the stream delivers when the gate opens, so the test can prove the
  /// screen recovers to the celebration instead of hanging on the spinner.
  final PipEvolution? delivered;

  /// Every `watchEvolution()` call — proves a retry either reloads or is not
  /// offered at all, never a dead button over a live subscription.
  int evolutionCalls = 0;

  @override
  Stream<PipEvolution?> watchEvolution() {
    evolutionCalls++;
    return evolutionGate.stream;
  }

  Future<void> closeGate() async {
    evolutionGate.add(delivered);
    await evolutionGate.close();
  }
}

/// Cleared-investigation harness for the "is the retry really dead?" question
/// (`6_bugs.md` §"Investigated and cleared"). Two failure delivery shapes are
/// exercised, because the bloc's guard reads a field that `onError` clears:
///
///  * [failFast] -> `Stream.error(...)`, the shape a fake repository uses;
///  * [failSlow] -> `addError` on a broadcast controller, the shape every real
///    Drift stream uses.
class _FailingRepository extends PipRepositoryImpl {
  _FailingRepository({required super.db, required this.failFast});

  final bool failFast;

  final StreamController<PipNest?> nestGate =
      StreamController<PipNest?>.broadcast();
  final StreamController<PipEvolution?> evolutionGate =
      StreamController<PipEvolution?>.broadcast();

  int nestCalls = 0;
  int evolutionCalls = 0;

  @override
  Stream<PipNest?> watchNest() {
    nestCalls++;
    if (!failFast) return nestGate.stream;
    return Stream<PipNest?>.error(Exception('nest down'));
  }

  @override
  Stream<PipEvolution?> watchEvolution() {
    evolutionCalls++;
    if (!failFast) return evolutionGate.stream;
    return Stream<PipEvolution?>.error(Exception('evolution down'));
  }

  void failSlow() {
    nestGate.addError(Exception('nest down'));
    evolutionGate.addError(Exception('evolution down'));
  }

  Future<void> closeGates() async {
    await nestGate.close();
    await evolutionGate.close();
  }
}

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

/// Bounded pumps: `pumpAndSettle` never returns on the loading spinner.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpEvolution(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
}) async {
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip-evolution', theme: theme);
  await _settle(tester);
}

/// Resizes the surface AFTER `pumpAppRoute` (which forces 390x844) and lets
/// the tree rebuild — the established K06/K07 width-matrix pattern.
Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  await _settle(tester);
}

/// A second `approved` row for `q-bins`, which Maya has already had approved
/// once. Legal in the schema (no unique index on (questId, childId)) and
/// routine in the product: a `daily`/`weekly` quest is re-completable, and K05
/// inserts one row per completion. Writes NOTHING the app does not write.
Future<void> _addDuplicateCompletion(AppDatabase db) => db
    .into(db.questCompletions)
    .insert(
      QuestCompletionsCompanion.insert(
        questId: 'q-bins',
        childId: 'maya',
        familyId: Seed.familyId,
        status: const Value('approved'),
        coins: const Value(15),
        createdAt: Value(Seed.utc(10, 3, 8, 30)),
        createdAtTz: const Value('Europe/London'),
      ),
    );

/// Real-async poll, up to ~3 s — the repository suite's pattern. The per-test
/// `--timeout` still bounds any hang.
Future<void> _waitFor(bool Function() ready) async {
  for (var i = 0; i < 300 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// The painted box of sparkle 1 in the art canvas: art `y` extent, the row that
/// is widest, and the horizontal extent. Rasterising the layer's own painter is
/// the pattern `pip_evolution_sparks_test.dart` already established (Skia's
/// software raster is deterministic, so these numbers are reproducible).
///
/// Only the lilac fill in the art's left 100 px is scanned, which is sparkle 1
/// alone: the other three sparkles are success/coin/peach and the second lilac
/// entry is the dot at art (286, 210).
typedef _SparkleBox = ({int top, int bottom, int widest, int left, int right});

/// Paints the layer's own painter into a raster and measures sparkle 1.
///
/// * why a raster: the defect is in the PATH, so the only honest proof reads
///   the pixels back. `pip_evolution_sparks_test.dart` already established
///   this harness (Skia's software raster is deterministic, so the numbers are
///   reproducible run to run).
/// * what is scanned: the lilac fill in the art's left 100 px, which is
///   sparkle 1 alone — the other three sparkles are success/coin/peach, and the
///   only other lilac entry is the dot at art (286, 210).
/// * why symmetry, not an exact outline: a 4-point sparkle's tip and base are
///   equidistant from its side points, so its painted box MUST be symmetric
///   about its own middle whatever the antialiasing does at the tips. The
///   tip-less shape is symmetric about neither its middle nor the design's
///   centre line, so this cannot be satisfied by luck.
Future<_SparkleBox> _sparkleBox(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: EvolutionSparksGeometry.boxWidth,
            height: EvolutionSparksGeometry.boxHeight,
            child: PipEvolutionSparks(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final painter = tester
      .widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(PipEvolutionSparks),
              matching: find.byType(CustomPaint),
            )
            .first,
      )
      .painter!;

  const size = EvolutionSparksGeometry.artSize;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final rgba = (await tester.runAsync(() async {
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    // `rawRgba` is `toByteData`'s default: four bytes per pixel, straight (not
    // premultiplied) alpha, so the alpha test below reads 255 on a real fill.
    final data = (await image.toByteData())!;
    image.dispose();
    return data.buffer.asUint8List();
  }))!;

  final width = size.width.toInt();
  var top = 1 << 30;
  var bottom = -1;
  var left = 1 << 30;
  var right = -1;
  var widest = -1;
  var widestWidth = 0;
  for (var y = 0; y < size.height.toInt(); y++) {
    var rowLo = 1 << 30;
    var rowHi = -1;
    for (var x = 0; x < 100; x++) {
      final i = (y * width + x) * 4;
      if ((rgba[i] - 0x7C).abs() <= 24 &&
          (rgba[i + 1] - 0x6C).abs() <= 24 &&
          (rgba[i + 2] - 0xF2).abs() <= 24 &&
          rgba[i + 3] >= 200) {
        if (x < rowLo) rowLo = x;
        if (x > rowHi) rowHi = x;
      }
    }
    if (rowHi < 0) continue;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
    if (rowLo < left) left = rowLo;
    if (rowHi > right) right = rowHi;
    if (rowHi - rowLo + 1 > widestWidth) {
      widestWidth = rowHi - rowLo + 1;
      widest = y;
    }
  }
  expect(top, lessThan(1 << 30), reason: 'sparkle 1 must be painted');
  return (top: top, bottom: bottom, widest: widest, left: left, right: right);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  // ---------------------------------------------------------------------------
  // K07-BUG-1 — FIXED in iteration 2's build (per-stream arrival + error slots).
  // The widget proof above is parked until the view switches on
  // `state.evolutionStatus`; the state-level proof below is this layer's and
  // is green again.
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-1: a still-pending evolution stream renders the load-failure card '
    '("Oh no! Pip got lost.") instead of the spinner, and its "Try again" is a '
    'dead control',
    (tester) async {
      // Read what the real stream would deliver BEFORE the fake stands in for
      // it, so the release below lands the genuine evolution on screen.
      // `runAsync`: a real Drift read inside the fake-async zone deadlocks.
      final delivered = await tester.runAsync(
        () => PipRepositoryImpl(db: db).watchEvolution().first,
      );
      final repo = _PendingEvolutionRepository(db: db, delivered: delivered);
      await _useRepository(repo);
      await _pumpEvolution(tester);

      // Nothing has failed: the evolution stream is open and silent. The only
      // honest state is the spinner.
      expect(
        find.text('Oh no! Pip got lost.'),
        findsNothing,
        reason:
            'the evolution stream has NOT failed — it is still in flight, so '
            'the failure card is a false verdict on a kid screen',
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'the screen must say it is still loading Pip',
      );
      expect(find.byKey(const Key('k07-title')), findsNothing);

      // A pending stream must not be offered a retry at all: the bloc ignores
      // a reload while both subscriptions are live, so the control the old
      // false card painted was dead. (A REAL failure does re-subscribe — see
      // the `cleared:` proof in this file.)
      expect(repo.evolutionCalls, 1);
      expect(
        find.byKey(const Key('k07-retry')),
        findsNothing,
        reason:
            'a stream that has not failed must not offer a retry whose tap the '
            'bloc silently drops',
      );

      // …and when the stream really does answer, the celebration replaces the
      // spinner.
      await repo.closeGate();
      await _settle(tester);
      expect(find.byKey(const Key('k07-title')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await disposeApp(tester);
    },
  );

  test(
    'K07-BUG-1 (real repository, no fakes): the bloc publishes a "loaded" state '
    'with a nest but no evolution, which /pip-evolution renders as "Oh no! Pip '
    'got lost."',
    () async {
      // The SAME defect with the shipped `PipRepositoryImpl`, observed at the
      // state level instead of through the widget tree, so it cannot be blamed
      // on the fake's timing. `pip_bloc.dart` subscribes to the NEST stream
      // first (line 51) and to the evolution stream second (line 60), and
      // `copyWithLoaded` publishes `loaded` with `evolution == null`.
      var falseFailures = 0;
      const runs = 5;
      for (var i = 0; i < runs; i++) {
        final bloc = PipBloc(repository: PipRepositoryImpl(db: db));
        final seen = <PipState>[];
        final sub = bloc.stream.listen(seen.add);
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await bloc.close();
        await sub.cancel();
        if (seen.any(
          (s) =>
              s.status == PipStatus.loaded &&
              s.evolution == null &&
              s.nest != null,
        )) {
          falseFailures++;
        }
      }
      expect(
        falseFailures,
        0,
        reason:
            '$falseFailures of $runs cold opens published `loaded` before the '
            'evolution arrived — the K07 view renders exactly that state as '
            'the load-failure card (pip_evolution_view.dart:94-95)',
      );
    },
  );

  // ---------------------------------------------------------------------------
  // K07-BUG-2 — still open on iteration 2 (the fix never landed).
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-2: at 320 px the grown 240 px Pip covers the 68 px old Pip and the '
    '30 px arrow, so the before -> after story is unreadable',
    (tester) async {
      await _pumpEvolution(tester);

      // Reference: the design at 390 lets `.k7-arrow` (76..106) tuck exactly
      // 2 px under `.k7-new` (104..344); nothing may be covered beyond that.
      const designOverlap = 2.0;
      final wideArrow = tester.getRect(find.byKey(const Key('k07-arrow')));
      final wideNew = tester.getRect(find.byKey(const Key('k07-new-pip')));
      expect(
        wideNew.left - wideArrow.right,
        greaterThanOrEqualTo(-designOverlap),
        reason: 'design sanity: the arrow only tucks 2 px at 390',
      );

      await _resize(tester, 320);

      final oldRect = tester.getRect(find.byKey(const Key('k07-old-pip')));
      final arrowRect = tester.getRect(find.byKey(const Key('k07-arrow')));
      final newRect = tester.getRect(find.byKey(const Key('k07-new-pip')));

      // 320 is a supported width (docs/design/SPACING_SPEC.md:369 plans 320
      // layouts), but 2 + 68 + 6 + 30 + 6 + 240 = 352 > 280 of content, so
      // the fixed-size grown Pip slides left over both comparison glyphs.
      expect(
        newRect.left - arrowRect.right,
        greaterThanOrEqualTo(-designOverlap),
        reason:
            "at 320 the arrow sits entirely inside the grown Pip's box "
            '(arrow ${arrowRect.left}..${arrowRect.right}, Pip '
            '${newRect.left}..${newRect.right})',
      );
      expect(
        newRect.left - oldRect.right,
        greaterThanOrEqualTo(-designOverlap),
        reason:
            'at 320 the old Pip is '
            '${(oldRect.right - newRect.left).round()}px covered by the grown '
            'Pip',
      );

      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // K07-BUG-3 — FIXED in iteration 2's build: `watchEvolution` now reports the
  // distinct-quest count for the milestone card (2a) and the stats card is fed
  // `evolution.questsFinishedCount` (2b). Both proofs are un-skipped.
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-3: the "quests done" card counts completion ROWS, so completing '
    'the same quest twice inflates a milestone that is about quests',
    (tester) async {
      // The duplicate row is written BEFORE anything is pumped, so no live
      // watch exists yet — a DB write while the app is pumped deadlocks this
      // harness (see the async-gap note in the file header).
      await tester.runAsync(() => _addDuplicateCompletion(db));
      await _pumpEvolution(tester);

      // Demo truth: Maya has 4 DISTINCT quests done (q-dishwasher + q-table
      // `done_pending`, q-bins + q-hoover `approved`) plus a second approval
      // of q-bins — still 4 quests.
      final number = tester.widget<Text>(
        find.byKey(const Key('k07-stat-quests')),
      );
      expect(
        number.data,
        '4',
        reason:
            'the card is labelled "quests done" on a quest-milestone screen, so '
            're-approving q-bins (5 completion ROWS, 4 distinct quests) must '
            'not move it',
      );
      expect(
        find.text('Because you helped 5 times'),
        findsOneWidget,
        reason:
            'the sub-line is the honest per-completion sentence and MAY count '
            'rows — the two numbers disagreeing is exactly the symptom',
      );

      await disposeApp(tester);
    },
  );

  test('K07-BUG-3 (repository, no widget tree): watchEvolution reports 5 for 4 '
      'distinct quests after one quest is completed twice', () async {
    final local = AppDatabase.memory();
    await Seed.demo(local);
    addTearDown(local.close);
    final repo = PipRepositoryImpl(db: local);

    final seen = <PipEvolution?>[];
    final sub = repo.watchEvolution().listen(seen.add);
    await _waitFor(() => seen.isNotEmpty);
    expect(seen.last!.questsDone, 4, reason: 'demo truth: 4 rows');

    await _addDuplicateCompletion(local);
    await _waitFor(() => seen.length > 1);
    // The re-emit must have landed with the inflated row count, or the proof
    // below would pass for the wrong reason.
    await _waitFor(() => seen.last?.questsDone == 5);

    final rows = await local.select(local.questCompletions).get();
    final counted = rows
        .where(
          (c) =>
              c.childId == 'maya' &&
              (c.status == 'done_pending' || c.status == 'approved'),
        )
        .toList();
    final distinct = counted.map((c) => c.questId).toSet();

    // The card's number is the distinct one (`questsFinishedCount`), while the
    // sub-line honestly keeps the per-completion row count (`questsDone`) —
    // which is why both are asserted here.
    expect(
      seen.last!.questsFinishedCount,
      distinct.length,
      reason:
          '${counted.length} completion rows cover only ${distinct.length} '
          'distinct quests (${distinct.join(', ')}), so "quests done" must '
          'count quests, not rows',
    );
    expect(
      seen.last!.questsDone,
      counted.length,
      reason: 'the sub-line still counts completions ("helped 5 times")',
    );

    await sub.cancel();
  });

  // ---------------------------------------------------------------------------
  // K07-BUG-4 — new on iteration 2: the exact cause behind `5_ui.md` D2.
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-4: every confetti sparkle loses its `M` tip vertex, so the '
    "design's 4-point sparkle is painted as a flat-topped blob",
    (tester) async {
      final box = await _sparkleBox(tester);

      // `M32 30 37 44 51 49 37 54 32 68 27 54 13 49 27 44Z` — the tip (32,30)
      // and the base (32,68) are equidistant from the side points at y = 49, so
      // the painted sparkle must be symmetric about its own middle, and that
      // middle is the design's y = 49.
      final middle = (box.top + box.bottom) / 2;
      expect(
        box.bottom - box.top,
        greaterThanOrEqualTo(20),
        reason:
            'the painted sparkle is only ${box.bottom - box.top} px tall '
            "(art rows ${box.top}..${box.bottom}); the design's 38 px sparkle "
            'paints ~23 after the 3 px ink stroke eats both tips. The missing '
            'height is the top arm: `Path.moveTo` draws nothing and '
            "addPolygon(close: true) closes to the polygon's OWN first "
            'point, so the `M 32 30` tip is never stroked or filled.',
      );
      expect(
        (box.widest - middle).abs(),
        lessThanOrEqualTo(2),
        reason:
            'the widest row is art y ${box.widest} but the painted box is '
            '${box.top}..${box.bottom} (middle $middle) — a 4-point sparkle is '
            'symmetric about its side points (design y 49), so this is the '
            'flat-top blob `5_ui.md` D2 photographed',
      );
      expect(
        (middle - 49).abs(),
        lessThanOrEqualTo(2),
        reason:
            "the sparkle must sit on the design's centre line (art y 49 = the "
            'left/right points of the `d`), not float below it',
      );

      // The horizontal extent is already correct, so the fix must not disturb
      // it: sparkle 1 spans art x 13..51 (CSS 33..71 on screen).
      expect(box.left, inInclusiveRange(19, 21));
      expect(box.right, inInclusiveRange(42, 44));
    },
  );

  // ---------------------------------------------------------------------------
  // Cleared-investigation harnesses. NOT skipped: they pin the boundary of the
  // bugs above, so a fix cannot be "remove the guard", "hard-code 4" or
  // "redraw the sparkles by hand".
  // ---------------------------------------------------------------------------

  testWidgets(
    'cleared: after a REAL stream failure "Try again" really re-subscribes '
    '(both Dart failure-delivery shapes)',
    (tester) async {
      for (final failFast in <bool>[true, false]) {
        final repo = _FailingRepository(db: db, failFast: failFast);
        await _useRepository(repo);
        await _pumpEvolution(tester);

        if (failFast) {
          // `Stream.error(...)`: delivered in a microtask.
        } else {
          repo.failSlow();
          await _settle(tester);
        }
        expect(
          find.text('Oh no! Pip got lost.'),
          findsOneWidget,
          reason: 'failFast=$failFast: a failing stream may show the card',
        );
        expect(repo.evolutionCalls, 1);

        await tester.tap(find.byKey(const Key('k07-retry')));
        await _settle(tester);

        expect(
          repo.evolutionCalls,
          2,
          reason:
              'failFast=$failFast: "Try again" is the only control on the card '
              'and must really re-subscribe',
        );
        if (failFast) {
          // The retried stream fails again, so the card is correct here — what
          // matters is that the second `watchEvolution()` call happened at all.
          expect(
            find.text('Oh no! Pip got lost.'),
            findsOneWidget,
            reason:
                'failFast=true: the stream is still broken, so the card stays',
          );
        } else {
          expect(
            find.byType(CircularProgressIndicator),
            findsOneWidget,
            reason:
                'failFast=false: the controllers are silent now, so a reload '
                'with no value yet is a spinner, not the card',
          );
        }

        await repo.closeGates();
        await disposeApp(tester);
        // The next iteration needs a fresh DI scope (GetIt holds the repo).
        db = await setUpTestScope();
      }
    },
  );

  testWidgets('control: no active child offers the picker, not a failure', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value(null)),
      );
      await GetIt.instance<AppSession>().refresh();
    });
    await _pumpEvolution(tester);

    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.byKey(const Key('k07-choose')), findsOneWidget);
    expect(find.byKey(const Key('k07-retry')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('k07-choose')));
    await _settle(tester);
    expect(currentPath(tester), '/who-is-playing');

    await disposeApp(tester);
  });

  testWidgets(
    'control: the no-child card live-updates into the celebration when a child '
    'is picked (no reload, no dead end)',
    (tester) async {
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value(null)),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      expect(find.text("Who's playing?"), findsOneWidget);

      // The picker writes `active_child_id`; K07 is a live watch, so the
      // celebration must appear without a reload or a "Try again".
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _settle(tester);

      expect(find.text("Who's playing?"), findsNothing);
      expect(find.text('Pip grew into a Hatchling!'), findsOneWidget);
      expect(find.text('Because you helped 2 times'), findsOneWidget);
      expect(find.byKey(const Key('k07-cta')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: switching the active child Maya -> Leo retitles the screen with '
    "Leo's own Pip data (no stale Maya frame)",
    (tester) async {
      await _pumpEvolution(tester);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(find.text('Because you helped 4 times'), findsOneWidget);
      final newPip = tester.getSemantics(find.byKey(const Key('k07-new-pip')));
      expect(newPip.getSemanticsData().label, "Maya's Pip, a fledgling");

      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _settle(tester);

      expect(find.text('Pip grew into a Fledgling!'), findsNothing);
      expect(find.text('Pip grew into a Hatchling!'), findsOneWidget);
      expect(find.text('Because you helped 2 times'), findsOneWidget);
      expect(find.text('60'), findsOneWidget, reason: "Leo's lifetime coins");
      expect(find.text('Meet Hatchling Pip'), findsOneWidget);
      final switched = tester.getSemantics(
        find.byKey(const Key('k07-new-pip')),
      );
      expect(
        switched.getSemanticsData().label,
        "Leo's Pip, a hatchling",
        reason: 'the image label must follow the DB row, not the screen',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    },
  );

  testWidgets('control: a rapid double tap on the CTA navigates once', (
    tester,
  ) async {
    await _pumpEvolution(tester);
    await tester.tap(find.byKey(const Key('k07-cta')));
    await tester.tap(find.byKey(const Key('k07-cta')), warnIfMissed: false);
    await _settle(tester);

    expect(currentPath(tester), '/pip');
    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });

  testWidgets('control: the lock opens the gate once and back returns', (
    tester,
  ) async {
    await _pumpEvolution(tester);
    await tester.tap(find.byKey(const Key('k07-lock')));
    await tester.tap(find.byKey(const Key('k07-lock')), warnIfMissed: false);
    await _settle(tester);
    expect(pushedPath(tester), '/parental-gate');

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pushedPath(tester), '/pip-evolution');

    await tester.tap(find.byKey(const Key('k07-cta')));
    await _settle(tester);
    expect(currentPath(tester), '/pip', reason: 'the lock round-trip is clean');

    await disposeApp(tester);
  });

  testWidgets(
    'control: a late stream emission after the app is torn down throws nothing',
    (tester) async {
      await _pumpEvolution(tester);
      // Tear the whole app down (bloc disposal cancels both subscriptions)
      // while a write is still in flight, so the stream tries to emit into a
      // closed bloc.
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipTotalCoins: Value(200)),
        );
      });
      await disposeApp(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.takeException(),
        isNull,
        reason: 'no add-after-close / emit-after-close on teardown',
      );
    },
  );

  testWidgets(
    'control: 9999 coins and a 19-character name hold at 320 px, scale 1.3, '
    'dark',
    (tester) async {
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(
            nickname: Value('Maximilian-Alexander'),
            pipTotalCoins: Value(9999),
          ),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpEvolution(tester, theme: ThemeMode.dark);
      await _resize(tester, 320);

      expect(find.text('9999'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow at 320/1.3');

      final stats = tester.getSemantics(find.byKey(const Key('k07-stats')));
      expect(
        stats.getSemanticsData().label,
        contains('9999 coins grown'),
        reason: 'the merged stat sentence carries the DB number',
      );

      await disposeApp(tester);
    },
  );
}
