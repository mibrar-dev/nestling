# K07 · 3 TEST (iteration 2) — the `/pip-evolution` suite

Job: write and extend the K07 tests in `app/test/features/pip/`, run the gates,
and record any real bug the tests expose. **No product code was changed by this
stage** — RULES §1 lets a test stage touch `app/test/features/pip/**` and
`docs/screens/K07/**` only. No simulator was booted, installed on or driven:
only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`. No
`flutter clean`, no `analysis_options` change, no `google_fonts`, no
`DateTime.now()` in any test.

Base for this stage: `2_build.md` (what iteration 2 landed), `2a_build_logic.md`
CONTRACT CHANGES §1–§2 (the per-stream state contract and the
`questsFinished` split), `2b_build_ui.md` (the deleted sibling branch, the bar
rule, the slot `FittedBox`, the sparkle parser), `6_bugs.md` / `4_review.md`'s
open items, and this stage's brief.

## Verdict summary

- **Tests added: 14**, in one new file. **Bugs found: none.**
- `test/features/pip` → **+406, ZERO skips**: iteration 1's parked proofs are
  all live now (K07-BUG-1, -2, -3, -4/SPARK), as the loop's contract requires of
  a fix commit, and they are green.
- Whole app → `+4461 ~10: All tests passed!` The 10 skips are other screens'
  (`k01_bugs` 1, `k03_bugs` 2, `k09_bugs` 6, `p12_bugs` 1) — **none is K07's**.
- One caveat, in **Gates**: another stage dropped a scratch probe
  (`zz_probe_k07_test.dart`, not mine) into `test/features/pip/` at 22:46, and
  it alone makes `flutter analyze` and `dart format` red for the tree right now.
- **Iteration 1's majors are fixed and now proven by live tests**
  (`K07-BUG-1`: no false failure card; `K07-BUG-4`/`SPARK-1`: the sparkle's `M`
  vertex is painted). What is still open is `5_ui` re-measuring the sparkle
  band, and three orchestrator items — none of them a test-stage item.

## Files

| file | state | tests |
|---|---|---|
| `pip_evolution_stream_contract_test.dart` | **new** | 14 |
| everything else in `test/features/pip/` | untouched | — |

`git status app/lib` is empty: the screen, the bloc and the repository are
exactly as `2_build.md` left them.

## What the new file proves, and why

Iteration 2 changed three things that the suite, as it stood, could not have
caught a regression in. Each is a behaviour change with no test behind it.

### 1. The VIEW side of the per-stream contract — a NEST failure on K07 (3 tests)

`2a` gave each load stream its own arrival flag and its own error slot, and `2b`
deleted the sibling branch from the view (`if (nest != null) return
_EvolutionFailure(...)`), so `/pip-evolution` now switches on
`state.evolutionStatus` alone. The state contract is pinned in
`pip_evolution_bloc_test.dart`; **the widget side of the mirror was not pinned
anywhere** — the suite had "the nest healthy, K07 failing → the failure card",
never the other way round, which is both the direction the deleted branch broke
and the direction the real streams take (`watchEvolution()`'s first emission
needs real Drift I/O, so a sibling failure lands *first*).

- `light` + `dark`: **a NEST failure cannot take down the celebration** — with
  `watchNest()` erroring and `watchEvolution()` real, the screen renders the
  title, the stats and the CTA; never `Oh no! Pip got lost.`, never
  `Who's playing?`, never the spinner; the route is unchanged; and no raw
  stream text (`nest down`, `Exception`) appears in any `Text` on screen.
- **A NEST failure while this screen is still loading shows the SPINNER, then
  the celebration**: the sibling errors immediately and K07's stream is gated
  silent → the spinner, no failure card, no picker, and **no `k07-retry`** (the
  honest half of K07-BUG-1's proof: a pending screen offers no recovery control
  because there is nothing to retry). Releasing the gate with the evolution the
  real repository would have delivered brings up `Pip grew into a Fledgling!`
  and `Meet Fledgling Pip`.
- The direction check, so the above cannot be satisfied by "the screen never
  fails": with **both** streams failing the card and its retry do appear —
  because `evolutionStatus` is `failure`, not because the nest failed.

