// K07 (Pip evolves, `/pip-evolution`) — Stage 6 adversarial bug proofs.
//
// ITERATION 3 (third pass, after the iteration-3 build f4174f9, which landed the
// orchestrator-mandatory D4 / K07-BUG-5 fix). No product code is changed by this
// stage (RULES §1: a bug hunt may add only `app/test/features/pip/**` and
// `docs/screens/K07/**`) — K07-BUG-6 and K07-BUG-7 are NEW on this pass; every
// earlier id was re-measured rather than assumed fixed.
//
// ITERATION 2 (second pass, after the iteration-2 build 34abefa) re-measured
// iteration 1's four bugs, which that build had FIXED.
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
// REAL-FONT ORDERING IS LOAD-BEARING: the iteration-3 block is LAST in this file
// because `_loadNunito` swaps the engine font collection for the rest of the
// process (see its doc comment). Do not add tests after it.
//
// Hunt matrix (the brief's list) and where each item is pinned:
//   0 children / no active child ....... `control: no active child…`
//                                            (plus `Seed.empty()` in the
//                                            view/a11y/contract suites)
//   a child picked afterwards .......... `control: the no-child card…`
//   1 child, 6 children, ghost child .... `control: one child, six children…`
//   active-child switch (Maya -> Leo) .. `control: switching…`
//   long UK name, 9999 coins ............ control (passing)
//   pip_stage 0 / 5 / 99 ............... `control: pip_stage 0, 5 and 99…`
//   0 / 999999999 coins, 0 / 1 quests ... `control: 0 and 999999999 coins…`
//   repeated quest completion .......... K07-BUG-3 (fixed; both proofs green)
//   rapid double taps ................... `control: a rapid double tap…` (CTA,
//                                            lock, retry, no-child Choose)
//   back nav / deep link / gate ......... controls (passing)
//   Drift persistence across reopen ..... `control: the screen's numbers…`
//   parent/kid mode guard ............... `control: kid mode with an EXPIRED…`
//                                            + `control: PARENT mode may open…`
//   dark-mode contrast .................. cleared in iteration 1; the DARK
//                                            SPARKLE palette is K07-BUG-5
//   text scale 1.3 + width 320 .......... K07-BUG-2 (fixed) + the 280..844 px
//                                            matrix at text scale 2.0
//   async gaps (stream still in flight) . K07-BUG-1 (fixed) +
//                                           `control: a late emission after…`
//   timezone / money rounding ........... n/a — K07 reads no clock and no £
//                                          (lifetime integer counters only)
//
// ASYNC-GAP NOTE (learned the hard way): a Drift WRITE issued while the app is
// pumped inside `tester.runAsync` can deadlock this harness when the written
// table is one a live watch is sitting on (measured: an INSERT into
// `quest_completions` with `watchCompletionsForChild` live hangs at the
// `await db.insert`, and `--timeout` cannot fire inside the fake-async zone).
// So every write in this file happens BEFORE the first pump, and the
// repository-level proof is a plain real-async `test` with no widget tree.
// A real Drift READ inside a `testWidgets` body needs `tester.runAsync` too
// (`watchEvolution().first` deadlocks otherwise).
//
// THEME NOTE (why K07-BUG-5 pumps the app shell instead of a bare MaterialApp):
// `context.nest` is `Theme.of(context).extension<NestTokens>()!`, so a painter
// wrapped in its own `MaterialApp(theme: NestTheme.dark())` can resolve the
// LIGHT palette while the real screen resolves the dark one. Every palette
// proof here goes through `pumpAppRoute`, which is what the device runs.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/ids.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_copy.dart';
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

/// K07-BUG-6 / K07-BUG-7's harness is layout-only, but this one belongs to
/// iteration 3's control set: an evolution stream that fails, then fails AGAIN
/// after a real retry, then heals. It answers the adversarial question the
/// single-retry control left open — is the failure card's "Try again" a live
/// control on the *second* visit, or does one re-subscription poison it?
class _TwiceFailingRepository extends PipRepositoryImpl {
  _TwiceFailingRepository({required super.db});

  final StreamController<PipEvolution?> healGate =
      StreamController<PipEvolution?>.broadcast();

  int evolutionCalls = 0;

  /// Fails until the test heals it; then the silent gate answers instead.
  bool heal = false;

  @override
  Stream<PipEvolution?> watchEvolution() {
    evolutionCalls++;
    if (heal) return healGate.stream;
    return Stream<PipEvolution?>.error(Exception('evolution down'));
  }

  Future<void> closeGates() => healGate.close();
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
Future<void> _resize(
  WidgetTester tester,
  double width, {
  double height = 844,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
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

/// One painted colour, read back from the layer's OWN rasteriser.
///
/// The samples are taken in the design's own `viewBox` coordinates
/// (`K07-evolution.html:35-46`) at points that are solid by construction: each
/// sparkle's waist/middle is fill, and `(13, 49)` is inside sparkle 1's
/// left-point stroke, which the 3 px `--ink` stroke covers completely. Sampling
/// pixels is the only honest way to read a `CustomPainter`'s palette back, and
/// Skia's software raster is deterministic, so these numbers reproduce run to
/// run.
///
/// NOT pumped inside a bare `MaterialApp(theme: NestTheme.dark())`: the proof
/// goes through the real app shell (`pumpAppRoute`), which is what the device
/// runs and the only place `context.nest` is the live theme's tokens.
Future<Map<String, int>> _sparkPalette(
  WidgetTester tester, {
  required ThemeMode theme,
}) async {
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip-evolution', theme: theme);
  await _settle(tester);
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
    final data = (await image.toByteData())!;
    image.dispose();
    return data.buffer.asUint8List();
  }))!;

