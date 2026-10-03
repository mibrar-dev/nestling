# Fix list after iteration 4

## From 3_test.md
# P05 · Add children — test notes (STAGE 3, iteration 4)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/add_children_test.dart` plus these notes — no screen
code touched.

Iteration 4 is the loop's last iteration and its brief is "be exact". The
orchestrator's four targets are addressed; the build stage's fixes (rowid child
order, 116 px cards, the `IntrinsicWidth` removal now that the shared chip is
fixed) are all re-proved. **P05's own suite is green (116 tests).** The full
`flutter test` run is still red on the one shared test filed as BLOCKING in
iteration 3, which arrived from main and is outside RULES §1 — hence FAIL.

## Tests added / rewritten (9 added; 3 superseded)

### CHILD ORDER ruling — now asserted directly (note 1)

The build implemented the interim `rowid` ordering in
`family_repository_impl.dart`, and flipped one assertion to `maya.left <
leo.left`. I replaced that single assertion — and my iteration-3 invariant
group — with a five-test group that proves the ruling itself:

| Test | What it rules out |
|---|---|
| the seeded roster reads **Maya, then Leo** (on `onboarding_kids`) | alphabetical order (Leo < Maya is the trap) |
| a child added in this session **appends**: `[Maya, Leo, Ollie]` | sorted-into-place — 'Ollie' lands between Leo and Maya alphabetically, so only insertion order gives this |
| **renaming** Maya → 'Zoe' keeps `[Zoe, Leo]` | nickname ordering: 'Zoe' would sort *after* Leo and flip the roster |
| the grid renders the bloc's roster **verbatim, unsorted** | a local re-sort in the grid |
| the bloc never reorders (fed both orders) | a sort in the bloc |

The rename test is the decisive one for the durable fix: it passes on the
`rowid` interim and would fail on any nickname-based ordering, so it keeps
proving the ruling after the shared `createdAt` column lands. Two harness
details that cost a cycle and are now written down: `pumpEventQueue()` hangs in
`testWidgets` (its `Future.delayed` never fires in the fake-async zone — drive
the clock with `tester.pump()` instead), and `FamilyBloc` is a GetIt *factory*,
so the rendered order must be read from `BlocProvider.of` on the grid.

### Form-card rhythm — every gap and row height vs the HTML (note 3)

