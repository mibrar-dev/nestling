# P14 · Rewards manager — Stage 2b build UI (iteration 2)

Owner: UI builder. Layer: `app/lib/features/rewards/presentation/views/**` +
`presentation/widgets/**`, plus the view/widget tests in
`app/test/features/rewards/`. No `domain/`, `data/` or `bloc/` file was
touched (the logic builder's concurrent edits to
`data/rewards_repository_impl.dart`, `bloc/rewards_bloc.dart` and
`bloc/rewards_event.dart` are its own), and no shared code outside the
feature.

## CONTRACT USED

Re-read `docs/screens/P14/2a_build_logic.md` before finishing — **CONTRACT
CHANGES (additive)**: the four write events gained an optional
`Completer<void>? result`. This build uses it exactly as declared:

* `saveReward()` passes `result:` and returns the completer's future;
* `deleteReward()` does the same for `RewardsDeleteRequested`;
* `RewardsNeedsOkChanged` also passes a channel so a failed flip can raise a
  toast (the toggle itself always shows the database value).

`2a` also removed the write-failure `failure` emit, so the full-screen error is
now only reachable through the stream's own error — which is what
`_RewardsFailure` now assumes.

## Files

- `app/lib/features/rewards/presentation/views/rewards_view.dart` — centred
  empty/failure scroll, no trailing spacer, static failure copy, safe
  `onDelete`, `showRewardEditorSheet` (keyboard-aware opener), the three
  write helpers on the result channel.
- `app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart`
  — keyboard inset + scrollable body, inline error caption, in-flight guard,
  every string from `RewardCopy`.
- `app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart` —
  `RewardCopy` gains the sheet strings (`nameLabel`, `priceLabel`,
  `decreasePrice`, `increasePrice`, `payoutHint()`, `saveError()`,
  `deleteError()`, `actionFailed`).
- `app/lib/features/rewards/presentation/widgets/p14_reward_card.dart` —
  `NestDevice.tapParent` instead of the literal `44.0`.
- `app/test/features/rewards/p14_bugs_test.dart` — B01/B02/B02-failure/B03
  un-skipped (B04/B05 were un-skipped by the logic builder).
- `app/test/features/rewards/rewards_states_test.dart` — the failure-state
  assertions now expect the static copy (review finding 2) and assert the raw
  exception is *not* shown.
- `docs/screens/P14/SHARED_REQUEST.md` (new) — the shared bottom-sheet
  keyboard inset.

The card geometry, the list order, the intro, the nav bar and the
`+ New reward` button are **untouched** — no design drift.

## FIXES_1.md — every item, in this layer