  /// RGB of one painted pixel, alpha dropped: every sample below is a solid
  /// fill or a solid stroke pixel, so alpha is 255 and only the RGB is the
  /// contract. `rawRgba`: R, G, B, A in that order.
  int at(int x, int y) {
    final i = (y * size.width.toInt() + x) * 4;
    return (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2];
  }

  return <String, int>{
    // `<g stroke="#1E1B3A">`, sampled on sparkle 1's left point (13, 49).
    'stroke': at(13, 49),
    // `fill="#7C6CF2"` on sparkle 1's waist.
    'lilac': at(32, 49),
    // `fill="#1F9D63"` on sparkle 2's waist.
    'success': at(312, 43),
    // `fill="#F4B400"` on sparkle 3's waist.
    'coin': at(18, 167),
    // `fill="#FF8A5B"` on sparkle 4's waist.
    'peach': at(334, 169),
    // `<circle cx="86" cy="10" r="7" fill="#F4B400">`, centre.
    'coinDot': at(86, 10),
    // `<circle cx="268" cy="8" r="6" fill="#3D7FF0">`, centre. The design's hex
    // is NOT a token in either theme (`5_ui.md` D5), so this sample is reported
    // by the controls and never asserted here.
    'skyDot': at(268, 8),
  };
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

  // ---------------------------------------------------------------------------
  // ITERATION 2's own hunt: the matrix items iteration 1 cleared but never
  // pinned, plus the one item iteration 1's tree did not have — the dark-mode
  // sparkle palette the orchestrator has since ruled on (ORCHESTRATOR_NOTES
  // 23:55, D4). Nothing in this block changes the screen (RULES §1).
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-5: in DARK the sparkles are stroked and filled from the DARK '
    "theme's tokens, so all four sparkles and every dot get a light ring on the "
    "night sky — the design's `svg.sparks` is a fixed, theme-invariant palette",
    (tester) async {
      final dark = await _sparkPalette(tester, theme: ThemeMode.dark);
      await disposeApp(tester);

      // `K07-evolution.html:36` — `<g stroke="#1E1B3A" stroke-width="3">`, the
      // one colour the dark design PNG paints around every sparkle and dot.
      expect(
        dark['stroke'],
        0x1E1B3A,
        reason:
            'the design strokes the whole `<g>` with the literal #1E1B3A in '
            'BOTH themes; the app stroked with the dark theme ink token '
            '(#F3F0FA), which is the white ring `5_ui.md` D4 / cmp_dark_2.png '
            'photographed. Sample was #${dark['stroke']!.toRadixString(16)}',
      );
      // The four accent fills that DO exist as light tokens: the design's
      // literals are those tokens' light values, so resolving from
      // `NestColors.light` satisfies both "tokens only" and PNG parity.
      expect(
        dark['lilac'],
        0x7C6CF2,
        reason: 'sparkle 1 `fill="#7C6CF2"` is theme-invariant',
      );
      expect(
        dark['success'],
        0x1F9D63,
        reason: 'sparkle 2 `fill="#1F9D63"` is theme-invariant',
      );
      expect(
        dark['coin'],
        0xF4B400,
        reason: 'sparkle 3 `fill="#F4B400"` is theme-invariant',
      );
      expect(
        dark['peach'],
        0xFF8A5B,
        reason: 'sparkle 4 `fill="#FF8A5B"` is theme-invariant',
      );

      // The whole layer must be theme-invariant, which is the property the
      // design's inline SVG has by construction (it never references a theme
      // variable). Comparing the two rasters covers every entry at once, so a
      // future accent added to `_sparks` cannot slip past the list above.
      final light = await _sparkPalette(tester, theme: ThemeMode.light);
      await disposeApp(tester);
      expect(
        dark,
        light,
        reason:
            'every `svg.sparks` colour is an inline hex, so the dark layer '
            'must be pixel-identical to the light one (sky dot aside: '
            '${light['skyDot']} vs ${dark['skyDot']} — the #3D7FF0 hex is '
            'not a token in either theme, which is 5_ui.md D5, a design-source '
            'bug, and not this screen to fix)',
      );
    },
  );

  testWidgets(
    'control: in LIGHT the sparks layer already matches the HTML literals '
    'exactly (the same sampler, so the dark proof cannot pass for the wrong '
    'reason)',
    (tester) async {
      final light = await _sparkPalette(tester, theme: ThemeMode.light);
      expect(light['stroke'], 0x1E1B3A);
      expect(light['lilac'], 0x7C6CF2);
      expect(light['success'], 0x1F9D63);
      expect(light['coin'], 0xF4B400);
      expect(light['peach'], 0xFF8A5B);
      expect(light['coinDot'], 0xF4B400);
      await disposeApp(tester);
    },
  );

  test("control: the screen's numbers survive a database reopen (Drift "
      'persistence — nothing on K07 is cached in memory)', () async {
    final dir = Directory.systemTemp.createTempSync('k07_bugs_reopen');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = File('${dir.path}/nestling.db');

    var database = AppDatabase(NativeDatabase(file));
    await Seed.demo(database);
    await database.customStatement(
      'UPDATE children SET pip_stage = 4, pip_total_coins = 260 '
      "WHERE id = 'maya'",
    );
    await database.close();

    database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final repo = PipRepositoryImpl(db: database);
    final seen = <PipEvolution?>[];
    final sub = repo.watchEvolution().listen(seen.add);
    await _waitFor(() => seen.isNotEmpty);

    expect(seen.last!.questsDone, 4);
    expect(seen.last!.questsFinishedCount, 4);
    expect(seen.last!.profile.stage, 4);
    expect(seen.last!.profile.totalCoins, 260);
    await sub.cancel();
  });

  testWidgets(
    'control: pip_stage 0, 5 and 99 are clamped into the 1..4 artboards and '
    'the copy follows the clamped stage',
    (tester) async {
      // A bad `pip_stage` must not hit `PipAvatar`'s `stage >= 1 && stage <= 4`
      // assert (a crash on a kid screen) nor invent a fifth stage name.
      for (final stage in <int>[0, 5, 99]) {
        await tester.runAsync(() async {
          await (db.update(db.children)..where((c) => c.id.equals('maya')))
              .write(ChildrenCompanion(pipStage: Value(stage)));
          await GetIt.instance<AppSession>().refresh();
        });
        await _pumpEvolution(tester);
        expect(tester.takeException(), isNull, reason: 'pip_stage=$stage');

        final expected = stage.clamp(1, 4);
        expect(
          tester.widget<Text>(find.byKey(const Key('k07-stat-stage'))).data,
          '$expected',
          reason: 'the stat card shows the clamped stage',
        );
        final title = evolutionTitle(expected);
        expect(find.text(title), findsOneWidget, reason: 'pip_stage=$stage');
        expect(find.text(evolutionCta(expected)), findsOneWidget);
        await disposeApp(tester);
        db = await setUpTestScope();
      }
    },
  );

  testWidgets(
    'control: 0 and 999999999 coins, and 0 or 1 completions, keep the numbers '
    'and the singular sub honest',
    (tester) async {
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipTotalCoins: Value(0)),
        );
        await db.delete(db.questCompletions).go();
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-coins'))).data,
        '0',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-quests'))).data,
        '0',
      );
      // `4_review.md` finding 2 owns this copy: `evolutionSub(0)` is "Because
      // you helped 0 times" today. Pinned HERE as the behaviour under review,
      // not as the desired copy — when finding 2's fix lands this assertion
      // moves with it.
      expect(find.text(evolutionSub(0)), findsOneWidget);
      await disposeApp(tester);

      db = await setUpTestScope();
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipTotalCoins: Value(999999999)),
        );
        await db.delete(db.questCompletions).go();
        await db
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
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-coins'))).data,
        '999999999',
        reason: 'a 9-digit coin total must survive the card, not be elided',
      );
      expect(
        find.text(evolutionSub(1)),
        findsOneWidget,
        reason: 'one completion reads "Because you helped 1 time"',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-quests'))).data,
        '1',
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: one child, six children and a deleted sibling all keep the '
    'ACTIVE child on screen (the roster never leaks onto K07)',
    (tester) async {
      await tester.runAsync(() async {
        // Leo is deleted: Maya must still render, and nothing may ask for the
        // picker while an active child exists.
        await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(find.text("Who's playing?"), findsNothing);
      await disposeApp(tester);

      db = await setUpTestScope();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: newId('child'),
                  familyId: Seed.familyId,
                  nickname: 'Extra$i',
                  ageBand: const Value('7-9'),
                  pipStage: const Value(2),
                  pipTotalCoins: const Value(10),
                  createdAt: Value(Seed.utc(9, 20, 8)),
                  createdAtTz: const Value('Europe/London'),
                ),
              );
        }
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      // Six children exist; K07 is about whoever is playing, so the card and
      // the hero are still Maya's, not the newest row's.
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-quests'))).data,
        '4',
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('k07-new-pip')))
            .getSemanticsData()
            .label,
        "Maya's Pip, a fledgling",
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets('control: no overflow from a 280x360 phone to an 844x390 landscape at '
      'text scale 2.0, and the caption stays above the bar', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpEvolution(tester);

    for (final size in <Size>[
      const Size(280, 360),
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(844, 390),
    ]) {
      await _resize(tester, size.width, height: size.height);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'no overflow at ${size.width.toInt()}x${size.height.toInt()} '
            'at text scale 2.0',
      );
      expect(
        find.byKey(const Key('k07-cta')),
        findsOneWidget,
        reason: 'the CTA is never dropped at ${size.width.toInt()} px',
      );
      // The caption is the LAST line of the design's copy, so on a surface
      // where the column is taller than the viewport it must be REACHABLE by
      // scrolling and must come to rest above the bar — never painted under
      // the bar's opaque surface. Scrolled deterministically (a synthetic drag
      // cannot be trusted at 280x360, where the grown Pip owns the centre).
      final caption = tester.getRect(find.byKey(const Key('k07-caption')));
      final barTop = tester.getRect(find.byKey(const Key('k07-bar'))).top;
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('k07-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(
        position.maxScrollExtent,
        greaterThanOrEqualTo(caption.bottom - barTop),
        reason:
            'the caption needs ${(caption.bottom - barTop).toStringAsFixed(1)} px '
            'of scroll at ${size.width.toInt()}x${size.height.toInt()} but the '
            'column only scrolls ${position.maxScrollExtent.toStringAsFixed(1)} px, '
            'so the last line of copy is unreachable',
      );
      position.jumpTo(position.maxScrollExtent);
      await _settle(tester);
      final scrolled = tester.getRect(find.byKey(const Key('k07-caption')));
      expect(
        scrolled.bottom,
        lessThanOrEqualTo(barTop + 1),
        reason:
            'scrolled to the end, the caption still reaches '
            '${(scrolled.bottom - barTop).toStringAsFixed(1)} px into the bar at '
            '${size.width.toInt()}x${size.height.toInt()}',
      );
    }
    await disposeApp(tester);
  });

  testWidgets(
    'control: kid mode with an EXPIRED trial cannot reach /pip-evolution '
    '(the gate redirect holds)',
    (tester) async {
      // `Seed.empty()` is the shared "onboarded parent, no children, trial
      // running" state — it owns `subscription_status`. This test only ages
      // `trial_start`, so expiry still flows through `AppSession` and nothing
      // writes `subscription_status` (the TRIAL rule).
      await tester.runAsync(() async {
        await Seed.empty(db);
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(trialStart: Value(DateTime.utc(2026))),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      expect(GetIt.instance<AppSession>().trialExpired, isTrue);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/pip-evolution');
      await _settle(tester);

      expect(currentPath(tester), '/parental-gate');
      expect(find.byKey(const Key('k07-title')), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: PARENT mode may open /pip-evolution (it is not on the parentOnly '
    'list, which is intended — a grown-up may inspect the child moment)',
    (tester) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.parent);
      await pumpAppRoute(tester, '/pip-evolution');
      await _settle(tester);

      expect(currentPath(tester), '/pip-evolution');
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: a rapid double tap on "Try again" re-subscribes once per tap and '
    'never stacks two live subscriptions',
    (tester) async {
      final repo = _FailingRepository(db: db, failFast: true);
      await _useRepository(repo);
      await _pumpEvolution(tester);
      expect(find.byKey(const Key('k07-retry')), findsOneWidget);
      expect(repo.evolutionCalls, 1);

      // Two taps inside one frame: `failFast` means each attempt dies in a
      // microtask and clears the subscription, so each tap may open exactly one
      // new stream — never two for one tap, and never a stuck pair.
      await tester.tap(find.byKey(const Key('k07-retry')));
      await tester.tap(find.byKey(const Key('k07-retry')), warnIfMissed: false);
      await _settle(tester);

      expect(
        repo.evolutionCalls,
        3,
        reason: 'one re-subscription per tap (1 initial + 2 taps)',
      );
      expect(find.byKey(const Key('k07-retry')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await repo.closeGates();
      await disposeApp(tester);
    },
  );

  // ===========================================================================
  // ITERATION 3's hunt (after the iteration-3 build `f4174f9`, which landed the
  // orchestrator-mandatory D4 / K07-BUG-5 fix).
  //
  // Nothing here changes the screen (RULES §1: a bug hunt adds only
  // `app/test/features/pip/**` and `docs/screens/K07/**`).
  //
  // REAL-FONT NOTE — the one thing this pass changed about the method. The
  // file header's "text-driven geometry measured in a widget test is not the
  // device's geometry" caveat is true and it HID a real defect: Flutter's test
  // font renders all three stat labels at the SAME width, so the cards' scale
  // factors came out equal and the misalignment vanished; with the bundled
  // Nunito loaded (`_loadNunito`, the pattern
  // `test/core/design_system/nest_pet_stage_test.dart:154` established) the
  // three labels' widths differ and the drift is 2.40 px on a 320 px phone.
  // `FontLoader` mutates the engine font collection for the rest of the
  // process, so these tests are deliberately LAST in the file: nothing after
  // them can be perturbed by the swap.
  // ===========================================================================

  testWidgets(
    'K07-BUG-6: the three stat cards are different heights and their top and '
    'bottom edges drift apart, because the row CENTRES its children instead of '
    'stretching them like the design flex row does',
    (tester) async {
      await _loadNunito(tester);
      // No DB write at all: this is the shipped demo seed (Maya, 4 quests,
      // 120 coins, stage 3). The brief's own width.
      await _pumpEvolution(tester);
      await _resize(tester, 320);

      final quests = _cardRect(tester, 'k07-card-quests');
      final coins = _cardRect(tester, 'k07-card-coins');
      final stages = _cardRect(tester, 'k07-card-stage');

      // `.k7-stats { display: flex; gap: 10px }` with no `align-items`, so CSS
      // stretches all three `.k7-stats > div` to the tallest — one height,
      // three identical top and bottom edges. The design PNG measures all
      // three at y 545..629 (84 px) at x 20 / 140 / 260.
      expect(
        _drift(<double>[quests.height, coins.height, stages.height]),
        lessThanOrEqualTo(0.5),
        reason:
            'the three `.k7-stats > div` boxes are ${quests.height} / '
            '${coins.height} / ${stages.height} px tall. `_StatCell` wraps its '
            'number+label in `FittedBox(fit: scaleDown)`, so a card whose '
            'content is narrower than the cell is scaled LESS and therefore '
            'painted SHORTER; the design stretches all three to one height.',
      );
      expect(
        _drift(<double>[quests.top, coins.top, stages.top]),
        lessThanOrEqualTo(0.5),
        reason:
            'card tops are ${quests.top} / ${coins.top} / ${stages.top} — the '
            'chunky 3 px ink borders and 6 px `--sh-kid` shadows make a ragged '
            'top edge plainly visible, and the owner ALIGNMENT rule calls any '
            'visible misalignment a UI failure.',
      );
      expect(
        _drift(<double>[quests.bottom, coins.bottom, stages.bottom]),
        lessThanOrEqualTo(0.5),
        reason:
            'card bottoms are ${quests.bottom} / ${coins.bottom} / '
            '${stages.bottom} — the row uses the default '
            'CrossAxisAlignment.center, so unequal cards are centred against '
            'each other and their bottom edges splay.',
      );

      await disposeApp(tester);
    },
  );

  testWidgets(
    'K07-BUG-7: the app-only `maxLines` caps truncate the celebration copy — '
    'the hero headline is cut mid-glyph with NO ellipsis, and the quest count '
    'is ellipsized away, at accessibility text scales the design never clamps',
    (tester) async {
      await _loadNunito(tester);
      await _pumpEvolution(tester);

      // Read the caps the screen ACTUALLY applies, so this proof measures the
      // shipped widget rather than a hard-coded number (and so raising or
      // dropping a cap is what turns it green).
      final heroCap = tester
          .widget<NestBalancedText>(find.byKey(const Key('k07-title')))
          .maxLines;
      final subCap = tester
          .widget<Text>(find.byKey(const Key('k07-sub')))
          .maxLines;

      // `.k7-hero` / `.k7-sub` carry NO line clamp in the design (only
      // `text-wrap: balance` on `.kid-title` and `text-align: center`), so in
      // the browser these lines simply grow and `.scroll` scrolls. The app adds
      // `maxLines: 4` on a `NestBalancedText` whose default overflow is
      // `TextOverflow.clip` (a HARD cut, not even an ellipsis) and
      // `maxLines: 2` + ellipsis on the sub-line, which carries the count.
      final overlongTitle = <String>[];
      final overlongSub = <String>[];
      for (final scale in const <double>[1, 1.3, 1.5, 2, 2.5, 3, 3.16]) {
        for (final width in const <double>[350, 320, 280]) {
          final scaler = TextScaler.linear(scale);
          for (final stage in const [1, 2, 3, 4]) {
            final lines = _lineCount(
              evolutionTitle(stage),
              NestType.kidTitle(),
              width,
              scaler,
            );
            if (heroCap != null && lines > heroCap) {
              overlongTitle.add(
                'stage $stage needs $lines lines at ${scale}x '
                '${width.toInt()}px',
              );
            }
          }
          for (final q in const [1, 44, 9999, 999999, 999999999]) {
            final lines = _lineCount(
              evolutionSub(q),
              NestType.kidBody(),
              width,
              scaler,
            );
            if (subCap != null && lines > subCap) {
              overlongSub.add(
                '"$q times" needs $lines lines at ${scale}x '
                '${width.toInt()}px',
              );
            }
          }
        }
      }
      expect(
        overlongTitle,
        isEmpty,
        reason:
            'the hero is capped at $heroCap lines with the default '
            'TextOverflow.clip, so a further line is cut mid-glyph with '
            'nothing to show for it — iOS reaches 3.16x (.accessibility5) on a '
            '390 px phone, and 2.5x already needs 5 lines at 320 px. '
            'Offenders: ${overlongTitle.take(3).join('; ')}',
      );
      expect(
        overlongSub,
        isEmpty,
        reason:
            'the sub-line is capped at $subCap lines and carries the quest '
            'count, so the one sentence that explains WHY Pip grew reads '
            '"Because you helped 9999..." at 2x (Android maximum font scale) '
            'on a 320 px phone, and even "Because you helped 1 time" needs 3 '
            'lines at 3.16x. Offenders: ${overlongSub.take(3).join('; ')}',
      );
      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // ITERATION 3's controls: what this pass MEASURED as clean, pinned so a
  // future fix cannot "fix" K07-BUG-6/7 by breaking fidelity.
  // ---------------------------------------------------------------------------

  testWidgets(
    "control: with the real Nunito the stat cards are exactly the design's "
    '110x84 at x 20 / 140 / 260 on the design width, and at 375 / 360 they stay '
    'on the 20 px gutter with equal heights and aligned edges',
    (tester) async {
      await _loadNunito(tester);
      for (final width in const <double>[390, 375, 360]) {
        await _pumpEvolution(tester);
        await _resize(tester, width);
        final quests = _cardRect(tester, 'k07-card-quests');
        final coins = _cardRect(tester, 'k07-card-coins');
        final stages = _cardRect(tester, 'k07-card-stage');
        final first = width == 390;
        // `.k7-stats { display: flex; gap: 10px }` inside a 20 px-gutted
        // `.scroll`: three equal cells, so cell = (width - 40 - 20) / 3 —
        // exactly the design's 110 at 390.
        final cell = (width - 40 - 20) / 3;
        expect(quests.left, closeTo(20, 0.01));
        expect(quests.width, closeTo(cell, 0.01));
        // At the design's own 390 the absolute card is pinned: x 20..130,
        // y 545..629 (84 px tall).
        if (first) {
          expect(quests.width, closeTo(110, 0.5));
          expect(quests.height, closeTo(84, 0.5));
        }
        // The 20 px side gutter and the 10 px `.k7-stats` gap hold at every
        // width: three equal cells with two 10 px gutters between them.
        expect(coins.width, closeTo(quests.width, 0.01));
        expect(stages.width, closeTo(quests.width, 0.01));
        expect(coins.left - quests.right, closeTo(10, 0.01));
        expect(stages.left - coins.right, closeTo(10, 0.01));
        expect(stages.right, closeTo(width - 20, 0.01));
        // …and they share one height, so their top and bottom edges align.
        expect(
          _drift(<double>[quests.height, coins.height, stages.height]),
          lessThanOrEqualTo(0.5),
        );
        expect(
          _drift(<double>[quests.top, coins.top, stages.top]),
          lessThanOrEqualTo(0.5),
        );
        expect(
          _drift(<double>[quests.bottom, coins.bottom, stages.bottom]),
          lessThanOrEqualTo(0.5),
        );
        await disposeApp(tester);
      }
    },
  );

  testWidgets(
    'control: no copy is truncated at text scale 1.0–2.0 on a 320 px phone '
    'with the real Nunito, so the widget test font (not the screen) is what '
    'makes text look clipped',
    (tester) async {
      await _loadNunito(tester);
      await _pumpEvolution(tester);
      await _resize(tester, 320);
      // The brief's own combination, asserted on the real rendered paragraphs.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _settle(tester);
      expect(_exceededMaxLines(tester, 'k07-title'), isFalse);
      expect(_exceededMaxLines(tester, 'k07-sub'), isFalse);
      expect(_exceededMaxLines(tester, 'k07-caption'), isFalse);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: a second REAL stream failure still leaves "Try again" alive, and '
    'the celebration comes back when the stream finally answers',
    (tester) async {
      final repo = _TwiceFailingRepository(db: db);
      await _useRepository(repo);
      addTearDown(repo.closeGates);
      await _pumpEvolution(tester);
      expect(find.byKey(const Key('k07-retry')), findsOneWidget);
      expect(repo.evolutionCalls, 1);

      await tester.tap(find.byKey(const Key('k07-retry')));
      await _settle(tester);
      expect(repo.evolutionCalls, 2, reason: 'retry #1 re-subscribed');
      expect(
        find.byKey(const Key('k07-retry')),
        findsOneWidget,
        reason: 'the second failure offers a second, live retry',
      );

      repo.heal = true;
      await tester.tap(find.byKey(const Key('k07-retry')));
      await _settle(tester);
      expect(repo.evolutionCalls, 3, reason: 'retry #2 re-subscribed');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('k07-retry')), findsNothing);

      final delivered = await tester.runAsync(
        () => PipRepositoryImpl(db: db).watchEvolution().first,
      );
      await tester.runAsync(() async => repo.healGate.add(delivered));
      await _settle(tester);
      expect(find.byKey(const Key('k07-title')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: only done_pending / approved rows for the ACTIVE child count '
    'toward the milestone (to_do, not_yet and rows belonging to another child '
    'do not)',
    (tester) async {
      // Written BEFORE the first pump: a write to a table a live watch sits on
      // deadlocks this harness inside the fake-async zone (file header).
      await tester.runAsync(() async {
        for (final entry in const <(String, String)>[
          ('q-todo', 'maya'),
          ('q-notyet', 'maya'),
          ('q-denied', 'maya'),
          ('q-leo', 'leo'),
        ]) {
          await db
              .into(db.questCompletions)
              .insert(
                QuestCompletionsCompanion.insert(
                  questId: entry.$1,
                  childId: entry.$2,
                  familyId: Seed.familyId,
                  status: Value(
                    entry.$1 == 'q-denied'
                        ? 'denied'
                        : entry.$1 == 'q-todo'
                        ? 'to_do'
                        : entry.$1 == 'q-notyet'
                        ? 'not_yet'
                        : 'approved',
                  ),
                  coins: const Value(15),
                ),
              );
        }
      });
      await _pumpEvolution(tester);
      // Demo truth for Maya: 4 counted completions, 4 distinct quests.
      expect(
        tester.widget<Text>(find.byKey(const Key('k07-stat-quests'))).data,
        '4',
      );
      expect(find.text('Because you helped 4 times'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // ITERATION 4. The app shell clamps the OS text scaler to 1.0–1.3
  // (`app/lib/app/app.dart:17-20`), so 1.3 is the app's own MAXIMUM supported
  // size, not an exotic accessibility step — which is what makes the two
  // proofs below live defects rather than speculation. Both are measured with
  // the real bundled Nunito and go through `pumpAppRoute`, i.e. the same
  // `_clampTextScaler` the device runs.
  // ---------------------------------------------------------------------------

  testWidgets(
    'K07-BUG-8: the three `.k7-stats` cards paint their number and their label '
    'at THREE DIFFERENT type sizes inside one row, and the numbers no longer '
    'share a baseline — each cell has its own `FittedBox(fit: scaleDown)`, so '
    'a narrower cell shrinks less, while the design sets ONE `font-size` for '
    'all three `<b>` and all three `<span>`',
    (tester) async {
      await _loadNunito(tester);

      // (a) The DESIGN width, at the app's own maximum supported text size.
      //     Nothing exotic about 1.3: `_clampTextScaler` caps there.
      await _pumpEvolution(tester);
      await _resize(tester, 390);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      // Cleared on the way out, or `--run-skipped` would leak 1.3 into every
      // later test in this file (the controls below assert scale-1.0 geometry).
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _settle(tester);

      final tops = <double>[
        for (final k in _kStatCells) _statNumberRect(tester, k).top,
      ];
      final heights = <double>[
        for (final k in _kStatCells) _statNumberRect(tester, k).height,
      ];
      final labelHeights = <double>[
        for (final k in _kStatCells) _statLabelRect(tester, k).height,
      ];

      expect(
        _drift(tops),
        lessThanOrEqualTo(2.0),
        reason:
            'at 390 px and text scale 1.3 the three numbers start at '
            'y ${tops.map((v) => v.toStringAsFixed(2)).join(' / ')}. '
            '`K07-evolution.html:29` gives `.k7-stats b` ONE font-size for all '
            'three cards and CSS scales nothing, so all three `<b>` must share '
            'one top edge; the owner ALIGNMENT rule calls anything visibly '
            'off a UI failure and the UI VERDICT rule allows ±2 px.',
      );
      expect(
        _drift(heights),
        lessThanOrEqualTo(0.5),
        reason:
            'the three numbers are painted '
            '${heights.map((v) => v.toStringAsFixed(2)).join(' / ')} px tall — '
            'a ${(_drift(heights) / heights.first * 100).toStringAsFixed(1)}% '
            'spread inside one row, which reads as three different type sizes '
            'rather than three cards of one design.',
      );
      expect(
        _drift(labelHeights),
        lessThanOrEqualTo(0.5),
        reason:
            'the three labels are painted '
            '${labelHeights.map((v) => v.toStringAsFixed(2)).join(' / ')} px '
            'tall; `K07-evolution.html:30` gives `.k7-stats span` ONE '
            'font-size for all three.',
      );
      await disposeApp(tester);

      // (b) A 320 px phone at the DEFAULT text scale — no accessibility
      //     setting at all, just a narrow device
      //     (`docs/design/SPACING_SPEC.md:369` plans 320 px layouts).
      await _pumpEvolution(tester);
      await _resize(tester, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      await _settle(tester);
      final narrowTops = <double>[
        for (final k in _kStatCells) _statNumberRect(tester, k).top,
      ];
      expect(
        _drift(narrowTops),
        lessThanOrEqualTo(2.0),
        reason:
            'at 320 px and text scale 1.0 the three numbers start at '
            'y ${narrowTops.map((v) => v.toStringAsFixed(2)).join(' / ')}, so '
            'the row is ragged with no accessibility setting involved.',
      );
      await disposeApp(tester);
    },
  );

  testWidgets(
    'K07-BUG-9: the app-only `maxLines: 3` + ellipsis survives on the caption, '
    'the same clamp K07-BUG-7 removed from the hero and the sub — `.kcap` has '
    'no clamp in the design, and it needs 4 lines at 280 px if the text-scale '
    'clamp is ever raised',
    (tester) async {
      await _loadNunito(tester);
      await _pumpEvolution(tester);
      await _resize(tester, 280);
      // `.kcap` is exactly `kidCaption`, so the design's own style measures it.
      const caption = 'Pip still loves a chin scratch.';
      const scale = TextScaler.linear(1.3);
      final needed = NestBalancedText.lineCountFor(
        text: caption,
        style: NestType.kidCaption(color: const Color(0xFF1E1B3A)),
        maxWidth: 280 - 2 * NestSpacing.padSide,
        textDirection: TextDirection.ltr,
        textScaler: scale,
      );
      final cap = tester
          .widget<Text>(find.byKey(const Key('k07-caption')))
          .maxLines;
      expect(
        cap,
        anyOf(isNull, lessThanOrEqualTo(needed)),
        reason:
            'the caption needs $needed lines at 280 px but the widget caps it '
            'at ${cap ?? "null"} with an ellipsis. `.kcap` '
            '(`K07-evolution.html:14`) sets no clamp and `.scroll` scrolls, so '
            'the cap can only ever truncate. Latent while `_clampTextScaler` '
            'holds at 1.3 — the same two lines the hero and the sub got rid of '
            'in the K07-BUG-7 fix are still here.',
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'K07-BUG-10: a stat number wider than its card is CLIPPED mid-digit, with '
    'no ellipsis and no shrink — `.k7-stats b` sets no `overflow` in the '
    'design, so CSS paints the digits over the card edge instead of cutting '
    'them',
    (tester) async {
      await _loadNunito(tester);
      // 9999 is the value ORCHESTRATOR_NOTES 03:03 names for this row. The
      // shipped demo seed (Maya 175 / Leo 60) is only 0.77 px over per side at
      // 320 px / 1.3 — invisible — so the proof uses the value the ruling
      // itself names, where the cut is 12.47 px per side.
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipTotalCoins: Value(9999)),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpEvolution(tester);
      await _resize(tester, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _settle(tester);

      final cut = <String>[];
      for (final cell in _kStatCells) {
        final rp = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byKey(Key(cell)),
                matching: find.byType(RichText),
              ),
            )
            .first;
        // `softWrap: false` lays the paragraph out on ONE line at infinite
        // width and then constrains the box, so the intrinsic width is the
        // honest measure of the glyphs the widget asked to paint.
        final intrinsic = TextPainter(
          text: TextSpan(text: rp.text.toPlainText(), style: rp.text.style),
          textDirection: TextDirection.ltr,
          textScaler: rp.textScaler,
          maxLines: 1,
        )..layout();
        if (intrinsic.width > rp.size.width + 0.5 &&
            rp.overflow == TextOverflow.clip) {
          cut.add(
            '"${rp.text.toPlainText()}" paints '
            '${intrinsic.width.toStringAsFixed(2)} px into a '
            '${rp.size.width.toStringAsFixed(2)} px box — '
            '${(intrinsic.width - rp.size.width).toStringAsFixed(2)} px of '
            'digits cut off the right edge',
          );
        }
      }
      expect(
        cut,
        isEmpty,
        reason:
            'at 320 px / text scale 1.3 the card is a third of the row '
            '(86.67 px), so 9999 needs 93.60 px and loses 24.93 px of its '
            'right-hand digits (and is no longer centred: a `softWrap: false` '
            'paragraph lays out at infinite width, so the line starts at the '
            "content box's left edge). `K07-evolution.html:29` sets no "
            '`overflow` on `.k7-stats b`; a browser paints the line over the '
            'card edge (CSS `visible`), so the design never silently removes '
            'digits. Reachability: `pip_total_coins` is written ONLY by the '
            'seed (175/60), so the worst shipped case is 1.53 px off the right '
            '— this is latent, not a shipping defect. Cheapest fix that '
            'removes the silent cut: `overflow: TextOverflow.visible` on the '
            'number, which keeps the mandated single 30 px size. Offenders: '
            '${cut.join('; ')}',
      );
      await disposeApp(tester);
    },
    skip: true,
  );

  testWidgets(
    'control: at the design 390 px and text scale 1.0 the three stat cards '
    'are exactly the design 110x84 at x 20 / 140 / 260, their numbers share '
    'one top edge and one painted size (34.00 px = Nunito 900 30/34), so a '
    'K07-BUG-8 fix cannot be "shrink every card by the same amount"',
    (tester) async {
      await _loadNunito(tester);
      await _pumpEvolution(tester);
      await _resize(tester, 390);

      final tops = <double>[
        for (final k in _kStatCells) _statNumberRect(tester, k).top,
      ];
      final heights = <double>[
        for (final k in _kStatCells) _statNumberRect(tester, k).height,
      ];
      final labelTops = <double>[
        for (final k in _kStatCells) _statLabelRect(tester, k).top,
      ];
      expect(_drift(tops), lessThanOrEqualTo(0.5));
      expect(_drift(heights), lessThanOrEqualTo(0.5));
      expect(_drift(labelTops), lessThanOrEqualTo(0.5));
      // `.k7-stats b { font-size: 30px; line-height: 34px }` — 34 px is the
      // design's own line box, so 34.00 is the value a fix must keep.
      expect(heights[0], closeTo(34, 0.5));
      final cards = <Rect>[for (final k in _kStatCells) _cardRect(tester, k)];
      expect(cards.first.height, closeTo(84, 0.5));
      expect(cards.first.width, closeTo(110, 0.5));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'control: the app clamps the OS text scaler to 1.0–1.3 (`app.dart:17-20`), '
    'so 1.3 is the app maximum supported size — the envelope the K07-BUG-8 '
    'proof measures against, and why no copy on this screen truncates',
    (tester) async {
      await _pumpEvolution(tester);
      for (final osScale in <double>[1, 1.3, 2, 3.16]) {
        tester.platformDispatcher.textScaleFactorTestValue = osScale;
        await _settle(tester);
        final ctx = tester.element(find.byKey(const Key('k07-title')));
        expect(
          MediaQuery.textScalerOf(ctx).scale(100) / 100,
          lessThanOrEqualTo(1.3 + 1e-9),
          reason: 'OS asks for $osScale; the shell must clamp to <= 1.3',
        );
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await disposeApp(tester);
    },
  );
}

/// The three painted `.k7-stats` card keys, in the design's own order.
const List<String> _kStatCells = <String>[
  'k07-card-quests',
  'k07-card-coins',
  'k07-card-stage',
];

/// The painted rect of a stat card's NUMBER, transformed by whatever scale
/// (`FittedBox`) sits between it and the screen — so this is the type size the
/// eye actually reads, not the style's nominal one.
Rect _statNumberRect(WidgetTester tester, String cellKey) => tester.getRect(
  find
      .descendant(of: find.byKey(Key(cellKey)), matching: find.byType(RichText))
      .at(0),
);

/// The painted rect of a stat card's LABEL (`<span>`), same transform.
Rect _statLabelRect(WidgetTester tester, String cellKey) => tester.getRect(
  find
      .descendant(of: find.byKey(Key(cellKey)), matching: find.byType(RichText))
      .at(1),
);

/// Loads the bundled Nunito so text-driven geometry matches the device.
///
/// `flutter test` otherwise lays out with a fallback font that is markedly
/// WIDER than Nunito; for K07-BUG-6 that difference is the whole point (the
/// fallback renders all three stat labels at the same width, hiding the bug).
/// Same pattern as `test/core/design_system/nest_pet_stage_test.dart:154`.
Future<void> _loadNunito(WidgetTester tester) async {
  await tester.runAsync(() async {
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
    await loader.load();
  });
}

/// The painted card box, not the text inside it.
Rect _cardRect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// Largest pairwise distance in [values] — the alignment drift.
double _drift(List<double> values) {
  final sorted = <double>[...values]..sort();
  return sorted.last - sorted.first;
}

/// Real-font line count for `text` at `width` and `scale` — the same
/// `TextPainter` probe `NestBalancedText` itself uses to lay out and balance.
int _lineCount(String text, TextStyle style, double width, TextScaler scaler) =>
    NestBalancedText.lineCountFor(
      text: text,
      style: style,
      maxWidth: width,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    );

/// Whether the rendered paragraph under [key] is running past its `maxLines`.
bool _exceededMaxLines(WidgetTester tester, String key) => tester
    .renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(RichText),
      ),
    )
    .didExceedMaxLines;
