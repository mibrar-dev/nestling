# 3 — TEST (iteration 4) — K06 · Pip's nest (`/pip`, feature `pip`)

In-memory Drift + `Seed.demo` / `Seed.empty`. **No simulator was booted,
installed on, screenshot or driven** (stage rule — only `5_ui` may, and only
on 604697A9-…-396E9CA2493A). No `flutter clean`, no `analysis_options` change,
no image attached. **No product code touched.**

## Headline

```
dart format --output=none --set-exit-if-changed .   → 593 files (0 changed)  exit 0
flutter analyze                                    → No issues found!         exit 0
flutter test --timeout 120s test/features/pip      → +235: All tests passed!   exit 0
flutter test --timeout 120s                        → +3859 ~4: All tests passed! exit 0
```

**K06 has zero parked proofs for the first time in this loop** — every proof
this screen filed across four iterations is now live and green, and nothing is
parked in its place. The `~4` in the whole repo are the four pre-existing
non-K06 skips (`k01_bugs_test.dart:569`, `k03_bugs_test.dart:1665`,
`k03_bugs_test.dart:1733`, `p12_bugs_test.dart:321`).

## VERDICT: PASS

All tests pass and **this stage found no bug**.

The screen's only open item is no longer a K06 finding at all: with
`shared/shared_batch7`, `shared/k06_glyphs` and iteration 4's component switch
landed, all four `ORCHESTRATOR_NOTES` items are closed and both
`SHARED_REQUEST` glyph sections are resolved (§4).

## 1. What iteration 4 changed, and how I checked it

Iteration 4 was the component swap the review stage demanded (`4_review.md`
finding 1, iteration 3): **three local widgets deleted** —
`PipCareButton` (152 lines) → `NestKidButton(trailing:)`, `PipNestSlot`
(98 lines) → `NestPetStage(…)`, `_DashedBorderPainter` → the shared
`NestDashedBorder` — plus the review's two carried minors (`pipStageName` out
of `domain/`, the care-cost constants onto the abstract repository) and
`shared/k06_glyphs`' exact Sun-hat, Feed and Play SVGs.

A swap like that is exactly where a screen changes size without anyone
noticing, so I measured before I asserted. The shared kid button wraps its
painted card in 6 px of shadow room (`Padding(bottom: gap6)`), so its widget
box is the design's **91 px card + 6**, and the view compensates with
`SizedBox(height: s4 - gap6)`. If that arithmetic were a pixel out, every band
below the care row would drift.

I measured the whole column myself (temporary probe, real fonts loaded, then
deleted) against the design numbers this screen has pinned since iteration 1:

| Band | Design | App after the switch |
|---|---|---|
| back / lock | 47–103 | 47–103 ✓ |
| title | 107–141 | 107–141 ✓ |
| pet slot | 150–356 | 150–356 ✓ |
| growth card | 372–486 | 372–486 ✓ |
| care **card** | 502–593 | 502–593 ✓ (box 502–599 = card + 6) |
| section heading | 609–635 | 609–635 ✓ |
| wardrobe tiles | 651–767 | 651–767 ✓ |
| caption | 783–803 | 783–803 ✓ |

Pixel-exact, and the compensation lands: the wardrobe row still starts exactly
one `s4` below the **painted** card, not below the padded box.

## 2. Tests added this stage

Two new files (13 tests) and one addition to an existing one. All inside
`app/test/features/pip/` (RULES §1); no existing assertion weakened.

### `pip_shared_component_fidelity_test.dart` (7, new) — the swap changed nothing visible

* **The care row kept the design pitch** (3): the painted card is 91 px at the
  design height for all three buttons; each widget box is that card **plus the
  shared 6 px**, with the room *below* the card and none beside it; and the
  wardrobe heading still starts exactly `s4` below the painted card — the
  direct proof that the view's `s4 - gap6` compensation is exact rather than
  1 px optimistic.