| item | fix |
|---|---|
| Review 1 (major) — a failed write lost the input and replaced the list with a raw exception | `_submit()` is async: it awaits `onSave`, keeps the sheet open on error and paints `RewardCopy.saveError` above Save; Save is disabled while in flight (`_saving`), so a double tap cannot write twice. Delete uses the same channel. P14-B03 proof passes. |
| Review 2 (minor) — raw exception as user copy | The full-screen failure renders `RewardCopy.loadError` only; `state.errorMessage` stays the technical detail. |
| Review 3 (minor) — trailing 16 px spacer | `_RewardsScroll` no longer appends anything; the 66 px bottom pad already stands in for the home band. |
| Review 4 (minor) / **P14-B02** — empty + failure top-aligned | New `_RewardsCenteredScroll` (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight:)` + `Center`) keeps the 20 px gutters and the 66 px pad and centres both surfaces in the viewport. Measured: empty-state centre 442.5 vs viewport centre 475.5 (was 294.0); failure union centre 442.5 (was 153.0). Both proofs pass. |
| Review 5 (minor) — split copy + literals | All five sheet strings moved into `RewardCopy`; both `SizedBox(6)` → `NestSpacing.gap6`; `const size = 44.0` → `NestDevice.tapParent`. |
| Review 6 (minor) — `reward!` force-unwrap | `onDelete: existing == null ? () async {} : () => deleteReward(bloc, existing.id)`. |
| Review 9 / **P14-B01** (major) — the keyboard covered the sheet | See below. Proof passes. |
| Review 7–8 (a11y `performAction`, test hygiene) | Already covered by the test stage's files; still green. |
| Review 10 (probe scratch files) | Gone from the tree. |

## P14-B01 — the keyboard fix, and why it is feature-local

`showNestBottomSheet` caps the sheet at 92 % of the screen and never reads
`MediaQuery.viewInsets`; the cap is also read once, when the sheet opens —
before a keyboard exists. The fix is two-part:

1. **`showRewardEditorSheet`** (`rewards_view.dart`) opens the shared
   `NestBottomSheet` (same grabber, radius, `paper` fill, scrim, safe area,
   close button) through `showModalBottomSheet` **without** a `constraints`
   cap, so the sheet may grow by the keyboard band and ride its top off-screen
   instead of leaving the buttons behind the keyboard.
2. **`RewardEditorSheet`** pads its form by `viewInsetsOf(context).bottom`
   (plain `Padding`, no implicit animation — the motion rule) and caps the
   form itself: `screen - chrome` while the keyboard is up, the resting
   `screen * 0.92 - chrome` when it is not, where `chrome` is
   `NestBottomSheet`'s own padding/grabber/title (107, derived from tokens and
   `NestType.h3`, never hard-coded). The form lives in a
   `SingleChildScrollView` inside that cap, so it scrolls rather than
   overflowing when the room left is short — which also removes the 23 px
   `RenderFlex` overflow the old bare `Column` produced inside the sheet.

Measured with a 300 px inset (`[P14-B01]`, 390×844): `Save` 682→734 becomes
404→456, `Cancel` 742→794 becomes 464→516 — both above the keyboard top of
544, and the resting layout (no keyboard) is unchanged.

`SHARED_REQUEST.md` asks for the same fix in the shared helper so the other 29
screens can delete their local copies.

## Owner / orchestrator rules

- **BOTTOM EDGE** — no bottom bar, tab bar or CTA on this screen; the
  `Scaffold` paints `paper` to the physical edge and the sheet is a
  `NestBottomSheet` in `paper`. Removing the trailing spacer makes the last
  child sit where the design puts it.
- **ALIGNMENT** — one 20 px gutter for both scroll roots; the card's tile,
  column and edit rects are untouched (still asserted numerically by
  `reward_card_widget_test.dart`).
- **DATA OVER MOCKS / CHILD ORDER** — the view renders the stream verbatim;
  the creation order and the per-row `needsOk` come from the repository (2a).
  Nothing about the toggle is hard-coded.
- **COPY** — em dash U+2014, `é` U+00E9, ASCII `+`; every string now lives in
  `RewardCopy` for a single diff against `P14-rewards.html`.
- **FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS / TRIAL / PIP** —
  N/A or untouched. No `google_fonts`, no `letterSpacing`, no chips, no
  `text-wrap: balance` on this screen, no `subscription_status` write.
- **ACCESSIBILITY ACTIONS** — every control still exposes
  `SemanticsAction.tap`; the inline error is plain text and the disabled Save
  passes no action, which the a11y test asserts.
- **UI CHECK MEASURES SHAPES** — the card rects (350×122, 40×40 tile, 51×31
  track at x 179, 44×44 edit button) are unchanged and still asserted.
- **SIMULATORS** — none used.

## Verification

```
$ flutter analyze lib/features/rewards test/features/rewards
   No issues found!
$ dart format --output=none --set-exit-if-changed lib/features/rewards test/features/rewards
   25 files, 0 changed
$ flutter test test/features/rewards/
   00:04 +84: All tests passed!
```

84 tests, 0 failed, 0 skipped — the five stage-6 bug proofs (B01, B02 ×2,
B03, B04, B05) are all un-skipped and green. No whole-app `flutter test` and no
simulator: the integrator owns those.

## LEFT FOR NEXT ITERATION

1. **Stage 5 must re-measure the list.** The list layout did not move (intro at
   the same y, card pitch 138, the same x rects), but the `+ New reward`
   button's bottom edge when scrolled to the end is now 16 px lower than
   iteration 1 — that is review finding 3's intended correction (the design has
   no gap after the last child).
2. **Sheet restyle is unverified against a render.** The sheet has no design
   reference, but the resting sheet is now 107 px shorter in the sense that it
   caps itself; if a stage-5 screenshot of an open sheet looks 16–23 px
   different from iteration 1, that is the chrome reservation, not a drift in
   the list screen.
3. **`SHARED_REQUEST.md` (bottom sheet)** — when the shared
   `showNestBottomSheet` is fixed, delete `showRewardEditorSheet` and go back
   to it.
4. **`Reward.detail`** is still carried but unused by P14 (price shows in the
   coin pill), per plan §2 — left alone.

VERDICT: PASS