### 2. The design's ink rule belongs to the design's button (6 tests)

`4_review.md` finding 5: the `.kid-bar` 3 px ink rule is now built only when
there is a CTA (`border: stage == null ? null : …`). Nothing asserted it, so
unifying the bar again would have gone unnoticed. Each case asserts the rule,
the bar's painted **height**, its surface token and the owner BOTTOM EDGE rule:

| state | rule | height | surface to the physical edge |
|---|---|---|---|
| celebration (light + dark) | `border.top` = `nestKid.borderWidth` (read from the theme, not a literal) | 123 = 3 + 12 + 64 + 6 + 4 + 34 | yes |
| loading | `border == null` | 50 = 12 + 4 + 34 | yes |
| failure (light + dark) | `border == null` | 50 | yes |
| no child (`Seed.empty`) | `border == null` | 50 | yes |

The 50 px band is the measured consequence of the fix (a rule and an empty
button row over nothing read as a broken button); the surface box itself is
untouched, so the bottom-edge rule still holds on all four — asserted by
`decoration.color == tokens.surface` plus `bar.left == 0`, `bar.right == 390`,
`bar.bottom == 844`.

### 3. The stage slot keeps its design geometry above 350 px (2 tests)

`K07-BUG-2`'s fix wraps the slot's three fixed-size pieces in
`FittedBox(scaleDown, bottomRight)` **only** when the content box is narrower
than `EvolutionStageGeometry.designSlotWidth` (350). The parked-now-live proof
covers 390 and 320; **430 — the third width this brief names — was never
checked**, so a threshold keyed on "not 390", or on the screen width instead of
the slot's, would have passed everything.

- **at 430**: nothing is downscaled. The grown Pip is 240×240 still anchored
  6 px from the slot's right edge, the arrow 30 at `left: 76`, the old Pip 68 at
  `left: 2`, and the design's own 2 px arrow tuck survives.
- **at 320**: the three pieces downscale **as one** — the arrow and the old Pip
  share the grown Pip's scale factor (within 0.01), the factor is < 1, and
  `bottomRight` alignment keeps the grown Pip's 6 px inset (scaled). Legibility
  itself stays `k07_bugs_test.dart`'s job; this pins the mechanism it relies on.

### 4. Two pure edges (2 tests)

- **`questsFinished: 0` is a count, not a missing value.** `int?` with `??`:
  a distinct-quest count of zero must stay zero, or a card that is about quests
  would fall back to the row count. (Unreachable in the demo — 0 distinct means
  0 rows — so only a unit test can reach it.) Two entities differing only in the
  distinct count are also asserted to be *different* states, so the card
  repaints.
- **An action outcome carries both arrival flags and both error slots.** K06's
  care / wardrobe taps write to this same `PipState`. If either
  `withActionStarted` or `withActionFailed` dropped a flag, a toast could
  re-arm a stream (`nestSettled: false` on a loaded screen → `/pip`'s spinner
  again); if it dropped a slot, it could clear a failure and make the retry
  card disappear. Both are asserted after each transition.

## Coverage against this stage's brief

| required | where it is pinned |
|---|---|
| bloc_test for every event/state path | `pip_evolution_bloc_test.dart` (26: every `PipState` helper, per-stream statuses, both stream-failure shapes, the sibling-slot carry, `toLoading` re-arm, retry, double-load guard, `close()`, `Seed.demo` end to end) — 2a's layer, re-verified here |
| light + dark | every state in `pip_evolution_view_test.dart`, `pip_evolution_widget_test.dart`, `pip_evolution_a11y_test.dart`, `pip_evolution_copy_test.dart`, and the new file's bar + nest-failure groups |
| widths 320 / 390 / 430 | `pip_evolution_widget_test.dart` fit matrix (12 combinations) + the new file's slot tests at 430 and 320 |
| text scale 1.0 and 1.3 | the fit matrix, plus the a11y file's 320 px / 1.3 target check |
| empty / loading / error states | `pip_evolution_view_test.dart` (loading with a gated repository, flaky failure, `Seed.empty`, nest-healthy/evolution-failing) + the new file (both streams failing, gated loading, `Seed.empty` bar) |
| every tap navigates to the right route | CTA → `/pip`, lock → `/parental-gate` (pushed), *Try again* → a real reload, *Choose* → `/who-is-playing`; each through the **pointer** and through `performAction(SemanticsAction.tap)` |
| semantics labels on icon buttons | `pip_evolution_a11y_test.dart`: the lock speaks the design's `aria-label` `Grown-ups`, the whole semantics tree is swept, no informative node advertises a tap |
| tap targets ≥ 44 parent / ≥ 56 kid | `pip_evolution_a11y_test.dart` uses the **kid** bound (`NestDevice.tapKid` = 56) for lock / CTA / retry / choose, at 390 px and at 320 px with text scale 1.3 |
| in-memory Drift with `Seed.demo` / `Seed.empty` | `setUpTestScope` in every file; the no-child paths re-seed `Seed.empty` |

