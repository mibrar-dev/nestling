# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 4)

Adversarial pass over K07 **as it stands after the iteration-4 build `7c29857`**
(which landed K07-BUG-6 and K07-BUG-7). **This stage changed no product code** —
RULES §1 lets a bug hunt add only `app/test/features/pip/**` and
`docs/screens/K07/**`, and `git status --porcelain app/lib` is empty at the end
of it. No simulator was booted, installed on or driven: only `5_ui` may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`. No `flutter clean`, no `analysis_options`
change, no skipped gate, no `google_fonts`, no `DateTime.now()`, no `pkill`.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **2 skipped failing
proofs** (K07-BUG-8, the new major; K07-BUG-9, the new minor) on top of the 30
tests that pass: iteration 1's four proofs and iteration 2's K07-BUG-5, plus
iteration 3's controls, plus **2 new controls** from this pass.

## Verdict summary

| # | Severity | Status | Summary | Proof |
|---|---|---|---|---|
| **K07-BUG-8** | **MAJOR** | **OPEN** | Each `.k7-stats` card wraps its own number+label pair in its own `FittedBox(fit: scaleDown)`, so the **three numbers in one row are painted at three different type sizes** and their **top edges drift**. At the design width 390 px with the app's own **maximum** supported text scale (1.3) the tops are 651.13 / 651.02 / **647.97** — a **3.16 px** splay, and the painted heights 39.37 / 39.51 / **43.40** (a 10.2 % spread). At 320 px with **no** text scaling at all it is **2.40 px**. The design sets ONE `font-size` for all three `<b>` and all three `<span>`. | `k07_bugs_test.dart` → `K07-BUG-8: the three .k7-stats cards paint their number…` (real Nunito, 390 px @ 1.3 and 320 px @ 1.0) |
| **K07-BUG-9** | minor | **OPEN** | The app-only `maxLines: 3` + ellipsis survives on the caption — the same clamp K07-BUG-7 removed from the hero and the sub. `.kcap` sets no clamp in the design. | `k07_bugs_test.dart` → `K07-BUG-9: the app-only maxLines: 3 + ellipsis survives…` |
| K07-BUG-5 | ~~MAJOR~~ | FIXED, re-verified | The dark-mode sparkle palette (`ORCHESTRATOR_NOTES` 23:55, D4). | green |
| K07-BUG-1 … 4, 6, 7 | — | FIXED, re-verified | Iterations 1–3's six findings. | all green |
| *new this pass* | — | **CORRECTION** | `4_review.md` finding 2 is **overstated** and `6_bugs.md` iteration 3's K07-BUG-7 reachability table is **wrong**: the app shell clamps the OS text scaler to **1.0–1.3**, so none of the scales either note leans on (Android's 2.0× max, iOS 3.16×) can ever be rendered. | `control: the app clamps the OS text scaler to 1.0–1.3…` |

**This pass: one major bug, K07-BUG-8, plus one minor (K07-BUG-9).** Both are
confined to `features/pip/presentation/**`, so both are RULES §1-legal for this
branch.

Everything else in the brief's hunt matrix is clean. Two of this pass's
observations overlap `4_review.md` findings 1 and 2 — those are **not**
re-reported here as new bugs; see "Carried from stage 4" for exactly how this
pass's numbers relate to theirs.

---

## K07-BUG-8 — MAJOR — the three stat numbers are painted at three different type sizes

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`
— `_StatCell`'s `FittedBox(fit: BoxFit.scaleDown)` at `:164`, inside the
iteration-4 `IntrinsicHeight` + `CrossAxisAlignment.stretch` row at `:88-91`.

The design:

```css
.k7-stats { display: flex; gap: 10px; }                          /* line 27 */
.k7-stats > div { flex: 1; min-width: 0; … padding: 12px 6px; }  /* line 28 */
.k7-stats b     { font-size: 30px; line-height: 34px; }          /* line 29 */
.k7-stats span  { font-size: 14px; line-height: 18px; }          /* line 30 */
```

There is no `transform`, no `zoom` and no `font-size` override per item: **all
three `<b>` are 30 px and all three `<span>` are 14 px, at every width and at
every text scale.** A browser that runs out of room makes the text *wrap*; it
never makes one item smaller than its siblings.

The app gives **each cell its own `FittedBox`**. `BoxFit.scaleDown` shrinks a
cell's content by *that cell's own* factor, and the three cells' contents have
different intrinsic widths — the numbers are `4` / `120` / `3` and the labels are
`quests done` / `coins grown` / `of 4 stages`. So the narrower cells shrink less
and the three numbers come out at three different sizes.

### Evidence — real bundled Nunito, real app shell, shipped demo seed

Measured with `pumpAppRoute` (so `_clampTextScaler` is in play, i.e. what the
device runs) on the **painted** rects — `tester.getRect` on each card's `RichText`,
which applies the whole transform chain, so these are the sizes the eye reads.
Font pattern: `FontLoader('Nunito')` with `assets/fonts/Nunito-Bold.ttf` /
`Nunito-Black.ttf`, the pattern `test/core/design_system/nest_pet_stage_test.dart:154`
established.

| width | OS text scale | painted number height | number top | drift |
|---|---|---|---|---|
| **430** | 1.0 / 1.1 / 1.15 / 1.3 | 34.00 / 37.00 / 39.00 / 44.00 ×3 | identical | **0.00** ✓ |
| **390** (design) | **1.0** | **34.00 / 34.00 / 34.00** | 594.00 ×3 | **0.00** ✓ |
| **390** | **1.3** | **39.37 / 39.51 / 43.40** | 651.13 / 651.02 / **647.97** | **3.16** ✗ |
| 375 | 1.15 | 37.30 / 37.44 / 39.00 | — | 1.35 |
| 375 | 1.3 | 37.23 / 37.37 / 41.04 | — | 2.99 ✗ |
| 360 | 1.1 | 34.87 / 35.00 / 37.00 | — | 1.70 |
| 360 | 1.15 | 35.16 / 35.29 / 38.76 | — | 2.86 ✗ |
| 344 | 1.0 | 32.95 / 33.08 / 34.00 | — | 0.83 |
| 344 | 1.1 | 32.60 / 32.72 / 35.94 | — | 2.66 ✗ |
| **320** | **1.0** | **29.52 / 29.63 / 32.54** | 606.56 / 606.47 / **604.16** | **2.40** ✗ |
| 320 | 1.3 | 29.38 / 29.49 / 32.39 | — | 2.36 ✗ |
| 280 | 1.0 | 23.78 / 23.87 / 26.22 | — | 1.93 |
| 280 | 1.3 | 23.68 / 23.76 / 26.10 | — | 1.90 |

The labels drift the same way — at 390 px / 1.3 they are 20.58 / 20.65 /
**22.69** px tall against the design's single 14 px.

### Why 1.3 is not an exotic setting

`app/lib/app/app.dart:17-20`:

```dart
MediaQueryData _clampTextScaler(BuildContext context, MediaQueryData data) {
  final scaler = data.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.3);
  return data.copyWith(textScaler: scaler);
}
```

The shell pins every screen to **1.0–1.3** — the range "the design system
supports" (SPACING_SPEC §10). So **1.3 is the app's own maximum supported size**,
and the top of that range is where the bug is worst. Verified live: asking the
OS for 3.0, `MediaQuery.textScalerOf(context).scale(100) / 100` is **1.3**
(pinned by `control: the app clamps the OS text scaler to 1.0–1.3…`).

And the second case needs no accessibility setting at all: **320 px at scale
1.0**, the width `docs/design/SPACING_SPEC.md:369` plans layouts for and the
width this stage's own brief names.

### Third trigger — a large coin total, at the design width, at scale 1.0

Same mechanism, different axis. `pip_total_coins` has no CHECK constraint, and
the card's width does not change with the value, so a wide value alone shrinks
card 2 only:

| `pip_total_coins` | painted number height @390 / 1.0 |
|---|---|
| 120 (demo) … 12345 | 34.00 / 34.00 / 34.00 |
| **999 999 999** | 34.00 / **19.31** / 34.00 |

A 43 % size difference between the middle card's number and its two neighbours,
on the design's own width, at the default text size.

**Repro (deterministic, ~5 s, no simulator)**

```
cd app && flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_bugs_test.dart
```

**Failing test** — `K07-BUG-8: the three .k7-stats cards paint their number and
their label at THREE DIFFERENT type sizes inside one row…`

```
Expected: a value less than or equal to <2.0>
  Actual: <3.1619291693054947>
