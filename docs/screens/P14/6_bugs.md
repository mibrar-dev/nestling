# P14 · Rewards manager — Stage 6 adversarial bug hunt (iteration 3)

Route `/rewards` · feature `rewards` · parent mode · design
`design/html-source/screens/P14-rewards.html` + light/dark PNGs
(1170×2532 ÷3). This stage changed **nothing** in `app/lib/**`; it added four
iteration-3 guards to `app/test/features/rewards/p14_bugs_test.dart` and
rewrote this report.

Gates on the iteration-3 build (`e2ff9bb`, main merged through `b105d50`):

* `flutter test` on the ten stable feature test files →
  **+114 passed, 0 skipped, 0 failed**.
* `flutter test test/features/rewards/p14_bugs_test.dart` → **27/27 green**;
  every B01–B08 proof runs unskipped (there are no skips left, so
  `--run-skipped` is the same green run).
* `flutter analyze` / `dart format` on the bug file → clean.
* No simulator was booted, installed on, screenshotted or driven.
* `ORCHESTRATOR_NOTES.md` (12:27, 12:35) re-verified in the code: creation
  order via `watchRewardsInCreationOrder`, seed `Baking together needsOk:
  false`, toggle state DB-driven — all pinned by live proofs.

## Status of every finding

| id | severity | finding | fixed in | live proof |
|---|---|---|---|---|
| P14-B01 | major | iOS keyboard covered the sheet's Save/Cancel/Delete | iter-2 build | `[P14-B01] the keyboard must not cover the editor sheet controls` |
| P14-B02 | minor | empty/failure surfaces top-aligned, not centred | iter-2 build | `[P14-B02] …` (both) |
| P14-B03 | minor | failed sheet write lost the input, no inline error | iter-2 build | `[P14-B03] a sheet write failure keeps the sheet open with an inline error` |
| P14-B04 | minor, latent | delete orphaned reward redemptions | iter-2 build | `[P14-B04] deleting a reward with a pending request orphans the request` |
| P14-B05 | major | list ordered by coin price, not creation order | iter-2 build | `[P14-B05] rewards are listed in creation order, not price order` |
| P14-B06 | minor | stream error after data swallowed (stale list, no retry) | iter-3 build | `[P14-B06] a stream error after data still offers the failure surface` |
| P14-B07 | minor | inline write-error caption not announced | iter-3 build | `[P14-B07] the inline write-error caption is announced to screen readers` |
| P14-B08 | minor | sheet overflowed when the keyboard capped the form | iter-3 build | `[P14-B08] the sheet must not overflow when the keyboard caps the form` |

**Open bugs: none.** Every finding above has a repro, a fix and a proof that
runs unskipped and green.

## Iteration-3 verification of the B06–B08 fixes

* **B06** — the bloc pipes `watchItems()` through `_closeOnError` (forward the
  first error, then close) and the view renders the failure surface for every
  `failure`, so `Try again` always appears and re-subscribes exactly once.
  Independently re-proved end-to-end: mid-stream error → surface → retry →
  card back with `watchItems()` called **2** times.
* **B07** — the caption is `Semantics(liveRegion: true, label:, child:
  ExcludeSemantics(...))`; the node's `isLiveRegion` is now true.
* **B08** — the hand-derived chrome arithmetic is gone; the form is a loose
  `Flexible`, so the layout engine hands it exactly what the grabber/title
  left. Re-ran the full keyboard matrix — **no overflow in any case**, Save
  above the keyboard or one short scroll away:

  | device | scale | keyboard | overflow | Save (initial) | keyboard top |
  |---|---|---|---|---|---|
  | 390×844 | 1.0 | 300 | no | 382–434 | 544 |
  | 390×844 | 1.3 | 300 | no | 382–434 | 544 |
  | 390×844 | 1.3 | 336 | no | 359–411 | 508 |
  | 375×667 | 1.0 | 260 | no | 337–389 | 407 |
  | 375×667 | 1.3 | 260 | no | 359–411 (245–297 after scroll) | 407 |
  | 360×640 | 1.3 | 260 | no | 359–411 (219–271 after scroll) | 380 |
  | 320×568 | 1.3 | 260 | no | 359–411 (219–271 after scroll) | 308 |

## Iteration-3 attacks that held (new guards in the test file)

* **Keyboard matrix** — 320×568/360×640/375×667/390×844 at 1.0 and 1.3 text
  scale with 260–336 px keyboards: no exception, controls reachable.
* **Notched safe area** — with `view.padding.top = 47` (a real notch) and the
  keyboard up at 1.3, the sheet's Material starts at y = 47 and the title at
  78.5, clear of the status bar/notch (`useSafeArea: true` + `SafeArea`).
* **Sheet semantics** — exactly **one** `Needs my OK` node (the switch), with
  `SemanticsAction.tap` and `toggled: true`; `performAction(tap)` flips the
  switch (`true → false`). The visible label twin is `ExcludeSemantics`.
* **Resting geometry unchanged** — no keyboard: sheet 345→844, Save 682–734,
  Cancel 742–794 (identical to the pre-fix layout).
* All iteration-1/2 clean guards still green: kid-mode gate, Back pop, restart
  persistence, rapid double taps, 9999 coins + long name at 320×1.3, a11y tap
  actions, empty-state create, failed-toggle toast, failed-save retry, Save
  in-flight guard, cascade scope, edit position/create-last, seeded Baking
  OFF, dark mode at 1.3.

## Notes, not bugs

* **Double-tap `Try again`** stacks a second recovery subscription
  (`watchItems()` called 3× for two same-frame taps). No user-visible effect
  (both streams emit the same list); single-tap recovery is exactly one
  subscription. Recorded, not filed.
* **Keyboard-capped form on the smallest screens** (320×568 @1.3) needs one
  short scroll to reach Save. The controls are reachable — this is the
  deliberate trade for never hiding them behind the keyboard.
* **Same-frame toggle / confirmed-Delete double taps** remain unguarded (both
  are idempotent: the toggle writes the same value twice, the second delete
  matches 0 rows). Sub-frame timing only; recorded in earlier iterations.
* **Raw error tail in the caption** (`Could not save the reward: Bad state:
  disk full`) is awaiting the orchestrator ruling flagged in `2_build.md`
  (review wants friendly-only copy; stage 6 reads the tail as the contract).
* **`SHARED_REQUEST.md`** (shared bottom-sheet `viewInsets`; `NestIconButton`
  shape) still open; `Reward.detail` remains carried but unused (plan §2).

## Verdict rationale

Iteration 1's five defects (two major) and iteration 2's three minor defects
are all fixed and independently re-verified; the iteration-3 hunt found no new
defect with a repro. No major bug is open.

VERDICT: PASS
