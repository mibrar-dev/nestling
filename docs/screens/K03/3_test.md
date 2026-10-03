# K03 Kid home — Stage 3 (TEST), iteration 10

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
- `flutter test` (whole app) → **exit 0, `+1582`** — 1582 pass, **0 skip,
  0 fail**.
- `flutter test test/features/kid_home/` → **exit 0, `+178`** — 178 pass,
  **0 skip, 0 fail**.

| File | Iteration 9 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 84 | **87** (+3, all pass) |
| `kid_home_bloc_test.dart` | 31 | **31** |
| `k03_bugs_test.dart` | 59 | **59** |
| `kid_home_geometry_test.dart` | 1 | **1**, extended by the build |

Iteration 9 was the first iteration with `review=PASS`; the only failing stage
was the UI check, and both of its deviations were outside K03's edit scope (one
shared component, one shared cosmetic). Nothing from iteration 9's
review/bugs output needed a test.

## What iteration 10 delivered (the surface under test)

1. **`shared/pet_stage_seat` landed** (branch report:
   `docs/screens/_shared/pet_stage_seat_REPORT.md`), fixing 5_ui iteration 9
   deviation 1 — the bowl was squashed (198×**72** instead of 198×**86**) and Pip
   stood **on** the rim (≈1 px overlap) instead of sitting in the bowl. The
   screen answers with `nestHeight: 156 → 188`
   (`kid_home_view.dart:81`), which paints the design's 86 px tall outline
   (`188 × 110/240`) and seats the feet ≈23 px below the rim.
2. **`_kQuestCardShadowRoom` tokenised** to `NestSpacing.gap6`, so the view and
   the test name the same 6 px reserve the same way (behaviour unchanged).
3. **The real-font geometry test** now pins the new rows: nest outline
   278…364 (±2), nest centre 195 (±1), Pip centre 195 with feet 301 (±3),
   hearts 448, first card 559 — and it passes.
4. Main also merged `shared_batch4` (schema v4), which changed
   `watchActiveQuests` to **creation order** — relevant below.

## Tests added (this stage)

### `kid_home_view_test.dart` — pet slot group

1. **`the bowl outline is the design 198×86`** — the rendered nest box is
   236×188 and the art's visible outline is `box × (202/240 × 110/240)` →
   198×86. Complements the width pin the build added; before `nestHeight: 188`
   the outline was 72 tall (squashed).
2. **"Pip's feet sit inside the bowl, not on the rim"** — the regression the UI
   stage measured: `feet (pipBox.bottom − 21.2, the v2 avatar's feet line) −
   rimTop (nestBox.top + nestBox.height × 95/240)` must be ≈23 px. Measured
   22.98 in this viewport; the pre-fix value was ≈1 (standing on the rim). The
   test also pins that the feet are *inside* the bowl, not sunk through its
   floor. Both ratios come from the assets and are cited in the shared report,
   so a change in either is a deliberate flag, not silent drift.

### `kid_home_view_test.dart` — new group `K03 quest order (data wins)`

3. **`the list keeps the repository order (alphabetical by title)`** — pins
   Maya's six cards as Empty the dishwasher · Hoover the stairs · Lay the table ·
   Put the bins out · Reading – 20 minutes · Tidy your bedroom, i.e. the
   repository's `sort(title.compareTo)`. This makes the order *intentional and
   visible* rather than incidental, and documents the divergence below in the
   test itself.

## Results

All 3 new tests pass; nothing else moved. Still green: the layout matrix (light
+ dark × 320/390/430 × text scale 1.0/1.3), layout invariants on painted card
rects, PERIODS, bottom-edge and alignment owner rules, navigation, labels, tap
targets, the accessibility-actions matrix from iteration 9 (every control
advertises `SemanticsAction.tap` and performing it changes the real state/DB;
non-controls advertise none), the PipAvatar mandate, the completion/celebration
state machine, the shapes group (chip pill, tile + tint, 56 px check, `.speech`
bubble, scene box per width), and the real-font geometry test.

## Bugs found

**None.** No test failed and nothing misbehaved under this stage's probes.

### Observation for the orchestrator (not a finding)

**Quest order vs the new shared ruling.** Main's schema v4 / `shared_batch4`
changed `watchActiveQuests` to creation order
(`app_database.dart:477-480`: `orderBy([createdAt, id])`), but K03's
repository still re-sorts locally
(`kid_home_repository_impl.dart:73`: `sort((a, b) => a.title.compareTo(b.title))`),
so K03 is now the only screen that re-orders quests. This is **not** reported as
a defect because:
- `1_plan.md` §a states the repo order deliberately — "repo order
  (alphabetical — visual order differs from PNG sample order; data order wins,
  do NOT re-sort)";
- the orchestrator's ORCHESTRATOR_NOTES says "Quest order and '4 done today'
  come from the database (DATA OVER MOCKS): not findings", and the UI stage has
  accepted the alphabetical data order for nine iterations (its A2 item);
- the design settles nothing: the PNG's sample order (dishwasher, reading,
  tidy) is a third order again.

My test pins the documented behaviour and names the divergence in a comment, so
if the orchestrator ever rules creation order, the diff shows exactly which six
cards move.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset emulated)
  pass — the dock surface runs to the physical edge and the meadow ends at the
  dock's top border in both themes.
- **ALIGNMENT:** gutters and shared card/bar/dock edges pass; the pet slot is on
  the axis at 320/390/430 with no clipping; dock labels cannot wrap, so the
  three buttons keep equal heights at every width and text scale; quest cards
  keep the design's 12 px gap between *painted* rects.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| PIP | Mandated `PipAvatar` in every state; **now also seated in the bowl** with the design's 23 px rim overlap (new pin) |
| BOTTOM EDGE / ALIGNMENT | Proven by tests (above) |
| PERIODS + DATA OVER MOCKS | Counts from the DB; daily/weekly/once + new-period proofs green; quest order now pinned as documented |
| COPY | Re-verified character-by-character against the HTML source (0 curly / 4 straight apostrophes; the seed's en dash and the detail chip's middle dot intact) |
| FONTS / LETTER SPACING | No `google_fonts`; every rendered string asserts `letterSpacing == 0` |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip` |
| UI CHECK MEASURES SHAPES | Outline 198×86 and the Pip's feet line are measured as geometry, not inferred from props; painted-card gaps, chip pill, tile + tint, check, bubble and scene box likewise |
| BALANCED HEADINGS | The only `.kid-title` heading renders through `NestBalancedText`; nothing else does |
| ACCESSIBILITY ACTIONS | Iteration 9's 7-test matrix still green (tap action on every control, real effect, none on non-controls) |
| CHILD ORDER | No child list here; pinned at the repository level (K03-BUG-12) |
| TRIAL | No test writes `subscription_status` |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- The pet-slot derivations need both asset ratios, not one: the outline is
  **not** vertically centred in the nest box — it starts 95/240 down it (the
  art's outer bowl spans 95…205 of 240). A centred assumption is off by ~24 px
  and hides a 46 px error as a 23 px one.
- The v2 Pip's feet sit 21.2 px above the bottom of its 152 px box, so
  `pipBox.bottom` is not the feet line.
- Offstage cards have **no semantics node** (iteration 9's note): scroll a
  control into view before asserting or performing its semantics action.
- `pushedPath`, not `currentPath`, for `push`ed routes.
- The design source uses a **straight** apostrophe (`Who's playing?`).
- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`;
  bottom insets are emulated via `tester.view.padding` / `viewPadding` at 3×
  physical px; never `pumpAndSettle` while a loading spinner is on screen;
  seed the DB before pumping the route.

VERDICT: PASS