```

(the number tops' drift at 390 px / 1.3; the second, height-drift assertion and
the 320 px / 1.0 case fail on the same defect.)

**Impact.** The celebration screen's three headline numbers sit in one row and
read as three different type sizes. This is the element the whole screen exists
to show. It is an owner **ALIGNMENT**-rule failure ("cards and bars aligned to
the same edges, nothing a few px off. Treat visible misalignment as a UI
failure") and a **UI VERDICT**-rule failure (3.16 px against a ±2 px tolerance,
at the design width). No data, state, a11y or copy impact.

It survived three iterations because the defect only exists once the `FittedBox`
actually has to scale, which `5_ui` never does: at 390 px / 1.0 all three cards
fit at scale 1.000, so the painted heights are 34.00 × 3 and nothing is visible.

**Suggested fix** — `pip_evolution_stats.dart` only, one of:

1. **Drop the per-cell `FittedBox` and let the label wrap, as CSS does.** The
   number keeps `maxLines: 1`, so all three numbers are the design's single
   30 px, and the labels wrap inside the cell. This is the *closest* match to
   the CSS — the browser never scales type, it wraps. The cost is that a very
   wide value (9 digits) would then clip inside the card instead of shrinking,
   which is a separate decision worth taking deliberately.
2. **Scale the row once, not each cell** — one `FittedBox` around the whole
   `Row`, so a single factor applies to all three. Cheaper than (1) and keeps
   shrink-to-fit, but it shrinks the cards' *boxes* too, so the design's
   `flex: 1` geometry (110 px wide, at x 20 / 140 / 260) holds only while
   nothing needs shrinking.
3. Compute one scale factor from the row and pass it down to the three cells,
   keeping the per-cell boxes. More code than (2) for the same visual result.

Options 2 and 3 scale the card *geometry* as well as its type; the design's
cards keep `flex: 1` and only the text reflows, so option 1 is the only one of
the three that is exactly CSS-faithful at every width.

If `4_review.md` finding 1's `alignment: Alignment.topCenter` lands first, it is
necessary but **not sufficient**: it fixes the numbers' *inset* (all three then
sit 15.00 px below their card top, as CSS says) while the numbers stay three
different sizes. That is why finding 1 measured its 2.40 px at 320 px only,
where the two defects happen to coincide — at 390 px the insets are already
equal (15.00 × 3) while the painted sizes are still 39.37 / 39.51 / 43.40, so
`topCenter` alone leaves the screen visibly wrong **at the design width**. Both
fixes are needed, and this pass's `K07-BUG-8` proof asserts the number **tops
and sizes** rather than the card tops, exactly as `4_review.md` finding 1 asked
for.

**Fix verified where it was cheap, then reverted.** With only K07-BUG-9's fix
applied (see below), `--run-skipped` reports `+33 -1`: K07-BUG-9 goes green,
K07-BUG-8 still fails, both controls still pass, and `test/features/pip` moves
nowhere (`+449 ~2`). A scratch attempt at option 2 above was abandoned after it
produced 26 failures — nesting a `FittedBox` around a row that already contains
three of them collapses the cards' geometry, which is precisely the regression
`5_ui`'s 110 px / x 20-140-260 measurement would catch. **K07-BUG-8's fix is
not verified here and the build stage should treat the options above as
directions, not as patches.**

**Not fixed, per the brief.** This stage only proves the bugs.

---

## K07-BUG-9 — minor — the app-only caption clamp survives K07-BUG-7's fix

**Where** `app/lib/features/pip/presentation/views/pip_evolution_view.dart:380-387`
— `Text(evolutionCaption(), …, maxLines: 3, overflow: TextOverflow.ellipsis)`.

`1_plan.md` §(a).3's `maxLines: 4` (hero) and §(a).4's `maxLines: 2` (sub) were
dropped by the iteration-4 build because the design clamps neither
(`K07-evolution.html:24-25`). The caption is the same class and was left behind:
`.kcap` (`K07-evolution.html:14`) sets only a font/weight/size/line-height/colour,
and `.scroll` scrolls, so the browser simply grows the line.

`NestBalancedText.lineCountFor` (the component's own `@visibleForTesting` probe,
which is exactly what its `build` uses) with real Nunito:

| text scale | 390 | 360 | 320 | 280 |
|---|---|---|---|---|
| 1.3 (the app's max) | 1 | 1 | 1 | 2 |
| 2.0 | 2 | 2 | 2 | 3 |
| 3.0 | 2 | 2 | 3 | **4** ✗ |

and the real rendered paragraph confirms it: at 280 px / scale 3.0 a `Text` with
the design's own `kidCaption` style and `maxLines: 3` reports
`didExceedMaxLines == true`.

**Severity is minor, and honestly bounded: it is not reachable today.**
`_clampTextScaler` caps the app at 1.3, where the caption needs 1–2 lines. This
is the same conclusion `4_review.md` finding 2 reached. What this pass adds is
the *permanent* proof, so the fourth cap cannot be re-added silently and so the
"no cap in the design" argument is pinned rather than argued.

**Failing test** — `K07-BUG-9: the app-only maxLines: 3 + ellipsis survives on the
caption…` reads the cap **off the shipped widget** (so dropping it is what turns
it green) and measures the design's own line count beside it.

**Suggested fix** — `pip_evolution_view.dart` only: drop `maxLines: 3` and
`overflow: TextOverflow.ellipsis`. Then correct the comment at `:338-347`, which
justifies the two removed caps with "iOS reaches 3.16×" — a scale `app.dart`
clamps away — so nobody "restores" a cap later.

**Knock-ons checked.** No other test pins the caption's cap:
`pip_evolution_copy_test.dart:353` only asserts the caption is *not* a
`NestBalancedText` (the orchestrator's balanced-heading rule), which is
orthogonal; `k07_bugs_test.dart:1611` and the `280x360` matrix assert
`didExceedMaxLines == false`, which stays true at 1.3 with the cap gone. So the
fix is confined to the view plus this proof — unlike the hero and the sub, whose
`maxLines: 4` *was* pinned by `pip_evolution_copy_test.dart:334` and had to move
with them.

---

## CORRECTION — the accessibility-scale premise behind K07-BUG-7 is unreachable

This pass measured, live, that `app.dart`'s `_clampTextScaler` caps every screen
at **1.3×**. Two documents in this folder lean on scales the app cannot render,
and the next stage should not inherit them:

- **`4_review.md` finding 2** says the surviving caption cap is "pure noise
  rather than a live defect" because "asking for `textScaleFactorTestValue =
  3.16` produces the same caption height as 1.3×". Correct, and this pass
  confirms it from the other direction: at OS 3.0 the app sees **exactly 1.3**.
- **This file, iteration 3, K07-BUG-7**, justified a *minor* severity on the
  basis that "Android's 2.0× maximum truncates a 6-digit count at 320 px" and
  "iOS reaches 3.16×". Neither is reachable. The severity was in the right
  place anyway (the hero's `TextOverflow.clip` really is a hard cut, and the
  design really clamps neither line), but the *evidence* should be restated as:
  **the caps were app-only, and app-only is the defect** — which is exactly the
  framing the iteration-4 build used, and the right one.

The corollary is the one that matters for iteration 5: **do not go looking for
2×–3.2× artefacts on this screen.** The whole reachable envelope is 1.0–1.3, and
this pass swept it.

---

## The brief's hunt matrix — what this pass measured

| item | result | pinned by |
|---|---|---|
| **0 children / no active child** | Unchanged and clean: "Who's playing?" + `Choose`. | iteration 2's control |
| **1 / 6 children, deleted sibling** | Unchanged and clean. | iteration 2's control |
| **long UK names ("Maximilian-Alexander")** | The nickname is only ever in the a11y label, never painted — no rect to overflow. | iteration 2's control |
| **9999 coins / 0 / 999 999 999** | The large values feed **K07-BUG-8** — at 999 999 999 the middle card's number paints at 19.31 px against its siblings' 34.00, on the design width at scale 1.0. No overflow, no elision. | this pass (probe) + K07-BUG-8 |
| **empty lists / 0 and 1 completions** | Unchanged; the singular branch is intact. | iteration 2's control |
| **`pip_stage` out of range** | Unchanged; 0 / 5 / 99 clamp into 1..4. | iteration 2's control |
| **count isolation** (`to_do` / `not_yet` / `denied` / another child) | Unchanged and clean. | iteration 3's control |
| **repeated quest completion** | K07-BUG-3, fixed; both proofs green. | K07-BUG-3 ×2 |
| **rapid double taps** | Unchanged and clean, CTA / lock / retry / Choose. | iteration 2's controls |
| **back navigation / deep link to `/pip-evolution`** | Unchanged and clean. | iteration 2's controls |
| **Drift persistence across a reopen** | Unchanged and clean. | iteration 2's control |
| **parent/kid mode guard** | Unchanged and clean (kid + expired trial still redirects). | iteration 2's controls |
| **dark-mode contrast** | Unchanged; every painted pair clears 4.5:1. The only low pair remains the orchestrator-mandated `#1E1B3A` sparkle stroke on `#1F1C2E` (D4), which is PNG parity, not a contrast requirement. | iteration 1/3 |
| **text scale 1.3 + width 320** | **Both halves fail, for the same defect.** At 320 px / 1.3 the tops drift 2.36 px and the numbers paint 29.38 / 29.49 / 32.39; at 320 px / **1.0**, with no text scaling at all, 2.40 px. Copy is not truncated (see the correction above — 1.3 is the ceiling). | **K07-BUG-8** |
| **bottom edge (owner rule)** | Unchanged and clean: the bar's surface runs to the physical edge in both themes. | iteration 3 |
| **async gaps** | Unchanged and clean. | iteration 2/3 controls |
| **timezone / BST / money rounding** | Provably n/a: `pip_total_coins` is written only by the seed, K07 renders coins and never `£`, and `watchEvolution` counts rows and reads no clock. | iteration 3 |