* **The care internals are the design sizes** (1), all measured, none pinned
  before: 24 px lead icon, a 20 px label line box, the 16 px `.k6-coin img`,
  the 19 px `.k6-free` pill (13 px font + 3 px padding), and the pill inside
  Play's card rather than below it.
* **The pet slot is wired with the design arguments** (1): `nestWidth` 230,
  `nestHeight`/`slotHeight` 206, `fixedPipHeight` 134, `pipBottom` 81,
  `nestFit: contain`, and **`showGlow`/`showGroundShadow` false**. That last
  pair is the one thing every other proof in the suite is blind to: a glow
  paints *outside* every rect, so a regression to the shared default would keep
  all 235 tests green and show up only as heat in the pet band.
* **The slot geometry** (2): 230 × 206 slot, the 134 px Pip at `bottom: 81`
  with its **9 px overhang above the slot** (`134 - (206 - 81)`), and the nest
  art in the slot box at `BoxFit.contain` sharing its bottom edge.
* **The shared dash kept the design metric** (1): 6 / 3, with the stroke
  deferred to `NestKidTheme.borderWidth` (never a literal), and no dashed layer
  at all on an owned tile.

### `pip_care_glyphs_test.dart` (6, new) — the care row's icons, byte-compared

The wardrobe glyphs went through two rounds of "the app draws a look-alike"
(Scarf/Wellies on `shared_batch7`, then the Sun hat on `shared/k06_glyphs`).
The **care row's three icons were the same class of artefact with no proof at
all**: `shared/k06_glyphs` added `ic_kid_feed.svg` / `ic_kid_play.svg` and K06
now draws them, while Bath's `NestIcons.bubbles` already matched — none of it
verified. This reads the design's three `.k6-care` button bodies out of
`K06-pip.html` — path **and** circle geometry (`cx`/`cy`/`r`), in source order
— and compares them with the asset each icon constant resolves to:

* the three icons are the design glyphs byte for byte (whitespace/case
  normalised, nothing else);
