# K03 Kid home — Stage 2b UI chunk (iteration 10)

Scope: `app/lib/features/kid_home/presentation/views/**`,
`presentation/widgets/**` and the view/widget tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_geometry_test.dart`). **No domain/data/bloc/route/DI file touched.**
`2a_build_logic.md` re-read before finishing: **no CONTRACT CHANGES**, nothing
in it touches the view layer. No simulator was booted, installed on, driven or
screenshot (SIMULATORS rule — stage 5 only).

## The one mandated change: adopt the shared pet-seat fix

`shared/pet_stage_seat` (7ef13cc) is on main, so
`docs/screens/_shared/pet_stage_seat_REPORT.md` and
`ORCHESTRATOR_NOTES` (10:14) apply: **one number changed** —
`kid_home_view.dart` `_kNestBoxHeight: 156 → 188`, keeping `nestWidth: 236`
and `fixedPipHeight: 152` (the report states `visibleNestWidth: 198` ≡
`nestWidth: 236`, so the call is byte-for-byte the mandated one). The block
stays the design's 236 px slot (16.6 + 188 + 31.4), so nothing below the pet
block moved — `_kStageToHearts` stays 10.75 and no other lever was needed.

Measured at real fonts after the change (`kid_home_geometry_test.dart`):

| pin | design | measured | tolerance |
|---|---|---|---|
| nest outline top (rim) | 278 | 278 | ±2 |
| nest outline bottom | 364 | 364 | ±2 |
| visible nest width | 198 | 198 | ±2 |
| visible nest height | 86 | 86 | ±2 |
| nest / Pip centre x | 195 | 195 | ±1 |
| Pip feet (inside bowl) | 301 | 301 | ±3 |
| Pip head | 199 | 199 | ±5 |
| hearts row centre | 448 | **447.75** | ±2 |
| first card top | 559 | 559 | ±2 |

Independent check of the *design* side (I read `design/screens/light/
K03-kid-home.png` with PIL rather than trusting the note): ink rows at the
centre column run 276–278 then 300–302, i.e. the front rim at ≈278 and Pip's
feet at ≈301; the bowl's widest row is 196–198 px (x 97…292). The app now
lands on those rows, so FIXES_9 deviation 1 (squashed 198×72 nest 41 px low,
Pip standing on the rim) is closed in the app by the shared fix.

## Review findings closed in my layer

- **Finding 2 (minor)** — `_kQuestCardShadowRoom` was the one bare `6` in the
  view; it now reads `const double _kQuestCardShadowRoom = NestSpacing.gap6;`
  (same value, same revert rule for SHARED_REQUEST #16(b), now named the same
  way in the view and in `kid_home_view_test.dart`).
- **Finding 4 (minor)** — the geometry pin measured the `SvgPicture` BOX, so a
  drift in `PipNestFallback.visibleNestRatio` would have passed silently. The
  pin now asserts the PAINTED outline (`nest.width × visibleNestRatio ≈ 198`,
  `nest.height × 110/240 ≈ 86`) plus rim 278 / bottom 364 and Pip's feet 301.
  I did **not** switch the call to `visibleNestWidth: 198` as the finding
  suggested, because `ORCHESTRATOR_NOTES` (10:14) mandates keeping
  `nestWidth: 236` and the two are equivalent by construction
  (`pet_stage_seat_REPORT.md`); the intent of the finding is met on the
  assertion side, which is where it can actually drift.

## FIXES_9 items

| item | disposition |
|---|---|
| Deviation 1 — Pip seat + nest proportions (shared `NestPetStage`) | **Fixed** by adopting the shared call above; pins added |
| Deviation 2 — speech-bubble tail ~10 px short | **Not locally fixable**: `_TailPainter` lives in `core/design_system/components/nest_pet_stage.dart`, which this stage may not edit. Filed as new **SHARED_REQUEST #17** with the measured numbers (centre column x195: design white y 152→174, app y 152→164; `.speech::after` is a 9 px ink wedge, the painter's inner fill only 6.5 px deep in an 18×10 box) and a no-API-change request. Blocks: no. |

No other FIXES_9 / FIXES_8 UI item was open: 5_ui recorded everything else as
exact (header, bubble body, hearts, chips, progress, cards per status, dock,
bottom edge, 20 px gutters, dark flips) or as an accepted override.

## Tests updated (both in my file set, both re-run)

- `kid_home_view_test.dart` — the explicit-size pin moved with the shared
  geometry: `236×188` box (prop **and** rendered `SvgPicture` rect), the
  painted outline 198×86, `fallback.nestH == 188`, `pipH`/`fixedPipHeight`
  still 152, gutters and the 320/390/430 centring proofs unchanged. This was
  the one test that broke on the value change (`the nest box is 236×156…`).
- `kid_home_geometry_test.dart` — real-font pin extended as in the table
  above; header comment rewritten to the new numbers. Values re-derived by
  measuring, not guessed (temporarily tightened to 0.05 to read 447.75, then
  restored to ±2).

## Rules re-checked in this chunk

- **PIP** — the child's own `PipAvatar` (Maya: Mochi · sunny · stage 3) in the
  pet stage, failure, empty and no-child states; no `pip_stage_*.svg`.
- **STATUS BAR** — `NestStatusBar()` only reserves height; unchanged.
- **DATA OVER MOCKS / PERIODS** — counts come from state/DB; no design number
  hard-coded anywhere in the view.
- **BOTTOM EDGE (owner)** — untouched and still correct: the dock's
  `Container(color: tokens.surface)` wraps its `SafeArea(top: false)`, so the
  bar's own surface runs from y 720 to the physical edge in both themes, with
  the home indicator inside it and no meadow/sky strip.
- **ALIGNMENT (owner)** — 20 px gutters on header, pet slot, section, cards
  and dock unchanged; the nest stays on the slot axis at 320/390/430.
- **COPY / FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS /
  SHAPES / TRIAL / CHILD ORDER** — no copy, font, spacing or chip changed;
  `NestBalancedText` still renders the only `.kid-title`; the new pins measure
  painted background/border geometry, not text positions.
- **ACCESSIBILITY ACTIONS** — untouched: every control keeps its shared
  `SemanticsAction.tap`; the pet block's semantics node is the shared
  `Semantics(image: true, label: 'Pip the Fledgling, stage 3 of 4')` and stays
  display-only.

## Verification (in `app/`, this worktree)

- `dart format lib/features/kid_home/presentation test/features/kid_home` →
  formatted, 0 pending.
- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found!**
- `flutter test test/features/kid_home/kid_home_view_test.dart
  test/features/kid_home/kid_home_geometry_test.dart` → **+85, all passed**.
- `flutter test test/features/kid_home/` → **+175, all passed** (the whole
  feature folder, to prove the change breaks neither the bloc nor the bug
  proofs; the whole-app suite is the integrator's).
- `grep skip:` and `grep google_fonts` over the feature → clean (the only hit
  is a comment saying there are none). No `analysis_options.yaml` change.

## LEFT FOR NEXT ITERATION

- SHARED_REQUEST **#17** (bubble tail interior) — shared-component, needs a
  core branch; nothing local remains.
- SHARED_REQUEST **#6** (screen-background gradient stops for `KidScope`) —
  the feature-local `_MeadowPainter` stays until it lands; `TODO(K03)` in the
  view records it.
- SHARED_REQUEST **#16(b)** (card shadow padding) — when it lands, delete
  `_kQuestCardShadowRoom` and put `NestSpacing.s3` straight back in the quest
  column.
- A fresh UI capture is the only way to confirm the new pet block on device
  (stage 5); expect the pet band (2/3) heat to drop with the nest now at
  278…364 and Pip seated in the bowl.

VERDICT: PASS