## Carried from stage 4 (not re-reported as this stage's findings)

`4_review.md` owns its three minors; this stage did not duplicate them and did
not fix them. Two are directly related to this pass and are **corroborated**
here rather than restated:

1. **Finding 1** — the three numbers are 2.40 px apart at 320 px, and
   `FittedBox`'s default `Alignment.center` also sits them ~12 px below the CSS
   position. **This pass measures the same 2.40 px and confirms it is a
   *baseline* splay of three differently-scaled numbers**, i.e. finding 1's
   `Alignment.topCenter` is necessary but **not sufficient**: with the default
   centre alignment the drift is 2.40 px at 320 px, and K07-BUG-8's per-card
   scale difference is present at 390 px too, where the insets *are* equal
   (15.00 × 3). Both fixes are needed. Finding 1's own note says a test "must
   assert the number tops, not just the card tops" — this pass's
   `K07-BUG-8` proof does exactly that.
2. **Finding 2** — the surviving `.kcap` cap, now `K07-BUG-9` with a permanent
   proof. See the correction above for where this pass agrees and where it
   sharpens.
3. **Finding 3** — `evolutionSub(0)` renders "Because you helped 0 times". The
   zero branch is still missing and still only reachable at 0 completions.
   Unchanged; no wording invented.

## Observations (not findings)

