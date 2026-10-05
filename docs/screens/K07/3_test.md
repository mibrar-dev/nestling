# K07 · 3 TEST (iteration 4) — the `/pip-evolution` suite

Job: write and extend the K07 tests in `app/test/features/pip/`, run the gates,
and record any real bug the tests expose. **No product code was changed by this
stage** — RULES §1 lets a test stage touch `app/test/features/pip/**` and
`docs/screens/K07/**` only, and `git status app/lib` is empty at the end of it.
No simulator was booted, installed on or driven: only `5_ui` may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`. No `flutter clean`, no
`analysis_options` change, no `google_fonts`, no `DateTime.now()` in any test,
no `pkill` of any kind.

Base for this stage: `2_build.md` (what iteration 4 landed), `6_bugs.md`
(iteration 3's hunt: **K07-BUG-6** major, **K07-BUG-7** minor),
`ORCHESTRATOR_NOTES.md` (no iteration-4 update; D1/D2/D3/D4 all stand and are
proven), and this stage's brief.

## Verdict summary

- **Tests added: 13**, in one new file. **Bugs found: none.**
- The feature's own 27 files: **+447, ZERO skips** (434 at the checkpoint `7c29857`
  + my 13). Every bug proof from iterations 1–3 is live and green, including the
  two iteration-4 fixes.
- Whole app: see **Gates** — the measurement excludes a concurrent stage's
  scratch probes, which are not mine (Observations 1).
- **What iteration 4's fixes changed, and what this stage adds:** both fixes are
  correct and proven, but the live proofs pin them at **one width each** (320 px
  for the cards) or against **computed** line counts (for the caps). The 13 new
  tests generalise both across the matrix this brief names, and pin the two
  properties a fix of that kind must not break — the cards must still **grow**
  with the text scale, and the caps must stay dropped on the **rendered**
  paragraphs, not just on a paper line count.

## Files

| file | state | tests |
|---|---|---|
| `pip_evolution_stats_scales_test.dart` | **new** — the stat row and the celebration copy at every width and every text scale | 13 |
| everything else in `test/features/pip/` | untouched | — |

## What the new file proves, and why

Iteration 4's build fixed two bugs with one line each, and both are in the
widgets this file exercises:

- **K07-BUG-6 (major)** — the three `.k7-stats` cards were *centred* against one
  another (`Row`'s default `CrossAxisAlignment.center`) while each card's
  `FittedBox(scaleDown)` shrank less when its content was narrower, so the row's
  top and bottom edges splayed: **2.40 px** at 320 px with the demo seed,
  **11.67 px** with a 9-digit coin total at 390. The fix is `IntrinsicHeight` +
  `CrossAxisAlignment.stretch` — the CSS default `align-items: stretch`, since
  `.k7-stats` has no `align-items`.
- **K07-BUG-7 (minor)** — the app-only `maxLines: 4` on the hero (whose default
  overflow is a **hard clip**) and `maxLines: 2` + ellipsis on the sub-line (which
  carries the count) were dropped; the design clamps neither.

### 1. The three stat cards are ONE height, everywhere (11 tests)

`.k7-stats`'s height is content-driven — the label wraps on a narrow cell and the
`FittedBox` scales the number+label pair down — so "one height" has to hold
everywhere, not just where the proof measured it:

| theme | widths × text scales |
|---|---|
| light | 320 / 390 / 430 × 1.0 / 1.3 / **2.0** (9) |
| dark | 320 @ 1.3, 430 @ 2.0 (2 spot-checks — the same layout code runs in both themes) |

Each case asserts the **spread** (max − min) of the three cards' heights, tops
and bottoms is ≤ **0.5 px**. That tolerance is the measurement's, not a design
allowance: the cards carry a 3 px ink border *and* a 6 px `--sh-kid` shadow, so a
2 px splay reads as three cards of different sizes, and the owner ALIGNMENT rule
calls any visible misalignment a UI failure. Each case also pins the row's other
half — the 20 px side gutters and the two 10 px gaps from
`EvolutionStatsGeometry.gap` — and that nothing threw (the
`IntrinsicHeight`-inside-a-`SingleChildScrollView` pairing is exactly the shape
that throws when one half of it is missing).

### 2. The cards **grow** with the text scale — they are not pinned (1 test)

The bug stage argued for `IntrinsicHeight` over a fixed card height, and gave the
reason: *"a fixed height would stop the cards growing at large text scales — the
opposite of what accessibility needs."* Nothing tested that reasoning, so a
future "simplification" to a pinned height would have passed every existing test
while reintroducing the truncation in a new place. This test measures one pumped
screen at 1×, then changes only the metrics to **2×** (Android's maximum font
scale) and measures again:

- every card is **strictly taller** at 2× (the content really needs more room), and
- the three are **still equal** (the stretch holds at the new size), and
- the value is still its full string (`175`), i.e. the row grew by wrapping and
  scaling down rather than by clipping the number away.

### 3. The app-only line clamps stay dropped, on the rendered paragraphs (1 test)

At **320 px / 2.0**:

- the hero's `maxLines` is `null` (the design's `.k7-hero` has no clamp; the copy
  test pins this too), and the **sub-line's** is `null` with `overflow` **not**
  `TextOverflow.ellipsis` — the sub's cap was the one that ellipsized away the
  count that explains *why* Pip grew, and unlike the hero's it had no unit-level
  pin at all;
- the **rendered** paragraphs report `didExceedMaxLines == false` for both lines.
  The live proof measures *computed* line counts against the cap values it reads
  off the widgets, which is a good regression guard but says nothing about what
  the framework actually laid out;
- the copy itself is untouched by the fix: `Because you helped 4 times` and
  `Pip grew into a Fledgling!` render whole, and the CTA is still there.

### The font caveat this file is built around

With the fallback test font all three stat labels measure the same width, so
**K07-BUG-6 is invisible**: the bug stage measured three cards of 54.08 px and
**0.00** drift with the fallback font at 320 px, against 76.88 / 77.05 / 81.68 and
**2.40** with real Nunito. A pass measured on the fallback font would be a lie,
so `FontLoader('Inter' + 'Nunito')` runs in this file's `setUp` and every test
here is a real-font test. (`FontLoader` mutates the engine's font collection for
the rest of the process, which is why `k07_bugs_test.dart` keeps its real-font
tests last in the file; here it is unconditional, so ordering is not load-bearing
— but no test in this file may rely on the fallback font.)

## Coverage against this stage's brief

| required | where it is pinned |
|---|---|
| bloc_test for every event/state path | `pip_evolution_bloc_test.dart` (29: every `PipState` helper, both stream-failure shapes, per-stream statuses, the sibling-slot carry, `toLoading(restarting*)` in both directions, the surviving-stream proof, retry, double-load guard, `close()`, `Seed.demo` end to end) |
| light + dark | every state in the view / widget / a11y / copy / sparks / stats-scales files |
| widths 320 / 390 / 430 | the fit matrix, the stage-slot tests, and the new stat-card matrix at all three widths |
| text scale 1.0 and 1.3 | the fit matrix + the a11y target check; the new file adds **2.0** on top, because that is where two iteration-3/4 defects lived |
| empty / loading / error states | `pip_evolution_view_test.dart` (gated loading, flaky failure, `Seed.empty`, nest-healthy/evolution-failing) and `pip_evolution_stream_contract_test.dart` (both streams failing, gated loading with a failed sibling, mid-session failure) |
| every tap navigates to the right route | CTA → `/pip`, lock → `/parental-gate` (pushed), *Try again* → a real, scoped reload, *Choose* → `/who-is-playing`; each through the **pointer** and through `performAction(SemanticsAction.tap)` |
| semantics labels on icon buttons | `pip_evolution_a11y_test.dart`: the lock speaks the design's `aria-label` `Grown-ups`, the whole semantics tree is swept, no informative node advertises a tap |
| tap targets ≥ 44 parent / ≥ 56 kid | `pip_evolution_a11y_test.dart` uses the **kid** bound (`NestDevice.tapKid` = 56) for lock / CTA / retry / choose, at 390 px and at 320 px with text scale 1.3 |
| in-memory Drift with `Seed.demo` / `Seed.empty` | `setUpTestScope` in every file; the no-child paths re-seed `Seed.empty` |

## Bugs found

**None.** The 13 new tests are green against the screen as `7c29857` left it, and
none of them exposed a defect in `app/lib/features/pip/**`. Nothing was patched.

### Iteration 3's findings, now closed and proven by live tests

| id | was | proof, now live |
|---|---|---|
| **K07-BUG-6** (major) | the three `.k7-stats` cards were different heights with splayed top and bottom edges whenever a cell was narrower than its content (2.40 px at 320 px, 11.67 px at 390 with a 9-digit total) | `k07_bugs_test.dart` → *K07-BUG-6* (real Nunito, 320 px, height/top/bottom spread ≤ 0.5) + this stage's **11-case matrix** and the growth test |
| **K07-BUG-7** (minor) | the app-only `maxLines: 4` (hard-clipped hero) and `maxLines: 2` + ellipsis (sub, which carries the count) truncated the celebration copy at accessibility text scales | `k07_bugs_test.dart` → *K07-BUG-7* (caps read off the shipped widgets, line counts over 7 scales × 3 widths) + `pip_evolution_copy_test.dart` (hero `maxLines` is `isNull`) + this stage's rendered-paragraph test |
| K07-BUG-1 … K07-BUG-5 | iterations 1–2's findings | still live and green (`+447`, zero skips) |

**2a's** five repository tests for the production status-**UPDATE** paths
(re-doing a quest, approving, declining, and the Equatable dedupe that keeps the
celebration still) are also live in that `+447` — they are the other half of what
"data-driven" means for this screen, and 2a added them unprompted.

### Still open, and why it is not a test-stage item

- **`5_ui`**: re-verify the dark sparkles (`5_ui.md` **D4**) and the stat-card
  band (expected unmoved at 390 px). Only that stage may boot a simulator.
- **`1_plan.md` §(a).3 / §(a).4 re-ratification (orchestrator)** — the plan still
  documents the dropped `maxLines: 4` / `maxLines: 2` caps and reads
  `Row(spacing: 10)` where the shipped tree is
  `IntrinsicHeight > Row(spacing: 10, stretch: true)`. Documentation only; the
  tests now pin the shipped behaviour, so nothing is blocked.
- **`evolutionSub(0)`** — "Because you helped 0 times" needs a wording ruling
  (`SHARED_REQUEST.md` item 5). My iteration-3 test makes the case reproducible
  from the database; no copy is invented here.
- **`SHARED_REQUEST.md`** items 1–5: the K07 background deviation (no
  `KidScope`, no `.meadow`), the screen-scoped load event, the no-entry-point
  note, the `shot.sh` pre-first-frame save, and the off-token `#3D7FF0` sky dot.
- **No in-app entry point for `/pip-evolution`** — a K06/flow-owner decision.

## Observations (documented, not findings)

1. **A concurrent stage's scratch probes are in the feature directory again, and
   this time they were being rewritten under me.** `zz_probe_iter4_k07_test.dart`
   (02:21) and `zz_probe_iter4_b_k07_test.dart` (02:23) appeared during this
   stage's runs and were deleted again within minutes;
   `zz_probe2_iter4_k07_test.dart` (02:27) replaced them. None of the three is
   mine — none references this stage's tests — and three of the first file's
   probes (*probe A: caption + sub + hero caps at scale x width*, *probe B: card
   rects + number offsets at 390/1.0*, *probe C: big text scale layout safety*)
   fail as it stands. Every measurement below excludes `zz_probe*`.
2. **The `libsqlite3.dylib` native-asset race, third iteration running.** This
   time I ran a single `flutter test` process, alone — the concurrent stage in
   this worktree rebuilt `build/native_assets` while my suite was loading it, and
   `pip_shared_component_fidelity_test.dart` died with
   `Couldn't resolve native function 'sqlite3_initialize' … no such file`. The same
   file passes in the clean 27-file run (+447). It is an environmental race, not a
   test result, and it keeps costing gate runs — worth a line in the loop's own
   notes about not sharing a worktree with a live stage for `flutter` runs.
3. **`6_bugs.md` observation 3** (`pip_buy_result_test.dart` stalling when the
   whole feature directory runs at once) **did not reproduce** for the second
   time: the directory completed in 24 s both times. Recorded as unreproduced,
   not fixed — nobody changed it.
4. **Carried forward — zsh does not word-split unquoted expansions.**
   `flutter test $FILES` passes 26 files as one path and dies with
   `Failed to load … Does not exist`. Use `ls … | xargs flutter test …`.
5. **Carried forward — the device-inset detail.** The bar's `SafeArea` only sees
   the 34 px home reserve on a real device and `NestHomeIndicator` shrinks outside
   the gallery, so a test that does not fake `view.padding` measures the no-CTA
   bar as 16 px instead of 50. This file fakes the insets (47 / 34) like
   `pip_evolution_widget_test.dart` does.

## Gates

No simulator; `--timeout 120s` on every run.

```
# 1. The feature's own 27 files (a concurrent stage's probes excluded)
$ ls test/features/pip/*.dart | grep -v zz_probe | \
      xargs flutter test --timeout 120s --reporter compact
00:24 +447: All tests passed!           # zero skips

$ flutter test --timeout 120s test/features/pip/pip_evolution_stats_scales_test.dart
00:01 +13: All tests passed!

# 2. The whole app (244 files, probes excluded)
$ find test -name "*_test.dart" | grep -v zz_probe | sort | \
      xargs flutter test --timeout 120s --reporter compact
03:42 +4501 ~10 -1: Some tests failed.

#    The ONE failure is the native-asset race again, not a test result:
#    test/features/privacy_consent/privacy_consent_artwork_test.dart (P04, another
#    feature) died with Couldn't resolve native function 'sqlite3_initialize' …
#    libsqlite3.dylib: no such file. Re-run alone, immediately after:
$ flutter test --timeout 120s test/features/privacy_consent/privacy_consent_artwork_test.dart
00:02 +11: All tests passed!

# 3. Analyze / format for the file this stage added
$ flutter analyze test/features/pip/pip_evolution_stats_scales_test.dart
Analyzing pip_evolution_stats_scales_test.dart...
No issues found! (ran in 2.0s)

$ dart format --output=none --set-exit-if-changed \
      test/features/pip/pip_evolution_stats_scales_test.dart
Formatted 1 file (0 changed)
```

VERDICT: PASS