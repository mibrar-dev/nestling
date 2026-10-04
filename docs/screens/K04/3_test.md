# K04 Quest detail — Stage 3 test (iteration 2)

Scope: close the coverage gaps iteration 1 declared, then re-run
`flutter analyze` + `flutter test`. Inputs: `1_plan.md` §f, `RULES.md`,
`ORCHESTRATOR_NOTES.md` (14:28 + 15:08 updates), `6_bugs.md`, `5_ui.md`.
**No simulator was booted, installed on or driven** (stage 5 only).

## Verdict up front: FAIL

The brief's bar is *"PASS only if all tests pass **and no bugs were found**"*.
The first half holds; the second does not. There is a **known, open, currently
failing bug on this screen — K04-BUG-4** — and its regression proof is
`skip: true`, so a green suite partly reflects a hidden failure. I verified that
independently rather than taking stage 6's word for it:

```
$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-4 \
    test/features/kid_home/k04_bugs_test.dart
Expected: TextOverflow:<TextOverflow.ellipsis>
  Actual:   TextOverflow:<TextOverflow.clip>
00:00 +0 -1: Some tests failed.
```

Per the brief I did **not** patch the screen. `6_bugs.md` records it as Minor
(`NestBalancedText(quest.title, … maxLines: 3)` in `quest_detail_view.dart:577`
passes no `overflow:`, and the component defaults to `TextOverflow.clip`, so a
title needing more than 3 lines is cut mid-word with no ellipsis). The fix is
one argument at that call site, or a shared default — the orchestrator decides.

A second, larger reason this stage cannot PASS: the UI check `5_ui.md` is
**`VERDICT: FAIL`** with an open **Major** — the hero tile glyph. That is not a
test finding of mine, but it means the screen is not in a shippable state, and a
test stage should not hand a green tick over the top of it.

## Tests added this iteration (47 new cases)

### `quest_detail_bloc_test.dart` — NEW, 9 cases
Closes the "bloc_test for every event/state path" and `stepsFor` gaps with a
scripted repository (fresh streams per `watchHome()`, like Drift).

- `LoadRequested` walks initial → **loading → loaded → loaded+profiles**. The
  third emission is the profiles roster, which `_onLoadRequested` starts
  alongside the home stream; my first expectation wrongly listed two states and
  failed, which is how the two-subscription contract got pinned rather than
  assumed.
- The load guard ignores a reload while the stream is live (`watchHomeCalls == 1`
  after two loads) — K03-BUG-15, the guard `Try again` depends on.
- A load **after** a stream failure really re-subscribes (`watchHomeCalls == 2`,
  status back to `loaded`) — the K04 failure card's whole recovery path.
- `QuestCompleted` celebrates once on the flip, carrying `justCompletedCoins: 15`
  into the K05 extra.
- A failing write raises `actionError` + bumps `actionNonce`, and **no**
  celebration fires.
- A quest vanishing mid-flight never lets a recycled id celebrate.
- `stepsFor` delegates, never throws for an unknown id, and is readable before
  any load event; **plus one case against the real seeded Drift DB** asserting
  `q-tidy`'s three steps in seed order — the checklist column the whole screen
  hangs off that single call.

### `quest_detail_matrix_test.dart` — NEW, 19 cases
Closes the **dark-mode** and **430 px** gaps: `{light, dark} × {320, 390, 430} ×
{1.0, 1.3}` on the real seeded DB.

- No overflow, copy intact, and **ALIGNMENT** enforced per cell: the steps card
  and both buttons share 20 px gutters at *every* width (`card.left == 20`,
  `card.right == width - 20`), and the tile / pill / cheer row re-centre on the
  new midpoint.
- **BOTTOM EDGE** in both modes: bar rect is `left 0 … right width`,
  `bottom == 844`, filled with that theme's `surface` token — plus a
  *structural* proof that the bar is the body `Column`'s **last child**, so
  nothing can paint below it or around the home pill. Note the dark design PNG
  **does** show a meadow strip under the bar; the owner rule overrides the
  designs and the app correctly does not reproduce it.
- Dark is genuinely dark: `surface == 0xFF1F1C2E` vs light `0xFFFFFFFF`, on both
  the bar and the card, so a light-mode colour leak or a swapped theme fails.
- Dark interactions still work: `I did it!` → `/quest-complete`, a step toggles
  to the **dark** `leaf` token, bottom `Back` → `/kid-home`.