## Bugs found

**None.** The 14 new tests are green against the screen as `2_build.md` left it,
and none of them exposed a defect in `app/lib/features/pip/**`. Nothing was
patched, as a test stage must not.

### The iteration-1 findings, now closed and proven by live tests

Re-running the whole feature directory is the evidence: **+406 with zero skips**
means every proof that iteration 1 parked now runs and passes — the loop's rule
that a fix commit un-skips its own proofs.

| id | was | proof, now live |
|---|---|---|
| **K07-BUG-1** (major) | a pending evolution stream rendered `Oh no! Pip got lost.` with a dead *Try again*, 5/5 cold opens | `pip_evolution_bloc_test.dart` + `k07_bugs_test.dart` (state level, real repository, 5 cold opens; widget level: spinner instead of the card, and **no retry** while pending) — plus the new file's nest-failure cases, the direction the deleted sibling branch broke |
| **K07-BUG-4** = `K07-BUG-SPARK-1` (major, mandatory via `ORCHESTRATOR_NOTES` D2) | every sparkle lost its `M` tip vertex: `moveTo` + `addPolygon` drops the moveTo, so the 4-point sparkle painted as a flat-topped 7-gon | `k07_sparkles_bug_test.dart` — three proofs live: Flutter's `Path.addPolygon` semantics (the trap), the design's polygon with its tip rasterised from the HTML, and the silhouette's symmetry about the design's axis |
| **K07-BUG-3** (minor) | `quests done` counted completion ROWS, so one re-completable daily quest inflated a milestone about quests | `k07_bugs_test.dart` widget + repository halves: the card reads `4` (distinct quests) while the sub-line honestly reads `Because you helped 5 times` |
| **K07-BUG-2** (minor) | at 320 px the grown 240 px Pip covered the arrow and the "before" silhouette | `k07_bugs_test.dart` at 390 and 320, plus the new file's 430 px and "one piece" tests |

### Still open, and why it is not a test-stage item

- **`5_ui` must re-measure the sparkle band** (design `y 407..528` in PNG px =
  CSS 136..176; the app was `449..528`). Only the UI stage may boot simulator
  `BC440E48-B3A3-43BC-971B-0EF5DB621874`. The in-test rasterisation already
  proves the painter's own art-space band matches the HTML exactly, so what
  remains is the composited screen band.
- **`4_review.md` finding 9** — the orchestrator still owes a ruling on the
  dark-mode sparkle accents (the design's inline SVG hard-codes `#7C6CF2` /
  `#1F9D63` / `#FF8A5B`; "tokens only" wins, so the token re-theme stands and
  `pip_evolution_sparks_test.dart` pins that deviation in both directions).