1. **The screen still has no in-app entry point.** `PipRoutePaths.evolution` has
   no call site outside `pip_routes.dart`; the only ways in are
   `--dart-define=INITIAL_ROUTE=/pip-evolution` or a deep link. Carried from
   iteration 2 — the K06/flow owner's call.
2. **The `#3D7FF0` sky dot** is still off-token in the design source, and after
   the mandated D4 fix it paints the light sky token in both themes. Still
   `SHARED_REQUEST.md` item 4 / `5_ui.md` D5.
3. **Stage 3's `pip_evolution_stats_scales_test.dart` is untracked in this
   worktree** (written by the concurrently-running `3_test` stage, mtime 02:20,
   against this stage's 02:12 start). This stage **read and ran it but did not
   edit or delete it** — RULES §1 plus the "do not delete unfamiliar work" rule.
   It generalises the stat row across 320/390/430 × light/dark × 1.0/1.3/2.0;
   note that its 2.0 column is clamped to 1.3 by `app.dart`, so its 2.0 rows
   are the same measurement as its 1.3 rows.
4. `flutter test test/features/pip` was **not** run as one command while stage 3
   was writing: `3_test.md` (mtime 02:33), `4_review.md` (02:32) and `5_ui.md`
   (02:39) all changed mid-pass, so the gates below were run against the tree as
   it stood at each step and the two counts are reported separately.

## Gates

```
$ dart format --set-exit-if-changed .
Formatted 643 files (0 changed) in 3.25 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 8.2s)

$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
00:03 +32 ~2: All tests passed!        (30 green, 2 parked)

$ flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart
00:04 +30 -2: Some tests failed.       exactly the two new proofs fail:
  K07-BUG-8 → number-top drift 3.1619291693054947 px (limit 2.0)
  K07-BUG-9 → the caption's cap is 3 where the design needs none
  (both controls stay green, so nothing else moved)

$ flutter test --timeout 120s test/features/pip
00:22 +449 ~2: All tests passed!       (the ~2 are this stage's parked proofs)

$ flutter test --timeout 120s          # the whole app
03:48 +4504 ~12: All tests passed!
```

The 12 app-wide skips are the suite's own parked proofs, unchanged by this stage:
`k01_bugs` 1, `k03_bugs` 2, `k09_bugs` 6, `p12_bugs` 1, plus this stage's two.

Every gate ran with a per-test timeout, nothing was waited on for more than ten
minutes, and nothing hung. The two `skip: true` lines are this stage's parked
proofs — inside `test/features/pip` they are the **only** skips. The stage-3/4/5
K07 suites were read and run but **not edited**.

Scratch probes (`zz_probe*_iter4_k07_test.dart`, 9 files) were exploratory and
are **deleted**; every number they produced is either quoted above or pinned by a
permanent test in `k07_bugs_test.dart`. One probe (`zz_probe10`, a coin-value
sweep inside a single `testWidgets`) hit the documented async-zone deadlock in
this file's own header (a Drift write on a table a live watch sits on, inside
`runAsync`) and was abandoned; its one needed number was re-measured with the
write before the first pump.