### `quest_detail_touch_targets_test.dart` — NEW, 10 cases
Closes the tap-target gap as a *rule* rather than a side effect of the geometry
test: `{320, 390, 430} × {1.0, 1.3}`, asserting every control's rendered box is
≥ `NestDevice.tapKid` (56) tall and ≥ `tapParent` (44) wide — back and lock
exactly 56×56, step rows ≥ 60, both bar buttons ≥ 56.

Reachability is proven separately, which is the part a size assertion misses: a
step toggles when tapped in the **empty 140 px right of its painted label**,
on the ring itself, and 5 px inside its top edge; and the lock's
`performAction(SemanticsAction.tap)` really pushes `/parental-gate`.

### `quest_detail_view_test.dart` — EXTENDED, 19 → 28 cases
- **`Seed.empty` on the real repository** (no fake): onboarded parent, no
  children, no active child → `Who's playing?`, no quest, no coin pill, chrome
  intact, `Choose` → `/who-is-playing`.
- The four non-loaded states (loading, failure, missing quest, no child) each
  re-pumped at the tightest cell **320 px @ 1.3×** in **both themes** — 8 cases.
  The `PipAvatar(140)` failure card and the wide buttons were the overflow risks.

## Results (real runs)

```
$ dart format test/features/kid_home/
$ flutter analyze
No issues found! (ran in 4.0s)

$ flutter test --timeout 120s test/features/kid_home/quest_detail_*.dart
00:02 +69: All tests passed!          # 9 bloc + 19 matrix + 10 targets + 28 view + 3 geometry

$ flutter test --timeout 120s test/features/kid_home
00:12 +544 ~4: All tests passed!

$ flutter test --timeout 120s
01:32 +3675 ~5: All tests passed!
```

K04 now has **69** cases across five files (was 22). The suite-wide count moved
3415 → 3675: ~48 are mine and the rest came from other screens' tests landing
in this worktree between iterations — not a K04 change.

The 5 skips include the **K04-BUG-4 proof**, which is the skip this verdict
turns on. The Drift "AppDatabase multiple times" warning is pre-existing harness
noise. `analysis_options.yaml` was not touched and nothing outside
`app/test/features/kid_home/**` + `docs/screens/K04/**` was written.

## Iteration-1 gaps — status

| gap | status |
|---|---|
| Dark mode uncovered | **closed** — 19-case matrix, colours from tokens + structural bottom-edge proof |
| Width 430 uncovered | **closed** — all three widths in the matrix and the target rules |
| Tap targets implicit | **closed** — size rule at 6 cells + edge-reachability probes |
| `stepsFor` untested | **closed** — 4 cases incl. the real seeded DB |
| `quest_detail_copy_parity_test.dart` absent | **not a gap** — copy parity is a group in the view test; no coverage lost, left as is to avoid churn |
| Non-loaded states at 320 @ 1.3× / dark | **closed** — 8 new cases |

## Not findings / process

Per the orchestrator rules these are not reported as blockers: the uncommitted
stage 4/5/6 artefacts in the worktree (`4_review.md`, `5_ui.md`, `6_bugs.md`,
`k04_bugs_test.dart`, `ui/*.png`) and merge order — all handled by the loop.

`ORCHESTRATOR_NOTES.md` 15:08 asks kid screens to switch to the shared
`questIconFor/rewardIconFor(audience: kid)` once it lands on main. Verified in
this worktree: `grep -rn questIconFor app/lib/` returns **0 hits** — only the
unrelated single-argument `rewardIconFor(String key)` exists. The note's own
wording is "not a finding meanwhile", so no K04 change was made and no test was
written against a helper that does not exist. It should be picked up after the
next main merge.

## Bugs found

1. **K04-BUG-4 — OPEN, Minor.** `quest_detail_view.dart:577` — over-cap title is
   clipped instead of ellipsised (`TextOverflow.clip` is `NestBalancedText`'s
   default and the call passes no `overflow:`). Repro + failing proof in
   `6_bugs.md`; verified still failing above. Not patched, per the brief.
2. **Not a new bug, but verdict-relevant:** `5_ui.md` `VERDICT: FAIL` with an
   open Major on the hero tile glyph (`ic_quest_bed.svg` renders as a plain arch
   at the 64/120 px hero size). Root cause is shared-asset, not screen code;
   `core/**` is off-limits to a screen agent. Flagged so a green test stage is
   not read as sign-off.

VERDICT: FAIL
