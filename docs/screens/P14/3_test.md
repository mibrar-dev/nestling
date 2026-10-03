# P14 · Rewards manager — Stage 3 tests (iteration 3)

Route `/rewards` · feature `rewards` · parent mode. Test-only stage:
`git status --porcelain -- app/lib tools/` is **empty**.

## Gates

```
$ dart format .
Formatted 470 files (0 changed) in 1.21 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test
01:35 +2247 ~1: All tests passed!
```

**117 passed / 0 failed / 0 skipped** in the feature dir (was 103 with 0 skipped
in the iteration-3 baseline; the one remaining app-wide skip is in P02's
onboarding suite, not this feature).

| file | tests |
|---|---|
| p14_bugs_test | 27 · rewards_a11y_test 14 · rewards_responsive_test 16 |
| rewards_bloc_test 17 · rewards_repository_test 11 | rewards_view_test 9 · rewards_states_test 7 |
| rewards_write_failures_test 9 · reward_card_widget_test 4 | rewards_order_test 3 |

## Iteration 2's three bugs are fixed, and I verified the fixes

`grep -rn "skip:" test/features/rewards/` → **none**. All of B06/B07/B08 now
run live. I re-measured each independently before trusting the green:

* **B06** (stream error after data swallowed) — fixed on both halves: the view
  drops the `items.isNotEmpty` short-circuit, and the bloc pipes `watchItems()`
  through `_closeOnError` so a failed load releases its subscription.
* **B07** (inline caption not a live region) — the caption is now
  `Semantics(liveRegion: true, label: …, child: ExcludeSemantics(child: Text))`.
* **B08** (sheet overflows when the keyboard caps the form) — the hand-derived
  chrome arithmetic is gone, replaced by a loose `Flexible` + `SingleChildScrollView`.

**No new bugs found.** The iteration-3 code behaves correctly across every probe
I threw at it.

## Tests added (7, all in existing files so each lands where a maintainer looks)

**`rewards_bloc_test.dart` — subscription hygiene.** The B06 logic fix is only
worth what it delivers, and one recovery (`watches == 2`) does not prove it.
New test drives four consecutive failing loads and asserts `live == 0` after
each — a dead subscription parked on a dead stream is invisible in the UI, so
it has to be measured — then a recovering load leaves exactly one live, and
`bloc.close()` releases it.

**`rewards_responsive_test.dart` — the full keyboard matrix (6 rows).** The bug
sweep covered B08 for one combination; the other four (and a sixth I added) were
unguarded. Each row asserts no `RenderFlex` overflow *and* that `Save` ends up
above the keyboard — scrolling to the end when it does not start there.
The sixth row, **320×568 @ 1.3 with a 260 px keyboard**, is the one that
actually exercises the scroll escape (see below). Also pinned the resting sheet
in both modes: create `422→794`, edit `362→794` — the keyboard work moved
neither.

**`rewards_a11y_test.dart` — two announcement contracts.** The sheet switch is
announced exactly once (iteration 3 wrapped the visible `Needs my OK` twin in
`ExcludeSemantics`; VoiceOver previously read the label twice for one control),
and the B07 caption is one live region announced once.

## Two mistakes of my own, both caught before they shipped

**1. I nearly filed a phantom dead-control bug.** Chasing the keyboard, I
measured `maxScrollExtent == 0` at 320×568 and concluded Save/Cancel/Delete
were stranded behind the keyboard with no escape — a repeat of B01. It was my
measurement: `find.byType(Scrollable).last` matches the **name field's**
internal scrollable, not the form's. Querying the Scrollable that actually owns
the Save button gives `viewport 181, maxScroll 213`, and after scrolling to the
end `Save.bottom = 197` — comfortably above the keyboard top at 308. The sheet
behaves correctly; my probe lied.

**2. My own responsive test carried that same bug.** Its scroll branch drove
`find.byType(SingleChildScrollView).last` and asserted reachability afterwards.
It passed — but only because every matrix row happened to start with `Save`
already above the keyboard, so the branch never ran. It would have "passed" a
genuinely dead button. Fixed to drive the owning Scrollable, to assert
`maxScrollExtent > 0` before relying on the scroll, and given the 320×568 row
that makes the branch actually execute.

Also corrected two of my own over-strict assumptions: the card does **not**
announce its visible `Needs my OK` (the `.okrow` subtree absorbs it into an
ancestor node), and I had hard-coded the sheet switch as "on" — `Baking
together` seeds `needsOk: false`, the design's own state. That is the exact
hard-coding trap `ORCHESTRATOR_NOTES` warns about, in a test written to prevent
it; it now reads `rewardNeedsOk('r-baking')`.

## ORCHESTRATOR_NOTES (12:27 + 12:35) — every mandatory item verified live

1. **Creation order** — `rewards_order_test.dart` runs both layers green: the
   screen renders `watchItems()` verbatim, and that order equals `Seed.demo()`'s
   insertion sequence. No price sort remains in the feature.
2. **Baking `needsOk: false`** — pinned in the repository test's seeded map and
   read from the DB everywhere else.
3. **No hard-coded toggle state** — verified by the correction above; every
   toggle assertion reads `rewardNeedsOk(id)`.

## Notes for the next iteration

* Process cleanup, not a finding: `_p14_probe*.dart` scratch files from earlier
  stages were untracked, assertion-free, and the runner was invoking dozens of
  throwaway `print`-only tests. All removed; this stage's own probes deleted
  too. The feature dir now contains only real tests and one harness file.
* Still true from iteration 1: `setUpAll(loadBundledFonts)` is mandatory or the
  overflow assertions are meaningless; `pumpAndSettle` alone will not show a
  written Drift row (await the future first); `tester.runAsync` is required for
  `watchItems().first` inside a widget test.
* New, from this iteration: **when asserting scroll behaviour, always address
  the `Scrollable` by what it contains.** `find.byType(Scrollable)` matches at
  least three here — the list, the form, and the text field's internal one — and
  `.last` picks the wrong one often enough to silently assert nothing.
* `SHARED_REQUEST.md` is still open for the shared `showNestBottomSheet`
  keyboard inset. P14 ships a feature-local copy; the other screens do not.

VERDICT: PASS