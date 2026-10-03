# P14 · Rewards manager — Stage 2b build, UI chunk (iteration 3)

Owner: UI builder. Layer: `app/lib/features/rewards/presentation/views/**`,
`presentation/widgets/**`, plus the widget/view tests in
`app/test/features/rewards/`. No `domain/`, no `data/`, no bloc edits (the
2a CONTRACT CHANGES re-read before finishing: the four write events' optional
`Completer<void>? result` channel and "writes never emit `failure`" are both
already wired in the view — `_changeNeedsOk` / `saveReward` / `deleteReward`
use them, and the view now relies on the second half, see B06). No simulator
was booted, installed on, screenshotted or driven.

## Layout status

The iteration-2 layout is unchanged and needs no work: title `Reward shop`,
the exact intro, the six `.rw` cards in database (creation) order, the
`+ New reward` button and the 20 px gutters all already measure Δ0 against
`design/screens/{light,dark}/P14-rewards.png` (stage 5, iteration 2). The
iteration-2 review's UI handoff asked the UI stage to re-measure because the
*data* changed — that is stage 5's job (row order 50 → 80 → 60 → 100 → 150
with "Baking together" **off**, `Choose dinner` below the fold); the view
already renders `watchItems()` verbatim with the toggle bound to
`reward.needsOk`, so no code change was required for it.

## FIXES_2.md items — all three open bugs closed, all proofs un-skipped

