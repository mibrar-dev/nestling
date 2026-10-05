# Fix list after iteration 3

## From 6_bugs.md
# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 3, third pass)

Adversarial pass over K07 **as it stands after the iteration-3 build `f4174f9`**
and the iteration-3 stage-3/4/5 work alongside it. **This stage changed no
product code** — RULES §1 lets a bug hunt add only `app/test/features/pip/**` and
`docs/screens/K07/**`, and `git status --porcelain app/lib` is empty at the end
of it (the two fixes below were each applied to verify them green, then reverted
from the index — evidence in their own sections). No simulator was booted,
installed on or driven: only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`.
No `flutter clean`, no `analysis_options` change, no skipped gate, no
`google_fonts`, no `DateTime.now()`, no `pkill`.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **2 skipped failing
proofs** (K07-BUG-6, the new major; K07-BUG-7, the new minor) on top of the 28
tests that pass: iteration 1's four proofs and iteration 2's K07-BUG-5 (now
green, the orchestrator's mandatory D4 fix having landed), plus **4 new controls**
from this pass.

## Verdict summary

| # | Severity | Status | Summary | Proof |
|---|---|---|---|---|
| **K07-BUG-6** | **MAJOR** | **OPEN** (in-feature fix, verified green) | The three `.k7-stats` cards are **different heights with splayed top and bottom edges** whenever the cell is narrower than their content. `PipEvolutionStats`'s `Row` uses the default `CrossAxisAlignment.center`, so unequal cards are centred against each other instead of stretched. On a **320 px phone with the shipped demo seed** the cards are 76.9 / 77.1 / 81.7 px tall and their edges drift **2.40 px**; with a 9-digit coin total the drift is **11.67 px** at 390. The design is a CSS flex row with no `align-items`, i.e. `stretch`, and the PNG measures all three at y 545..629. | `k07_bugs_test.dart` → `K07-BUG-6: the three stat cards are different heights…` (real Nunito, demo seed, 320 px) |
| **K07-BUG-7** | minor | **OPEN** (in-feature fix, verified green) | The app adds two line clamps the design does not have: `maxLines: 4` on the hero `NestBalancedText`, whose default overflow is `TextOverflow.clip` (a **hard cut, not even an ellipsis**), and `maxLines: 2` + ellipsis on the sub-line, which **carries the quest count**. At accessibility text scales the headline is cut mid-glyph and the count is ellipsized away ("Because you helped 9999…"). iOS reaches 3.16× on a 390 px phone; Android's 2.0× maximum truncates a 6-digit count at 320 px. | `k07_bugs_test.dart` → `K07-BUG-7: the app-only \`maxLines\` caps truncate…` |
| K07-BUG-5 | ~~MAJOR~~ | **FIXED, re-verified** | The dark-mode sparkle palette (`ORCHESTRATOR_NOTES` 23:55, D4). | now green, un-skipped by the build; the ink stroke samples `0x1E1B3A` in dark |
| K07-BUG-1 … 4 | — | **FIXED, re-verified** | Iteration 1's four findings. | all green |

**This pass: one major bug, **K07-BUG-6**, plus one minor
(**K07-BUG-7**). Both are confined to `features/pip/presentation/**`, so both are
RULES §1-legal for this branch; both fixes were verified green and then reverted.

Everything else in the brief's hunt matrix is clean, and one of the two
"findings" this pass started with is retracted below: **no copy on this screen is
truncated at text scale 1.0–2.0** — the clipping an earlier probe appeared to see
was Flutter's fallback test font, not Nunito (see "The real-font correction").

---

## K07-BUG-6 — MAJOR — the three stat cards are unequal and their edges splay

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`
— `PipEvolutionStats.build`'s `Row` (`:78`) and `_StatCell`'s
`FittedBox(fit: BoxFit.scaleDown)` (`:151`).

The design:

```css
.k7-stats { display: flex; gap: 10px; }
.k7-stats > div { flex: 1; min-width: 0; background: var(--surface);
                  border: 3px solid var(--ink); border-radius: var(--r-m);
                  box-shadow: var(--sh-kid); padding: 12px 6px; … }