The note asked me to take every vertical gap from the HTML because the rows
"drift down cumulatively". Measured on the current code, **they do not drift —
every gap and every row height is the design value** (390 px, scale 1.0):
`h3` 24 · →field 10 · label 18 · →input 6 · input **52** · →Age band 8 ·
label 18 · →chips 4 · →Avatar colour 8 · label 18 · →swatch 4 · swatch 44 ·
→note 6. Two new tests pin exactly that table (row heights + the seven gaps,
with the HTML selector quoted in the reason strings) and a second test asserts
`sub → grid = 14` and `grid → form card = 12` at **320, 390 and 430** (notes 2
and 3's gap targets).

## Results

```
dart format .        clean (362 files, 0 changed)
flutter analyze      No issues found!
flutter test test/features/family/    00:05 +116: All tests passed!
    add_children_test.dart   105 · p05_bugs_test.dart 11 · zero skips
flutter test (full suite)             1 failure — app/test/app/router_push_test.dart
```

## Bugs found

### None in P05 code

Nothing in this iteration's diff produced a defect: the order fix, the 116 px
card, the chip-component cleanup and the removed `IntrinsicWidth` wrappers all
re-pass, including the BUG-1 geometry proofs (no chip claims the run, ≤2 rows in
the test font, one row in production).

### 1. Still-open shared gate: `router_push_test.dart` asserts P05's placeholder

Unchanged from iteration 3 — `app/test/app/router_push_test.dart:104` passes
`showsFrom: 'P05 Add children'`, the pre-build placeholder title, so line 37
fails and the repo gate stays red on every branch where P05 is built. The file
is still at main's `7eaa1f7`, this worktree has never touched
`app/test/app/**` or `app/lib/app/**`, and the fix is one string
(`'Who\u2019s in your nest?'`). Filed as BLOCKING since iteration 3.

### 2. The residual 4.87% band drift is a shared typography effect, not P05's

The QA note's ladder (+4 at "Nickname", +8 at the field, +13 at the chips, +20
at "Avatar colour", and the form card top at ≈407 vs the design's 399) is real,
but **it is not produced by P05's layout**: every gap is a literal `SizedBox`
and every row height measures the HTML value in a widget test (table above).
The only variable left is the line boxes, and they only differ on device —
`NestType` promises "line boxes match the CSS exactly"
(`typography.dart:8`), which holds for the test fallback font (1.0 em) but not
for Nunito/Inter, which the app **fetches at runtime** (`pubspec.yaml` bundles
no fonts). Flutter scales a font's ascent+descent, whose natural line height
exceeds 1 em, so each row grows ~4 px and the error compounds down the card —
which reproduces the QA ladder and the 8 px head offset exactly.

Consequence: I could not reproduce it in tests, so it is not something this
stage can gate on; it belongs to the type scale, and it affects **every**
screen's vertical rhythm equally. Filed in `SHARED_REQUEST.md` with the
measurement table and three owner options (clamp line height with
`TextHeightBehavior`/strut, bundle metrics-matching fonts, or accept it as a
known delta). P05's action is complete: the gaps and heights are now pinned, so
any future drift is either caught here or attributable to that shared effect.

## Noted, not bugs

* `NestChip`'s 44 px tap row still occupies 44 (design `.chip` visual is 32);
  correct per `SPACING_SPEC` §6 ("base 32 high is below 44 → wrap in a 44-min
  tap area").
* The chips wrap to two rows **in tests only** (the fallback font is ~30%
  wider); production renders one row, verified on the simulator in iteration 2.
* Mid-save Continue is still dropped by the BUG-2 guard (buttons disable for the
  whole save; the design has no "still saving" state).
* `onSaved` on the event, `child_display.dart` placement, the raw exception
  string and the 1 px pencil offsets remain carried accepts from the review.


## From 5_ui.md
# P05 · Add children — UI check (STAGE 5, iteration 4)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (still mandatory; overrides the
brief's `fresh`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_4.png` → `cmp_light_4.png`, **mean diff 3.78%** (was 4.87%)
- Dark: `docs/screens/P05/ui/app_dark_4.png` → `cmp_dark_4.png`, **mean diff 3.75%** (was 4.88%)

Per-band drift (light): band0 0–105: 1.58% · band1 105–211: 5.02% · band2 211–316: 0.55% ·
band3 316–422: 2.83% · band4 422–527: 4.24% · band5 527–633: 10.76% · band6 633–738: 1.50% ·
band7 738–844: 3.71%. Dark matches within ~0.5% (band5 11.11%).

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who’s" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names | 254.0–262.7 | 254.0–262.7 | 0 |
| h3 "Add a child" | 334.7–346.7 | 334.7–346.7 | 0 |
| "Nickname" label | 370.0–376.7 | 370.0–376.7 | 0 |
| "Age band" label | 454.0–460.7 | 454.0–460.7 | 0 |
| chip labels | 481.0–490.7 | 486.0–495.7 | +5 |
| "Avatar colour" label | 516.0–522.7 | 528.0–534.7 | +12 |
| swatch row zone | 529–577 | 541–589 | +12 |
| helper caption | 588.0–594.7 | 600.0–606.7 | +12 |
| CTA (buttons + caption) | 678 / 716–768 / 781–790 | identical | 0 |
| CTA top (gutter) | 644 | 645 | +1 |

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — the one remaining defect] Chip row is 44 px tall vs design 32 px, pushing
   swatches + caption +12 px low (outside the ±2 px tolerance; band5 drift 10.8–11.1%
   is this shift of large colour circles).
   Design: `.chip` 32 px row (467–499), labels 481–491, Avatar label 516, swatches
   529–573, caption 588. App: same row top, but the shared `NestChip` interactive box
   is 44 tall (labels centred +5 at 486–496), so every row below sits +12.
   Root cause (shared, read-only finding): after the batch-1 fix `nest_chip.dart` carries
   the 44-min tap minimum AS the layout box (`ConstrainedBox(minWidth 44)` + symmetric
   vertical 4.5 padding around a 35 px pill = 44 px layout height). SPACING_SPEC §10.6
   requires the tap area to "keep visual size" — i.e. a 32 px layout row with the 44 px
   tap area overlaid (Stack), not stacked. P05 cannot fix this (never touch `core/`; no
   clean local workaround — negative spacing or fixed heights would break tokens and
   text-scale behaviour).
   Fix: shared DS follow-up on `nest_chip.dart` (overlay construction); the standing
   `SHARED_REQUEST.md` #3 already covers it. P05-local `IntrinsicWidth` workaround is
   now redundant (shared fix lays one row correctly) — cleanup note for the build stage.

2. [Pass, verified fixed] CHILD ORDER: Maya left, Leo right from the database, matching
   the design and the ruling (iteration-3 finding closed by the repo order fix + test).

3. [Pass, verified fixed] Card clearance: h3/Nickname/Age-band labels now ±0 (iteration-3
   +8 closed). Cards top/height match (band2 0.55%).

4. [Pass] Copy character-exact vs HTML (curly ’ U+2019, em/en dashes, "Avatar colour",
   all labels/captions/buttons, `Edit <name>`). No overflow/clipping/ellipsis. Focus-ring
   absence accepted (unfocused launch is fine, orchestrator note 4).

5. [Pass] Owner rules: bottom bar surface to the physical edge both modes (CTA +1 px);
   20 px gutters, all edges aligned. Dark-mode colours match (band tables within 0.5%).

6. Note on orchestrator iteration-4 targets (§18.2–3: card top ≈ 399, field ≈ 471, chips
   centre ≈ 569, colour centre ≈ 637, helper ≈ 674): these do not reproduce from the
   design PNG (measured: card top ~192, h3 ink 334.7, Age-band label 454, chips ~467–499,
   swatches 529–573, caption ink 588; method: dark-pixel row runs on 1170×2532 ÷ 3).
   The table above is the reproducible record; the residual to close is the +12 in row 1.

## Verdict basis

Everything is visible, ordered, and spelled correctly, and all owner rules hold — except
one systematic +12 px shift of the swatch row, its label, and the helper caption, owned
by the shared chip component. It exceeds the ±2 px tolerance and shows clearly in the
compare heat-map, so the gate cannot pass on this build.