| bug | fix | proof (now live, un-skipped) |
|---|---|---|
| **P14-B06** minor — a stream error *after* the first emission was swallowed: the stale list stayed, no error surface, no `Try again` | `rewards_view.dart`: the `failure` branch drops the `items.isNotEmpty` shortcut and always renders `_RewardsCenteredScroll(_RewardsFailure())`. Safe precisely because of the 2a contract — writes report through the `result` channel and no longer emit `failure`, so the only thing that can reach this branch is the stream itself, and `emit.forEach` ends its subscription when it errors (a list rendered from it can never update again) | `[P14-B06] a stream error after data still offers the failure surface` (`p14_bugs_test.dart`) **and** a new, stronger `[P14-B06] a stream error after rows shows Try again` in `rewards_view_test.dart` (row on screen → stream dies → `Try again` present, `RewardCard` gone, `Something went wrong` shown, and `Try again` really re-subscribes to the empty state) |
| **P14-B07** minor — the inline write-error caption was a plain `Text`, so a failed save was silent to VoiceOver/TalkBack | `p14_reward_editor_sheet.dart`: the caption is now `Semantics(liveRegion: true, label: …, child: ExcludeSemantics(child: Text(…)))` — the `NestTextField` error-row pattern (`nest_text_field.dart:341-354`, P03 §8), announced exactly once | `[P14-B07] the inline write-error caption is announced to screen readers` |
| **P14-B08** minor — the sheet re-derived `NestBottomSheet`'s chrome by hand and under-counted it (it used `fontSize × height` for a title row that is really `max(line, 44 px close button)`, with no text scaler), so `available` was 13–20 px too generous and the form overflowed the sheet's Column when the keyboard capped it | **The arithmetic is gone.** `RewardEditorSheet.build` now returns `Flexible(fit: loose, child: Padding(bottom: keyboard, child: SingleChildScrollView(_form())))`. A loose flex child is handed exactly the height the grabber and title row left over, measured by the layout engine, at any text scale and any shared-component change — so there is nothing left to drift from `NestBottomSheet`, which is what stage 4 finding 4 asked for. Loose fit preserves the resting geometry byte-for-byte (the form shrink-wraps; `rewards_write_failures_test.dart`'s "with no keyboard the sheet sits exactly where it always did — sheet 422→794, Save 682→734" still passes) and scrolls only when the keyboard leaves genuinely too little room | `[P14-B08] the sheet must not overflow when the keyboard caps the form` (390×844 @1.3 with a 336 px keyboard, `Save.bottom ≤ keyboard top`), plus the existing `[P14-B01]` keyboard proof |

The six other iteration-1 proofs (B01–B05, `ORDER`) were already live and stay
green; the last skip in the feature directory is gone.

### A harness artefact found while un-skipping B06 (worth recording)

Both B06 proofs drove a hand-made `StreamController`, added rows, then
`addError`. With the branch fixed and the assertions passing, **the tests
never returned** — they hung at the end of the body and then at the test
framework's own `asyncBarrier`. Reproduced four times, isolated to the
controller: the same flow with a self-terminating stream passes in seconds,
and the view code is identical. The cause is the test's own fixture — a
single-subscription controller left open across the error, whose cancelled
subscription stays pending in the fake-async zone (it was masked before only
because the assertions failed first). Both proofs now use a self-terminating
`async*` stream — *rows, then the error, then done*, which is exactly the
shape a Drift `QueryStream` takes when its query fails. No assertion was
weakened, removed or re-pointed; the two `pump` calls that used to add and
error are now one pump before the 200 ms mark (the card must really be on
screen first) and one past it.

## Stage 4 review items in this layer

* **Finding 2 (duplicate announcement) — fixed.** The sheet's `Needs my OK`
  row had both a visible `Text` and a `NestToggle` carrying the identical
  label, so VoiceOver read "Needs my OK" and then "Needs my OK, switch, on"
  for one control. The visible twin is now `ExcludeSemantics`; the switch
  keeps the label (and its `toggled`/`enabled` state and tap action), so the
  row announces once. `rewards_a11y_test.dart`'s "one activatable node per
  label" proof still holds unchanged.
* **Finding 4 (chrome re-derived by hand) — fixed**, see B08 above; the
  `SHARED_REQUEST.md` line stays open for the keyboard inset itself, which is
  the shared helper's job, not this screen's.
* **Finding 5 (`_EditButton` hand-rolled because `NestIconButton` is
  circular) — unchanged**, still correct and still filed in
  `SHARED_REQUEST.md` for `NestIconButton.shape`. The 44×44 radius-12 rect,
  fill, border and icon are asserted numerically by
  `reward_card_widget_test.dart` and `rewards_responsive_test.dart`.
* **Finding 1 (the inline caption interpolates the raw exception) — NOT
  changed, deliberately, and it needs a spec decision.** `p14_bugs_test.dart`
  `[P14-B07]` locates the caption with `find.textContaining('disk full')` and
  asserts it is a live region, so dropping `$error` from
  `RewardCopy.saveError` / `deleteError` would fail that proof. Stage 4
  (finding 1) and stage 6 ("Notes, not bugs" — "friendly sentence first; the
  technical tail matches the build's stated contract") disagree about
  whether the tail belongs in parent-facing copy. That is a judgement call
  about intended behaviour, and per the stage-3 lesson it belongs in a spec,
  not in a test I should quietly relax. Filed under LEFT FOR NEXT ITERATION.
* **Findings 6–7 (test-hygiene comments and `disposeApp` on mock-repo
  tests) — test-stage files**, not mine. Finding 7's prescription for
  mock-repository tests ("no Drift stream is open, so no drain is needed") is
  exactly what the B06 teardown now documents.

## Gates (no simulator, no whole-app suite — the integrator runs those)

```
$ dart format lib/features/rewards test/features/rewards     # clean (0 changed after format)
$ flutter analyze lib/features/rewards test/features/rewards
No issues found! (ran in 3.1s)

$ flutter test test/features/rewards/
00:05 +103: All tests passed!
```

103 passed / **0 failed / 0 skipped** (up from 97 passed + 4 skipped in
iteration 2): the three un-skipped bug proofs, the new B06 view proof, and
bloc / repository / a11y / responsive (320/390/430 × 1.0/1.3 × light/dark) /
states / order / card-geometry / view / write-failure files all green.

No `google_fonts`, no `letterSpacing`, no `Colors.*`/`Color(0x…)`/literal
sizes, no new hand-rolled component, no `skip:`, no `ignore:`, no
`analysis_options.yaml` change, no copy retyped (the design copy is
untouched by this iteration — B06/B07/B08 are all behaviour, not layout).

## LEFT FOR NEXT ITERATION

1. **Review finding 1 — the raw exception in the sheet caption copy.** Needs
   an orchestrator ruling: either (a) the copy becomes
   `Could not save the reward. Please try again.` and the `[P14-B07]` proof's
   `find.textContaining('disk full')` locator changes to the friendly
   sentence, or (b) the tail stays and the review finding is closed. Both
   stages cannot be right at once; I did not edit either.
2. **Stage 5 re-measure.** The UI check should re-measure title y, intro y
   and each card top (the layout did not move, but the visible data did:
   `Baking together` renders **off** and `Choose dinner` is below the fold)
   and confirm the bottom edge — the screen has no bar, so `paper` runs to
   the physical edge by construction.
3. `SHARED_REQUEST.md` still open (bottom-sheet `viewInsets` in the shared
   `showNestBottomSheet`, and `NestIconButton.shape`). Both are filed; the
   P14-local versions stay until they land.
4. Not mine, flagged only so the next stage is not surprised: `rewards_bloc.dart`
   and `rewards_bloc_test.dart` show as modified in `git status` — that is the
   2a builder's parallel work in this shared worktree, not mine.

VERDICT: PASS