```

No `align-items`, so CSS stretches all three items to the tallest — one height,
three identical top and bottom edges. `5_ui.md` measured exactly that on the
light PNG: cards at x 20..130 / 140..250 / 260..370, **all at y 545..629**.

The app:

```dart
child: Row(                       // ← crossAxisAlignment defaults to .center
  spacing: EvolutionStatsGeometry.gap,
  children: <Widget>[
    Expanded(child: _StatCell(...)),   // height = its child's intrinsic height
    …
```

Each `_StatCell` is a `Container` whose height is its child's intrinsic height,
and that child is a `FittedBox(fit: scaleDown)` — so a cell whose content is
*narrower* than the cell's inner box is scaled **less** and therefore painted
**shorter**. `CrossAxisAlignment.center` then centres the three boxes against one
another, so their tops and bottoms splay by exactly half the height difference.

### Evidence — measured, real Nunito, **no DB write at all** (shipped demo seed)

`FontLoader('Nunito')` with the bundled `Nunito-Bold.ttf` / `Nunito-Black.ttf`
(the pattern `test/core/design_system/nest_pet_stage_test.dart:154` established),
so these are the device's numbers, not the test font's:

| surface width | cell inner box | card heights | top edges | bottom edges | **edge drift** |
|---|---|---|---|---|---|
| **390** (design) | 92.0 px | 84.00 / 84.00 / 84.00 | 579 / 579 / 579 | 663 / 663 / 663 | **0.00** ✓ |
| 375 | 87.0 px | 84.00 / 84.00 / 84.00 | 579 / 579 / 579 | 663 / 663 / 663 | **0.00** ✓ |
| 360 | 82.7 px | 84.00 / 84.00 / 84.00 | 579 / 579 / 579 | 663 / 663 / 663 | **0.00** ✓ |
| **320** | 68.7 px | **76.88 / 77.05 / 81.68** | 581.40 / 581.31 / 579.00 | 658.28 / 658.37 / 660.68 | **2.40** ✗ |
| 280 | 58.7 px | **67.77 / 67.92 / 71.64** | 580.93 / 580.86 / 579.00 | 648.71 / 648.78 / 650.64 | **1.93** ✗ |

The threshold is exactly where the mechanism predicts: the cells only start to
shrink once the inner box drops below the widest content, which for Nunito 700 14
is the label `quests done`. 320 px is a **supported** width
(`docs/design/SPACING_SPEC.md:369` plans 320 layouts, and `k07_bugs_test.dart`'s
own K07-BUG-2 proof says so), and 320 px is the width this file's own brief names.

The same defect scales with the value (each row is a separate run, cards at
390 px):

| `pip_total_coins` | heights @390 | drift @390 | heights @320 | drift @320 |
|---|---|---|---|---|
| 120 (demo) | 84 / 84 / 84 | 0.00 | 76.9 / 77.1 / 81.7 | **2.40** |
| 1 200 | 84 / 84 / 84 | 0.00 | 76.9 / 77.1 / 81.7 | **2.40** |
| 12 345 | 84 / 84 / 84 | 0.00 | 76.9 / **71.2** / 81.7 | **5.24** |
| 123 456 | 84 / **76.0** / 84 | **4.00** | 76.9 / **64.3** / 81.7 | **8.67** |
| 999 999 999 | 84 / **60.7** / 84 | **11.67** | 76.9 / **52.9** / 81.7 | **14.40** |

**Repro (deterministic, ~2 s, no simulator)**

```
cd app && flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_bugs_test.dart
```

**Failing test** — `K07-BUG-6: the three stat cards are different heights and
their top and bottom edges drift apart…`

```
Expected: a value less than or equal to <0.5>
  Actual: <4.802077656253232>
```

(the height spread of the three card boxes: 81.68 − 76.88. The top- and
bottom-edge assertions, 2.40 px each, are the same defect.)

**Impact.** Every session on a 320 px phone — and any width ≤ ~330 — shows the
celebration screen's three focal cards with ragged top and bottom edges. The
cards carry a 3 px ink border **and** a 6 px `--sh-kid` shadow, so a 2.4 px
splay reads as three cards of different sizes rather than one row; at large
values it is 12–14 px and unmistakable. No data, state, a11y or copy impact.

This is a UI failure by the two rules that apply here, not a matter of taste:

- **owner ALIGNMENT rule**: *"cards and bars aligned to the same edges, nothing
  a few px off. Treat visible misalignment as a UI failure."*
- **UI VERDICT rule**: ±2 px. Measured **2.40 px** with the demo seed.

It survived iterations 1 and 2 because `5_ui` measures at **390 px only**, where
the defect is exactly 0.00.

**Suggested fix** — feature-local, RULES §1-legal, `pip_evolution_stats.dart` only.
`CrossAxisAlignment.stretch` must be paired with `IntrinsicHeight`, because the
row sits in a `SingleChildScrollView` and its cross axis is otherwise unbounded
(measured: a bare `crossAxisAlignment: CrossAxisAlignment.stretch` throws
*"BoxConstraints forces an infinite height — BoxConstraints(w=110.0, h=Infinity)"*
inside the 280×360 control):

```dart
child: IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,   // CSS `align-items: stretch`
    spacing: EvolutionStatsGeometry.gap,
    children: <Widget>[ … ],
  ),
),
```

This is preferable to pinning the card height, because a fixed height would stop
the cards growing at large text scales — the opposite of what accessibility needs.

**Fix verified, then reverted.** With the patch applied,
`flutter test --timeout 120s --run-skipped` over the twelve K07 suites
(`k07_bugs`, `k07_sparkles_bug`, `pip_evolution_{view,a11y,widget,copy,sparks,
data,stream_contract,repository,bloc}`, `pip_iter2_fixes`) →
`+206 -1`: **K07-BUG-6 goes green** and nothing else moves — the K07-BUG-5 dark
palette proof, the three D2 sparkle-shape proofs, the 2a/2b contract proofs and
the a11y tap-action proofs are all unaffected. The single failure is
`pip_evolution_copy_test.dart:334`, which pins `maxLines == 4` — see K07-BUG-7.
The working tree was then restored from the index
(`git status --porcelain app/lib` → empty).

---

## K07-BUG-7 — minor — app-only line clamps truncate the headline and the count

**Where** `app/lib/features/pip/presentation/views/pip_evolution_view.dart` —
the hero `NestBalancedText(…, maxLines: 4)` (`:341-346`) and the sub
`Text(…, maxLines: 2, overflow: TextOverflow.ellipsis)` (`:347-354`).

The design puts **no clamp** on either: `.k7-hero` only adds
`overflow-wrap: anywhere` and `text-align: center` on top of `.kid-title`
(which contributes `text-wrap: balance`), and `.k7-sub` only adds
`text-align: center` on top of `.kid-body`. In the browser both lines simply grow
and `.scroll` (`overflow-y: auto`) scrolls.

Two app-only caps sit on top of that, and one of them is a hard cut:

- `NestBalancedText`'s default `overflow` is `TextOverflow.clip`, so the hero's
  5th line is **cut mid-glyph with nothing to show for it** — not even an ellipsis.
- The sub-line's cap drops the ellipsized tail of **the number that explains why
  Pip grew**.

### Evidence — `NestBalancedText.lineCountFor` (the component's own `@visibleForTesting`
probe, which is exactly what its `build` uses), real Nunito

| text scale | 350 px (390 phone) | 320 px | 280 px |
|---|---|---|---|
| 1.0 | clean | clean | clean |
| 1.3 | clean | clean | clean |
| 2.0 | clean | **sub 3 lines** (6-digit count) | **title 5** + sub 3–4 |
| 2.5 | sub 3 (4-digit) | **title 5** (all stages) + sub 3 | title 5 + sub 3–4 |
| 3.0 | **title 5** (Hatchling/Songbird) + sub 3 | **title 5** + sub 3 | title 5 + sub 3–4 |
| 3.16 | **title 5** (3 stages) + sub 3–4 | **title 5** + sub 3–4 | title 5–6 + sub 4–6 |

Read the reachability carefully, because it bounds the severity:

- **2.0×** is Android's **maximum** font scale. At 320 px a 6-digit count is
  ellipsized away. At 240 px content the headline needs 5 lines.
- **2.5× and above** is reachable on iOS (`.accessibility3` = 2.71×,
  `.accessibility5` = 3.16×). At 390 px, 3× already needs 5 lines for
  "Pip grew into a Hatchling!" / "…a Songbird!".
- At the brief's own named combination (**1.3×, 320 px**) there is **no**
  truncation, and none at 320 px up to 2.0× for a normal count.

So this is an accessibility-scale defect, not a shipping-demo one, which is why
it is **minor** rather than major.

**Failing test** — `K07-BUG-7: the app-only \`maxLines\` caps truncate the
celebration copy…`. It reads the caps **off the shipped widgets** (so raising or
dropping a cap is what turns it green) and lists the offenders in the reason.

