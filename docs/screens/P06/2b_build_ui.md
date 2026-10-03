# P06 Pocket money setup — UI build (Stage 2b, iteration 6)

Builder: UI chunk only — `app/lib/features/pocket_money/presentation/views/**`,
`presentation/widgets/**`, and the `view`/`widget` tests in
`app/test/features/pocket_money/`. No `domain/`, `data/` or bloc/cubit file was
touched; `2a_build_logic.md` reports **no CONTRACT CHANGES**, so the BLoC
events/states in `1_plan.md` are exactly as iterations 3–5 used them.
No simulator was booted, driven or screenshotted (SIMULATORS rule: only stage 5
may). Full-app `flutter test` was not run (integrator owns it); the feature
suite was.

## Files changed

| File | Change |
|---|---|
| `lib/features/pocket_money/presentation/widgets/p06_weekly_stepper.dart` | **new** — token-for-token `NestStepper` with the design's `−`/`+` glyph pair |
| `lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart` | `_BaseStepper` → `P06WeeklyStepper`; day cells announce `Payout day: <day>` |
| `test/features/pocket_money/pocket_money_setup_view_geometry_test.dart` | **new** — the mandated real-fonts geometry guard (07:22 note) |
| `test/features/pocket_money/p06_weekly_stepper_widget_test.dart` | **new** — widget tests for the stepper, incl. "minus is not U+002D" (07:58 note) |
| `test/features/pocket_money/p06_bugs_test.dart` | removed the two `skip: true` lines (BUG-11, BUG-12) |
| `test/features/pocket_money/pocket_money_setup_view_test.dart` | day-cell semantics labels; fixed a bogus "fits on one line" assertion |
| `docs/screens/P06/SHARED_REQUEST.md` | items 4 (`NestStepper` glyph override) and 5 (`NestChip` day variant) |

## FIXES_5 items — all closed