- **`SHARED_REQUEST.md`** — item 1 (record the K07 background deviation: no
  `KidScope`, no `.meadow`, a lilac glow + the shared dark stars) and item 2 (a
  screen-scoped load event so K07 stops opening K06's stream) are orchestrator
  notes. `4_review.md` finding 4 is the same request, accepted as-is.
- **`4_review.md` finding 12's UI half is measured; its stage is 5_ui's.**

## Observations (documented, not findings)

1. **Another stage's scratch probe makes the tree's analyze/format red right
   now.** `app/test/features/pip/zz_probe_k07_test.dart` appeared at 22:46,
   inside this stage's run, and is 15.8 KB of in-flight work (8 diagnostics:
   4 missing `await`, 2 double-quoted strings, 1 unsorted directive, 1 missing
   final newline; `dart format` wants to reformat it). It is **not** mine — I
   created, edited and deleted nothing outside the two files above, and it
   contains no reference to this stage's tests. Every other file in the repo is
   clean:
   ```
   $ flutter analyze | grep '•' | grep -v zz_probe_k07_test | wc -l
   0
   $ dart format --output=none --show=changed .
   Changed test/features/pip/zz_probe_k07_test.dart
   ```
   Whoever wrote it should delete it when done (iteration 1's
   `zz_scratch_sparks_probe_test.dart` went the same way). **This is not a K07
   defect**, but the next gate will be red until the file goes.
2. **The two failures in my first whole-app run were environmental, not
   logical.** `k09_bugs_test.dart` → *K09-BUG-4* and
   `settings_repository_test.dart` → *watchRoster lists Maya then Leo* failed
   with `Couldn't resolve native function 'sqlite3_initialize' … Failed to load
   dynamic library …/app/build/native_assets/macos/libsqlite3.dylib (no such
   file)` — the sqlite3 native asset missing from `build/` because another
   process was compiling in the same worktree at the time (I had `flutter
   analyze` running alongside). The identical tree, run on its own, is green:
   `+4461 ~10: All tests passed!` Both are other features' tests and neither is
   a K07 finding.
3. **A device-inset detail that silently changes every bar measurement.** The bar's
   `SafeArea` only sees the 34 px home reserve on a real device, and
   `NestHomeIndicator` renders `SizedBox.shrink()` outside the gallery, so a test
   that does not fake `view.padding` measures the no-CTA bar as **16 px** instead
   of 50 (12 + 4, no home reserve) and the celebration bar as 89 instead of 123.
   `pip_evolution_widget_test.dart` fakes the insets for this reason and says
   so; the new file does the same, with the measurement recorded in a comment so
   the next author does not have to rediscover it.
4. **`pip_evolution_data_test.dart` (iteration 1's file) needed no change** after
   `questsFinished` split the card from the sub-line — by design: its rows
   belong to quests the child has never completed, so rows and distinct quests
   agree and both sentences stay asserted at `4` and at `1`. It is now also
   incidental proof that the demo seed still reads `4` on the card after the
   split.
5. **Carried forward (both pinned in the suite, not just noted):** the design's
   inline `#3D7FF0` sparkle dot is not a token (`tokens.css` defines
   `--sky: #2563D6`), so the screen paints `tokens.sky`; and every shared
   control (`NestKidButton`, `NestLockButton`) exposes an extra **unlabelled**
   tap node inside its labelled parent — a design-system characteristic measured
   identically on `/pip` and `/today`, which is why `tappableLabels` counts
   button-flagged nodes only.

## Gates

No simulator; `--timeout 120s` on every run. **Read the last block first**: the
tree's `flutter analyze` / `dart format` are red, entirely inside another
stage's scratch file.

```
# 1. The feature's own directory — zero skips, every proof live
$ flutter analyze
$ dart format --output=none --set-exit-if-changed .

$ flutter test --timeout 120s test/features/pip
00:13 +406: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_stream_contract_test.dart
00:02 +14: All tests passed!

# 2. The whole app, every feature
$ flutter test --timeout 120s
02:33 +4461 ~10: All tests passed!     # 10 skips: k01(1) k03(2) k09(6) p12(1) — none K07's

# 3. LATER, after another stage dropped its probe into test/features/pip/
$ flutter analyze
… 8 diagnostics, all in test/features/pip/zz_probe_k07_test.dart …
8 issues found.

$ flutter analyze | grep '•' | grep -v zz_probe_k07_test | wc -l
0
```

`flutter analyze` over the two files this stage owns is **No issues found!**, and
`dart format --output=none --set-exit-if-changed .` reports them unchanged.

VERDICT: PASS