**Suggested fix** — `pip_evolution_view.dart` only: drop both caps (the design has
none) or raise them to the envelope's worst case. Dropping is safe because
`.k7-scroll` scrolls. Two knock-ons the build stage must handle in the same
commit, both found by this pass:

1. `1_plan.md` §(a).3 specifies `maxLines: 4`, so the cap is a *planned* value
   that turns out to be wrong — the plan's note is that `.k7-hero` adds
   `overflow-wrap: anywhere` (≈ `softWrap`), which says nothing about line caps.
   Worth a re-ratification rather than a silent change.
2. `pip_evolution_copy_test.dart:334` pins `expect(balanced.single.maxLines, 4)`
   with the comment *"the heading keeps the shared `kidTitle` style (the plan's
   maxLines 4)"*. That one assertion is the **only** thing that fails when the
   cap is dropped (verified: `Expected: <4>  Actual: <null>`), and it has to move
   with it.

**Fix verified, then reverted.** With both caps dropped, K07-BUG-7 goes green
along with K07-BUG-6 (`+206 -1`, the one failure being the assertion above), and
the tree was restored from the index afterwards.

---

## The real-font correction — a candidate finding this pass RETRACTS

Iteration 2's harness note recorded that "text-driven geometry measured in a
widget test is not the device's geometry" because the test font is wider than
Nunito. This pass loaded the real bundled Nunito, which both **sharpens** the
hunt and **retracts** an apparent defect:

- **Retracted:** an initial probe (fallback font) showed the hero and sub
  "exceeding max lines" at 320 px and even 1.3×. With real Nunito the **rendered**
  paragraphs report `didExceedMaxLines == false` at **every** width in
  {390, 320, 280} and every scale in {1.0, 1.3, 1.5, 2.0, 3.0}. Pinned by
  `control: no copy is truncated at text scale 1.0–2.0 on a 320 px phone…`.
- **Sharpened:** the fallback font renders all three stat labels at the *same*
  width, so K07-BUG-6 is **invisible** without Nunito (fallback @320 px: three
  cards of 54.08 px, drift 0.00; real Nunito @320 px: 76.88 / 77.05 / 81.68,
  drift 2.40). Had this pass trusted the fallback font it would have cleared the
  one major bug in the screen.

**Method note for the next stage.** `FontLoader` mutates the engine's font
collection for the rest of the test process, so the real-font tests in
`k07_bugs_test.dart` are deliberately **last in the file** — anything after them
would be measuring a different font. That ordering is load-bearing.

---

## The brief's hunt matrix — what this pass measured

| item | result | pinned by |
|---|---|---|
| **0 children / no active child** | Unchanged from iteration 2 and re-measured clean: "Who's playing?" + `Choose`, no retry, no spinner. The card's content also **fits** its body box at 390/1.0, 320/1.3 and 280/2.0 — `Center` without a scroll view is safe here. | iteration 2's control |
| **1 child / 6 children / deleted sibling** | Unchanged, re-measured clean. | iteration 2's control |
| **long UK names** | Re-measured: the nickname is only ever in the a11y label, never painted, so there is no rect to overflow. | iteration 2's control |
| **9999 coins / 0 / 999999999** | Re-measured with **real Nunito**: no overflow, no elision. The large values instead feed K07-BUG-6 (which is what this pass found). | iteration 2's control + K07-BUG-6 |
| **empty lists / 0 and 1 completions** | Re-measured; the singular branch is intact. | iteration 2's control |
| **`pip_stage` out of range** | Re-measured; 0/5/99 clamp into the 1..4 artboards. | iteration 2's control |
| **count isolation** (new) | `to_do`, `not_yet` and `denied` rows for Maya and an `approved` row for **Leo** all leave Maya at "4" / "Because you helped 4 times". The schema documents the completion vocabulary as `to_do | done_pending | approved | not_yet` (`app_database.dart:12`); `denied` is what the approvals feature writes, and `expired` belongs to `subscription_status`, not to completions. Only `done_pending` + `approved` count. | `control: only done_pending / approved rows…` (new) |
| **repeated quest completion** | K07-BUG-3, fixed; both proofs green. | K07-BUG-3 ×2 |
| **rapid double taps** | Re-measured on every control. One step further: a **second** real stream failure still leaves "Try again" live (1 → 2 → 3 subscriptions) and the celebration returns when the stream finally answers. | `control: a second REAL stream failure…` (new) + iteration 2's controls |
| **back navigation / deep links** | Re-measured, unchanged and clean. | iteration 2's controls |
| **Drift persistence across a reopen** | Re-measured, clean. | iteration 2's control |
| **parent/kid mode guard** | Re-measured, clean (kid + expired trial still redirects to `/parental-gate`). | iteration 2's controls |
| **dark-mode contrast** (new, real hexes) | Every painted pair clears 4.5:1. Light: `ink`/`lilacTint` 14.11, `ink2`/`lilacTint` 7.59, `ink`/`surface` 16.50, `ink2`/`surface` 8.87, `onAccent`/`lilacStrong` 5.03. Dark: 12.58, 8.37, 14.76, 9.82, 7.74. The only low pair is the **sparkle stroke** in dark (`#1E1B3A` on `#1F1C2E` = 1.01) — which is exactly what the orchestrator's 23:55 ruling mandates for PNG parity, not a contrast requirement. | measured this pass |
| **text scale 1.3 + width 320** | Clean with the real font (see the retraction above). The defect that *is* there is 34 px further up the scale — K07-BUG-7. | `control: no copy is truncated…` (new) + K07-BUG-7 |
| **bottom edge (owner rule)** | Re-measured: the bar's surface runs to the physical edge (bar 390 × 89 at y 755 on an 844 px screen, `bottom == screenHeight`). `NestHomeIndicator` collapses to `SizedBox.shrink()` off the gallery (`showMockGlyphs == false`), so the `SafeArea` inset — not the pill — is what fills the edge, and there is no strip under it in either theme. | measured this pass |
| **async gaps** | Re-measured; unchanged and clean. | iteration 2's controls |
| **timezone / BST / money rounding** | Still provably n/a, and now with a stronger argument: `pip_total_coins` is written **only by the seed** (`Seed.demo()` 175 / 60) and `pip_total_coins` has no CHECK constraint; K07 renders coins, never `£`; and `watchEvolution` counts rows and reads no clock. Nothing to round, nothing period-dependent. | `pip_evolution_data_test.dart` + this pass's read of the column |

