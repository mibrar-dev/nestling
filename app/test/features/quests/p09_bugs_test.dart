// P09 · New / edit quest — Stage 6 adversarial bug tests (iterations 1–2).
//
// Iteration-1 proofs: the five bugs below failed on the iteration-1 tree
// (`881880a`) and are now UNSKIPPED — iteration 2 fixed them in
// `lib/features/quests/presentation/views/quest_editor_view.dart` (+ the
// repository-side coin range and coin value the logic builder added), so they
// run on every `flutter test`.
//
// Iteration-2 proofs (BUG-P09-6..8) are UNSKIPPED as of iteration 3 — the view
// halves landed in `quest_editor_view.dart`, so all eight proofs now run on
// every `flutter test`. Run with `--run-skipped` only for a parked proof.
// The unskipped group at the bottom ("attacks that hold") documents the
// adversarial probes that pass, so a regression is caught here.
//
//   BUG-P09-1  major  the payout helper hard-codes 1p/coin and ignores the
//                     family's `coinValuePencePerCoin` (wrong money figure)
//                     → the view streams `watchCoinValuePencePerCoin()`
//   BUG-P09-2  major  double-tap Save creates the quest twice (no in-flight
//                     guard; the pill stays enabled while saving)
//                     → local `_saving` guard + the pill disables itself
//   BUG-P09-3  minor  a quest icon outside the six tiles (`plate`, `shirt`,
//                     `sofa`, `bag`, `leaf`) shows no selected tile
//                     → `_questIcons.aliases` maps every seeded key to a tile
//   BUG-P09-4  minor  out-of-range stored coins cannot be restored once the
//                     stepper touches them (9999 → 9998; `+` is disabled)
//                     → the stepper bounds grow to include the stored value
//   BUG-P09-5  minor  a quest assigned to a removed child shows no selected
//                     pill and Save keeps the orphaned id
//                     → an assignee the roster no longer lists falls back to
//                       "Anyone", so Save clears the dangling id
//   BUG-P09-6  minor  an out-of-range reward is shown at face value (9999 /
//                     `= 9999p`, or 0 / `= 0p`) but silently clamped on save
//                     (`_save` wrote 100 / 1)
//                     → the value is still shown as stored, but Save is
//                       BLOCKED with a live-region `Coins must be 1–100`
//                       caption, so nothing is written until it is in range
//   BUG-P09-7  minor  tapping the alias-highlighted tile (Dishes for `plate`,
//                     Bins for `bag`/`shirt`/`bins`) is visually a no-op but
//                     rewrites the stored icon key
//                     → an already-selected tile's tap is inert
//   BUG-P09-8  major  a nickname starting with an astral-plane character
//                     (emoji) made `_initial` emit a lone UTF-16 surrogate,
//                     so the editor threw "string is not well-formed UTF-16"
//                     while painting the avatar
//                     → `_initial` takes the first grapheme (`characters`)
//
// Iteration-3 proofs (BUG-P09-9..12), `skip: true` until their fix lands.
// BUG-P09-9 and BUG-P09-12 are independently tracked by 4_review.md §2/§3 and
// ORCHESTRATOR_NOTES 20:09; the proofs here pin the exact rects/glyphs so the
// loop can unskip them with the fix.
//
//   BUG-P09-9  major  batch 5's `NestToggle` (track is now the layout box)
//                     left P09's two compensations stale: the approval card
//                     renders 68 vs design 72 (due card 680 vs 684) and the
//                     track paints 4 px right / 2 px up
//   BUG-P09-10 minor  the shared 59x44 hit slop is clipped by the 40-high
//                     approval Row: the toggle's effective tap target is
//                     ~51x40, so taps 5 px above/below or 2 px right of the
//                     track miss (the design's `::before` reaches 59x44)
//   BUG-P09-11 minor  an out-of-range reward has no practical repair: a
//                     9999-coin row needs 9899 `-` taps before Save unblocks
//   BUG-P09-12 major  four of the six icon tiles still draw the legacy
//                     glyphs; the mandatory 20:09 note (batch-5 report) says
//                     switch to questBed / questDishes / questHoover /
//                     questBins (Book and Paw are unchanged)

import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';
import 'package:nestling/features/today/today_routes.dart';

import '../../test_scope.dart';

/// Resizes the surface (and optionally scales text), then settles a frame.
Future<void> _resize(
  WidgetTester tester,
  double width, [
  double scale = 1,
]) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Loads the bundled Inter/Nunito faces so geometry proofs measure the real
/// text metrics (same technique as `quest_editor_view_geometry_test.dart`).
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