### 4_review #1 — H1 renders one ellipsized line → **fixed, no workaround**
The shared fix (`shared/balanced_text_ellipsis`) is on main and merged here
(`d5112fd`): `NestBalancedText`'s default `overflow` is now
`TextOverflow.clip` and `lineCountFor` no longer lays out with a hard-coded
`'…'`. `_SetupTitle` is unchanged — still
`NestBalancedText('How does pocket money work in your house?', style:
context.nestText.h1, textAlign: TextAlign.left)` with **no** `maxLines`, no
local `overflow`, per the 07:58 instruction ("keep using `NestBalancedText`;
do not work around it"). It now paints **two 34 px lines at 107–175**, and
the whole card sits back on the design's 415–684.

### 4_review #2 — the real-fonts geometry test was absent → **added**
`pocket_money_setup_view_geometry_test.dart` loads the bundled Inter/Nunito
with `FontLoader` (as `privacy_consent_geometry_test.dart` does), seeds
`Seed.onboardingKids` (the shoot seed), pumps `/pocket-money-setup` at
390×844 and pins **every** anchor from `ORCHESTRATOR_NOTES` at ±1 px:

| Anchor | Design | Test | Result |
|---|---|---|---|
| H1 top / height | 107 / 68 | 107 / 68 | pass |
| option cards | 191, 263, 335 (each 64 tall, 20→370) | same | pass |
| settings card | 415 → 684 | same | pass |
| `Payout day` label | 431 → 449 | same | pass |
| day pill | 455 → 487, 32 tall, centre **470.5** | same | pass |
| `Weekly base` | top 503, centre **512** | same | pass |
| `Maya` / `Leo` | centres **545** / **589** | same | pass |
| `Coin value` | centre **650** | same | pass |
| CTA panel | surface reaches 844; 124 tall; button 350×52 | same | pass |

The orchestrator's `555 / 597 / 630 / 674 / 735` were read off the **compare
sheet**, which sits ~84.5 px lower than screen space; the table above pins
the screen-space equivalents the sheet numbers correspond to (checked by
re-deriving them from the design hook table in `4_review`: chip 470.5 +
84.5 = 555, weekly 512 + 84.5 = 596.5 ≈ 597, Maya 545 + 84.5 = 629.5 ≈ 630,
Leo 589 + 84.5 = 673.5 ≈ 674, coin 650 + 84.5 = 734.5 ≈ 735). The test file
documents this so the next stage does not "correct" it back.

### 4_review #3 / P06-BUG-12 — stepper minus is a hyphen → **fixed**
`NestStepper` (`core/design_system`, RULES §1 forbids editing) hard-codes
`label: '-'` and exposes no glyph override, so the fix had to live in the
screen. New `P06WeeklyStepper` (`presentation/widgets/`) is identical to the
shared component token for token — 44 dp circles, 1 px `line` border on
`surface`, `NestType.bodyStrong` 20, `NestSpacing.s3` gaps, 64 dp
`NestType.money` 18/24 value, identical `Semantics` + 0.45 `Opacity`
disabled contract — except it pairs `kP06StepperMinusGlyph` (`−`, U+2212,
the HTML's `&minus;`) with `+` (U+002B). The whole widget is one deletable
file once `NestStepper` grows the override now requested in
`SHARED_REQUEST.md` item 4; it is marked for retirement in its own doc
comment.

`p06_weekly_stepper_widget_test.dart` covers the 07:58 ask verbatim: the
minus `Text.data` is `'−'`, equals the exported constant, and its code units
are **not** `[0x2D]`; `+` is U+002B from the same 20/w700 style; both buttons
are 44 dp, announce as buttons, fire their callbacks, and a null callback
dims to 0.45 and swallows the tap.

### 4_review #4 — the `Payout day` group label was dropped → **restored**
The day cells now carry the HTML's group name in their own semantics label
(`Payout day: Mon` … `Payout day: Sun`) instead of reintroducing the
`Semantics(container: true)` wrapper that iteration 5 had to remove (it
re-clamped `NestChipWrap`'s ±6 px hit slop). No extra widget enters the chip
chain, so the ±5 px-above/below tap guards stay green (verified). The a11y
test's control list and its uniqueness assertion were updated to the anchored
pattern and additionally assert the bare `Mon`…`Sun` labels are gone.

### 4_review #5 — invented empty-state copy → **unchanged, still flagged**
`'Add children to set weekly amounts.'` has no source in `DESIGN_SPEC.md §5`
or the HTML and renders only for `Seed.empty`/`Seed.fresh`. `4_review` classes
it as "a finding-to-be-ratified, not a fix", so it is left byte-identical
pending the orchestrator's decision rather than silently reworded.

## ORCHESTRATOR_NOTES — item by item

| Note | Item | Result |
|---|---|---|
| 04:05 | 1 seed `onboarding_kids`, DB children in insertion order | unchanged (Maya £3.00, Leo £1.50 from the DB; no literals); the new geometry test pumps exactly this seed |
| 04:05 | 2 chips inside the 16 px inset at 390/320 | unchanged, guard green |
| 04:05 | 3 letterSpacing 0, no local tracking | unchanged; no `copyWith(letterSpacing:)` added |
| 04:05 | 4 gold coin tile (`assets/coin.svg`) | unchanged (`NestlingIllustrations.coin` in the 40×40 `coinTint` tile) |
| 04:05 | 5 option cards' height | **pinned** at 64 each (191/263/335) by the geometry test |
| 04:05 | 6 `NestChipWrap` + ±5 px taps | unchanged, guard green |
| 07:22 | chip-row centre / `Weekly base` / Maya / Leo / coin | all pinned at ±1 px, all green |
| 07:22 | real-fonts geometry test | **added** (see above) |
| 07:22 | `−` (U+2212) like `+` | **fixed** |
| 07:22 | every FIXES_4 item | still fixed — no regression in this stage (suite green) |
| 07:58 | 1 title must be 2 lines, keep `NestBalancedText`, no workaround | **done**, screen back at the iteration-4 positions |
| 07:58 | 2 minus not U+002D + a test | **done** |
| 07:58 | 3 the five y targets from the title's bottom | **done**, all green |

## Other iteration-5 UI notes

* **5_ui deviation 3 (day-chip glyph ~10 px)** — already resolved by
  iteration 5's `_DayPill`, which paints `NestType.fieldLabel` (Inter
  13/18 w600, the HTML's `.chip.day { font-size: 13px }`) directly with no
  `FittedBox`. No change needed; `SHARED_REQUEST.md` item 5 records that what
  remains is de-duplication only.
* **5_ui deviation 4 (`£` glyph vs `coin.svg`)** and **5 (bottom strip)** —
  token equivalent / owner override; no change.
* **CTA panel** — `NestBottomCta(dense: true)` keeps the CTA surface running
  to the physical edge with no page-tint strip (OWNER BOTTOM EDGE) in both
  themes; the geometry test now pins `bottom == 844`, `height == 124` and the
  350×52 button so a future change cannot quietly reintroduce a strip.
* **PIP / STATUS BAR / COPY / FONTS** — no Pip on P01–P07, no status-bar
  coupling, no copy characters touched, no `google_fonts`/`GoogleFonts` in
  the feature or its tests (`grep` → 0).

## Checks run (stage-allowed only)

* `flutter analyze lib/features/pocket_money test/features/pocket_money` →
  **No issues found!**
* `dart format --output=none --set-exit-if-changed` on both → **0 changed**
* `flutter test test/features/pocket_money/` → **+155: All tests passed!**
  (was `+143 ~2 -1` at the start of the stage: the two skips are now real,
  passing proofs and the one pre-existing failure is fixed)
* No `flutter clean`, no `flutter run`, no simulator, no whole-app
  `flutter test`, no `analysis_options.yaml` change.

## LEFT FOR NEXT ITERATION

* **Nothing blocking this screen.** The stage-6 `zz_p06_s6_probe_test.dart`
  probe is gone from the worktree (its numbers are folded into
  `pocket_money_setup_view_geometry_test.dart`).
* **Needs the orchestrator's call:** ratify or replace the empty-state copy
  `'Add children to set weekly amounts.'` (4_review #5).
* **Needs a shared merge, non-blocking:** `NestStepper`'s U+2212 glyph
  override (`SHARED_REQUEST.md` item 4) — when it lands, delete
  `p06_weekly_stepper.dart`, point `_BaseStepper` back at `NestStepper`, and
  keep the widget test's glyph assertions as the regression guard.

VERDICT: PASS