## Carried from stage 4 (not re-reported as this stage's findings)

`4_review.md` still owns its three minors; this stage did not duplicate them and
did not fix them:

1. `evolutionSub(0)` renders "Because you helped 0 times" (the zero branch is
   missing; wording needs the orchestrator's sign-off — `SHARED_REQUEST.md`
   item 5). Iteration 2's control still pins today's wording with a comment
   saying it moves when the finding lands, and this pass re-read it: the branch is
   still missing and still only reachable at 0 completions.
2. A test header naming the wrong sparkle file — **now corrected** by the
   iteration-3 build (`2_build.md`: `pip_evolution_sparks_test.dart` header fixed),
   so that finding is closed.
3. Finding 1 (`toLoading()` clearing both arrival flags) was **fixed** by the
   iteration-3 2a build and re-verified green in `pip_evolution_bloc_test.dart`.
   Only the structural cause survives, as finding 2's sibling: `PipLoadRequested`
   still subscribes K06's `watchNest()` on K07 (cost only, `SHARED_REQUEST.md`
   item 2).

## Observations (not findings)

1. **The screen has still no in-app entry point.** `PipRoutePaths.evolution` has
   no call site outside `pip_routes.dart`; the only ways in are
   `--dart-define=INITIAL_ROUTE=/pip-evolution` or a deep link. Carried from
   iteration 2 — it is the K06/flow owner's call, not a K07 defect.
