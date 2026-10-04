# P09 — 2a build, logic chunk (FIXES_5 iteration)

## CONTRACT CHANGES (UI builder: read first)

No shape changes, no behaviour changes in this layer. Three routed items:

- **BUG-P09-14 (unique ids) is blocked on shared code + your one-liner.**
  `ORCHESTRATOR_NOTES.md` 09:27 orders `newId('q')` from
  `shared/unique_ids` — that helper exists nowhere in `app/lib` yet (the
  batch has not landed), and the minting site is your line
  (`quest_editor_view.dart:543`, still `'q-${appNowUtc()...}'`). Nothing
  in `domain/`/`data/`/`bloc/` can mint the id: events carry complete
  entities and the repo must not silently rewrite primary keys. When the
  helper lands, swap the mint, and in the same commit update the CLOCK
  test in `quest_editor_states_test.dart` (§3.1) — it asserts the stored
  id EQUALS `q-<appNowUtc ms>` exactly, so a random suffix breaks it by
  design. The parked BUG-P09-14 proof stays skipped until then (not this
  layer's file).
- **P09-TEST-8 (verbatim non-ArgumentError failures): no safe bloc change
  exists — do not rewire `_editorError`.** Mapping everything-unknown to
  generic would break the states suite's pinned offline/disk-full
  passthrough (another stage's assertions); mapping one more concrete
  type (e.g. `SqliteException`) is drift-leaking whack-a-mole. The only
  reachable producer of a raw-SQL toast was the id collision, which dies
  with the BUG-P09-14 fix above. A broader taxonomy (own copy for
  operational errors) needs orchestrator copy + cross-stage test edits.
- **CLOCK/KID-BACKGROUND rules:** my layer has no `DateTime.now()`,
  no meadow, nothing kid-mode. The feature's sole `DateTime.now()`
  was already migrated to `appNowUtc()` (view line above).

## Files changed

None in `domain/`, `data/`, `bloc/`, DI, routes, or my tests. This
iteration's FIXES_5 items are: a view one-liner blocked on shared code
(BUG-P09-14), a taxonomy question with no safe change (P09-TEST-8), a
view layout item (P09-TEST-9), and skipped proofs in files outside this
layer's names. Editing any of them from here would be scope violation.

## Verification (logic layer only)

- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- Split feature runs: 107 + 96 + 80 + 95 pass; bugs file 30 pass, 1 skip
  (BUG-P09-14 parked), 1 fail — see below. `dart format` clean.
- Whole-app `flutter test` and any simulator deliberately NOT run
  (integrator / stage 5 own them); no simulator was booted.

## One failing proof, routed (not this layer)

`p09_bugs_test.dart` BUG-P09-10 "2 px right of the track flips the
toggle" taps absolute (356, 635.5) — truly 2 px past the track's right
edge (354) — and the toggle does not flip. Ruled out from this side:
my layer has no hit-test mechanism; the batch-6 `NestCard` change is an
additive optional-`radius` param with identical defaults; geometry rects
are exact (card 72, track 303/620.5/51/31), so this is hit-test routing,
not layout. Asymmetry note for the owner: the vertical overhang probes
(5 px above/below, truly outside the track) pass — only the right
overhang misses. Coverage gap in the same area: `quest_editor_toggle_
hit_area_test.dart` computes all probes as offsets from the track
*centre* (±2/±4/±6.5 on a 51×31 box), so none of them ever leaves the
track — the bugs proof is the only true slop probe on x. View-side
and shared-hit-slop forensics belong to the UI builder/integrator
(Stack sibling? `Positioned(right: s4)` clipping the slop's right
overhang?); the test file is not mine to edit.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. Open elsewhere: BUG-P09-14
  (shared `newId` → view one-liner + CLOCK-test update + un-skip),
  BUG-P09-10 right-overhang forensics, P09-TEST-8/9, stage 5 re-shoot.

VERDICT: PASS