**One harness bug this stage found in itself**, recorded because it would
otherwise bite the next stage: the first draft of `K07-BUG-8` set
`textScaleFactorTestValue = 1.3` without an `addTearDown`, so under
`--run-skipped` it leaked 1.3 into the control that follows it and that control
failed too. It is fixed (`addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue)`),
and it is why the control asserts against an explicitly reset 1.0.

## Verdict

Iterations 1–3's six findings are closed, and this pass re-measured rather than
assumed it. The whole brief matrix — 0/1/6 children, out-of-range stages, 0 to
999 999 999 coins, one and zero completions, `to_do`/`not_yet`/`denied`/other-child
row isolation, rapid double taps, back navigation and deep links, Drift
persistence, both mode guards, contrast in both themes, the 280 → 844 px matrix,
the bottom-edge rule and the async-gap cases — is clean, and the newly covered
parts are pinned.

What this pass found is a defect three iterations missed, because the UI check
only ever looks at 390 px with the default text size: **the three stat cards
paint their headline numbers at three different type sizes**, and the numbers'
top edges drift 3.16 px apart at the design width once the text scale reaches the
1.3 maximum the app itself supports. Same mechanism at 320 px needs no
accessibility setting at all. That is an owner ALIGNMENT failure and a UI-verdict
failure on the element the whole screen exists to show, and it is a two-line,
feature-local fix.

It also produced one correction the loop needs: the 1.0–1.3 clamp in `app.dart`
makes every 2×–3.2× reachability argument in this folder's earlier bug reports
unreachable, so iteration 5 should not hunt there.

VERDICT: FAIL