2. **The `#3D7FF0` sky dot** is still off-token in the design source, and after
   the mandated D4 fix it paints the light sky token (`#2563D6`) in both themes.
   Still `SHARED_REQUEST.md` item 4 / `5_ui.md` D5, and the K07-BUG-5 proof
   deliberately reports rather than pins it.
3. **`flutter test test/features/pip --run-skipped` can stall** in
   `pip_buy_result_test.dart` when the whole directory runs at once (iteration 2
   measured 7 minutes of no progress; this pass hit the same wall and worked
   around it by naming files). Not caused by, and not fixable from, K07.
4. **Iteration-3 stage 5 (`5_ui`) ran concurrently with this stage** in the same
   worktree: its screenshots (`ui/app_{light,dark}_3.png`, `ui/cmp_{light,dark}_3.png`)
   and its edits to `3_test.md` / `4_review.md` / `5_ui.md` /
   `pip_evolution_{data,sparks,stream_contract}_test.dart` appeared in
   `git status` mid-pass. Nothing here is attributed to that work, and the gates
   below were run against the tree as it stood.

## Gates

```
$ dart format --set-exit-if-changed .
Formatted 642 files (0 changed) in 2.02 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test --timeout 120s test/features/pip
00:09 +427 ~2: All tests passed!        (28 K07 proofs/controls green, 2 parked)

$ flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart
  → +28 -2:  exactly two proofs fail, one per new finding:
      K07-BUG-6  → card-height spread <4.802077656253232> px (limit 0.5)
      K07-BUG-7  → the hero needs 5 lines at 3x/390 and the sub needs 3 at 2x/320

# with both fixes applied, then reverted (see each finding's section):
$ flutter test --timeout 120s --run-skipped <the 12 K07 suites>
  → +206 -1:  K07-BUG-6 and K07-BUG-7 green; the one failure is
     pip_evolution_copy_test.dart:334 pinning the plan's maxLines == 4
```

$ flutter test --timeout 120s          # the whole app
01:33 +4482 ~12: All tests passed!

Every gate ran with a per-test timeout, nothing was waited on for more than ten
minutes, and nothing hung. The 12 skips are this stage's two parked proofs plus the repo's own
parked proofs, unchanged by it: `k01_bugs` 1, `k03_bugs` 2, `k09_bugs` 6,
`p12_bugs` 1. Inside `test/features/pip` this stage's two are the **only**
skips. The stage-3/4/5 K07 suites were
read and run but **not edited** by this stage.

Scratch probes (`zz_probe*_iter3_k07_test.dart`, 6 files, ~90 measurements) were
exploratory and are **deleted**; every number they produced is either quoted above
or pinned by a permanent test in `k07_bugs_test.dart`.

## Verdict

Iteration 1's four bugs and iteration 2's K07-BUG-5 are all closed, and this pass
re-measured rather than assumed it — the dark sparkles now paint the design's own
`#1E1B3A` stroke in both themes, the "Oh no! Pip got lost." false card is still
gone, the sparkle tips are back, the milestone card counts quests and not rows,
and the 320 px slot still tells its before → after story.

The whole brief matrix — 0/1/6 children, out-of-range stages, 0 to 999 999 999
coins, one and zero completions, `to_do`/`not_yet`/`denied`/other-child row
isolation, rapid double taps on every control including a *second* real failure,
back navigation and deep links, Drift persistence across a reopen, both mode
guards, contrast in both themes, the 280 → 844 px matrix, the bottom-edge rule,
async gaps — is clean, and the parts this pass newly covered are now pinned.

What the pass did find is a defect both earlier iterations walked past, because
`5_ui` only measures at 390 px: **the three stat cards are not equal height and
their edges splay**, measurably on a 320 px phone with the shipped demo seed
(2.40 px, and 11.67 px for a large coin total), purely because the row centres
its children where the design's flex row stretches them. That is an owner ALIGNMENT
rule failure and a UI-verdict-rule failure on the screen's focal element, and it
has a two-line, feature-local, already-verified-green fix.