/// The `QuestsRepository` singleton for the current test scope.
QuestsRepository get _repo => GetIt.instance<QuestsRepository>();

/// The header Save pill.
QuestSavePill _savePill(WidgetTester tester) =>
    tester.widget<QuestSavePill>(find.byType(QuestSavePill));

/// The semantics node that announces [label] as a button.
SemanticsNode _button(WidgetTester tester, String label) => find.semantics
    .byPredicate(
      (n) => n.label == label && n.getSemanticsData().flagsCollection.isButton,
    )
    .evaluate()
    .single;

/// One of the six icon tiles, by its design key.
QuestIconTile _iconTile(WidgetTester tester, String key) => tester
    .widget<QuestIconTile>(find.byKey(ValueKey<String>('quest-icon-$key')));

void main() {
  setUpAll(_loadBundledFonts);
  setUp(setUpTestScope);

  // -- BUG-P09-1 -----------------------------------------------------------
  group('BUG-P09-1 — the payout helper ignores the family coin value', () {
    testWidgets('a 2p-per-coin family still reads "= 15p at payout"', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
          .write(const FamiliesCompanion(coinValuePencePerCoin: Value(2)));
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // 15 coins at the family's 2p/coin rate is 30p. The view hard-codes
      // `_pencePerCoin = 1` (plan §1-5: "Helper derives from
      // families.coinValuePencePerCoin") instead of reading the database,
      // so it prints the wrong money figure. P06 pins the opposite
      // behaviour for the same column ("the coin value string follows the
      // database, not the design").
      expect(find.text('= 30p at payout'), findsOneWidget);
      expect(find.text('= 15p at payout'), findsNothing);
      await disposeApp(tester);
    });
  });

  // -- BUG-P09-2 -----------------------------------------------------------
  group('BUG-P09-2 — double-tap Save creates the quest twice', () {
    testWidgets('two Save taps before the router frame make two quests', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Double tap quest');
      await tester.pump();

      await tester.tap(find.text('Save'));
      // The local Drift save is fast; let the first insert land, then tap
      // again before the router frame replaces the editor — a human
      // double-tap. `_save` never checks `editorStatus` and the pill stays
      // enabled while saving, so both taps dispatch a create.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final quests = await tester.runAsync(() => _repo.getItems());
      expect(
        quests!.where((q) => q.title == 'Double tap quest').length,
        1,
        reason: 'a double-tap on Save must not create the quest twice',
      );
      await disposeApp(tester);
    });
  });

  // -- BUG-P09-3 -----------------------------------------------------------
  group('BUG-P09-3 — a quest icon outside the six tiles has no selection', () {
    testWidgets('editing q-table (icon "plate") selects no tile', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-table');

      // The seed stores icons the six-tile picker has no tile for (`plate`,
      // `shirt`, `sofa`, `bag`, `leaf`). The row renders with nothing
      // selected, so the parent cannot see the quest's current icon; only
      // `bins` is aliased to a tile (`bin`). The icon is preserved on save,
      // so this is a visible-state/a11y defect, not data loss.
      final selected = tester
          .widgetList<QuestIconTile>(find.byType(QuestIconTile))
          .where((tile) => tile.selected)
          .length;
      expect(selected, 1);
      await disposeApp(tester);
    });
  });

  // -- BUG-P09-4 -----------------------------------------------------------
  group('BUG-P09-4 — out-of-range stored coins cannot be restored', () {
    testWidgets('a 9999-coin quest drops to 9998 with no way back', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-9999',
              familyId: Seed.familyId,
              title: 'Mega quest',
              coins: const Value(9999),
              repeatRule: const Value('weekly'),
              days: const Value('6'),
              assigneeChildId: const Value('maya'),
            ),
          );
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-9999');
      expect(find.text('9999'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('decrease')));
      await tester.pump();
      expect(find.text('9998'), findsOneWidget);

      // The stepper clamps only its buttons: 9998 is not < 100, so `+` is
      // dead and the stored 9999 can never be restored. The editor has no
      // representation for a coin value outside its 1..100 design range —
      // it neither clamps stored data nor offers a way back.
      final stepper = tester.widget<NestStepper>(find.byType(NestStepper));
      expect(stepper.onIncrease, isNotNull);
      await disposeApp(tester);
    });
  });

  // -- BUG-P09-5 -----------------------------------------------------------
  group('BUG-P09-5 — a removed child leaves an orphaned assignee', () {
    testWidgets('q-bed assigned to deleted Leo shows no selected pill', (
      tester,
    ) async {
      await setUpTestScope();
      await GetIt.instance<FamilyRepository>().removeChild('leo');
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-bed');

      // The quest still points at the deleted `leo` row. No pill matches,
      // so the row shows nothing selected, and Save writes the orphan id
      // back (there is no fallback to `Anyone`).
      final selected = tester
          .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
          .where((pill) => pill.selected)
          .length;
      expect(selected, 1);
      await disposeApp(tester);
    });
  });

  // -- iteration 2 proofs ---------------------------------------------------
  group(
    'BUG-P09-6 — an out-of-range reward is shown at face value, saved clamped',
    () {
      testWidgets('the screen says 9999 / 9999p and the write says 100', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-9999',
                familyId: Seed.familyId,
                title: 'Mega quest',
                coins: const Value(9999),
                repeatRule: const Value('weekly'),
                days: const Value('6'),
                assigneeChildId: const Value('maya'),
              ),
            );
        await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-9999');
        expect(find.text('9999'), findsOneWidget);
        expect(find.text('= 9999p at payout'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final saved = await tester.runAsync(() => _repo.getQuest('q-9999'));
        // What the screen showed is what must be stored (or the save must be
        // blocked with a visible reason); `_save` clamps silently to 100.
        expect(saved?.coins, 9999);
        await disposeApp(tester);
      });

      testWidgets('a 0-coin quest is shown as 0 / 0p and saved as 1', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-zero',
                familyId: Seed.familyId,
                title: 'Zero quest',
                coins: const Value(0),
                repeatRule: const Value('weekly'),
                days: const Value('6'),
                assigneeChildId: const Value('maya'),
              ),
            );
        await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-zero');
        expect(find.text('0'), findsOneWidget);
        expect(find.text('= 0p at payout'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final saved = await tester.runAsync(() => _repo.getQuest('q-zero'));
        expect(saved?.coins, 0);
        await disposeApp(tester);
      });
    },
  );

  group(
    'BUG-P09-7 — tapping the alias-highlighted tile rewrites the stored key',
    () {
      testWidgets(
        'q-table (plate) saves dishwasher after a no-op-looking tap',
        (tester) async {
          await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-table');

          // The Dishes tile is highlighted through the `plate` alias, so it
          // already looks selected; tapping it is visually a no-op but
          // `onTap` normalises `_icon` to the tile key.
          expect(_iconTile(tester, 'dishwasher').selected, isTrue);
          await tester.tap(
            find.byKey(const ValueKey<String>('quest-icon-dishwasher')),
          );
          await tester.pump();

          await tester.tap(find.text('Save'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          final saved = await tester.runAsync(() => _repo.getQuest('q-table'));
          // A tap on the already-selected tile must not change what is stored.
          expect(saved?.icon, 'plate');
          await disposeApp(tester);
        },
      );
    },
  );

  group('BUG-P09-8 — an emoji-leading nickname breaks the avatar initial', () {
    testWidgets(
      'the initial is the full first grapheme, not a lone surrogate',
      (tester) async {
        final db = await setUpTestScope();
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'child-emoji',
                familyId: Seed.familyId,
                nickname: '😀 Sam',
                ageBand: const Value('7-9'),
                avatarColour: const Value('sky'),
                createdAt: Value(DateTime.utc(2026, 9, 19, 9)),
              ),
            );
        await pumpAppRoute(tester, QuestsRoutePaths.editor);

        // P05 allows any non-empty nickname ≤ 24 UTF-16 units, emoji included.
        // `_initial` took the first grapheme, which does not split the
        // surrogate pair, so the avatar receives '😀'.
        final avatars = tester
            .widgetList<NestAvatar>(find.byType(NestAvatar))
            .toList();
        expect(avatars.last.initial, '😀');
        tester.takeException(); // drain: the paint failure is proven next door
        await disposeApp(tester);
      },
    );

    testWidgets('painting the lone surrogate throws a UTF-16 error', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'child-emoji',
              familyId: Seed.familyId,
              nickname: '😀 Sam',
              ageBand: const Value('7-9'),
              avatarColour: const Value('sky'),
              createdAt: Value(DateTime.utc(2026, 9, 19, 9)),
            ),
          );
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // Flutter's paragraph builder rejects the malformed string:
      // `ArgumentError: string is not well-formed UTF-16` — the editor fails
      // to paint. (Scratch run confirmed the exact error.)
      expect(
        tester.takeException(),
        isNull,
        reason: 'a child nickname must never break the editor paint',
      );
      await disposeApp(tester);
    });
  });

  // -- iteration 3 proofs ---------------------------------------------------
  group('BUG-P09-9 — the approval block misses the design after batch 5', () {
    testWidgets('the approval card is 72 high and the due card starts at 684', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // Batch 5 made the 51x31 track the toggle's layout box, so the card's
      // old bottom-padding shave (16 -> 12, sized for the old 44-high box)
      // now makes the card 68: everything below it sits 4 px high.
      final approval = tester.getRect(find.byType(NestCard).at(1));
      expect(approval.top, 600);
      expect(approval.height, 72);
      expect(tester.getRect(find.byType(NestCard).at(2)).top, 684);
      await disposeApp(tester);
    }, skip: true);

    testWidgets('the toggle track is the design rect 303/620.5/51/31', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // `QuestEditorMetrics.toggleTrackOffset` (4, -2) compensated the OLD
      // 59x44 component; with the track as the layout box it now pushes the
      // track 4 px past the content edge and 2 px up.
      final track = tester.getRect(find.byType(NestToggle));
      expect(track.left, 303);
      expect(track.top, 620.5);
      expect(track.width, 51);
      expect(track.height, 31);
      await disposeApp(tester);
    }, skip: true);
  });

  group('BUG-P09-10 — the 59x44 hit slop is clipped by the approval Row', () {
    /// Pumps fresh (value starts ON), taps [at], and expects the flip.
    Future<void> tapAndExpectFlip(WidgetTester tester, Offset at) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tapAt(at);
      await tester.pump();
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle)).value,
        isFalse,
        reason: 'a tap at $at is inside the design ::before area (59x44)',
      );
      await disposeApp(tester);
    }

    testWidgets('5 px above the track flips the toggle', (tester) async {
      await tapAndExpectFlip(tester, const Offset(328.5, 615.5));
    }, skip: true);

    testWidgets('5 px below the track flips the toggle', (tester) async {
      await tapAndExpectFlip(tester, const Offset(328.5, 656.5));
    }, skip: true);

    testWidgets('2 px right of the track flips the toggle', (tester) async {
      await tapAndExpectFlip(tester, const Offset(356, 635.5));
    }, skip: true);
  });

  group('BUG-P09-11 — an out-of-range reward has no practical repair', () {
    testWidgets('one step must bring 9999 into the 1..100 range', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-9999',
              familyId: Seed.familyId,
              title: 'Mega quest',
              coins: const Value(9999),
              repeatRule: const Value('weekly'),
              days: const Value('6'),
              assigneeChildId: const Value('maya'),
            ),
          );
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-9999');
      expect(find.text('Coins must be 1–100'), findsOneWidget);
      expect(_savePill(tester).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey<String>('decrease')));
      await tester.pump();

      // 9999 -> 9998 still blocks Save: the parent would need 9899 taps to
      // repair the row. A corrupt row must be repairable in one step (or the
      // screen must offer a one-tap fix), not only by counting down.
      expect(find.text('Coins must be 1–100'), findsNothing);
      expect(_savePill(tester).onPressed, isNotNull);
      await disposeApp(tester);
    }, skip: true);
  });

  group('BUG-P09-12 — four icon tiles still draw the legacy glyphs', () {
    testWidgets('the six tiles draw the design glyphs in design order', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // ORCHESTRATOR_NOTES 20:09 + shared batch 5: the exact design paths
      // landed as questBed / questDishes / questHoover / questBins; Book and
      // Paw are byte-identical to the design and stay unchanged.
      expect(_iconTile(tester, 'bed').icon, NestIcons.questBed);
      expect(_iconTile(tester, 'dishwasher').icon, NestIcons.questDishes);
      expect(_iconTile(tester, 'hoover').icon, NestIcons.questHoover);
      expect(_iconTile(tester, 'book').icon, NestIcons.book);
      expect(_iconTile(tester, 'bin').icon, NestIcons.questBins);
      expect(_iconTile(tester, 'paw').icon, NestIcons.paw);
      await disposeApp(tester);
    }, skip: true);
  });

  // -- attacks that hold ----------------------------------------------------
  group('attacks that hold (not skipped)', () {
    testWidgets('a double-tap on Delete quest shows one confirm modal', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.scrollUntilVisible(
        find.text('Delete quest'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // The first tap pushes the dialog route synchronously, so the modal
      // barrier is already the hit-test target when the second tap lands:
      // the framework swallows it (warnIfMissed is expected here).
      await tester.tap(find.text('Delete quest'), warnIfMissed: false);
      await tester.tap(find.text('Delete quest'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Delete this quest?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a double-tap on Due by shows one option sheet', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      await tester.tap(find.text('Due by'), warnIfMissed: false);
      await tester.tap(find.text('Due by'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Before school (8:30am)'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a saved quest survives an app restart', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Restart quest');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await disposeApp(tester);

      // A fresh app object over the same Drift database. The library opens
      // on Ideas, so switch to Active (the saved quest is the newest row,
      // i.e. the last one).
      await pumpAppRoute(tester, QuestsRoutePaths.library);
      await tester.tap(find.textContaining('Active ('));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text('Restart quest'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Restart quest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('kid mode cannot reach /quest-editor (parental gate)', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), ParentalGateRoutePaths.gate);
      expect(find.text('New quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('kid mode cannot reach /quest-editor with a query either', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), ParentalGateRoutePaths.gate);
      expect(find.text('Edit quest'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('320-wide at text scale 1.3 has no overflow (new + edit)', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 320, 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('New quest'), findsOneWidget);
      await disposeApp(tester);

      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await _resize(tester, 320, 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('Edit quest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a one-child family defaults the new quest to that child', (
      tester,
    ) async {
      await setUpTestScope();
      await GetIt.instance<FamilyRepository>().removeChild('leo');
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      expect(find.text('Leo'), findsNothing);
      final selected = tester
          .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
          .where((pill) => pill.selected)
          .toList();
      expect(selected.single.label, 'Maya');
      await disposeApp(tester);
    });

    testWidgets('six children with long names wrap at 320 without overflow', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // Creation order (Maya, Leo, then the four added) — never sorted.
      const extras = <(String, String)>[
        ('child-max', 'Maximilian-Alexander'),
        ('child-anna', 'Annabella-Rose'),
        ('child-cass', 'Cassandra-Jane'),
        ('child-fitz', 'Fitzwilliam'),
      ];
      var offset = 2;
      for (final (id, name) in extras) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: id,
                familyId: Seed.familyId,
                nickname: name,
                ageBand: const Value('7-9'),
                avatarColour: const Value('sky'),
                createdAt: Value(
                  DateTime.utc(2026, 9, 19, 8).add(Duration(minutes: offset++)),
                ),
              ),
            );
      }
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 320, 1.3);

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<QuestPersonPill>(find.byType(QuestPersonPill))
            .map((pill) => pill.label),
        <String>[
          'Maya',
          'Leo',
          'Maximilian-Alexander',
          'Annabella-Rose',
          'Cassandra-Jane',
          'Fitzwilliam',
          'Anyone',
        ],
      );
      await disposeApp(tester);
    });

    testWidgets('dark mode Save pill keeps 4.5:1 contrast', (tester) async {
      await pumpAppRoute(
        tester,
        QuestsRoutePaths.editor,
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(QuestSavePill));
      final tokens = context.nest;
      expect(_contrast(tokens.surface, tokens.leaf), greaterThanOrEqualTo(4.5));
      await disposeApp(tester);
    });

    testWidgets('Cancel on a quest pushed from Today returns to Today', (
      tester,
    ) async {
      await pumpAppRoute(tester, TodayRoutePaths.today);
      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Edit quest'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), TodayRoutePaths.today);
      await disposeApp(tester);
    });

    testWidgets('a due time is stored as wall-clock text in any zone', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await Seed.movedToDubai(db);
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(find.byType(TextField).first, 'Dubai quest');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final saved = await tester.runAsync(() => _repo.getItems());
      final quest = saved!.firstWhere((q) => q.title == 'Dubai quest');
      expect(quest.dueLabel, 'Before tea (5pm)');
      expect(quest.dueTimeLocal, '17:00');
      await disposeApp(tester);
    });

    testWidgets('every due-sheet row exposes tap and applies the choice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Due by'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      for (final label in <String>[
        'Before school (8:30am)',
        'Before tea (5pm)',
        'Before bed (7:30pm)',
      ]) {
        final node = tester.getSemantics(find.text(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must expose tap',
        );
      }
      final bed = tester.getSemantics(find.text('Before bed (7:30pm)'));
      bed.owner!.performAction(bed.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Before bed (7:30pm) ›'), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Keep it and Delete expose tap in the confirm modal', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.scrollUntilVisible(
        find.text('Delete quest'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      for (final label in <String>['Keep it', 'Delete']) {
        final node = _button(tester, label);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must expose tap',
        );
      }
      final keep = _button(tester, 'Keep it');
      keep.owner!.performAction(keep.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete this quest?'), findsNothing);
      expect(find.text('Edit quest'), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });
  });
}