* the design really does have three care buttons in Feed/Play/Bath order (the
  oracle's own sanity check);
* none of them is the superseded look-alike (`NestIcons.feedBowl`,
  `NestIcons.ball` — which still exist for other screens, asserted);
* the three are distinct assets, so a copy-paste swap cannot wire all three to
  one glyph.

### `pip_copy_parity_test.dart` (+1)

**BALANCED HEADINGS** (orchestrator rule) had no proof anywhere in the K06
suite: `.kid-title` sets `text-wrap: balance`, so the title must render through
`NestBalancedText` — but swapping it for a plain `Text` leaves every string,
rect and measurement in the suite identical, and the only symptom is a
one-word orphan line in a screenshot. Now pinned: exactly one
`NestBalancedText` on the screen, its copy, and `maxLines: 2`.

## 3. One authoring slip of my own (recorded, fixed)

My first draft of the fidelity file ended every test without `disposeApp`,
which fails the framework's pending-timer check and, worse, left the earlier
groups' results unreliable until the file was fixed. Two assertions in it were
also wrong before they were fixed: the Pip's overhang is
`134 - (206 - 81) = 9`, not `134 - 81 = 53`. Both corrected; the file is 7/7
and the whole suite was re-run afterwards.

## 4. Open items

**None that belong to K06.**

| Item | Status |
|---|---|
| `ORCHESTRATOR_NOTES` 11:30 item 1 (locked dashed border) | closed in iteration 2 (BUG-6), still green |
| item 2 (design glyphs) | closed: Scarf + Wellies on `shared_batch7`, **Sun hat on `shared/k06_glyphs`** — the proof this stage parked in iteration 2 is un-skipped and green |
| item 3 (prices 30/60) | closed upstream; `K06-BATCH7` live and green with no expectation changed |
| item 4 (Pip + nest correct) | informational; `4_review.md` finding 1 resolved the earlier tension with BUG-4 by measurement, and this stage re-measured the bands (§1) |
| 13:52 component switch | **complete in iteration 4** — all five items adopted, three local widgets deleted, and §1 above is the measurement that nothing moved |
| `SHARED_REQUEST.md` §1/§2/§3/§5/§6/§7 | all resolved; the file should be rolled up as "adopted on main" by the build stage |
| `kPipNotWearable` — the only on-screen string not in the design | still awaiting an orchestrator ruling (`2_build.md` §5.2); unchanged since iteration 1 and not a bug |
| `NestProgress`'s kid highlight spans the whole track | shared component (core); deliberately not pinned green by me |
| the design-derived identities (`kPipSlotWidth`, `kPipCareButtonHeight`, `kPipNestArtWidth`) are now literals (230 / 206 / 91) in three test files, since the widgets that declared them were deleted | test-only cosmetics, commented as the CSS they come from. A shared test-side const block would be tidier than three copies; recorded as an optional tidy, not filed |

## 5. Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | `pip_bloc_test.dart` (19) + `pip_bloc_actions_test.dart` (22) + the mapping/carry groups in `pip_buy_result_test.dart` (18) + `pip_atomic_writes_test.dart` (17) | ✅ |
| light + dark | every widget group; dark × 320/430 for the loaded body, failure card and no-child card | ✅ |
| widths 320 / 390 / 430 | real surfaces, asserted inside every `_pumpNest` (the size is applied *after* `pumpAppRoute`, which pins 390 itself) | ✅ |
| text scale 1.0 / 1.3 | fit matrix on the loaded body, the failure/no-child cards, the care-height proofs at all six width × scale combinations, and the held-press proof | ✅ |
| empty / loading / error | `pip_nest_states_test.dart` (19) | ✅ |
| every tap → right route | Back → `/kid-home` (loaded, failure, no-child), lock → `/parental-gate`, Choose → `/who-is-playing`, six non-navigating taps proven to stay on `/pip` | ✅ |
| semantics labels on icon buttons | Back / Grown-ups read from the HTML `aria-label`s; every control asserts `hasAction(tap)`; disabled care buttons assert `enabled: false` + no tap; the toast gate itself is pinned; `performAction` drives the real DB | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | ≥ 56 both axes for all 9 controls + hit test 5 px inside every corner | ✅ |
| in-memory Drift, Seed.demo / empty | all fifteen K06 files | ✅ |

Standing rules: no `google_fonts`/`GoogleFonts`, no `DateTime.now()`, no new
rows, no `letterSpacing` added, `NestBalancedText` on the `.kid-title` (now
pinned), one shared `KidScope` + meadow, no bottom bar, `disposeApp` inside
every pumped test's body.

## 6. Hand-off

* The K06 suite is fully green with **no parked proof**, so a future stage has
  nothing to `--run-skipped` here: every gate is live.
* Two proof families now read the design source instead of a transcription —
  copy parity (`pip_copy_parity_test.dart`) and glyphs
  (`pip_care_glyphs_test.dart`, `pip_orchestrator_notes_test.dart`). A design
  source edit moves those oracles rather than silently green-lighting them.
* The component swap's risk was *size*, and it is now pinned from the design
  side (`pip_shared_component_fidelity_test.dart`). If a future shared
  component changes its padding or default, that file fails with the design
  number in the message.

## 7. Files changed by this stage

* `app/test/features/pip/pip_shared_component_fidelity_test.dart` (new, 7)
* `app/test/features/pip/pip_care_glyphs_test.dart` (new, 6)
* `app/test/features/pip/pip_copy_parity_test.dart` (edited: +1 balanced-title
  proof)
* `docs/screens/K06/3_test.md` (this file)

No `app/lib/**` file was touched, and no existing K06 test file had its
assertions changed — the iteration-4 build re-pointed two of my files' imports
and measure-points at the shared components, which I checked against the design
numbers before accepting (§1): the geometry test still measures the
**design-visible painted card**, and every design constant (91, 108.67, the 12
px gaps, the 9 px pet margin, 230 × 206) is still asserted.

VERDICT: PASS
