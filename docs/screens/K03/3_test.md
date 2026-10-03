# K03 Kid home — Stage 3 (TEST), iteration 11

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_bloc_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`).
Per RULES §1 this stage only touched `app/test/features/kid_home/**` and
`docs/screens/K03/**` — **no screen code was patched, and no bug was found, so
there is nothing to record as a defect**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `BC440E48-…`).

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched, no
  new suppressions).
- `flutter test` (whole app) → **exit 0, `+1793`** — 1793 pass, **0 skip,
  0 fail**.
- `flutter test test/features/kid_home/` → **exit 0, `+185`** — 185 pass,
  **0 skip, 0 fail**.

| File | Iteration 10 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 87 | **89** (+2 from the build) |
| `kid_home_bloc_test.dart` | 31 | **31** |
| `k03_bugs_test.dart` | 59 | **59** |
| `kid_home_geometry_test.dart` | 1 | **6** (+5 from the build, +1 from this stage) |

Iteration 10 was the first iteration with **all four stages PASS**
(`build=PASS test=PASS review=PASS ui=PASS bugs=PASS`), so this stage started from
a green baseline and the build for iteration 11 changed **no product code** —
only tests and a new capture route.

## What iteration 11 delivered (the surface under test)

1. **No `kid_home` production change.** `git show fbc4b56 -- app/lib/…` is empty
   for the view, bloc, state and repository; the iteration is verification-only.
2. **Pixel-level meadow pins** (build, `kid_home_geometry_test.dart`): the screen
   is rendered into a `RepaintBoundary` and the actual bytes at (10, 600) and
   (10, 700) are compared, in **both** themes, against the CSS
   `kid-horizon → kid-meadow` grade (±2/255) — and, crucially, each row must
   have moved *off* the horizon tone in the direction `kid-meadow` lies. That is
   the dark "flat navy" regression (FIXES_10 #1, the 4th time it appeared), and
   the pin fails if the grade stops or is computed over the band's in-flow
   height instead of the design's 321 px run.
3. **`ui/widgetrender_{light,dark}_11.png`** — a capture route that does not need
   the simulator (no product change behind it).

## Tests added (this stage)

The new **UI VERDICT RULE** is the one thing this stage can make automatic: "a
UI check may only PASS when every element is within ±2 px of the design position
… A uniform vertical shift of the whole screen is a FAIL, even if each element
'looks the same'. Report the measured y of the screen title, the first control
and each card top, design versus app."

The build's geometry test already pinned the hero block, the hearts row (448),
the progress bar (527…542) and card 1 (559). It did **not** pin the rest of the
column, and the rule explicitly names *each card top*. So one new test in
`kid_home_geometry_test.dart` (real Inter/Nunito, 390×844, the OS 34 px bottom
inset emulated because the design's dock top is measured on a device):

**`every row below the nest lands within 2 px of the design`**
- the section row (`KidStatusChip`, the 32 px pill centred on the title) sits on
  the design's **y 494**;
- **card 1's painted top is 559**, and **every** following painted top keeps the
  design's `.k3-quests { gap: 12px }` rhythm (measured against the *painted*
  rect, since the widget rect carries the shared card's 6 px shadow reserve);
- the dock's painted top is **720** and its bottom is the physical edge
  (844) — the bar owns the OS inset;
- **card 2 peeks above the dock**: its top is above the bar and its bottom below
  it, which is what the design shows.

Two local helpers were added for this (`_dockSurface`, `_paintedCard`), mirroring
the ones in the view suite.

## Results — measured rows at real fonts (390×844, light, 34 px inset)

| row | measured | design | Δ |
| --- | --- | --- | --- |
| status bar (excluded by the rule) | 0…47 | 47 | — |
| avatar `.avatar.s64` | 51…115 | 4 px below the reserve | — |
| greeting `.k3-name` 22/26 | 60…86 | metric | — |
| coin pill | 65…101 | metric | — |
| lock (first control) | 55…111 (56 tall) | ≥ 44 | — |
| hearts row centre | **447.8** | 448 | **−0.2** |
| section row centre (`Today's quests` + chip) | **493.8** | 494 | **−0.2** |
| progress bar | **526.8…542.8** | 527…542 | **−0.2 / +0.8** |
| card 1 painted top | **558.8** | 559 | **−0.2** |
| cards 2…6 painted tops | 658.8 · 758.8 · 858.8 · 958.8 · 1062.8 | 12 px painted gaps | 0.0 each |
| dock painted top | **719.0** | ≈720 | **−1.0** |
| dock bottom | 844.0 | physical edge | 0.0 |

Every row is inside the ±2 px band, so no uniform shift exists: the hero block
(rim 278, feet 301), the hearts row, the section row, the progress bar, all six
card tops and the dock are pinned at absolute design coordinates in one suite, and
a shift of the whole screen would break several of them at once.

All 185 K03 tests pass, and nothing else moved: the layout matrix (light + dark ×
320/390/430 × text scale 1.0/1.3), layout invariants on painted card rects,
PERIODS, bottom-edge and alignment owner rules, navigation, labels, tap targets,
the accessibility-actions matrix (iteration 9), the PipAvatar mandate and its
bowl seat (iteration 10), the completion/celebration state machine, the shapes
group (chip pill, tile + tint, 56 px check, `.speech` bubble, scene box per
width), and the quest-order pin.

## Bugs found

**None.** No test failed, no row is outside ±2 px, and nothing in the screen
misbehaved under this stage's probes. The iteration-10 tail (dark meadow,
squashed bowl, Pip on the rim) is closed and now pinned on the bytes and on the
geometry respectively.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset) pass, and
  the new dock pin re-confirms it at real fonts: the painted surface starts at
  719 and reaches 844 — the physical edge — in one piece.
- **ALIGNMENT:** gutters and shared card/bar/dock edges pass; the pet slot is on
  the axis at 320/390/430 with no clipping; dock labels cannot wrap; quest cards
  keep the design's 12 px gap between painted rects, now verified for **all six**
  cards rather than the first two.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| **UI VERDICT RULE** | **New pin**: section row, every card top, the 12 px painted gaps, the card-2 peek and the dock top at real fonts, all ±2 px of the design rows — plus the build's hero/hearts/progress rows, so the whole column is pinned |
| PIP | Mandated `PipAvatar` in every state, seated in the bowl (feet ≈23 px below the rim, iteration 10) |
| BOTTOM EDGE / ALIGNMENT | Proven by tests (above) |
| PERIODS + DATA OVER MOCKS | Counts from the DB; daily/weekly/once + new-period proofs green; quest order pinned as documented |
| COPY | Re-verified character-by-character against the HTML source (straight apostrophes, the seed's en dash, the detail chip's middle dot) |
| FONTS / LETTER SPACING | No `google_fonts`; every rendered string asserts `letterSpacing == 0`; real-font geometry uses the bundled faces |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip` |
| UI CHECK MEASURES SHAPES | Painted rects for cards and dock, pixel bytes for the meadow grade, outline/feet geometry for the pet slot, chip/tile/check/bubble boxes |
| BALANCED HEADINGS | The only `.kid-title` heading renders through `NestBalancedText` |
| ACCESSIBILITY ACTIONS | Iteration 9's 7-test matrix still green |
| CHILD ORDER | No child list here; pinned at the repository level (K03-BUG-12) |
| TRIAL | No test writes `subscription_status` |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- The real-font geometry file is the only place where absolute design rows are
  meaningful: the fallback test font is wider than Nunito, so the same screen
  measures ~11 px lower there. Keep absolute rows in `kid_home_geometry_test.dart`
  and relationships in `kid_home_view_test.dart`.
- Emulate the OS bottom inset (`tester.view.padding` / `viewPadding`, 3× physical
  px) before measuring the dock: the design's y ≈720 includes it.
- The design's outline fractions are asymmetric — the bowl starts 95/240 down
  its box while its height is 110/240 — and the v2 Pip's feet sit 21.2 px above
  the bottom of its 152 px box.
- Offstage cards have **no semantics node**; scroll a control into view before
  asserting or performing its semantics action.
- `pushedPath`, not `currentPath`, for `push`ed routes; the design source uses a
  **straight** apostrophe.
- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`; never
  `pumpAndSettle` while a loading spinner is on screen; seed the DB before
  pumping the route.

VERDICT: PASS
