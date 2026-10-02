# K03 Kid home — test notes (Stage 3, iteration 2)

Iteration 1 left K03 green (44 tests). Iteration 2 re-tests the fixed screen
(K03-BUG-1/2/3/5/6 fixes, the new completion/celebration state machine) and
extends the suite for the mandatory orchestrator PipAvatar rules. Two real
requirement violations were found and are recorded below; the screen was NOT
patched.

## Files

- `app/test/features/kid_home/kid_home_bloc_test.dart` — 14 → 20 tests.
- `app/test/features/kid_home/kid_home_view_test.dart` — 30 → 36 tests.
- `app/test/features/kid_home/k03_bugs_test.dart` — bug-hunt proofs
  (unchanged this stage; K03-BUG-1/2/3/5/6 un-skipped and green, K03-BUG-4
  skipped pending the foundation ruling).
- No `app/lib/**` change in this stage; nothing outside RULES §1 touched.

## New / extended tests (this iteration)

Bloc + state (7):
- state: completion outcomes are explicit and nonce-bumped
  (`withCompletionSucceeded` carries questId/coins; `withCompletionFailed`
  bumps `actionNonce`; `withCompletionStarted` clears the outcome);
- state: `copyWithLoaded` clears transient completion outcomes;
- bloc: the celebration signal rides the flip emission itself
  (`justCompletedQuestId`/`Coins` on the 5/6 state — extended existing test);
- bloc: the celebration signal clears on the next stream emission (one-shot,
  cannot celebrate twice);
- bloc: a completion that does not flip the card never celebrates;
- bloc: two identical failures both surface (reset between attempts);
- bloc: retry after a failure clears the error and celebrates on success.

View (6 new + 3 extended):
- Pip: the pet slot renders the child's own `PipAvatar` (Maya =
  mochi/sunny/none/stage 3, size 152) with no v1 art;
- Pip: the active child's database look drives `PipAvatar` (Leo =
  bolt/sky/none/stage 2);
- Pip: the empty-quests state shows the child's own Pip (**FAILS**);
- Pip: no product state renders the v1 `pip_stage_*.svg` art (**FAILS**);
- navigation: double-tapping the check completes once (one event, one
  celebration);
- navigation: a failed check tap can be retried and then celebrates;
- extended: a failed completion asserts no `/quest-complete` opens;
- extended: the child-with-no-quests test uses the shared quest-less-child
  helper.

The view fake repository now models the real one: a successful
`completeQuest` flips the quest to `done_pending` and re-emits, so the
celebration rides the flip in fake-backed tests exactly as it does on Drift.

## Results

- `dart format --set-exit-if-changed .` — 343 files, 0 changed.
- `flutter analyze` — `No issues found!`
- `flutter test` — `+380 ~1 -2`: 380 pass, 1 skip (K03-BUG-4, filed as
  SHARED_REQUEST #4), 2 fail — the two bug proofs below.
- K03 alone: bloc 20/20; view 34/36.

## Bugs found (screen NOT patched)

### K03-BUG-7 — empty-quests state renders the v1 Pip SVG

**Severity: Moderate (mandatory orchestrator rule).**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:877`
(`_KidEmptyQuests` → `NestEmptyState(art: SvgPicture.asset(pipStage1))`).

Rule: the stage brief says every Pip on a product screen must be the child's
OWN `PipAvatar`, and v1 `pip_stage_*.svg` art is never allowed in product
screens. This state has the active child loaded, so the child's look is
available.

Repro: insert a quest-less child (`Nina`, DB defaults mochi/sunny/stage 1),
set `app_state.active_child_id`, open `/kid-home` → "No quests today" shows
`assets/illustrations/pip_stage_1.svg` and zero `PipAvatar` widgets.

Failing test: `kid_home_view_test.dart:470` "the empty-quests state shows the
child's own Pip" — Expected exactly one `PipAvatar`; found 0.

Fix hint: keep the 160 px art slot, render
`PipAvatar(style/skin/accessory/stage from the child)` instead of the v1 SVG.

### K03-BUG-8 — failure state renders the v1 Pip SVG

**Severity: Moderate (mandatory orchestrator rule).**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:200`
(`_KidFailure` → `SvgPicture.asset(pipStage1)`).

Repro: register a repository whose streams error (or stop the DB), open
`/kid-home` → "Oh no! Pip got lost." renders
`assets/illustrations/pip_stage_1.svg`.

Failing test: `kid_home_view_test.dart:485` "no product state renders the v1
`pip_stage_*.svg` art" — Expected empty; actual
`['assets/illustrations/pip_stage_1.svg']`.

Fix hint: this state has no child data, so the brief's no-child fallback
applies: a neutral `PipAvatar(style: mochi, skin: sunny, stage: 1)` (or no
art at all) — never the v1 illustration.

## Verified green this iteration

- K03-BUG-1/2/3/6 fixes hold under the stage-3 suite: double-tap check →
  exactly one completion and one celebration; failed write → no K05, list
  kept, SnackBar; retry after failure → celebration; two identical failures
  both announce; the celebration signal is one-shot (cleared by the next
  stream emission).
- PipAvatar mandate in the loaded state: Maya mochi/sunny/none/stage 3 at
  size 152; Leo bolt/sky/none/stage 2; no v1 art while loaded.
- All iteration-1 coverage still green: 12-cell light/dark × 320/390/430 ×
  scale 1.0/1.3 matrix, empty/loading/error states, every tap destination,
  semantics labels, kid tap targets ≥ 56.

## Notes / observations (not bugs)

1. The pet slot composes the nest SVG with a standalone `PipAvatar`
   (`inNest` left at its default `false`) instead of the `PipStage` artboard.
   The note's slot intent — Pip ≈152 px on the 260×236 nest, feet at the rim
   — is met; checked visually against the design crop and the iteration-2
   capture, so this is not raised as a bug.
2. K03-BUG-4 ("done today" day-boundary semantics) stays skipped: needs the
   foundation ruling in `SHARED_REQUEST.md` #4.
3. Harness notes from iteration 1 still apply: direct Drift work inside a
   `testWidgets` body must go through `tester.runAsync`; avoid
   `pumpAndSettle` while a loading spinner can be on screen; use
   `tester.getSemantics` for merged card labels.

VERDICT: FAIL
