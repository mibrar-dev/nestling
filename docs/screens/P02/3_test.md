# P02 Value tour — test notes (Stage 3, iteration 3)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every
router test ends with `disposeApp()`. No screen, bloc, route or design-system
code was changed by this stage.

This iteration ran against the **iteration-3 build**, which implements the
mandatory `docs/screens/P02/ORCHESTRATOR_NOTES.md` (the tour is a marketing
*illustration*: design copy and data win over the database, punctuation is
verbatim, no truncation) and the BOTTOM EDGE / ALIGNMENT owner rules. Those
build fixes landed in the worktree *during* this stage (the
`ValueTourPreviewRow` `FittedBox` at 09:31, the repository copy at 09:34), so
each half was verified as it landed and every gate was re-run against the
settled tree (no `lib/` write in the 2 minutes before the final run).

## Tests added / changed this stage

### `p02_bugs_test.dart` — **zero skips now (was 4)**

The bugs stage had left `P02-BUG-7/8a/8b/9` as `skip: true`. All four are
fixed by the iteration-3 build, so they are now **enforced, un-skipped
regressions** and the file runs clean with no skips:

- **BUG-8a** card-1 rows use the design's static copy (Maya · weekly, Leo ·
  once, Maya · daily, Maya · weekly) — un-skipped, passes.
- **BUG-8b** both card date chips are the design's static `Sat 4 Oct`
  (the derived payout Saturday is gone) — un-skipped, passes.
- **BUG-9** step-1 body and card heads use the design's punctuation (curly
  quotes, em dash, U+2019) — un-skipped, passes.
- **BUG-7** card-1 titles render in full at the design width — un-skipped,
  passes: the title now lays out unbounded inside `FittedBox(scaleDown)`, so
  no ellipsis can trip. The file header was updated to the true status table.

Two of these were initially red for a test-side reason, not a screen reason:
`_cardOne()` still matched the old straight apostrophe (`Today's quests`)
after the build switched the heads to U+2019, so the BUG-2 and BUG-8b
finders matched nothing (`Bad state: No element`). The finder was corrected to
`'Today’s quests'`; BUG-2 (38dp rows) then passed again unchanged. Header and
BUG-7 comments now record the shipped contract.

### `value_tour_view_test.dart` — 61 → **71 tests** (10 added)

- **Every page's copy, character by character (4)** — notes item 2 is
  mandatory for *all* pages, but only page 1's block exists in the HTML
  (`:128-129`); pages 2–3 were previously unasserted. Three step tests pin
  each title and body verbatim, and a fourth asserts the three card heads
  use U+2019 **and** that no straight-apostrophe variant exists anywhere
  (no silent ASCII fallback).
- **The design's copy is byte-identical under every seed (1)** — the direct
  proof of notes item 1. It renders card 1 under `Seed.demo` (Maya 120 coins,
  3 approvals, 12 quests), `Seed.empty` (onboarded parent, no children) and
  `Seed.fresh` (nothing), snapshots rows/subs/coins + chip + progress, and
  requires all three snapshots to be **one identical string** which is the
  design's copy. This replaces the iteration-2 "derived chip" test and would
  catch any re-introduction of a database dependency in the illustration.
- **No preview title is truncated at 320dp × text scale 1.3 (1)** — the second
  half of notes item 3, which had no widget proof. Font-agnostic: whether the
  row scales the title down or lets it wrap, `RenderParagraph
  .didExceedMaxLines` must be false for all four names.
- **Two fast taps advance one step, never skip a page (1)** — review 7's fix
  (`animateToPage(target)` instead of `nextPage`) had no test. Two taps 50ms
  apart must land on step 2, not step 3, with the CTA still `p02_next`.
- **Live configuration changes (2)** — `didChangeDependencies` rebuilds the
  `PageController` when the viewport fraction changes; neither path was
  covered. A live resize (390 → 320 while on step 3) must keep the step, the
  dots index, the `Continue` CTA and the clamped card width; a live
  text-scale change (1.0 → 1.3) must grow the pager 400 → 520dp and keep the
  step. Both were real risks (a controller disposed mid-flight) and both pass.
- **The repository’s step copy matches what the view renders (1)** — the
  build mirrored the design's punctuation into
  `onboarding_repository_impl.dart` mid-stage, which makes pre-load/loaded
  parity a real contract. The test reads the repository's three steps through
  DI and requires each title and body to be the string the view actually
  renders on that step, then pins all three details literally. Two tests in
  `onboarding_bloc_test.dart` (which pinned the old straight-quote strings)
  were realigned to the same source of truth.
- **The dashed add-rows are labels, not controls (1)** — completes the tap
  audit: each `.pv-add` row on all three cards announces as plain text, has
  no `SemanticsAction.tap`, and neither pages nor navigates when tapped.

## Contract tests realigned to the mandatory notes

The iteration-2 build had followed the (now superseded) data-over-mocks
reading, so the contract file pinned the wrong things. Realigned:
`_expectedPayoutChip()` (derived payout Saturday) → the static `Sat 4 Oct`
chip, with the `Sat 4 Oct findsNothing` assertion removed; step-1 body straight
quotes → curly quotes + em dash; the three card heads → U+2019; card-1 subs
(seed values) → the design's; the card-3 ledger test dropped its
`formatPounds(…)`/Drift-derived expectations in favour of the design's static
£3.00 / +£1.20 / £4.20. The now-unused `london_time.dart` import is gone
(`flutter analyze` clean, no ignores, no weakened analysis options).

## Results (run by this stage, `app/`)

- `dart format .` — 354 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **132 passed, 0 failed,
  0 skipped**.
- `flutter test` (full suite) — **562 passed, 0 failed, 0 skipped**
  (was 547 passed + 4 skipped).

## Bugs found

**None open.** All three mandatory-note findings from the bugs stage
(BUG-7/8/9) are fixed in the screen and now enforced by un-skipped proofs, and
the suite has zero skips for the first time. The red tests seen mid-stage were
stale expectations (straight apostrophes and the old repository punctuation,
both superseded by the notes) and three wrong assertions of my own
(`snapshots.single` on a 3-element list; a resize assertion on a card the
`PageView` had disposed; an add-row page-index assumption) — all corrected in
the test layer; no screen code was touched.

Residual observations (non-blocking, no user impact, no failing test):

- The lazy route-level `BlocProvider` (`onboarding_routes.dart:36-40`) still
  only runs its load event on the first read; unchanged since iteration 1 and
  pinned deliberately. Now that the repository copy is exercised, the parity
  test above shows what a first read yields.
- `SHARED_REQUEST.md` items 1–3 (compact nav-bar wide action, shared compact
  preview-row variant, pager-metric tokens) are still open and non-blocking.
  Note 3 is now satisfied by a feature-private `FittedBox(scaleDown)` inside
  `ValueTourPreviewRow`, which is one more reason for shared item 2 to land.
  Residual trade-off for the orchestrator: at 320dp × 1.3 the title scales to
  ≈0.74 rather than wrapping, so it renders smaller than the scaled design
  size — legible and untruncated, but not the "wrap where there is room"
  wording of the note.
- Uncommitted build work in the worktree (process item, per the stage rules).

VERDICT: PASS
